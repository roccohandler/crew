// SPEC: nutrition addendum §2, §4 (RATIFIED 2026-09-18) · docs/api.md nutrition/template — GET the daily template (its slots with
// their saved meals) · PUT the whole ordered list (0 … dayTemplateMaxSlots; every slot names one of the user's own saved meals). A
// checklist, never a requirement. 18+ only (A16.c · A22 G3).
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { requireNutrition } from "@/lib/nutrition-access";
import { putTemplate, templateSlots } from "@/lib/nutrition-meals";
import { putTemplateSchema } from "@/lib/validate-nutrition";

export async function GET(req: Request) {
  try {
    const userId = await requireUser(req);
    await requireNutrition(userId);
    return json({ slots: await templateSlots(new ObjectId(userId)) });
  } catch (error) {
    return errorResponse(error);
  }
}

export async function PUT(req: Request) {
  try {
    const userId = await requireUser(req);
    const body = putTemplateSchema.parse(await req.json());
    await requireNutrition(userId);
    return json({ slots: await putTemplate(new ObjectId(userId), body) });
  } catch (error) {
    return errorResponse(error);
  }
}
