// SPEC: docs/api.md POST auth/apple/callback — the web Sign in with Apple flow: Apple POSTs form data (id_token, state, user JSON on
// the first sign-in) back here; we verify, sign in with cookies, and redirect into the app. Public. T012 (web button).
// W5 (owner-approved 2026-09-17): the attempt is BOUND — `state` must be one this server signed (start route), the browser must
// carry the nonce cookie that state names, and Apple's id_token must echo that nonce; anything else, and any other failure, lands
// on /login?apple=failed with one line (never a JSON body in a browser tab, never a 404 — the audit's item 8).
import { errorResponse } from "@/lib/api-error";
import { APPLE_NONCE_COOKIE, appleNonceCookie, cookieValue, readAppleState, verifyAppleIdentityToken } from "@/lib/apple-auth";
import { signInOrCreateAppleUser } from "@/lib/apple-sign-in";
import { authCookieHeaders, signAccessToken } from "@/lib/auth";
import { limitAuthByIp } from "@/lib/rate-limit";
import { issueRefreshToken } from "@/lib/refresh-tokens";

const SEE_OTHER = 303;

function displayNameFrom(userJson: string | null): string | undefined {
  if (userJson === null) return undefined;
  try {
    const parsed = JSON.parse(userJson) as { name?: { firstName?: string; lastName?: string } };
    const name = [parsed.name?.firstName, parsed.name?.lastName].filter(Boolean).join(" ").trim();
    return name.length > 0 ? name : undefined;
  } catch {
    return undefined;
  }
}

function redirectTo(location: string, extraHeaders: HeadersInit = {}): Response {
  const headers = new Headers(extraHeaders);
  headers.set("location", location);
  headers.append("set-cookie", appleNonceCookie("", 0)); // the nonce is single-use either way
  return new Response(null, { status: SEE_OTHER, headers });
}

export async function POST(req: Request) {
  const base = process.env.APP_BASE_URL ?? "http://localhost:3000";
  const failed = () => redirectTo(`${base}/login?apple=failed`);
  try {
    await limitAuthByIp(req);
    const form = await req.formData();
    const state = await readAppleState(String(form.get("state") ?? ""));
    if (state === null) return failed(); // unsigned, expired or tampered
    if (cookieValue(req, APPLE_NONCE_COOKIE) !== state.nonce) return failed(); // not the browser that started this attempt
    const identity = await verifyAppleIdentityToken(String(form.get("id_token") ?? ""), state.nonce); // Apple echoes the nonce
    const { user } = await signInOrCreateAppleUser({
      identity,
      displayName: displayNameFrom(typeof form.get("user") === "string" ? String(form.get("user")) : null),
      timezone: state.tz ?? "UTC",
      eulaAccepted: state.eula,
      birthYear: state.by,
    });
    const access = await signAccessToken(user._id.toHexString());
    const refreshToken = await issueRefreshToken(user._id);
    return redirectTo(`${base}${state.next}`, authCookieHeaders(access.token, refreshToken));
  } catch (error) {
    errorResponse(error); // one shape for the log; the browser gets the line, not the JSON
    return failed();
  }
}
