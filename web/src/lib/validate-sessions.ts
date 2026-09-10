// SPEC: docs/api.md sessions (create with snapshot; patch set logs / status) · sync (ops in order) · Part IX Session,
// SessionExercise, SetLog · Flow 3 (warm-ups, holds, "—" weight) · A1 (the snapshot names its plan kind) · A2 (cardio rows,
// distanceMeters). Mirrors ApiSessions.swift.
import { z } from "zod";
import { TimeUnits } from "@/lib/time-units";
import { clientIdSchema, timezoneSchema } from "@/lib/validate";
import { SpecConstants } from "@/generated/spec-constants";

// SPEC: A2 — seconds are bounded by the exercise type: a mobility hold ≤ holdSecondsMax, a cardio block ≤ cardioMinutesMax minutes
export const cardioSecondsMax = SpecConstants.cardioMinutesMax * TimeUnits.secondsPerMinute;
export const secondsCapFor = (type: string) => (type === "cardio" ? cardioSecondsMax : SpecConstants.holdSecondsMax);

export const setLogInputSchema = z.object({
  targetReps: z.number().int().min(0).max(SpecConstants.planTargetRepsMax),
  actualReps: z.number().int().min(0).max(SpecConstants.planTargetRepsMax),
  weight: z.number().min(0).max(SpecConstants.setWeightMax).nullish(), // absent = null: Swift's Codable omits a nil optional
  holdSeconds: z.number().int().min(0).max(cardioSecondsMax).nullish(), // the per-type cap is applied by the exercise schema
  distanceMeters: z.number().int().min(0).max(SpecConstants.cardioDistanceMaxMeters).nullish(), // A2: cardio only, optional
  weightUnit: z.enum(["lb", "kg"]).nullish(), // A9: the unit this weight was ENTERED in
  isWarmup: z.boolean(),
  done: z.boolean(),
});

export const sessionExerciseInputSchema = z
  .object({
    exerciseId: z.string().min(1).max(SpecConstants.exerciseNameMaxChars),
    name: z.string().trim().min(1).max(SpecConstants.exerciseNameMaxChars),
    equipment: z.string().min(1).max(SpecConstants.exerciseNameMaxChars),
    type: z.enum(["strength", "mobility", "cardio"]),
    targetSets: z.number().int().min(1).max(SpecConstants.planMaxSetsPerExercise),
    targetReps: z.number().int().min(0).max(SpecConstants.planTargetRepsMax),
    holdSeconds: z.number().int().min(0).max(cardioSecondsMax).nullish(),
    order: z.number().int().min(0).max(SpecConstants.planMaxExercisesPerDay),
    skipped: z.boolean().optional(),
    sets: z.array(setLogInputSchema).max(SpecConstants.planMaxSetsPerExercise + SpecConstants.planMaxSetsPerExercise), // work + warm-ups
  })
  .refine((exercise) => (exercise.holdSeconds ?? 0) <= secondsCapFor(exercise.type) && exercise.sets.every((set) => (set.holdSeconds ?? 0) <= secondsCapFor(exercise.type)), "holdSeconds: over the limit for this exercise type")
  // SPEC: A11 (V55) — an exercise never arrives with zero work sets. The phone's engine already refuses the removal that
  // would cause it, but an offline client is not a trusted one, and an exercise made only of warm-ups reports 0/0 forever.
  .refine((exercise) => exercise.sets.length === 0 || exercise.sets.some((set) => !set.isWarmup), "sets: an exercise needs at least one work set");

// A1: `kind` is the plan kind the session runs ("cardio" for a standalone log, A2); `weekday` is still accepted from older clients and ignored
export const createSessionSchema = z.object({
  clientId: clientIdSchema,
  timezone: timezoneSchema,
  startedAt: z.iso.datetime(),
  workoutSnapshot: z.object({
    name: z.string().trim().min(1).max(SpecConstants.exerciseNameMaxChars),
    kind: z.enum(["push", "pull", "legs", "fullBodyA", "fullBodyB", "custom", "cardio"]).optional(),
    weekday: z.number().int().min(1).max(TimeUnits.daysPerWeek).optional(),
    isPlannedDay: z.boolean(),
    exercises: z.array(sessionExerciseInputSchema).min(1).max(SpecConstants.planMaxExercisesPerDay),
  }),
});
export type CreateSessionInput = z.infer<typeof createSessionSchema>;

export const completionPostSchema = z.object({
  clientId: clientIdSchema,
  shareToCrew: z.boolean(),
  caption: z.string().max(SpecConstants.captionMaxChars).optional(),
  photoKey: z.string().min(1).optional(),
});

export const patchSessionSchema = z.object({
  timezone: timezoneSchema,
  exercises: z.array(sessionExerciseInputSchema).max(SpecConstants.planMaxExercisesPerDay).optional(),
  status: z.enum(["inProgress", "completed", "discarded"]).optional(),
  completedAt: z.iso.datetime().optional(),
  post: completionPostSchema.optional(),
});
export type PatchSessionInput = z.infer<typeof patchSessionSchema>;

export const syncOpSchema = z.object({
  opId: z.string().min(1).max(SpecConstants.exerciseNameMaxChars),
  kind: z.enum(["createSession", "patchSession", "createPost", "deletePost", "sendMessage", "react", "unreact", "putPlan", "pause", "pushToken"]),
  payload: z.record(z.string(), z.unknown()),
});

export const syncSchema = z.object({
  timezone: timezoneSchema,
  ops: z.array(syncOpSchema).max(SpecConstants.syncBatchMaxOps),
});
export type SyncInput = z.infer<typeof syncSchema>;
