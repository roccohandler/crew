// SPEC: Flow 6 (the chat IS the comment section) · E20 (chat ≤ 1,000 chars; delete own messages = tombstone) · E2 (Captain
// removes content) · docs/api.md messages. T030
import { ObjectId } from "mongodb";
import { forbidden, notFound } from "@/lib/api-error";
import { requireMember } from "@/lib/crews";
import { messages } from "@/lib/db";
import type { MessageDoc } from "@/lib/documents-social";

export function messageResponse(doc: MessageDoc) {
  return { id: doc._id.toHexString(), kind: doc.kind, userId: doc.userId.toHexString(), body: doc.deletedAt === null ? doc.body : "", deleted: doc.deletedAt !== null, createdAt: doc.createdAt.toISOString() };
}

// SPEC: 8.2 ④ — idempotent on clientId
export async function sendMessage(userId: ObjectId, crewId: string, clientId: string, body: string, now: Date = new Date()): Promise<{ message: MessageDoc; created: boolean }> {
  const { crew } = await requireMember(userId, crewId);
  const collection = await messages();
  const existing = await collection.findOne({ clientId });
  if (existing !== null) return { message: existing, created: false };
  const doc: MessageDoc = { _id: new ObjectId(), clientId, crewId: crew._id, userId, kind: "message", body, createdAt: now, deletedAt: null };
  await collection.insertOne(doc);
  return { message: doc, created: true };
}

export async function deleteMessage(userId: ObjectId, crewId: string, messageId: string, now: Date = new Date()): Promise<void> {
  const { crew } = await requireMember(userId, crewId);
  const collection = await messages();
  const doc = ObjectId.isValid(messageId) ? await collection.findOne({ _id: new ObjectId(messageId), crewId: crew._id, kind: "message" }) : null;
  if (doc === null) throw notFound("Message");
  if (!doc.userId.equals(userId) && !crew.captainId.equals(userId)) throw forbidden("Only the sender or the Captain can delete a message.");
  await collection.updateOne({ _id: doc._id }, { $set: { deletedAt: now } });
}
