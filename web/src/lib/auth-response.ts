// SPEC: Part IV — JWT in Keychain (iOS: tokens in the body) / httpOnly cookie (web: cookies, body carries the user).
// The one place a signed-in response is shaped, used by register, login, apple, refresh.
import type { ObjectId } from "mongodb";
import { authCookieHeaders, isIosClient, signAccessToken } from "@/lib/auth";
import { json } from "@/lib/api-error";
import { issueRefreshToken } from "@/lib/refresh-tokens";
import type { PublicUser } from "@/lib/users";

export async function signedInResponse(req: Request, userId: ObjectId, user: PublicUser, status: number, presetRefreshToken?: string): Promise<Response> {
  const access = await signAccessToken(userId.toHexString());
  const refreshToken = presetRefreshToken ?? (await issueRefreshToken(userId));
  if (isIosClient(req)) {
    return json({ user, accessToken: access.token, refreshToken, accessExpiresAt: access.expiresAt.toISOString() }, status);
  }
  return json({ user, accessExpiresAt: access.expiresAt.toISOString() }, status, authCookieHeaders(access.token, refreshToken));
}
