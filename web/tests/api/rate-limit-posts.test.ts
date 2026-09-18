// SPEC: G11 (post creation 60/hour/user) · 8.7 "rate limits on auth + posting" — the auth limiter is proven in auth.test.ts;
// this is the posting half. A22 (owner-approved 2026-09-18): a post is created by the session that completes it, so the limiter
// sits on PATCH sessions/[id] when the body carries `post`: the 61st posted completion inside an hour is 429, and it is per USER
// (a second account is unaffected). T044
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { PATCH as patchSession } from "@/app/api/v1/sessions/[id]/route";
import { POST as createSession } from "@/app/api/v1/sessions/route";
import { closeDb, resetDbForTests } from "@/lib/db";
import { HttpStatus } from "@/lib/http-status";
import { SpecConstants } from "@/generated/spec-constants";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { sampleCardioSessionBody } from "./plans-sessions";

let poster: TestUser;
let neighbour: TestUser;

beforeAll(async () => {
  await resetDbForTests();
  poster = await createUser("poster", "UTC");
  neighbour = await createUser("neighbour", "UTC");
});

afterAll(async () => {
  await closeDb();
});

// One posted completion: a standalone cardio log (A2) created and completed with its post, the way the Home flow does it
async function post(user: TestUser): Promise<number> {
  const created = await readJson<{ session: { id: string } }>(await createSession(request("POST", "/sessions", { token: user.accessToken, body: sampleCardioSessionBody({ timezone: "UTC" }) })));
  const done = await patchSession(request("PATCH", `/sessions/${created.session.id}`, { token: user.accessToken, body: { timezone: "UTC", status: "completed", post: { clientId: randomUUID(), shareToCrew: false } } }), { params: Promise.resolve({ id: created.session.id }) });
  return done.status;
}

describe("post creation limit (G11: 60/hour/user)", () => {
  it("accepts the first 60 posted completions in an hour and rejects the 61st with 429, per user", async () => {
    const statuses: number[] = [];
    for (let index = 0; index < SpecConstants.rateLimitPostCreationPerHourPerUser; index += 1) statuses.push(await post(poster));
    expect(statuses.every((status) => status === HttpStatus.ok)).toBe(true);
    expect(await post(poster)).toBe(HttpStatus.tooManyRequests);
    expect(await post(neighbour)).toBe(HttpStatus.ok);
  }, 180_000);
});
