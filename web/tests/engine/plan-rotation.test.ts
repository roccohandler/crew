// SPEC: A1 (owner-directed 2026-09-08) rotation rules — 4 days → 12 completions → 4/4/4; misses never advance; 1 day →
// Push then Pull three weeks later; 7 days → PPLPPLP / PLPPLPP; a cardio session never advances; legacy names infer; a
// plan without the last kind cycles its own kinds. Twin of ios/CrewTests/PlanRotationTests.swift: identical cases.
import { describe, expect, it } from "vitest";
import { lastRotationKind, nextTrainingDayKey, nextWorkoutKind, projectWeek, workoutKindFromName, type RotationSession } from "@/lib/engine/plan-rotation";
import { TimeUnits } from "@/lib/time-units";

const ppl = ["push", "pull", "legs"];
const completed = (kind: string | null, order: number, name = ""): RotationSession => ({ kind, name, completedAt: order, status: "completed" });

function completeNext(sessions: RotationSession[], cycle: string[]): string {
  const next = nextWorkoutKind(lastRotationKind(sessions, cycle), cycle);
  sessions.push(completed(next, sessions.length + 1));
  return next;
}

describe("nextWorkoutKind / lastRotationKind — the pointer follows the last COMPLETED rotation workout", () => {
  it("4 days a week, 12 completions → 4 Push, 4 Pull, 4 Legs", () => {
    const sessions: RotationSession[] = [];
    const done: string[] = [];
    for (let index = 0; index < 12; index += 1) done.push(completeNext(sessions, ppl));
    expect(done.slice(0, 3)).toEqual(ppl);
    expect(done.filter((kind) => kind === "push")).toHaveLength(4);
    expect(done.filter((kind) => kind === "pull")).toHaveLength(4);
    expect(done.filter((kind) => kind === "legs")).toHaveLength(4);
  });

  it("misses, in-progress and discarded sessions never advance", () => {
    const sessions = [completed("push", 1), { kind: "pull", name: "Pull day", completedAt: null, status: "inProgress" }, { kind: "pull", name: "Pull day", completedAt: 2, status: "discarded" }];
    expect(lastRotationKind(sessions, ppl)).toBe("push");
    expect(nextWorkoutKind("push", ppl)).toBe("pull");
    expect(nextWorkoutKind("legs", ppl)).toBe("push");
    expect(nextWorkoutKind(null, ppl)).toBe("push");
    expect(lastRotationKind([], ppl)).toBeNull();
  });

  it("the latest completion wins regardless of list order", () => {
    expect(lastRotationKind([completed("legs", 3), completed("push", 1), completed("pull", 2)], ppl)).toBe("legs");
  });

  it("a cardio session never advances", () => {
    expect(lastRotationKind([completed("push", 1), completed("cardio", 2, "Walk")], ppl)).toBe("push");
  });

  it("legacy sessions infer their kind from the name; a stored kind is never overridden by the name", () => {
    expect(workoutKindFromName("Push day")).toBe("push");
    expect(workoutKindFromName("Pull day")).toBe("pull");
    expect(workoutKindFromName("Leg day")).toBe("legs");
    expect(workoutKindFromName("Full body A")).toBe("fullBodyA");
    expect(workoutKindFromName("Full body B")).toBe("fullBodyB");
    expect(workoutKindFromName("Walk")).toBeNull();
    expect(lastRotationKind([completed(null, 1, "Leg day")], ppl)).toBe("legs");
    expect(lastRotationKind([completed("custom", 1, "Push day")], ppl)).toBeNull();
    expect(lastRotationKind([completed(null, 1, "Full body B")], ["fullBodyA", "fullBodyB"])).toBe("fullBodyB");
  });

  it("a plan without the last completed kind cycles its own kinds from the top", () => {
    const cycle = ["custom", "push"];
    expect(nextWorkoutKind("legs", cycle)).toBe("custom");
    expect(lastRotationKind([completed("legs", 1)], cycle)).toBeNull();
    expect(lastRotationKind([completed("legs", 2), completed("custom", 1)], cycle)).toBe("custom");
    expect(nextWorkoutKind("custom", cycle)).toBe("push");
    expect(nextWorkoutKind("push", cycle)).toBe("custom");
  });
});

describe("projectWeek — done · rest · open · planned, kinds running on from nextKind", () => {
  it("1 day a week: Push this Monday, Pull three weeks later even after two missed Mondays", () => {
    const week1 = projectWeek({ weekKey: "2026-09-07", todayKey: "2026-09-07", trainingWeekdays: [1], cycle: ppl, nextKind: "push", completedKindByDay: {} });
    expect(week1.map((day) => day.state)).toEqual(["planned", "rest", "rest", "rest", "rest", "rest", "rest"]);
    expect(week1[0]?.kind).toBe("push");
    const after = nextWorkoutKind(lastRotationKind([completed("push", 1)], ppl), ppl);
    const week4 = projectWeek({ weekKey: "2026-09-28", todayKey: "2026-09-28", trainingWeekdays: [1], cycle: ppl, nextKind: after, completedKindByDay: {} });
    expect(week4[0]?.kind).toBe("pull");
    const week2 = projectWeek({ weekKey: "2026-09-14", todayKey: "2026-09-28", trainingWeekdays: [1], cycle: ppl, nextKind: after, completedKindByDay: {} });
    expect(week2[0]?.state).toBe("open"); // a missed Monday: no word, no kind, no red
    expect(week2[0]?.kind).toBeNull();
  });

  it("7 days a week: PPLPPLP, then PLPPLPP once all seven are completed", () => {
    const all = [1, 2, 3, 4, 5, 6, 7];
    const week1 = projectWeek({ weekKey: "2026-09-07", todayKey: "2026-09-07", trainingWeekdays: all, cycle: ppl, nextKind: "push", completedKindByDay: {} });
    expect(week1.map((day) => day.kind)).toEqual(["push", "pull", "legs", "push", "pull", "legs", "push"]);
    const sessions: RotationSession[] = [];
    for (let index = 0; index < TimeUnits.daysPerWeek; index += 1) completeNext(sessions, ppl);
    const next = nextWorkoutKind(lastRotationKind(sessions, ppl), ppl);
    const week2 = projectWeek({ weekKey: "2026-09-14", todayKey: "2026-09-14", trainingWeekdays: all, cycle: ppl, nextKind: next, completedKindByDay: {} });
    expect(week2.map((day) => day.kind)).toEqual(["pull", "legs", "push", "pull", "legs", "push", "pull"]);
  });

  it("states: a done Monday, rest days, today and Friday planned; past training days without a session are open", () => {
    const week = projectWeek({ weekKey: "2026-09-09", todayKey: "2026-09-09", trainingWeekdays: [1, 3, 5], cycle: ppl, nextKind: "pull", completedKindByDay: { "2026-09-07": "push" } });
    expect(week.map((day) => day.dayKey)).toEqual(["2026-09-07", "2026-09-08", "2026-09-09", "2026-09-10", "2026-09-11", "2026-09-12", "2026-09-13"]);
    expect(week.map((day) => day.weekday)).toEqual([1, 2, 3, 4, 5, 6, 7]);
    expect(week.map((day) => day.state)).toEqual(["done", "rest", "planned", "rest", "planned", "rest", "rest"]);
    expect(week.map((day) => day.kind)).toEqual(["push", null, "pull", null, "legs", null, null]);
    const missed = projectWeek({ weekKey: "2026-09-07", todayKey: "2026-09-10", trainingWeekdays: [1, 3, 5], cycle: ppl, nextKind: "push", completedKindByDay: {} });
    expect(missed.map((day) => day.state)).toEqual(["open", "rest", "open", "rest", "planned", "rest", "rest"]);
    expect(missed[4]?.kind).toBe("push");
  });

  it("nextTrainingDayKey is the next planned day strictly after a day", () => {
    expect(nextTrainingDayKey("2026-09-09", [1, 3, 5])).toBe("2026-09-11");
    expect(nextTrainingDayKey("2026-09-11", [1, 3, 5])).toBe("2026-09-14");
    expect(nextTrainingDayKey("2026-09-11", [5])).toBe("2026-09-18");
    expect(nextTrainingDayKey("2026-09-11", [])).toBeNull();
  });
});
