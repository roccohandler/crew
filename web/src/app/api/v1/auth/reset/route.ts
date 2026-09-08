// SPEC: docs/api.md POST auth/reset — always 202 (no account enumeration); creates a single-use 30-min token and
// sends the one email (Part IV); rate-limited per IP (G11) · T011
import { errorResponse, json } from "@/lib/api-error";
import { users } from "@/lib/db";
import { sendPasswordResetEmail } from "@/lib/email";
import { logEvent } from "@/lib/events";
import { HttpStatus } from "@/lib/http-status";
import { createPasswordReset, resetLinkFor } from "@/lib/password-resets";
import { limitAuthByIp } from "@/lib/rate-limit";
import { resetRequestSchema } from "@/lib/validate";

export async function POST(req: Request) {
  try {
    await limitAuthByIp(req);
    const body = resetRequestSchema.parse(await req.json());
    const user = await (await users()).findOne({ emailLower: body.email.toLowerCase() });
    if (user !== null && user.passwordHash !== undefined) {
      const token = await createPasswordReset(user._id);
      await sendPasswordResetEmail(user.email, resetLinkFor(token));
      await logEvent(user._id.toHexString(), "password_reset_requested");
    }
    return json({ accepted: true }, HttpStatus.accepted);
  } catch (error) {
    return errorResponse(error);
  }
}
