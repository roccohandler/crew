// SPEC: nutrition addendum §2 (RATIFIED 2026-09-18) · docs/api.md nutrition/logs/[id] — DELETE a log (the server id, or the
// clientId a phone logged it with offline). Another user's log is a 404 (8.2 ①). Nothing is recomputed: a log was never counted
// (clause ③). 18+ only (A16.c · A22 G3).
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { requireNutrition } from "@/lib/nutrition-access";
import { deleteLog } from "@/lib/nutrition-logs";

type Context = { params: Promise<{ id: string }> };

export async function DELETE(req: Request, context: Context) {
  try {
    const userId = await requireUser(req);
    const { id } = await context.params;
    await requireNutrition(userId);
    await deleteLog(new ObjectId(userId), id);
    return json({ ok: true });
  } catch (error) {
    return errorResponse(error);
  }
}
