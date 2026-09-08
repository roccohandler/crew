// SPEC: T030 (Verify: messages suite) · 8.2 Messages/Reactions: 1,000-char limit; own-delete tombstone; Captain delete; un-react;
// reaction XP cap (V27); blocked-user filtering both directions (E9).
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { POST as block } from "@/app/api/v1/blocks/route";
import { DELETE as deleteMessage } from "@/app/api/v1/crews/[id]/messages/[messageId]/route";
import { POST as sendMessage } from "@/app/api/v1/crews/[id]/messages/route";
import { GET as stream } from "@/app/api/v1/crews/[id]/stream/route";
import { POST as joinCrew } from "@/app/api/v1/crews/join/route";
import { POST as createCrew } from "@/app/api/v1/crews/route";
import { DELETE as unreact, POST as react } from "@/app/api/v1/posts/[id]/reactions/route";
import { POST as createPost } from "@/app/api/v1/posts/route";
import { closeDb, resetDbForTests } from "@/lib/db";
import { SpecConstants } from "@/generated/spec-constants";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";

let captain: TestUser;
let alex: TestUser;
let outsider: TestUser;
let crewId = "";
let postId = "";
const params = (id: string) => ({ params: Promise.resolve({ id }) });
const messageParams = (id: string, messageId: string) => ({ params: Promise.resolve({ id, messageId }) });

beforeAll(async () => {
  await resetDbForTests();
  captain = await createUser("captain", "UTC");
  alex = await createUser("alex", "UTC");
  outsider = await createUser("outsider", "UTC");
  const crew = await readJson<{ crew: { id: string; inviteLink: string } }>(await createCrew(request("POST", "/crews", { token: captain.accessToken, body: { name: "Dawn Patrol", emoji: "🌅" } })));
  crewId = crew.crew.id;
  await joinCrew(request("POST", "/crews/join", { token: alex.accessToken, body: { token: crew.crew.inviteLink.split("/join/")[1] } }));
  const post = await readJson<{ post: { id: string } }>(await createPost(request("POST", "/posts", { token: captain.accessToken, body: { clientId: randomUUID(), type: "meal", caption: "eggs", shareToCrew: true, timezone: "UTC", isPlannedDay: false } })));
  postId = post.post.id;
});
afterAll(async () => {
  await closeDb();
});

describe("messages", () => {
  it("sends into the stream (idempotent), enforces the 1,000-char limit, tombstones own messages, and lets the Captain delete", async () => {
    const body = { clientId: randomUUID(), body: "ok ok I'm going" };
    const first = await sendMessage(request("POST", `/crews/${crewId}/messages`, { token: alex.accessToken, body }), params(crewId));
    expect(first.status).toBe(201);
    const message = await readJson<{ message: { id: string } }>(first);
    expect((await sendMessage(request("POST", `/crews/${crewId}/messages`, { token: alex.accessToken, body }), params(crewId))).status).toBe(200);
    expect((await sendMessage(request("POST", `/crews/${crewId}/messages`, { token: alex.accessToken, body: { clientId: randomUUID(), body: "x".repeat(SpecConstants.chatMessageMaxChars + 1) } }), params(crewId))).status).toBe(400);
    expect((await sendMessage(request("POST", `/crews/${crewId}/messages`, { token: outsider.accessToken, body }), params(crewId))).status).toBe(404);
    expect((await deleteMessage(request("DELETE", `/crews/${crewId}/messages/${message.message.id}`, { token: alex.accessToken }), messageParams(crewId, message.message.id))).status).toBe(200);
    const feed = await readJson<{ items: { kind: string; deleted?: boolean; body?: string }[] }>(await stream(request("GET", `/crews/${crewId}/stream`, { token: captain.accessToken }), params(crewId)));
    expect(feed.items.find((item) => item.kind === "message")).toMatchObject({ deleted: true, body: "" });
    const second = await readJson<{ message: { id: string } }>(await sendMessage(request("POST", `/crews/${crewId}/messages`, { token: alex.accessToken, body: { clientId: randomUUID(), body: "again" } }), params(crewId)));
    expect((await deleteMessage(request("DELETE", `/crews/${crewId}/messages/${second.message.id}`, { token: captain.accessToken }), messageParams(crewId, second.message.id))).status).toBe(200);
  });
});

describe("reactions", () => {
  it("crew-mates react once per post (a second emoji replaces), un-react, outsiders cannot, and the XP cap holds", async () => {
    expect((await react(request("POST", `/posts/${postId}/reactions`, { token: outsider.accessToken, body: { emoji: "🔥" } }), params(postId))).status).toBe(403);
    expect((await react(request("POST", `/posts/${postId}/reactions`, { token: alex.accessToken, body: { emoji: "🙃" } }), params(postId))).status).toBe(400);
    const first = await readJson<{ gamification: { totalXP: number } }>(await react(request("POST", `/posts/${postId}/reactions`, { token: alex.accessToken, body: { emoji: "🔥" } }), params(postId)));
    expect(first.gamification.totalXP).toBe(SpecConstants.xpReaction);
    const replaced = await readJson<{ gamification: { totalXP: number } }>(await react(request("POST", `/posts/${postId}/reactions`, { token: alex.accessToken, body: { emoji: "💪" } }), params(postId)));
    expect(replaced.gamification.totalXP).toBe(SpecConstants.xpReaction); // one reaction per target, replaced not added
    const feed = await readJson<{ items: { kind: string; reactions?: { emoji: string }[] }[] }>(await stream(request("GET", `/crews/${crewId}/stream`, { token: captain.accessToken }), params(crewId)));
    expect(feed.items.find((item) => item.kind === "post")?.reactions).toEqual([{ emoji: "💪", userId: alex.id }]);
    expect((await unreact(request("DELETE", `/posts/${postId}/reactions`, { token: alex.accessToken }), params(postId))).status).toBe(200);
    expect((await unreact(request("DELETE", `/posts/${postId}/reactions`, { token: alex.accessToken }), params(postId))).status).toBe(404);
  });

  it("a block hides content both ways in the stream", async () => {
    await sendMessage(request("POST", `/crews/${crewId}/messages`, { token: alex.accessToken, body: { clientId: randomUUID(), body: "visible before the block" } }), params(crewId));
    expect((await block(request("POST", "/blocks", { token: captain.accessToken, body: { userId: alex.id } }))).status).toBe(201);
    const captainsFeed = await readJson<{ items: { userId: string }[] }>(await stream(request("GET", `/crews/${crewId}/stream`, { token: captain.accessToken }), params(crewId)));
    expect(captainsFeed.items.some((item) => item.userId === alex.id)).toBe(false);
    const alexFeed = await readJson<{ items: { userId: string }[] }>(await stream(request("GET", `/crews/${crewId}/stream`, { token: alex.accessToken }), params(crewId)));
    expect(alexFeed.items.some((item) => item.userId === captain.id)).toBe(false);
  });
});
