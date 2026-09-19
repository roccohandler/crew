// SPEC: A28 (e) · GAP 10 as R-086 reads it — the season label's day arithmetic. Twin of ios/CrewTests/SeasonFactsTests.swift:
// identical cases.
import { describe, expect, it } from "vitest";
import { seasonFacts, seasonLine } from "@/lib/progress-facts";

const built = [{ from: "2026-08-10", weekdays: [1, 3, 5] }]; // a Monday

describe("seasonFacts", () => {
  it("counts the calendar weeks from the build to today, this one included, and the workouts inside them", () => {
    const facts = seasonFacts(built, [], ["2026-08-10", "2026-08-12", "2026-09-18", "2026-08-01"], "2026-09-19");
    expect(facts).toEqual({ startDayKey: "2026-08-10", weeks: 6, workouts: 3 });
    expect(seasonLine(facts!)).toBe("This season · 6 weeks · 3 workouts");
  });

  it("restarts at the end of the latest pause that has run its course; one still running changes nothing", () => {
    expect(seasonFacts(built, ["2026-09-07", "2026-08-24"], ["2026-09-01", "2026-09-08"], "2026-09-19")).toEqual({ startDayKey: "2026-09-07", weeks: 2, workouts: 1 });
    expect(seasonFacts(built, ["2026-09-25"], [], "2026-09-19")?.startDayKey).toBe("2026-08-10");
  });

  it("a days change is not a restart: the season runs from the FIRST entry", () => {
    const changed = [...built, { from: "2026-09-02", weekdays: [2, 4] }];
    expect(seasonFacts(changed, [], [], "2026-09-19")?.startDayKey).toBe("2026-08-10");
  });

  it("a season that started this week reads in the singular; no plan history reads nothing", () => {
    const facts = seasonFacts([{ from: "2026-09-17", weekdays: [4] }], [], ["2026-09-17"], "2026-09-19");
    expect(seasonLine(facts!)).toBe("This season · 1 week · 1 workout");
    expect(seasonFacts([], [], [], "2026-09-19")).toBeNull();
  });
});
