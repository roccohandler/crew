// The standing-checks registry: one entry per route + method. standing-checks.gen.test.ts discovers every route.ts
// under app/api/v1 and FAILS for any (route, method) missing here — a new route cannot ship without declaring how the
// four standing checks apply to it (8.2 ①–④, T015).
//   public      — no token needed (② does not apply)
//   jsonBody    — ③ applies: "{" → 400 and {} → 400 in the standard error shape (false = no JSON body)
//   validBody   — ④ applies when it carries clientId: the same body twice returns the same document id
//   foreignPath — ① applies: a path to a resource owned by ANOTHER user, called as the test user → 403 or 404
import { randomUUID } from "node:crypto";
import { POST as createMealLogRoute } from "@/app/api/v1/nutrition/logs/route";
import { POST as createSavedMealRoute } from "@/app/api/v1/nutrition/saved-meals/route";
import { POST as createSessionRoute } from "@/app/api/v1/sessions/route";
import type { TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { samplePlanBody, sampleSessionBody } from "./plans-sessions";
import { postWorkout } from "./workout-post";

async function foreignSessionPath(_me: TestUser, other: TestUser): Promise<string> {
  const reply = await readJson<{ session: { id: string } }>(await createSessionRoute(request("POST", "/sessions", { token: other.accessToken, body: sampleSessionBody() })));
  return `/sessions/${reply.session.id}`;
}

// A22 (2026-09-18): a post exists only through a completed session, so the foreign post is the other user's posted workout
async function foreignPostPath(_me: TestUser, other: TestUser): Promise<string> {
  return `/posts/${(await postWorkout(other, { cardio: true, timezone: "UTC" })).postId}`;
}

// nutrition addendum §2 — another adult's saved meal and log: each must be a 404 for the test user (8.2 ①)
const savedMealBody = () => ({ clientId: randomUUID(), name: "Chicken and rice", proteinG: 45, carbsG: 60, fatG: 12 });
const mealLogBody = () => ({ clientId: randomUUID(), timezone: "UTC", name: "Quick add", proteinG: 30, carbsG: 0, fatG: 10, quickAdd: true });
async function foreignSavedMealPath(_me: TestUser, other: TestUser): Promise<string> {
  const reply = await readJson<{ meal: { id: string } }>(await createSavedMealRoute(request("POST", "/nutrition/saved-meals", { token: other.accessToken, body: savedMealBody() })));
  return `/nutrition/saved-meals/${reply.meal.id}`;
}
async function foreignMealLogPath(_me: TestUser, other: TestUser): Promise<string> {
  const reply = await readJson<{ log: { id: string } }>(await createMealLogRoute(request("POST", "/nutrition/logs", { token: other.accessToken, body: mealLogBody() })));
  return `/nutrition/logs/${reply.log.id}`;
}

const foreignReactionPath = async (me: TestUser, other: TestUser) => `${await foreignPostPath(me, other)}/reactions`;

// A crew the test user is NOT in (created by `other`) — every crews/[id]/* method must 404 for outsiders
let foreignCrew: { id: string } | null = null;
async function foreignCrewIds(other: TestUser): Promise<{ id: string }> {
  if (foreignCrew !== null) return foreignCrew;
  const { POST: createCrewRoute } = await import("@/app/api/v1/crews/route");
  const crew = await readJson<{ crew: { id: string } }>(await createCrewRoute(request("POST", "/crews", { token: other.accessToken, body: { name: "Theirs", emoji: "🌊" } })));
  foreignCrew = { id: crew.crew.id }; // A21.2 / W3: the messages routes are gone, so there is no message to seed
  return foreignCrew;
}
const foreignCrewPath = (suffix: string) => async (_me: TestUser, other: TestUser) => `/crews/${(await foreignCrewIds(other)).id}${suffix}`;

export interface StandingEntry {
  public?: boolean;
  jsonBody: boolean;
  validBody?: (user: TestUser) => Promise<object> | object;
  foreignPath?: (user: TestUser, other: TestUser) => Promise<string>;
  idField?: string; // where the created document's id lives in the response (④)
}

export const STANDING_REGISTRY: Record<string, StandingEntry> = {
  "auth/register:POST": { public: true, jsonBody: true },
  "auth/login:POST": { public: true, jsonBody: true },
  "auth/apple:POST": { public: true, jsonBody: true },
  "auth/apple/callback:POST": { public: true, jsonBody: false },
  "auth/apple/start:GET": { public: true, jsonBody: false }, // W5: mints the nonce + signed state, 303 to Apple
  "auth/refresh:POST": { public: true, jsonBody: true },
  "auth/logout:POST": { jsonBody: true },
  "auth/reset:POST": { public: true, jsonBody: true },
  "auth/reset/confirm:POST": { public: true, jsonBody: true },
  "plans:GET": { jsonBody: false },
  "plans:PUT": { jsonBody: true, validBody: () => samplePlanBody() },
  "sessions:POST": { jsonBody: true, validBody: () => sampleSessionBody(), idField: "session" },
  "sessions:GET": { jsonBody: false },
  "sessions/[id]:GET": { jsonBody: false, foreignPath: foreignSessionPath },
  "sessions/[id]:PATCH": { jsonBody: true, foreignPath: foreignSessionPath, validBody: () => ({ timezone: "UTC" }) },
  "sync:POST": { jsonBody: true, validBody: () => ({ timezone: "UTC", ops: [] }) },
  "posts:GET": { jsonBody: false },
  "posts/[id]:GET": { jsonBody: false, foreignPath: foreignPostPath },
  "posts/[id]:PATCH": { jsonBody: true, foreignPath: foreignPostPath, validBody: () => ({ caption: "x" }) },
  "posts/[id]:DELETE": { jsonBody: false, foreignPath: foreignPostPath },
  "posts/[id]/reactions:POST": { jsonBody: true, foreignPath: foreignReactionPath, validBody: () => ({ emoji: "🔥" }) },
  "posts/[id]/reactions:DELETE": { jsonBody: false, foreignPath: foreignReactionPath },
  // nutrition addendum §2 — the fixture users are adults (birthYear at register), so every route is reachable; DELETE targets takes an optional body
  "nutrition/targets:GET": { jsonBody: false },
  "nutrition/targets:PUT": { jsonBody: true, validBody: () => ({ bodyweight: 176, unit: "lb" }) },
  "nutrition/targets:DELETE": { jsonBody: false },
  "nutrition/saved-meals:GET": { jsonBody: false },
  "nutrition/saved-meals:POST": { jsonBody: true, validBody: savedMealBody, idField: "meal" },
  "nutrition/saved-meals/[id]:PATCH": { jsonBody: true, foreignPath: foreignSavedMealPath, validBody: () => ({ name: "renamed" }) },
  "nutrition/saved-meals/[id]:DELETE": { jsonBody: false, foreignPath: foreignSavedMealPath },
  "nutrition/template:GET": { jsonBody: false },
  "nutrition/template:PUT": { jsonBody: true, validBody: () => ({ slots: [] }) },
  "nutrition/logs:GET": { jsonBody: false },
  "nutrition/logs:POST": { jsonBody: true, validBody: mealLogBody, idField: "log" },
  "nutrition/logs/[id]:DELETE": { jsonBody: false, foreignPath: foreignMealLogPath },
  "photos:POST": { jsonBody: false },
  "photos/[key]:GET": { jsonBody: false, foreignPath: async () => "/photos/no-such-key" },
  "crews:POST": { jsonBody: true },
  "crews:GET": { jsonBody: false },
  "crews/join:GET": { public: true, jsonBody: false },
  "crews/join:POST": { jsonBody: true },
  "crews/[id]:PATCH": { jsonBody: true, foreignPath: foreignCrewPath(""), validBody: () => ({ name: "x" }) },
  "crews/[id]/members:GET": { jsonBody: false, foreignPath: foreignCrewPath("/members") },
  "crews/[id]/members:DELETE": { jsonBody: true, foreignPath: foreignCrewPath("/members"), validBody: () => ({}) },
  "crews/[id]/invite:POST": { jsonBody: false, foreignPath: foreignCrewPath("/invite") },
  "crews/[id]/mute:PATCH": { jsonBody: true, foreignPath: foreignCrewPath("/mute"), validBody: () => ({ muted: true }) },
  "crews/[id]/stream:GET": { jsonBody: false, foreignPath: foreignCrewPath("/stream") },
  "blocks:GET": { jsonBody: false },
  "blocks:POST": { jsonBody: true },
  "blocks:DELETE": { jsonBody: true },
  "push-token:POST": { jsonBody: true },
  "push-token:DELETE": { jsonBody: true },
  "reports:POST": { jsonBody: true },
  "events:POST": { jsonBody: true },
  "../cron/notifications:GET": { public: true, jsonBody: false }, // CRON_SECRET-gated, not a user route
  "users/me:GET": { jsonBody: false },
  "users/me:PATCH": { jsonBody: true },
  "users/me:DELETE": { jsonBody: true },
  "users/me/export:GET": { jsonBody: false },
  "pause:GET": { jsonBody: false },
  "pause:POST": { jsonBody: true },
  "pause:DELETE": { jsonBody: false },
};
