// SPEC: docs/api.md pause — GET current · POST create (V22/V23/V44 via validatePauseRequest) · DELETE end early; XP suppression
// is the recompute's (V20) · T041
import { ObjectId } from "mongodb";
import { z } from "zod";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { dayKeyFor } from "@/lib/engine/day-key";
import { logEvent } from "@/lib/events";
import { recomputeAndStore } from "@/lib/gamification-store";
import { HttpStatus } from "@/lib/http-status";
import { createPause, currentPause, endPause, pauseResponse } from "@/lib/pauses";
import { findUserById } from "@/lib/users";
import { dayKeySchema, timezoneSchema } from "@/lib/validate";

export const createPauseSchema = z.object({ startDay: dayKeySchema, endDay: dayKeySchema, timezone: timezoneSchema });

export async function GET(req: Request) {
  try {
    const userId = await requireUser(req);
    const user = await findUserById(userId);
    const doc = await currentPause(new ObjectId(userId), dayKeyFor(new Date(), user?.timezone ?? "UTC"));
    return json({ pause: doc === null ? null : pauseResponse(doc) });
  } catch (error) {
    return errorResponse(error);
  }
}

export async function POST(req: Request) {
  try {
    const userId = await requireUser(req);
    const body = createPauseSchema.parse(await req.json());
    const doc = await createPause(new ObjectId(userId), body.startDay, body.endDay, body.timezone);
    const gamification = await recomputeAndStore(userId);
    await logEvent(userId, "pause_created", { days: body.endDay });
    return json({ pause: pauseResponse(doc), gamification }, HttpStatus.created);
  } catch (error) {
    return errorResponse(error);
  }
}

export async function DELETE(req: Request) {
  try {
    const userId = await requireUser(req);
    const user = await findUserById(userId);
    await endPause(new ObjectId(userId), user?.timezone ?? "UTC");
    const gamification = await recomputeAndStore(userId);
    await logEvent(userId, "pause_ended");
    return json({ ok: true, gamification });
  } catch (error) {
    return errorResponse(error);
  }
}
