// SPEC: docs/api.md sessions (create with snapshot; patch set logs / status) · sync (ops in order) · Part IX Session,
// SessionExercise, SetLog · Flow 3 (warm-ups, holds, "—" weight). Mirrors ApiSessions.swift.
import { z } from "zod";
import { TimeUnits } from "@/lib/time-units";
import { clientIdSchema, timezoneSchema } from "@/lib/validate";
import { SpecConstants } from "@/generated/spec-constants";

export const setLogInputSchema = z.object({
  targetReps: z.number().int().min(0).max(SpecConstants.planTargetRepsMax),
  actualReps: z.number().int().min(0).max(SpecConstants.planTargetRepsMax),
  weight: z.number().min(0).max(SpecConstants.setWeightMax).nullish(), // absent = null: Swift's Codable omits a nil optional
  holdSeconds: z.number().int().min(0).max(SpecConstants.holdSecondsMax).nullish(),
  isWarmup: z.boolean(),
  done: z.boolean(),
});

export const sessionExerciseInputSchema = z.object({
  exerciseId: z.string().min(1).max(SpecConstants.exerciseNameMaxChars),
  name: z.string().trim().min(1).max(SpecConstants.exerciseNameMaxChars),
  equipment: z.string().min(1).max(SpecConstants.exerciseNameMaxChars),
  type: z.enum(["strength", "mobility"]),
  targetSets: z.number().int().min(1).max(SpecConstants.planMaxSetsPerExercise),
  targetReps: z.number().int().min(0).max(SpecConstants.planTargetRepsMax),
  holdSeconds: z.number().int().min(0).max(SpecConstants.holdSecondsMax).nullish(),
  order: z.number().int().min(0).max(SpecConstants.planMaxExercisesPerDay),
  skipped: z.boolean().optional(),
  sets: z.array(setLogInputSchema).max(SpecConstants.planMaxSetsPerExercise + SpecConstants.planMaxSetsPerExercise), // work + warm-ups
});

export const createSessionSchema = z.object({
  clientId: clientIdSchema,
  timezone: timezoneSchema,
  startedAt: z.iso.datetime(),
  workoutSnapshot: z.object({
    name: z.string().trim().min(1).max(SpecConstants.exerciseNameMaxChars),
    weekday: z.number().int().min(1).max(TimeUnits.daysPerWeek),
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
