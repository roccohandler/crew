// SPEC: nutrition addendum §2, §4 (RATIFIED 2026-09-18) · docs/api.md nutrition/logs — GET ?dayKey= the day's logs · POST one (a
// template slot, a saved meal or quick-add grams; idempotent on clientId — V62, 8.2 ④; the day is the server's, E15). A log is never
// a game event: this route recomputes nothing and awards nothing (clause ③, V63). 18+ only (A16.c · A22 G3).
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { HttpStatus } from "@/lib/http-status";
import { requireNutrition } from "@/lib/nutrition-access";
import { createLog, listLogs, mealLogResponse } from "@/lib/nutrition-logs";
import { createLogSchema, logsQuerySchema } from "@/lib/validate-nutrition";

export async function GET(req: Request) {
  try {
    const userId = await requireUser(req);
    const query = logsQuerySchema.parse({ dayKey: new URL(req.url).searchParams.get("dayKey") ?? undefined });
    await requireNutrition(userId);
    return json({ items: (await listLogs(new ObjectId(userId), query.dayKey)).map(mealLogResponse) });
  } catch (error) {
    return errorResponse(error);
  }
}

export async function POST(req: Request) {
  try {
    const userId = await requireUser(req);
    const body = createLogSchema.parse(await req.json());
    await requireNutrition(userId);
    const { log, created } = await createLog(new ObjectId(userId), body);
    return json({ log: mealLogResponse(log) }, created ? HttpStatus.created : HttpStatus.ok);
  } catch (error) {
    return errorResponse(error);
  }
}
