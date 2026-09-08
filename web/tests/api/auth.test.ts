// SPEC: T010 (Verify: npm test tests/api/auth) · 8.2 Auth: register/login/refresh rotation/logout; duplicate email;
// EULA gate; age floor (E9); rate limit (G11); cookie vs Bearer (Part IV). Real handlers, real MongoDB.
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { POST as login } from "@/app/api/v1/auth/login/route";
import { POST as logout } from "@/app/api/v1/auth/logout/route";
import { POST as refresh } from "@/app/api/v1/auth/refresh/route";
import { POST as register } from "@/app/api/v1/auth/register/route";
import { closeDb, resetDbForTests } from "@/lib/db";
import { SpecConstants } from "@/generated/spec-constants";
import { cookiesFrom, readJson, request } from "./http";

const sam = { email: "sam@example.com", password: "correct horse battery", displayName: "Sam", timezone: "America/Los_Angeles", eulaAccepted: true, birthYear: 1994 };

interface Tokens { user: { id: string; email: string }; accessToken: string; refreshToken: string }

beforeAll(async () => {
  await resetDbForTests();
});
afterAll(async () => {
  await closeDb();
});

describe("auth/register", () => {
  it("creates the account and returns tokens to the iOS client", async () => {
    const response = await register(request("POST", "/auth/register", { body: sam }));
    expect(response.status).toBe(201);
    const body = await readJson<Tokens>(response);
    expect(body.user.email).toBe(sam.email);
    expect(body.accessToken.split(".")).toHaveLength(3);
    expect(body.refreshToken.length).toBeGreaterThan(20);
    expect(response.headers.getSetCookie()).toHaveLength(0);
  });

  it("rejects a duplicate email regardless of case", async () => {
    const response = await register(request("POST", "/auth/register", { body: { ...sam, email: "SAM@example.com" } }));
    expect(response.status).toBe(409);
    expect((await readJson(response)).error).toMatchObject({ code: "emailTaken" });
  });

  it("gates on the EULA and the age floor before writing anything", async () => {
    const noEula = await register(request("POST", "/auth/register", { body: { ...sam, email: "eula@example.com", eulaAccepted: false } }));
    expect(noEula.status).toBe(403);
    const young = await register(request("POST", "/auth/register", { body: { ...sam, email: "young@example.com", birthYear: new Date().getUTCFullYear() - SpecConstants.minimumAgeYears + 1 } }));
    expect(young.status).toBe(403);
    expect((await readJson(young)).error).toMatchObject({ code: "underage" });
  });

  it("returns the standard error shape for a malformed body", async () => {
    const response = await register(request("POST", "/auth/register", { rawBody: "{not json" }));
    expect(response.status).toBe(400);
    expect((await readJson(response)).error).toMatchObject({ code: "validation" });
  });

  // A phone names its zone as Foundation does — "GMT" on a device set to UTC, "US/Pacific" on an older one — and the server
  // must take every zone it can compute day keys with (E8); a made-up zone is still a validation error (R-052).
  it("accepts every timezone Intl can format with, not only the canonical list", async () => {
    // each call from its own address so this test never spends the file's shared G11 budget (10/min per IP)
    for (const [index, timezone] of ["GMT", "UTC", "US/Pacific", "Etc/GMT+5"].entries()) {
      const response = await register(request("POST", "/auth/register", { ip: `198.51.100.${index + 1}`, body: { ...sam, email: `zone-${index}@example.com`, timezone } }));
      expect(response.status, timezone).toBe(201);
    }
    const madeUp = await register(request("POST", "/auth/register", { ip: "198.51.100.9", body: { ...sam, email: "zone-mars@example.com", timezone: "Mars/Olympus" } }));
    expect(madeUp.status).toBe(400);
    expect((await readJson(madeUp)).error).toMatchObject({ code: "validation" });
  });
});

describe("auth/login + refresh rotation + logout", () => {
  it("logs in, rotates the refresh token, and kills the family on reuse", async () => {
    const loginResponse = await login(request("POST", "/auth/login", { body: { email: sam.email, password: sam.password } }));
    expect(loginResponse.status).toBe(200);
    const first = await readJson<Tokens>(loginResponse);

    const rotated = await refresh(request("POST", "/auth/refresh", { body: { refreshToken: first.refreshToken } }));
    expect(rotated.status).toBe(200);
    const second = await readJson<Tokens>(rotated);
    expect(second.refreshToken).not.toBe(first.refreshToken);

    const reuse = await refresh(request("POST", "/auth/refresh", { body: { refreshToken: first.refreshToken } }));
    expect(reuse.status).toBe(401);
    const familyDead = await refresh(request("POST", "/auth/refresh", { body: { refreshToken: second.refreshToken } }));
    expect(familyDead.status).toBe(401);
  });

  it("rejects a wrong password with 401 and no detail", async () => {
    const response = await login(request("POST", "/auth/login", { body: { email: sam.email, password: "nope nope nope" } }));
    expect(response.status).toBe(401);
    expect((await readJson(response)).error).toMatchObject({ code: "invalidCredentials" });
  });

  it("uses httpOnly cookies for the web client and refreshes from the cookie", async () => {
    const response = await login(request("POST", "/auth/login", { body: { email: sam.email, password: sam.password }, ios: false }));
    expect(response.status).toBe(200);
    const cookies = response.headers.getSetCookie();
    expect(cookies.some((line) => line.startsWith("crew_access=") && /HttpOnly/i.test(line))).toBe(true);
    expect(cookies.some((line) => line.startsWith("crew_refresh=") && /Path=\/api\/v1\/auth/.test(line))).toBe(true);
    const refreshed = await refresh(request("POST", "/auth/refresh", { cookie: cookiesFrom(response), ios: false }));
    expect(refreshed.status).toBe(200);
    expect(refreshed.headers.getSetCookie().some((line) => line.startsWith("crew_refresh="))).toBe(true);
  });

  it("logout revokes the refresh token and clears cookies", async () => {
    const loginResponse = await login(request("POST", "/auth/login", { body: { email: sam.email, password: sam.password } }));
    const tokens = await readJson<Tokens>(loginResponse);
    const response = await logout(request("POST", "/auth/logout", { token: tokens.accessToken, body: { refreshToken: tokens.refreshToken } }));
    expect(response.status).toBe(200);
    expect(response.headers.getSetCookie().some((line) => line.startsWith("crew_access=;"))).toBe(true);
    const dead = await refresh(request("POST", "/auth/refresh", { body: { refreshToken: tokens.refreshToken } }));
    expect(dead.status).toBe(401);
  });

  it("rate-limits auth endpoints per IP (G11)", async () => {
    let last = 0;
    for (let attempt = 0; attempt < SpecConstants.rateLimitAuthRequestsPerMinutePerIp + 1; attempt += 1) {
      const response = await login(request("POST", "/auth/login", { body: { email: sam.email, password: "wrong" }, ip: "203.0.113.9" }));
      last = response.status;
    }
    expect(last).toBe(429);
  });
});
