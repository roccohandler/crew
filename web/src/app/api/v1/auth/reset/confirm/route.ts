// SPEC: docs/api.md POST auth/reset/confirm — consume once, set the hash, revoke every refresh token (8.2 Auth) · T011
import { errorResponse, json } from "@/lib/api-error";
import { logEvent } from "@/lib/events";
import { HttpStatus } from "@/lib/http-status";
import { confirmPasswordReset } from "@/lib/password-resets";
import { limitAuthByIp } from "@/lib/rate-limit";
import { resetConfirmSchema } from "@/lib/validate";

export async function POST(req: Request) {
  try {
    await limitAuthByIp(req);
    const body = resetConfirmSchema.parse(await req.json());
    const userId = await confirmPasswordReset(body.token, body.newPassword);
    await logEvent(userId.toHexString(), "password_reset_completed");
    return json({ ok: true }, HttpStatus.ok);
  } catch (error) {
    return errorResponse(error);
  }
}
