// SPEC: Flow 9 — LAYER 1 did I show up (heat map, rings history, streaks, totals, meals/week) · LAYER 2 how much work (sets/week,
// Push/Pull/Legs balance) · LAYER 3 am I stronger (only where weights were logged). Server-side facts for the web Progress page.
// A2/A6: sets = strength work sets; mobility and cardio are minutes per week (facts, never targets). A1: planned = trainingWeekdays.
import type { ObjectId } from "mongodb";
import { gamificationStates, posts, sessions } from "@/lib/db";
import type { ExerciseType, SessionDoc } from "@/lib/documents";
import { addDays, dayKeyFor, weekKeyFor } from "@/lib/engine/day-key";
import { workoutKindFromName } from "@/lib/engine/plan-rotation";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

const HEATMAP_WEEKS = SpecConstants.progressHeatMapWeeks;
const RING_WEEKS = SpecConstants.progressRingHistoryWeeks;

export interface DayCell { dayKey: string; workout: boolean; posted: boolean }
export interface WeekRecord { weekKey: string; done: number; planned: number; sets: number; meals: number; cardioMinutes: number; mobilityMinutes: number }
export interface ExerciseTrend { exerciseId: string; name: string; points: { dayKey: string; best: number }[] }

// Done, non-warm-up sets of one exercise type across a week's sessions
function doneSetsOf(weekSessions: SessionDoc[], type: ExerciseType) {
  return weekSessions.flatMap((session) => session.exercises.filter((exercise) => exercise.type === type)).flatMap((exercise) => exercise.sets).filter((set) => set.done && !set.isWarmup);
}

// SPEC: A2 — minutes are the sum of done hold/cardio seconds, rounded; a fact, never a target
const minutesOf = (sets: { holdSeconds: number | null }[]) => Math.round(sets.reduce((sum, set) => sum + (set.holdSeconds ?? 0), 0) / TimeUnits.secondsPerMinute);

function weekRecord(weekKey: string, completed: SessionDoc[], ownPosts: { dayKey: string; type: string }[], plannedWeekdays: number[]): WeekRecord {
  const inWeek = (dayKey: string) => dayKey >= weekKey && dayKey < addDays(weekKey, TimeUnits.daysPerWeek);
  const weekSessions = completed.filter((session) => inWeek(session.dayKey));
  return {
    weekKey, done: new Set(weekSessions.map((session) => session.dayKey)).size, planned: plannedWeekdays.length,
    sets: doneSetsOf(weekSessions, "strength").length, meals: ownPosts.filter((post) => post.type === "meal" && inWeek(post.dayKey)).length,
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

export async function progressFacts(userId: ObjectId, timezone: string, plannedWeekdays: number[], now: Date = new Date()) {
  const todayKey = dayKeyFor(now, timezone);
  const from = addDays(weekKeyFor(todayKey), -(HEATMAP_WEEKS - 1) * TimeUnits.daysPerWeek);
  const [completed, ownPosts, state] = await Promise.all([
    (await sessions()).find({ userId, status: "completed", dayKey: { $gte: from } }).sort({ dayKey: 1 }).toArray(),
    (await posts()).find({ userId, deletedAt: null, dayKey: { $gte: from } }, { projection: { dayKey: 1, type: 1 } }).toArray(),
    (await gamificationStates()).findOne({ userId }),
  ]);
  const workoutDays = new Set(completed.map((session) => session.dayKey));
  const postDays = new Set(ownPosts.map((post) => post.dayKey));
  const days: DayCell[] = [];
  for (let day = from; day <= todayKey; day = addDays(day, 1)) days.push({ dayKey: day, workout: workoutDays.has(day), posted: postDays.has(day) });
  const weeks: WeekRecord[] = [];
  for (let offset = RING_WEEKS - 1; offset >= 0; offset -= 1) weeks.push(weekRecord(addDays(weekKeyFor(todayKey), -offset * TimeUnits.daysPerWeek), completed, ownPosts, plannedWeekdays));
  return { todayKey, days, weeks, balance: balanceOf(completed), totals: { workouts: completed.length, posts: ownPosts.length, longestStreak: state?.longestStreak ?? 0, currentStreak: state?.currentStreak ?? 0 }, strength: strengthTrends(completed) };
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
