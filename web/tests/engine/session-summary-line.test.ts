// SPEC: A6 (owner-directed 2026-09-08) — "Push day · 12/12 sets · 44 min" · "Walk · 25 min · 2.1 km"; A2 distance in
// meters, shown at one decimal in the poster's units. Twin of ios/CrewTests/SessionSummaryLineTests.swift: identical cases.
import { describe, expect, it } from "vitest";
import { distanceText, sessionSummaryLine } from "@/lib/engine/session-summary-line";

describe("sessionSummaryLine", () => {
  it("a strength session reads sets and wall-clock minutes", () => {
    expect(sessionSummaryLine("Push day", false, 12, 12, 44, null, null, "km")).toBe("Push day · 12/12 sets · 44 min");
    expect(sessionSummaryLine("Leg day", false, 1, 15, 3, null, null, "mi")).toBe("Leg day · 1/15 sets · 3 min");
  });

  it("a cardio log reads its minutes and, when known, the distance in the poster's units", () => {
    expect(sessionSummaryLine("Walk", true, 1, 1, 0, 25, 2100, "km")).toBe("Walk · 25 min · 2.1 km");
    expect(sessionSummaryLine("Walk", true, 1, 1, 0, 25, 2100, "mi")).toBe("Walk · 25 min · 1.3 mi");
    expect(sessionSummaryLine("Run", true, 1, 1, 0, 30, null, "mi")).toBe("Run · 30 min");
    expect(sessionSummaryLine("Bike", true, 1, 1, 12, null, null, "km")).toBe("Bike · 12 min"); // no logged minutes → the session's own
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
});
