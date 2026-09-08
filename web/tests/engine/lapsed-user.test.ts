// SPEC: T042 (Verify: unit) — the 14-day welcome-back trigger (E4/S18) and the stale-session rule (S01)
import { describe, expect, it } from "vitest";
import { isStaleSession, quietDays, shouldShowWelcomeBack } from "@/lib/lapsed-user";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

describe("welcome back (E4 / S18)", () => {
  it("counts quiet days from the last activity", () => {
    expect(quietDays("2026-09-01", "2026-09-15")).toBe(14);
    expect(quietDays("2026-09-15", "2026-09-01")).toBe(0);
  });

  it("triggers at 14 quiet days, not 13", () => {
    expect(shouldShowWelcomeBack("2026-09-01", null, "2026-09-14")).toBe(false);
    expect(shouldShowWelcomeBack("2026-09-01", null, "2026-09-15")).toBe(true);
    expect(SpecConstants.lapsedUserQuietDays).toBe(14);
  });

  it("never shows for a user without a post (the bridge owns them)", () => {
    expect(shouldShowWelcomeBack(null, null, "2026-09-15")).toBe(false);
  });

  it("stays silent once acknowledged during this quiet spell", () => {
    expect(shouldShowWelcomeBack("2026-09-01", "2026-09-15", "2026-09-15")).toBe(false);
    expect(shouldShowWelcomeBack("2026-09-01", "2026-09-15", "2026-10-30")).toBe(false);
  });

  it("shows again after activity and a fresh 14 quiet days", () => {
    expect(shouldShowWelcomeBack("2026-09-20", "2026-09-15", "2026-10-04")).toBe(true);
  });
});

describe("stale session (S01)", () => {
  const started = new Date("2026-09-04T18:00:00Z");
  it("is stale after more than a day, not before", () => {
    const limit = SpecConstants.staleInProgressSessionAfterHours * TimeUnits.msPerHour;
    expect(isStaleSession(started, new Date(started.getTime() + limit))).toBe(false);
    expect(isStaleSession(started, new Date(started.getTime() + limit + 1))).toBe(true);
  });
});
