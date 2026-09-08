// SPEC: T029 (Verify: crews suite) · 8.2 Crews: create; join via link; full-crew rejection; regenerated link kills old; leave keeps
// past posts; Captain removes member; captaincy auto-pass; last-out archive; 1-crew invariant · V37 pulse · E2 join-forward.
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { PATCH as renameCrew } from "@/app/api/v1/crews/[id]/route";
import { POST as regenerateInvite } from "@/app/api/v1/crews/[id]/invite/route";
import { DELETE as leaveOrRemove, GET as listMembers } from "@/app/api/v1/crews/[id]/members/route";
import { GET as stream } from "@/app/api/v1/crews/[id]/stream/route";
import { GET as previewInvite, POST as joinCrew } from "@/app/api/v1/crews/join/route";
import { PATCH as muteCrew } from "@/app/api/v1/crews/[id]/mute/route";
import { GET as myCrew, POST as createCrew } from "@/app/api/v1/crews/route";
import { POST as createPost } from "@/app/api/v1/posts/route";
import { GET as getMe } from "@/app/api/v1/users/me/route";
import { closeDb, crews, resetDbForTests } from "@/lib/db";
import { SpecConstants } from "@/generated/spec-constants";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";

let captain: TestUser;
let alex: TestUser;
let sam: TestUser;
let crewId = "";
let inviteLink = "";
const params = (id: string) => ({ params: Promise.resolve({ id }) });
const tokenOf = (link: string) => link.split("/join/")[1]!;

beforeAll(async () => {
  await resetDbForTests();
  captain = await createUser("captain", "UTC");
  alex = await createUser("alex", "UTC");
  sam = await createUser("sam", "UTC");
});
afterAll(async () => {
  await closeDb();
});

describe("crews", () => {
  it("creates a crew (caller = Captain) and enforces one crew per user", async () => {
    const response = await createCrew(request("POST", "/crews", { token: captain.accessToken, body: { name: "Dawn Patrol", emoji: "🌅" } }));
    expect(response.status).toBe(201);
    const reply = await readJson<{ crew: { id: string; inviteLink: string } }>(response);
    crewId = reply.crew.id;
    inviteLink = reply.crew.inviteLink;
    expect((await createCrew(request("POST", "/crews", { token: captain.accessToken, body: { name: "Second", emoji: "🔥" } }))).status).toBe(409);
    expect((await createCrew(request("POST", "/crews", { token: captain.accessToken, body: { name: "x".repeat(SpecConstants.crewNameMaxChars + 1), emoji: "🔥" } }))).status).toBe(400);
  });

  it("previews the invite without auth and joins via link with a system line", async () => {
    const preview = await readJson<{ name: string; emoji: string; memberCount: number; full: boolean }>(await previewInvite(new Request(`http://localhost:3000/api/v1/crews/join?token=${tokenOf(inviteLink)}`)));
    expect(preview).toMatchObject({ name: "Dawn Patrol", emoji: "🌅", memberCount: 1, full: false });
    expect((await joinCrew(request("POST", "/crews/join", { token: alex.accessToken, body: { token: tokenOf(inviteLink) } }))).status).toBe(201);
    expect((await joinCrew(request("POST", "/crews/join", { token: alex.accessToken, body: { token: tokenOf(inviteLink) } }))).status).toBe(409); // already in a crew
    const mine = await readJson<{ crew: { id: string }; members: { displayName: string }[]; pulse: { posted: number; total: number } }>(await myCrew(request("GET", "/crews", { token: alex.accessToken })));
    expect(mine.crew.id).toBe(crewId);
    expect(mine.members).toHaveLength(2);
    expect(mine.pulse).toEqual({ posted: 0, total: 2 });
    const feed = await readJson<{ items: { kind: string; body?: string }[] }>(await stream(request("GET", `/crews/${crewId}/stream`, { token: alex.accessToken }), params(crewId)));
    expect(feed.items.some((item) => item.kind === "system" && item.body === "alex joined the crew")).toBe(true);
  });

  it("counts the pulse from shared posts and shows them in the stream (join-forward)", async () => {
    await createPost(request("POST", "/posts", { token: captain.accessToken, body: { clientId: randomUUID(), type: "meal", caption: "who's in at 6am", shareToCrew: true, timezone: "UTC", isPlannedDay: false } }));
    const mine = await readJson<{ pulse: { posted: number; total: number } }>(await myCrew(request("GET", "/crews", { token: captain.accessToken })));
    expect(mine.pulse).toEqual({ posted: 1, total: 2 });
    await joinCrew(request("POST", "/crews/join", { token: sam.accessToken, body: { token: tokenOf(inviteLink) } }));
    const samsFeed = await readJson<{ items: { kind: string }[] }>(await stream(request("GET", `/crews/${crewId}/stream`, { token: sam.accessToken }), params(crewId)));
    expect(samsFeed.items.filter((item) => item.kind === "post")).toHaveLength(0); // joined after the post: join-forward
    const captainsFeed = await readJson<{ items: { kind: string; comeback?: boolean }[] }>(await stream(request("GET", `/crews/${crewId}/stream`, { token: captain.accessToken }), params(crewId)));
    expect(captainsFeed.items.filter((item) => item.kind === "post")).toHaveLength(1);
    expect(captainsFeed.items.find((item) => item.kind === "post")?.comeback).toBe(false);
  });

  it("regenerated link kills the old one; only the Captain may regenerate or rename", async () => {
    expect((await regenerateInvite(request("POST", `/crews/${crewId}/invite`, { token: alex.accessToken }), params(crewId))).status).toBe(403);
    const regenerated = await readJson<{ inviteLink: string }>(await regenerateInvite(request("POST", `/crews/${crewId}/invite`, { token: captain.accessToken }), params(crewId)));
    expect(regenerated.inviteLink).not.toBe(inviteLink);
    expect((await previewInvite(new Request(`http://localhost:3000/api/v1/crews/join?token=${tokenOf(inviteLink)}`))).status).toBe(404);
    inviteLink = regenerated.inviteLink;
    expect((await renameCrew(request("PATCH", `/crews/${crewId}`, { token: sam.accessToken, body: { name: "Nope" } }), params(crewId))).status).toBe(403);
    expect((await renameCrew(request("PATCH", `/crews/${crewId}`, { token: captain.accessToken, body: { name: "Dawn Patrol II" } }), params(crewId))).status).toBe(200);
  });

  it("rejects joins when full", async () => {
    for (let index = 0; index < SpecConstants.crewMaxMembers - 3; index += 1) {
      const filler = await createUser(`filler${index}`);
      expect((await joinCrew(request("POST", "/crews/join", { token: filler.accessToken, body: { token: tokenOf(inviteLink) } }))).status).toBe(201);
    }
    const eleventh = await createUser("eleventh");
    const full = await joinCrew(request("POST", "/crews/join", { token: eleventh.accessToken, body: { token: tokenOf(inviteLink) } }));
    expect(full.status).toBe(409);
    expect((await readJson(full)).error).toMatchObject({ code: "crewFull" });
  });

  // SPEC: E2 per-crew mute · S17 (Settings: per-crew mute) · docs/api.md PATCH crews/[id]/mute
  it("mutes and unmutes the crew for one member only, visible on users/me; an outsider is 404", async () => {
    expect((await muteCrew(request("PATCH", `/crews/${crewId}/mute`, { token: alex.accessToken, body: { muted: true } }), params(crewId))).status).toBe(200);
    const alexMe = await readJson<{ crew: { muted: boolean } }>(await getMe(request("GET", "/users/me", { token: alex.accessToken })));
    expect(alexMe.crew.muted).toBe(true);
    const captainMe = await readJson<{ crew: { muted: boolean } }>(await getMe(request("GET", "/users/me", { token: captain.accessToken })));
    expect(captainMe.crew.muted).toBe(false); // a mute is the member's own, never the crew's
    expect((await muteCrew(request("PATCH", `/crews/${crewId}/mute`, { token: alex.accessToken, body: { muted: false } }), params(crewId))).status).toBe(200);
    expect((await readJson<{ crew: { muted: boolean } }>(await getMe(request("GET", "/users/me", { token: alex.accessToken })))).crew.muted).toBe(false);
    expect((await muteCrew(request("PATCH", `/crews/${crewId}/mute`, { token: alex.accessToken, body: { muted: "yes" } }), params(crewId))).status).toBe(400);
    const outsider = await createUser("outsider", "UTC");
    expect((await muteCrew(request("PATCH", `/crews/${crewId}/mute`, { token: outsider.accessToken, body: { muted: true } }), params(crewId))).status).toBe(404);
  });

  it("Captain removes a member; a member cannot; leaving passes captaincy to the longest-tenured; last out archives", async () => {
    expect((await leaveOrRemove(request("DELETE", `/crews/${crewId}/members`, { token: alex.accessToken, body: { userId: sam.id } }), params(crewId))).status).toBe(403);
    expect((await leaveOrRemove(request("DELETE", `/crews/${crewId}/members`, { token: captain.accessToken, body: { userId: sam.id } }), params(crewId))).status).toBe(200);
    expect((await listMembers(request("GET", `/crews/${crewId}/members`, { token: sam.accessToken }), params(crewId))).status).toBe(404);
    expect((await leaveOrRemove(request("DELETE", `/crews/${crewId}/members`, { token: captain.accessToken }), params(crewId))).status).toBe(200);
    const doc = await (await crews()).findOne({ _id: (await import("mongodb")).ObjectId.createFromHexString(crewId) });
    expect(doc?.captainId.toHexString()).toBe(alex.id); // longest-tenured after the captain
    const members = await readJson<{ members: { id: string }[] }>(await listMembers(request("GET", `/crews/${crewId}/members`, { token: alex.accessToken }), params(crewId)));
    for (const member of members.members) {
      const who = member.id === alex.id ? alex : null;
      if (who) continue;
      await leaveOrRemove(request("DELETE", `/crews/${crewId}/members`, { token: alex.accessToken, body: { userId: member.id } }), params(crewId));
    }
    await leaveOrRemove(request("DELETE", `/crews/${crewId}/members`, { token: alex.accessToken }), params(crewId));
    const archived = await (await crews()).findOne({ _id: (await import("mongodb")).ObjectId.createFromHexString(crewId) });
    expect(archived?.archivedAt).not.toBeNull();
  });
});
