// SPEC: docs/api.md sessions — create with the workout snapshot (immune to later plan edits; idempotent on clientId), patch
// set logs (warm-ups excluded from x/y, holds by seconds, done/asPlanned per V33), completion per V32 creates the workout
// Post (post ≠ log, E3) and recomputes. Part IX Session/SessionExercise/SetLog. A1: the snapshot's kind is stored (the
// rotation pointer reads it). A2: cardio rows carry distanceMeters. A6: the post gets its summary line here. Mirrors ApiSessions.swift.
import { ObjectId } from "mongodb";
import { notFound } from "@/lib/api-error";
import { sessions, users } from "@/lib/db";
import type { SessionDoc, SessionExerciseDoc, SetLogDoc } from "@/lib/documents";
import { asPlanned, completionFacts } from "@/lib/engine/completion";
import { sessionSummaryLine } from "@/lib/engine/session-summary-line";
import { createPost } from "@/lib/posts";
import { distanceUnitOf } from "@/lib/users";
import { serverDayKey } from "@/lib/server-clock";
import { TimeUnits } from "@/lib/time-units";
import type { CreateSessionInput, PatchSessionInput } from "@/lib/validate-sessions";

type ExerciseInput = CreateSessionInput["workoutSnapshot"]["exercises"][number];

function toSetLog(input: ExerciseInput["sets"][number]): SetLogDoc {
  return {
    ...input, weight: input.weight ?? null, holdSeconds: input.holdSeconds ?? null, distanceMeters: input.distanceMeters ?? null,
    // A9: stored only when the client named it — an absent unit stays absent and reads back as the account's own
    weightUnit: input.weightUnit ?? undefined,
    asPlanned: asPlanned({ targetReps: input.targetReps, actualReps: input.actualReps, done: input.done, isWarmup: input.isWarmup }),
  };
}

function toExercise(input: ExerciseInput): SessionExerciseDoc {
  return { exerciseId: input.exerciseId, name: input.name, equipment: input.equipment, type: input.type, targetSets: input.targetSets, targetReps: input.targetReps, holdSeconds: input.holdSeconds ?? null, order: input.order, skipped: input.skipped ?? false, sets: input.sets.map(toSetLog) };
}

function factsOf(doc: SessionDoc) {
  return completionFacts(doc.exercises.flatMap((exercise) => exercise.sets).map((set) => ({ targetReps: set.targetReps, actualReps: set.actualReps, done: set.done, isWarmup: set.isWarmup })));
}

export function sessionResponse(doc: SessionDoc) {
  const facts = factsOf(doc);
  return {
    id: doc._id.toHexString(), clientId: doc.clientId, dayKey: doc.dayKey, status: doc.status, workoutName: doc.workoutName, workoutKind: doc.workoutKind ?? null, isPlannedDay: doc.isPlannedDay,
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
    workoutName: input.workoutSnapshot.name, workoutKind: input.workoutSnapshot.kind ?? null, isPlannedDay: input.workoutSnapshot.isPlannedDay, startedAt, completedAt: null,
    timezone: input.timezone, exercises: input.workoutSnapshot.exercises.map(toExercise), updatedAt: now,
  };
  await collection.insertOne(doc);
  return { session: doc, created: true };
}

// SPEC: A6 — the post's one readable line, from the session's own facts at completion: strength "Push day · 12/12 sets · 44 min",
// cardio "Walk · 25 min · 2.1 km" in the poster's units (the twin SessionSummaryLine.swift formats the same inputs)
async function summaryFor(userId: ObjectId, doc: SessionDoc, completedAt: Date): Promise<string> {
  const user = await (await users()).findOne({ _id: userId }, { projection: { units: 1 } });
  const facts = factsOf(doc);
  const cardioSets = doc.exercises.filter((exercise) => exercise.type === "cardio").flatMap((exercise) => exercise.sets).filter((set) => set.done && !set.isWarmup);
  const cardioSeconds = cardioSets.reduce((sum, set) => sum + (set.holdSeconds ?? 0), 0);
  const distance = cardioSets.some((set) => typeof set.distanceMeters === "number") ? cardioSets.reduce((sum, set) => sum + (set.distanceMeters ?? 0), 0) : null;
  const minutes = Math.round((completedAt.getTime() - doc.startedAt.getTime()) / TimeUnits.msPerMinute);
  const cardioMinutes = cardioSets.length > 0 ? Math.round(cardioSeconds / TimeUnits.secondsPerMinute) : null;
  return sessionSummaryLine(doc.workoutName, doc.workoutKind === "cardio", facts.setsDone, facts.setsPlanned, minutes, cardioMinutes, distance, user === null || user === undefined ? "mi" : distanceUnitOf(user));
}

// SPEC: V32 — ≥1 work set done = complete (a done cardio set is a work set, V51); completion keys the day (V07) and creates the workout post
async function completeSession(userId: ObjectId, doc: SessionDoc, input: PatchSessionInput, now: Date): Promise<void> {
  if (!factsOf(doc).complete) return;
  doc.status = "completed";
  doc.completedAt = input.completedAt ? new Date(input.completedAt) : now;
  doc.dayKey = serverDayKey(doc.completedAt, input.timezone, now);
  await createPost(userId, {
    clientId: input.post?.clientId ?? `${doc.clientId}-post`, type: doc.workoutKind === "cardio" ? "cardio" : "workout", sessionId: doc._id, // A14: a standalone cardio log is not a workout caption: input.post?.caption, photoKey: input.post?.photoKey,
    shareToCrew: input.post?.shareToCrew ?? false, timezone: input.timezone, isPlannedDay: doc.isPlannedDay, workoutCompleted: true, createdAt: doc.completedAt, dayKey: doc.dayKey,
    summary: await summaryFor(userId, doc, doc.completedAt),
  }, now);
}

// SPEC: V32 — a completion with zero work sets stays in progress (nothing counted)
export async function patchSession(userId: ObjectId, id: string, input: PatchSessionInput, now: Date = new Date()): Promise<SessionDoc> {
  const doc = await findOwnSession(userId, id);
  if (doc.status === "completed") return doc; // completion is final: later edits change stats via PATCH sets only (V36)
  if (input.exercises !== undefined) doc.exercises = input.exercises.map(toExercise);
  if (input.status === "discarded") doc.status = "discarded";
  if (input.status === "completed") await completeSession(userId, doc, input, now);
  doc.updatedAt = now;
  await (await sessions()).replaceOne({ _id: doc._id }, doc);
  return doc;
}
