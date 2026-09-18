// SPEC: T012 (Verify: auth suite + manual device check) · docs/api.md POST auth/apple + the web callback ·
// E9 gates on first sign-in · E18 (a returning subject signs straight in). Real jose verification against a local JWKS.
// W5 (2026-09-17): the web flow is state/nonce bound — start route → signed state + nonce cookie → Apple echoes the nonce → callback
// accepts only the matching triple; every failure lands on /login?apple=failed.
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { POST as appleSignIn } from "@/app/api/v1/auth/apple/route";
import { POST as appleCallback } from "@/app/api/v1/auth/apple/callback/route";
import { GET as appleStart } from "@/app/api/v1/auth/apple/start/route";
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

  // W5 — the start route: a signed state and a nonce, in the Apple URL and in the browser's cookie
  async function startWeb(): Promise<{ state: string; nonce: string; cookie: string }> {
    const started = await appleStart(new Request("http://localhost:3000/api/v1/auth/apple/start?eula=1&next=%2Fhome&tz=Europe%2FBerlin&by=1990"));
    expect(started.status).toBe(303);
    const location = new URL(started.headers.get("location") ?? "");
    expect(`${location.origin}${location.pathname}`).toBe("https://appleid.apple.com/auth/authorize");
    const state = location.searchParams.get("state") ?? "";
    const nonce = location.searchParams.get("nonce") ?? "";
    expect(state.split(".")).toHaveLength(3); // a JWT, not the old plain query string
    expect(nonce.length).toBeGreaterThan(0);
    const cookie = started.headers.getSetCookie().find((line) => line.startsWith("crew_apple_nonce=")) ?? "";
    expect(cookie).toContain("SameSite=None; Secure"); // Apple's cross-site form POST must carry it
    return { state, nonce, cookie: cookie.split(";")[0] ?? "" };
  }

  const callback = (form: URLSearchParams, cookie?: string) =>
    appleCallback(new Request("http://localhost:3000/api/v1/auth/apple/callback", { method: "POST", headers: { "content-type": "application/x-www-form-urlencoded", ...(cookie ? { cookie } : {}) }, body: form.toString() }));

  it("web callback: the start route binds the attempt; the callback verifies state, cookie and id_token nonce, sets cookies, and redirects into the app", async () => {
    const { state, nonce, cookie } = await startWeb();
    const token = await apple.sign({ sub: "web.sub.1", email: "web@example.com", nonce }, { audience: SERVICES_ID });
    const response = await callback(new URLSearchParams({ id_token: token, state, user: JSON.stringify({ name: { firstName: "Sam", lastName: "Web" } }) }), cookie);
    expect(response.status).toBe(303);
    expect(response.headers.get("location")).toBe("http://localhost:3000/home");
    const set = response.headers.getSetCookie();
    expect(set.some((line) => line.startsWith("crew_access="))).toBe(true);
    expect(set.some((line) => line.startsWith("crew_apple_nonce=;") && line.includes("Max-Age=0"))).toBe(true); // single-use
    const user = await (await users()).findOne({ appleSub: "web.sub.1" });
    expect(user?.displayName).toBe("Sam Web");
    expect(user?.timezone).toBe("Europe/Berlin");
  });

  it("web callback: a token minted for another nonce, a missing browser cookie, or an unsigned state all land on /login?apple=failed and sign nobody in", async () => {
    const { state, nonce, cookie } = await startWeb();
    const failed = "http://localhost:3000/login?apple=failed";
    const otherNonce = await apple.sign({ sub: "web.sub.2", email: "w2@example.com", nonce: "someone-elses-attempt" }, { audience: SERVICES_ID });
    expect((await callback(new URLSearchParams({ id_token: otherNonce, state }), cookie)).headers.get("location")).toBe(failed);
    const right = await apple.sign({ sub: "web.sub.2", email: "w2@example.com", nonce }, { audience: SERVICES_ID });
    expect((await callback(new URLSearchParams({ id_token: right, state }))).headers.get("location")).toBe(failed); // no cookie: another browser
    expect((await callback(new URLSearchParams({ id_token: right, state: "tz=Europe/Berlin&eula=1&next=/home" }), cookie)).headers.get("location")).toBe(failed); // the old unsigned shape
    expect(await (await users()).countDocuments({ appleSub: "web.sub.2" })).toBe(0);
  });
});
