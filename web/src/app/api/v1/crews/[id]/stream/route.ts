// SPEC: docs/api.md GET crews/[id]/stream?since= — the ONE unified stream (Flow 6): posts + system lines (A21.2: no chat), 7-day
// window, join-forward, blocked users filtered both ways — from the items, the pulse and the member strip (E9 / W3), comeback
// banners (V39) · S12 · T029/T031
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { blockedIdsFor, memberDots, pulseFor, streamFor } from "@/lib/crew-stream";
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
    const hidden = await blockedIdsFor(userId); // E9: one block set for the items, the pulse and the strip alike
    const stream = await streamFor(membership, todayKey, since, hidden);
    return json({ ...stream, pulse: await pulseFor(crew._id, todayKey, hidden), members: await memberDots(crew._id, crew.captainId, todayKey, hidden), serverTime: new Date().toISOString() });
  } catch (error) {
    return errorResponse(error);
  }
}
