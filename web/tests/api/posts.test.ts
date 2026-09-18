// SPEC: T026 (Verify: npm test tests/api/posts) · 8.2 Posts — A22 (owner-approved 2026-09-18): the plate journal is gone; a post is
// a WORKOUT post created by the session that completes it (S10 · A21.9), so POST posts no longer exists. Delete keeps log + streak
// (E3); caption edit (G2: an optional caption ≤ captionMaxChars on a workout post); idempotency on the completion's clientId (④);
// the journal forever; another user's post is a 404.
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { DELETE as deletePost, GET as getPost, PATCH as patchPost } from "@/app/api/v1/posts/[id]/route";
import * as postsRoute from "@/app/api/v1/posts/route";
import { PATCH as patchSession } from "@/app/api/v1/sessions/[id]/route";
import { POST as createSession } from "@/app/api/v1/sessions/route";
import { closeDb, resetDbForTests } from "@/lib/db";
import { SpecConstants } from "@/generated/spec-constants";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { sampleCardioSessionBody } from "./plans-sessions";
import { postWorkout, type JournalItem } from "./workout-post";

let me: TestUser;
const TZ = "America/Los_Angeles";
const params = (id: string) => ({ params: Promise.resolve({ id }) });
const journal = async (user: TestUser) => (await readJson<{ items: JournalItem[] }>(await postsRoute.GET(request("GET", "/posts", { token: user.accessToken })))).items;

beforeAll(async () => {
  await resetDbForTests();
  me = await createUser("posts");
});
afterAll(async () => {
  await closeDb();
});

describe("posts", () => {
  it("POST posts is gone: the only way to a post is the session that completes it (A22)", () => {
    expect("POST" in postsRoute).toBe(false);
  });

  it("a completed planned workout is the day's post — server dayKey, +25 +100, streak 1 — and replaying the completion creates it once", async () => {
    const first = await postWorkout(me, { caption: "felt strong" });
    expect(first.gamification).toMatchObject({ currentStreak: 1, totalXP: SpecConstants.xpFirstPostOfDay + SpecConstants.xpPlannedWorkout }); // V25 / V67
    const items = await journal(me);
    expect(items).toHaveLength(1);
    expect(items[0]).toMatchObject({ id: first.postId, type: "workout", caption: "felt strong" });
    expect(items[0]?.dayKey).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    const again = await patchSession(request("PATCH", `/sessions/${first.sessionId}`, { token: me.accessToken, body: { timezone: TZ, status: "completed", post: { clientId: first.clientId, shareToCrew: false } } }), params(first.sessionId));
    expect(again.status).toBe(200);
    expect(await journal(me)).toHaveLength(1); // ④: the same completion twice writes one post
  });

  it("a caption over the limit is refused with the completion (400); a solo shared post stays journal-only", async () => {
    const created = await readJson<{ session: { id: string } }>(await createSession(request("POST", "/sessions", { token: me.accessToken, body: sampleCardioSessionBody({ timezone: TZ }) })));
    const tooLong = await patchSession(request("PATCH", `/sessions/${created.session.id}`, { token: me.accessToken, body: { timezone: TZ, status: "completed", post: { clientId: randomUUID(), shareToCrew: false, caption: "x".repeat(SpecConstants.captionMaxChars + 1) } } }), params(created.session.id));
    expect(tooLong.status).toBe(400);
    const shared = await postWorkout(me, { cardio: true, shareToCrew: true });
    expect((await journal(me)).find((item) => item.id === shared.postId)?.crewId).toBeNull(); // shareToCrew without a crew = the private journal (Flow 10)
  });

  it("edits the caption (G2), and deleting a post keeps the streak (E3) while removing it from the journal", async () => {
    const created = await postWorkout(me, { cardio: true, caption: "edit me" });
    const edited = await readJson<{ post: { caption: string } }>(await patchPost(request("PATCH", `/posts/${created.postId}`, { token: me.accessToken, body: { caption: "edited" } }), params(created.postId)));
    expect(edited.post.caption).toBe("edited");
    const before = await journal(me);
    expect(before.find((item) => item.id === created.postId)?.clientId).toMatch(/^[0-9a-f-]{36}$/); // a phone addresses its journal by clientId (hydration, deletePost)
    const deleted = await readJson<{ gamification: { currentStreak: number } }>(await deletePost(request("DELETE", `/posts/${created.postId}`, { token: me.accessToken }), params(created.postId)));
    expect(deleted.gamification.currentStreak).toBe(1); // the planned workout still counts today (E3)
    expect(await journal(me)).toHaveLength(before.length - 1);
    expect((await getPost(request("GET", `/posts/${created.postId}`, { token: me.accessToken }), params(created.postId))).status).toBe(404);
  });

  it("hides another user's journal post (404)", async () => {
    const other = await createUser("other-posts");
    const theirs = await postWorkout(other, { cardio: true });
    expect((await getPost(request("GET", `/posts/${theirs.postId}`, { token: me.accessToken }), params(theirs.postId))).status).toBe(404);
  });
});
