// SPEC: docs/api.md POST/DELETE push-token — register/refresh or remove the APNs device token · T033
import { ObjectId } from "mongodb";
import { errorResponse, json } from "@/lib/api-error";
import { requireUser } from "@/lib/auth";
import { pushTokens } from "@/lib/db";
import { logEvent } from "@/lib/events";
import { HttpStatus } from "@/lib/http-status";
import { pushTokenSchema } from "@/lib/validate";

export async function POST(req: Request) {
  try {
    const userId = new ObjectId(await requireUser(req));
    const body = pushTokenSchema.parse(await req.json());
    await (await pushTokens()).updateOne({ token: body.token }, { $set: { userId, platform: "ios", updatedAt: new Date() }, $setOnInsert: { _id: new ObjectId() } }, { upsert: true });
    await logEvent(userId.toHexString(), "push_token_registered");
    return json({ ok: true }, HttpStatus.created);
  } catch (error) {
    return errorResponse(error);
  }
}

export async function DELETE(req: Request) {
  try {
    const userId = new ObjectId(await requireUser(req));
    const body = pushTokenSchema.parse(await req.json());
    await (await pushTokens()).deleteOne({ token: body.token, userId });
    return json({ ok: true });
  } catch (error) {
    return errorResponse(error);
  }
}
