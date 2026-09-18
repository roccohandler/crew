// SPEC: 5.6.3 map change (nutrition addendum §2, RATIFIED 2026-09-18) — the phone's six nutrition ops: putNutritionTargets ·
// upsertSavedMeal · deleteSavedMeal · putDayTemplate · createMealLog · deleteMealLog. Each is the same lib call its route makes, behind
// the same 18+ gate (a gated account's op is a per-op refusal, never a failed batch), idempotent on the ids the phone chose. No op
// here touches gamification (clause ③). "Delete my nutrition data" is network-only, like endPause: there is no op for it.
import type { ObjectId } from "mongodb";
import { isApiError } from "@/lib/api-error";
import { requireNutrition } from "@/lib/nutrition-access";
import { createLog, deleteLog } from "@/lib/nutrition-logs";
import { createSavedMeal, deleteSavedMeal, patchSavedMeal, putTemplate } from "@/lib/nutrition-meals";
import { putTargets } from "@/lib/nutrition-targets-store";
import { createLogSchema, putTargetsSchema, putTemplateSchema, savedMealSchema } from "@/lib/validate-nutrition";
import type { SyncInput } from "@/lib/validate-sessions";

type Op = SyncInput["ops"][number];
const NUTRITION_KINDS = ["putNutritionTargets", "upsertSavedMeal", "deleteSavedMeal", "putDayTemplate", "createMealLog", "deleteMealLog"];
const idOf = (payload: Record<string, unknown>): string => (typeof payload.id === "string" ? payload.id : "");

// An upsert: the first arrival creates the meal; a later edit of the same clientId carries the new name and grams
async function upsertSavedMeal(userId: ObjectId, payload: Record<string, unknown>): Promise<void> {
  const input = savedMealSchema.parse(payload);
  const { created } = await createSavedMeal(userId, input);
  if (!created) await patchSavedMeal(userId, input.clientId, { name: input.name, proteinG: input.proteinG, carbsG: input.carbsG, fatG: input.fatG });
}

// SPEC: 5.6.3 · 8.2 ④ — a queued DELETE is idempotent: a row that is already gone (deleted on the web meanwhile, or the op replayed)
// IS the state the phone asked for, so it is delivered, never held as poison for the user to "retry" (E19 is for real failures)
async function alreadyGoneIsDone(work: Promise<void>): Promise<void> {
  try {
    await work;
  } catch (error) {
    if (!(isApiError(error) && error.code === "notFound")) throw error;
  }
}

export async function runNutritionOp(userId: ObjectId, op: Op, timezone: string): Promise<boolean> {
  if (!NUTRITION_KINDS.includes(op.kind)) return false;
  await requireNutrition(userId.toHexString());
  if (op.kind === "putNutritionTargets") await putTargets(userId, putTargetsSchema.parse(op.payload));
  if (op.kind === "upsertSavedMeal") await upsertSavedMeal(userId, op.payload);
  if (op.kind === "deleteSavedMeal") await alreadyGoneIsDone(deleteSavedMeal(userId, idOf(op.payload)));
  if (op.kind === "putDayTemplate") await putTemplate(userId, putTemplateSchema.parse(op.payload));
  if (op.kind === "createMealLog") await createLog(userId, createLogSchema.parse({ timezone, ...op.payload }));
  if (op.kind === "deleteMealLog") await alreadyGoneIsDone(deleteLog(userId, idOf(op.payload)));
  return true;
}
