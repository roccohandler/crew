// SPEC: T020 (Verify: both unit suites) · 8.3 plan generator property test: every days × experience × equipment combo
// yields a valid plan (limits respected, mobility block present, Full-Body at ≤2 days).
import { describe, expect, it } from "vitest";
import { generatePlan, type SeedCatalog } from "@/lib/engine/plan-generator";
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

describe("generatePlan — every days × experience × equipment combination is a valid plan", () => {
  const subsets = daySubsets();
  it("covers 127 day subsets × 3 × 3 = 1143 plans", () => {
    expect(subsets.length * experiences.length * accesses.length).toBe(1143);
  });

  for (const experience of experiences) {
    for (const access of accesses) {
      it(`${experience} / ${access}`, () => {
        for (const days of subsets) {
          const plan = generatePlan(days, experience, access, seed);
          expect(plan.workouts.map((workout) => workout.weekday)).toEqual([...days].sort((a, b) => a - b));
          const fullBody = days.length <= SpecConstants.fullBodyMaxTrainingDays;
          for (const workout of plan.workouts) {
            expect(fullBody ? ["fullBodyA", "fullBodyB"] : ["push", "pull", "legs"]).toContain(workout.kind);
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
          }
          if (fullBody && days.length === 2) expect(plan.workouts.map((workout) => workout.kind)).toEqual(["fullBodyA", "fullBodyB"]);
          if (days.length === 3 && !fullBody) expect(plan.workouts.map((workout) => workout.kind)).toEqual(["push", "pull", "legs"]);
        }
      });
    }
  }

  it("brand new = 4 exercises at 3×10; some = 5 at 3×8–10; experienced = 6 with barbell lifts in a full gym", () => {
    const brandNew = generatePlan([1, 3, 5], "brandNew", "fullGym", seed).workouts[0]!;
    expect(brandNew.exercises.filter((row) => row.type === "strength").every((row) => row.targetSets === 3 && row.targetReps === 10)).toBe(true);
    const some = generatePlan([1, 3, 5], "some", "dumbbells", seed).workouts[0]!;
    expect(some.exercises.filter((row) => row.type === "strength").every((row) => row.targetReps === 8 && row.targetRepsMax === 10)).toBe(true);
    const experienced = generatePlan([1, 3, 5], "experienced", "fullGym", seed);
    expect(experienced.workouts.some((workout) => workout.exercises.some((row) => row.equipment === "barbell"))).toBe(true);
  });
});
