// SPEC: G11 (post creation 60/hour/user) · 8.7 "rate limits on auth + posting" — the auth limiter is proven in auth.test.ts;
// this is the posting half: the 61st post inside an hour is 429, and it is per USER (a second account is unaffected). T044
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { POST as createPost } from "@/app/api/v1/posts/route";
import { closeDb, resetDbForTests } from "@/lib/db";
import { HttpStatus } from "@/lib/http-status";
import { SpecConstants } from "@/generated/spec-constants";
import { createUser, type TestUser } from "./fixtures";
import { request } from "./http";

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

const post = (user: TestUser) => createPost(request("POST", "/posts", { token: user.accessToken, body: { clientId: randomUUID(), type: "text", caption: "plate", shareToCrew: false, timezone: "UTC", isPlannedDay: false } }));

describe("post creation limit (G11: 60/hour/user)", () => {
  it("accepts the first 60 posts in an hour and rejects the 61st with 429, per user", async () => {
    const statuses: number[] = [];
    for (let index = 0; index < SpecConstants.rateLimitPostCreationPerHourPerUser; index += 1) statuses.push((await post(poster)).status);
    expect(statuses.every((status) => status === HttpStatus.created)).toBe(true);
    expect((await post(poster)).status).toBe(HttpStatus.tooManyRequests);
    expect((await post(neighbour)).status).toBe(HttpStatus.created);
  }, 120_000);
});
