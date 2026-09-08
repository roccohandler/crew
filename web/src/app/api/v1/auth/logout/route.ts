// SPEC: docs/api.md POST auth/logout — revoke the presented refresh token, clear the web cookies · T010
import { errorResponse, json } from "@/lib/api-error";
import { REFRESH_COOKIE, clearedCookieHeaders, readCookie, requireUser } from "@/lib/auth";
import { logEvent } from "@/lib/events";
import { HttpStatus } from "@/lib/http-status";
import { revokeRefreshToken } from "@/lib/refresh-tokens";
import { refreshSchema } from "@/lib/validate";

export async function POST(req: Request) {
  try {
    const userId = await requireUser(req);
    const raw = await req.text();
    const body = refreshSchema.parse(raw.length > 0 ? JSON.parse(raw) : {});
    const presented = body.refreshToken ?? readCookie(req, REFRESH_COOKIE);
    if (presented !== null) await revokeRefreshToken(presented);
    await logEvent(userId, "logout");
    return json({ ok: true }, HttpStatus.ok, clearedCookieHeaders());
  } catch (error) {
    return errorResponse(error);
  }
}
