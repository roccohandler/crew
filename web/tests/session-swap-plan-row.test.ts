// SPEC: A26 (owner-approved 2026-09-18, canonical templates) · E7 ("Update my plan") — the owner's Pull repeats the rope curl
// three times, so a mid-workout swap that also updates the plan must change ONE plan row: the one at the session row's order
// when it still holds that exercise, else the first row that does; an exercise the plan lacks changes nothing.
// Twin of SessionModelTests.testUpdateMyPlanNamesOneRowOfARepeatedExercise.
import { describe, expect, it } from "vitest";
import { planRowToSwap } from "@/components/SessionSwap";
import { generatePlan } from "@/lib/engine/plan-generator";
import { exercises, planTemplates } from "@/generated/seed";

describe("planRowToSwap", () => {
  const pull = generatePlan([1, 3, 5], "brandNew", { exercises, planTemplates }).workouts[1]!.exercises;

  it("names the plan row at the session row's order", () => {
    expect(planRowToSwap(pull, "cable-rope-curl", 3)).toBe(3);
  });

  it("falls back to the first row holding the exercise when the plan has moved since", () => {
    expect(planRowToSwap(pull, "cable-rope-curl", 2)).toBe(1);
  });

  it("names nothing when the plan no longer holds the exercise", () => {
    expect(planRowToSwap(pull, "barbell-row", 2)).toBeNull();
  });
});
