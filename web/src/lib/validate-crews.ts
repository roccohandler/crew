// SPEC: docs/api.md crews (create ≤ crewNameMaxChars + emoji; join by token; rename; leave/remove; mute), safety (reports ≤
// reportReasonMaxChars on a post, a crew name or a user — A21.2 / W3 retired the message target with the chat; blocks). Mirrors
// ApiCrews.swift.
import { z } from "zod";
import { objectIdSchema } from "@/lib/validate";
import { SpecConstants } from "@/generated/spec-constants";

const emojiSchema = z.string().trim().min(1).max(SpecConstants.crewEmojiMaxChars); // one emoji, ZWJ sequences included
const crewNameSchema = z.string().trim().min(1).max(SpecConstants.crewNameMaxChars);

export const createCrewSchema = z.object({ name: crewNameSchema, emoji: emojiSchema });
export const renameCrewSchema = z.object({ name: crewNameSchema.optional(), emoji: emojiSchema.optional() });
export const joinCrewSchema = z.object({ token: z.string().min(1).max(SpecConstants.exerciseNameMaxChars) });
export const leaveOrRemoveSchema = z.object({ userId: objectIdSchema.optional() });
export const muteSchema = z.object({ muted: z.boolean() });

// SPEC: E9 (as marked by A21.2) — reportable: a post, a crew name, a user
export const createReportSchema = z.object({
  targetType: z.enum(["post", "crewName", "user"]),
  targetId: objectIdSchema,
  reason: z.string().trim().min(1).max(SpecConstants.reportReasonMaxChars),
});

export const blockSchema = z.object({ userId: objectIdSchema });
