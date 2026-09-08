// SPEC: docs/api.md POST crews/[id]/messages — send (≤ chatMessageMaxChars; idempotent on clientId) · T030
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { messageResponse, sendMessage } from "@/lib/crew-messages";
import { logEvent } from "@/lib/events";
import { HttpStatus } from "@/lib/http-status";
import { sendMessageSchema } from "@/lib/validate-crews";

type Context = { params: Promise<{ id: string }> };

export async function POST(req: Request, context: Context) {
  try {
    const userId = await requireUser(req);
    const { id } = await context.params;
    const body = sendMessageSchema.parse(await req.json());
    const { message, created } = await sendMessage(new ObjectId(userId), id, body.clientId, body.body);
    if (created) await logEvent(userId, "message_sent");
    return json({ message: messageResponse(message) }, created ? HttpStatus.created : HttpStatus.ok);
  } catch (error) {
    return errorResponse(error);
  }
}
