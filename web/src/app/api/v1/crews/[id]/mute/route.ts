// SPEC: docs/api.md PATCH crews/[id]/mute — per-crew mute (E2, S17) · T029
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { requireMember } from "@/lib/crews";
import { crewMemberships } from "@/lib/db";
import { muteSchema } from "@/lib/validate-crews";

type Context = { params: Promise<{ id: string }> };

export async function PATCH(req: Request, context: Context) {
  try {
    const userId = new ObjectId(await requireUser(req));
    const { id } = await context.params;
    const body = muteSchema.parse(await req.json());
    const { membership } = await requireMember(userId, id);
    await (await crewMemberships()).updateOne({ _id: membership._id }, { $set: { mutedAt: body.muted ? new Date() : null } });
    return json({ muted: body.muted });
  } catch (error) {
    return errorResponse(error);
  }
}
