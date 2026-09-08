// SPEC: docs/api.md posts/[id]/reactions — react (UNIQUE per user-target; a second emoji replaces the first), un-react (tap
// again, E20); only crew-mates of the post's crew may react (Flow 6); the daily XP cap is enforced by recompute (V27). T026/T030
import { ObjectId } from "mongodb";
import { apiError, notFound } from "@/lib/api-error";
import { crewMemberships, posts, reactions } from "@/lib/db";
import type { PostDoc } from "@/lib/documents-social";
import { dayKeyFor } from "@/lib/engine/day-key";
import { HttpStatus } from "@/lib/http-status";

export async function reactablePost(userId: ObjectId, postId: string): Promise<PostDoc> {
  const post = ObjectId.isValid(postId) ? await (await posts()).findOne({ _id: new ObjectId(postId), deletedAt: null }) : null;
  if (post === null) throw notFound("Post");
  if (post.crewId === null) throw apiError("notInCrew", "You can only react to posts in your crew.", HttpStatus.forbidden);
  const membership = await (await crewMemberships()).findOne({ userId, crewId: post.crewId });
  if (membership === null) throw apiError("notInCrew", "You can only react to posts in your crew.", HttpStatus.forbidden);
  return post;
}

export async function react(userId: ObjectId, post: PostDoc, emoji: string, timezone: string, now: Date = new Date()): Promise<void> {
  const collection = await reactions();
  await collection.updateOne(
    { targetType: "post", targetId: post._id, userId },
    { $set: { emoji }, $setOnInsert: { _id: new ObjectId(), targetType: "post", targetId: post._id, userId, dayKey: dayKeyFor(now, timezone), createdAt: now } },
    { upsert: true },
  );
}

export async function unreact(userId: ObjectId, post: PostDoc): Promise<boolean> {
  const result = await (await reactions()).deleteOne({ targetType: "post", targetId: post._id, userId });
  return result.deletedCount === 1;
}

export async function reactionsFor(postIds: ObjectId[]): Promise<Map<string, { emoji: string; userId: string }[]>> {
  const docs = await (await reactions()).find({ targetType: "post", targetId: { $in: postIds } }).toArray();
  const byPost = new Map<string, { emoji: string; userId: string }[]>();
  for (const doc of docs) {
    const key = doc.targetId.toHexString();
    byPost.set(key, [...(byPost.get(key) ?? []), { emoji: doc.emoji, userId: doc.userId.toHexString() }]);
  }
  return byPost;
}
