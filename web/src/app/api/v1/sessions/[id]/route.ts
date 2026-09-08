// SPEC: docs/api.md GET/PATCH sessions/[id] — own sessions only (8.2 ①: a foreign id is a 404); PATCH upserts set logs,
// completion creates the workout Post and recomputes (5.6.4) · T023
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { logEvent } from "@/lib/events";
import { recomputeAndStore } from "@/lib/gamification-store";
import { findOwnSession, patchSession, sessionResponse } from "@/lib/sessions";
import { patchSessionSchema } from "@/lib/validate-sessions";

type Context = { params: Promise<{ id: string }> };

export async function GET(req: Request, context: Context) {
  try {
    const userId = await requireUser(req);
    const { id } = await context.params;
    return json({ session: sessionResponse(await findOwnSession(new ObjectId(userId), id)) });
  } catch (error) {
    return errorResponse(error);
  }
}

export async function PATCH(req: Request, context: Context) {
  try {
    const userId = await requireUser(req);
    const { id } = await context.params;
    const body = patchSessionSchema.parse(await req.json());
    const session = await patchSession(new ObjectId(userId), id, body);
    const gamification = await recomputeAndStore(userId);
    if (session.status === "completed") await logEvent(userId, "workout_completed", { planned: session.isPlannedDay, dayKey: session.dayKey });
    return json({ session: sessionResponse(session), gamification });
  } catch (error) {
    return errorResponse(error);
  }
}
