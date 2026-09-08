// SPEC: docs/api.md GET crews/[id]/stream?since= — the ONE unified stream (Flow 6): posts + messages + system lines, 7-day
// window, join-forward, blocked users filtered both ways, comeback banners (V39) · S12 · T029/T031
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { memberDots, pulseFor, streamFor } from "@/lib/crew-stream";
import { requireMember } from "@/lib/crews";
import { dayKeyFor } from "@/lib/engine/day-key";
import { findUserById } from "@/lib/users";

type Context = { params: Promise<{ id: string }> };

export async function GET(req: Request, context: Context) {
  try {
    const userId = new ObjectId(await requireUser(req));
    const { id } = await context.params;
    const { crew, membership } = await requireMember(userId, id);
    const user = await findUserById(userId.toHexString());
    const todayKey = dayKeyFor(new Date(), user?.timezone ?? "UTC");
    const since = new URL(req.url).searchParams.get("since");
    const stream = await streamFor(userId, membership, todayKey, since);
    return json({ ...stream, pulse: await pulseFor(crew._id, todayKey), members: await memberDots(crew._id, crew.captainId, todayKey), serverTime: new Date().toISOString() });
  } catch (error) {
    return errorResponse(error);
  }
}
