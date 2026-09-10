// SPEC: docs/api.md POST auth/register · Part IV (crypto.scrypt) · E9 (EULA, 13+) · E18 (re-signup = fresh identity) · T010
import { errorResponse, apiError } from "@/lib/api-error";
import { signedInResponse } from "@/lib/auth-response";
import { users } from "@/lib/db";
import { logEvent } from "@/lib/events";
import { HttpStatus } from "@/lib/http-status";
import { hashPassword } from "@/lib/password";
import { limitAuthByIp } from "@/lib/rate-limit";
import { createUserWithState, publicUser, requireSignupGates } from "@/lib/users";
import { registerSchema } from "@/lib/validate";

export async function POST(req: Request) {
  try {
    await limitAuthByIp(req);
    const body = registerSchema.parse(await req.json());
    requireSignupGates(body.eulaAccepted, body.birthYear);
    const existing = await (await users()).findOne({ emailLower: body.email.toLowerCase() });
    if (existing !== null) throw apiError("emailTaken", "That email already has a Crew account. Log in instead.", HttpStatus.conflict);
    const passwordHash = await hashPassword(body.password);
    const user = await createUserWithState({ email: body.email, authProvider: "email", passwordHash, displayName: body.displayName, timezone: body.timezone, measurementSystem: body.measurementSystem });
    await logEvent(user._id.toHexString(), "account_created", { provider: "email" });
    return await signedInResponse(req, user._id, publicUser(user), HttpStatus.created);
  } catch (error) {
    return errorResponse(error);
  }
}
