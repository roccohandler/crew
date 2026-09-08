// SPEC: Flow 3 (PR celebrations) · Flow 9 layer 3 (only where weights were logged — never logged weight → politely does not
// exist) · README kind achievements `prCount` · 5.6.1 Award.prBadge(exercise). A "new best" is a completed session whose best
// done work-set weight for an exercise beats every EARLIER completed session's best, where an earlier logged weight exists.
// Pure. Twin: ios/Crew/Engine/PersonalRecords.swift.

export interface RecordSet {
  done: boolean;
  isWarmup: boolean;
  weight: number | null;
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

export function bestWeight(sets: RecordSet[]): number {
  return Math.max(0, ...sets.filter((set) => set.done && !set.isWarmup && set.weight !== null).map((set) => set.weight ?? 0));
}

// The exercises of `current` that set a new best against `earlier` (any order) — the celebration's PR badges
export function newRecords(current: RecordExercise[], earlier: RecordSession[]): string[] {
  const records: string[] = [];
  for (const exercise of current) {
    const best = bestWeight(exercise.sets);
    if (best === 0) continue;
    const previousBest = Math.max(0, ...earlier.flatMap((session) => session.exercises.filter((row) => row.exerciseId === exercise.exerciseId).map((row) => bestWeight(row.sets))));
    if (previousBest > 0 && best > previousBest) records.push(exercise.name);
  }
  return records;
}

// Every (session, exercise) new best across a user's history, folded chronologically
export function prCount(sessions: RecordSession[]): number {
  const chronological = [...sessions].sort((left, right) => left.completedAt.localeCompare(right.completedAt));
  let count = 0;
  for (let index = 0; index < chronological.length; index += 1) {
    const session = chronological[index];
    if (session !== undefined) count += newRecords(session.exercises, chronological.slice(0, index)).length;
  }
  return count;
}
