// SPEC: docs/api.md POST auth/refresh — rotation: new access + refresh, the old refresh is dead, reuse kills the
// family (G11; 8.2 Auth "refresh rotation") · T010
import { errorResponse, unauthorized } from "@/lib/api-error";
import { REFRESH_COOKIE, readCookie } from "@/lib/auth";
import { signedInResponse } from "@/lib/auth-response";
import { HttpStatus } from "@/lib/http-status";
import { rotateRefreshToken } from "@/lib/refresh-tokens";
import { findUserById, publicUser } from "@/lib/users";
import { refreshSchema } from "@/lib/validate";

export async function POST(req: Request) {
  try {
    const raw = await req.text();
    const body = refreshSchema.parse(raw.length > 0 ? JSON.parse(raw) : {});
    const presented = body.refreshToken ?? readCookie(req, REFRESH_COOKIE);
    if (presented === null) throw unauthorized();
    const rotated = await rotateRefreshToken(presented);
    const user = await findUserById(rotated.userId.toHexString());
    if (user === null) throw unauthorized();
    return await signedInResponse(req, user._id, publicUser(user), HttpStatus.ok, rotated.refreshToken);
  } catch (error) {
    return errorResponse(error);
  }
}
