// SPEC: V32 (≥1 work set done = complete) · V33 (done and asPlanned recorded separately) · Flow 3 (warm-up rows are
// excluded from every count; "—" is a complete set — weight plays no part). Twin: ios/Crew/Engine/Completion.swift.
export interface SetFacts {
  targetReps: number;
  actualReps: number;
  done: boolean;
  isWarmup: boolean;
}

export interface CompletionFacts {
  complete: boolean;
  setsDone: number;
  setsPlanned: number;
  setsAsPlanned: number;
  sets: { done: boolean; asPlanned: boolean }[];
}

export function asPlanned(set: SetFacts): boolean {
  return set.done && set.actualReps >= set.targetReps;
}

export function completionFacts(sets: SetFacts[]): CompletionFacts {
  const work = sets.filter((set) => !set.isWarmup);
  const setsDone = work.filter((set) => set.done).length;
  return {
    complete: setsDone >= 1,
    setsDone,
    setsPlanned: work.length,
    setsAsPlanned: work.filter(asPlanned).length,
    sets: sets.map((set) => ({ done: set.done, asPlanned: asPlanned(set) })),
  };
}
