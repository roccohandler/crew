// SPEC: T041 (Verify: account suite) · 8.2 Account: JSON export completeness; delete cascade — posts vanish from streams, blobs
// deleted, 404s everywhere after · 8.2 Pause: create/end; overlap rejected; XP suppression server-enforced (V20) · E18 re-signup.
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { GET as stream } from "@/app/api/v1/crews/[id]/stream/route";
import { POST as joinCrew } from "@/app/api/v1/crews/join/route";
import { POST as createCrew } from "@/app/api/v1/crews/route";
import { DELETE as endPause, POST as createPause } from "@/app/api/v1/pause/route";
import { POST as createPost } from "@/app/api/v1/posts/route";
import { GET as exportData } from "@/app/api/v1/users/me/export/route";
import { DELETE as deleteMe, GET as getMe, PATCH as patchMe } from "@/app/api/v1/users/me/route";
import { POST as register } from "@/app/api/v1/auth/register/route";
import { closeDb, photos, posts, resetDbForTests, users } from "@/lib/db";
import { emailOutbox } from "@/lib/email";
import { addDays, dayKeyFor } from "@/lib/engine/day-key";
import { ObjectId } from "mongodb";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";

let me: TestUser;
let mate: TestUser;
let crewId = "";
const params = (id: string) => ({ params: Promise.resolve({ id }) });
const today = () => dayKeyFor(new Date(), "UTC");

beforeAll(async () => {
  await resetDbForTests();
  me = await createUser("owner", "UTC");
  mate = await createUser("mate", "UTC");
  const crew = await readJson<{ crew: { id: string; inviteLink: string } }>(await createCrew(request("POST", "/crews", { token: me.accessToken, body: { name: "Export Crew", emoji: "📦" } })));
  crewId = crew.crew.id;
  await joinCrew(request("POST", "/crews/join", { token: mate.accessToken, body: { token: crew.crew.inviteLink.split("/join/")[1] } }));
  await createPost(request("POST", "/posts", { token: me.accessToken, body: { clientId: randomUUID(), type: "meal", caption: "shared plate", shareToCrew: true, timezone: "UTC", isPlannedDay: false } }));
});
afterAll(async () => {
  await closeDb();
});

describe("pause", () => {
  it("creates, suppresses XP for posts during it (V20), rejects a second, and ends early", async () => {
    const start = addDays(today(), 1);
    const created = await createPause(request("POST", "/pause", { token: me.accessToken, body: { startDay: start, endDay: addDays(start, 7), timezone: "UTC" } }));
    expect(created.status).toBe(201);
    expect((await createPause(request("POST", "/pause", { token: me.accessToken, body: { startDay: addDays(start, 8), endDay: addDays(start, 10), timezone: "UTC" } }))).status).toBe(409);
    expect((await createPause(request("POST", "/pause", { token: mate.accessToken, body: { startDay: addDays(today(), -1), endDay: addDays(today(), 3), timezone: "UTC" } }))).status).toBe(400);
    expect((await createPause(request("POST", "/pause", { token: mate.accessToken, body: { startDay: today(), endDay: addDays(today(), 22), timezone: "UTC" } }))).status).toBe(400);
    const before = await readJson<{ gamification: { totalXP: number } }>(await getMe(request("GET", "/users/me", { token: mate.accessToken })));
    await createPause(request("POST", "/pause", { token: mate.accessToken, body: { startDay: today(), endDay: addDays(today(), 3), timezone: "UTC" } }));
    const during = await readJson<{ gamification: { totalXP: number; currentStreak: number } }>(await createPost(request("POST", "/posts", { token: mate.accessToken, body: { clientId: randomUUID(), type: "text", caption: "paused post", shareToCrew: false, timezone: "UTC", isPlannedDay: false } })));
    expect(during.gamification.totalXP).toBe(before.gamification.totalXP);
    expect((await endPause(request("DELETE", "/pause", { token: mate.accessToken }))).status).toBe(200);
  });
});

describe("users/me + export + delete cascade", () => {
  it("patches profile fields and exports everything the user owns", async () => {
    const patched = await readJson<{ displayName: string; units: string }>(await patchMe(request("PATCH", "/users/me", { token: me.accessToken, body: { displayName: "Owner Prime", units: "kg", reminderTime: "07:30" } })));
    expect(patched).toMatchObject({ displayName: "Owner Prime", units: "kg" });
    const data = await readJson<{ user: { email: string; passwordHash?: string }; posts: unknown[]; memberships: unknown[]; gamification: unknown; pauses: unknown[] }>(await exportData(request("GET", "/users/me/export", { token: me.accessToken })));
    expect(data.user.email).toBe(me.email);
    expect(data.user.passwordHash).toBeUndefined();
    expect(data.posts.length).toBe(1);
    expect(data.memberships.length).toBe(1);
    expect(data.pauses.length).toBe(1);
    expect(data.gamification).not.toBeNull();
  });

  it("deletes the account: posts vanish from the stream, photos go, everything 404s, the email goes out, re-signup is fresh", async () => {
    await (await photos()).insertOne({ _id: new ObjectId(), photoKey: "owner-photo", ownerId: new ObjectId(me.id), purpose: "post", bytes: 1, width: 1, height: 1, storage: "local", url: "C:/nonexistent/owner-photo.jpg", createdAt: new Date() });
    expect((await deleteMe(request("DELETE", "/users/me", { token: me.accessToken, body: { confirm: "delete" } }))).status).toBe(200);
    expect((await getMe(request("GET", "/users/me", { token: me.accessToken }))).status).toBe(404);
    expect(await (await posts()).countDocuments({ userId: new ObjectId(me.id) })).toBe(0);
    expect(await (await photos()).countDocuments({ photoKey: "owner-photo" })).toBe(0);
    expect(await (await users()).countDocuments({ _id: new ObjectId(me.id) })).toBe(0);
    const feed = await readJson<{ items: { userId: string }[] }>(await stream(request("GET", `/crews/${crewId}/stream`, { token: mate.accessToken }), params(crewId)));
    expect(feed.items.some((item) => item.userId === me.id)).toBe(false);
    expect((await (await emailOutbox()).findOne({ to: me.email, kind: "accountDeleted" }))).not.toBeNull();
    const again = await register(request("POST", "/auth/register", { ip: "203.0.113.77", body: { email: me.email, password: "fresh start 123", displayName: "Owner Again", timezone: "UTC", eulaAccepted: true, birthYear: 1990 } }));
    expect(again.status).toBe(201);
    expect((await readJson<{ user: { id: string } }>(again)).user.id).not.toBe(me.id);
  });
});
