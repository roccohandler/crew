// SPEC: nutrition addendum §2, §4 (RATIFIED 2026-09-18) · V62 · V63 — meal logs. Idempotent on clientId (a template slot tapped
// twice logs once); the day is the server's (E15, the 3 AM boundary in the device's zone); a slot log COPIES the saved meal's name
// and grams at log time, so editing or deleting the meal later never rewrites a day. A log is never a game event: nothing here
// recomputes, awards or counts anything (clause ③) — and nothing here is ever read by a stream, a pulse or a profile (clause ④).
import { ObjectId } from "mongodb";
import { apiError, notFound } from "@/lib/api-error";
import { mealLogs, savedMeals } from "@/lib/db";
import type { MealLogDoc } from "@/lib/documents-nutrition";
import { HttpStatus } from "@/lib/http-status";
import { serverDayKey } from "@/lib/server-clock";
import type { CreateLogInput } from "@/lib/validate-nutrition";
import { SpecConstants } from "@/generated/spec-constants";

export interface MealLogResponse { id: string; clientId: string; dayKey: string; savedMealId: string | null; name: string; proteinG: number; carbsG: number; fatG: number; quickAdd: boolean; createdAt: string }

export function mealLogResponse(doc: MealLogDoc): MealLogResponse {
  return { id: doc._id.toHexString(), clientId: doc.clientId, dayKey: doc.dayKey, savedMealId: doc.savedMealId?.toHexString() ?? null, name: doc.name, proteinG: doc.proteinG, carbsG: doc.carbsG, fatG: doc.fatG, quickAdd: doc.quickAdd, createdAt: doc.createdAt.toISOString() };
}

export async function listLogs(userId: ObjectId, dayKey: string): Promise<MealLogDoc[]> {
  return (await mealLogs()).find({ userId, dayKey, deletedAt: null }).sort({ createdAt: 1 }).toArray();
}

// The saved meal a slot names, by server id or clientId; a meal deleted meanwhile is simply absent and the payload stands
async function mealFor(userId: ObjectId, id: string | undefined) {
  if (id === undefined) return null;
  const collection = await savedMeals();
  return ObjectId.isValid(id) ? collection.findOne({ _id: new ObjectId(id), userId, deletedAt: null }) : collection.findOne({ clientId: id, userId, deletedAt: null });
}

export async function createLog(userId: ObjectId, input: CreateLogInput, now: Date = new Date()): Promise<{ log: MealLogDoc; created: boolean }> {
  const collection = await mealLogs();
  const existing = await collection.findOne({ clientId: input.clientId });
  if (existing !== null) return { log: existing, created: false };
  const createdAt = input.createdAt === undefined ? now : new Date(input.createdAt);
  const dayKey = serverDayKey(createdAt, input.timezone, now);
  if ((await collection.countDocuments({ userId, dayKey, deletedAt: null })) >= SpecConstants.mealLogsPerDayMax) throw apiError("dayFull", "That's a lot of entries for one day. Delete one to add another.", HttpStatus.conflict);
  const meal = await mealFor(userId, input.savedMealId);
  const grams = meal === null ? { name: input.name, proteinG: input.proteinG, carbsG: input.carbsG, fatG: input.fatG } : { name: meal.name, proteinG: meal.proteinG, carbsG: meal.carbsG, fatG: meal.fatG };
  const log: MealLogDoc = { _id: new ObjectId(), clientId: input.clientId, userId, dayKey, savedMealId: meal?._id ?? null, ...grams, quickAdd: input.quickAdd, createdAt: createdAt.getTime() <= now.getTime() ? createdAt : now, deletedAt: null };
  await collection.insertOne(log);
  return { log, created: true };
}

export async function deleteLog(userId: ObjectId, id: string, now: Date = new Date()): Promise<void> {
  const collection = await mealLogs();
  const filter = ObjectId.isValid(id) ? { _id: new ObjectId(id), userId, deletedAt: null } : { clientId: id, userId, deletedAt: null };
  const result = await collection.updateOne(filter, { $set: { deletedAt: now } });
  if (result.matchedCount === 0) throw notFound("Log");
}
