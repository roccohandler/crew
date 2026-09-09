// SPEC: A6 (owner-directed 2026-09-08) — Today · Yesterday · Mon · Mon Sep 8 · Mon Sep 8, 2025; This week · Last week ·
// Week of Sep 1. Twin of ios/CrewTests/DayLabelTests.swift: identical cases, identical labels.
import { describe, expect, it } from "vitest";
import { dayLabel, weekHeader } from "@/lib/engine/day-label";
import { addDays } from "@/lib/engine/day-key";
import { SpecConstants } from "@/generated/spec-constants";

const today = "2026-09-08"; // a Tuesday

describe("dayLabel — readable day labels", () => {
  it("Today, Yesterday, then a weekday name up to dayLabelWeekdayWithinDays back", () => {
    expect(dayLabel("2026-09-08", today)).toBe("Today");
    expect(dayLabel("2026-09-07", today)).toBe("Yesterday");
    expect(dayLabel("2026-09-06", today)).toBe("Sun");
    expect(dayLabel("2026-09-03", today)).toBe("Thu");
    expect(dayLabel("2026-09-02", today)).toBe("Wed"); // six days back — the last weekday-only label
    expect(dayLabel(addDays(today, -SpecConstants.dayLabelWeekdayWithinDays), today)).toHaveLength("Wed".length);
  });

  it("a date in the same year, a date with its year otherwise", () => {
    expect(dayLabel("2026-09-01", today)).toBe("Tue Sep 1"); // seven days back
    expect(dayLabel(addDays(today, -(SpecConstants.dayLabelWeekdayWithinDays + 1)), today)).toBe("Tue Sep 1");
    expect(dayLabel("2026-01-01", today)).toBe("Thu Jan 1");
    expect(dayLabel("2025-12-31", today)).toBe("Wed Dec 31, 2025");
    expect(dayLabel("2025-09-08", today)).toBe("Mon Sep 8, 2025");
  });

  it("a future day (a pause's return day) reads as a date, never as a bare weekday", () => {
    expect(dayLabel("2026-09-09", today)).toBe("Wed Sep 9");
    expect(dayLabel("2026-09-14", today)).toBe("Mon Sep 14");
    expect(dayLabel("2027-01-04", today)).toBe("Mon Jan 4, 2027");
  });
});

describe("weekHeader — This week · Last week · Week of", () => {
  it("names the current and previous weeks, then the Monday's date", () => {
    expect(weekHeader("2026-09-07", "2026-09-07")).toBe("This week");
    expect(weekHeader("2026-08-31", "2026-09-07")).toBe("Last week");
    expect(weekHeader("2026-08-24", "2026-09-07")).toBe("Week of Aug 24");
    expect(weekHeader("2025-12-29", "2026-09-07")).toBe("Week of Dec 29");
  });
});
