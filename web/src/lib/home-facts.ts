// SPEC: A14 · A18.6a · A18.7 · A18.9 — the facts Home REPORTS, as opposed to the state it is IN: today's three
// logging vectors, the week's seven marks with their done/planned counts, and what today actually held.
//
// Twin of ios Features/Home/HomeModel+Facts.swift, split from today-state.ts for the same reason that file is split
// from HomeModel.swift: the state machine answers "what day is this", these answer "what is there to report".
import type { ObjectId } from "mongodb";
import { posts, sessions } from "@/lib/db";
import { addDays, isoWeekday, weekKeyFor } from "@/lib/engine/day-key";
import { TimeUnits } from "@/lib/time-units";

// SPEC: A14 — today's state for each of the three logging vectors. A measurement or nothing: `null`/false renders as
// an invitation to log, never as a zero and never as "0/3" (A8, the same rule that strips the ring off the bridge).
// Twin of ios VectorSlots.
export interface VectorSlots { workoutDone: boolean; cardioMinutes: number | null; meals: number }

// SPEC: A18.9 · A6 — what today actually held, in the sentence the journal already prints. The line is the one the
// server STORED on the post at completion (lib/sessions.ts summaryFor), so this reads a fact rather than recomputing
// one, and the all-done card, the journal and Progress can never disagree. Twin of ios HomeModel.todaySummary.
export async function todaySummary(userId: ObjectId, todayKey: string): Promise<string[]> {
  const rows = await (await posts())
    .find({ userId, dayKey: todayKey, deletedAt: null, type: { $in: ["workout", "cardio"] } }, { projection: { summary: 1, createdAt: 1 } })
    .sort({ createdAt: 1 })
    .toArray();
  return rows.map((row) => row.summary ?? "").filter((line) => line.length > 0);
}

// SPEC: A14 — today per vector, the server twin of ios HomeModel.slots. A completed session of kind `cardio` is CARDIO,
// not a workout: the same split A14 gives the post type, the journal row and the heat map. Ritual equality, never a score.
export async function vectorSlots(userId: ObjectId, todayKey: string): Promise<VectorSlots> {
  const [completed, mealCount] = await Promise.all([
    (await sessions()).find({ userId, status: "completed", dayKey: todayKey }, { projection: { workoutKind: 1, exercises: 1 } }).toArray(),
    (await posts()).countDocuments({ userId, dayKey: todayKey, type: "meal", deletedAt: null }),
  ]);
  const cardioSeconds = completed
    .filter((session) => session.workoutKind === "cardio")
    .flatMap((session) => session.exercises.filter((row) => row.type === "cardio").flatMap((row) => row.sets))
    .filter((set) => set.done && !set.isWarmup)
    .reduce((total, set) => total + (set.holdSeconds ?? 0), 0);
  return {
    workoutDone: completed.some((session) => session.workoutKind !== "cardio"),
    cardioMinutes: cardioSeconds > 0 ? Math.round(cardioSeconds / TimeUnits.secondsPerMinute) : null,
    meals: mealCount,
  };
}

// SPEC: Flow 2 — done/planned this week; a standalone cardio log (A2) never fills a planned slot.
//
// A18.7 — THE MARKS ARE COMPUTED HERE, not in the component, exactly as ios HomeModel.weekMarks computes them in the
// model. WeekStrip used to derive its own marks from `projectWeek`'s states, which tested the day's COMPLETION before
// the training-day guard and so emitted "done" for a bonus workout on a non-training day — while this function, which
// feeds the ring, counted planned days only. One user, two answers, and two different summary sentences out of the
// same WeekSummary twin ("Wed, Sat done" on web, "Wed done" on iOS). The trainingWeekdays guard comes FIRST on both
// engines now: the ring counts planned days, so a strip that marked an unplanned completion could not be read against
// it — and A18.1 puts the word "workouts" beside the ring, which is what makes that readable pairing the point.
//
// A18.7 also marks EVERY planned day rather than only the next one (`upcoming` after `nextUp`): A17.4 left a plan
// training four days a week with a ring saying "of 4" and a strip that could account for at most three of them.
//
// A18.6a — PAUSE-AWARE. A planned day inside an active pause window is never `missed` and never counts toward
// `planned`: Flow 7 and spec:460 promise "pauses without penalty", and A17.1 turned these marks into the English
// sentence "This week: Mon missed", printed directly above a card saying the streak is frozen.
export async function weekMarks(userId: ObjectId, plannedWeekdays: number[], todayKey: string, pause: { startDay: string; endDay: string } | null): Promise<{ marks: string[]; done: number; planned: number }> {
  const weekKey = weekKeyFor(todayKey);
  const days = Array.from({ length: TimeUnits.daysPerWeek }, (_, offset) => addDays(weekKey, offset));
  const completed = await (await sessions()).find({ userId, status: "completed", dayKey: { $in: days }, workoutKind: { $ne: "cardio" } }, { projection: { dayKey: 1 } }).toArray();
  const doneDays = new Set(completed.map((session) => session.dayKey));
  let done = 0;
  let planned = 0;
  const marks: string[] = days.map((day) => {
    const isToday = day === todayKey;
    const frozen = pause !== null && day >= pause.startDay && day < pause.endDay;
    if (!plannedWeekdays.includes(isoWeekday(day)) || frozen) return isToday ? "today" : "rest";
    planned += 1;
    if (doneDays.has(day)) { done += 1; return "done"; }
    if (isToday) return "today";
    return day < todayKey ? "missed" : "upcoming";
  });
  const next = marks.indexOf("upcoming");
  if (next >= 0) marks[next] = "nextUp";
  return { marks, done, planned };
}
