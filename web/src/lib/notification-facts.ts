// SPEC: T033 — gathers the facts the eligibility functions decide on, per user, from the real collections; records each send
// in `notificationLog` so "already sent today" is a fact, not a guess. Called by the cron route. A1: a planned day is one of the
// plan's trainingWeekdays. A7: the user's toggles ride along as `prefs`.
import { ObjectId } from "mongodb";
import { getDb, pauses, posts, pushTokens, sessions } from "@/lib/db";
import type { NotificationPrefs } from "@/lib/documents";
import { dayKeyFor, isoWeekday } from "@/lib/engine/day-key";
import type { ReminderFacts, StreakRiskFacts } from "@/lib/notification-eligibility";
import { findPlan, isPlannedWeekday } from "@/lib/plans";
import { TimeUnits } from "@/lib/time-units";
import { notificationPrefsOf } from "@/lib/users";
import { SpecConstants } from "@/generated/spec-constants";

interface NotificationLogDoc {
  _id: ObjectId;
  userId: ObjectId;
  kind: string;
  dayKey: string;
  sentAt: Date;
}

export async function notificationLog() {
  return (await getDb()).collection<NotificationLogDoc>("notificationLog");
}

function localClock(now: Date, timezone: string): { time: string; minuteOfDay: number } {
  const parts = new Intl.DateTimeFormat("en-US", { timeZone: timezone, hourCycle: "h23", hour: "2-digit", minute: "2-digit" }).formatToParts(now);
  const hour = Number(parts.find((part) => part.type === "hour")?.value ?? "0");
  const minute = Number(parts.find((part) => part.type === "minute")?.value ?? "0");
  return { time: `${String(hour).padStart(SpecConstants.initialsMaxLetters, "0")}:${String(minute).padStart(SpecConstants.initialsMaxLetters, "0")}`, minuteOfDay: hour * TimeUnits.minutesPerHour + minute };
}

async function usualPostMinute(userId: ObjectId, timezone: string): Promise<number | null> {
  const recent = await (await posts()).find({ userId, deletedAt: null }, { projection: { createdAt: 1 } }).sort({ createdAt: -1 }).limit(SpecConstants.usualPostTimeSampleSize).toArray();
  if (recent.length === 0) return null;
  const minutes = recent.map((post) => localClock(post.createdAt, timezone).minuteOfDay).sort((left, right) => left - right);
  return minutes[Math.floor(minutes.length / SpecConstants.initialsMaxLetters)] ?? null;
}

type NotifiableUser = { _id: ObjectId; timezone: string; reminderTime: string | null; notificationPrefs?: NotificationPrefs };

export async function gatherFacts(user: NotifiableUser, streak: number, now: Date): Promise<{ reminder: ReminderFacts; risk: StreakRiskFacts; dayKey: string }> {
  const dayKey = dayKeyFor(now, user.timezone);
  const clock = localClock(now, user.timezone);
  const [plan, todaySessions, todayPosts, pause, tokens, log] = await Promise.all([
    findPlan(user._id),
    (await sessions()).find({ userId: user._id, dayKey, status: "completed" }).toArray(),
    (await posts()).countDocuments({ userId: user._id, dayKey, deletedAt: null }),
    (await pauses()).findOne({ userId: user._id, startDay: { $lte: dayKey }, endDay: { $gt: dayKey } }),
    (await pushTokens()).countDocuments({ userId: user._id }),
    (await notificationLog()).find({ userId: user._id, dayKey }).toArray(),
  ]);
  const base = { paused: pause !== null, hasPushToken: tokens > 0, postedToday: todayPosts > 0, prefs: notificationPrefsOf(user) };
  return {
    dayKey,
    reminder: { ...base, reminderTime: user.reminderTime, localTime: clock.time, isPlannedDay: isPlannedWeekday(plan, isoWeekday(dayKey)), workoutDoneToday: todaySessions.some((session) => session.workoutKind !== "cardio"), alreadySentToday: log.some((entry) => entry.kind === "reminder") },
    risk: { ...base, currentStreak: streak, alreadySentToday: log.some((entry) => entry.kind === "streakRisk"), localMinuteOfDay: clock.minuteOfDay, usualPostMinuteOfDay: await usualPostMinute(user._id, user.timezone) },
  };
}

export async function recordSend(userId: ObjectId, kind: string, dayKey: string, now: Date): Promise<void> {
  await (await notificationLog()).insertOne({ _id: new ObjectId(), userId, kind, dayKey, sentAt: now });
}
