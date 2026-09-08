// SPEC: Part IV (auth = Sign in with Apple + email, JWT in Keychain / httpOnly cookie) · G11 (access 15 min) ·
// 8.7 (httpOnly/secure cookies on web) · 5.2 lib/auth.ts: jwt sign/verify, cookie helpers, requireUser(req) → userId | 401.
// iOS sends `Authorization: Bearer <access>` and receives tokens in the body (header `X-Crew-Client: ios`);
// web receives httpOnly cookies. Refresh-token rotation lives in lib/refresh-tokens.ts.
import { SignJWT, jwtVerify } from "jose";
import { unauthorized } from "@/lib/api-error";
import { CryptoParams } from "@/lib/crypto-params";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

export const ACCESS_COOKIE = "crew_access";
export const REFRESH_COOKIE = "crew_refresh";
const REFRESH_COOKIE_PATH = "/api/v1/auth";

function secretKey(): Uint8Array {
  const secret = process.env.JWT_SECRET ?? "";
  if (secret.length < CryptoParams.jwtSecretMinBytes) throw new Error("JWT_SECRET must be at least 32 bytes (see .env.example)");
  return new TextEncoder().encode(secret);
}

export async function signAccessToken(userId: string, now: Date = new Date()): Promise<{ token: string; expiresAt: Date }> {
  const expiresAt = new Date(now.getTime() + SpecConstants.jwtAccessTokenMinutes * TimeUnits.msPerMinute);
  const token = await new SignJWT({})
    .setProtectedHeader({ alg: "HS256" })
    .setSubject(userId)
    .setIssuedAt(Math.floor(now.getTime() / TimeUnits.msPerSecond))
    .setExpirationTime(Math.floor(expiresAt.getTime() / TimeUnits.msPerSecond))
    .sign(secretKey());
  return { token, expiresAt };
}

export async function verifyAccessToken(token: string): Promise<string | null> {
  try {
    const { payload } = await jwtVerify(token, secretKey(), { algorithms: ["HS256"] });
    return typeof payload.sub === "string" ? payload.sub : null;
  } catch {
    return null;
  }
}

export function readCookie(req: Request, name: string): string | null {
  const header = req.headers.get("cookie") ?? "";
  for (const part of header.split(";")) {
    const [key, ...rest] = part.trim().split("=");
    if (key === name) return decodeURIComponent(rest.join("="));
  }
  return null;
}

// SPEC: docs/api.md — Bearer header first (iOS), then the web cookie; anything else is 401
export async function requireUser(req: Request): Promise<string> {
  const header = req.headers.get("authorization") ?? "";
  const bearer = header.startsWith("Bearer ") ? header.slice("Bearer ".length) : null;
  const token = bearer ?? readCookie(req, ACCESS_COOKIE);
  if (token === null) throw unauthorized();
  const userId = await verifyAccessToken(token);
  if (userId === null) throw unauthorized();
  return userId;
}

export function isIosClient(req: Request): boolean {
  return req.headers.get("x-crew-client") === "ios";
}

function serializeCookie(name: string, value: string, maxAgeSeconds: number, path: string): string {
  const secure = process.env.COOKIE_SECURE === "true" ? "; Secure" : "";
  return `${name}=${encodeURIComponent(value)}; Path=${path}; Max-Age=${maxAgeSeconds}; HttpOnly; SameSite=Lax${secure}`;
}

export function authCookieHeaders(accessToken: string, refreshToken: string): HeadersInit {
  const headers = new Headers();
  headers.append("Set-Cookie", serializeCookie(ACCESS_COOKIE, accessToken, SpecConstants.jwtAccessTokenMinutes * TimeUnits.secondsPerMinute, "/"));
  headers.append("Set-Cookie", serializeCookie(REFRESH_COOKIE, refreshToken, SpecConstants.jwtRefreshTokenDays * TimeUnits.hoursPerDay * TimeUnits.minutesPerHour * TimeUnits.secondsPerMinute, REFRESH_COOKIE_PATH));
  return headers;
}

export function clearedCookieHeaders(): HeadersInit {
  const headers = new Headers();
  headers.append("Set-Cookie", serializeCookie(ACCESS_COOKIE, "", 0, "/"));
  headers.append("Set-Cookie", serializeCookie(REFRESH_COOKIE, "", 0, REFRESH_COOKIE_PATH));
  return headers;
}
