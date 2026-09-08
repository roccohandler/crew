// SPEC: 8.3 "Validators: all input limits" — every limit the spec names (E20 captions 280 · crew names 30 · exercise names 60 ·
// chat 1,000; Flow 8 ≤ 15 exercises/day, ≤ 20 sets/exercise (G3); E9 age floor; G11/GAP ceilings) is enforced by exactly one
// zod schema, at the limit (accepted) and one over (rejected). The numbers come from SpecConstants, never typed here (C7).
import { describe, expect, it } from "vitest";
import { createPostSchema, patchPostSchema, reactionSchema } from "@/lib/validate-posts";
import { createCrewSchema, createReportSchema, sendMessageSchema } from "@/lib/validate-crews";
import { exerciseTemplateInputSchema, putPlanSchema, workoutTemplateInputSchema } from "@/lib/validate-plans";
import { setLogInputSchema, syncSchema } from "@/lib/validate-sessions";
import { clientEventsSchema, registerSchema, timezoneSchema, updateMeSchema } from "@/lib/validate";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

const text = (length: number) => "x".repeat(length);
const uuid = "5d1f6f4e-0f0e-4a6b-9a4d-2b6c4a7f1c2e";

const exerciseRow = (overrides: Partial<ReturnType<typeof exerciseTemplateInputSchema.parse>> = {}) => ({ exerciseId: "bench-press", name: "Bench press", pattern: "horizontalPush", equipment: "barbell", type: "strength" as const, targetSets: SpecConstants.planMaxSetsPerExercise, targetReps: SpecConstants.planTargetRepsMax, order: 0, ...overrides });

describe("input limits (8.3 validators)", () => {
  it("captions: the 280th character is accepted, the 281st rejected (E20)", () => {
    const base = { clientId: uuid, type: "text" as const, shareToCrew: false, timezone: "UTC", isPlannedDay: false };
    expect(createPostSchema.safeParse({ ...base, caption: text(SpecConstants.captionMaxChars) }).success).toBe(true);
    expect(createPostSchema.safeParse({ ...base, caption: text(SpecConstants.captionMaxChars + 1) }).success).toBe(false);
    expect(patchPostSchema.safeParse({ caption: text(SpecConstants.captionMaxChars + 1) }).success).toBe(false);
  });

  it("a meal needs a photo or a line of text; a reaction must be one of the five (Flow 4, Flow 6)", () => {
    const meal = { clientId: uuid, type: "meal" as const, shareToCrew: true, timezone: "UTC", isPlannedDay: false };
    expect(createPostSchema.safeParse({ ...meal, caption: "   " }).success).toBe(false);
    expect(createPostSchema.safeParse({ ...meal, photoKey: "k" }).success).toBe(true);
    for (const emoji of SpecConstants.reactionEmojis) expect(reactionSchema.safeParse({ emoji }).success).toBe(true);
    expect(reactionSchema.safeParse({ emoji: "👍" }).success).toBe(false);
  });

  it("crew names ≤ 30, chat messages ≤ 1,000, report reasons ≤ 500 (E20, GAP)", () => {
    expect(createCrewSchema.safeParse({ name: text(SpecConstants.crewNameMaxChars), emoji: "🌅" }).success).toBe(true);
    expect(createCrewSchema.safeParse({ name: text(SpecConstants.crewNameMaxChars + 1), emoji: "🌅" }).success).toBe(false);
    expect(sendMessageSchema.safeParse({ clientId: uuid, body: text(SpecConstants.chatMessageMaxChars) }).success).toBe(true);
    expect(sendMessageSchema.safeParse({ clientId: uuid, body: text(SpecConstants.chatMessageMaxChars + 1) }).success).toBe(false);
    expect(sendMessageSchema.safeParse({ clientId: uuid, body: "   " }).success).toBe(false);
    const report = { targetType: "post" as const, targetId: "0123456789abcdef01234567" };
    expect(createReportSchema.safeParse({ ...report, reason: text(SpecConstants.reportReasonMaxChars) }).success).toBe(true);
    expect(createReportSchema.safeParse({ ...report, reason: text(SpecConstants.reportReasonMaxChars + 1) }).success).toBe(false);
  });

  it("exercise names ≤ 60, ≤ 20 sets per exercise (G3), reps/weight/hold ceilings (R-044)", () => {
    expect(exerciseTemplateInputSchema.safeParse(exerciseRow({ name: text(SpecConstants.exerciseNameMaxChars) })).success).toBe(true);
    expect(exerciseTemplateInputSchema.safeParse(exerciseRow({ name: text(SpecConstants.exerciseNameMaxChars + 1) })).success).toBe(false);
    expect(exerciseTemplateInputSchema.safeParse(exerciseRow({ targetSets: SpecConstants.planMaxSetsPerExercise + 1 })).success).toBe(false);
    expect(exerciseTemplateInputSchema.safeParse(exerciseRow({ targetReps: SpecConstants.planTargetRepsMax + 1 })).success).toBe(false);
    expect(exerciseTemplateInputSchema.safeParse(exerciseRow({ targetWeight: SpecConstants.setWeightMax + 1 })).success).toBe(false);
    expect(exerciseTemplateInputSchema.safeParse(exerciseRow({ holdSeconds: SpecConstants.holdSecondsMax + 1 })).success).toBe(false);
    const set = { targetReps: 0, actualReps: 0, isWarmup: false, done: true };
    expect(setLogInputSchema.safeParse({ ...set, weight: SpecConstants.setWeightMax }).success).toBe(true);
    expect(setLogInputSchema.safeParse({ ...set, weight: SpecConstants.setWeightMax + 1 }).success).toBe(false);
    expect(setLogInputSchema.safeParse({ ...set, actualReps: SpecConstants.planTargetRepsMax + 1 }).success).toBe(false);
  });

  it("≤ 15 exercises per day, one workout per weekday, never an eighth day (Flow 8)", () => {
    const rows = (count: number) => Array.from({ length: count }, (_, index) => exerciseRow({ exerciseId: `row-${index}`, order: index }));
    const workout = (weekday: number, count: number) => ({ weekday, name: "Push day", kind: "push" as const, exercises: rows(count) });
    expect(workoutTemplateInputSchema.safeParse(workout(1, SpecConstants.planMaxExercisesPerDay)).success).toBe(true);
    expect(workoutTemplateInputSchema.safeParse(workout(1, SpecConstants.planMaxExercisesPerDay + 1)).success).toBe(false);
    expect(putPlanSchema.safeParse({ workouts: [workout(1, 1), workout(1, 1)] }).success).toBe(false);
    expect(putPlanSchema.safeParse({ workouts: [workout(TimeUnits.daysPerWeek + 1, 1)] }).success).toBe(false);
  });

  it("accounts: password ≥ passwordMinChars, display name ≤ displayNameMaxChars, birth year ≥ birthYearMin, a real timezone", () => {
    const account = { email: "a@example.com", password: text(SpecConstants.passwordMinChars), displayName: "Sam", timezone: "America/Los_Angeles", eulaAccepted: true, birthYear: SpecConstants.birthYearMin };
    expect(registerSchema.safeParse(account).success).toBe(true);
    expect(registerSchema.safeParse({ ...account, password: text(SpecConstants.passwordMinChars - 1) }).success).toBe(false);
    expect(registerSchema.safeParse({ ...account, displayName: text(SpecConstants.displayNameMaxChars + 1) }).success).toBe(false);
    expect(registerSchema.safeParse({ ...account, birthYear: SpecConstants.birthYearMin - 1 }).success).toBe(false);
    expect(registerSchema.safeParse({ ...account, timezone: "Mars/Olympus" }).success).toBe(false);
    for (const zone of ["UTC", "GMT", "US/Pacific", "Europe/Berlin"]) expect(timezoneSchema.safeParse(zone).success).toBe(true);
    expect(updateMeSchema.safeParse({ reminderTime: "07:30" }).success).toBe(true);
    expect(updateMeSchema.safeParse({ reminderTime: "7:30" }).success).toBe(false);
  });

  it("sync batches ≤ syncBatchMaxOps; a client event batch never empty and never nameless", () => {
    const op = { opId: "op", kind: "react" as const, payload: {} };
    expect(syncSchema.safeParse({ timezone: "UTC", ops: Array.from({ length: SpecConstants.syncBatchMaxOps }, () => op) }).success).toBe(true);
    expect(syncSchema.safeParse({ timezone: "UTC", ops: Array.from({ length: SpecConstants.syncBatchMaxOps + 1 }, () => op) }).success).toBe(false);
    expect(clientEventsSchema.safeParse({ events: [] }).success).toBe(false);
    expect(clientEventsSchema.safeParse({ events: [{ name: "", at: "2026-09-08T10:00:00.000Z" }] }).success).toBe(false);
  });
});
