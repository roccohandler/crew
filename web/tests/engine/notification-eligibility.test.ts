// SPEC: T033 (Verify: unit) · 8.3 Notification eligibility: reminder / streak-risk / digest conditions (+ smart-mute).
import { describe, expect, it } from "vitest";
import { crewActivityDue, digestDue, reminderDue, streakRiskDue } from "@/lib/notification-eligibility";

const reminder = { reminderTime: "07:00", localTime: "07:00", isPlannedDay: true, workoutDoneToday: false, postedToday: false, paused: false, hasPushToken: true, alreadySentToday: false };

describe("notification eligibility", () => {
  it("reminder fires at the chosen time on a planned day, never when paused, done, rest, unset, or already sent", () => {
    expect(reminderDue(reminder)).toBe(true);
    expect(reminderDue({ ...reminder, localTime: "07:01" })).toBe(false);
    expect(reminderDue({ ...reminder, paused: true })).toBe(false);
    expect(reminderDue({ ...reminder, workoutDoneToday: true })).toBe(false);
    expect(reminderDue({ ...reminder, isPlannedDay: false })).toBe(false);
    expect(reminderDue({ ...reminder, reminderTime: null })).toBe(false);
    expect(reminderDue({ ...reminder, alreadySentToday: true })).toBe(false);
    expect(reminderDue({ ...reminder, hasPushToken: false })).toBe(false);
  });

  it("streak-risk nudges once at the usual time only when a live streak has nothing posted", () => {
    const risk = { currentStreak: 12, postedToday: false, paused: false, hasPushToken: true, alreadySentToday: false, localMinuteOfDay: 20 * 60, usualPostMinuteOfDay: 20 * 60 };
    expect(streakRiskDue(risk)).toBe(true);
    expect(streakRiskDue({ ...risk, localMinuteOfDay: 19 * 60 })).toBe(false);
    expect(streakRiskDue({ ...risk, postedToday: true })).toBe(false);
    expect(streakRiskDue({ ...risk, currentStreak: 0 })).toBe(false);
    expect(streakRiskDue({ ...risk, usualPostMinuteOfDay: null })).toBe(false);
    expect(streakRiskDue({ ...risk, paused: true })).toBe(false);
  });

  it("crew activity: a reaction on your post buzzes; a crew-mate's post never nudges; mute silences", () => {
    expect(crewActivityDue({ hasPushToken: true, muted: false, isOwnPost: true, kind: "reaction" })).toBe(true);
    expect(crewActivityDue({ hasPushToken: true, muted: false, isOwnPost: false, kind: "post" })).toBe(false);
    expect(crewActivityDue({ hasPushToken: true, muted: true, isOwnPost: true, kind: "reaction" })).toBe(false);
  });

  it("digests never fire", () => {
    expect(digestDue()).toBe(false);
  });
});
