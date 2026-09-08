// SPEC: T042 (Verify: unit) · E4 / S18 — the welcome-back answer lives on the account: PATCH users/me { welcomeBackAckDay }
// round-trips through GET users/me, is validated as a day key, and starts out null for a new account.
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { GET as getMe, PATCH as patchMe } from "@/app/api/v1/users/me/route";
import { closeDb, resetDbForTests } from "@/lib/db";
import { HttpStatus } from "@/lib/http-status";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";

let me: TestUser;

beforeAll(async () => {
  await resetDbForTests();
  me = await createUser("lapsed", "UTC");
});

afterAll(async () => {
  await closeDb();
});

describe("welcome-back acknowledgement (E4)", () => {
  it("is null for a new account and round-trips once answered", async () => {
    const fresh = await readJson<{ user: { welcomeBackAckDay: string | null } }>(await getMe(request("GET", "/users/me", { token: me.accessToken })));
    expect(fresh.user.welcomeBackAckDay).toBeNull();
    const patched = await readJson<{ welcomeBackAckDay: string | null }>(await patchMe(request("PATCH", "/users/me", { token: me.accessToken, body: { welcomeBackAckDay: "2026-09-04" } })));
    expect(patched.welcomeBackAckDay).toBe("2026-09-04");
    const again = await readJson<{ user: { welcomeBackAckDay: string | null } }>(await getMe(request("GET", "/users/me", { token: me.accessToken })));
    expect(again.user.welcomeBackAckDay).toBe("2026-09-04");
  });

  it("rejects anything that is not a day key", async () => {
    const response = await patchMe(request("PATCH", "/users/me", { token: me.accessToken, body: { welcomeBackAckDay: "yesterday" } }));
    expect(response.status).toBe(HttpStatus.badRequest);
  });
});
