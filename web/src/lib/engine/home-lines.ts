// SPEC: A14 (owner-directed 2026-09-09) — Home shows the day's ACTUAL work, not its size. Owner-reported: "it's not clear
// visually what the work should be". Before this, the card read "5 exercises + mobility" — a measurement of the workout
// rather than the workout — while the plan editor two taps away listed every row.
//
// C5 governs the sets×reps phrase: this is its THIRD occurrence (web GeneratedPlan.targetsLabel, iOS
// WorkoutDraftText.repsText, now Home), so it is extracted here into a plain function and GeneratedPlan delegates to it.
// Pure and CONCRETE (C1: no generics) — the same shape the Swift twin takes.
// Twin of ios/Crew/Engine/HomeLines.swift.
import { TimeUnits } from "@/lib/time-units";

export interface HomeExercise {
  name: string;
  type: string; // strength | mobility | cardio (A2)
  targetSets: number;
  targetReps: number;
  targetRepsMax: number | null;
  holdSeconds: number | null;
  order: number;
}

export interface HomeLine {
  name: string;
  detail: string;
}

// SPEC: A14 · A4 — "3×8", or "3×8–10" when the row carries a rep range
export function setsByReps(targetSets: number, targetReps: number, targetRepsMax: number | null): string {
  const reps = targetRepsMax === null || targetRepsMax === targetReps ? `${targetReps}` : `${targetReps}–${targetRepsMax}`;
  return `${targetSets}×${reps}`;
}

// SPEC: A14 — the strength rows in plan order; mobility and cardio are the tail line, never rows of their own, so the card
// stays the length of the actual lifting
export function strengthLines(exercises: HomeExercise[]): HomeLine[] {
  return [...exercises]
    .filter((exercise) => exercise.type === "strength")
    .sort((left, right) => left.order - right.order)
    .map((exercise) => ({ name: exercise.name, detail: setsByReps(exercise.targetSets, exercise.targetReps, exercise.targetRepsMax) }));
}

// SPEC: A2 — cardio and mobility seconds → minutes, rounded exactly the way the server and JournalFacts round
function minutesOf(seconds: number): number {
  return Math.round(seconds / TimeUnits.secondsPerMinute);
}

// SPEC: A14 · A2 — "+ mobility · 3 holds" / "+ mobility · 3 holds · cardio · 20 min"; null when the workout is pure lifting
// (a zero is never a verdict, A8 — an absent tail says nothing rather than saying "0 holds")
export function tailLine(exercises: HomeExercise[]): string | null {
  const holds = exercises.filter((exercise) => exercise.type === "mobility").length;
  const cardioSeconds = exercises.filter((exercise) => exercise.type === "cardio").reduce((total, exercise) => total + (exercise.holdSeconds ?? 0), 0);
  const parts: string[] = [];
  if (holds > 0) parts.push(`mobility · ${holds} ${holds === 1 ? "hold" : "holds"}`);
  if (cardioSeconds > 0) parts.push(`cardio · ${minutesOf(cardioSeconds)} min`);
  return parts.length === 0 ? null : `+ ${parts.join(" · ")}`;
}
