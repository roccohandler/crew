// SPEC: docs/api.md PATCH crews/[id] — Captain renames / changes the emoji (E2) · T029
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { requireCaptain } from "@/lib/crews";
import { crews } from "@/lib/db";
import { renameCrewSchema } from "@/lib/validate-crews";

type Context = { params: Promise<{ id: string }> };

export async function PATCH(req: Request, context: Context) {
  try {
    const userId = await requireUser(req);
    const { id } = await context.params;
    const body = renameCrewSchema.parse(await req.json());
    const crew = await requireCaptain(new ObjectId(userId), id);
    const changes: { name?: string; emoji?: string } = {};
    if (body.name !== undefined) changes.name = body.name;
    if (body.emoji !== undefined) changes.emoji = body.emoji;
    await (await crews()).updateOne({ _id: crew._id }, { $set: changes });
    return json({ crew: { id: crew._id.toHexString(), name: changes.name ?? crew.name, emoji: changes.emoji ?? crew.emoji } });
  } catch (error) {
    return errorResponse(error);
  }
}
