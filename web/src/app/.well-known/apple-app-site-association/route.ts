// SPEC: 1A (universal links: a tapped invite opens the app) · A21.3 (the link's token takes the pasted-code path) · W7 code half
// (owner order 2026-09-18, item 3) — Apple's app-site association for the host APP_BASE_URL names: /join/* opens Crew on a phone
// that has it, and the web landing page everywhere else. Served as plain JSON with no redirect (Apple's CDN fetches it as-is).
// The app id is <team id>.<bundle id>: the team id is public in this file by design (APPLE_TEAM_ID, or the APNs key's team — the
// same team), the bundle id is the one Sign in with Apple already names. Until both are configured the file is ABSENT (404), so a
// half-configured host never claims links it cannot open. Not under api/v1: Apple fixes the path.
import { errorResponse, notFound } from "@/lib/api-error";

export const dynamic = "force-dynamic"; // read the environment per request: configuring the team id needs no rebuild

export async function GET() {
  try {
    const teamId = process.env.APPLE_TEAM_ID ?? process.env.APNS_TEAM_ID ?? "";
    const bundleId = process.env.APPLE_BUNDLE_ID ?? "";
    if (teamId.length === 0 || bundleId.length === 0) throw notFound("App association");
    const body = { applinks: { details: [{ appIDs: [`${teamId}.${bundleId}`], components: [{ "/": "/join/*", comment: "Crew invite links (A21.3)" }] }] } };
    return new Response(JSON.stringify(body), { headers: { "content-type": "application/json", "cache-control": "public, max-age=3600" } });
  } catch (error) {
    return errorResponse(error);
  }
}
