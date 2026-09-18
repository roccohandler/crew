// SPEC: nutrition addendum §2–§3 (RATIFIED 2026-09-18) · docs/api.md nutrition/targets — GET the targets (null until set) · PUT
// a bodyweight, with all three grams (manual) or none (derived; this is also "Recalculate") · DELETE the targets and the bodyweight
// with them (V64), or `everything` — Settings' "Delete my nutrition data". 18+ only (A16.c · A22 G3): under 18 this route is a 404.
// No nutrition route recomputes gamification (clause ③).
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { logEvent } from "@/lib/events";
import { requireNutrition } from "@/lib/nutrition-access";
import { deleteTargets, findTargets, putTargets, targetsResponse } from "@/lib/nutrition-targets-store";
import { deleteTargetsSchema, putTargetsSchema } from "@/lib/validate-nutrition";

export async function GET(req: Request) {
  try {
    const userId = await requireUser(req);
    await requireNutrition(userId);
    const doc = await findTargets(new ObjectId(userId));
    return json({ targets: doc === null ? null : targetsResponse(doc) });
  } catch (error) {
    return errorResponse(error);
  }
}

export async function PUT(req: Request) {
  try {
    const userId = await requireUser(req);
    const body = putTargetsSchema.parse(await req.json());
    await requireNutrition(userId);
    const doc = await putTargets(new ObjectId(userId), body);
    await logEvent(userId, "nutrition_targets_set", { source: doc.source });
    return json({ targets: targetsResponse(doc) });
  } catch (error) {
    return errorResponse(error);
  }
}

export async function DELETE(req: Request) {
  try {
    const userId = await requireUser(req);
    const body = deleteTargetsSchema.parse(await req.json().catch(() => ({})));
    await requireNutrition(userId);
    await deleteTargets(new ObjectId(userId), body.everything === true);
    await logEvent(userId, "nutrition_data_deleted", { everything: body.everything === true });
    return json({ ok: true });
  } catch (error) {
    return errorResponse(error);
  }
}
