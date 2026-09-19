// SPEC: Flow 9 — LAYER 1 did I show up (heat map, rings history, streaks, totals; A22: meals/week left with the plate journal) · LAYER 2 how much work (sets/week,
// Push/Pull/Legs balance) · LAYER 3 am I stronger (only where weights were logged). Server-side facts for the web Progress page.
// A2/A6: sets = strength work sets; mobility and cardio are minutes per week (facts, never targets). A1 · A27 (a): planned = the
// days the training days in effect on each of them plan.
import type { ObjectId } from "mongodb";
import { gamificationStates, pauses, posts, sessions } from "@/lib/db";
import type { ExerciseType, SessionDoc } from "@/lib/documents";
import { addDays, dayKeyFor, daysBetween, weekKeyFor } from "@/lib/engine/day-key";
import { workoutKindFromName } from "@/lib/engine/plan-rotation";
import { isPlannedOn, type TrainingDaysEntry } from "@/lib/engine/training-days";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

const HEATMAP_WEEKS = SpecConstants.progressHeatMapWeeks;
const RING_WEEKS = SpecConstants.progressRingHistoryWeeks;

// A14: three marks, not two — a walk is no longer counted as a workout (it used to write a "workout" post, so every
// count of workouts silently included cardio). Same hue, different fill treatment: law ⑥ gains no second colour.
export interface DayCell { dayKey: string; workout: boolean; cardio: boolean; posted: boolean }
export interface WeekRecord { weekKey: string; done: number; planned: number; sets: number; cardioMinutes: number; mobilityMinutes: number }
export interface ExerciseTrend { exerciseId: string; name: string; points: { dayKey: string; best: number }[] }

// Done, non-warm-up sets of one exercise type across a week's sessions
function doneSetsOf(weekSessions: SessionDoc[], type: ExerciseType) {
  return weekSessions.flatMap((session) => session.exercises.filter((exercise) => exercise.type === type)).flatMap((exercise) => exercise.sets).filter((set) => set.done && !set.isWarmup);
}

// SPEC: A2 — minutes are the sum of done hold/cardio seconds, rounded; a fact, never a target
const minutesOf = (sets: { holdSeconds: number | null }[]) => Math.round(sets.reduce((sum, set) => sum + (set.holdSeconds ?? 0), 0) / TimeUnits.secondsPerMinute);

// SPEC: A1 · A27 (a) — a week's planned count is its days that the training days in effect ON each of them plan
function weekRecord(weekKey: string, completed: SessionDoc[], trainingDays: TrainingDaysEntry[]): WeekRecord {
  const inWeek = (dayKey: string) => dayKey >= weekKey && dayKey < addDays(weekKey, TimeUnits.daysPerWeek);
  const weekSessions = completed.filter((session) => inWeek(session.dayKey));
  const planned = Array.from({ length: TimeUnits.daysPerWeek }, (_, offset) => addDays(weekKey, offset)).filter((day) => isPlannedOn(trainingDays, day)).length;
  return {
    weekKey, done: new Set(weekSessions.map((session) => session.dayKey)).size, planned,
    sets: doneSetsOf(weekSessions, "strength").length,
    cardioMinutes: minutesOf(doneSetsOf(weekSessions, "cardio")), mobilityMinutes: minutesOf(doneSetsOf(weekSessions, "mobility")),
  };
}

// SPEC: Flow 9 layer 2 — Push/Pull/Legs balance by the session's kind (legacy sessions infer it from the name, A1); a standalone
// cardio log is not a split day
function balanceOf(completed: SessionDoc[]) {
  const balance = { push: 0, pull: 0, legs: 0, fullBody: 0 };
  for (const session of completed) {
    const kind = session.workoutKind ?? workoutKindFromName(session.workoutName);
    if (kind === "cardio") continue;
    if (kind === "push") balance.push += 1; else if (kind === "pull") balance.pull += 1; else if (kind === "legs") balance.legs += 1; else balance.fullBody += 1;
  }
  return balance;
}

export async function progressFacts(userId: ObjectId, timezone: string, trainingDays: TrainingDaysEntry[], now: Date = new Date()) {
  const todayKey = dayKeyFor(now, timezone);
  const from = addDays(weekKeyFor(todayKey), -(HEATMAP_WEEKS - 1) * TimeUnits.daysPerWeek);
  const [completed, ownPosts, state] = await Promise.all([
    (await sessions()).find({ userId, status: "completed", dayKey: { $gte: from } }).sort({ dayKey: 1 }).toArray(),
    (await posts()).find({ userId, deletedAt: null, dayKey: { $gte: from } }, { projection: { dayKey: 1, type: 1 } }).toArray(),
    (await gamificationStates()).findOne({ userId }),
  ]);
  const workoutDays = new Set(completed.filter((session) => session.workoutKind !== "cardio").map((session) => session.dayKey));
  const cardioDays = new Set(completed.filter((session) => session.workoutKind === "cardio").map((session) => session.dayKey));
  const postDays = new Set(ownPosts.map((post) => post.dayKey));
  const days: DayCell[] = [];
  for (let day = from; day <= todayKey; day = addDays(day, 1)) days.push({ dayKey: day, workout: workoutDays.has(day), cardio: cardioDays.has(day), posted: postDays.has(day) });
  const weeks: WeekRecord[] = [];
  for (let offset = RING_WEEKS - 1; offset >= 0; offset -= 1) weeks.push(weekRecord(addDays(weekKeyFor(todayKey), -offset * TimeUnits.daysPerWeek), completed, trainingDays));
  // A14: `workouts` counts workouts — a standalone cardio session is not one. It used to be, because a cardio log wrote a
  // post of type "workout"; the totals line on Progress therefore reported walks as workouts.
  const workoutTotal = completed.filter((session) => session.workoutKind !== "cardio").length;
  return { todayKey, days, weeks, balance: balanceOf(completed), totals: { workouts: workoutTotal, posts: ownPosts.length, longestStreak: state?.longestStreak ?? 0, currentStreak: state?.currentStreak ?? 0 }, strength: strengthTrends(completed) };
}

// LAYER 3 — only where weights were logged: never logged weight → politely doesn't exist
function strengthTrends(completed: { dayKey: string; exercises: { exerciseId: string; name: string; sets: { done: boolean; weight: number | null }[] }[] }[]): ExerciseTrend[] {
  const trends = new Map<string, ExerciseTrend>();
  for (const session of completed) {
    for (const exercise of session.exercises) {
      const weights = exercise.sets.filter((set) => set.done && set.weight !== null).map((set) => set.weight ?? 0);
      if (weights.length === 0) continue;
      const trend = trends.get(exercise.exerciseId) ?? { exerciseId: exercise.exerciseId, name: exercise.name, points: [] };
      trend.points.push({ dayKey: session.dayKey, best: Math.max(...weights) });
      trends.set(exercise.exerciseId, trend);
    }
  }
  return [...trends.values()];
}

// SPEC: A28 (e) (owner-approved 2026-09-19) — "This season · N weeks · N workouts": a LABEL, no engine rule, no vector, no stored
// field. GAP 10 read conservatively (R-086): a season starts at the plan's first training-days entry (its build, A27 (a)) or at the
// end of the latest pause that has run its course, whichever is later; a days change never restarts it. Weeks are the calendar
// weeks it touches, this one included; workouts are completed workouts (a standalone cardio log is not one, A14).
// Twin of ios/Crew/Features/Progress/SeasonFacts.swift — identical cases in both suites.
export interface SeasonFacts { startDayKey: string; weeks: number; workouts: number }

export function seasonFacts(history: TrainingDaysEntry[], endedPauseDays: string[], workoutDayKeys: string[], todayKey: string): SeasonFacts | null {
  const built = history[0]?.from;
  if (built === undefined || built > todayKey) return null;
  const pauseEnd = endedPauseDays.filter((day) => day <= todayKey).sort().pop();
  const start = pauseEnd !== undefined && pauseEnd > built ? pauseEnd : built;
  const weeks = daysBetween(weekKeyFor(start), weekKeyFor(todayKey)) / TimeUnits.daysPerWeek + 1;
  return { startDayKey: start, weeks, workouts: workoutDayKeys.filter((day) => day >= start && day <= todayKey).length };
}

export function seasonLine(facts: SeasonFacts): string {
  return `This season · ${facts.weeks} ${facts.weeks === 1 ? "week" : "weeks"} · ${facts.workouts} ${facts.workouts === 1 ? "workout" : "workouts"}`;
}

// SPEC: A28 (e) · GAP 10 (R-086) — the season from what the server holds: the plan's history, every pause that has run its course
// (the server keeps an early end as endDay = that day, which the phone does not — docs/debt.md), and the completed workouts since
export async function seasonOf(userId: ObjectId, trainingDays: TrainingDaysEntry[], todayKey: string): Promise<SeasonFacts | null> {
  const ended = (await (await pauses()).find({ userId, endDay: { $lte: todayKey } }, { projection: { endDay: 1 } }).toArray()).map((doc) => doc.endDay);
  const start = seasonFacts(trainingDays, ended, [], todayKey)?.startDayKey;
  if (start === undefined) return null;
  const workouts = await (await sessions()).find({ userId, status: "completed", workoutKind: { $ne: "cardio" }, dayKey: { $gte: start, $lte: todayKey } }, { projection: { dayKey: 1 } }).toArray();
  return seasonFacts(trainingDays, ended, workouts.map((doc) => doc.dayKey), todayKey);
}
