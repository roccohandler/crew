// SPEC: docs/api.md POST crews/[id]/invite — the Captain regenerates the invite token; the old link dies (E2) · T029
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { inviteLinkFor, regenerateInvite } from "@/lib/crews";
import { logEvent } from "@/lib/events";

type Context = { params: Promise<{ id: string }> };

export async function POST(req: Request, context: Context) {
  try {
    const userId = await requireUser(req);
    const { id } = await context.params;
    const token = await regenerateInvite(new ObjectId(userId), id);
    await logEvent(userId, "crew_invite_regenerated");
    return json({ inviteLink: inviteLinkFor(token) });
  } catch (error) {
    return errorResponse(error);
  }
}
