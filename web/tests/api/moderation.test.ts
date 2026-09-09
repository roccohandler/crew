// SPEC: T034 (Verify: moderation suite) · 8.2 Moderation/Safety: report post/message/crew-name lands in the queue (the email);
// block hides both ways without notification; EULA gate on register (covered in auth.test.ts) · T033 push-token route ·
// A7: the blocked list is readable (GET blocks) and DELETE blocks is the unblock.
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { DELETE as unblock, GET as listBlocks, POST as block } from "@/app/api/v1/blocks/route";
import { POST as createPost } from "@/app/api/v1/posts/route";
import { DELETE as removePushToken, POST as registerPushToken } from "@/app/api/v1/push-token/route";
import { POST as report } from "@/app/api/v1/reports/route";
import { closeDb, pushTokens, reports, resetDbForTests } from "@/lib/db";
import { emailOutbox } from "@/lib/email";
import { pushOutbox, sendPush } from "@/lib/push";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { ObjectId } from "mongodb";

let me: TestUser;
let other: TestUser;

beforeAll(async () => {
  await resetDbForTests();
  me = await createUser("reporter", "UTC");
  other = await createUser("reported", "UTC");
});
afterAll(async () => {
  await closeDb();
});

describe("reports", () => {
  it("stores the report and emails the moderation inbox with target + reporter context", async () => {
    const post = await readJson<{ post: { id: string } }>(await createPost(request("POST", "/posts", { token: other.accessToken, body: { clientId: randomUUID(), type: "text", caption: "questionable", shareToCrew: false, timezone: "UTC", isPlannedDay: false } })));
    const response = await report(request("POST", "/reports", { token: me.accessToken, body: { targetType: "post", targetId: post.post.id, reason: "this is not okay" } }));
    expect(response.status).toBe(201);
    expect(await (await reports()).countDocuments({ status: "open" })).toBe(1);
    const email = await (await emailOutbox()).findOne({ kind: "reportReceived" });
    expect(email?.text).toContain(post.post.id);
    expect(email?.text).toContain(me.id);
    expect(email?.text).toContain("questionable");
    expect((await report(request("POST", "/reports", { token: me.accessToken, body: { targetType: "post", targetId: new ObjectId().toHexString(), reason: "ghost" } }))).status).toBe(404);
  });
});

describe("blocks", () => {
  it("lists who I blocked with their name, only for me, and DELETE unblocks (A7)", async () => {
    const listFor = async (user: TestUser) => (await readJson<{ blocked: { userId: string; displayName: string }[] }>(await listBlocks(request("GET", "/blocks", { token: user.accessToken })))).blocked;
    expect(await listFor(me)).toEqual([]);
    expect((await block(request("POST", "/blocks", { token: me.accessToken, body: { userId: other.id } }))).status).toBe(201);
    expect((await block(request("POST", "/blocks", { token: me.accessToken, body: { userId: other.id } }))).status).toBe(201); // idempotent
    expect(await listFor(me)).toEqual([{ userId: other.id, displayName: "reported" }]);
    expect(await listFor(other)).toEqual([]); // silent: the blocked person never sees it
    expect((await unblock(request("DELETE", "/blocks", { token: me.accessToken, body: { userId: other.id } }))).status).toBe(200);
    expect(await listFor(me)).toEqual([]);
    expect((await unblock(request("DELETE", "/blocks", { token: me.accessToken, body: { userId: other.id } }))).status).toBe(404);
  });
});

describe("push tokens", () => {
  it("registers, sends to the outbox without APNs credentials, and unregisters", async () => {
    expect((await registerPushToken(request("POST", "/push-token", { token: me.accessToken, body: { token: "device-token-1", platform: "ios" } }))).status).toBe(201);
    expect(await (await pushTokens()).countDocuments({ token: "device-token-1" })).toBe(1);
    const sent = await sendPush(new ObjectId(me.id), { title: "Push day is ready 💪", body: "5 exercises + mobility · ~45 min", kind: "reminder" });
    expect(sent).toBe(1);
    expect(await (await pushOutbox()).countDocuments({ token: "device-token-1" })).toBe(1);
    expect((await removePushToken(request("DELETE", "/push-token", { token: me.accessToken, body: { token: "device-token-1" } }))).status).toBe(200);
    expect(await (await pushTokens()).countDocuments({ token: "device-token-1" })).toBe(0);
  });
});
