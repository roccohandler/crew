// SPEC: T023 (Verify: npm test tests/api/sessions) · 8.2 Sessions/Sets: client-UUID idempotency; snapshot immunity to later
// plan edits; warm-up exclusion; duration holds; partial completion (V32) · S10 (numbers match the engine) · post ≠ log ·
// A1 (workoutKind stored) · A2 (distanceMeters kept; a standalone cardio log completes on its one done set — V51 — and earns
// the bonus +25 through the existing engine, V30/V31) · A6 (the post's summary line).
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { ObjectId } from "mongodb";
import { PUT as putPlan } from "@/app/api/v1/plans/route";
import { GET as getSession, PATCH as patchSession } from "@/app/api/v1/sessions/[id]/route";
import { GET as listSessions, POST as createSession } from "@/app/api/v1/sessions/route";
import { closeDb, posts, resetDbForTests, users } from "@/lib/db";
import { TimeUnits } from "@/lib/time-units";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { doneSets, sampleCardioSessionBody, samplePlanBody, sampleSessionBody } from "./plans-sessions";

let me: TestUser;
interface SessionReply { session: { id: string; status: string; setsDone: number; setsPlanned: number; setsAsPlanned: number; dayKey: string; workoutName: string; workoutKind: string | null; exercises: { sets: { distanceMeters: number | null }[] }[] }; gamification?: { currentStreak: number; totalXP: number } }

beforeAll(async () => {
  await resetDbForTests();
  me = await createUser("sessions");
  await putPlan(request("PUT", "/plans", { token: me.accessToken, body: samplePlanBody() }));
});
afterAll(async () => {
  await closeDb();
});

const params = (id: string) => ({ params: Promise.resolve({ id }) });
const complete = (id: string, body: object) => patchSession(request("PATCH", `/sessions/${id}`, { token: me.accessToken, body }), params(id));
const summaryOf = async (sessionId: string) => (await (await posts()).findOne({ sessionId: new ObjectId(sessionId) }))?.summary;

describe("sessions", () => {
  it("creates once per clientId (idempotent), stores the snapshot's kind, and reads it back with warm-ups excluded from x/y", async () => {
    const body = sampleSessionBody();
    const first = await createSession(request("POST", "/sessions", { token: me.accessToken, body }));
    expect(first.status).toBe(201);
    const second = await createSession(request("POST", "/sessions", { token: me.accessToken, body }));
    expect(second.status).toBe(200);
    const created = await readJson<SessionReply>(first);
    expect((await readJson<SessionReply>(second)).session.id).toBe(created.session.id);
    expect(created.session.setsPlanned).toBe(4); // 3 work sets + 1 mobility hold; the warm-up is excluded (Flow 2: "18/18 sets" counts holds)
    expect(created.session.workoutKind).toBe("push");
    const fetched = await readJson<SessionReply>(await getSession(request("GET", `/sessions/${created.session.id}`, { token: me.accessToken }), params(created.session.id)));
    expect(fetched.session.workoutName).toBe("Push day");
    const older = sampleSessionBody(); // a pre-A1 client: weekday instead of kind
    const legacy = await readJson<SessionReply>(await createSession(request("POST", "/sessions", { token: me.accessToken, body: { ...older, workoutSnapshot: { ...older.workoutSnapshot, kind: undefined, weekday: 1 } } })));
    expect(legacy.session.workoutKind).toBeNull();
  });

  it("completes on ≥1 work set (partial counts), creates the workout post with its summary line, recomputes +125, and is immune to plan edits", async () => {
    const body = sampleSessionBody({ startedAt: new Date(Date.now() - 44 * TimeUnits.msPerMinute).toISOString() });
    const created = await readJson<SessionReply>(await createSession(request("POST", "/sessions", { token: me.accessToken, body })));
    const notYet = await complete(created.session.id, { timezone: body.timezone, status: "completed", exercises: doneSets(body, 0) });
    expect((await readJson<SessionReply>(notYet)).session.status).toBe("inProgress");
    const done = await complete(created.session.id, { timezone: body.timezone, status: "completed", exercises: doneSets(body, 1), post: { clientId: "3f6c2e2a-8f9b-4c1e-9d10-000000000001", shareToCrew: false } });
    const reply = await readJson<SessionReply>(done);
    expect(reply.session.status).toBe("completed");
    expect(reply.session.setsDone).toBe(1);
    expect(reply.gamification).toMatchObject({ currentStreak: 1, totalXP: 125 }); // V25 day-one total
    expect(await (await posts()).countDocuments({ sessionId: { $ne: null } })).toBe(1);
    expect(await summaryOf(created.session.id)).toBe("Push day · 1/4 sets · 44 min"); // A6
    await putPlan(request("PUT", "/plans", { token: me.accessToken, body: samplePlanBody([2, 4]) })); // later plan edit
    const after = await readJson<SessionReply>(await getSession(request("GET", `/sessions/${created.session.id}`, { token: me.accessToken }), params(created.session.id)));
    expect(after.session.workoutName).toBe("Push day");
    expect(after.session.setsPlanned).toBe(4);
  });

  it("a standalone cardio log keeps its distance, completes on its one done set (V51), reads as 'Walk · 25 min · 2.1 km', and earns the bonus +25 (V30/V31)", async () => {
    await (await users()).updateOne({ _id: new ObjectId(me.id) }, { $set: { units: "kg" } });
    const walk = sampleCardioSessionBody({ minutes: 25, distanceMeters: 2100 });
    const created = await readJson<SessionReply>(await createSession(request("POST", "/sessions", { token: me.accessToken, body: walk })));
    expect(created.session.workoutKind).toBe("cardio");
    expect(created.session.exercises[0]!.sets[0]!.distanceMeters).toBe(2100);
    const reply = await readJson<SessionReply>(await complete(created.session.id, { timezone: walk.timezone, status: "completed", post: { clientId: "3f6c2e2a-8f9b-4c1e-9d10-000000000002", shareToCrew: false } }));
    expect(reply.session).toMatchObject({ status: "completed", setsDone: 1, setsPlanned: 1, setsAsPlanned: 1 });
    expect(reply.gamification).toMatchObject({ currentStreak: 1, totalXP: 150 }); // second workout of the day, unplanned → +25, nothing else (V31)
    expect(await summaryOf(created.session.id)).toBe("Walk · 25 min · 2.1 km");
    const bike = sampleCardioSessionBody({ activity: "Bike", minutes: 30, distanceMeters: null });
    const ride = await readJson<SessionReply>(await createSession(request("POST", "/sessions", { token: me.accessToken, body: bike })));
    const rode = await readJson<SessionReply>(await complete(ride.session.id, { timezone: bike.timezone, status: "completed", post: { clientId: "3f6c2e2a-8f9b-4c1e-9d10-000000000003", shareToCrew: false } }));
    expect(rode.gamification?.totalXP).toBe(175);
    expect(await summaryOf(ride.session.id)).toBe("Bike · 30 min"); // no distance → nothing, never "no distance recorded"
  });

  it("lists by dayKey range and hides other users' sessions (404)", async () => {
    const other = await createUser("other-sessions");
    const theirs = await readJson<SessionReply>(await createSession(request("POST", "/sessions", { token: other.accessToken, body: sampleSessionBody() })));
    expect((await getSession(request("GET", `/sessions/${theirs.session.id}`, { token: me.accessToken }), params(theirs.session.id))).status).toBe(404);
    const mine = await readJson<{ items: unknown[] }>(await listSessions(request("GET", "/sessions?from=2000-01-01&to=2100-01-01", { token: me.accessToken })));
    expect(mine.items.length).toBe(5);
  });
});
