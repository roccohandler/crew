// SPEC: 8.3 "DayKey: 3 AM boundary, Monday weeks, DST, timezone shifts" — the unit half of T016 (the vector half is V05–V10 in
// tests/vectors.test.ts). Twin of ios/CrewTests/DayKeyTests.swift: identical cases, identical expected keys. E8 · E20.
import { describe, expect, it } from "vitest";
import { addDays, dayKeyFor, daysBetween, isoWeekday, weekKeyFor } from "@/lib/engine/day-key";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

const LA = "America/Los_Angeles";
const BERLIN = "Europe/Berlin";
const AUCKLAND = "Pacific/Auckland";

describe("dayKeyFor — the day ends at 3 AM local (E8)", () => {
  it("02:59 belongs to the previous calendar day, 03:00 opens the new one", () => {
    expect(dayKeyFor(new Date("2026-09-08T09:59:00Z"), LA)).toBe("2026-09-07"); // 02:59 PDT
    expect(dayKeyFor(new Date("2026-09-08T10:00:00Z"), LA)).toBe("2026-09-08"); // 03:00 PDT
    expect(dayKeyFor(new Date("2026-09-08T00:59:00Z"), BERLIN)).toBe("2026-09-07"); // 02:59 CEST
    expect(dayKeyFor(new Date("2026-09-08T01:00:00Z"), BERLIN)).toBe("2026-09-08"); // 03:00 CEST
  });

  it("the boundary hour is the spec constant, never a typed 3", () => {
    const boundaryUtcHour = SpecConstants.dayBoundaryHour; // UTC has no offset, so the boundary is that hour on the clock
    expect(dayKeyFor(new Date(Date.UTC(2026, 8, 8, boundaryUtcHour - 1, 59)), "UTC")).toBe("2026-09-07");
    expect(dayKeyFor(new Date(Date.UTC(2026, 8, 8, boundaryUtcHour, 0)), "UTC")).toBe("2026-09-08");
  });

  it("DST spring-forward keeps a full 24 h day (V08 reading: the boundary that night sits at 04:00 on the clock)", () => {
    // Los Angeles springs forward 2026-03-08 at 02:00 PST → 03:00 PDT. Midnight of 03-08 is 08:00Z; +3 h absolute = 11:00Z,
    // which the clock shows as 04:00 PDT.
    expect(dayKeyFor(new Date("2026-03-08T10:59:00Z"), LA)).toBe("2026-03-07"); // 03:59 PDT, still the 7th
    expect(dayKeyFor(new Date("2026-03-08T11:00:00Z"), LA)).toBe("2026-03-08");
  });

  it("DST fall-back: the boundary is 3 h of absolute time past midnight (02:00 on the clock that night)", () => {
    // Los Angeles falls back 2026-11-01 at 02:00 PDT → 01:00 PST. Midnight of 11-01 is 07:00Z; +3 h = 10:00Z = 02:00 PST.
    expect(dayKeyFor(new Date("2026-11-01T09:59:00Z"), LA)).toBe("2026-10-31");
    expect(dayKeyFor(new Date("2026-11-01T10:00:00Z"), LA)).toBe("2026-11-01");
  });

  it("follows the device's zone: the same instant is different days on either side of the date line (E8)", () => {
    const instant = new Date("2026-09-08T15:30:00Z");
    expect(dayKeyFor(instant, LA)).toBe("2026-09-08"); // 08:30 PDT
    expect(dayKeyFor(instant, AUCKLAND)).toBe("2026-09-09"); // 03:30 NZST — past the boundary, the 9th has begun
    expect(dayKeyFor(new Date("2026-09-08T14:30:00Z"), AUCKLAND)).toBe("2026-09-08"); // 02:30 NZST — still the 8th
  });
});

describe("weekKeyFor — Monday-start weeks worldwide (E20)", () => {
  it("maps every day of a week to its Monday, Sunday included", () => {
    for (const day of ["2026-09-07", "2026-09-08", "2026-09-10", "2026-09-12", "2026-09-13"]) expect(weekKeyFor(day)).toBe("2026-09-07");
    expect(weekKeyFor("2026-09-14")).toBe("2026-09-14");
    expect(weekKeyFor("2026-09-06")).toBe("2026-08-31");
  });

  it("isoWeekday runs Monday 1 … Sunday 7", () => {
    expect(isoWeekday("2026-09-07")).toBe(SpecConstants.weekStartWeekday);
    expect(isoWeekday("2026-09-13")).toBe(TimeUnits.daysPerWeek);
  });
});

describe("addDays / daysBetween — calendar arithmetic that ignores DST and zones", () => {
  it("crosses month and year ends", () => {
    expect(addDays("2026-12-31", 1)).toBe("2027-01-01");
    expect(addDays("2026-03-01", -1)).toBe("2026-02-28");
    expect(daysBetween("2026-12-31", "2027-01-01")).toBe(1);
    expect(daysBetween("2027-01-01", "2026-12-31")).toBe(-1);
  });

  it("a DST change between two day keys is still a whole number of days", () => {
    expect(daysBetween("2026-03-07", "2026-03-09")).toBe(1 + 1);
    expect(daysBetween("2026-10-31", "2026-11-02")).toBe(1 + 1);
  });
});
