// SPEC: T023 (Verify: npm test tests/api/plans) · 8.2 Plans: one-per-user invariant; PUT replace forward-only; limits
// rejected server-side; mobility holds persist.
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { GET as getPlan, PUT as putPlan } from "@/app/api/v1/plans/route";
import { closeDb, plans, resetDbForTests } from "@/lib/db";
import { SpecConstants } from "@/generated/spec-constants";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { samplePlanBody } from "./plans-sessions";

let me: TestUser;

beforeAll(async () => {
  await resetDbForTests();
  me = await createUser("plans");
});
afterAll(async () => {
  await closeDb();
});

describe("plans", () => {
  it("404s before a plan exists, then PUT creates and GET returns it with mobility holds", async () => {
    expect((await getPlan(request("GET", "/plans", { token: me.accessToken }))).status).toBe(404);
    const saved = await putPlan(request("PUT", "/plans", { token: me.accessToken, body: samplePlanBody() }));
    expect(saved.status).toBe(200);
    const fetched = await readJson<{ workouts: { weekday: number; exercises: { type: string; holdSeconds?: number }[] }[] }>(await getPlan(request("GET", "/plans", { token: me.accessToken })));
    expect(fetched.workouts.map((workout) => workout.weekday)).toEqual([1, 3, 5]);
    expect(fetched.workouts[0]!.exercises.some((row) => row.type === "mobility" && (row.holdSeconds ?? 0) > 0)).toBe(true);
  });

  it("PUT replaces the whole plan (one document per user) and the invariant holds in the database", async () => {
    await putPlan(request("PUT", "/plans", { token: me.accessToken, body: samplePlanBody([2, 4]) }));
    const fetched = await readJson<{ workouts: { weekday: number; kind: string }[] }>(await getPlan(request("GET", "/plans", { token: me.accessToken })));
    expect(fetched.workouts.map((workout) => workout.weekday)).toEqual([2, 4]);
    expect(fetched.workouts.map((workout) => workout.kind)).toEqual(["fullBodyA", "fullBodyB"]);
    expect(await (await plans()).countDocuments({})).toBe(1);
  });

  it("rejects limits server-side: too many exercises, too many sets, a long name, a duplicate weekday", async () => {
    const base = samplePlanBody();
    const tooMany = { workouts: [{ ...base.workouts[0]!, exercises: Array.from({ length: SpecConstants.planMaxExercisesPerDay + 1 }, (_, index) => ({ ...base.workouts[0]!.exercises[0]!, order: index })) }] };
    expect((await putPlan(request("PUT", "/plans", { token: me.accessToken, body: tooMany }))).status).toBe(400);
    const tooManySets = { workouts: [{ ...base.workouts[0]!, exercises: [{ ...base.workouts[0]!.exercises[0]!, targetSets: SpecConstants.planMaxSetsPerExercise + 1 }] }] };
    expect((await putPlan(request("PUT", "/plans", { token: me.accessToken, body: tooManySets }))).status).toBe(400);
    const longName = { workouts: [{ ...base.workouts[0]!, exercises: [{ ...base.workouts[0]!.exercises[0]!, name: "x".repeat(SpecConstants.exerciseNameMaxChars + 1) }] }] };
    expect((await putPlan(request("PUT", "/plans", { token: me.accessToken, body: longName }))).status).toBe(400);
    const duplicate = { workouts: [base.workouts[0]!, { ...base.workouts[1]!, weekday: 1 }] };
    expect((await putPlan(request("PUT", "/plans", { token: me.accessToken, body: duplicate }))).status).toBe(400);
  });
});
