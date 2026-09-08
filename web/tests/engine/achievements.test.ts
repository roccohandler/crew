// SPEC: README kind achievements — the counter derivations the vectors do not cover: prCount (Flow 3 / Flow 9 layer 3),
// crew full-pulse days and weeks (V37/V38/V40 membership rules), and the seed lookups. The thresholds themselves are V45–V50.
import { describe, expect, it } from "vitest";
import { achievementTitle, achievementsEarned } from "@/lib/engine/achievements";
import { fullPulseDays, fullPulseWeeks, type MemberFacts } from "@/lib/engine/crew-rules";
import { addDays } from "@/lib/engine/day-key";
import { newRecords, prCount, type RecordSession } from "@/lib/engine/personal-records";

const session = (completedAt: string, exerciseId: string, weights: (number | null)[]): RecordSession => ({
  completedAt,
  exercises: [{ exerciseId, name: exerciseId, sets: weights.map((weight) => ({ done: true, isWarmup: false, weight })) }],
});

describe("personal records", () => {
  it("counts a new best only against an earlier logged weight", () => {
    const history = [session("2026-09-01T10:00:00Z", "bench", [100, 100]), session("2026-09-03T10:00:00Z", "bench", [105]), session("2026-09-05T10:00:00Z", "bench", [105]), session("2026-09-07T10:00:00Z", "bench", [110])];
    expect(prCount(history)).toBe(2); // 105 beats 100; 110 beats 105; the repeat does not
    expect(prCount([session("2026-09-01T10:00:00Z", "squat", [null, null])])).toBe(0); // never logged weight → no PR
    expect(prCount([session("2026-09-01T10:00:00Z", "squat", [135])])).toBe(0); // the first logged weight is a baseline, not a PR
  });

  it("ignores warm-ups and undone sets, and is chronological regardless of input order", () => {
    const later = session("2026-09-09T10:00:00Z", "row", [90]);
    const earlier: RecordSession = { completedAt: "2026-09-02T10:00:00Z", exercises: [{ exerciseId: "row", name: "row", sets: [{ done: true, isWarmup: true, weight: 200 }, { done: false, isWarmup: false, weight: 150 }, { done: true, isWarmup: false, weight: 80 }] }] };
    expect(prCount([later, earlier])).toBe(1);
    expect(newRecords(later.exercises, [earlier])).toEqual(["row"]);
  });
});

describe("crew full pulse", () => {
  const members: MemberFacts[] = [{ userId: "A", joinedDayKey: "2026-08-31" }, { userId: "B", joinedDayKey: "2026-08-31" }, { userId: "C", joinedDayKey: "2026-09-03" }];
  const everyDay = (userId: string, from: string, count: number) => Array.from({ length: count }, (_, offset) => ({ userId, dayKey: addDays(from, offset) }));

  it("counts days where everyone present posted, with at least the minimum crew", () => {
    const posts = [...everyDay("A", "2026-09-01", 7), ...everyDay("B", "2026-09-01", 7), ...everyDay("C", "2026-09-03", 4)];
    expect(fullPulseDays(members, posts, "2026-09-01", "2026-09-07")).toBe(6); // 09-07: C present, C has posts 09-03..09-06 only → not full
    expect(fullPulseDays([{ userId: "A", joinedDayKey: "2026-08-31" }], everyDay("A", "2026-09-01", 7), "2026-09-01", "2026-09-07")).toBe(0); // one person is not a crew
  });

  it("counts only complete Mon–Sun weeks that start after the user joined", () => {
    const posts = [...everyDay("A", "2026-08-31", 14), ...everyDay("B", "2026-08-31", 14)];
    const pair = members.slice(0, 2);
    expect(fullPulseWeeks(pair, posts, "2026-08-31", "2026-09-13")).toBe(2); // Mon 08-31 → Sun 09-06, Mon 09-07 → Sun 09-13
    expect(fullPulseWeeks(pair, posts, "2026-09-01", "2026-09-13")).toBe(1); // joined Tuesday: the first week does not count
    expect(fullPulseWeeks(pair, posts, "2026-08-31", "2026-09-12")).toBe(1); // the second week is not complete yet
  });
});

describe("seed lookups", () => {
  it("names an earned achievement and knows nothing about unknown ids", () => {
    expect(achievementTitle("first-flame")).toBe("First flame");
    expect(achievementTitle("nope")).toBeNull();
    expect(achievementsEarned({}, [])).toEqual([]);
  });
});
