// SPEC: S16 History/Journal on web — every post forever (Flow 6: the feed shows 7 days, the journal keeps everything); editing a
// past session never alters XP (the copy says so); deleted posts absent, logs present (E3). Newest first; delete yours anytime.
// Reached from Progress (S15 → S16). Web twin of ios JournalScreen. T040 (web half completed 2026-09-05)
import { ObjectId } from "mongodb";
import Link from "next/link";
import { redirect } from "next/navigation";
import { DeletePostButton } from "@/components/DeletePostButton";
import { EmptyState } from "@/components/EmptyState";
import { posts } from "@/lib/db";
import { mealTagEmoji, type MealTag } from "@/lib/engine/meal-tag";
import { readSession } from "@/lib/session";

export default async function JournalPage() {
  const session = await readSession();
  if (session.kind !== "signedIn") redirect("/");
  const docs = await (await posts()).find({ userId: new ObjectId(session.user.id), deletedAt: null }).sort({ createdAt: -1 }).toArray();
  if (docs.length === 0) return <EmptyState title="Your journal starts with one post" line="Every workout and every plate lands here, forever." ctaTitle="Post something" href="/post" />;
  return (
    <div className="stack">
      <h1>Journal</h1>
      <p className="muted">Everything you posted, kept. Editing a past workout changes your stats, never your XP or streak.</p>
      <Link className="button button--text" href="/progress">Back to Progress</Link>
      {docs.map((post) => (
        <article key={post._id.toHexString()} className="card stack stack--tight">
          <p className="whisper">{post.dayKey}{post.earlierToday ? " · earlier that day" : ""}</p>
          {post.photoKey ? <img className="photo" src={`/api/v1/photos/${post.photoKey}`} alt={post.caption || "Your plate"} /> : null}
          <p>{post.type === "workout" ? "Workout ✓" : (post.caption || (post.mealTag ? mealTagEmoji[post.mealTag as MealTag] : "🍽"))}</p>
          <DeletePostButton id={post._id.toHexString()} />
        </article>
      ))}
    </div>
  );
}
