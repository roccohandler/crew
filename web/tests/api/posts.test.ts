// SPEC: T026 (Verify: npm test tests/api/posts) · 8.2 Posts: fitness/meal/text-only creation; delete keeps log + streak (E3);
// caption edit; 3-meal XP cap server-enforced (V26); idempotency (④); journal forever.
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { DELETE as deletePost, GET as getPost, PATCH as patchPost } from "@/app/api/v1/posts/[id]/route";
import { GET as listPosts, POST as createPost } from "@/app/api/v1/posts/route";
import { closeDb, resetDbForTests } from "@/lib/db";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";

let me: TestUser;
interface PostReply { post: { id: string; type: string; dayKey: string; caption: string; crewId: string | null }; gamification: { currentStreak: number; totalXP: number } }
const params = (id: string) => ({ params: Promise.resolve({ id }) });
const meal = (caption: string) => ({ clientId: randomUUID(), type: "meal", caption, shareToCrew: true, timezone: "America/Los_Angeles", isPlannedDay: false });

beforeAll(async () => {
  await resetDbForTests();
  me = await createUser("posts");
});
afterAll(async () => {
  await closeDb();
});

describe("posts", () => {
  it("creates a text post with the server dayKey, counts the day (+25), and is idempotent on clientId", async () => {
    const body = { clientId: randomUUID(), type: "text", caption: "protein shake post-gym", shareToCrew: false, timezone: "America/Los_Angeles", isPlannedDay: false };
    const first = await createPost(request("POST", "/posts", { token: me.accessToken, body }));
    expect(first.status).toBe(201);
    const reply = await readJson<PostReply>(first);
    expect(reply.post.dayKey).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    expect(reply.gamification).toMatchObject({ currentStreak: 1, totalXP: 25 });
    const again = await createPost(request("POST", "/posts", { token: me.accessToken, body }));
    expect(again.status).toBe(200);
    expect((await readJson<PostReply>(again)).post.id).toBe(reply.post.id);
  });

  it("enforces the 3-meal XP cap server-side (V26) and a solo post stays journal-only", async () => {
    let last: PostReply | null = null;
    for (const caption of ["eggs", "salad", "rice", "late snack"]) last = await readJson<PostReply>(await createPost(request("POST", "/posts", { token: me.accessToken, body: meal(caption) })));
    expect(last?.gamification.totalXP).toBe(25 + 15 * 3); // first-post XP already counted by the text post; four meals earn 15 × 3
    expect(last?.post.crewId).toBeNull(); // shareToCrew without a crew = the private journal (Flow 10)
  });

  it("rejects a meal with neither photo nor text, and a caption over the limit", async () => {
    expect((await createPost(request("POST", "/posts", { token: me.accessToken, body: { ...meal(""), caption: "" } }))).status).toBe(400);
    expect((await createPost(request("POST", "/posts", { token: me.accessToken, body: meal("x".repeat(281)) }))).status).toBe(400);
  });

  it("edits the caption, and deleting a post keeps the streak (E3) while removing it from the journal", async () => {
    const created = await readJson<PostReply>(await createPost(request("POST", "/posts", { token: me.accessToken, body: meal("edit me") })));
    const edited = await readJson<PostReply>(await patchPost(request("PATCH", `/posts/${created.post.id}`, { token: me.accessToken, body: { caption: "edited" } }), params(created.post.id)));
    expect(edited.post.caption).toBe("edited");
    const before = await readJson<{ items: { id: string; clientId: string }[] }>(await listPosts(request("GET", "/posts", { token: me.accessToken })));
    expect(before.items.find((item) => item.id === created.post.id)?.clientId).toMatch(/^[0-9a-f-]{36}$/); // a phone addresses its journal by clientId (hydration, deletePost)
    const deleted = await readJson<{ gamification: { currentStreak: number } }>(await deletePost(request("DELETE", `/posts/${created.post.id}`, { token: me.accessToken }), params(created.post.id)));
    expect(deleted.gamification.currentStreak).toBe(1); // other posts today still count the day
    const after = await readJson<{ items: unknown[] }>(await listPosts(request("GET", "/posts", { token: me.accessToken })));
    expect(after.items.length).toBe(before.items.length - 1);
    expect((await getPost(request("GET", `/posts/${created.post.id}`, { token: me.accessToken }), params(created.post.id))).status).toBe(404);
  });

  it("hides another user's journal post (404)", async () => {
    const other = await createUser("other-posts");
    const theirs = await readJson<PostReply>(await createPost(request("POST", "/posts", { token: other.accessToken, body: meal("theirs") })));
    expect((await getPost(request("GET", `/posts/${theirs.post.id}`, { token: me.accessToken }), params(theirs.post.id))).status).toBe(404);
  });
});
