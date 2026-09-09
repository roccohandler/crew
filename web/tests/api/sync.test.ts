// SPEC: T023 (Verify: npm test tests/api/sync) · 8.2 Sync: offline queue replays in order; last-write-wins on plan; server
// gamification recompute overrides client divergence; device-clock skew reconciled to server time · A1 (the putPlan op carries
// trainingWeekdays + the rotation).
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { GET as getPlan } from "@/app/api/v1/plans/route";
import { POST as sync } from "@/app/api/v1/sync/route";
import { closeDb, posts, resetDbForTests, sessions } from "@/lib/db";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { doneSets, samplePlanBody, sampleSessionBody } from "./plans-sessions";

let me: TestUser;
interface SyncReply { results: { opId: string; ok: boolean; error?: string; retryable?: boolean }[]; gamification: { currentStreak: number; totalXP: number } }
interface PlanReply { trainingWeekdays: number[]; workouts: { kind: string }[] }

beforeAll(async () => {
  await resetDbForTests();
  me = await createUser("sync");
});
afterAll(async () => {
  await closeDb();
});

describe("sync", () => {
  it("replays ops in order (plan → session → completion → meal) and returns the recomputed state", async () => {
    const session = sampleSessionBody();
    const ops = [
      { opId: "1", kind: "putPlan", payload: samplePlanBody([1, 3, 5]) },
      { opId: "2", kind: "createSession", payload: session },
      { opId: "3", kind: "createPost", payload: { clientId: randomUUID(), type: "meal", caption: "eggs", shareToCrew: false, isPlannedDay: true } },
    ];
    const first = await readJson<SyncReply>(await sync(request("POST", "/sync", { token: me.accessToken, body: { timezone: session.timezone, ops } })));
    expect(first.results.map((result) => result.ok)).toEqual([true, true, true]);
    expect(first.gamification).toMatchObject({ currentStreak: 1, totalXP: 40 });
    const replay = await readJson<SyncReply>(await sync(request("POST", "/sync", { token: me.accessToken, body: { timezone: session.timezone, ops } })));
    expect(replay.results.every((result) => result.ok)).toBe(true);
    expect(replay.gamification.totalXP).toBe(40); // idempotent: nothing counted twice
    const plan = await readJson<PlanReply>(await getPlan(request("GET", "/plans", { token: me.accessToken })));
    expect(plan.trainingWeekdays).toEqual([1, 3, 5]);
    expect(plan.workouts.map((workout) => workout.kind)).toEqual(["push", "pull", "legs"]);
  });

  it("reports a bad op without failing the batch and keeps the server clock for a future-dated post", async () => {
    const farFuture = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString();
    const ops = [
      { opId: "bad", kind: "createPost", payload: { clientId: "not-a-uuid", type: "meal", shareToCrew: false } },
      { opId: "future", kind: "createPost", payload: { clientId: randomUUID(), type: "text", caption: "from the future", shareToCrew: false, isPlannedDay: false, createdAt: farFuture } },
    ];
    const reply = await readJson<SyncReply>(await sync(request("POST", "/sync", { token: me.accessToken, body: { timezone: "America/Los_Angeles", ops } })));
    expect(reply.results[0]).toMatchObject({ ok: false, error: "validation", retryable: false });
    expect(reply.results[1]).toMatchObject({ ok: true });
    const post = await (await posts()).findOne({ caption: "from the future" });
    expect(post?.createdAt.getTime()).toBeLessThanOrEqual(Date.now());
  });

  it("last write wins on the plan across two syncs; a pre-A1 putPlan body is a per-op validation error, not a failed batch", async () => {
    await sync(request("POST", "/sync", { token: me.accessToken, body: { timezone: "UTC", ops: [{ opId: "p1", kind: "putPlan", payload: samplePlanBody([2, 4, 6]) }] } }));
    await sync(request("POST", "/sync", { token: me.accessToken, body: { timezone: "UTC", ops: [{ opId: "p2", kind: "putPlan", payload: samplePlanBody([7]) }] } }));
    const plan = await readJson<PlanReply>(await getPlan(request("GET", "/plans", { token: me.accessToken })));
    expect(plan.trainingWeekdays).toEqual([7]);
    const stale = await readJson<SyncReply>(await sync(request("POST", "/sync", { token: me.accessToken, body: { timezone: "UTC", ops: [{ opId: "p3", kind: "putPlan", payload: { workouts: samplePlanBody([1]).workouts } }] } })));
    expect(stale.results[0]).toMatchObject({ ok: false, error: "validation", retryable: false });
    expect((await readJson<PlanReply>(await getPlan(request("GET", "/plans", { token: me.accessToken })))).trainingWeekdays).toEqual([7]);
  });

  // The phone's contract (5.6.3): a session it created offline is addressed by clientId; Swift's Codable omits nil optionals
  // (no weight, no hold, no distance) rather than sending null; a post it deletes is named by clientId too
  it("replays an iPhone batch: session by clientId, absent nil fields, delete by clientId", async () => {
    const session = sampleSessionBody({ clientId: randomUUID() });
    const bare = session.workoutSnapshot.exercises.map((exercise) => ({ ...exercise, holdSeconds: undefined, sets: exercise.sets.map((set) => ({ targetReps: set.targetReps, actualReps: set.actualReps, isWarmup: set.isWarmup, done: set.done })) }));
    const mealClientId = randomUUID();
    const ops = [
      { opId: "s1", kind: "createSession", payload: { ...session, workoutSnapshot: { ...session.workoutSnapshot, exercises: bare } } },
      { opId: "s2", kind: "patchSession", payload: { sessionId: session.clientId, status: "completed", exercises: doneSets(session, 1) } },
      { opId: "m1", kind: "createPost", payload: { clientId: mealClientId, type: "meal", caption: "gone soon", shareToCrew: false, isPlannedDay: false } },
      { opId: "m2", kind: "deletePost", payload: { clientId: mealClientId } },
    ];
    const reply = await readJson<SyncReply>(await sync(request("POST", "/sync", { token: me.accessToken, body: { timezone: session.timezone, ops } })));
    expect(reply.results.map((result) => result.ok)).toEqual([true, true, true, true]);
    const stored = await (await sessions()).findOne({ clientId: session.clientId });
    expect(stored?.status).toBe("completed");
    expect(stored?.workoutKind).toBe("push");
    expect(stored?.exercises[0]?.sets[0]?.weight).toBeNull();
    expect(stored?.exercises[0]?.sets[0]?.distanceMeters).toBeNull();
    expect(stored?.exercises[0]?.holdSeconds).toBeNull();
    const meal = await (await posts()).findOne({ clientId: mealClientId });
    expect(meal?.deletedAt).not.toBeNull();
  });
});
