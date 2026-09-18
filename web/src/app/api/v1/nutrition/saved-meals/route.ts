// SPEC: nutrition addendum §2, §4 (RATIFIED 2026-09-18) · docs/api.md nutrition/saved-meals — GET the user's saved meals · POST
// one (manual, or copied from a fast-food seed item; idempotent on clientId — 8.2 ④). 18+ only (A16.c · A22 G3). Grams are integers
// within bounds and nothing else is checked (clause ⑤).
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { HttpStatus } from "@/lib/http-status";
import { requireNutrition } from "@/lib/nutrition-access";
import { createSavedMeal, listSavedMeals, savedMealResponse } from "@/lib/nutrition-meals";
import { savedMealSchema } from "@/lib/validate-nutrition";

export async function GET(req: Request) {
  try {
    const userId = await requireUser(req);
    await requireNutrition(userId);
    return json({ items: (await listSavedMeals(new ObjectId(userId))).map(savedMealResponse) });
  } catch (error) {
    return errorResponse(error);
  }
}

export async function POST(req: Request) {
  try {
    const userId = await requireUser(req);
    const body = savedMealSchema.parse(await req.json());
    await requireNutrition(userId);
    const { meal, created } = await createSavedMeal(new ObjectId(userId), body);
    return json({ meal: savedMealResponse(meal) }, created ? HttpStatus.created : HttpStatus.ok);
  } catch (error) {
    return errorResponse(error);
  }
}
