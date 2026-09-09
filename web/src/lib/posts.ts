// SPEC: docs/api.md posts — create (server dayKey, idempotent on clientId), the journal shape, delete keeps the log (E3).
// Shared by the posts route (T026/T027), session completion (S10: your workout is now a POST) and sync. Part IX Post.
// A6: a workout post carries the summary line the server wrote at completion; it rides into the journal and the crew stream.
import { ObjectId } from "mongodb";
import { crewMemberships, posts } from "@/lib/db";
import type { PostDoc } from "@/lib/documents-social";
import { serverDayKey } from "@/lib/server-clock";

export interface NewPost {
  clientId: string;
  type: "workout" | "meal" | "text";
  sessionId?: ObjectId;
  photoKey?: string;
  caption?: string;
  mealTag?: "breakfast" | "lunch" | "dinner" | "snack";
  shareToCrew: boolean;
  timezone: string;
  isPlannedDay: boolean;
  workoutCompleted: boolean;
  earlierToday?: boolean;
  summary?: string; // A6: set by session completion only; clients never send one
  createdAt?: Date; // the client's creation instant, reconciled by server-clock.ts
  dayKey?: string; // sessions pass their own (completion) dayKey
}

export interface PostResponse {
  id: string;
  clientId: string; // the id the creating client chose — a phone addresses its journal by it (hydration, deletePost)
  type: PostDoc["type"];
  sessionId: string | null;
  photoKey: string | null;
  caption: string;
  mealTag: PostDoc["mealTag"];
  crewId: string | null;
  dayKey: string;
  isPlannedDay: boolean;
  workoutCompleted: boolean;
  earlierToday: boolean;
  summary: string | null; // A6
  createdAt: string;
}

export function postResponse(doc: PostDoc): PostResponse {
  return {
    id: doc._id.toHexString(), clientId: doc.clientId, type: doc.type, sessionId: doc.sessionId?.toHexString() ?? null, photoKey: doc.photoKey, caption: doc.caption,
    mealTag: doc.mealTag, crewId: doc.crewId?.toHexString() ?? null, dayKey: doc.dayKey, isPlannedDay: doc.isPlannedDay,
    workoutCompleted: doc.workoutCompleted, earlierToday: doc.earlierToday, summary: doc.summary ?? null, createdAt: doc.createdAt.toISOString(),
  };
}

export async function currentCrewId(userId: ObjectId): Promise<ObjectId | null> {
  const membership = await (await crewMemberships()).findOne({ userId });
  return membership?.crewId ?? null;
}

// SPEC: 8.2 ④ idempotent on clientId · E15 server clock · Flow 10 (solo: the post goes to the private journal)
export async function createPost(userId: ObjectId, input: NewPost, now: Date = new Date()): Promise<{ post: PostDoc; created: boolean }> {
  const collection = await posts();
  const existing = await collection.findOne({ clientId: input.clientId });
  if (existing !== null) return { post: existing, created: false };
  const createdAt = input.createdAt ?? now;
  const doc: PostDoc = {
    _id: new ObjectId(),
    clientId: input.clientId,
    userId,
    type: input.type,
    sessionId: input.sessionId ?? null,
    photoKey: input.photoKey ?? null,
    caption: input.caption ?? "",
    mealTag: input.mealTag ?? null,
    crewId: input.shareToCrew ? await currentCrewId(userId) : null,
    dayKey: input.dayKey ?? serverDayKey(createdAt, input.timezone, now),
    isPlannedDay: input.isPlannedDay,
    workoutCompleted: input.workoutCompleted,
    earlierToday: input.earlierToday ?? false,
    createdAt: createdAt.getTime() <= now.getTime() ? createdAt : now,
    deletedAt: null,
  };
  if (input.summary !== undefined) doc.summary = input.summary;
  await collection.insertOne(doc);
  return { post: doc, created: true };
}

// SPEC: 5.6.3 replay — an iPhone deletes a post it may have created offline, so it names the clientId; idempotent (E3: the
// log and the streak are untouched; the server recompute after the batch is the truth)
export async function deletePostByClientId(userId: ObjectId, clientId: string, now: Date = new Date()): Promise<void> {
  await (await posts()).updateOne({ userId, clientId, deletedAt: null }, { $set: { deletedAt: now } });
}
