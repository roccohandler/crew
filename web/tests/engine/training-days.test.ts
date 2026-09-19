// SPEC: A27 (a) as ruled 2026-09-18 — a day is judged by the training days in effect on that day; a change takes effect from the
// dayKey it is saved, forward, never backward; the history is append-only. Twin of ios/CrewTests/TrainingDaysTests.swift:
// identical cases. The rules on the game engine are the vectors' (V85–V90); these pin the helpers every reader shares.
import { describe, expect, it } from "vitest";
import { appendTrainingDays, isPlannedOn, weekdaysOn, type TrainingDaysEntry } from "@/lib/engine/training-days";

const history: TrainingDaysEntry[] = [{ from: "2026-09-01", weekdays: [1, 3, 5] }, { from: "2026-09-16", weekdays: [2, 4, 6] }];

describe("weekdaysOn / isPlannedOn — the entry in effect ON the day", () => {
  it("the day before a change keeps the old days; the change day and after read the new ones", () => {
    expect(weekdaysOn(history, "2026-09-15")).toEqual([1, 3, 5]);
    expect(weekdaysOn(history, "2026-09-16")).toEqual([2, 4, 6]);
    expect(weekdaysOn(history, "2026-10-30")).toEqual([2, 4, 6]);
    expect(isPlannedOn(history, "2026-09-14")).toBe(true); // Monday, old days
    expect(isPlannedOn(history, "2026-09-15")).toBe(false); // Tuesday, still the old days
    expect(isPlannedOn(history, "2026-09-16")).toBe(false); // Wednesday, the change day: the new days
    expect(isPlannedOn(history, "2026-09-17")).toBe(true); // Thursday, new days
  });

  it("a day before every entry takes the first (R-082); no history plans nothing", () => {
    expect(weekdaysOn(history, "2026-08-03")).toEqual([1, 3, 5]);
    expect(isPlannedOn(history, "2026-08-03")).toBe(true);
    expect(weekdaysOn([], "2026-09-14")).toEqual([]);
    expect(isPlannedOn([], "2026-09-14")).toBe(false);
  });

  it("two changes saved the same day: the later one is in effect from that day", () => {
    const sameDay = [...history, { from: "2026-09-16", weekdays: [7] }];
    expect(weekdaysOn(sameDay, "2026-09-16")).toEqual([7]);
    expect(weekdaysOn(sameDay, "2026-09-15")).toEqual([1, 3, 5]);
  });
});

describe("appendTrainingDays — append-only, forward only", () => {
  it("appends the new days from the day they are saved, sorted and unique, and never edits an entry", () => {
    const next = appendTrainingDays(history, [6, 2, 4, 2, 7], "2026-09-20");
    expect(next).toEqual([...history, { from: "2026-09-20", weekdays: [2, 4, 6, 7] }]);
    expect(next.slice(0, history.length)).toEqual(history);
  });

  it("the same days again append nothing", () => {
    expect(appendTrainingDays(history, [6, 4, 2], "2026-09-20")).toBe(history);
  });

  it("an edit saved before the last entry's day takes effect from that entry's day, never behind it", () => {
    expect(appendTrainingDays(history, [1], "2026-09-10")).toEqual([...history, { from: "2026-09-16", weekdays: [1] }]);
  });

  it("the first entry of a new plan is in effect from the day it is saved", () => {
    expect(appendTrainingDays([], [3, 1, 5], "2026-09-18")).toEqual([{ from: "2026-09-18", weekdays: [1, 3, 5] }]);
  });
});
