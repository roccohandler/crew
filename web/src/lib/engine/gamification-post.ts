// SPEC: README "postCreated" — the first post of a day counts it (streak + 1, +25); kind XP (planned +100 first completed
// workout, +25 further/rest-day, meals +15 ×3, text 0); comeback after ≥3 quiet non-paused days (V29); perfect week per
// G6 (every day posted, every planned day's workout done, ≥1 planned day) → +150 + shield (V13, V28); levels G2.
// Twin: ios/Crew/Engine/GamificationPost.swift.
import type { Award, GameEvent, GamificationState, Pause } from "@/lib/engine/gamification";
import { isPaused, levelFor } from "@/lib/engine/gamification";
import { addDays, weekKeyFor } from "@/lib/engine/day-key";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

type PostEvent = Extract<GameEvent, { type: "postCreated" }>;

export function quietDaysBetween(fromDayKey: string, toDayKey: string, pauses: Pause[]): number {
  let quiet = 0;
  for (let day = addDays(fromDayKey, 1); day < toDayKey; day = addDays(day, 1)) if (!isPaused(day, pauses)) quiet += 1;
  return quiet;
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

// SPEC: V13, V14, V28 — +150 always; the shield only below the cap; once per week
function awardPerfectWeekIfEarned(state: GamificationState, xp: Award[], flags: { perfect?: boolean; shieldEarned?: boolean }): void {
  if (!weekIsPerfect(state)) return;
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

// SPEC: G6 — perfect week: every day posted AND every planned day workout-completed AND ≥1 planned day; once per week
function weekIsPerfect(state: GamificationState): boolean {
  if (state.week.key === null || state.week.awarded) return false;
  const everyDayPosted = Array.from({ length: TimeUnits.daysPerWeek }, (_, offset) => addDays(state.week.key as string, offset)).every((day) => state.week.posted.includes(day));
  return everyDayPosted && state.week.planned.length >= 1 && state.week.planned.every((day) => state.week.plannedDone.includes(day));
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
  if (isPaused(day, pauses)) return []; // SPEC: V20
  ensureDay(state, day);
  ensureWeek(state, day);
  const snapshot = snapshotOf(state);
  const streakBefore = state.currentStreak;
  const xp: Award[] = [];
  const flags: { comeback?: boolean; perfect?: boolean; shieldEarned?: boolean } = {};
  if (state.day.posts === 0) {
    // SPEC: V29 / V39 — the first post after ≥ comebackMissedDaysThreshold quiet days; never the first-ever post
    flags.comeback = state.lastCountedDayKey !== null && quietDaysBetween(state.lastCountedDayKey, day, pauses) >= SpecConstants.comebackMissedDaysThreshold;
    state.currentStreak += SpecConstants.streakIncrementPerCountedDay; // SPEC: V01, V02, V11
    state.longestStreak = Math.max(state.longestStreak, state.currentStreak);
    state.lastCountedDayKey = day;
    xp.push({ award: "xp", amount: SpecConstants.xpFirstPostOfDay, reason: "firstPostOfDay" }); // SPEC: V24
  }
  state.day.posts += 1;
  if (event.kind === "workout" && event.workoutCompleted === true) {
    // SPEC: V25, V30, V31, E7 — first completed workout on a planned day = +100; every other completed workout = +25
    const planned = event.isPlannedDay && state.day.workouts === 0;
    xp.push(planned ? { award: "xp", amount: SpecConstants.xpPlannedWorkout, reason: "plannedWorkout" } : { award: "xp", amount: SpecConstants.xpBonusWorkout, reason: "bonusWorkout" });
    state.day.workouts += 1;
  }
  if (event.kind === "meal") {
    if (state.day.meals < SpecConstants.mealXpDailyCap) xp.push({ award: "xp", amount: SpecConstants.xpMealPost, reason: "meal" }); // SPEC: V26
    state.day.meals += 1;
  }
  if (flags.comeback) xp.push({ award: "xp", amount: SpecConstants.xpComeback, reason: "comeback" });
  addUnique(state.week.posted, day);
  if (event.isPlannedDay) addUnique(state.week.planned, day);
  if (event.isPlannedDay && event.kind === "workout" && event.workoutCompleted === true) addUnique(state.week.plannedDone, day);
  awardPerfectWeekIfEarned(state, xp, flags);
  (state.undo[day] ??= []).push(snapshot);
  return finishAwards(state, xp, streakBefore, flags);
}
