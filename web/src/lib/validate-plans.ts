// SPEC: docs/api.md plans (PUT replace, forward-only) · Flow 8 limits as input constraints (≤ planMaxExercisesPerDay,
// ≤ planMaxSetsPerExercise, names ≤ exerciseNameMaxChars) · Part IX ExerciseTemplate/WorkoutTemplate. Mirrors ApiPlans.swift.
import { z } from "zod";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

export const exerciseTemplateInputSchema = z.object({
  exerciseId: z.string().min(1).max(SpecConstants.exerciseNameMaxChars),
  name: z.string().trim().min(1).max(SpecConstants.exerciseNameMaxChars),
  pattern: z.string().min(1).max(SpecConstants.exerciseNameMaxChars),
  equipment: z.string().min(1).max(SpecConstants.exerciseNameMaxChars),
  type: z.enum(["strength", "mobility"]),
  targetSets: z.number().int().min(1).max(SpecConstants.planMaxSetsPerExercise),
  targetReps: z.number().int().min(0).max(SpecConstants.planTargetRepsMax),
  targetRepsMax: z.number().int().min(1).max(SpecConstants.planTargetRepsMax).optional(),
  targetWeight: z.number().min(0).max(SpecConstants.setWeightMax).optional(),
  holdSeconds: z.number().int().min(0).max(SpecConstants.holdSecondsMax).optional(),
  perSide: z.boolean().optional(),
  order: z.number().int().min(0).max(SpecConstants.planMaxExercisesPerDay),
});

export const workoutTemplateInputSchema = z.object({
  weekday: z.number().int().min(1).max(TimeUnits.daysPerWeek), // ISO 1..7
  name: z.string().trim().min(1).max(SpecConstants.exerciseNameMaxChars),
  kind: z.enum(["push", "pull", "legs", "fullBodyA", "fullBodyB", "custom"]),
  exercises: z.array(exerciseTemplateInputSchema).min(1).max(SpecConstants.planMaxExercisesPerDay),
});

export const putPlanSchema = z
  .object({ workouts: z.array(workoutTemplateInputSchema).max(TimeUnits.daysPerWeek) })
  .refine((plan) => new Set(plan.workouts.map((workout) => workout.weekday)).size === plan.workouts.length, "one workout per weekday");

export type PutPlanInput = z.infer<typeof putPlanSchema>;
