// SPEC: S16 History/Journal on web — every post forever (Flow 6: the feed shows 7 days, the journal keeps everything); editing a
// past session never alters XP (the copy says so); deleted posts absent, logs present (E3). A6: grouped by day under readable
// labels (Today · Yesterday · Mon · Mon Sep 8) inside week headers (This week · Last week · Week of Sep 1), one summary line
// per post, an empty state that invites. Reached from Progress (S15 → S16). Web twin of ios JournalScreen. T040
import { ObjectId } from "mongodb";
import Link from "next/link";
import { redirect } from "next/navigation";
import { EmptyState } from "@/components/EmptyState";
import { JournalDay } from "@/app/(app)/journal/JournalDay";
import { dayKeysOf, summaryFromSession, weeksOf } from "@/app/(app)/journal/rows";
import { posts, sessions } from "@/lib/db";
import { dayKeyFor, weekKeyFor } from "@/lib/engine/day-key";
import { weekHeader } from "@/lib/engine/day-label";
import { findPlan } from "@/lib/plans";
import { readSession } from "@/lib/session";

export default async function JournalPage() {
  const session = await readSession();
  if (session.kind !== "signedIn") redirect("/");
  const userId = new ObjectId(session.user.id);
  const docs = await (await posts()).find({ userId, deletedAt: null }).sort({ createdAt: -1 }).toArray();
  if (docs.length === 0) return <EmptyState title="Your first post lands here." line="Workouts and meals stack up day by day." ctaTitle="Post something" href="/post" />;
  // SPEC: A6 — a workout post without a server summary reads the same line computed from its session
  const sessionIds = docs.flatMap((post) => (post.sessionId ? [post.sessionId] : []));
  const [plan, sessionDocs] = await Promise.all([findPlan(userId), (await sessions()).find({ _id: { $in: sessionIds } }).toArray()]);
  const sessionLines = new Map(sessionDocs.map((doc) => [doc._id.toHexString(), summaryFromSession(doc, session.user.distanceUnit)]));
  const todayKey = dayKeyFor(new Date(), session.user.timezone);
  const thisWeek = weekKeyFor(todayKey);
  return (
    <div className="stack">
      <h1>Journal</h1>
      <p className="muted">Everything you posted, kept. Editing a past workout changes your stats, never your XP or streak.</p>
      <Link className="button button--text" href="/progress">Back to Progress</Link>
      {weeksOf(dayKeysOf(docs)).map((week) => (
        <section key={week.weekKey} className="stack" aria-label={weekHeader(week.weekKey, thisWeek)}>
          <h2 className="whisper">{weekHeader(week.weekKey, thisWeek)}</h2>
          {week.dayKeys.map((dayKey) => (
            <JournalDay key={dayKey} dayKey={dayKey} todayKey={todayKey} dayPosts={docs.filter((post) => post.dayKey === dayKey)} trainingWeekdays={plan?.trainingWeekdays ?? []} timeZone={session.user.timezone} sessionLines={sessionLines} />
          ))}
        </section>
      ))}
    </div>
  );
}
