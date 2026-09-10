// SPEC: A12 — the prefill twin. Every assertion here has an identical assertion in
// ios/CrewTests/SetPrefillTests.swift: the two engines must open a row at the same numbers (8.1).
import { describe, expect, it } from "vitest";
import { openingReps, openingWeight, prefillFacts, type PrefillSet } from "@/lib/engine/set-prefill";

const work = (reps: number, weight: number | null, done = true): PrefillSet => ({ actualReps: reps, weight, done, isWarmup: false });

describe("prefillFacts", () => {
  it("has nothing to say with no history", () => {
    expect(prefillFacts([])).toBeNull();
  });

  it("takes the heaviest done work set of the most recent session", () => {
    expect(prefillFacts([[work(8, 135), work(6, 155), work(5, 145)]])).toEqual({ reps: 6, weight: 155, weightUnit: null });
  });

  it("ignores warm-ups, however heavy they look", () => {
    const sets: PrefillSet[] = [{ actualReps: 12, weight: 225, done: true, isWarmup: true }, work(8, 135)];
    expect(prefillFacts([sets])).toEqual({ reps: 8, weight: 135, weightUnit: null });
  });

  it("ignores rows that were never completed", () => {
    expect(prefillFacts([[work(8, 135), work(1, 315, false)]])).toEqual({ reps: 8, weight: 135, weightUnit: null });
  });

  it("falls through a session where the exercise was skipped entirely", () => {
    // newest first: the skipped session has no done rows, so the one before it wins
    expect(prefillFacts([[work(0, null, false)], [work(10, 95)]])).toEqual({ reps: 10, weight: 95, weightUnit: null });
  });

  it("carries reps forward for a bodyweight exercise that never has a weight", () => {
    expect(prefillFacts([[work(14, null)]])).toEqual({ reps: 14, weight: null, weightUnit: null });
  });

  it("carries the unit the weight was entered in", () => {
    expect(prefillFacts([[{ actualReps: 5, weight: 100, weightUnit: "kg", done: true, isWarmup: false }]]))
      .toEqual({ reps: 5, weight: 100, weightUnit: "kg" });
  });
});

describe("what a row opens at", () => {
  it("uses the plan's targets when there is no history — nothing regresses for a first-ever session", () => {
    expect(openingReps(10, null)).toBe(10);
    expect(openingWeight(null, null)).toBeNull();
  });

  it("lets reality beat the target once there is history", () => {
    const facts = prefillFacts([[work(6, 185)]]);
    expect(openingReps(10, facts)).toBe(6);
    expect(openingWeight(null, facts)).toBe(185);
  });

  it("keeps a null weight null — '—' is still a complete set forever", () => {
    const facts = prefillFacts([[work(12, null)]]);
    expect(openingWeight(null, facts)).toBeNull();
  });
});
