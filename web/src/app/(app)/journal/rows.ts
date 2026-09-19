// SPEC: A6 — the Journal's rows, pure and server-only: one readable line per post (workout / cardio = the summary the server
// wrote at completion, else the same line computed from the session), a day's "Rest day" tag, and the days newest first. The page
// renders; this file decides the words. A22 (owner-approved 2026-09-18): the plate journal is gone — a legacy meal or text row
// (pre-A22) reads its caption, or the word "Post", and is never created again.
import type { SessionDoc } from "@/lib/documents";
import type { PostDoc } from "@/lib/documents-social";
import { completionFacts } from "@/lib/engine/completion";
import { weekKeyFor } from "@/lib/engine/day-key";
import { sessionSummaryLine, withoutWorkoutMinutes } from "@/lib/engine/session-summary-line";
import { isPlannedOn, type TrainingDaysEntry } from "@/lib/engine/training-days";

// SPEC: A6 — a workout post without a server summary (pre-A6) reads the same line computed from its session: sets from the
// completion facts (V32: warm-ups excluded); no minutes (A28 (c))
export function summaryFromSession(session: SessionDoc, distanceUnit: string): string {
  const facts = completionFacts(session.exercises.flatMap((exercise) => exercise.sets));
  return sessionSummaryLine(session.workoutName, session.workoutKind === "cardio", facts.setsDone, facts.setsPlanned, null, null, distanceUnit);
}

// SPEC: A6 · A14 — workout and cardio are two row types; both read the server summary the completion wrote ("Push day · 12 of 12
// sets" / "Walk · 25 min · 2.1 km"), so the words do not change — only which count each falls into. A22: a legacy row
// of a retired kind reads its caption.
// A28 (c) · R-086: a summary stored before A28 still carries the workout's minutes; it reads without them (nothing stored changes)
export function postLine(post: PostDoc, sessionLine: string | null): string {
  const stored = post.summary === undefined ? undefined : withoutWorkoutMinutes(post.summary);
  if (post.type === "workout") return stored ?? sessionLine ?? "Workout ✓";
  if (post.type === "cardio") return stored ?? sessionLine ?? "Cardio ✓";
  return post.caption || "Post";
}

// SPEC: A6 — "Rest day" tags a day that was not a training day and holds no workout (A1: rest = weekday ∉ trainingWeekdays)
// A14: cardio counts here exactly as it did when it WAS a "workout" post — a day you walked is not tagged "Rest day".
// The tag describes what you did, not what the plan scheduled, and this keeps the pre-A14 reading byte-identical.
// A27 (a): "a training day" is asked of the training days in effect ON that day, never of today's.
export function isRestDay(dayKey: string, dayPosts: PostDoc[], trainingDays: TrainingDaysEntry[]): boolean {
  return !isPlannedOn(trainingDays, dayKey) && !dayPosts.some((post) => post.type === "workout" || post.type === "cardio");
}

// The days that hold posts, newest first (a backfilled post sorts by its dayKey, not by when it was written)
export function dayKeysOf(docs: PostDoc[]): string[] {
  return [...new Set(docs.map((post) => post.dayKey))].sort((left, right) => right.localeCompare(left));
}

// SPEC: A6 — the days grouped under their week (weekHeader names it: This week · Last week · Week of Sep 1), newest first
export function weeksOf(dayKeys: string[]): { weekKey: string; dayKeys: string[] }[] {
  const weeks: { weekKey: string; dayKeys: string[] }[] = [];
  for (const dayKey of dayKeys) {
    const weekKey = weekKeyFor(dayKey);
    const last = weeks[weeks.length - 1];
    if (last && last.weekKey === weekKey) last.dayKeys.push(dayKey); else weeks.push({ weekKey, dayKeys: [dayKey] });
  }
  return weeks;
}
