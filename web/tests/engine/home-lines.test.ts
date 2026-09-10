// SPEC: A14 (owner-directed 2026-09-09) — Home shows the day's actual work. Twin of ios/CrewTests/HomeLinesTests.swift:
// the same cases and the same expected strings, so the card cannot read differently on the two platforms.
import { describe, expect, it } from "vitest";
import { setsByReps, strengthLines, tailLine, type HomeExercise } from "@/lib/engine/home-lines";

function exercise(name: string, over: Partial<HomeExercise> = {}): HomeExercise {
  return { name, type: "strength", targetSets: 3, targetReps: 8, targetRepsMax: null, holdSeconds: null, order: 0, ...over };
}

describe("setsByReps", () => {
  it("reads as a fixed count or a range", () => {
    expect(setsByReps(3, 8, null)).toBe("3×8");
    expect(setsByReps(3, 8, 10)).toBe("3×8–10");
    expect(setsByReps(1, 15, null)).toBe("1×15");
  });

  // A range whose ends are equal is not a range — it would read "3×8–8", which is noise
  it("collapses a range with equal ends", () => {
    expect(setsByReps(4, 12, 12)).toBe("4×12");
  });
});

describe("strengthLines", () => {
  it("keeps plan order and drops everything that is not a lift", () => {
    const rows = [
      exercise("Cable Fly", { order: 2 }),
      exercise("Pigeon", { type: "mobility", order: 5 }),
      exercise("Bench Press", { order: 0 }),
      exercise("Walk", { type: "cardio", holdSeconds: 1200, order: 6 }),
      exercise("Incline DB Press", { targetRepsMax: 10, order: 1 }),
    ];
    expect(strengthLines(rows)).toEqual([
      { name: "Bench Press", detail: "3×8" },
      { name: "Incline DB Press", detail: "3×8–10" },
      { name: "Cable Fly", detail: "3×8" },
    ]);
  });

  it("does not mutate the array it was handed", () => {
    const rows = [exercise("Cable Fly", { order: 2 }), exercise("Bench Press", { order: 0 })];
    strengthLines(rows);
    expect(rows.map((row) => row.name)).toEqual(["Cable Fly", "Bench Press"]);
  });
});

describe("tailLine", () => {
  // A8 — a pure-lifting day says nothing rather than saying "0 holds"
  it("is absent when there is nothing to tail", () => {
    expect(tailLine([exercise("Bench Press")])).toBeNull();
    expect(tailLine([])).toBeNull();
  });

  it("names mobility then cardio", () => {
    const holds = [exercise("Pigeon", { type: "mobility", holdSeconds: 30 }), exercise("Couch", { type: "mobility", holdSeconds: 30 })];
    expect(tailLine(holds)).toBe("+ mobility · 2 holds");
    expect(tailLine([exercise("Pigeon", { type: "mobility", holdSeconds: 30 })])).toBe("+ mobility · 1 hold");
    expect(tailLine([...holds, exercise("Walk", { type: "cardio", holdSeconds: 1200 })])).toBe("+ mobility · 2 holds · cardio · 20 min");
  });

  // A2 — cardio seconds round exactly the way the server and JournalFacts round (90 s → 2 min, not 1)
  it("rounds cardio minutes half-up like everything else", () => {
    expect(tailLine([exercise("Row", { type: "cardio", holdSeconds: 90 })])).toBe("+ cardio · 2 min");
    expect(tailLine([exercise("Row", { type: "cardio", holdSeconds: 89 })])).toBe("+ cardio · 1 min");
  });

  // A14 — a mobility block with no seconds still counts as a hold: the tail names WHAT is there, not how long
  it("counts a hold that carries no seconds", () => {
    expect(tailLine([exercise("Pigeon", { type: "mobility", holdSeconds: null })])).toBe("+ mobility · 1 hold");
  });
});
