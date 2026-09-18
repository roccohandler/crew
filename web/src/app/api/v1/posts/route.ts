// SPEC: docs/api.md GET posts?from=&to= (the journal keeps everything forever, Flow 6) · T026/T027. A22 (owner-approved
// 2026-09-18): POST posts is GONE — the plate journal (meal and text posts) left the product, and a workout post is created by
// the session that completes it (PATCH sessions/[id] `post`, S10 · A21.9), so no client creates a post here any more.
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { posts } from "@/lib/db";
import { postResponse } from "@/lib/posts";
import { dayKeySchema } from "@/lib/validate";

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
