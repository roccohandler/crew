// SPEC: nutrition addendum §2–§3 (RATIFIED 2026-09-18) — the targets document: derive from the bodyweight, or keep the three grams
// the user typed (source manual); "Recalculate" is a PUT without grams. Deleting the targets deletes the bodyweight with it (V64,
// E1's exception); `everything` is Settings' "Delete my nutrition data" — targets + saved meals + template + logs, one cascade.
// No function here touches gamification (clause ③).
import { ObjectId } from "mongodb";
import { dayTemplates, mealLogs, nutritionTargets, savedMeals } from "@/lib/db";
import type { NutritionTargetsDoc } from "@/lib/documents-nutrition";
import { deriveTargets, type MacroTargets } from "@/lib/engine/nutrition-targets";
import { bodyweightTenthsOf, type PutTargetsInput } from "@/lib/validate-nutrition";
import { SpecConstants } from "@/generated/spec-constants";

export interface TargetsResponse {
  bodyweight: number; // in `unit`, to one decimal
  unit: "lb" | "kg";
  proteinG: number;
  carbsG: number;
  fatG: number;
  source: "derived" | "manual";
  estimate: MacroTargets; // what the bodyweight derives today — the A16.a screen and "Recalculate" read it
  updatedAt: string;
}

export function targetsResponse(doc: NutritionTargetsDoc): TargetsResponse {
  return {
    bodyweight: doc.bodyweightTenths / SpecConstants.bodyweightEntryScale, unit: doc.bodyweightUnit, proteinG: doc.proteinG, carbsG: doc.carbsG, fatG: doc.fatG,
    source: doc.source, estimate: deriveTargets(doc.bodyweightTenths, doc.bodyweightUnit), updatedAt: doc.updatedAt.toISOString(),
  };
}

export async function findTargets(userId: ObjectId): Promise<NutritionTargetsDoc | null> {
  return (await nutritionTargets()).findOne({ userId });
}

export async function putTargets(userId: ObjectId, input: PutTargetsInput, now: Date = new Date()): Promise<NutritionTargetsDoc> {
  const bodyweightTenths = bodyweightTenthsOf(input.bodyweight);
  const derived = deriveTargets(bodyweightTenths, input.unit);
  const manual = input.proteinG !== undefined && input.carbsG !== undefined && input.fatG !== undefined;
  const grams = manual ? { proteinG: input.proteinG ?? 0, carbsG: input.carbsG ?? 0, fatG: input.fatG ?? 0 } : { proteinG: derived.proteinG, carbsG: derived.carbsG, fatG: derived.fatG };
  const fields = { bodyweightTenths, bodyweightUnit: input.unit, ...grams, source: manual ? ("manual" as const) : ("derived" as const), updatedAt: now };
  await (await nutritionTargets()).updateOne({ userId }, { $set: fields, $setOnInsert: { _id: new ObjectId(), userId } }, { upsert: true });
  const stored = await findTargets(userId);
  if (stored === null) throw new Error("targets vanished after upsert");
  return stored;
}

// SPEC: V64 — one tap, and no bodyweight is left anywhere; `everything` clears the whole nutrition surface for this user
export async function deleteTargets(userId: ObjectId, everything: boolean): Promise<void> {
  await (await nutritionTargets()).deleteOne({ userId });
  if (!everything) return;
  await Promise.all([(await savedMeals()).deleteMany({ userId }), (await dayTemplates()).deleteMany({ userId }), (await mealLogs()).deleteMany({ userId })]);
}
