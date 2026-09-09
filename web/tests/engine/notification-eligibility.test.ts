// SPEC: T033 (Verify: unit) · 8.3 Notification eligibility: reminder / streak-risk / digest conditions (+ smart-mute) · A7: each
// kind is silenced by its own toggle.
import { describe, expect, it } from "vitest";
import { crewActivityDue, digestDue, reminderDue, streakRiskDue } from "@/lib/notification-eligibility";

const allOn = { workoutReminder: true, streakRisk: true, crewActivity: true };
const reminder = { reminderTime: "07:00", localTime: "07:00", isPlannedDay: true, workoutDoneToday: false, postedToday: false, paused: false, hasPushToken: true, alreadySentToday: false, prefs: allOn };

describe("notification eligibility", () => {
  it("reminder fires at the chosen time on a planned day, never when paused, done, rest, unset, already sent, or toggled off", () => {
    expect(reminderDue(reminder)).toBe(true);
    expect(reminderDue({ ...reminder, localTime: "07:01" })).toBe(false);
    expect(reminderDue({ ...reminder, paused: true })).toBe(false);
    expect(reminderDue({ ...reminder, workoutDoneToday: true })).toBe(false);
    expect(reminderDue({ ...reminder, isPlannedDay: false })).toBe(false);
    expect(reminderDue({ ...reminder, reminderTime: null })).toBe(false);
    expect(reminderDue({ ...reminder, alreadySentToday: true })).toBe(false);
    expect(reminderDue({ ...reminder, hasPushToken: false })).toBe(false);
    expect(reminderDue({ ...reminder, prefs: { ...allOn, workoutReminder: false } })).toBe(false);
    expect(reminderDue({ ...reminder, prefs: { ...allOn, streakRisk: false, crewActivity: false } })).toBe(true); // the other toggles are not its business
  });

  it("streak-risk nudges once at the usual time only when a live streak has nothing posted, and only while its toggle is on", () => {
    const risk = { currentStreak: 12, postedToday: false, paused: false, hasPushToken: true, alreadySentToday: false, localMinuteOfDay: 20 * 60, usualPostMinuteOfDay: 20 * 60, prefs: allOn };
    expect(streakRiskDue(risk)).toBe(true);
    expect(streakRiskDue({ ...risk, localMinuteOfDay: 19 * 60 })).toBe(false);
    expect(streakRiskDue({ ...risk, postedToday: true })).toBe(false);
    expect(streakRiskDue({ ...risk, currentStreak: 0 })).toBe(false);
    expect(streakRiskDue({ ...risk, usualPostMinuteOfDay: null })).toBe(false);
    expect(streakRiskDue({ ...risk, paused: true })).toBe(false);
    expect(streakRiskDue({ ...risk, prefs: { ...allOn, streakRisk: false } })).toBe(false);
  });

  it("crew activity: a reaction on your post buzzes; a crew-mate's post never nudges; mute or the toggle silences", () => {
    const reaction = { hasPushToken: true, muted: false, isOwnPost: true, kind: "reaction" as const, prefs: allOn };
    expect(crewActivityDue(reaction)).toBe(true);
    expect(crewActivityDue({ ...reaction, isOwnPost: false, kind: "post" })).toBe(false);
    expect(crewActivityDue({ ...reaction, muted: true })).toBe(false);
    expect(crewActivityDue({ ...reaction, prefs: { ...allOn, crewActivity: false } })).toBe(false);
  });

  it("digests never fire", () => {
    expect(digestDue()).toBe(false);
  });
});
