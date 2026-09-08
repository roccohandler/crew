// SPEC: docs/api.md POST posts (server dayKey — E15; idempotent on clientId — 8.2 ④; same-day backfill only; rate-limited —
// G11; recompute — 5.6.4) · GET posts?from=&to= (the journal keeps everything forever, Flow 6) · T026/T027
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { posts } from "@/lib/db";
import { logEvent } from "@/lib/events";
import { recomputeAndStore } from "@/lib/gamification-store";
import { createPost, postResponse } from "@/lib/posts";
import { limitPostCreation } from "@/lib/rate-limit";
import { dayKeySchema } from "@/lib/validate";
import { createPostSchema } from "@/lib/validate-posts";
import { HttpStatus } from "@/lib/http-status";

export async function POST(req: Request) {
  try {
    const userId = await requireUser(req);
    const body = createPostSchema.parse(await req.json());
    await limitPostCreation(userId);
    const { post, created } = await createPost(new ObjectId(userId), { ...body, sessionId: body.sessionId ? new ObjectId(body.sessionId) : undefined, createdAt: body.createdAt ? new Date(body.createdAt) : undefined });
    const gamification = await recomputeAndStore(userId);
    if (created) await logEvent(userId, "post_created", { kind: body.type, shared: post.crewId !== null, hasPhoto: post.photoKey !== null });
    return json({ post: postResponse(post), gamification }, created ? HttpStatus.created : HttpStatus.ok);
  } catch (error) {
    return errorResponse(error);
  }
}

export async function GET(req: Request) {
  try {
    const userId = await requireUser(req);
    const url = new URL(req.url);
    const range: Record<string, string> = {};
    const from = url.searchParams.get("from");
    const to = url.searchParams.get("to");
    if (from !== null) range.$gte = dayKeySchema.parse(from);
    if (to !== null) range.$lte = dayKeySchema.parse(to);
    const filter = { userId: new ObjectId(userId), deletedAt: null, ...(Object.keys(range).length > 0 ? { dayKey: range } : {}) };
    const docs = await (await posts()).find(filter).sort({ createdAt: -1 }).toArray();
    return json({ items: docs.map(postResponse) });
  } catch (error) {
    return errorResponse(error);
  }
}
