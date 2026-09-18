// SPEC: T020 (Verify: both unit suites) · 8.3 plan generator property test: every days × experience combo yields a valid plan
// (limits respected, mobility block present) · A21.1 (owner-approved 2026-09-17): the equipment axis is gone — every user trains
// in a full gym, so a row's equipment is any of the five tags · A1 (owner-directed 2026-09-08): every combination yields exactly
// the pplCycle's kinds once, in order, at every day count — Full-Body A/B is never generated · A26 (owner-approved 2026-09-18,
// canonical templates): the rows are the owner's own Push, Pull and Legs at EVERY experience; experience changes the sets only.
import { describe, expect, it } from "vitest";
import { cardioRow, generatePlan, type SeedCatalog } from "@/lib/engine/plan-generator";
import { exercises, planTemplates, type Equipment, type Experience, type TemplateKind } from "@/generated/seed";
import { SpecConstants } from "@/generated/spec-constants";

const seed: SeedCatalog = { exercises, planTemplates };
const experiences: Experience[] = ["brandNew", "some", "experienced"];
const equipmentTags: Equipment[] = ["barbell", "dumbbell", "machine", "cable", "bodyweight"];
const countFor: Record<TemplateKind, number> = { push: SpecConstants.templatePushExerciseCount, pull: SpecConstants.templatePullExerciseCount, legs: SpecConstants.templateLegsExerciseCount };
const setsFor: Record<Experience, number> = { brandNew: SpecConstants.beginnerTargetSets, some: SpecConstants.someExperienceTargetSets, experienced: SpecConstants.experiencedTargetSets };

// every non-empty subset of Mon..Sun (127 of them)
function daySubsets(): number[][] {
  const subsets: number[][] = [];
  for (let mask = 1; mask < 1 << 7; mask += 1) subsets.push([1, 2, 3, 4, 5, 6, 7].filter((_, index) => (mask & (1 << index)) !== 0));
  return subsets;
}

describe("generatePlan — every days × experience combination is a valid PPL plan (A1, A21.1)", () => {
  const subsets = daySubsets();
  it("covers 127 day subsets × 3 experiences = 381 plans", () => {
    expect(subsets.length * experiences.length).toBe(381);
  });

  for (const experience of experiences) {
    it(`${experience}`, () => {
      for (const days of subsets) {
        const plan = generatePlan(days, experience, seed);
        expect(plan.trainingWeekdays).toEqual([...days].sort((a, b) => a - b));
        expect(plan.workouts.map((workout) => workout.kind)).toEqual(planTemplates.split.pplCycle);
        expect(plan.workouts.map((workout) => workout.kind)).toEqual(["push", "pull", "legs"]);
        expect(plan.workouts.map((workout) => workout.name)).toEqual(["Push day", "Pull day", "Leg day"]);
        for (const workout of plan.workouts) {
          const strength = workout.exercises.filter((row) => row.type === "strength");
          const holds = workout.exercises.filter((row) => row.type === "mobility");
          expect(strength).toHaveLength(countFor[workout.kind as TemplateKind]);
          for (const row of strength) expect([row.targetSets, row.targetReps, row.targetRepsMax]).toEqual([setsFor[experience], SpecConstants.templateTargetReps, undefined]); // A26: sets by experience × 8, no range
          expect(workout.exercises.length).toBeLessThanOrEqual(SpecConstants.planMaxExercisesPerDay);
          expect(holds.length).toBeGreaterThanOrEqual(SpecConstants.mobilityHoldsMin);
          expect(holds.length).toBeLessThanOrEqual(SpecConstants.mobilityHoldsMax);
          const holdSeconds = holds.reduce((sum, row) => sum + (row.holdSeconds ?? 0) * (row.perSide ? 2 : 1), 0);
          expect(holdSeconds).toBeGreaterThanOrEqual(SpecConstants.mobilityMinutesMin * 60);
          expect(holdSeconds).toBeLessThanOrEqual(SpecConstants.mobilityMinutesMax * 60);
          for (const row of workout.exercises) {
            expect(row.name.length).toBeLessThanOrEqual(SpecConstants.exerciseNameMaxChars);
            expect(row.targetSets).toBeLessThanOrEqual(SpecConstants.planMaxSetsPerExercise);
            expect(equipmentTags).toContain(row.equipment); // A21.1: the tag stays; the tier is gone
          }
          expect(workout.exercises.map((row) => row.order)).toEqual(workout.exercises.map((_, index) => index));
          expect(workout.exercises.some((row) => row.type === "cardio")).toBe(false); // cardio blocks are added by the editor, never generated
        }
      }
    });
  }

  it("keeps the days sorted and unique, and never generates Full-Body A/B even at one or two days", () => {
    expect(generatePlan([5, 1, 1, 3], "brandNew", seed).trainingWeekdays).toEqual([1, 3, 5]);
    for (const days of [[7], [2, 4]]) {
      const plan = generatePlan(days, "some", seed);
      expect(plan.trainingWeekdays).toEqual(days);
      expect(plan.workouts.map((workout) => workout.kind)).toEqual(["push", "pull", "legs"]);
    }
  });

  it("the rows are the owner's canonical Push, Pull and Legs at every experience — 3×8 · 4×8 · 5×8 (A26)", () => {
    const strengthIds = (experience: Experience) => generatePlan([1, 3, 5], experience, seed).workouts.map((workout) => workout.exercises.filter((row) => row.type === "strength").map((row) => row.exerciseId));
    const canonical = [
      ["barbell-bench-press", "cable-rope-triceps-extension", "machine-incline-press", "cable-triceps-pushdown", "machine-decline-press"],
      ["lat-pulldown", "cable-rope-curl", "machine-row", "cable-rope-curl", "cable-face-pull", "cable-rope-curl"],
      ["machine-standing-calf-raise", "leg-press", "leg-extension", "seated-leg-curl", "dumbbell-walking-lunge"],
    ];
    for (const experience of experiences) expect(strengthIds(experience)).toEqual(canonical);
    const firstRow = (experience: Experience) => generatePlan([1, 3, 5], experience, seed).workouts[0]!.exercises[0]!;
    expect(experiences.map((experience) => `${firstRow(experience).targetSets}×${firstRow(experience).targetReps}`)).toEqual(["3×8", "4×8", "5×8"]);
    expect(firstRow("brandNew")).toMatchObject({ name: "Barbell Bench Press", equipment: "barbell", order: 0 });
  });

  it("a repeated exercise keeps one row per slot, each with its own order (A26: Pull's three rope curls)", () => {
    const pull = generatePlan([1, 3, 5], "some", seed).workouts[1]!;
    const curls = pull.exercises.filter((row) => row.exerciseId === "cable-rope-curl");
    expect(curls.map((row) => row.order)).toEqual([1, 3, 5]);
    expect(pull.exercises.some((row) => row.equipment === "barbell")).toBe(false); // barbell is never the default on Pull
  });

  it("a cardio row is duration-based: one set, no reps, the activity's seed seconds (A2)", () => {
    const walk = cardioRow(seed, "walk", 4);
    expect(walk).toEqual({ exerciseId: "walk", name: "Walk", pattern: "cardio", equipment: "bodyweight", type: "cardio", targetSets: 1, targetReps: 0, holdSeconds: 1200, order: 4 });
    expect(exercises.filter((row) => row.type === "cardio").map((row) => row.id)).toEqual(["walk", "run", "bike", "swim", "row", "elliptical", "stairs", "hike", "other-cardio"]);
  });
});
