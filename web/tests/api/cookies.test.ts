// SPEC: 8.7 (httpOnly / Secure cookies on web) · W5 (owner-approved 2026-09-17): `Secure` follows COOKIE_SECURE when it is set, and
// DEFAULTS TO ON in production — an unset variable on Vercel can no longer ship a cookie over plain HTTP (docs/MVP_STATE_REPORT.md §9).
import { afterEach, describe, expect, it } from "vitest";
import { authCookieHeaders, clearedCookieHeaders } from "@/lib/auth";

const lines = (headers: HeadersInit) => new Headers(headers).getSetCookie();
const saved = { secure: process.env.COOKIE_SECURE, env: process.env.NODE_ENV };

afterEach(() => {
  if (saved.secure === undefined) delete process.env.COOKIE_SECURE; else process.env.COOKIE_SECURE = saved.secure;
  Reflect.set(process.env, "NODE_ENV", saved.env);
});

describe("cookie Secure flag", () => {
  it("follows COOKIE_SECURE when set, in any environment", () => {
    Reflect.set(process.env, "NODE_ENV", "production");
    process.env.COOKIE_SECURE = "false";
    expect(lines(authCookieHeaders("a", "r")).every((line) => !line.includes("; Secure"))).toBe(true);
    Reflect.set(process.env, "NODE_ENV", "development");
    process.env.COOKIE_SECURE = "true";
    expect(lines(authCookieHeaders("a", "r")).every((line) => line.includes("; Secure"))).toBe(true);
  });

  it("defaults to Secure in production and to plain elsewhere when COOKIE_SECURE is unset", () => {
    delete process.env.COOKIE_SECURE;
    Reflect.set(process.env, "NODE_ENV", "production");
    expect(lines(authCookieHeaders("a", "r")).every((line) => line.includes("; Secure") && line.includes("HttpOnly") && line.includes("SameSite=Lax"))).toBe(true);
    expect(lines(clearedCookieHeaders()).every((line) => line.includes("; Secure") && line.includes("Max-Age=0"))).toBe(true);
    Reflect.set(process.env, "NODE_ENV", "development");
    expect(lines(authCookieHeaders("a", "r")).every((line) => !line.includes("; Secure"))).toBe(true);
  });
});
