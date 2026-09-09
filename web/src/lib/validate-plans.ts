// SPEC: docs/api.md plans (PUT replace, forward-only) · Flow 8 limits as input constraints (≤ planMaxExercisesPerDay,
// ≤ planMaxSetsPerExercise, names ≤ exerciseNameMaxChars) · Part IX ExerciseTemplate/WorkoutTemplate · A1 (a plan is
// trainingWeekdays + an ORDERED list of workouts, kinds unique) · A2 (cardio rows). Mirrors ApiPlans.swift.
import { z } from "zod";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

// SPEC: A2 — seconds are bounded by the exercise type: a mobility hold ≤ holdSecondsMax, a cardio block ≤ cardioMinutesMax minutes
const cardioSecondsMax = SpecConstants.cardioMinutesMax * TimeUnits.secondsPerMinute;

export const exerciseTemplateInputSchema = z
  .object({
    exerciseId: z.string().min(1).max(SpecConstants.exerciseNameMaxChars),
    name: z.string().trim().min(1).max(SpecConstants.exerciseNameMaxChars),
    pattern: z.string().min(1).max(SpecConstants.exerciseNameMaxChars),
    equipment: z.string().min(1).max(SpecConstants.exerciseNameMaxChars),
    type: z.enum(["strength", "mobility", "cardio"]),
    targetSets: z.number().int().min(1).max(SpecConstants.planMaxSetsPerExercise),
    targetReps: z.number().int().min(0).max(SpecConstants.planTargetRepsMax),
    targetRepsMax: z.number().int().min(1).max(SpecConstants.planTargetRepsMax).optional(),
    targetWeight: z.number().min(0).max(SpecConstants.setWeightMax).optional(),
    holdSeconds: z.number().int().min(0).max(cardioSecondsMax).optional(), // mobility holds and cardio blocks, in seconds
    perSide: z.boolean().optional(),
    order: z.number().int().min(0).max(SpecConstants.planMaxExercisesPerDay),
  })
  .refine((row) => (row.holdSeconds ?? 0) <= (row.type === "cardio" ? cardioSecondsMax : SpecConstants.holdSecondsMax), "holdSeconds: over the limit for this exercise type");

export const workoutKindSchema = z.enum(["push", "pull", "legs", "fullBodyA", "fullBodyB", "custom"]);

export const workoutTemplateInputSchema = z.object({
  name: z.string().trim().min(1).max(SpecConstants.exerciseNameMaxChars),
  kind: workoutKindSchema,
  exercises: z.array(exerciseTemplateInputSchema).min(1).max(SpecConstants.planMaxExercisesPerDay),
});

const weekdaySchema = z.number().int().min(1).max(TimeUnits.daysPerWeek); // ISO 1..7

// SPEC: A1 — training days are unique ISO weekdays (≥ 1); workouts are the rotation in stored order, one per kind
export const putPlanSchema = z
  .object({
    trainingWeekdays: z.array(weekdaySchema).min(1).max(TimeUnits.daysPerWeek),
    workouts: z.array(workoutTemplateInputSchema).min(1).max(TimeUnits.daysPerWeek),
  })
  .refine((plan) => new Set(plan.trainingWeekdays).size === plan.trainingWeekdays.length, "trainingWeekdays: each weekday once")
  .refine((plan) => new Set(plan.workouts.map((workout) => workout.kind)).size === plan.workouts.length, "workouts: one workout per kind");

export type PutPlanInput = z.infer<typeof putPlanSchema>;
