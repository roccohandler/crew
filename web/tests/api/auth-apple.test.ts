// SPEC: T012 (Verify: auth suite + manual device check) · docs/api.md POST auth/apple + the web callback ·
// E9 gates on first sign-in · E18 (a returning subject signs straight in). Real jose verification against a local JWKS.
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { POST as appleSignIn } from "@/app/api/v1/auth/apple/route";
import { POST as appleCallback } from "@/app/api/v1/auth/apple/callback/route";
import { closeDb, resetDbForTests, users } from "@/lib/db";
import { startFakeApple, type FakeApple } from "./apple-jwks";
import { readJson, request } from "./http";

const BUNDLE_ID = "com.test.crew";
const SERVICES_ID = "com.test.crew.web";
let apple: FakeApple;

beforeAll(async () => {
  await resetDbForTests();
  apple = await startFakeApple(BUNDLE_ID);
  process.env.APPLE_JWKS_URL = apple.url;
  process.env.APPLE_BUNDLE_ID = BUNDLE_ID;
  process.env.APPLE_SERVICES_ID = SERVICES_ID;
});
afterAll(async () => {
  await apple.stop();
  await closeDb();
});

describe("auth/apple", () => {
  it("creates an account from a valid identity token (201) and signs the same subject straight in (200)", async () => {
    const token = await apple.sign({ sub: "001234.abcdef", email: "jordan@privaterelay.appleid.com", email_verified: "true" });
    const created = await appleSignIn(request("POST", "/auth/apple", { body: { identityToken: token, displayName: "Jordan", timezone: "America/New_York", eulaAccepted: true, birthYear: 1992 } }));
    expect(created.status).toBe(201);
    const body = await readJson<{ user: { displayName: string; authProvider: string }; accessToken: string }>(created);
    expect(body.user.displayName).toBe("Jordan");
    expect(body.user.authProvider).toBe("apple");
    expect(body.accessToken).toBeTruthy();

    const again = await apple.sign({ sub: "001234.abcdef" });
    const signedIn = await appleSignIn(request("POST", "/auth/apple", { body: { identityToken: again, timezone: "America/New_York", eulaAccepted: false } }));
    expect(signedIn.status).toBe(200);
    expect(await (await users()).countDocuments({ appleSub: "001234.abcdef" })).toBe(1);
  });

  it("rejects a token for another audience, a wrong issuer, or garbage", async () => {
    const wrongAudience = await apple.sign({ sub: "9.9" }, { audience: "com.someone.else" });
    expect((await appleSignIn(request("POST", "/auth/apple", { body: { identityToken: wrongAudience, timezone: "UTC", eulaAccepted: true } }))).status).toBe(401);
    const wrongIssuer = await apple.sign({ sub: "9.9" }, { issuer: "https://evil.example" });
    expect((await appleSignIn(request("POST", "/auth/apple", { body: { identityToken: wrongIssuer, timezone: "UTC", eulaAccepted: true } }))).status).toBe(401);
    expect((await appleSignIn(request("POST", "/auth/apple", { body: { identityToken: "not.a.jwt", timezone: "UTC", eulaAccepted: true } }))).status).toBe(401);
  });

  it("gates a NEW Apple account on the EULA", async () => {
    const token = await apple.sign({ sub: "fresh.sub", email: "fresh@example.com" });
    const response = await appleSignIn(request("POST", "/auth/apple", { body: { identityToken: token, timezone: "UTC", eulaAccepted: false } }));
    expect(response.status).toBe(403);
    expect((await readJson(response)).error).toMatchObject({ code: "eulaRequired" });
  });

  it("web callback: verifies the form post, sets cookies, and redirects into the app", async () => {
    const token = await apple.sign({ sub: "web.sub.1", email: "web@example.com" }, { audience: SERVICES_ID });
    const form = new URLSearchParams({ id_token: token, state: "tz=Europe/Berlin&eula=1&by=1990&next=/home", user: JSON.stringify({ name: { firstName: "Sam", lastName: "Web" } }) });
    const req = new Request("http://localhost:3000/api/v1/auth/apple/callback", { method: "POST", headers: { "content-type": "application/x-www-form-urlencoded" }, body: form.toString() });
    const response = await appleCallback(req);
    expect(response.status).toBe(303);
    expect(response.headers.get("location")).toBe("http://localhost:3000/home");
    expect(response.headers.getSetCookie().some((line) => line.startsWith("crew_access="))).toBe(true);
    const user = await (await users()).findOne({ appleSub: "web.sub.1" });
    expect(user?.displayName).toBe("Sam Web");
  });
});
