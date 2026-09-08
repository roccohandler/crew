// SPEC: Part IV success targets · T045 "metrics live from first-party events" — the weekly report the owner reads (XII Beta).
// Seeds the real collections and checks every reading against hand-computed numbers; the targets come from spec-constants.
import { ObjectId } from "mongodb";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { closeDb, crewMemberships, getDb, posts, resetDbForTests, users } from "@/lib/db";
import { SpecConstants } from "@/generated/spec-constants";
// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore — plain ESM script, run by node in production; imported here to prove its arithmetic
import { computeMetrics, formatReport } from "../../scripts/metrics.mjs";

const at = (day: string) => new Date(`${day}T12:00:00Z`);

async function seedUser(label: string, createdDay: string, postDays: string[], crewId: ObjectId | null): Promise<void> {
  const userId = new ObjectId();
  await (await users()).insertOne({ _id: userId, email: `${label}@example.com`, emailLower: `${label}@example.com`, authProvider: "email", displayName: label, profilePhotoKey: null, units: "lb", timezone: "UTC", reminderTime: null, eulaAcceptedAt: at(createdDay), createdAt: at(createdDay) });
  for (const day of postDays) {
    await (await posts()).insertOne({ _id: new ObjectId(), clientId: `${label}-${day}`, userId, type: "meal", sessionId: null, photoKey: null, caption: "", mealTag: null, crewId, dayKey: day, isPlannedDay: false, workoutCompleted: false, earlierToday: false, createdAt: at(day), deletedAt: null });
  }
  if (crewId !== null) await (await crewMemberships()).insertOne({ _id: new ObjectId(), crewId, userId, joinedAt: at(createdDay), joinedDayKey: createdDay, mutedAt: null });
}

beforeAll(async () => {
  await resetDbForTests();
  const crewId = new ObjectId();
  await seedUser("ana", "2026-08-01", ["2026-08-01", "2026-08-03", "2026-08-09"], crewId); // same-day post ✓, retained (day 8) ✓, crew
  await seedUser("ben", "2026-08-02", ["2026-08-04"], crewId); // no same-day post, not retained, crew
  await seedUser("cai", "2026-08-03", ["2026-08-03", "2026-08-10", "2026-08-11"], null); // same-day ✓, retained (day 7) ✓, solo
  await seedUser("dee", "2026-08-05", [], null); // never posted, solo
  await seedUser("eve", "2026-08-12", ["2026-08-12"], null); // too recent for D7 (window ends 08-14): excluded from the D7 cohort
});

afterAll(async () => {
  await closeDb();
});

describe("E10 metrics report", () => {
  it("computes the Part IV readings from the seeded facts", async () => {
    const report = await computeMetrics(await getDb(), { from: "2026-08-01", to: "2026-08-14" });
    expect(report.signups).toBe(5);
    expect(report.installToFirstPostSameDayPct).toBe(60); // ana, cai, eve of 5
    expect(report.d7RetentionPct).toBe(50); // eligible: ana, ben, cai, dee → ana + cai retained
    expect(report.postsPerUserPerWeek).toBe(1); // 8 posts / 4 posters (ana, ben, cai, eve) / 2 weeks
    expect(report.crewVsSoloRetentionMultiplier).toBe(1); // crew 50% (ana of ana+ben) ÷ solo 50% (cai of cai+dee)
    expect(report.crashFreePct).toBeNull();
    expect(report.targets.d7RetentionPct).toBe(SpecConstants.targetD7RetentionPct);
    expect(formatReport(report)).toContain("D7 retention");
  });

  it("reads null rather than dividing by zero on an empty window", async () => {
    const report = await computeMetrics(await getDb(), { from: "2027-01-01", to: "2027-01-07" });
    expect(report.signups).toBe(0);
    expect(report.installToFirstPostSameDayPct).toBeNull();
    expect(report.postsPerUserPerWeek).toBeNull();
  });
});
