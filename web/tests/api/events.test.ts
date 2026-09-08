// SPEC: docs/api.md POST events · 1C ("measured, funnel-instrumented") · 1D (the onboarding → first-post gap as its own funnel
// step) · Part IV (first-party analytics) · 8.2 ③ (malformed body → 400 in the standard shape). Real handler, real database (C4).
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { POST as postEvents } from "@/app/api/v1/events/route";
import { closeDb, events, resetDbForTests } from "@/lib/db";
import { HttpStatus } from "@/lib/http-status";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";

let me: TestUser;

beforeAll(async () => {
  await resetDbForTests();
  me = await createUser("funnel", "UTC");
});

afterAll(async () => {
  await closeDb();
});

describe("POST events (client funnel events)", () => {
  it("stores a batch under the caller with the client's own timestamps and the server's receivedAt", async () => {
    const heroAt = "2026-09-08T10:00:00.000Z";
    const savedAt = "2026-09-08T10:01:12.000Z";
    const response = await postEvents(request("POST", "/events", { token: me.accessToken, ios: false, body: { events: [{ name: "onboarding_hero", at: heroAt, props: { invite: false } }, { name: "onboarding_saved", at: savedAt }] } }));
    expect(response.status).toBe(HttpStatus.created);
    expect(await readJson<{ accepted: number }>(response)).toEqual({ accepted: 2 });

    const stored = await (await events()).find({ name: { $in: ["onboarding_hero", "onboarding_saved"] } }).sort({ at: 1 }).toArray();
    expect(stored.map((event) => event.name)).toEqual(["onboarding_hero", "onboarding_saved"]);
    expect(stored.every((event) => event.userId?.toHexString() === me.id)).toBe(true);
    expect(stored.every((event) => event.source === "web")).toBe(true);
    expect(stored[0]?.at.toISOString()).toBe(heroAt);
    expect(stored[0]?.props).toEqual({ invite: false });
    expect(stored[1]?.props).toEqual({});
    // hero → saved is the 1C speed measurement, computable from the stored moments alone
    expect((stored[1]?.at.getTime() ?? 0) - (stored[0]?.at.getTime() ?? 0)).toBe(72_000);
    expect(stored.every((event) => event.receivedAt instanceof Date)).toBe(true);
  });

  it("marks the iPhone's batches as ios", async () => {
    const response = await postEvents(request("POST", "/events", { token: me.accessToken, body: { events: [{ name: "onboarding_plan_built", at: "2026-09-08T10:00:40.000Z" }] } }));
    expect(response.status).toBe(HttpStatus.created);
    const stored = await (await events()).findOne({ name: "onboarding_plan_built" });
    expect(stored?.source).toBe("ios");
  });

  it("rejects an empty batch, a missing timestamp and a non-ISO timestamp with the standard error shape", async () => {
    for (const body of [{ events: [] }, { events: [{ name: "onboarding_hero" }] }, { events: [{ name: "onboarding_hero", at: "yesterday" }] }]) {
      const response = await postEvents(request("POST", "/events", { token: me.accessToken, body }));
      expect(response.status).toBe(HttpStatus.badRequest);
      const reply = await readJson<{ error: { code: string; message: string } }>(response);
      expect(reply.error.code).toBe("validation");
    }
  });

  it("needs an account (a funnel step is flushed after sign-up, never anonymously)", async () => {
    const response = await postEvents(request("POST", "/events", { body: { events: [{ name: "onboarding_hero", at: "2026-09-08T10:00:00.000Z" }] } }));
    expect(response.status).toBe(HttpStatus.unauthorized);
  });
});
