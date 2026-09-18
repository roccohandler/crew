// SPEC: T041 (Verify: account suite) · 8.2 Account: JSON export completeness; delete cascade — posts vanish from streams, blobs
// deleted, 404s everywhere after · 8.2 Pause: create/end; overlap rejected; XP suppression server-enforced (V20) · E18 re-signup ·
// A7: notification toggles round-trip (absent = all on, partial PATCH merges); a profile photo key must be the caller's own.
// W5 (2026-09-17): the cascade crawl — a crew-mate's reaction on the user's post, the reports the user filed, the outbox rows — finds nothing left.
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { GET as stream } from "@/app/api/v1/crews/[id]/stream/route";
import { POST as joinCrew } from "@/app/api/v1/crews/join/route";
import { POST as createCrew } from "@/app/api/v1/crews/route";
import { DELETE as endPause, POST as createPause } from "@/app/api/v1/pause/route";
import { GET as exportData } from "@/app/api/v1/users/me/export/route";
import { DELETE as deleteMe, GET as getMe, PATCH as patchMe } from "@/app/api/v1/users/me/route";
import { POST as register } from "@/app/api/v1/auth/register/route";
import { closeDb, photos, posts, reactions, reports, resetDbForTests, users } from "@/lib/db";
import { emailOutbox } from "@/lib/email";
import { pushOutbox } from "@/lib/push";
import { addDays, dayKeyFor } from "@/lib/engine/day-key";
import { ObjectId } from "mongodb";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { postWorkout } from "./workout-post";

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
  await postWorkout(me, { cardio: true, shareToCrew: true, caption: "shared session", timezone: "UTC" }); // A22: a post is a workout post
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
    const during = await postWorkout(mate, { cardio: true, timezone: "UTC" }); // V79: a workout completed inside the pause pays nothing
    expect(during.gamification.totalXP).toBe(before.gamification.totalXP);
    expect((await endPause(request("DELETE", "/pause", { token: mate.accessToken }))).status).toBe(200);
  });
});

describe("users/me + export + delete cascade", () => {
  it("patches profile fields and exports everything the user owns", async () => {
    const patched = await readJson<{ displayName: string; units: string }>(await patchMe(request("PATCH", "/users/me", { token: me.accessToken, body: { displayName: "Owner Prime", units: "kg", reminderTime: "07:30" } })));
    expect(patched).toMatchObject({ displayName: "Owner Prime", units: "kg" });
    const data = await readJson<{ user: { email: string; passwordHash?: string }; posts: unknown[]; memberships: unknown[]; gamification: unknown; pauses: unknown[]; blocks: unknown[] }>(await exportData(request("GET", "/users/me/export", { token: me.accessToken })));
    expect(data.user.email).toBe(me.email);
    expect(data.user.passwordHash).toBeUndefined();
    expect(data.posts.length).toBe(1);
    expect(data.memberships.length).toBe(1);
    expect(data.pauses.length).toBe(1);
    expect(data.blocks).toEqual([]);
    expect(data.gamification).not.toBeNull();
  });

  it("keeps notification toggles per row: absent = all on, a partial PATCH merges over the stored ones (A7)", async () => {
    type Prefs = { workoutReminder: boolean; streakRisk: boolean; crewActivity: boolean };
    const mine = async () => (await readJson<{ user: { notificationPrefs: Prefs } }>(await getMe(request("GET", "/users/me", { token: me.accessToken })))).user.notificationPrefs;
    expect(await mine()).toEqual({ workoutReminder: true, streakRisk: true, crewActivity: true });
    const first = await readJson<{ notificationPrefs: Prefs }>(await patchMe(request("PATCH", "/users/me", { token: me.accessToken, body: { notificationPrefs: { streakRisk: false } } })));
    expect(first.notificationPrefs).toEqual({ workoutReminder: true, streakRisk: false, crewActivity: true });
    await patchMe(request("PATCH", "/users/me", { token: me.accessToken, body: { notificationPrefs: { crewActivity: false } } }));
    expect(await mine()).toEqual({ workoutReminder: true, streakRisk: false, crewActivity: false }); // merged, not replaced
    expect((await patchMe(request("PATCH", "/users/me", { token: me.accessToken, body: { notificationPrefs: { streakRisk: "no" } } }))).status).toBe(400);
  });

  // A23 — the seen-state round trip: what one device saw, every device has seen. The list is a UNION — it never shrinks, a
  // repeat changes nothing, an id the copy file does not name is refused, and a PATCH that carries ONLY whispers is a real write.
  it("unions the seen whispers into the account and never removes one (A23)", async () => {
    const seen = async () => (await readJson<{ user: { whispersSeen: string[] } }>(await getMe(request("GET", "/users/me", { token: me.accessToken })))).user.whispersSeen;
    expect(await seen()).toEqual([]);
    const phone = await readJson<{ whispersSeen: string[] }>(await patchMe(request("PATCH", "/users/me", { token: me.accessToken, body: { whispersSeen: ["how.pause"] } })));
    expect(phone.whispersSeen).toEqual(["how.pause"]);
    await patchMe(request("PATCH", "/users/me", { token: me.accessToken, body: { whispersSeen: ["why.streak", "how.pause"] } })); // the web, later
    expect(await seen()).toEqual(["how.pause", "why.streak"]);
    await patchMe(request("PATCH", "/users/me", { token: me.accessToken, body: { whispersSeen: [] } })); // nothing a client sends can shrink it
    expect(await seen()).toEqual(["how.pause", "why.streak"]);
    expect((await patchMe(request("PATCH", "/users/me", { token: me.accessToken, body: { whispersSeen: ["why.everything"] } }))).status).toBe(400);
  });

  it("accepts a profile photo key only when it names the caller's own photo uploaded with purpose profile (A7, E1)", async () => {
    const patchPhoto = async (profilePhotoKey: string | null) => patchMe(request("PATCH", "/users/me", { token: me.accessToken, body: { profilePhotoKey } }));
    const photo = (photoKey: string, ownerId: string, purpose: "post" | "profile") => ({ _id: new ObjectId(), photoKey, ownerId: new ObjectId(ownerId), purpose, bytes: 1, width: 1, height: 1, storage: "local" as const, url: `C:/nonexistent/${photoKey}.jpg`, createdAt: new Date() });
    await (await photos()).insertMany([photo("owner-post", me.id, "post"), photo("mate-profile", mate.id, "profile"), photo("owner-profile", me.id, "profile")]);
    expect((await patchPhoto("ghost")).status).toBe(400);
    expect((await patchPhoto("owner-post")).status).toBe(400); // a post photo is not a profile photo
    expect((await patchPhoto("mate-profile")).status).toBe(400); // someone else's
    const set = await readJson<{ profilePhotoKey: string | null }>(await patchPhoto("owner-profile"));
    expect(set.profilePhotoKey).toBe("owner-profile");
    expect((await readJson<{ profilePhotoKey: string | null }>(await patchPhoto(null))).profilePhotoKey).toBeNull(); // null still clears
  });

  it("deletes the account: posts vanish from the stream, photos go, everything 404s, the email goes out, re-signup is fresh — and the crawl finds no leftovers (W5)", async () => {
    await (await photos()).insertOne({ _id: new ObjectId(), photoKey: "owner-photo", ownerId: new ObjectId(me.id), purpose: "post", bytes: 1, width: 1, height: 1, storage: "local", url: "C:/nonexistent/owner-photo.jpg", createdAt: new Date() });
    // W5 — the leftovers the audit named: a crew-mate's reaction on MY post, a report I filed, a report naming me, my outbox rows
    const myPost = await (await posts()).findOne({ userId: new ObjectId(me.id) });
    expect(myPost).not.toBeNull();
    await (await reactions()).insertOne({ _id: new ObjectId(), targetType: "post", targetId: myPost!._id, userId: new ObjectId(mate.id), emoji: "🔥", dayKey: today(), createdAt: new Date() });
    await (await reports()).insertMany([
      { _id: new ObjectId(), targetType: "user", targetId: new ObjectId(mate.id), reporterId: new ObjectId(me.id), reason: "filed by me", status: "open", createdAt: new Date() },
      { _id: new ObjectId(), targetType: "user", targetId: new ObjectId(me.id), reporterId: new ObjectId(mate.id), reason: "names me", status: "open", createdAt: new Date() },
    ]);
    await (await emailOutbox()).insertOne({ _id: new ObjectId(), to: me.email, subject: "old", text: "old", kind: "passwordReset", sentAt: new Date() });
    await (await pushOutbox()).insertOne({ _id: new ObjectId(), userId: new ObjectId(me.id), token: "t", kind: "reminder", title: "old", body: "old", sentAt: new Date() });
    expect((await deleteMe(request("DELETE", "/users/me", { token: me.accessToken, body: { confirm: "delete" } }))).status).toBe(200);
    expect((await getMe(request("GET", "/users/me", { token: me.accessToken }))).status).toBe(404);
    expect(await (await posts()).countDocuments({ userId: new ObjectId(me.id) })).toBe(0);
    expect(await (await photos()).countDocuments({ photoKey: "owner-photo" })).toBe(0);
    expect(await (await users()).countDocuments({ _id: new ObjectId(me.id) })).toBe(0);
    const feed = await readJson<{ items: { userId: string }[] }>(await stream(request("GET", `/crews/${crewId}/stream`, { token: mate.accessToken }), params(crewId)));
    expect(feed.items.some((item) => item.userId === me.id)).toBe(false);
    expect((await (await emailOutbox()).findOne({ to: me.email, kind: "accountDeleted" }))).not.toBeNull();
    // W5 — the crawl: nothing of theirs is left but the one "account deleted" email
    expect(await (await reactions()).countDocuments({ targetId: myPost!._id })).toBe(0);
    expect(await (await reactions()).countDocuments({ userId: new ObjectId(me.id) })).toBe(0);
    expect(await (await reports()).countDocuments({ $or: [{ reporterId: new ObjectId(me.id) }, { targetId: new ObjectId(me.id) }] })).toBe(0);
    expect(await (await pushOutbox()).countDocuments({ userId: new ObjectId(me.id) })).toBe(0);
    expect(await (await emailOutbox()).countDocuments({ to: me.email })).toBe(1);
    const again = await register(request("POST", "/auth/register", { ip: "203.0.113.77", body: { email: me.email, password: "fresh start 123", displayName: "Owner Again", timezone: "UTC", eulaAccepted: true, birthYear: 1990 } }));
    expect(again.status).toBe(201);
    expect((await readJson<{ user: { id: string } }>(again)).user.id).not.toBe(me.id);
  });

  // Q12 — seen on production 2026-09-08: the cascade had finished and the answer was 500, because Resend refused the send. The
  // transport here is the REAL one pointed at a closed local port (the SDK reads RESEND_BASE_URL per client), so `deliver` throws
  // without touching the network; the deletion still answers 200, the account is gone, and no confirmation row was written.
  it("answers 200 with the cascade done when the account-deleted email cannot be sent (Q12, E9)", async () => {
    const gone = await createUser("unmailable", "UTC");
    process.env.RESEND_API_KEY = "re_unreachable";
    process.env.RESEND_BASE_URL = "http://127.0.0.1:9";
    try {
      expect((await deleteMe(request("DELETE", "/users/me", { token: gone.accessToken, body: { confirm: "delete" } }))).status).toBe(200);
    } finally {
      delete process.env.RESEND_API_KEY; // back to the outbox transport every other test uses
      delete process.env.RESEND_BASE_URL;
    }
    expect((await getMe(request("GET", "/users/me", { token: gone.accessToken }))).status).toBe(404);
    expect(await (await users()).countDocuments({ _id: new ObjectId(gone.id) })).toBe(0);
    expect(await (await emailOutbox()).countDocuments({ to: gone.email })).toBe(0);
  });
});
