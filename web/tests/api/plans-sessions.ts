// Fixture builders for plans and sessions — the shapes the clients send (mirrors PlanDraft / session snapshots).
import { randomUUID } from "node:crypto";
import { generatePlan } from "@/lib/engine/plan-generator";
import { exercises, planTemplates } from "@/generated/seed";

export function samplePlanBody(days: number[] = [1, 3, 5]) {
  return generatePlan(days, "brandNew", "fullGym", { exercises, planTemplates });
}

export function sampleSessionBody(overrides: Partial<{ clientId: string; startedAt: string; isPlannedDay: boolean; timezone: string }> = {}) {
  return {
    clientId: overrides.clientId ?? randomUUID(),
    timezone: overrides.timezone ?? "America/Los_Angeles",
    startedAt: overrides.startedAt ?? new Date().toISOString(),
    workoutSnapshot: {
      name: "Push day",
      weekday: 1,
      isPlannedDay: overrides.isPlannedDay ?? true,
      exercises: [
        { exerciseId: "push-up", name: "Push-Up", equipment: "bodyweight", type: "strength" as const, targetSets: 3, targetReps: 10, holdSeconds: null, order: 0, sets: [
          { targetReps: 10, actualReps: 10, weight: null, holdSeconds: null, isWarmup: true, done: false },
          { targetReps: 10, actualReps: 10, weight: null, holdSeconds: null, isWarmup: false, done: false },
          { targetReps: 10, actualReps: 10, weight: null, holdSeconds: null, isWarmup: false, done: false },
          { targetReps: 10, actualReps: 10, weight: null, holdSeconds: null, isWarmup: false, done: false },
        ] },
        { exerciseId: "couch-stretch", name: "Couch Stretch", equipment: "bodyweight", type: "mobility" as const, targetSets: 1, targetReps: 0, holdSeconds: 90, order: 1, sets: [
          { targetReps: 0, actualReps: 0, weight: null, holdSeconds: 90, isWarmup: false, done: false },
        ] },
      ],
    },
  };
}

export function doneSets(body: ReturnType<typeof sampleSessionBody>, workSetsDone: number) {
  let remaining = workSetsDone;
  return body.workoutSnapshot.exercises.map((exercise) => ({
    ...exercise,
    sets: exercise.sets.map((set) => {
      if (set.isWarmup || exercise.type === "mobility" || remaining === 0) return set;
      remaining -= 1;
      return { ...set, done: true };
    }),
  }));
}
