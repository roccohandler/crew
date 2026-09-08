// SPEC: 5.2 lib/validate.ts — zod schemas, one per DTO, mirroring ApiModels.swift. This file holds the shared
// primitives and the auth DTOs; other groups live in validate-<group>.ts (C9 file cap). Every limit is a
// SpecConstants value; the schemas are the only place input limits are enforced (8.3 Validators).
import { z } from "zod";
import { SpecConstants } from "@/generated/spec-constants";

const supportedTimeZones = new Set(Intl.supportedValuesOf("timeZone"));

export const timezoneSchema = z.string().refine((value) => supportedTimeZones.has(value) || value === "UTC", "must be an IANA timezone");
export const dayKeySchema = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "must be YYYY-MM-DD");
export const clientIdSchema = z.uuid();
export const objectIdSchema = z.string().regex(/^[0-9a-f]{24}$/, "must be an id");
export const emailSchema = z.email().max(SpecConstants.captionMaxChars);
export const passwordSchema = z.string().min(SpecConstants.passwordMinChars, `at least ${SpecConstants.passwordMinChars} characters`).max(SpecConstants.captionMaxChars);
export const displayNameSchema = z.string().trim().min(1).max(SpecConstants.displayNameMaxChars);
const birthYearSchema = z.number().int().min(SpecConstants.birthYearMin).max(new Date().getUTCFullYear());

export const registerSchema = z.object({
  email: emailSchema,
  password: passwordSchema,
  displayName: displayNameSchema,
  timezone: timezoneSchema,
  eulaAccepted: z.boolean(),
  birthYear: birthYearSchema,
});
export type RegisterInput = z.infer<typeof registerSchema>;

export const loginSchema = z.object({ email: emailSchema, password: z.string().min(1) });

export const refreshSchema = z.object({ refreshToken: z.string().min(1).optional() });

export const appleSignInSchema = z.object({
  identityToken: z.string().min(1),
  displayName: displayNameSchema.optional(),
  timezone: timezoneSchema,
  eulaAccepted: z.boolean(),
  birthYear: birthYearSchema.optional(),
});

export const resetRequestSchema = z.object({ email: emailSchema });
export const resetConfirmSchema = z.object({ token: z.string().min(1), newPassword: passwordSchema });

export const updateMeSchema = z.object({
  displayName: displayNameSchema.optional(),
  units: z.enum(["lb", "kg"]).optional(),
  timezone: timezoneSchema.optional(),
  reminderTime: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/, "must be HH:MM").nullable().optional(),
  profilePhotoKey: z.string().min(1).nullable().optional(),
  welcomeBackAckDay: dayKeySchema.optional(), // E4: set when the user answers the welcome-back screen
});

export const deleteAccountSchema = z.object({ confirm: z.literal("delete") });

export const pushTokenSchema = z.object({ token: z.string().min(1), platform: z.literal("ios").optional() });

export const clientEventsSchema = z.object({
  events: z.array(z.object({ name: z.string().min(1).max(SpecConstants.exerciseNameMaxChars), at: z.iso.datetime(), props: z.record(z.string(), z.union([z.string(), z.number(), z.boolean(), z.null()])).optional() })).min(1),
});
