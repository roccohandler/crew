// SPEC: T023 (Verify: npm test tests/api/sync) · 8.2 Sync: offline queue replays in order; last-write-wins on plan; server
// gamification recompute overrides client divergence; device-clock skew reconciled to server time · A1 (the putPlan op carries
// trainingWeekdays + the rotation) · A22 (owner-approved 2026-09-18): a queued `createPost` from an older phone is refused PER OP
// as `postsRetired` — the plate journal is gone and a workout post rides its session's completion.
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { GET as getPlan } from "@/app/api/v1/plans/route";
import { POST as sync } from "@/app/api/v1/sync/route";
import { closeDb, posts, resetDbForTests, sessions } from "@/lib/db";
import { dayKeyFor } from "@/lib/engine/day-key";
import { SpecConstants } from "@/generated/spec-constants";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { doneSets, samplePlanBody, sampleSessionBody } from "./plans-sessions";

let me: TestUser;
interface SyncReply { results: { opId: string; ok: boolean; error?: string; retryable?: boolean }[]; gamification: { currentStreak: number; totalXP: number } }
interface PlanReply { trainingWeekdays: number[]; workouts: { kind: string }[] }
const dayOne = SpecConstants.xpFirstPostOfDay + SpecConstants.xpPlannedWorkout; // V25 / V67: the first planned workout of a day

beforeAll(async () => {
  await resetDbForTests();
  me = await createUser("sync");
});
afterAll(async () => {
  await closeDb();
});

describe("sync", () => {
  it("replays ops in order (plan → session → completion with its post) and returns the recomputed state", async () => {
    const session = sampleSessionBody();
    const ops = [
      { opId: "1", kind: "putPlan", payload: samplePlanBody([1, 3, 5]) },
      { opId: "2", kind: "createSession", payload: session },
      { opId: "3", kind: "patchSession", payload: { sessionId: session.clientId, status: "completed", exercises: doneSets(session, 1), post: { clientId: randomUUID(), shareToCrew: false } } },
    ];
    const first = await readJson<SyncReply>(await sync(request("POST", "/sync", { token: me.accessToken, body: { timezone: session.timezone, ops } })));
    expect(first.results.map((result) => result.ok)).toEqual([true, true, true]);
    expect(first.gamification).toMatchObject({ currentStreak: 1, totalXP: dayOne });
    const replay = await readJson<SyncReply>(await sync(request("POST", "/sync", { token: me.accessToken, body: { timezone: session.timezone, ops } })));
    expect(replay.results.every((result) => result.ok)).toBe(true);
    expect(replay.gamification.totalXP).toBe(dayOne); // idempotent: nothing counted twice, one post
    const plan = await readJson<PlanReply>(await getPlan(request("GET", "/plans", { token: me.accessToken })));
    expect(plan.trainingWeekdays).toEqual([1, 3, 5]);
    expect(plan.workouts.map((workout) => workout.kind)).toEqual(["push", "pull", "legs"]);
  });

  it("a retired createPost op is refused per op, non-retryably, and a malformed op fails alone — the rest of the batch lands", async () => {
    const ops = [
      { opId: "meal", kind: "createPost", payload: { clientId: randomUUID(), type: "meal", caption: "eggs", shareToCrew: false, isPlannedDay: false } },
      { opId: "bad", kind: "createSession", payload: { clientId: "not-a-uuid" } },
      { opId: "ok", kind: "createSession", payload: sampleSessionBody() },
    ];
    const reply = await readJson<SyncReply>(await sync(request("POST", "/sync", { token: me.accessToken, body: { timezone: "America/Los_Angeles", ops } })));
    expect(reply.results[0]).toMatchObject({ ok: false, error: "postsRetired", retryable: false });
    expect(reply.results[1]).toMatchObject({ ok: false, error: "validation", retryable: false });
    expect(reply.results[2]).toMatchObject({ ok: true });
    expect(await (await posts()).countDocuments({ type: { $in: ["meal", "text"] } })).toBe(0); // nothing of the plate journal is ever written again
  });

  it("a future-dated completion lands on the server's day (E15): the client clock never moves the dayKey", async () => {
    const session = sampleSessionBody({ clientId: randomUUID() });
    const farFuture = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString();
    const ops = [
      { opId: "s", kind: "createSession", payload: session },
      { opId: "c", kind: "patchSession", payload: { sessionId: session.clientId, status: "completed", completedAt: farFuture, exercises: doneSets(session, 1) } },
    ];
    const reply = await readJson<SyncReply>(await sync(request("POST", "/sync", { token: me.accessToken, body: { timezone: session.timezone, ops } })));
    expect(reply.results.every((result) => result.ok)).toBe(true);
    const stored = await (await sessions()).findOne({ clientId: session.clientId });
    expect(stored?.dayKey).toBe(dayKeyFor(new Date(), session.timezone));
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
  // (no weight, no hold, no distance) rather than sending null; the completion carries its post; a post it deletes is named by
  // clientId too
  it("replays an iPhone batch: session by clientId, absent nil fields, the completion's post, delete by clientId", async () => {
    const session = sampleSessionBody({ clientId: randomUUID() });
    const bare = session.workoutSnapshot.exercises.map((exercise) => ({ ...exercise, holdSeconds: undefined, sets: exercise.sets.map((set) => ({ targetReps: set.targetReps, actualReps: set.actualReps, isWarmup: set.isWarmup, done: set.done })) }));
    const postClientId = randomUUID();
    const ops = [
      { opId: "s1", kind: "createSession", payload: { ...session, workoutSnapshot: { ...session.workoutSnapshot, exercises: bare } } },
      { opId: "s2", kind: "patchSession", payload: { sessionId: session.clientId, status: "completed", exercises: doneSets(session, 1), post: { clientId: postClientId, shareToCrew: false } } },
      { opId: "d1", kind: "deletePost", payload: { clientId: postClientId } },
    ];
    const reply = await readJson<SyncReply>(await sync(request("POST", "/sync", { token: me.accessToken, body: { timezone: session.timezone, ops } })));
    expect(reply.results.map((result) => result.ok)).toEqual([true, true, true]);
    const stored = await (await sessions()).findOne({ clientId: session.clientId });
    expect(stored?.status).toBe("completed");
    expect(stored?.workoutKind).toBe("push");
    expect(stored?.exercises[0]?.sets[0]?.weight).toBeNull();
    expect(stored?.exercises[0]?.sets[0]?.distanceMeters).toBeNull();
    expect(stored?.exercises[0]?.holdSeconds).toBeNull();
    const post = await (await posts()).findOne({ clientId: postClientId });
    expect(post?.type).toBe("workout");
    expect(post?.deletedAt).not.toBeNull();
  });
});
