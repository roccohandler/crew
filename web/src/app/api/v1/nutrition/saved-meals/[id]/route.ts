// SPEC: nutrition addendum §2 (RATIFIED 2026-09-18) · docs/api.md nutrition/saved-meals/[id] — PATCH the name or the grams · DELETE
// the meal (its template slots go with it; logs keep their own copy, so history is untouched). `id` is the server id, or the
// clientId a phone created it with offline. Another user's meal is a 404 (8.2 ①). 18+ only (A16.c · A22 G3).
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { requireNutrition } from "@/lib/nutrition-access";
import { deleteSavedMeal, patchSavedMeal, savedMealResponse } from "@/lib/nutrition-meals";
import { patchSavedMealSchema } from "@/lib/validate-nutrition";

type Context = { params: Promise<{ id: string }> };

export async function PATCH(req: Request, context: Context) {
  try {
    const userId = await requireUser(req);
    const { id } = await context.params;
    const body = patchSavedMealSchema.parse(await req.json());
    await requireNutrition(userId);
    return json({ meal: savedMealResponse(await patchSavedMeal(new ObjectId(userId), id, body)) });
  } catch (error) {
    return errorResponse(error);
  }
}

export async function DELETE(req: Request, context: Context) {
  try {
    const userId = await requireUser(req);
    const { id } = await context.params;
    await requireNutrition(userId);
    await deleteSavedMeal(new ObjectId(userId), id);
    return json({ ok: true });
  } catch (error) {
    return errorResponse(error);
  }
}
