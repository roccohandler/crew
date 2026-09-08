// SPEC: Part IV (auth = Sign in with Apple + email) · docs/api.md POST auth/apple · T012.
// Verifies an Apple identity token against Apple's JWKS (APPLE_JWKS_URL — a local JWKS in tests), issuer
// https://appleid.apple.com, audience = the iOS bundle id or the web Services ID. Returns the stable subject + email.
import { createRemoteJWKSet, jwtVerify } from "jose";
import { apiError } from "@/lib/api-error";
import { HttpStatus } from "@/lib/http-status";

export const APPLE_ISSUER = "https://appleid.apple.com";
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

export async function verifyAppleIdentityToken(identityToken: string): Promise<AppleIdentity> {
  const audiences = acceptedAudiences();
  if (audiences.length === 0) throw apiError("invalidAppleToken", "Sign in with Apple is not configured on this server.", HttpStatus.unauthorized);
  try {
    const { payload } = await jwtVerify(identityToken, appleKeys(), { issuer: APPLE_ISSUER, audience: audiences });
    if (typeof payload.sub !== "string") throw new Error("no subject");
    const email = typeof payload.email === "string" ? payload.email : null;
    const verified = payload.email_verified === true || payload.email_verified === "true";
    return { sub: payload.sub, email, emailVerified: verified };
  } catch {
    throw apiError("invalidAppleToken", "Apple didn't accept that sign-in. Try again.", HttpStatus.unauthorized);
  }
}

export function appleAuthorizeUrl(state: string): string {
  const base = process.env.APP_BASE_URL ?? "http://localhost:3000";
  const params = new URLSearchParams({
    client_id: process.env.APPLE_SERVICES_ID ?? "",
    redirect_uri: `${base}/api/v1/auth/apple/callback`,
    response_type: "code id_token",
    response_mode: "form_post",
    scope: "name email",
    state,
  });
  return `${APPLE_ISSUER}/auth/authorize?${params.toString()}`;
}
