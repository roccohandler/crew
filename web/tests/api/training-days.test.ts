// SPEC: A27 (a) as ruled 2026-09-18 (owner-approved) — a day is judged by the training days in effect on that day; a change takes
// effect from the dayKey it is saved, forward, never backward; the history is append-only; a plan from before A27 is migrated to
// one entry in effect from its creation dayKey. Every reader that asks "was this day planned?" consults the entry in effect for
// that dayKey: Home's week marks and ring, the Progress rings, the journal's Rest day tag, the notification check (the cron's). The
// streak and perfect-week rules are the vectors' (V85–V90). Real Mongo, real handlers, no mocks (C4).
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { ObjectId } from "mongodb";
import { isRestDay } from "@/app/(app)/journal/rows";
import { GET as getPlan, PUT as putPlan } from "@/app/api/v1/plans/route";
import { closeDb, plans, resetDbForTests, users } from "@/lib/db";
import { dayKeyFor } from "@/lib/engine/day-key";
import type { TrainingDaysEntry } from "@/lib/engine/training-days";
import { gatherFacts } from "@/lib/notification-facts";
import { findPlan, replacePlan } from "@/lib/plans";
import { progressFacts } from "@/lib/progress-facts";
import { homeFacts } from "@/lib/today-state";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { samplePlanBody } from "./plans-sessions";

const TZ = "America/Los_Angeles";
// Mon/Wed/Fri until Thursday 2026-09-10, Tue/Thu/Sat from it
const HISTORY: TrainingDaysEntry[] = [{ from: "2026-09-01", weekdays: [1, 3, 5] }, { from: "2026-09-10", weekdays: [2, 4, 6] }];
const at = (dayKey: string) => new Date(`${dayKey}T18:00:00Z`); // 11:00 in TZ, well clear of the 3 AM boundary
const oid = (user: TestUser) => new ObjectId(user.id);

interface PlanReply { trainingWeekdays: number[]; trainingDaysHistory: TrainingDaysEntry[] }
const fetchPlan = async (user: TestUser) => readJson<PlanReply>(await getPlan(request("GET", "/plans", { token: user.accessToken })));

// A plan document written straight into the collection, the way the history reads after a change on Thursday
async function planWithHistory(user: TestUser): Promise<void> {
  await (await plans()).insertOne({ _id: new ObjectId(), userId: oid(user), trainingWeekdays: [2, 4, 6], trainingDaysHistory: HISTORY, workouts: samplePlanBody([2, 4, 6]).workouts, updatedAt: at("2026-09-10") });
}

beforeAll(async () => {
  await resetDbForTests();
});
afterAll(async () => {
  await closeDb();
});

describe("the history — append-only, forward only (A27 (a))", () => {
  it("PUT appends a change of days in effect from the day it is saved; the same days append nothing; GET returns it", async () => {
    const user = await createUser("td-append", TZ);
    const today = dayKeyFor(new Date(), TZ);
    await putPlan(request("PUT", "/plans", { token: user.accessToken, body: samplePlanBody([1, 3, 5]) }));
    const reordered = samplePlanBody([1, 3, 5]);
    await putPlan(request("PUT", "/plans", { token: user.accessToken, body: { ...reordered, workouts: [...reordered.workouts].reverse() } })); // an exercise-only save
    expect((await fetchPlan(user)).trainingDaysHistory).toEqual([{ from: today, weekdays: [1, 3, 5] }]);
    await putPlan(request("PUT", "/plans", { token: user.accessToken, body: samplePlanBody([6, 2, 4]) }));
    const fetched = await fetchPlan(user);
    expect(fetched.trainingDaysHistory).toEqual([{ from: today, weekdays: [1, 3, 5] }, { from: today, weekdays: [2, 4, 6] }]);
    expect(fetched.trainingWeekdays).toEqual([2, 4, 6]); // always the last entry
  });

  it("a plan from before A27 is migrated once: one entry, its days, in effect from its creation dayKey; a change then appends", async () => {
    const user = await createUser("td-migrate", TZ);
    const created = ObjectId.createFromTime(Date.UTC(2026, 8, 3, 18) / 1000); // 2026-09-03 11:00 in TZ
    await (await plans()).insertOne({ _id: created, userId: oid(user), trainingWeekdays: [1, 3, 5], workouts: samplePlanBody().workouts, updatedAt: at("2026-09-03") } as never);
    expect((await fetchPlan(user)).trainingDaysHistory).toEqual([{ from: "2026-09-03", weekdays: [1, 3, 5] }]);
    expect((await (await plans()).findOne({ userId: oid(user) }))?.trainingDaysHistory).toEqual([{ from: "2026-09-03", weekdays: [1, 3, 5] }]); // written, once
    await putPlan(request("PUT", "/plans", { token: user.accessToken, body: samplePlanBody([2]) }));
    expect((await fetchPlan(user)).trainingDaysHistory).toEqual([{ from: "2026-09-03", weekdays: [1, 3, 5] }, { from: dayKeyFor(new Date(), TZ), weekdays: [2] }]);
  });

  it("a queued edit keeps its own day inside E15's window; outside it the server clock wins; never before the last entry", async () => {
    const user = await createUser("td-saved-at", "UTC");
    const body = (days: number[], savedAt?: string) => ({ ...samplePlanBody(days), ...(savedAt === undefined ? {} : { savedAt }) });
    await replacePlan(oid(user), body([1, 3, 5]), "UTC", at("2026-09-10"));
    await replacePlan(oid(user), body([2, 4, 6], "2026-09-12T12:00:00Z"), "UTC", at("2026-09-14")); // two days late: its own day
    await replacePlan(oid(user), body([7], "2026-08-01T12:00:00Z"), "UTC", at("2026-09-15")); // outside the window: now
    await replacePlan(oid(user), body([1], "2026-09-13T12:00:00Z"), "UTC", at("2026-09-16")); // behind the last entry: its day
    expect((await findPlan(oid(user)))?.trainingDaysHistory).toEqual([
      { from: "2026-09-10", weekdays: [1, 3, 5] }, { from: "2026-09-12", weekdays: [2, 4, 6] }, { from: "2026-09-15", weekdays: [7] }, { from: "2026-09-15", weekdays: [1] },
    ]);
  });
});

describe("every reader asks the days in effect on the day it judges (A27 (a))", () => {
  it("Home's week marks and ring: Monday and Wednesday stay missed under the old days, Thursday on reads the new ones", async () => {
    const user = await createUser("td-home", TZ);
    await planWithHistory(user);
    const facts = await homeFacts(oid(user), TZ, at("2026-09-10"));
    expect(facts.weekMarks).toEqual(["missed", "rest", "missed", "today", "rest", "nextUp", "rest"]);
    expect(facts.ringPlanned).toBe(4); // Mon, Wed (old days) + Thu, Sat (new days)
  });

  it("the Progress rings count each week's planned days by the days in effect on each of them", async () => {
    const user = await createUser("td-progress", TZ);
    const facts = await progressFacts(oid(user), TZ, HISTORY, at("2026-09-10"));
    expect(facts.weeks.map((week) => [week.weekKey, week.planned]).slice(-2)).toEqual([["2026-08-31", 3], ["2026-09-07", 4]]);
  });

  it("the journal's Rest day tag reads the day's own training days, never today's", () => {
    expect(isRestDay("2026-09-08", [], HISTORY)).toBe(true); // Tuesday under the old days
    expect(isRestDay("2026-09-09", [], HISTORY)).toBe(false); // Wednesday under the old days
    expect(isRestDay("2026-09-11", [], HISTORY)).toBe(true); // Friday under the new days
    expect(isRestDay("2026-09-12", [], HISTORY)).toBe(false); // Saturday under the new days
  });

  it("the notification check (the cron's) asks the entry in effect on today's dayKey", async () => {
    const user = await createUser("td-notify", TZ);
    await planWithHistory(user);
    const doc = await (await users()).findOne({ _id: oid(user) });
    if (doc === null) throw new Error("no user");
    const planned = async (dayKey: string) => (await gatherFacts({ _id: doc._id, timezone: TZ, reminderTime: null }, 0, at(dayKey))).reminder.isPlannedDay;
    expect(await planned("2026-09-09")).toBe(true); // Wednesday, old days
    expect(await planned("2026-09-10")).toBe(true); // Thursday, new days
    expect(await planned("2026-09-11")).toBe(false); // Friday, new days: rest
  });
});
