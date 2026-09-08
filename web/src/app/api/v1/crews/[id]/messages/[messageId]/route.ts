// SPEC: docs/api.md DELETE crews/[id]/messages/[messageId] — own message → tombstone; the Captain may delete any (E2, E20) · T030
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { deleteMessage } from "@/lib/crew-messages";

type Context = { params: Promise<{ id: string; messageId: string }> };

export async function DELETE(req: Request, context: Context) {
  try {
    const userId = await requireUser(req);
    const { id, messageId } = await context.params;
    await deleteMessage(new ObjectId(userId), id, messageId);
    return json({ ok: true });
  } catch (error) {
    return errorResponse(error);
  }
}
