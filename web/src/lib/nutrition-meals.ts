// SPEC: nutrition addendum §2, §4 (RATIFIED 2026-09-18) — saved meals and the daily template. A meal is a name and three integers;
// a seed-sourced meal COPIES the grams at save time (a later seed edit never rewrites history); deleting a meal removes its template
// slots; the template is a checklist of 0–dayTemplateMaxSlots slots, never a requirement. Idempotent on clientId (8.2 ④).
import { ObjectId } from "mongodb";
import { apiError, notFound } from "@/lib/api-error";
import { dayTemplates, savedMeals } from "@/lib/db";
import type { SavedMealDoc } from "@/lib/documents-nutrition";
import { HttpStatus } from "@/lib/http-status";
import type { PatchSavedMealInput, PutTemplateInput, SavedMealInput } from "@/lib/validate-nutrition";
import { fastFood } from "@/generated/seed";
import { SpecConstants } from "@/generated/spec-constants";

export interface SavedMealResponse { id: string; clientId: string; name: string; proteinG: number; carbsG: number; fatG: number; source: SavedMealDoc["source"]; createdAt: string }
export interface TemplateSlotResponse { savedMealId: string; label: string; meal: SavedMealResponse }

export function savedMealResponse(doc: SavedMealDoc): SavedMealResponse {
  return { id: doc._id.toHexString(), clientId: doc.clientId, name: doc.name, proteinG: doc.proteinG, carbsG: doc.carbsG, fatG: doc.fatG, source: doc.source, createdAt: doc.createdAt.toISOString() };
}

export async function listSavedMeals(userId: ObjectId): Promise<SavedMealDoc[]> {
  return (await savedMeals()).find({ userId, deletedAt: null }).sort({ createdAt: 1 }).toArray();
}

// The server id, or the clientId a phone created it with offline (the sessions precedent)
export async function findOwnMeal(userId: ObjectId, id: string): Promise<SavedMealDoc> {
  const collection = await savedMeals();
  const doc = ObjectId.isValid(id) ? await collection.findOne({ _id: new ObjectId(id), userId, deletedAt: null }) : await collection.findOne({ clientId: id, userId, deletedAt: null });
  if (doc === null) throw notFound("Saved meal");
  return doc;
}

export async function createSavedMeal(userId: ObjectId, input: SavedMealInput, now: Date = new Date()): Promise<{ meal: SavedMealDoc; created: boolean }> {
  const collection = await savedMeals();
  const existing = await collection.findOne({ clientId: input.clientId });
  if (existing !== null) return { meal: existing, created: false };
  if (input.seed !== undefined && !fastFood.items.some((item) => item.id === input.seed?.itemId && item.chainId === input.seed.chainId)) throw apiError("validation", "That item isn't in the list.", HttpStatus.badRequest);
  if ((await collection.countDocuments({ userId, deletedAt: null })) >= SpecConstants.savedMealsMax) throw apiError("savedMealsFull", `You can keep ${SpecConstants.savedMealsMax} saved meals. Delete one to add another.`, HttpStatus.conflict);
  const source: SavedMealDoc["source"] = input.seed === undefined ? { kind: "manual" } : { kind: "seed", chainId: input.seed.chainId, itemId: input.seed.itemId };
  const meal: SavedMealDoc = { _id: new ObjectId(), clientId: input.clientId, userId, name: input.name, proteinG: input.proteinG, carbsG: input.carbsG, fatG: input.fatG, source, createdAt: now, deletedAt: null };
  await collection.insertOne(meal);
  return { meal, created: true };
}

export async function patchSavedMeal(userId: ObjectId, id: string, input: PatchSavedMealInput): Promise<SavedMealDoc> {
  const meal = await findOwnMeal(userId, id);
  const changes = Object.fromEntries(Object.entries(input).filter(([, value]) => value !== undefined));
  await (await savedMeals()).updateOne({ _id: meal._id }, { $set: changes });
  return { ...meal, ...changes };
}

// SPEC: §2 — "deleting the meal removes the slot"; logs keep their own copy of the name and the grams, so history is untouched
export async function deleteSavedMeal(userId: ObjectId, id: string, now: Date = new Date()): Promise<void> {
  const meal = await findOwnMeal(userId, id);
  await (await savedMeals()).updateOne({ _id: meal._id }, { $set: { deletedAt: now } });
  await (await dayTemplates()).updateOne({ userId }, { $pull: { slots: { savedMealId: meal._id } }, $set: { updatedAt: now } });
}

export async function templateSlots(userId: ObjectId): Promise<TemplateSlotResponse[]> {
  const template = await (await dayTemplates()).findOne({ userId });
  if (template === null) return [];
  const meals = new Map((await listSavedMeals(userId)).map((meal) => [meal._id.toHexString(), meal]));
  return template.slots.flatMap((slot) => {
    const meal = meals.get(slot.savedMealId.toHexString());
    return meal === undefined ? [] : [{ savedMealId: meal._id.toHexString(), label: slot.label, meal: savedMealResponse(meal) }];
  });
}

export async function putTemplate(userId: ObjectId, input: PutTemplateInput, now: Date = new Date()): Promise<TemplateSlotResponse[]> {
  const slots: { savedMealId: ObjectId; label: string }[] = [];
  for (const slot of input.slots) slots.push({ savedMealId: (await findOwnMeal(userId, slot.savedMealId))._id, label: slot.label ?? "" });
  await (await dayTemplates()).updateOne({ userId }, { $set: { slots, updatedAt: now }, $setOnInsert: { _id: new ObjectId(), userId } }, { upsert: true });
  return templateSlots(userId);
}
