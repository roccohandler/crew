// SPEC: 5.6.5 · nutrition addendum §2 (RATIFIED 2026-09-18) — one typed function per nutrition endpoint, names identical to
// ApiNutrition.swift. Split from api-client.ts for the C9 cap. Every call is the signed-in user's own private data (clauses ③ ④):
// nothing here is ever sent to a crew. An `id` is the server id or the clientId the row was created with.
import { apiFetch, deleteJson, patchJson, postJson, putJson } from "@/lib/api-client";
import type { MealLogResponse } from "@/lib/nutrition-logs";
import type { SavedMealResponse, TemplateSlotResponse } from "@/lib/nutrition-meals";
import type { TargetsResponse } from "@/lib/nutrition-targets-store";

// All three grams (manual) or none (derive from the bodyweight — this is also "Recalculate")
export interface TargetsBody { bodyweight: number; unit: "lb" | "kg"; proteinG?: number; carbsG?: number; fatG?: number }
export interface MacroBody { proteinG: number; carbsG: number; fatG: number }
export interface SavedMealBody { clientId: string; name: string; proteinG: number; carbsG: number; fatG: number; seed?: { chainId: string; itemId: string } }
export interface MealLogBody { clientId: string; timezone: string; savedMealId?: string; name: string; proteinG: number; carbsG: number; fatG: number; quickAdd: boolean }
export interface TemplateSlotBody { savedMealId: string; label?: string }

export const getNutritionTargets = async () => (await apiFetch("/nutrition/targets")) as { targets: TargetsResponse | null };
export const putNutritionTargets = async (body: TargetsBody) => (await putJson("/nutrition/targets", body)) as { targets: TargetsResponse };
export const deleteNutritionTargets = async (everything: boolean) => (await deleteJson("/nutrition/targets", { everything })) as { ok: true };

export const listSavedMeals = async () => (await apiFetch("/nutrition/saved-meals")) as { items: SavedMealResponse[] };
export const createSavedMeal = async (body: SavedMealBody) => (await postJson("/nutrition/saved-meals", body)) as { meal: SavedMealResponse };
export const patchSavedMeal = async (id: string, body: { name?: string; proteinG?: number; carbsG?: number; fatG?: number }) => (await patchJson(`/nutrition/saved-meals/${id}`, body)) as { meal: SavedMealResponse };
export const deleteSavedMeal = async (id: string) => (await deleteJson(`/nutrition/saved-meals/${id}`)) as { ok: true };

export const getDayTemplate = async () => (await apiFetch("/nutrition/template")) as { slots: TemplateSlotResponse[] };
export const putDayTemplate = async (slots: TemplateSlotBody[]) => (await putJson("/nutrition/template", { slots })) as { slots: TemplateSlotResponse[] };

export const listMealLogs = async (dayKey: string) => (await apiFetch(`/nutrition/logs?dayKey=${dayKey}`)) as { items: MealLogResponse[] };
export const createMealLog = async (body: MealLogBody) => (await postJson("/nutrition/logs", body)) as { log: MealLogResponse };
export const deleteMealLog = async (id: string) => (await deleteJson(`/nutrition/logs/${id}`)) as { ok: true };
