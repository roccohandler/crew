// SPEC: docs/api.md GET crews/[id]/members (streak, today-dot, ⏸) · DELETE (leave, or Captain removes; captaincy auto-passes;
// last-one-out archives — E2) · T029
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { memberDots } from "@/lib/crew-stream";
import { removeMember, requireMember } from "@/lib/crews";
import { dayKeyFor } from "@/lib/engine/day-key";
import { logEvent } from "@/lib/events";
import { findUserById } from "@/lib/users";
import { leaveOrRemoveSchema } from "@/lib/validate-crews";

type Context = { params: Promise<{ id: string }> };

export async function GET(req: Request, context: Context) {
  try {
    const userId = new ObjectId(await requireUser(req));
    const { id } = await context.params;
    const { crew } = await requireMember(userId, id);
    const user = await findUserById(userId.toHexString());
    return json({ members: await memberDots(crew._id, crew.captainId, dayKeyFor(new Date(), user?.timezone ?? "UTC")) });
  } catch (error) {
    return errorResponse(error);
  }
}

export async function DELETE(req: Request, context: Context) {
  try {
    const userId = await requireUser(req);
    const { id } = await context.params;
    const raw = await req.text();
    const body = leaveOrRemoveSchema.parse(raw.length > 0 ? JSON.parse(raw) : {});
    const targetId = body.userId === undefined ? new ObjectId(userId) : new ObjectId(body.userId);
    const target = await findUserById(targetId.toHexString());
    await removeMember(new ObjectId(userId), id, targetId, target?.displayName ?? "Someone");
    await logEvent(userId, targetId.equals(new ObjectId(userId)) ? "crew_left" : "crew_member_removed");
    return json({ ok: true });
  } catch (error) {
    return errorResponse(error);
  }
}
