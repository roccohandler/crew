// SPEC: docs/api.md POST sync — replay the offline queue IN ORDER, each op idempotent; per-op results, never a failed batch;
// the server gamification state REPLACES the client's (5.6.3). Op kinds map to the same lib functions the routes use. T023/T030/T041
import { ObjectId } from "mongodb";
import { ZodError } from "zod";
import { isApiError } from "@/lib/api-error";
import { sendMessage } from "@/lib/crew-messages";
import { pushTokens } from "@/lib/db";
import { createPause } from "@/lib/pauses";
import { replacePlan } from "@/lib/plans";
import { createPost, deletePostByClientId } from "@/lib/posts";
import { react, reactablePost, unreact } from "@/lib/reactions";
import { createSession, patchSession } from "@/lib/sessions";
import { dayKeySchema, pushTokenSchema } from "@/lib/validate";
import { sendMessageSchema } from "@/lib/validate-crews";
import { putPlanSchema } from "@/lib/validate-plans";
import { createPostSchema, deletePostOpSchema, reactionSchema } from "@/lib/validate-posts";
import { createSessionSchema, patchSessionSchema, type SyncInput } from "@/lib/validate-sessions";

export interface SyncOpResult {
  opId: string;
  ok: boolean;
  error?: string;
  retryable?: boolean;
}

type Op = SyncInput["ops"][number];

async function runContentOp(userId: ObjectId, op: Op, timezone: string): Promise<boolean> {
  if (op.kind === "createSession") { await createSession(userId, createSessionSchema.parse({ timezone, ...op.payload })); return true; }
  if (op.kind === "patchSession") {
    const { sessionId, ...rest } = op.payload as { sessionId: string };
    await patchSession(userId, sessionId, patchSessionSchema.parse({ timezone, ...rest }));
    return true;
  }
  if (op.kind === "createPost") {
    const body = createPostSchema.parse({ timezone, ...op.payload });
    await createPost(userId, { ...body, sessionId: body.sessionId ? new ObjectId(body.sessionId) : undefined, createdAt: body.createdAt ? new Date(body.createdAt) : undefined });
    return true;
  }
  if (op.kind === "deletePost") { await deletePostByClientId(userId, deletePostOpSchema.parse(op.payload).clientId); return true; }
  if (op.kind === "putPlan") { await replacePlan(userId, putPlanSchema.parse(op.payload)); return true; }
  return false;
}

async function runSocialOp(userId: ObjectId, op: Op, timezone: string): Promise<boolean> {
  if (op.kind === "sendMessage") {
    const { crewId, ...rest } = op.payload as { crewId: string };
    const body = sendMessageSchema.parse(rest);
    await sendMessage(userId, crewId, body.clientId, body.body);
    return true;
  }
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
      const handled = (await runContentOp(userId, op, input.timezone)) || (await runSocialOp(userId, op, input.timezone));
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
