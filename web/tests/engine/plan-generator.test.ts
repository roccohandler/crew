// SPEC: T020 (Verify: both unit suites) · 8.3 plan generator property test: every days × experience × equipment combo
// yields a valid plan (limits respected, mobility block present) · A1 (owner-directed 2026-09-08): every combination
// yields exactly the pplCycle's kinds once, in order, at every day count — Full-Body A/B is never generated.
import { describe, expect, it } from "vitest";
import { cardioRow, generatePlan, type SeedCatalog } from "@/lib/engine/plan-generator";
import { equipmentAccess, exercises, planTemplates, type EquipmentAccess, type Experience } from "@/generated/seed";
import { SpecConstants } from "@/generated/spec-constants";

const seed: SeedCatalog = { exercises, planTemplates };
const experiences: Experience[] = ["brandNew", "some", "experienced"];
const accesses: EquipmentAccess[] = ["fullGym", "dumbbells", "bodyweight"];
const countFor: Record<Experience, number> = { brandNew: SpecConstants.beginnerExerciseCount, some: SpecConstants.someExperienceExerciseCount, experienced: SpecConstants.experiencedExerciseCount };

// every non-empty subset of Mon..Sun (127 of them)
function daySubsets(): number[][] {
  const subsets: number[][] = [];
  for (let mask = 1; mask < 1 << 7; mask += 1) subsets.push([1, 2, 3, 4, 5, 6, 7].filter((_, index) => (mask & (1 << index)) !== 0));
  return subsets;
}

describe("generatePlan — every days × experience × equipment combination is a valid PPL plan (A1)", () => {
  const subsets = daySubsets();
  it("covers 127 day subsets × 3 × 3 = 1143 plans", () => {
    expect(subsets.length * experiences.length * accesses.length).toBe(1143);
  });

  for (const experience of experiences) {
    for (const access of accesses) {
      it(`${experience} / ${access}`, () => {
        for (const days of subsets) {
          const plan = generatePlan(days, experience, access, seed);
          expect(plan.trainingWeekdays).toEqual([...days].sort((a, b) => a - b));
          expect(plan.workouts.map((workout) => workout.kind)).toEqual(planTemplates.split.pplCycle);
          expect(plan.workouts.map((workout) => workout.kind)).toEqual(["push", "pull", "legs"]);
          expect(plan.workouts.map((workout) => workout.name)).toEqual(["Push day", "Pull day", "Leg day"]);
          for (const workout of plan.workouts) {
            const strength = workout.exercises.filter((row) => row.type === "strength");
            const holds = workout.exercises.filter((row) => row.type === "mobility");
            expect(strength).toHaveLength(countFor[experience]);
            expect(workout.exercises.length).toBeLessThanOrEqual(SpecConstants.planMaxExercisesPerDay);
            expect(holds.length).toBeGreaterThanOrEqual(SpecConstants.mobilityHoldsMin);
            expect(holds.length).toBeLessThanOrEqual(SpecConstants.mobilityHoldsMax);
            const holdSeconds = holds.reduce((sum, row) => sum + (row.holdSeconds ?? 0) * (row.perSide ? 2 : 1), 0);
            expect(holdSeconds).toBeGreaterThanOrEqual(SpecConstants.mobilityMinutesMin * 60);
            expect(holdSeconds).toBeLessThanOrEqual(SpecConstants.mobilityMinutesMax * 60);
            for (const row of workout.exercises) {
              expect(row.name.length).toBeLessThanOrEqual(SpecConstants.exerciseNameMaxChars);
              expect(row.targetSets).toBeLessThanOrEqual(SpecConstants.planMaxSetsPerExercise);
              expect(equipmentAccess[access]).toContain(row.equipment);
            }
            expect(workout.exercises.map((row) => row.order)).toEqual(workout.exercises.map((_, index) => index));
            expect(workout.exercises.some((row) => row.type === "cardio")).toBe(false); // cardio blocks are added by the editor, never generated
          }
        }
      });
    }
  }

  it("keeps the days sorted and unique, and never generates Full-Body A/B even at one or two days", () => {
    expect(generatePlan([5, 1, 1, 3], "brandNew", "fullGym", seed).trainingWeekdays).toEqual([1, 3, 5]);
    for (const days of [[7], [2, 4]]) {
      const plan = generatePlan(days, "some", "bodyweight", seed);
      expect(plan.trainingWeekdays).toEqual(days);
      expect(plan.workouts.map((workout) => workout.kind)).toEqual(["push", "pull", "legs"]);
    }
  });

  it("brand new = 4 exercises at 3×10; some = 5 at 3×8–10; experienced = 6 with barbell lifts in a full gym", () => {
    const brandNew = generatePlan([1, 3, 5], "brandNew", "fullGym", seed).workouts[0]!;
    expect(brandNew.exercises.filter((row) => row.type === "strength").every((row) => row.targetSets === 3 && row.targetReps === 10)).toBe(true);
    const some = generatePlan([1, 3, 5], "some", "dumbbells", seed).workouts[0]!;
    expect(some.exercises.filter((row) => row.type === "strength").every((row) => row.targetReps === 8 && row.targetRepsMax === 10)).toBe(true);
    const experienced = generatePlan([1, 3, 5], "experienced", "fullGym", seed);
    expect(experienced.workouts.some((workout) => workout.exercises.some((row) => row.equipment === "barbell"))).toBe(true);
  });

  it("a cardio row is duration-based: one set, no reps, the activity's seed seconds (A2)", () => {
    const walk = cardioRow(seed, "walk", 4);
    expect(walk).toEqual({ exerciseId: "walk", name: "Walk", pattern: "cardio", equipment: "bodyweight", type: "cardio", targetSets: 1, targetReps: 0, holdSeconds: 1200, order: 4 });
    expect(exercises.filter((row) => row.type === "cardio").map((row) => row.id)).toEqual(["walk", "run", "bike", "swim", "row", "elliptical", "stairs", "hike", "other-cardio"]);
  });
});
