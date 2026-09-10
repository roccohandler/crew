// SPEC: Flow 3 (PR celebrations) · Flow 9 layer 3 (only where weights were logged — never logged weight → politely does not
// exist) · README kind achievements `prCount` · 5.6.1 Award.prBadge(exercise). A "new best" is a completed session whose best
// done work-set weight for an exercise beats every EARLIER completed session's best, where an earlier logged weight exists.
// A9 — every set carries the unit it was ENTERED in, and bests are compared on ONE normalised scale, so a preference
// change can never fire a false record or hide a real one. Pure. Twin: ios/Crew/Engine/PersonalRecords.swift.
import { normalizedForCompare, type WeightUnit } from "@/lib/engine/weight-units";

export interface RecordSet {
  done: boolean;
  isWarmup: boolean;
  weight: number | null;
  weightUnit?: WeightUnit; // A9: absent on a row logged before the split — falls back to the account's own unit
}

export interface RecordExercise {
  exerciseId: string;
  name: string;
  sets: RecordSet[];
}

export interface RecordSession {
  completedAt: string; // ISO instant — chronological order
  exercises: RecordExercise[];
}

// SPEC: A9 — the returned value is a COMPARISON scale (kilograms), never a number to display: two weights entered in
// different units are only orderable once normalised
export function bestWeight(sets: RecordSet[], accountUnit: WeightUnit = "lb"): number {
  return Math.max(0, ...sets.filter((set) => set.done && !set.isWarmup && set.weight !== null).map((set) => normalizedForCompare(set.weight ?? 0, set.weightUnit ?? accountUnit)));
}

// The exercises of `current` that set a new best against `earlier` (any order) — the celebration's PR badges
export function newRecords(current: RecordExercise[], earlier: RecordSession[], accountUnit: WeightUnit = "lb"): string[] {
  const records: string[] = [];
  for (const exercise of current) {
    const best = bestWeight(exercise.sets, accountUnit);
    if (best === 0) continue;
    const previousBest = Math.max(0, ...earlier.flatMap((session) => session.exercises.filter((row) => row.exerciseId === exercise.exerciseId).map((row) => bestWeight(row.sets, accountUnit))));
    if (previousBest > 0 && best > previousBest) records.push(exercise.name);
  }
  return records;
}

// Every (session, exercise) new best across a user's history, folded chronologically
export function prCount(sessions: RecordSession[], accountUnit: WeightUnit = "lb"): number {
  const chronological = [...sessions].sort((left, right) => left.completedAt.localeCompare(right.completedAt));
  let count = 0;
  for (let index = 0; index < chronological.length; index += 1) {
    const session = chronological[index];
    if (session !== undefined) count += newRecords(session.exercises, chronological.slice(0, index), accountUnit).length;
  }
  return count;
}
