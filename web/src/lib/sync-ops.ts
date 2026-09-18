// SPEC: docs/api.md POST sync — replay the offline queue IN ORDER, each op idempotent; per-op results, never a failed batch;
// the server gamification state REPLACES the client's (5.6.3). Op kinds map to the same lib functions the routes use. A21.2 / W3
// (2026-09-17): free-text chat is gone — a `sendMessage` op from an older phone is rejected PER OP, non-retryably (`chatRetired`),
// so that phone's queue holds it instead of retrying forever, and the rest of its batch still lands. A22 (owner-approved
// 2026-09-18): `createPost` takes the same shape (`postsRetired`) — the plate journal is gone and a workout post rides its
// session's completion (patchSession `post`). T023/T030/T041
import { ObjectId } from "mongodb";
import { ZodError } from "zod";
import { apiError, isApiError } from "@/lib/api-error";
import { pushTokens } from "@/lib/db";
import { HttpStatus } from "@/lib/http-status";
import { runNutritionOp } from "@/lib/nutrition-sync";
import { createPause } from "@/lib/pauses";
import { replacePlan } from "@/lib/plans";
import { deletePostByClientId } from "@/lib/posts";
import { react, reactablePost, unreact } from "@/lib/reactions";
import { createSession, patchSession } from "@/lib/sessions";
import { dayKeySchema, pushTokenSchema } from "@/lib/validate";
import { putPlanSchema } from "@/lib/validate-plans";
import { deletePostOpSchema, reactionSchema } from "@/lib/validate-posts";
import { createSessionSchema, patchSessionSchema, type SyncInput } from "@/lib/validate-sessions";

export interface SyncOpResult {
  opId: string;
  ok: boolean;
  error?: string;
  retryable?: boolean;
}

type Op = SyncInput["ops"][number];

// SPEC: A21.2 — the retired chat op: an ApiError, so the result is ok:false, retryable:false (the phone holds it — 5.6.3 poison)
const chatRetired = () => apiError("chatRetired", "Crew chat was retired; this message can't be sent.", HttpStatus.badRequest);
// SPEC: A22 — the retired post op: meal and text posts left the product; the phone holds the op, the batch lands
const postsRetired = () => apiError("postsRetired", "Meal and text posts were retired; this post can't be created.", HttpStatus.badRequest);

async function runContentOp(userId: ObjectId, op: Op, timezone: string): Promise<boolean> {
  if (op.kind === "createSession") { await createSession(userId, createSessionSchema.parse({ timezone, ...op.payload })); return true; }
  if (op.kind === "patchSession") {
    const { sessionId, ...rest } = op.payload as { sessionId: string };
    await patchSession(userId, sessionId, patchSessionSchema.parse({ timezone, ...rest }));
    return true;
  }
  if (op.kind === "createPost") throw postsRetired();
  if (op.kind === "deletePost") { await deletePostByClientId(userId, deletePostOpSchema.parse(op.payload).clientId); return true; }
  if (op.kind === "putPlan") { await replacePlan(userId, putPlanSchema.parse(op.payload)); return true; }
  return false;
}

async function runSocialOp(userId: ObjectId, op: Op, timezone: string): Promise<boolean> {
  if (op.kind === "sendMessage") throw chatRetired();
  if (op.kind === "react") {
    const { postId, emoji } = op.payload as { postId: string; emoji: string };
    await react(userId, await reactablePost(userId, postId), reactionSchema.parse({ emoji }).emoji, timezone);
    return true;
  }
  if (op.kind === "unreact") { await unreact(userId, await reactablePost(userId, (op.payload as { postId: string }).postId)); return true; }
  if (op.kind === "pause") {
    const { startDay, endDay } = op.payload as { startDay: string; endDay: string };
    await createPause(userId, dayKeySchema.parse(startDay), dayKeySchema.parse(endDay), timezone);
    return true;
  }
  if (op.kind === "pushToken") {
    const body = pushTokenSchema.parse(op.payload);
    await (await pushTokens()).updateOne({ token: body.token }, { $set: { userId, platform: "ios", updatedAt: new Date() }, $setOnInsert: { _id: new ObjectId() } }, { upsert: true });
    return true;
  }
  return false;
}

export async function replayOps(userId: ObjectId, input: SyncInput): Promise<SyncOpResult[]> {
  const results: SyncOpResult[] = [];
  for (const op of input.ops) {
    try {
      const handled = (await runContentOp(userId, op, input.timezone)) || (await runSocialOp(userId, op, input.timezone)) || (await runNutritionOp(userId, op, input.timezone));
      if (!handled) throw Object.assign(new Error(`sync op kind ${op.kind} is not accepted yet`), { retryable: true });
      results.push({ opId: op.opId, ok: true });
    } catch (error) {
      if (error instanceof ZodError) results.push({ opId: op.opId, ok: false, error: "validation", retryable: false });
      else if (isApiError(error)) results.push({ opId: op.opId, ok: false, error: error.code, retryable: false });
      else results.push({ opId: op.opId, ok: false, error: error instanceof Error ? error.message : "failed", retryable: (error as { retryable?: boolean }).retryable ?? true });
    }
  }
  return results;
}
