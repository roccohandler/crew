// SPEC: T023 (Verify: npm test tests/api/plans) · 8.2 Plans: one-per-user invariant; PUT replace forward-only; limits
// rejected server-side; mobility holds persist · A1: the plan is trainingWeekdays + the ordered rotation; a pre-A1 document
// reads back normalised; kinds unique; training days 1..7, unique, never empty.
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { ObjectId } from "mongodb";
import { GET as getPlan, PUT as putPlan } from "@/app/api/v1/plans/route";
import { closeDb, getDb, plans, resetDbForTests } from "@/lib/db";
import { SpecConstants } from "@/generated/spec-constants";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { samplePlanBody } from "./plans-sessions";

let me: TestUser;
interface PlanReply { trainingWeekdays: number[]; workouts: { kind: string; name: string; weekday?: number; exercises: { type: string; holdSeconds?: number }[] }[] }

beforeAll(async () => {
  await resetDbForTests();
  me = await createUser("plans");
});
afterAll(async () => {
  await closeDb();
});

const fetchPlan = async (user: TestUser) => readJson<PlanReply>(await getPlan(request("GET", "/plans", { token: user.accessToken })));

describe("plans", () => {
  it("404s before a plan exists, then PUT creates and GET returns training days + the rotation with mobility holds", async () => {
    expect((await getPlan(request("GET", "/plans", { token: me.accessToken }))).status).toBe(404);
    const saved = await putPlan(request("PUT", "/plans", { token: me.accessToken, body: samplePlanBody() }));
    expect(saved.status).toBe(200);
    const fetched = await fetchPlan(me);
    expect(fetched.trainingWeekdays).toEqual([1, 3, 5]);
    expect(fetched.workouts.map((workout) => workout.kind)).toEqual(["push", "pull", "legs"]);
    expect(fetched.workouts.every((workout) => workout.weekday === undefined)).toBe(true);
    expect(fetched.workouts[0]!.exercises.some((row) => row.type === "mobility" && (row.holdSeconds ?? 0) > 0)).toBe(true);
  });

  it("PUT replaces the whole plan (one document per user): two training days still rotate all three workouts (A1)", async () => {
    await putPlan(request("PUT", "/plans", { token: me.accessToken, body: samplePlanBody([2, 4]) }));
    const fetched = await fetchPlan(me);
    expect(fetched.trainingWeekdays).toEqual([2, 4]);
    expect(fetched.workouts.map((workout) => workout.kind)).toEqual(["push", "pull", "legs"]);
    expect(await (await plans()).countDocuments({})).toBe(1);
  });

  it("stores the workouts in the order given (that order IS the rotation) and sorts the training days", async () => {
    const body = samplePlanBody([5, 1, 3]);
    await putPlan(request("PUT", "/plans", { token: me.accessToken, body: { trainingWeekdays: [5, 1, 3], workouts: [...body.workouts].reverse() } }));
    const fetched = await fetchPlan(me);
    expect(fetched.trainingWeekdays).toEqual([1, 3, 5]);
    expect(fetched.workouts.map((workout) => workout.kind)).toEqual(["legs", "pull", "push"]);
  });

  it("normalises a pre-A1 document on read: weekdays → trainingWeekdays, workouts deduped by kind in first-seen order, weekday dropped", async () => {
    const legacy = await createUser("legacy-plan");
    const rows = samplePlanBody().workouts;
    const legacyDoc = { _id: new ObjectId(), userId: new ObjectId(legacy.id), updatedAt: new Date(), workouts: [
      { weekday: 1, name: "Push day", kind: "push", exercises: rows[0]!.exercises },
      { weekday: 3, name: "Pull day", kind: "pull", exercises: rows[1]!.exercises },
      { weekday: 5, name: "Push day", kind: "push", exercises: rows[0]!.exercises },
    ] };
    await (await getDb()).collection("plans").insertOne(legacyDoc);
    const fetched = await fetchPlan(legacy);
    expect(fetched.trainingWeekdays).toEqual([1, 3, 5]);
    expect(fetched.workouts.map((workout) => workout.kind)).toEqual(["push", "pull"]);
    expect(fetched.workouts.every((workout) => workout.weekday === undefined)).toBe(true);
    expect(await (await plans()).findOne({ userId: new ObjectId(legacy.id) }, { projection: { trainingWeekdays: 1 } })).not.toHaveProperty("trainingWeekdays"); // read-only until the next PUT
    await putPlan(request("PUT", "/plans", { token: legacy.accessToken, body: samplePlanBody([2]) }));
    const stored = await (await getDb()).collection("plans").findOne({ userId: new ObjectId(legacy.id) });
    expect(stored?.trainingWeekdays).toEqual([2]);
    expect((stored?.workouts as { weekday?: number }[]).every((workout) => workout.weekday === undefined)).toBe(true);
  });

  it("rejects limits server-side: too many exercises, too many sets, a long name, a duplicate kind, bad training days", async () => {
    const base = samplePlanBody();
    const put = async (body: unknown) => (await putPlan(request("PUT", "/plans", { token: me.accessToken, body }))).status;
    const first = base.workouts[0]!;
    expect(await put({ ...base, workouts: [{ ...first, exercises: Array.from({ length: SpecConstants.planMaxExercisesPerDay + 1 }, (_, index) => ({ ...first.exercises[0]!, order: index })) }] })).toBe(400);
    expect(await put({ ...base, workouts: [{ ...first, exercises: [{ ...first.exercises[0]!, targetSets: SpecConstants.planMaxSetsPerExercise + 1 }] }] })).toBe(400);
    expect(await put({ ...base, workouts: [{ ...first, exercises: [{ ...first.exercises[0]!, name: "x".repeat(SpecConstants.exerciseNameMaxChars + 1) }] }] })).toBe(400);
    expect(await put({ ...base, workouts: [first, { ...base.workouts[1]!, kind: "push" }] })).toBe(400);
    expect(await put({ ...base, workouts: [] })).toBe(400);
    expect(await put({ ...base, trainingWeekdays: [] })).toBe(400);
    expect(await put({ ...base, trainingWeekdays: [8] })).toBe(400);
    expect(await put({ ...base, trainingWeekdays: [1, 1] })).toBe(400);
    expect(await put({ ...base, trainingWeekdays: [1, 2, 3, 4, 5, 6, 7, 1] })).toBe(400);
    expect(await put({ workouts: base.workouts })).toBe(400); // the pre-A1 body shape
    expect(await put(base)).toBe(200);
  });
});
