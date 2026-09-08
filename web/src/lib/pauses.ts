// SPEC: Flow 7 planned absence (pick a return date, max 3 weeks; one active pause; never retroactive; resumes automatically) ·
// V19–V23, V44 (pause-validation.ts) · docs/api.md pause. T041
import { ObjectId } from "mongodb";
import { apiError, notFound } from "@/lib/api-error";
import { pauses } from "@/lib/db";
import type { PauseDoc } from "@/lib/documents-social";
import { dayKeyFor } from "@/lib/engine/day-key";
import { validatePauseRequest } from "@/lib/engine/pause-validation";
import { HttpStatus } from "@/lib/http-status";

const REJECTIONS = {
  retroactive: { code: "pauseRetroactive", message: "A pause can start today or later, never in the past.", status: HttpStatus.badRequest },
  tooLong: { code: "pauseTooLong", message: "Pauses last three weeks at most.", status: HttpStatus.badRequest },
  alreadyPaused: { code: "alreadyPaused", message: "One pause at a time — end this one first.", status: HttpStatus.conflict },
} as const;

export function pauseResponse(doc: PauseDoc) {
  return { startDay: doc.startDay, endDay: doc.endDay };
}

// The active or scheduled pause (endDay after today), if any
export async function currentPause(userId: ObjectId, todayKey: string): Promise<PauseDoc | null> {
  return (await pauses()).findOne({ userId, endDay: { $gt: todayKey } }, { sort: { startDay: 1 } });
}

export async function createPause(userId: ObjectId, startDay: string, endDay: string, timezone: string, now: Date = new Date()): Promise<PauseDoc> {
  const today = dayKeyFor(now, timezone);
  const existing = await (await pauses()).find({ userId }).toArray();
  const verdict = validatePauseRequest(today, startDay, endDay, existing.map((doc) => ({ startDay: doc.startDay, endDay: doc.endDay })));
  if (!verdict.accepted && verdict.reason) {
    const rejection = REJECTIONS[verdict.reason];
    throw apiError(rejection.code, rejection.message, rejection.status);
  }
  const doc: PauseDoc = { _id: new ObjectId(), userId, startDay, endDay, createdAt: now };
  await (await pauses()).insertOne(doc);
  return doc;
}

// Ending early: the return day becomes today (a scheduled pause that has not started is removed)
export async function endPause(userId: ObjectId, timezone: string, now: Date = new Date()): Promise<void> {
  const today = dayKeyFor(now, timezone);
  const doc = await currentPause(userId, today);
  if (doc === null) throw notFound("Pause");
  if (doc.startDay > today) await (await pauses()).deleteOne({ _id: doc._id });
  else await (await pauses()).updateOne({ _id: doc._id }, { $set: { endDay: today } });
}
