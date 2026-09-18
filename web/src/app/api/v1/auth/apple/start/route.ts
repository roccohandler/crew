// SPEC: docs/api.md GET auth/apple/start — W5 (owner-approved 2026-09-17): the web Sign in with Apple flow begins HERE, not at a
// link built into the page. This route mints the nonce, signs it into a short-lived `state` with what the attempt carries (EULA
// answer, where to land, timezone, birth year), sets the nonce as the browser's cookie and sends the browser to Apple with both.
// The callback accepts only the matching triple. Public; nothing is stored server-side.
import { appleAuthorizeUrl, appleNonceCookie, appleStateTtlSeconds, newAppleNonce, signAppleState, type AppleStart } from "@/lib/apple-auth";

const SEE_OTHER = 303;

function startFrom(url: URL): AppleStart {
  const next = url.searchParams.get("next") ?? "/home";
  const by = Number(url.searchParams.get("by") ?? "");
  const tz = url.searchParams.get("tz") ?? "";
  return { eula: url.searchParams.get("eula") === "1", next: next.startsWith("/") ? next : "/home", tz: tz.length > 0 ? tz : undefined, by: Number.isInteger(by) && by > 0 ? by : undefined };
}

export async function GET(req: Request) {
  const nonce = newAppleNonce();
  const state = await signAppleState(startFrom(new URL(req.url)), nonce);
  const headers = new Headers({ location: appleAuthorizeUrl(state, nonce), "cache-control": "no-store" });
  headers.append("set-cookie", appleNonceCookie(nonce, appleStateTtlSeconds));
  return new Response(null, { status: SEE_OTHER, headers });
}
