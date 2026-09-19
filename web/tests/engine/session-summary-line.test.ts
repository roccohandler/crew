// SPEC: A6 (owner-directed 2026-09-08) as amended by A28 (c) (2026-09-19) — "Push day · 12 of 12 sets" (no minutes: nothing shows the
// time a workout took) · "Walk · 25 min · 2.1 km" (a cardio log's ENTERED minutes stand, GAP 4 in A28); A2 distance in meters, shown
// at one decimal in the poster's units. Twin of ios/CrewTests/SessionSummaryLineTests.swift: identical cases.
import { describe, expect, it } from "vitest";
import { distanceText, sessionSummaryLine, withoutWorkoutMinutes } from "@/lib/engine/session-summary-line";

describe("sessionSummaryLine", () => {
  it("a strength session reads its sets and nothing of the clock", () => {
    expect(sessionSummaryLine("Push day", false, 12, 12, null, null, "km")).toBe("Push day · 12 of 12 sets");
    expect(sessionSummaryLine("Leg day", false, 1, 15, null, null, "mi")).toBe("Leg day · 1 of 15 sets");
  });

  it("a cardio log reads its entered minutes and, when known, the distance in the poster's units", () => {
    expect(sessionSummaryLine("Walk", true, 1, 1, 25, 2100, "km")).toBe("Walk · 25 min · 2.1 km");
    expect(sessionSummaryLine("Walk", true, 1, 1, 25, 2100, "mi")).toBe("Walk · 25 min · 1.3 mi");
    expect(sessionSummaryLine("Run", true, 1, 1, 30, null, "mi")).toBe("Run · 30 min");
    // A28 (c): no logged minutes no longer falls back to the session's clock
    expect(sessionSummaryLine("Bike", true, 1, 1, null, null, "km")).toBe("Bike");
    expect(sessionSummaryLine("Bike", true, 1, 1, null, 5000, "km")).toBe("Bike · 5.0 km");
  });

  it("distance rounds half-up to tenths identically on both engines", () => {
    expect(distanceText(2250, "km")).toBe("2.3 km"); // an exact half
    expect(distanceText(2249, "km")).toBe("2.2 km");
    expect(distanceText(1000, "km")).toBe("1.0 km");
    expect(distanceText(0, "km")).toBe("0.0 km");
    expect(distanceText(950, "km")).toBe("1.0 km");
    expect(distanceText(1609, "mi")).toBe("1.0 mi");
    expect(distanceText(16093, "mi")).toBe("10.0 mi");
    expect(distanceText(100000, "mi")).toBe("62.1 mi");
  });

  // A28 (c) · R-086 — a summary stored before A28 reads without the workout's minutes; everything else reads as stored
  it("a stored summary reads without the workout's minutes", () => {
    expect(withoutWorkoutMinutes("Push day · 12/12 sets · 44 min")).toBe("Push day · 12 of 12 sets");
    expect(withoutWorkoutMinutes("Push day · 12 of 12 sets")).toBe("Push day · 12 of 12 sets");
    expect(withoutWorkoutMinutes("Walk · 25 min · 2.1 km")).toBe("Walk · 25 min · 2.1 km");
    expect(withoutWorkoutMinutes("Walk · 25 min")).toBe("Walk · 25 min");
    expect(withoutWorkoutMinutes("Leg day · 3/x sets · 9 min")).toBe("Leg day · 3/x sets · 9 min");
  });
});
