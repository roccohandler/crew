// SPEC: A21.9 / W4 (owner-approved 2026-09-17) — "no post exists until a celebration button is tapped": a completion sent
// WITHOUT `post` records the workout and creates no post and no XP; the tapped button's `post` on the already-completed session
// creates the post once with the visibility it names; a second `post` changes nothing (the choice is made once). S10 · V25 · V32.
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { ObjectId } from "mongodb";
import { POST as createCrew } from "@/app/api/v1/crews/route";
import { PUT as putPlan } from "@/app/api/v1/plans/route";
import { PATCH as patchSession } from "@/app/api/v1/sessions/[id]/route";
import { POST as createSession } from "@/app/api/v1/sessions/route";
import { closeDb, posts, resetDbForTests } from "@/lib/db";
import { SpecConstants } from "@/generated/spec-constants";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { doneSets, samplePlanBody, sampleSessionBody } from "./plans-sessions";

let me: TestUser;
interface SessionReply { session: { id: string; status: string; setsDone: number }; gamification?: { currentStreak: number; totalXP: number } }

beforeAll(async () => {
  await resetDbForTests();
  me = await createUser("late-post");
  await putPlan(request("PUT", "/plans", { token: me.accessToken, body: samplePlanBody() }));
  await createCrew(request("POST", "/crews", { token: me.accessToken, body: { name: "Late Post", emoji: "🌙" } })); // shareToCrew has a crew to name
});
afterAll(async () => {
  await closeDb();
});

const params = (id: string) => ({ params: Promise.resolve({ id }) });
const patch = (id: string, body: object) => patchSession(request("PATCH", `/sessions/${id}`, { token: me.accessToken, body }), params(id));

describe("A21.9 — the post follows the tap, never the completion", () => {
  it("completes without a post, then creates the post once from the tapped button's visibility", async () => {
    const body = sampleSessionBody();
    const created = await readJson<SessionReply>(await createSession(request("POST", "/sessions", { token: me.accessToken, body })));
    const sessionId = new ObjectId(created.session.id);

    // Complete workout: the session is completed, and there is NO post and NO XP yet (A21.9)
    const completed = await readJson<SessionReply>(await patch(created.session.id, { timezone: body.timezone, status: "completed", exercises: doneSets(body, 1) }));
    expect(completed.session.status).toBe("completed");
    expect(completed.session.setsDone).toBe(1);
    expect(await (await posts()).countDocuments({ sessionId })).toBe(0);
    expect(completed.gamification?.totalXP ?? 0).toBe(0);

    // "Share to crew" tapped: the post is created with the tapped visibility, and the day counts (V25: 25 + 100)
    const shared = await readJson<SessionReply>(await patch(created.session.id, { timezone: body.timezone, status: "completed", post: { clientId: "3f6c2e2a-8f9b-4c1e-9d10-00000000a001", shareToCrew: true } }));
    expect(shared.session.status).toBe("completed");
    const post = await (await posts()).findOne({ sessionId });
    expect(post).not.toBeNull();
    expect(post?.crewId).not.toBeNull(); // shared: the crew it was shared to at creation (PostDoc.crewId)
    expect(post?.type).toBe("workout");
    expect(post?.summary).toMatch(/^Push day · 1\//);
    expect(shared.gamification).toMatchObject({ currentStreak: 1, totalXP: SpecConstants.xpFirstPostOfDay + SpecConstants.xpPlannedWorkout });

    // A replay, or a second tap with another id and the other visibility: nothing changes — the choice was made once
    await patch(created.session.id, { timezone: body.timezone, status: "completed", post: { clientId: "3f6c2e2a-8f9b-4c1e-9d10-00000000a002", shareToCrew: false } });
    expect(await (await posts()).countDocuments({ sessionId })).toBe(1);
    expect((await (await posts()).findOne({ sessionId }))?.crewId).not.toBeNull(); // still shared: the first answer stands
  });

  it("still refuses to complete on zero work sets, with or without a post", async () => {
    const body = sampleSessionBody();
    const created = await readJson<SessionReply>(await createSession(request("POST", "/sessions", { token: me.accessToken, body })));
    const notYet = await readJson<SessionReply>(await patch(created.session.id, { timezone: body.timezone, status: "completed", exercises: doneSets(body, 0), post: { clientId: "3f6c2e2a-8f9b-4c1e-9d10-00000000a003", shareToCrew: true } }));
    expect(notYet.session.status).toBe("inProgress");
    expect(await (await posts()).countDocuments({ sessionId: new ObjectId(created.session.id) })).toBe(0);
  });
});
