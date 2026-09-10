// SPEC: docs/api.md POST auth/apple (iOS: identity token from ASAuthorization) · Part IV · T012
import { errorResponse } from "@/lib/api-error";
import { verifyAppleIdentityToken } from "@/lib/apple-auth";
import { signInOrCreateAppleUser } from "@/lib/apple-sign-in";
import { signedInResponse } from "@/lib/auth-response";
import { HttpStatus } from "@/lib/http-status";
import { limitAuthByIp } from "@/lib/rate-limit";
import { publicUser } from "@/lib/users";
import { appleSignInSchema } from "@/lib/validate";

export async function POST(req: Request) {
  try {
    await limitAuthByIp(req);
    const body = appleSignInSchema.parse(await req.json());
    const identity = await verifyAppleIdentityToken(body.identityToken);
    const { user, created } = await signInOrCreateAppleUser({ identity, displayName: body.displayName, timezone: body.timezone, eulaAccepted: body.eulaAccepted, birthYear: body.birthYear, measurementSystem: body.measurementSystem });
    return await signedInResponse(req, user._id, publicUser(user), created ? HttpStatus.created : HttpStatus.ok);
  } catch (error) {
    return errorResponse(error);
  }
}
