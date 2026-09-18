// SPEC: docs/api.md posts (PATCH caption ≤ captionMaxChars on a workout post — A22 G2) · reactions (emoji ∈ reactionEmojis) · the
// sync op deletePost { clientId }. A22 (owner-approved 2026-09-18): createPostSchema is gone with POST posts — a workout post is
// created by its session's completion (completionPostSchema in validate-sessions.ts). Mirrors ApiPosts.swift.
import { z } from "zod";
import { clientIdSchema } from "@/lib/validate";
import { SpecConstants } from "@/generated/spec-constants";

export const patchPostSchema = z.object({ caption: z.string().max(SpecConstants.captionMaxChars) });

export const reactionSchema = z.object({ emoji: z.enum(SpecConstants.reactionEmojis) });

// The sync op deletePost names the post by its clientId (docs/api.md sync)
export const deletePostOpSchema = z.object({ clientId: clientIdSchema });
