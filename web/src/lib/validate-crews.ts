// SPEC: docs/api.md crews (create ≤ crewNameMaxChars + emoji; join by token; rename; leave/remove; mute), messages (≤
// chatMessageMaxChars, clientId), safety (reports ≤ reportReasonMaxChars, blocks). Mirrors ApiCrews.swift.
import { z } from "zod";
import { clientIdSchema, objectIdSchema } from "@/lib/validate";
import { SpecConstants } from "@/generated/spec-constants";

const emojiSchema = z.string().trim().min(1).max(SpecConstants.crewEmojiMaxChars); // one emoji, ZWJ sequences included
const crewNameSchema = z.string().trim().min(1).max(SpecConstants.crewNameMaxChars);

export const createCrewSchema = z.object({ name: crewNameSchema, emoji: emojiSchema });
export const renameCrewSchema = z.object({ name: crewNameSchema.optional(), emoji: emojiSchema.optional() });
export const joinCrewSchema = z.object({ token: z.string().min(1).max(SpecConstants.exerciseNameMaxChars) });
export const leaveOrRemoveSchema = z.object({ userId: objectIdSchema.optional() });
export const muteSchema = z.object({ muted: z.boolean() });

export const sendMessageSchema = z.object({ clientId: clientIdSchema, body: z.string().trim().min(1).max(SpecConstants.chatMessageMaxChars) });

export const createReportSchema = z.object({
  targetType: z.enum(["post", "message", "crewName", "user"]),
  targetId: objectIdSchema,
  reason: z.string().trim().min(1).max(SpecConstants.reportReasonMaxChars),
});

export const blockSchema = z.object({ userId: objectIdSchema });
