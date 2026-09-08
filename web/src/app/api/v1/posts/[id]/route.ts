// SPEC: docs/api.md posts/[id] — GET own (or a crew-mate's); PATCH caption (photos never editable, E3); DELETE keeps the log
// and never retro-breaks the streak (E3) — the server recompute is the truth · T026
import { ObjectId } from "mongodb";
import { errorResponse, json, notFound } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { crewMemberships, posts } from "@/lib/db";
import { logEvent } from "@/lib/events";
import { recomputeAndStore } from "@/lib/gamification-store";
import { postResponse } from "@/lib/posts";
import { patchPostSchema } from "@/lib/validate-posts";

type Context = { params: Promise<{ id: string }> };

async function ownPost(userId: ObjectId, id: string) {
  const doc = ObjectId.isValid(id) ? await (await posts()).findOne({ _id: new ObjectId(id), userId, deletedAt: null }) : null;
  if (doc === null) throw notFound("Post");
  return doc;
}

export async function GET(req: Request, context: Context) {
  try {
    const userId = new ObjectId(await requireUser(req));
    const { id } = await context.params;
    const doc = ObjectId.isValid(id) ? await (await posts()).findOne({ _id: new ObjectId(id), deletedAt: null }) : null;
    if (doc === null) throw notFound("Post");
    if (!doc.userId.equals(userId)) {
      const mate = doc.crewId === null ? null : await (await crewMemberships()).findOne({ userId, crewId: doc.crewId });
      if (mate === null) throw notFound("Post");
    }
    return json({ post: postResponse(doc) });
  } catch (error) {
    return errorResponse(error);
  }
}

export async function PATCH(req: Request, context: Context) {
  try {
    const userId = await requireUser(req);
    const { id } = await context.params;
    const body = patchPostSchema.parse(await req.json());
    const doc = await ownPost(new ObjectId(userId), id);
    await (await posts()).updateOne({ _id: doc._id }, { $set: { caption: body.caption } });
    return json({ post: postResponse({ ...doc, caption: body.caption }) });
  } catch (error) {
    return errorResponse(error);
  }
}

export async function DELETE(req: Request, context: Context) {
  try {
    const userId = await requireUser(req);
    const { id } = await context.params;
    const doc = await ownPost(new ObjectId(userId), id);
    await (await posts()).updateOne({ _id: doc._id }, { $set: { deletedAt: new Date() } });
    const gamification = await recomputeAndStore(userId);
    await logEvent(userId, "post_deleted", { kind: doc.type });
    return json({ ok: true, gamification });
  } catch (error) {
    return errorResponse(error);
  }
}
