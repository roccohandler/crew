// SPEC: docs/api.md POST auth/login · G11 (10 req/min/IP) · 1C (the login screen is a failure state, not a feature) · T010
import { apiError, errorResponse } from "@/lib/api-error";
import { signedInResponse } from "@/lib/auth-response";
import { users } from "@/lib/db";
import { logEvent } from "@/lib/events";
import { HttpStatus } from "@/lib/http-status";
import { verifyPassword } from "@/lib/password";
import { limitAuthByIp } from "@/lib/rate-limit";
import { publicUser } from "@/lib/users";
import { loginSchema } from "@/lib/validate";

const invalidCredentials = () => apiError("invalidCredentials", "That email and password don't match.", HttpStatus.unauthorized);

export async function POST(req: Request) {
  try {
    await limitAuthByIp(req);
    const body = loginSchema.parse(await req.json());
    const user = await (await users()).findOne({ emailLower: body.email.toLowerCase() });
    if (user === null || user.passwordHash === undefined) throw invalidCredentials();
    if (!(await verifyPassword(body.password, user.passwordHash))) throw invalidCredentials();
    await logEvent(user._id.toHexString(), "login", { provider: "email" });
    return await signedInResponse(req, user._id, publicUser(user), HttpStatus.ok);
  } catch (error) {
    return errorResponse(error);
  }
}
