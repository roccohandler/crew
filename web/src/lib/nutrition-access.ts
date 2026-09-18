// SPEC: A16.c · nutrition addendum §6 · A22 G3 (owner-approved 2026-09-18) — the gate every nutrition route passes first. Under 18
// the surface DOES NOT EXIST: the routes answer 404 like any unknown path — no copy, no upsell, no "unlock at 18". An account with
// no birth year (Sign in with Apple, or made before the year was stored) is asked for it once, when Nutrition is opened — the routes
// answer `birthYearRequired` until then. The arithmetic is the NutritionGate twin's (V65).
import { apiError, notFound } from "@/lib/api-error";
import type { UserDoc } from "@/lib/documents";
import { availability, type NutritionAvailability } from "@/lib/engine/nutrition-gate";
import { HttpStatus } from "@/lib/http-status";
import { findUserById } from "@/lib/users";

export function nutritionOf(doc: { birthYear?: number }, now: Date = new Date()): NutritionAvailability {
  return availability(doc.birthYear ?? null, now.getUTCFullYear());
}

export async function requireNutrition(userId: string, now: Date = new Date()): Promise<UserDoc> {
  const user = await findUserById(userId);
  if (user === null) throw notFound("User");
  const answer = nutritionOf(user, now);
  if (answer === "absent") throw notFound("Nutrition");
  if (answer === "askBirthYear") throw apiError("birthYearRequired", "Add your birth year to open Nutrition.", HttpStatus.forbidden);
  return user;
}
