// SPEC: T011 (Verify: auth suite incl. reset rows) · 8.2 Auth: token single-use, 30-min expiry, old token dead after
// use, reset invalidates existing refresh tokens · Part IV (the reset email is one link, gym-buddy voice).
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { POST as login } from "@/app/api/v1/auth/login/route";
import { POST as refresh } from "@/app/api/v1/auth/refresh/route";
import { POST as register } from "@/app/api/v1/auth/register/route";
import { POST as requestReset } from "@/app/api/v1/auth/reset/route";
import { POST as confirmReset } from "@/app/api/v1/auth/reset/confirm/route";
import { closeDb, passwordResets, resetDbForTests } from "@/lib/db";
import { emailOutbox } from "@/lib/email";
import { readJson, request } from "./http";

const jo = { email: "jo@example.com", password: "old password 123", displayName: "Jo", timezone: "Europe/Berlin", eulaAccepted: true, birthYear: 1990 };
interface Tokens { accessToken: string; refreshToken: string }

beforeAll(async () => {
  await resetDbForTests();
  await register(request("POST", "/auth/register", { body: jo }));
});
afterAll(async () => {
  await closeDb();
});

async function latestResetToken(): Promise<string> {
  const email = await (await emailOutbox()).findOne({ to: jo.email, kind: "passwordReset" }, { sort: { sentAt: -1 } });
  const match = /token=([A-Za-z0-9_-]+)/.exec(email?.text ?? "");
  if (!match?.[1]) throw new Error("no reset email in the outbox");
  return match[1];
}

describe("password reset", () => {
  it("accepts every request with 202 and emails one single-use link to a real account", async () => {
    const unknown = await requestReset(request("POST", "/auth/reset", { body: { email: "nobody@example.com" } }));
    expect(unknown.status).toBe(202);
    const known = await requestReset(request("POST", "/auth/reset", { body: { email: jo.email } }));
    expect(known.status).toBe(202);
    const email = await (await emailOutbox()).findOne({ to: jo.email });
    expect(email?.subject).toBe("Reset your Crew password");
    expect((email?.text.match(/https?:\/\//g) ?? []).length).toBe(1);
    expect(email?.text).not.toMatch(/!/);
  });

  it("consumes the token once, changes the password, and revokes refresh tokens", async () => {
    const before = await readJson<Tokens>(await login(request("POST", "/auth/login", { body: { email: jo.email, password: jo.password } })));
    const token = await latestResetToken();
    const confirmed = await confirmReset(request("POST", "/auth/reset/confirm", { body: { token, newPassword: "new password 456" } }));
    expect(confirmed.status).toBe(200);
    const reused = await confirmReset(request("POST", "/auth/reset/confirm", { body: { token, newPassword: "another one 789" } }));
    expect(reused.status).toBe(400);
    expect((await readJson(reused)).error).toMatchObject({ code: "resetTokenInvalid" });
    const oldPassword = await login(request("POST", "/auth/login", { body: { email: jo.email, password: jo.password } }));
    expect(oldPassword.status).toBe(401);
    const newPassword = await login(request("POST", "/auth/login", { body: { email: jo.email, password: "new password 456" } }));
    expect(newPassword.status).toBe(200);
    const deadRefresh = await refresh(request("POST", "/auth/refresh", { body: { refreshToken: before.refreshToken } }));
    expect(deadRefresh.status).toBe(401);
  });

  it("rejects an expired token", async () => {
    await requestReset(request("POST", "/auth/reset", { body: { email: jo.email } }));
    const token = await latestResetToken();
    const { hashToken } = await import("@/lib/refresh-tokens");
    await (await passwordResets()).updateOne({ tokenHash: hashToken(token) }, { $set: { expiresAt: new Date(Date.now() - 1000) } });
    const expired = await confirmReset(request("POST", "/auth/reset/confirm", { body: { token, newPassword: "expired try 000" } }));
    expect(expired.status).toBe(400);
  });
});
