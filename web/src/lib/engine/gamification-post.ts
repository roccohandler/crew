// SPEC: README "postCreated" — A22 G1 (a) (owner-approved 2026-09-18): a day COUNTS (streak + 1) only when a completed workout lands
// on a planned training day — or on any day under an all-rest plan (plannedWeekdays === []); a rest day neither requires nor
// breaks; a bonus or cardio day pays its XP and leaves the streak unchanged (V70, the repeal of V30). The first post of a day still
// pays +xpFirstPostOfDay whatever it is (V25, V70). Comeback: the first COUNTED day after ≥ comebackMissedDaysThreshold missed
// planned days (V82, R-069). Perfect week: every planned weekday of the Mon–Sun week carries a completed workout (V73–V76) — the
// "every day posted" clause is gone with the plate journal. Levels G2. Meals/text: fixture-only branches (their vectors are retired).
// A27 (a) (owner-approved 2026-09-18): with the training-days history on the event, each of those tests reads the days in effect
// on the day it judges (V85–V90). Twin: ios/Crew/Engine/GamificationPost.swift.
import type { Award, GameEvent, GamificationState, Pause } from "@/lib/engine/gamification";
import { isPaused, levelFor } from "@/lib/engine/gamification";
import { addDays, isoWeekday, weekKeyFor } from "@/lib/engine/day-key";
import { weekdaysOn } from "@/lib/engine/training-days";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

type PostEvent = Extract<GameEvent, { type: "postCreated" }>;

// SPEC: A27 (a) — the weekdays the plan asked for on `dayKey`, as this post knew them: from the history when the event carries it
// (a day the post has not reached yet reads the entry in effect on the post's own day — a later change had not been made), else the
// plan on the event (A22), else undefined (a pre-A22 fixture)
export function plannedWeekdaysOn(event: PostEvent, dayKey: string): number[] | undefined {
  if (event.trainingDays !== undefined) return weekdaysOn(event.trainingDays, dayKey < event.dayKey ? dayKey : event.dayKey);
  return event.plannedWeekdays;
}

// undefined = no plan on the event (pre-A22): every day is planned for the comeback, and no week can be perfect
function plannedOn(event: PostEvent, dayKey: string): boolean | undefined {
  return plannedWeekdaysOn(event, dayKey)?.includes(isoWeekday(dayKey));
}

export function quietDaysBetween(fromDayKey: string, toDayKey: string, pauses: Pause[]): number {
  let quiet = 0;
  for (let day = addDays(fromDayKey, 1); day < toDayKey; day = addDays(day, 1)) if (!isPaused(day, pauses)) quiet += 1;
  return quiet;
}

// GAP: A22 G1 (a) names no comeback rule — the most conservative reading (R-069): a "missed day" is a non-paused PLANNED day between
// two counted days (a rest day is never missed; an all-rest plan misses nothing). A fixture without plannedWeekdays (pre-A22) counts
// every non-paused day, as it always did. The crew's comeback BANNER keeps quietDaysBetween — silence in the stream (V37–V39).
// A27 (a): each day between is judged by the days in effect on it.
export function missedDaysBetween(fromDayKey: string, toDayKey: string, pauses: Pause[], event: PostEvent): number {
  let missed = 0;
  for (let day = addDays(fromDayKey, 1); day < toDayKey; day = addDays(day, 1)) {
    if (plannedOn(event, day) !== false && !isPaused(day, pauses)) missed += 1;
  }
  return missed;
}

function ensureDay(state: GamificationState, dayKey: string): void {
  if (state.day.key !== dayKey) state.day = { key: dayKey, posts: 0, meals: 0, workouts: 0, reactions: 0 };
}

function ensureWeek(state: GamificationState, dayKey: string): void {
  const weekKey = weekKeyFor(dayKey);
  if (state.week.key !== weekKey) state.week = { key: weekKey, posted: [], planned: [], plannedDone: [], awarded: false };
}

// Everything except the undo stacks and the earned achievements (V35) — restored wholesale by applyPostUndone
function snapshotOf(state: GamificationState): string {
  return JSON.stringify(state, (key, value: unknown) => (key === "undo" || key === "earnedAchievementIds" ? undefined : value));
}

// SPEC: A22 G1 (a) — what counts a day: a completed workout on a planned day; under an all-rest plan, any completed workout;
// a fixture without plannedWeekdays (pre-A22) counts a planned completed workout and nothing else. A27 (a): "all-rest" is the days
// in effect on the post's own day; the stamped isPlannedDay is a fact and is never re-judged.
export function countsTheDay(event: PostEvent): boolean {
  if (event.kind !== "workout" || event.workoutCompleted !== true) return false;
  const weekdays = plannedWeekdaysOn(event, event.dayKey);
  if (weekdays === undefined) return event.isPlannedDay;
  return event.isPlannedDay || weekdays.length === 0;
}

// SPEC: G6 as amended by A22 G1 (a) and A27 (a) — every day of this Mon–Sun week that was planned AT THE TIME carries a completed
// workout; ≥ 1 planned day; once per week. Without a plan on the event there is nothing to judge, so no week is perfect.
function weekIsPerfect(state: GamificationState, event: PostEvent): boolean {
  if (state.week.key === null || state.week.awarded) return false;
  const weekKey = state.week.key;
  const planned = Array.from({ length: TimeUnits.daysPerWeek }, (_, offset) => addDays(weekKey, offset)).filter((day) => plannedOn(event, day) === true);
  return planned.length > 0 && planned.every((day) => state.week.plannedDone.includes(day));
}

// SPEC: V73, V74 — +150 always; the shield only below the cap; once per week
function awardPerfectWeekIfEarned(state: GamificationState, event: PostEvent, xp: Award[], flags: { perfect?: boolean; shieldEarned?: boolean }): void {
  if (!weekIsPerfect(state, event)) return;
  state.week.awarded = true;
  flags.perfect = true;
  xp.push({ award: "xp", amount: SpecConstants.xpPerfectWeek, reason: "perfectWeek" });
  if (state.shields < SpecConstants.maxShields) {
    state.shields += SpecConstants.shieldsEarnedPerPerfectWeek;
    flags.shieldEarned = true;
  }
}

function addUnique(list: string[], value: string): void {
  if (!list.includes(value)) list.push(value);
}

// Builds the canonical award list (README order) after XP and state changes
export function finishAwards(state: GamificationState, xp: Award[], streakBefore: number, flags: { comeback?: boolean; perfect?: boolean; shieldEarned?: boolean; shieldConsumed?: boolean }): Award[] {
  state.totalXP += xp.reduce((sum, award) => sum + (award.award === "xp" ? award.amount : 0), 0);
  const awards: Award[] = [...xp];
  if (state.currentStreak !== streakBefore) awards.push({ award: "streakTo", value: state.currentStreak });
  if (flags.comeback) { state.tallies.comebacks += 1; awards.push({ award: "comeback" }); }
  if (flags.perfect) { state.tallies.perfectWeeks += 1; awards.push({ award: "perfectWeek" }); }
  if (flags.shieldEarned) awards.push({ award: "shieldEarned" });
  if (flags.shieldConsumed) { state.tallies.shieldsConsumed += 1; awards.push({ award: "shieldConsumed" }); }
  const level = levelFor(state.totalXP);
  if (level > state.level) awards.push({ award: "levelUp", value: level });
  state.level = level;
  return awards;
}

export function applyPostCreated(state: GamificationState, event: PostEvent, pauses: Pause[]): Award[] {
  const day = event.dayKey;
  if (isPaused(day, pauses)) return []; // SPEC: V20 → V79
  ensureDay(state, day);
  ensureWeek(state, day);
  const snapshot = snapshotOf(state);
  const streakBefore = state.currentStreak;
  const xp: Award[] = [];
  const flags: { comeback?: boolean; perfect?: boolean; shieldEarned?: boolean } = {};
  if (state.day.posts === 0) xp.push({ award: "xp", amount: SpecConstants.xpFirstPostOfDay, reason: "firstPostOfDay" }); // SPEC: V25, V70
  state.day.posts += 1;
  if (countsTheDay(event) && state.lastCountedDayKey !== day) {
    // SPEC: V82 — the first counted day after ≥ comebackMissedDaysThreshold missed planned days (R-069); never the first-ever
    flags.comeback = state.lastCountedDayKey !== null && missedDaysBetween(state.lastCountedDayKey, day, pauses, event) >= SpecConstants.comebackMissedDaysThreshold;
    state.currentStreak += SpecConstants.streakIncrementPerCountedDay; // SPEC: V02, V67, V72
    state.longestStreak = Math.max(state.longestStreak, state.currentStreak);
    state.lastCountedDayKey = day;
  }
  if (event.kind === "workout" && event.workoutCompleted === true) {
    // SPEC: V25, V70, V71, E7 — first completed workout on a planned day = +100; every other completed workout = +25
    const planned = event.isPlannedDay && state.day.workouts === 0;
    xp.push(planned ? { award: "xp", amount: SpecConstants.xpPlannedWorkout, reason: "plannedWorkout" } : { award: "xp", amount: SpecConstants.xpBonusWorkout, reason: "bonusWorkout" });
    state.day.workouts += 1;
  }
  if (event.kind === "meal") {
    if (state.day.meals < SpecConstants.mealXpDailyCap) xp.push({ award: "xp", amount: SpecConstants.xpMealPost, reason: "meal" }); // fixture-only since A22
    state.day.meals += 1;
  }
  if (flags.comeback) xp.push({ award: "xp", amount: SpecConstants.xpComeback, reason: "comeback" });
  addUnique(state.week.posted, day);
  if (event.isPlannedDay) addUnique(state.week.planned, day);
  if (event.isPlannedDay && event.kind === "workout" && event.workoutCompleted === true) addUnique(state.week.plannedDone, day);
  awardPerfectWeekIfEarned(state, event, xp, flags);
  (state.undo[day] ??= []).push(snapshot);
  return finishAwards(state, xp, streakBefore, flags);
}
