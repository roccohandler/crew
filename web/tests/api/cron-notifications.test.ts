// SPEC: T033 (Verify: unit + manual push on device) — the cron sender: secret-gated; a due reminder names the workout and goes
// out once per day; a rest day or a paused plan sends nothing · A1: the reminder names the ROTATION's next workout (the one after
// the last completed), never a weekday slot · A7: the workout-reminder toggle silences it.
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { GET as cron } from "@/app/api/cron/notifications/route";
import { PUT as putPlan } from "@/app/api/v1/plans/route";
import { POST as registerPushToken } from "@/app/api/v1/push-token/route";
import { PATCH as patchMe } from "@/app/api/v1/users/me/route";
import { closeDb, pauses, resetDbForTests, sessions, users } from "@/lib/db";
import { addDays, dayKeyFor } from "@/lib/engine/day-key";
import { notificationLog } from "@/lib/notification-facts";
import { pushOutbox } from "@/lib/push";
import { ObjectId } from "mongodb";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { samplePlanBody } from "./plans-sessions";

let me: TestUser;
const TZ = "UTC";

function nowLocalHHMM(): string {
  const parts = new Intl.DateTimeFormat("en-US", { timeZone: TZ, hourCycle: "h23", hour: "2-digit", minute: "2-digit" }).formatToParts(new Date());
  return `${parts.find((part) => part.type === "hour")!.value}:${parts.find((part) => part.type === "minute")!.value}`;
}

beforeAll(async () => {
  await resetDbForTests();
  process.env.CRON_SECRET = "test-cron-secret";
  me = await createUser("cron", TZ);
  await registerPushToken(request("POST", "/push-token", { token: me.accessToken, body: { token: "cron-device", platform: "ios" } }));
  await putPlan(request("PUT", "/plans", { token: me.accessToken, body: samplePlanBody([1, 2, 3, 4, 5, 6, 7]) }));
  await (await users()).updateOne({ _id: new ObjectId(me.id) }, { $set: { reminderTime: nowLocalHHMM() } });
});
afterAll(async () => {
  await closeDb();
});

const call = (secret = "test-cron-secret") => cron(new Request("http://localhost:3000/api/cron/notifications", { headers: { authorization: `Bearer ${secret}` } }));
const resetSends = async () => {
  await (await pushOutbox()).deleteMany({});
  await (await notificationLog()).deleteMany({});
};
const reminderTitle = async () => (await (await pushOutbox()).findOne({ userId: new ObjectId(me.id), kind: "reminder" }))?.title;

describe("cron notifications", () => {
  it("rejects a bad secret", async () => {
    expect((await call("wrong")).status).toBe(401);
  });

  it("sends the reminder once at the chosen time, naming the rotation's first workout, and never twice the same day", async () => {
    const first = await readJson<{ sent: number }>(await call());
    expect(first.sent).toBe(1);
    expect(await reminderTitle()).toBe("Push day is ready 💪"); // nothing completed yet → the cycle starts at its first workout
    const outbox = await (await pushOutbox()).findOne({ userId: new ObjectId(me.id), kind: "reminder" });
    expect(outbox?.body).toBe(`${samplePlanBody().workouts[0]!.exercises.filter((row) => row.type === "strength").length} exercises + mobility`);
    const second = await readJson<{ sent: number }>(await call());
    expect(second.sent).toBe(0);
  });

  it("names the workout after the last completed one (A1): a Push day yesterday makes today Pull day", async () => {
    await resetSends();
    const today = dayKeyFor(new Date(), TZ);
    const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
    await (await sessions()).insertOne({ _id: new ObjectId(), clientId: randomUUID(), userId: new ObjectId(me.id), dayKey: addDays(today, -1), status: "completed", workoutName: "Push day", workoutKind: "push", isPlannedDay: true, startedAt: yesterday, completedAt: yesterday, timezone: TZ, exercises: [], updatedAt: yesterday });
    expect((await readJson<{ sent: number }>(await call())).sent).toBe(1);
    expect(await reminderTitle()).toBe("Pull day is ready 💪");
  });

  it("sends nothing when the workout-reminder toggle is off (A7)", async () => {
    await resetSends();
    await patchMe(request("PATCH", "/users/me", { token: me.accessToken, body: { notificationPrefs: { workoutReminder: false } } }));
    expect((await readJson<{ sent: number }>(await call())).sent).toBe(0);
    await patchMe(request("PATCH", "/users/me", { token: me.accessToken, body: { notificationPrefs: { workoutReminder: true } } }));
    expect((await readJson<{ sent: number }>(await call())).sent).toBe(1);
  });

  it("sends nothing while paused", async () => {
    await resetSends();
    const today = dayKeyFor(new Date(), TZ);
    await (await pauses()).insertOne({ _id: new ObjectId(), userId: new ObjectId(me.id), startDay: today, endDay: `${Number(today.slice(0, 4)) + 1}-01-01`, createdAt: new Date() });
    const reply = await readJson<{ sent: number }>(await call());
    expect(reply.sent).toBe(0);
  });
});
