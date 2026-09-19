// SPEC: 1A · A21.3 · W7 code half (owner order 2026-09-18, item 3) — the app-site association: /join/* belongs to <team>.<bundle>;
// absent (404) until the team and the bundle are configured, so a half-configured host claims nothing; the APNs team id stands in
// for APPLE_TEAM_ID (the same team). Real handler, no mocks (C4).
import { afterEach, describe, expect, it } from "vitest";
import { GET } from "@/app/.well-known/apple-app-site-association/route";

const saved = { team: process.env.APPLE_TEAM_ID, apns: process.env.APNS_TEAM_ID, bundle: process.env.APPLE_BUNDLE_ID };
function setEnv(name: "APPLE_TEAM_ID" | "APNS_TEAM_ID" | "APPLE_BUNDLE_ID", value: string | undefined): void {
  if (value === undefined) delete process.env[name]; else process.env[name] = value;
}

afterEach(() => {
  setEnv("APPLE_TEAM_ID", saved.team);
  setEnv("APNS_TEAM_ID", saved.apns);
  setEnv("APPLE_BUNDLE_ID", saved.bundle);
});

describe("apple-app-site-association", () => {
  it("claims /join/* for the configured app, as JSON, with no redirect", async () => {
    setEnv("APPLE_TEAM_ID", "ABCDE12345");
    setEnv("APPLE_BUNDLE_ID", "com.example.crew");
    const reply = await GET();
    expect(reply.status).toBe(200);
    expect(reply.headers.get("content-type")).toBe("application/json");
    expect(reply.headers.get("location")).toBeNull();
    const body = (await reply.json()) as { applinks: { details: { appIDs: string[]; components: { "/": string }[] }[] } };
    expect(body.applinks.details).toHaveLength(1);
    expect(body.applinks.details[0]?.appIDs).toEqual(["ABCDE12345.com.example.crew"]);
    expect(body.applinks.details[0]?.components.map((component) => component["/"])).toEqual(["/join/*"]);
  });

  it("falls back to the APNs key's team id, and is absent until both the team and the bundle are configured", async () => {
    setEnv("APPLE_TEAM_ID", undefined);
    setEnv("APNS_TEAM_ID", "ZYXWV98765");
    setEnv("APPLE_BUNDLE_ID", "com.example.crew");
    const viaApns = (await (await GET()).json()) as { applinks: { details: { appIDs: string[] }[] } };
    expect(viaApns.applinks.details[0]?.appIDs).toEqual(["ZYXWV98765.com.example.crew"]);
    setEnv("APNS_TEAM_ID", undefined);
    expect((await GET()).status).toBe(404);
    setEnv("APPLE_TEAM_ID", "ABCDE12345");
    setEnv("APPLE_BUNDLE_ID", undefined);
    expect((await GET()).status).toBe(404);
  });

  // W7 (2026-09-18): the two ways a configured host still serves nothing, or serves an appID Apple never matches.
  it("counts a blank id as unset, and keeps no pasted whitespace in the appID", async () => {
    setEnv("APPLE_TEAM_ID", "");
    setEnv("APNS_TEAM_ID", "ZYXWV98765");
    setEnv("APPLE_BUNDLE_ID", "com.example.crew");
    const viaApns = (await (await GET()).json()) as { applinks: { details: { appIDs: string[] }[] } };
    expect(viaApns.applinks.details[0]?.appIDs).toEqual(["ZYXWV98765.com.example.crew"]);
    setEnv("APPLE_TEAM_ID", " ABCDE12345\n");
    setEnv("APPLE_BUNDLE_ID", " com.example.crew ");
    const pasted = (await (await GET()).json()) as { applinks: { details: { appIDs: string[] }[] } };
    expect(pasted.applinks.details[0]?.appIDs).toEqual(["ABCDE12345.com.example.crew"]);
    setEnv("APPLE_TEAM_ID", "   ");
    setEnv("APNS_TEAM_ID", undefined);
    expect((await GET()).status).toBe(404);
  });
});
