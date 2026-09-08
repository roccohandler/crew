// SPEC: docs/api.md — the web Sign in with Apple flow: Apple POSTs form data (id_token, state, user JSON on the first
// sign-in) back here; we verify, sign in with cookies, and redirect into the app. Public. T012 (web button).
import { errorResponse } from "@/lib/api-error";
import { verifyAppleIdentityToken } from "@/lib/apple-auth";
import { signInOrCreateAppleUser } from "@/lib/apple-sign-in";
import { authCookieHeaders, signAccessToken } from "@/lib/auth";
import { HttpStatus } from "@/lib/http-status";
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

export async function POST(req: Request) {
  try {
    await limitAuthByIp(req);
    const form = await req.formData();
    const identityToken = String(form.get("id_token") ?? "");
    const state = String(form.get("state") ?? "");
    const stateParams = new URLSearchParams(state);
    const identity = await verifyAppleIdentityToken(identityToken);
    const { user } = await signInOrCreateAppleUser({
      identity,
      displayName: displayNameFrom(typeof form.get("user") === "string" ? String(form.get("user")) : null),
      timezone: stateParams.get("tz") ?? "UTC",
      eulaAccepted: stateParams.get("eula") === "1",
      birthYear: stateParams.get("by") ? Number(stateParams.get("by")) : undefined,
    });
    const access = await signAccessToken(user._id.toHexString());
    const refreshToken = await issueRefreshToken(user._id);
    const base = process.env.APP_BASE_URL ?? "http://localhost:3000";
    const next = stateParams.get("next") ?? "/home";
    const headers = new Headers(authCookieHeaders(access.token, refreshToken));
    headers.set("location", `${base}${next.startsWith("/") ? next : "/home"}`);
    return new Response(null, { status: SEE_OTHER, headers });
  } catch (error) {
    const response = errorResponse(error);
    return response.status === HttpStatus.unauthorized ? Response.redirect(`${process.env.APP_BASE_URL ?? "http://localhost:3000"}/save?apple=failed`, SEE_OTHER) : response;
  }
}
