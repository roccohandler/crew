// SPEC: T030 · 8.2 Messages/Reactions as marked by A21.2 (owner-approved 2026-09-17: free-text chat is gone) — the stream is
// posts + system lines + reactions and a legacy chat row is never served; reactions once per post (a second emoji replaces),
// un-react, outsiders 403, the XP cap (V27); a block hides content both ways in the stream AND removes the blocked member from the
// pulse and the member strip for both sides (E9, W3). Successor of messages.test.ts.
import { randomUUID } from "node:crypto";
import { ObjectId } from "mongodb";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { POST as block } from "@/app/api/v1/blocks/route";
import { GET as stream } from "@/app/api/v1/crews/[id]/stream/route";
import { POST as joinCrew } from "@/app/api/v1/crews/join/route";
import { GET as myCrew, POST as createCrew } from "@/app/api/v1/crews/route";
import { DELETE as unreact, POST as react } from "@/app/api/v1/posts/[id]/reactions/route";
import { closeDb, messages, resetDbForTests } from "@/lib/db";
import { SpecConstants } from "@/generated/spec-constants";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { postWorkout } from "./workout-post";

type Feed = { items: { kind: string; userId: string; body?: string; reactions?: { emoji: string; userId: string }[] }[]; pulse: { posted: number; total: number }; members: { id: string }[] };
type Mine = { members: { id: string }[]; pulse: { posted: number; total: number } };

let captain: TestUser;
let alex: TestUser;
let outsider: TestUser;
let crewId = "";
let postId = "";
const params = (id: string) => ({ params: Promise.resolve({ id }) });

beforeAll(async () => {
  await resetDbForTests();
  captain = await createUser("captain", "UTC");
  alex = await createUser("alex", "UTC");
  outsider = await createUser("outsider", "UTC");
  const crew = await readJson<{ crew: { id: string; inviteLink: string } }>(await createCrew(request("POST", "/crews", { token: captain.accessToken, body: { name: "Dawn Patrol", emoji: "🌅" } })));
  crewId = crew.crew.id;
  await joinCrew(request("POST", "/crews/join", { token: alex.accessToken, body: { token: crew.crew.inviteLink.split("/join/")[1] } }));
  postId = (await postWorkout(captain, { cardio: true, shareToCrew: true, caption: "eggs", timezone: "UTC" })).postId; // A22: a post is a workout post
});
afterAll(async () => {
  await closeDb();
});

describe("the stream (A21.2)", () => {
  it("carries posts and the join system line, and never a legacy chat row", async () => {
    // a row an older build wrote before A21.2 — still in the collection, never in the stream
    await (await messages()).insertOne({ _id: new ObjectId(), clientId: randomUUID(), crewId: new ObjectId(crewId), userId: new ObjectId(alex.id), kind: "message", body: "who's in at 6am", createdAt: new Date(), deletedAt: null });
    const feed = await readJson<Feed>(await stream(request("GET", `/crews/${crewId}/stream`, { token: captain.accessToken }), params(crewId)));
    expect(feed.items.some((item) => item.kind === "system" && item.body === "alex joined the crew")).toBe(true);
    expect(feed.items.some((item) => item.kind === "post")).toBe(true);
    expect(feed.items.some((item) => item.kind === "message")).toBe(false);
    expect(feed.items.every((item) => item.kind === "post" || item.kind === "system")).toBe(true);
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
    const feed = await readJson<Feed>(await stream(request("GET", `/crews/${crewId}/stream`, { token: captain.accessToken }), params(crewId)));
    expect(feed.items.find((item) => item.kind === "post")?.reactions).toEqual([{ emoji: "💪", userId: alex.id }]);
    expect((await unreact(request("DELETE", `/posts/${postId}/reactions`, { token: alex.accessToken }), params(postId))).status).toBe(200);
    expect((await unreact(request("DELETE", `/posts/${postId}/reactions`, { token: alex.accessToken }), params(postId))).status).toBe(404);
  });

  // SPEC: E9 · W3 — a block is silent and total: the other person leaves the stream, the pulse's numerator and denominator, and the strip
  it("a block hides content both ways — in the stream, the pulse and the member strip", async () => {
    const before = await readJson<Feed>(await stream(request("GET", `/crews/${crewId}/stream`, { token: captain.accessToken }), params(crewId)));
    expect(before.pulse).toEqual({ posted: 1, total: 2 });
    expect(before.members.map((member) => member.id).sort()).toEqual([alex.id, captain.id].sort());
    expect((await block(request("POST", "/blocks", { token: captain.accessToken, body: { userId: alex.id } }))).status).toBe(201);
    const captainsFeed = await readJson<Feed>(await stream(request("GET", `/crews/${crewId}/stream`, { token: captain.accessToken }), params(crewId)));
    expect(captainsFeed.items.some((item) => item.userId === alex.id)).toBe(false);
    expect(captainsFeed.members.map((member) => member.id)).toEqual([captain.id]);
    expect(captainsFeed.pulse).toEqual({ posted: 1, total: 1 });
    const alexFeed = await readJson<Feed>(await stream(request("GET", `/crews/${crewId}/stream`, { token: alex.accessToken }), params(crewId)));
    expect(alexFeed.items.some((item) => item.userId === captain.id)).toBe(false);
    expect(alexFeed.members.map((member) => member.id)).toEqual([alex.id]);
    expect(alexFeed.pulse).toEqual({ posted: 0, total: 1 });
    const mine = await readJson<Mine>(await myCrew(request("GET", "/crews", { token: captain.accessToken })));
    expect(mine.members.map((member) => member.id)).toEqual([captain.id]);
    expect(mine.pulse).toEqual({ posted: 1, total: 1 });
  });
});
