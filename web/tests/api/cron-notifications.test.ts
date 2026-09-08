// SPEC: T033 (Verify: unit + manual push on device) — the cron sender: secret-gated; a due reminder names the workout and goes
// out once per day; a rest day or a paused plan sends nothing.
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { GET as cron } from "@/app/api/cron/notifications/route";
import { PUT as putPlan } from "@/app/api/v1/plans/route";
import { POST as registerPushToken } from "@/app/api/v1/push-token/route";
import { closeDb, pauses, resetDbForTests, users } from "@/lib/db";
import { dayKeyFor, isoWeekday } from "@/lib/engine/day-key";
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

describe("cron notifications", () => {
  it("rejects a bad secret", async () => {
    expect((await call("wrong")).status).toBe(401);
  });

  it("sends the reminder once at the chosen time, naming the workout, and never twice the same day", async () => {
    const first = await readJson<{ sent: number }>(await call());
    expect(first.sent).toBe(1);
    const outbox = await (await pushOutbox()).findOne({ userId: new ObjectId(me.id), kind: "reminder" });
    const todayWeekday = isoWeekday(dayKeyFor(new Date(), TZ));
    const plan = samplePlanBody([1, 2, 3, 4, 5, 6, 7]);
    expect(outbox?.title).toBe(`${plan.workouts.find((workout) => workout.weekday === todayWeekday)!.name} is ready 💪`);
    const second = await readJson<{ sent: number }>(await call());
    expect(second.sent).toBe(0);
  });

  it("sends nothing while paused", async () => {
    await (await pushOutbox()).deleteMany({});
    await (await (await import("@/lib/notification-facts")).notificationLog()).deleteMany({});
    const today = dayKeyFor(new Date(), TZ);
    await (await pauses()).insertOne({ _id: new ObjectId(), userId: new ObjectId(me.id), startDay: today, endDay: `${Number(today.slice(0, 4)) + 1}-01-01`, createdAt: new Date() });
    const reply = await readJson<{ sent: number }>(await call());
    expect(reply.sent).toBe(0);
  });
});
