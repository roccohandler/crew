// SPEC: A21.3 / W4 — the pasted invite code is read out of a bare code, a full link, or a link with a query or fragment;
// twin of ios/CrewTests/InviteCodeTests.swift (same cases, same answers).
import { describe, expect, it } from "vitest";
import { inviteToken } from "@/lib/invite-code";

describe("inviteToken", () => {
  it("accepts a bare code, trimmed", () => {
    expect(inviteToken("  abc123DEF  ")).toBe("abc123DEF");
  });
  it("reads the code out of a full invite link, with or without a query or fragment", () => {
    // The host is nothing to the parser, and the two here prove it: the one the links carried before W7 and the one they carry
    // now (APP_BASE_URL, 2026-09-18). Neither is rewritten when the domain moves again — that is the point of keeping both.
    expect(inviteToken("https://trycrew.fit/join/abc123DEF")).toBe("abc123DEF");
    expect(inviteToken("https://crew-eta-one.vercel.app/join/abc123DEF")).toBe("abc123DEF");
    expect(inviteToken("https://crew-eta-one.vercel.app/join/abc123DEF?utm=x#top")).toBe("abc123DEF");
    expect(inviteToken("crew-eta-one.vercel.app/join/abc123DEF/")).toBe("abc123DEF");
  });
  it("rejects nothing, whitespace inside a code, and a link with no code", () => {
    expect(inviteToken("")).toBeNull();
    expect(inviteToken("   ")).toBeNull();
    expect(inviteToken("abc 123")).toBeNull();
    expect(inviteToken("https://crew-eta-one.vercel.app/join/")).toBeNull();
  });
});
