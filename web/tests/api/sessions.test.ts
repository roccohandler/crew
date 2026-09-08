// SPEC: T023 (Verify: npm test tests/api/sessions) · 8.2 Sessions/Sets: client-UUID idempotency; snapshot immunity to later
// plan edits; warm-up exclusion; duration holds; partial completion (V32) · S10 (numbers match the engine) · post ≠ log.
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { PUT as putPlan } from "@/app/api/v1/plans/route";
import { GET as getSession, PATCH as patchSession } from "@/app/api/v1/sessions/[id]/route";
import { GET as listSessions, POST as createSession } from "@/app/api/v1/sessions/route";
import { closeDb, posts, resetDbForTests } from "@/lib/db";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { doneSets, samplePlanBody, sampleSessionBody } from "./plans-sessions";

let me: TestUser;
interface SessionReply { session: { id: string; status: string; setsDone: number; setsPlanned: number; setsAsPlanned: number; dayKey: string; workoutName: string }; gamification?: { currentStreak: number; totalXP: number } }

beforeAll(async () => {
  await resetDbForTests();
  me = await createUser("sessions");
  await putPlan(request("PUT", "/plans", { token: me.accessToken, body: samplePlanBody() }));
});
afterAll(async () => {
  await closeDb();
});

const params = (id: string) => ({ params: Promise.resolve({ id }) });

describe("sessions", () => {
  it("creates once per clientId (idempotent) and reads it back with warm-ups excluded from x/y", async () => {
    const body = sampleSessionBody();
    const first = await createSession(request("POST", "/sessions", { token: me.accessToken, body }));
    expect(first.status).toBe(201);
    const second = await createSession(request("POST", "/sessions", { token: me.accessToken, body }));
    expect(second.status).toBe(200);
    const created = await readJson<SessionReply>(first);
    expect((await readJson<SessionReply>(second)).session.id).toBe(created.session.id);
    expect(created.session.setsPlanned).toBe(4); // 3 work sets + 1 mobility hold; the warm-up is excluded (Flow 2: "18/18 sets" counts holds)
    const fetched = await readJson<SessionReply>(await getSession(request("GET", `/sessions/${created.session.id}`, { token: me.accessToken }), params(created.session.id)));
    expect(fetched.session.workoutName).toBe("Push day");
  });

  it("completes on ≥1 work set (partial counts), creates the workout post, recomputes +125, and is immune to plan edits", async () => {
    const body = sampleSessionBody();
    const created = await readJson<SessionReply>(await createSession(request("POST", "/sessions", { token: me.accessToken, body })));
    const notYet = await patchSession(request("PATCH", `/sessions/${created.session.id}`, { token: me.accessToken, body: { timezone: body.timezone, status: "completed", exercises: doneSets(body, 0) } }), params(created.session.id));
    expect((await readJson<SessionReply>(notYet)).session.status).toBe("inProgress");
    const done = await patchSession(request("PATCH", `/sessions/${created.session.id}`, { token: me.accessToken, body: { timezone: body.timezone, status: "completed", exercises: doneSets(body, 1), post: { clientId: "3f6c2e2a-8f9b-4c1e-9d10-000000000001", shareToCrew: false } } }), params(created.session.id));
    const reply = await readJson<SessionReply>(done);
    expect(reply.session.status).toBe("completed");
    expect(reply.session.setsDone).toBe(1);
    expect(reply.gamification).toMatchObject({ currentStreak: 1, totalXP: 125 }); // V25 day-one total
    expect(await (await posts()).countDocuments({ sessionId: { $ne: null } })).toBe(1);
    await putPlan(request("PUT", "/plans", { token: me.accessToken, body: samplePlanBody([2, 4]) })); // later plan edit
    const after = await readJson<SessionReply>(await getSession(request("GET", `/sessions/${created.session.id}`, { token: me.accessToken }), params(created.session.id)));
    expect(after.session.workoutName).toBe("Push day");
    expect(after.session.setsPlanned).toBe(4);
  });

  it("lists by dayKey range and hides other users' sessions (404)", async () => {
    const other = await createUser("other-sessions");
    const theirs = await readJson<SessionReply>(await createSession(request("POST", "/sessions", { token: other.accessToken, body: sampleSessionBody() })));
    expect((await getSession(request("GET", `/sessions/${theirs.session.id}`, { token: me.accessToken }), params(theirs.session.id))).status).toBe(404);
    const mine = await readJson<{ items: unknown[] }>(await listSessions(request("GET", "/sessions?from=2000-01-01&to=2100-01-01", { token: me.accessToken })));
    expect(mine.items.length).toBe(2);
  });
});
