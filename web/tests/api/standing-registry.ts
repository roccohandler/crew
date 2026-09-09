// The standing-checks registry: one entry per route + method. standing-checks.gen.test.ts discovers every route.ts
// under app/api/v1 and FAILS for any (route, method) missing here — a new route cannot ship without declaring how the
// four standing checks apply to it (8.2 ①–④, T015).
//   public      — no token needed (② does not apply)
//   jsonBody    — ③ applies: "{" → 400 and {} → 400 in the standard error shape (false = no JSON body)
//   validBody   — ④ applies when it carries clientId: the same body twice returns the same document id
//   foreignPath — ① applies: a path to a resource owned by ANOTHER user, called as the test user → 403 or 404
import { randomUUID } from "node:crypto";
import { POST as createPostRoute } from "@/app/api/v1/posts/route";
import { POST as createSessionRoute } from "@/app/api/v1/sessions/route";
import type { TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { samplePlanBody, sampleSessionBody } from "./plans-sessions";

async function foreignSessionPath(_me: TestUser, other: TestUser): Promise<string> {
  const reply = await readJson<{ session: { id: string } }>(await createSessionRoute(request("POST", "/sessions", { token: other.accessToken, body: sampleSessionBody() })));
  return `/sessions/${reply.session.id}`;
}

const textPost = () => ({ clientId: randomUUID(), type: "text", caption: "standing check", shareToCrew: false, timezone: "UTC", isPlannedDay: false });

async function foreignPostPath(_me: TestUser, other: TestUser): Promise<string> {
  const reply = await readJson<{ post: { id: string } }>(await createPostRoute(request("POST", "/posts", { token: other.accessToken, body: textPost() })));
  return `/posts/${reply.post.id}`;
}

const foreignReactionPath = async (me: TestUser, other: TestUser) => `${await foreignPostPath(me, other)}/reactions`;

// A crew the test user is NOT in (created by `other`) — every crews/[id]/* method must 404 for outsiders
let foreignCrew: { id: string; messageId: string } | null = null;
async function foreignCrewIds(other: TestUser): Promise<{ id: string; messageId: string }> {
  if (foreignCrew !== null) return foreignCrew;
  const { POST: createCrewRoute } = await import("@/app/api/v1/crews/route");
  const { POST: sendMessageRoute } = await import("@/app/api/v1/crews/[id]/messages/route");
  const crew = await readJson<{ crew: { id: string } }>(await createCrewRoute(request("POST", "/crews", { token: other.accessToken, body: { name: "Theirs", emoji: "🌊" } })));
  const message = await readJson<{ message: { id: string } }>(await sendMessageRoute(request("POST", `/crews/${crew.crew.id}/messages`, { token: other.accessToken, body: { clientId: randomUUID(), body: "hi" } }), { params: Promise.resolve({ id: crew.crew.id }) }));
  foreignCrew = { id: crew.crew.id, messageId: message.message.id };
  return foreignCrew;
}
const foreignCrewPath = (suffix: string) => async (_me: TestUser, other: TestUser) => `/crews/${(await foreignCrewIds(other)).id}${suffix}`;
const foreignMessagePath = async (_me: TestUser, other: TestUser) => { const ids = await foreignCrewIds(other); return `/crews/${ids.id}/messages/${ids.messageId}`; };

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
  "posts:POST": { jsonBody: true, validBody: textPost, idField: "post" },
  "posts:GET": { jsonBody: false },
  "posts/[id]:GET": { jsonBody: false, foreignPath: foreignPostPath },
  "posts/[id]:PATCH": { jsonBody: true, foreignPath: foreignPostPath, validBody: () => ({ caption: "x" }) },
  "posts/[id]:DELETE": { jsonBody: false, foreignPath: foreignPostPath },
  "posts/[id]/reactions:POST": { jsonBody: true, foreignPath: foreignReactionPath, validBody: () => ({ emoji: "🔥" }) },
  "posts/[id]/reactions:DELETE": { jsonBody: false, foreignPath: foreignReactionPath },
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
  "crews/[id]/messages:POST": { jsonBody: true, foreignPath: foreignCrewPath("/messages"), validBody: () => ({ clientId: randomUUID(), body: "hi" }) },
  "crews/[id]/messages/[messageId]:DELETE": { jsonBody: false, foreignPath: foreignMessagePath },
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
