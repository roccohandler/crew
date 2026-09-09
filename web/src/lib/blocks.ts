// SPEC: E9 — block any user; hides content both ways without notification (docs/api.md blocks). T034 (pulled forward for the
// stream filter and the join check). A7: the blocked list is readable so Settings can show and undo it.
import { ObjectId } from "mongodb";
import { blocks, users } from "@/lib/db";

export async function blockUser(blockerId: ObjectId, blockedId: ObjectId, now: Date = new Date()): Promise<void> {
  await (await blocks()).updateOne({ blockerId, blockedId }, { $setOnInsert: { _id: new ObjectId(), blockerId, blockedId, createdAt: now } }, { upsert: true });
}

export async function unblockUser(blockerId: ObjectId, blockedId: ObjectId): Promise<boolean> {
  const result = await (await blocks()).deleteOne({ blockerId, blockedId });
  return result.deletedCount === 1;
}

// SPEC: A7 — the people this user blocked, oldest first, with the name Settings shows ("Unblock {name}?")
export async function listBlocked(blockerId: ObjectId): Promise<{ userId: string; displayName: string }[]> {
  const docs = await (await blocks()).find({ blockerId }).sort({ createdAt: 1 }).toArray();
  const people = await (await users()).find({ _id: { $in: docs.map((doc) => doc.blockedId) } }, { projection: { displayName: 1 } }).toArray();
  return docs.map((doc) => ({ userId: doc.blockedId.toHexString(), displayName: people.find((person) => person._id.equals(doc.blockedId))?.displayName ?? "Someone" }));
}
