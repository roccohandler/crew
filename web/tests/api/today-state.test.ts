// SPEC: S07 (all five states) · Flow 2 (the weekly ring) · Flow 7 + V20 (pause) · A1 (the rotation projection) ·
// A14 (the three vectors) · A18.1/A18.2/A18.3/A18.6/A18.7/A18.9. Verify: npm test tests/api/today-state
//
// WHY THIS FILE EXISTS (J028, A18). `src/lib/today-state.ts` and `src/lib/home-facts.ts` ARE the web Home — today's
// state, the ring counts, the week's marks, the vector slots, the what's-next fact, quick-complete gating — and
// NOTHING under web/tests/ imported either of them. iOS pins the same facts with three test files (HomeModelTests,
// HomeModelEdgeTests, HomeVectorSlotsTests); the web twin had none, which is how the pause guard could exist on one
// engine and not the other for a whole release.
//
// Real Mongo, real handlers, no mocks (C4).
//
// TIME, AND WHY IT IS SPLIT IN TWO. `homeFacts(userId, tz, now)` takes its own clock, so a READ can be taken on any
// day. A WRITE cannot: E15's server clock wins, and `reconciledInstant` discards a client timestamp outside
// [now − syncClientTimestampMaxAgeDays, now + clientClockSkewToleranceMinutes] — a future-dated completion silently
// lands on today. So every state that needs no session (missed · upcoming · nextUp · rest · paused) is asserted by
// reading at a FIXED date, and every state that needs one (done · allDone · the vectors) is built at the real now
// against a plan whose training day IS today. Nothing here drifts with the calendar.
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { randomUUID } from "node:crypto";
import { ObjectId } from "mongodb";
import { PUT as putPlan } from "@/app/api/v1/plans/route";
import { POST as createSession } from "@/app/api/v1/sessions/route";
import { PATCH as patchSession } from "@/app/api/v1/sessions/[id]/route";
import { POST as createPost } from "@/app/api/v1/posts/route";
import { closeDb, resetDbForTests } from "@/lib/db";
import { dayKeyFor, isoWeekday } from "@/lib/engine/day-key";
import { createPause } from "@/lib/pauses";
import { homeFacts, nextUpLineOf } from "@/lib/today-state";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { doneSets, sampleCardioSessionBody, samplePlanBody, sampleSessionBody } from "./plans-sessions";

const TZ = "America/Los_Angeles";
// Read-only fixtures: a Wednesday whose week holds a past training day (Mon), today (Wed) and future ones (Fri, Sun).
const WEDNESDAY = new Date("2026-09-09T18:00:00Z"); // 11:00 in TZ, well clear of the 3 AM boundary
const THURSDAY = new Date("2026-09-10T18:00:00Z");

const params = (id: string) => ({ params: Promise.resolve({ id }) });
const oid = (user: TestUser) => new ObjectId(user.id);

async function savePlan(user: TestUser, days: number[]): Promise<void> {
  expect((await putPlan(request("PUT", "/plans", { token: user.accessToken, body: samplePlanBody(days) }))).status).toBe(200);
}

async function postMeal(user: TestUser): Promise<void> {
  const created = await createPost(request("POST", "/posts", { token: user.accessToken, body: { clientId: randomUUID(), type: "meal", caption: "eggs", timezone: TZ, shareToCrew: false, isPlannedDay: false } }));
  expect(created.status).toBe(201);
}

// A completed session, at the real now, through the real create + complete handlers. A cardio log arrives already
// done (its one set, V51); a strength session needs its work sets marked before V32 lets it complete.
async function completeSession(user: TestUser, body: ReturnType<typeof sampleSessionBody> | ReturnType<typeof sampleCardioSessionBody>, workSets = 0): Promise<void> {
  const created = await readJson<{ session: { id: string } }>(await createSession(request("POST", "/sessions", { token: user.accessToken, body })));
  const patch: Record<string, unknown> = { timezone: TZ, status: "completed", post: { clientId: randomUUID(), shareToCrew: false } };
  if (workSets > 0) patch.exercises = doneSets(body as ReturnType<typeof sampleSessionBody>, workSets);
  const done = await patchSession(request("PATCH", `/sessions/${created.session.id}`, { token: user.accessToken, body: patch }), params(created.session.id));
  expect(done.status).toBe(200);
}

const today = new Date();
const todayIso = isoWeekday(dayKeyFor(today, TZ));
const someOtherDay = todayIso === 1 ? 2 : 1; // a training day that is NOT today, whatever day this runs on

beforeAll(async () => {
  await resetDbForTests();
});
afterAll(async () => {
  await closeDb();
});

describe("today-state — the five states (S07)", () => {
  it("with no plan there is nothing to report, and §1D's BRIDGE persists until a POST exists — not until a workout does", async () => {
    const user = await createUser("ts-bridge", TZ);
    const empty = await homeFacts(oid(user), TZ, today);
    expect(empty.hasPlan).toBe(false);
    expect(empty.weekMarks).toHaveLength(7);
    expect(empty.todaySummaryLines).toEqual([]);

    await savePlan(user, [todayIso]);
    expect((await homeFacts(oid(user), TZ, today)).today.kind).toBe("bridge");

    // A18.8 — the scenario that put TWO CTAs on the one screen §1D says carries none. Starting a workout creates a
    // SESSION, and the bridge ends on the first POST, so an abandoned first workout leaves the bridge standing with
    // an open session beside it: the page rendered its single bridge CTA *and* a "Resume workout" banner, and an
    // XCUITest asserted both at once. The facts are what the page gates on, so they are what is pinned here.
    const started = await createSession(request("POST", "/sessions", { token: user.accessToken, body: sampleSessionBody({ timezone: TZ }) }));
    expect(started.status).toBe(201);
    const abandoned = await homeFacts(oid(user), TZ, today);
    expect(abandoned.today.kind).toBe("bridge");
    expect(abandoned.openSessionId).not.toBeNull();
  });

  it("a completed training day reads allDone, and A18.9 reports what the day held in the journal's own sentence", async () => {
    const user = await createUser("ts-alldone", TZ);
    await savePlan(user, [todayIso]);
    await postMeal(user); // off the bridge
    await completeSession(user, sampleSessionBody({ timezone: TZ }), 1);

    const facts = await homeFacts(oid(user), TZ, today);
    expect(facts.today.kind).toBe("allDone");
    expect(facts.todaySummaryLines).toHaveLength(1);
    expect(facts.todaySummaryLines[0]).toMatch(/^Push day · \d+\/\d+ sets · \d+ min$/);
    expect(facts.weekMarks[todayIso - 1]).toBe("done");
    expect(facts.ringDone).toBe(1);
    expect(facts.ringPlanned).toBe(1);
  });

  it("a non-training day reads rest, and `posted` flips with the day's posts", async () => {
    const user = await createUser("ts-rest", TZ);
    await savePlan(user, [someOtherDay]);
    await postMeal(user);
    expect((await homeFacts(oid(user), TZ, today)).today).toEqual({ kind: "rest", posted: true });
  });
});

describe("today-state — the ring and the week's marks (Flow 2 · A18.2 · A18.7)", () => {
  it("A18.7 — every planned day is marked, the first upcoming one distinctly, and the strip accounts for the ring", async () => {
    const user = await createUser("ts-marks", TZ);
    await savePlan(user, [1, 3, 5]); // Mon / Wed / Fri, read on a Wednesday
    const facts = await homeFacts(oid(user), TZ, WEDNESDAY);
    expect(facts.weekMarks).toEqual(["missed", "rest", "today", "rest", "nextUp", "rest", "rest"]);
    expect(facts.ringPlanned).toBe(3);
    // THE POINT of A18.7: every day the ring counts carries a mark, so the strip can be read against the fraction
    const counted = facts.weekMarks.filter((mark) => mark !== "rest").length;
    expect(counted).toBe(facts.ringPlanned);
  });

  it("A18.7 — the planned days AFTER the next one are marked too; A17.4 drew them exactly like rest days", async () => {
    const user = await createUser("ts-marks4", TZ);
    await savePlan(user, [1, 3, 5, 7]);
    const facts = await homeFacts(oid(user), TZ, WEDNESDAY);
    expect(facts.weekMarks).toEqual(["missed", "rest", "today", "rest", "nextUp", "rest", "upcoming"]);
    expect(facts.ringPlanned).toBe(4);
    expect(facts.weekMarks.filter((mark) => mark !== "rest")).toHaveLength(4);
  });

  it("A18.2 — a week with planned days and nothing done has a ring with nothing to show (the Monday '0/3')", async () => {
    const user = await createUser("ts-monday", TZ);
    await savePlan(user, [1, 3, 5]);
    const monday = new Date("2026-09-07T18:00:00Z");
    const facts = await homeFacts(oid(user), TZ, monday);
    expect(facts.ringPlanned).toBe(3);
    expect(facts.ringDone).toBe(0); // the gate the page applies is planned > 0 AND done > 0
  });
});

describe("today-state — the pause (Flow 7 · V20 · A18.6)", () => {
  it("A18.6 — a frozen plan offers no planned-workout controls, states no misses, and shows no ring", async () => {
    const user = await createUser("ts-paused", TZ);
    await savePlan(user, [1, 2, 3, 4, 5, 6, 7]); // every day trains, so every past day this week would be a miss
    await postMeal(user);
    // A pause that STARTED three days ago and is still running — created the only way the API allows, by being
    // created when its start day was today. (A retroactive pause is refused; this is how a live one actually exists.)
    const threeDaysAgo = new Date(today.getTime() - 3 * 24 * 60 * 60 * 1000);
    await createPause(oid(user), dayKeyFor(threeDaysAgo, TZ), dayKeyFor(new Date(today.getTime() + 4 * 24 * 60 * 60 * 1000), TZ), TZ, threeDaysAgo);

    const facts = await homeFacts(oid(user), TZ, today);
    expect(facts.today.kind).toBe("paused");
    // J021 — the guard iOS had at HomeModel.swift and web never mirrored
    expect(facts.quickCompleteAvailable).toBe(false); // rendered "Quick complete" under a card reading "Plan paused"
    expect(facts.todayWorkoutKind).toBeNull(); // sent the Workout row to a session stamped isPlannedDay: true
    // A18.6a — the header stops stating a penalty the card denies
    expect(facts.weekMarks).not.toContain("missed");
    expect(facts.weekMarks[todayIso - 1]).toBe("today");
    expect(facts.ringPlanned).toBeLessThan(7); // every frozen day is out of the denominator, not failed in it
    // A18.3 — no what's-next block while frozen: the next training day is inside the pause window
    expect(facts.nextUp).toBeNull();
  });
});

describe("today-state — the vectors and the what's-next fact (A14 · A18.3)", () => {
  it("A14 — a standalone cardio log fills the cardio slot, never the workout slot, and never a planned ring slot", async () => {
    const user = await createUser("ts-cardio", TZ);
    await savePlan(user, [someOtherDay]); // today is a REST day, so a cardio log cannot be confused with a planned one
    await postMeal(user);
    await completeSession(user, sampleCardioSessionBody({ timezone: TZ, minutes: 25 }));

    const facts = await homeFacts(oid(user), TZ, today);
    expect(facts.vectors.cardioMinutes).toBe(25);
    expect(facts.vectors.workoutDone).toBe(false);
    expect(facts.vectors.meals).toBe(1);
    expect(facts.weekMarks[todayIso - 1]).toBe("today"); // A2: a cardio log never fills a planned slot
    expect(facts.ringDone).toBe(0);
  });

  it("A18.3 — the what's-next fact comes in two halves, and the one-sentence form is byte-identical to A3's", async () => {
    const user = await createUser("ts-nextup", TZ);
    await savePlan(user, [1, 3, 5]);
    await postMeal(user);
    const facts = await homeFacts(oid(user), TZ, THURSDAY); // Friday is a training day, so it is "Tomorrow"
    expect(facts.today.kind).toBe("rest");
    expect(facts.nextUp?.heading).toBe("Tomorrow");
    expect(facts.nextUp?.detail).toMatch(/day · \d+ exercises?$/);
    expect(nextUpLineOf(facts.nextUp)).toBe(`Tomorrow: ${facts.nextUp?.detail}`);
  });

  it("A3 — an undone training day says nothing about what is next: the card IS what is next", async () => {
    const user = await createUser("ts-training", TZ);
    await savePlan(user, [todayIso]);
    await postMeal(user);
    const facts = await homeFacts(oid(user), TZ, today);
    expect(facts.today.kind).toBe("workout");
    expect(facts.nextUp).toBeNull();
    expect(facts.quickCompleteAvailable).toBe(true);
  });
});
