// SPEC: T009 (Verify: npm test tests/api/db) · Part IX invariants — one plan per user, one crew per user, reaction
// uniqueness — proven against a real MongoDB (C4), never a mock.
import { ObjectId } from "mongodb";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { closeDb, crewMemberships, gamificationStates, getDb, plans, reactions, resetDbForTests, users } from "@/lib/db";

beforeAll(async () => {
  await resetDbForTests();
});
afterAll(async () => {
  await closeDb();
});

async function expectDuplicateKey(insert: () => Promise<unknown>) {
  await expect(insert()).rejects.toMatchObject({ code: 11000 });
}

describe("lib/db — Part IX invariants as unique indexes", () => {
  it("creates every collection index once and connects", async () => {
    const db = await getDb();
    const planIndexes = await db.collection("plans").indexes();
    expect(planIndexes.some((index) => index.unique === true && index.key.userId === 1)).toBe(true);
  });

  it("one plan per user", async () => {
    const userId = new ObjectId();
    const collection = await plans();
    await collection.insertOne({ _id: new ObjectId(), userId, trainingWeekdays: [], workouts: [], updatedAt: new Date() });
    await expectDuplicateKey(() => collection.insertOne({ _id: new ObjectId(), userId, trainingWeekdays: [], workouts: [], updatedAt: new Date() }));
  });

  it("one crew per user", async () => {
    const userId = new ObjectId();
    const collection = await crewMemberships();
    const membership = { crewId: new ObjectId(), userId, joinedAt: new Date(), joinedDayKey: "2026-09-04", mutedAt: null };
    await collection.insertOne({ _id: new ObjectId(), ...membership });
    await expectDuplicateKey(() => collection.insertOne({ _id: new ObjectId(), ...membership, crewId: new ObjectId() }));
  });

  it("one reaction per user per target", async () => {
    const userId = new ObjectId();
    const targetId = new ObjectId();
    const collection = await reactions();
    const reaction = { targetType: "post" as const, targetId, userId, emoji: "🔥", dayKey: "2026-09-04", createdAt: new Date() };
    await collection.insertOne({ _id: new ObjectId(), ...reaction });
    await expectDuplicateKey(() => collection.insertOne({ _id: new ObjectId(), ...reaction, emoji: "💪" }));
  });

  it("one gamification state per user and one email per account (case-insensitive)", async () => {
    const userId = new ObjectId();
    const states = await gamificationStates();
    const state = { userId, currentStreak: 0, longestStreak: 0, totalXP: 0, level: 1, shields: 0, lastCountedDayKey: null, earnedAchievementIds: [], recomputedAt: new Date() };
    await states.insertOne({ _id: new ObjectId(), ...state });
    await expectDuplicateKey(() => states.insertOne({ _id: new ObjectId(), ...state }));
    const collection = await users();
    const user = { email: "Sam@Example.com", emailLower: "sam@example.com", authProvider: "email" as const, displayName: "Sam", profilePhotoKey: null, units: "lb" as const, timezone: "America/Los_Angeles", reminderTime: null, eulaAcceptedAt: new Date(), createdAt: new Date() };
    await collection.insertOne({ _id: new ObjectId(), ...user });
    await expectDuplicateKey(() => collection.insertOne({ _id: new ObjectId(), ...user, email: "SAM@example.com" }));
  });
});
