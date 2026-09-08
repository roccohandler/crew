// SPEC: docs/api.md posts (create: type, sessionId?, photoKey?, caption ≤ captionMaxChars, mealTag?, shareToCrew, timezone,
// isPlannedDay, backfill) · reactions (emoji ∈ reactionEmojis) · Flow 4 (photo/text only, never numbers). Mirrors ApiPosts.swift.
import { z } from "zod";
import { clientIdSchema, objectIdSchema, timezoneSchema } from "@/lib/validate";
import { SpecConstants } from "@/generated/spec-constants";

export const createPostSchema = z
  .object({
    clientId: clientIdSchema,
    type: z.enum(["workout", "meal", "text"]),
    sessionId: objectIdSchema.optional(),
    photoKey: z.string().min(1).optional(),
    caption: z.string().max(SpecConstants.captionMaxChars).optional(),
    mealTag: z.enum(["breakfast", "lunch", "dinner", "snack"]).optional(),
    shareToCrew: z.boolean(),
    timezone: timezoneSchema,
    isPlannedDay: z.boolean(),
    workoutCompleted: z.boolean().optional().default(false),
    earlierToday: z.boolean().optional(),
    createdAt: z.iso.datetime().optional(),
  })
  .refine((post) => post.type !== "meal" || post.photoKey !== undefined || (post.caption ?? "").trim().length > 0, "a meal needs a photo or a line of text");
export type CreatePostInput = z.infer<typeof createPostSchema>;

export const patchPostSchema = z.object({ caption: z.string().max(SpecConstants.captionMaxChars) });

export const reactionSchema = z.object({ emoji: z.enum(SpecConstants.reactionEmojis) });

// The sync op deletePost names the post by its clientId (docs/api.md sync)
export const deletePostOpSchema = z.object({ clientId: clientIdSchema });
