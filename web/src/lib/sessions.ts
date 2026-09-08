// SPEC: docs/api.md sessions — create with the workout snapshot (immune to later plan edits; idempotent on clientId), patch
// set logs (warm-ups excluded from x/y, holds by seconds, done/asPlanned per V33), completion per V32 creates the workout
// Post (post ≠ log, E3) and recomputes. Part IX Session/SessionExercise/SetLog. Mirrors ApiSessions.swift.
import { ObjectId } from "mongodb";
import { notFound } from "@/lib/api-error";
import { sessions } from "@/lib/db";
import type { SessionDoc, SessionExerciseDoc, SetLogDoc } from "@/lib/documents";
import { asPlanned, completionFacts } from "@/lib/engine/completion";
import { createPost } from "@/lib/posts";
import { serverDayKey } from "@/lib/server-clock";
import type { CreateSessionInput, PatchSessionInput } from "@/lib/validate-sessions";

type ExerciseInput = CreateSessionInput["workoutSnapshot"]["exercises"][number];

function toSetLog(input: ExerciseInput["sets"][number]): SetLogDoc {
  return { ...input, weight: input.weight ?? null, holdSeconds: input.holdSeconds ?? null, asPlanned: asPlanned({ targetReps: input.targetReps, actualReps: input.actualReps, done: input.done, isWarmup: input.isWarmup }) };
}

function toExercise(input: ExerciseInput): SessionExerciseDoc {
  return { exerciseId: input.exerciseId, name: input.name, equipment: input.equipment, type: input.type, targetSets: input.targetSets, targetReps: input.targetReps, holdSeconds: input.holdSeconds ?? null, order: input.order, skipped: input.skipped ?? false, sets: input.sets.map(toSetLog) };
}

export function sessionResponse(doc: SessionDoc) {
  const workSets = doc.exercises.flatMap((exercise) => exercise.sets);
  const facts = completionFacts(workSets.map((set) => ({ targetReps: set.targetReps, actualReps: set.actualReps, done: set.done, isWarmup: set.isWarmup })));
  return {
    id: doc._id.toHexString(), clientId: doc.clientId, dayKey: doc.dayKey, status: doc.status, workoutName: doc.workoutName, isPlannedDay: doc.isPlannedDay,
    startedAt: doc.startedAt.toISOString(), completedAt: doc.completedAt?.toISOString() ?? null, timezone: doc.timezone, exercises: doc.exercises,
    setsDone: facts.setsDone, setsPlanned: facts.setsPlanned, setsAsPlanned: facts.setsAsPlanned, updatedAt: doc.updatedAt.toISOString(),
  };
}

// `id` is the server id (web) or the session's clientId (an iPhone that created it offline knows nothing else — 5.6.3 replay)
export async function findOwnSession(userId: ObjectId, id: string): Promise<SessionDoc> {
  const collection = await sessions();
  const doc = ObjectId.isValid(id) ? await collection.findOne({ _id: new ObjectId(id), userId }) : await collection.findOne({ clientId: id, userId });
  if (doc === null) throw notFound("Session");
  return doc;
}

export async function createSession(userId: ObjectId, input: CreateSessionInput, now: Date = new Date()): Promise<{ session: SessionDoc; created: boolean }> {
  const collection = await sessions();
  const existing = await collection.findOne({ clientId: input.clientId });
  if (existing !== null) return { session: existing, created: false };
  const startedAt = new Date(input.startedAt);
  const doc: SessionDoc = {
    _id: new ObjectId(), clientId: input.clientId, userId, dayKey: serverDayKey(startedAt, input.timezone, now), status: "inProgress",
    workoutName: input.workoutSnapshot.name, isPlannedDay: input.workoutSnapshot.isPlannedDay, startedAt, completedAt: null, timezone: input.timezone,
    exercises: input.workoutSnapshot.exercises.map(toExercise), updatedAt: now,
  };
  await collection.insertOne(doc);
  return { session: doc, created: true };
}

// SPEC: V32 — ≥1 work set done = complete; a completion with zero work sets stays in progress (nothing counted)
export async function patchSession(userId: ObjectId, id: string, input: PatchSessionInput, now: Date = new Date()): Promise<SessionDoc> {
  const doc = await findOwnSession(userId, id);
  if (doc.status === "completed") return doc; // completion is final: later edits change stats via PATCH sets only (V36)
  if (input.exercises !== undefined) doc.exercises = input.exercises.map(toExercise);
  if (input.status === "discarded") doc.status = "discarded";
  if (input.status === "completed") {
    const facts = completionFacts(doc.exercises.flatMap((exercise) => exercise.sets));
    if (facts.complete) {
      doc.status = "completed";
      doc.completedAt = input.completedAt ? new Date(input.completedAt) : now;
      doc.dayKey = serverDayKey(doc.completedAt, input.timezone, now); // V07: keyed by completion
      await createPost(userId, {
        clientId: input.post?.clientId ?? `${doc.clientId}-post`, type: "workout", sessionId: doc._id, caption: input.post?.caption, photoKey: input.post?.photoKey,
        shareToCrew: input.post?.shareToCrew ?? false, timezone: input.timezone, isPlannedDay: doc.isPlannedDay, workoutCompleted: true, createdAt: doc.completedAt, dayKey: doc.dayKey,
      }, now);
    }
  }
  doc.updatedAt = now;
  await (await sessions()).replaceOne({ _id: doc._id }, doc);
  return doc;
}
