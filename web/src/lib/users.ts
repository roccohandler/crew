// SPEC: Part IX User · E1 (name + one profile picture; initials until set) · E9 (EULA at signup, 13+) · E18 · A7 (notification
// preferences, absent = all on; the profile photo must be the caller's own, purpose "profile").
// Creation, the public shape, and the age/EULA gates — the same for email and Apple accounts.
import { ObjectId } from "mongodb";
import { apiError } from "@/lib/api-error";
import { gamificationStates, photos, users } from "@/lib/db";
import type { NotificationPrefs, UserDoc } from "@/lib/documents";

import { HttpStatus } from "@/lib/http-status";
import { SpecConstants } from "@/generated/spec-constants";

export interface PublicUser {
  id: string;
  email: string;
  authProvider: "email" | "apple";
  displayName: string;
  profilePhotoKey: string | null;
  units: "lb" | "kg";
  timezone: string;
  reminderTime: string | null;
  notificationPrefs: NotificationPrefs; // always present — defaults filled (A7)
  welcomeBackAckDay: string | null;
  createdAt: string;
}

// SPEC: A7 — every toggle is on until the user turns it off; a partial object from the client is merged over these
export function notificationPrefsOf(doc: { notificationPrefs?: NotificationPrefs }): NotificationPrefs {
  return { workoutReminder: true, streakRisk: true, crewActivity: true, ...doc.notificationPrefs };
}

export function publicUser(doc: UserDoc): PublicUser {
  return {
    id: doc._id.toHexString(),
    email: doc.email,
    authProvider: doc.authProvider,
    displayName: doc.displayName,
    profilePhotoKey: doc.profilePhotoKey,
    units: doc.units,
    timezone: doc.timezone,
    reminderTime: doc.reminderTime,
    notificationPrefs: notificationPrefsOf(doc),
    welcomeBackAckDay: doc.welcomeBackAckDay ?? null,
    createdAt: doc.createdAt.toISOString(),
  };
}

// SPEC: E9 — EULA at signup, age floor 13+; the gate runs before anything is written
export function requireSignupGates(eulaAccepted: boolean, birthYear: number | undefined, now: Date = new Date()): void {
  if (!eulaAccepted) throw apiError("eulaRequired", "You need to accept the terms to create an account.", HttpStatus.forbidden);
  if (birthYear !== undefined && now.getUTCFullYear() - birthYear < SpecConstants.minimumAgeYears) {
    throw apiError("underage", `Crew is for people ${SpecConstants.minimumAgeYears} and up.`, HttpStatus.forbidden);
  }
}

// SPEC: A7 / E1 — a profile photo key must name a photo the caller uploaded with purpose "profile" (400 otherwise)
export async function requireOwnProfilePhoto(userId: ObjectId, photoKey: string): Promise<void> {
  const photo = await (await photos()).findOne({ photoKey, ownerId: userId, purpose: "profile" });
  if (photo === null) throw apiError("validation", "That isn't one of your profile photos. Upload it first.", HttpStatus.badRequest);
}

interface NewUser {
  email: string;
  authProvider: "email" | "apple";
  appleSub?: string;
  passwordHash?: string;
  displayName: string;
  timezone: string;
}

export async function createUserWithState(input: NewUser, now: Date = new Date()): Promise<UserDoc> {
  const doc: UserDoc = {
    _id: new ObjectId(),
    email: input.email,
    emailLower: input.email.toLowerCase(),
    authProvider: input.authProvider,
    displayName: input.displayName,
    profilePhotoKey: null,
    units: "lb",
    timezone: input.timezone,
    reminderTime: null,
    eulaAcceptedAt: now,
    createdAt: now,
  };
  if (input.appleSub !== undefined) doc.appleSub = input.appleSub;
  if (input.passwordHash !== undefined) doc.passwordHash = input.passwordHash;
  await (await users()).insertOne(doc);
  await (await gamificationStates()).insertOne({
    _id: new ObjectId(),
    userId: doc._id,
    currentStreak: 0,
    longestStreak: 0,
    totalXP: 0,
    level: SpecConstants.startingLevel,
    shields: 0,
    lastCountedDayKey: null,
    earnedAchievementIds: [],
    recomputedAt: now,
  });
  return doc;
}

export async function findUserById(userId: string): Promise<UserDoc | null> {
  if (!ObjectId.isValid(userId)) return null;
  return (await users()).findOne({ _id: new ObjectId(userId) });
}
