// SPEC: A11 (owner-directed 2026-09-09) — a set can be removed. Owner-reported: "there should be an area to remove a set
// for a user"; before this, one accidental tap on "+ set" permanently changed the workout's denominator, which feeds the
// live x/y line, the celebration, the shared post summary and the journal forever.
//
// Two rules make removal safe rather than merely possible:
//   ① the remaining rows are renumbered from zero, so `order` stays dense and a later patch cannot address a hole;
//   ② an exercise never drops below one set — Flow 3's whole model is that a set row IS the exercise, and an exercise with
//      no rows could neither be logged nor skipped. The floor counts WORK sets: deleting the last work set is refused even
//      when warm-ups remain, because warm-ups are excluded from every count (x/y, completion, PRs).
// Pure, and CONCRETE (C1: no generics in app code) — the same shape the Swift twin takes.
// Twin of ios/Crew/Engine/SetRemoval.swift.

export interface RemovableSet {
  order: number;
  isWarmup: boolean;
}

export interface RemovalResult {
  removed: boolean;
  sets: RemovableSet[];
}

// SPEC: A11 — remove the row at `order`, renumber the rest from zero, and refuse the removal that would leave no work set
export function removeSet(sets: RemovableSet[], order: number): RemovalResult {
  const ordered = [...sets].sort((left, right) => left.order - right.order);
  const target = ordered.find((set) => set.order === order);
  if (target === undefined) return { removed: false, sets: ordered };
  const workSets = ordered.filter((set) => !set.isWarmup).length;
  if (!target.isWarmup && workSets <= 1) return { removed: false, sets: ordered }; // ② the floor
  const kept = ordered.filter((set) => set.order !== order);
  return { removed: true, sets: kept.map((set, index) => ({ ...set, order: index })) }; // ① dense again
}

// SPEC: A11 — what the x/y denominator becomes after a removal: work sets only, warm-ups never (Flow 3)
export function setsPlanned(sets: RemovableSet[]): number {
  return sets.filter((set) => !set.isWarmup).length;
}
