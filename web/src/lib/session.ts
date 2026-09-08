// SPEC: Part IV (web: JWT in an httpOnly cookie) · 1C (authenticate once per device) · S01 (auth restored silently). Server
// components read the signed-in user from the cookie; when the access cookie is expired but a refresh cookie exists the page
// renders a client refresh (components/SessionKeeper.tsx) instead of bouncing to login.
import { cookies } from "next/headers";
import { ACCESS_COOKIE, REFRESH_COOKIE, verifyAccessToken } from "@/lib/auth";
import { findUserById, publicUser, type PublicUser } from "@/lib/users";

export type SessionState = { kind: "signedIn"; user: PublicUser } | { kind: "needsRefresh" } | { kind: "signedOut" };

export async function readSession(): Promise<SessionState> {
  const jar = await cookies();
  const access = jar.get(ACCESS_COOKIE)?.value;
  const refresh = jar.get(REFRESH_COOKIE)?.value;
  if (access !== undefined) {
    const userId = await verifyAccessToken(access);
    if (userId !== null) {
      const user = await findUserById(userId);
      if (user !== null) return { kind: "signedIn", user: publicUser(user) };
    }
  }
  return refresh !== undefined ? { kind: "needsRefresh" } : { kind: "signedOut" };
}
