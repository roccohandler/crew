// SPEC: E9 — block any user; hides content both ways without notification (docs/api.md blocks). T034 (pulled forward for the
// stream filter and the join check).
import { ObjectId } from "mongodb";
import { blocks } from "@/lib/db";

export async function blockUser(blockerId: ObjectId, blockedId: ObjectId, now: Date = new Date()): Promise<void> {
  await (await blocks()).updateOne({ blockerId, blockedId }, { $setOnInsert: { _id: new ObjectId(), blockerId, blockedId, createdAt: now } }, { upsert: true });
}

export async function unblockUser(blockerId: ObjectId, blockedId: ObjectId): Promise<boolean> {
  const result = await (await blocks()).deleteOne({ blockerId, blockedId });
  return result.deletedCount === 1;
}
