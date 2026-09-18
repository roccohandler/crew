// SPEC: Part IV (auth = Sign in with Apple + email) · docs/api.md POST auth/apple · GET auth/apple/start · POST auth/apple/callback · T012.
// Verifies an Apple identity token against Apple's JWKS (APPLE_JWKS_URL — a local JWKS in tests), issuer
// https://appleid.apple.com, audience = the iOS bundle id or the web Services ID. Returns the stable subject + email.
// W5 (owner-approved 2026-09-17): the WEB flow is state/nonce BOUND — the start route mints a nonce, signs it into a short-lived
// `state` (HS256 with the server's JWT secret) and sets it as a browser cookie; Apple echoes the nonce inside the id_token; the
// callback accepts only the triple that matches (signed state · cookie · id_token claim), so a token minted for another attempt,
// another browser, or an unsigned state cannot sign anyone in (docs/MVP_STATE_REPORT.md §9, item 8).
import { randomBytes } from "node:crypto";
import { createRemoteJWKSet, jwtVerify, SignJWT } from "jose";
import { apiError } from "@/lib/api-error";
import { secretKey } from "@/lib/auth";
import { CryptoParams } from "@/lib/crypto-params";
import { HttpStatus } from "@/lib/http-status";
import { TimeUnits } from "@/lib/time-units";

export const APPLE_ISSUER = "https://appleid.apple.com";
export const APPLE_START_PATH = "/api/v1/auth/apple/start";
export const APPLE_NONCE_COOKIE = "crew_apple_nonce";
const APPLE_STATE_AUDIENCE = "crew-apple-web";
const DEFAULT_JWKS_URL = "https://appleid.apple.com/auth/keys";

let jwks: { url: string; keys: ReturnType<typeof createRemoteJWKSet> } | null = null;

function appleKeys() {
  const url = process.env.APPLE_JWKS_URL ?? DEFAULT_JWKS_URL;
  if (jwks === null || jwks.url !== url) jwks = { url, keys: createRemoteJWKSet(new URL(url)) };
  return jwks.keys;
}

function acceptedAudiences(): string[] {
  return [process.env.APPLE_BUNDLE_ID, process.env.APPLE_SERVICES_ID].filter((value): value is string => typeof value === "string" && value.length > 0);
}

export interface AppleIdentity {
  sub: string;
  email: string | null;
  emailVerified: boolean;
}

// `expectedNonce` is the web flow's: the id_token must carry exactly it (iOS sends none — ASAuthorization's token is handed over directly)
export async function verifyAppleIdentityToken(identityToken: string, expectedNonce?: string): Promise<AppleIdentity> {
  const audiences = acceptedAudiences();
  if (audiences.length === 0) throw apiError("invalidAppleToken", "Sign in with Apple is not configured on this server.", HttpStatus.unauthorized);
  try {
    const { payload } = await jwtVerify(identityToken, appleKeys(), { issuer: APPLE_ISSUER, audience: audiences });
    if (typeof payload.sub !== "string") throw new Error("no subject");
    if (expectedNonce !== undefined && payload.nonce !== expectedNonce) throw new Error("nonce mismatch");
    const email = typeof payload.email === "string" ? payload.email : null;
    const verified = payload.email_verified === true || payload.email_verified === "true";
    return { sub: payload.sub, email, emailVerified: verified };
  } catch {
    throw apiError("invalidAppleToken", "Apple didn't accept that sign-in. Try again.", HttpStatus.unauthorized);
  }
}

// What a web sign-in attempt carries through Apple and back: the EULA answer, where to land, and (from the save form) timezone + birth year
export interface AppleStart {
  eula: boolean;
  next: string;
  tz?: string;
  by?: number;
}

// The href every web "Sign in with Apple" button points at — the start route mints the nonce and the signed state
export function appleStartUrl(start: AppleStart): string {
  const params = new URLSearchParams({ eula: start.eula ? "1" : "0", next: start.next });
  if (start.tz) params.set("tz", start.tz);
  if (start.by !== undefined) params.set("by", String(start.by));
  return `${APPLE_START_PATH}?${params.toString()}`;
}

export function newAppleNonce(): string {
  return randomBytes(CryptoParams.appleNonceBytes).toString("base64url");
}

export const appleStateTtlSeconds = CryptoParams.appleStateTtlMinutes * TimeUnits.secondsPerMinute;

export async function signAppleState(start: AppleStart, nonce: string, now: Date = new Date()): Promise<string> {
  const issuedAt = Math.floor(now.getTime() / TimeUnits.msPerSecond);
  return new SignJWT({ eula: start.eula, next: start.next, tz: start.tz, by: start.by, nonce })
    .setProtectedHeader({ alg: "HS256" })
    .setAudience(APPLE_STATE_AUDIENCE)
    .setIssuedAt(issuedAt)
    .setExpirationTime(issuedAt + appleStateTtlSeconds)
    .sign(secretKey());
}

// null for anything but a state this server signed within its TTL
export async function readAppleState(state: string): Promise<(AppleStart & { nonce: string }) | null> {
  try {
    const { payload } = await jwtVerify(state, secretKey(), { audience: APPLE_STATE_AUDIENCE });
    if (typeof payload.nonce !== "string" || typeof payload.next !== "string") return null;
    return {
      eula: payload.eula === true,
      next: payload.next.startsWith("/") ? payload.next : "/home",
      tz: typeof payload.tz === "string" ? payload.tz : undefined,
      by: typeof payload.by === "number" ? payload.by : undefined,
      nonce: payload.nonce,
    };
  } catch {
    return null;
  }
}

export function appleAuthorizeUrl(state: string, nonce: string): string {
  const base = process.env.APP_BASE_URL ?? "http://localhost:3000";
  const params = new URLSearchParams({
    client_id: process.env.APPLE_SERVICES_ID ?? "",
    redirect_uri: `${base}/api/v1/auth/apple/callback`,
    response_type: "code id_token",
    response_mode: "form_post",
    scope: "name email",
    state,
    nonce,
  });
  return `${APPLE_ISSUER}/auth/authorize?${params.toString()}`;
}

// The browser-bound half of the nonce. Apple answers with a CROSS-SITE form POST, which a SameSite=Lax cookie never accompanies,
// so this one is SameSite=None — and None requires Secure (browsers treat localhost as a secure context, so dev works too).
export function appleNonceCookie(nonce: string, maxAgeSeconds: number): string {
  return `${APPLE_NONCE_COOKIE}=${encodeURIComponent(nonce)}; Path=/api/v1/auth/apple; Max-Age=${maxAgeSeconds}; HttpOnly; SameSite=None; Secure`;
}

export function cookieValue(req: Request, name: string): string | null {
  for (const part of (req.headers.get("cookie") ?? "").split(";")) {
    const [key, ...rest] = part.trim().split("=");
    if (key === name) return decodeURIComponent(rest.join("="));
  }
  return null;
}
