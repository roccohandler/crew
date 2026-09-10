// SPEC: Flow 3 "Pre-fill from reality — rows load your last ACTUAL performance" · A12 (owner-directed 2026-09-09). Until
// now that promise was only DISPLAYED: the last-time line computed the previous session's real reps and weight, rendered
// them as a grey caption, and threw the numbers away — every strength set still opened at "—", so reaching 225 lb cost 45
// taps. This is the same lookup, used. A9: the unit the weight was entered in carries forward with it, so a prefilled row
// is never silently reinterpreted. Pure — the caller supplies the history. Twin of ios/Crew/Engine/SetPrefill.swift.

export interface PrefillFacts {
  reps: number;
  weight: number | null;
  weightUnit: "lb" | "kg" | null;
}

export interface PrefillSet {
  actualReps: number;
  weight: number | null;
  weightUnit?: "lb" | "kg";
  done: boolean;
  isWarmup: boolean;
}

// SPEC: A12 — the heaviest DONE WORK set of the most recent session that has one. Warm-ups never count (Flow 3 excludes
// them from every number), and an undone row is not a performance. Sessions arrive newest first; the first one with a
// usable row wins, so a session where the exercise was skipped falls through to the one before it.
export function prefillFacts(sessions: PrefillSet[][]): PrefillFacts | null {
  for (const sets of sessions) {
    const done = sets.filter((set) => set.done && !set.isWarmup);
    if (done.length === 0) continue;
    // Heaviest first; a bodyweight exercise has no weight at all, so its reps still carry forward
    const heaviest = done.reduce((best, set) => ((set.weight ?? 0) > (best.weight ?? 0) ? set : best));
    return { reps: heaviest.actualReps, weight: heaviest.weight, weightUnit: heaviest.weightUnit ?? null };
  }
  return null;
}

// SPEC: A12 — what a new row opens at. With no history the plan's targets stand exactly as before (nothing regresses for a
// first-ever session); with history, reality wins. A weight of null stays null — "—" is still a complete set forever for an
// exercise that has never carried a number.
export function openingReps(targetReps: number, facts: PrefillFacts | null): number {
  return facts?.reps ?? targetReps;
}

export function openingWeight(targetWeight: number | null, facts: PrefillFacts | null): number | null {
  return facts?.weight ?? targetWeight;
}
