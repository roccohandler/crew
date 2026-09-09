"use client";
// SPEC: Flow 6 — posts drop into the chat as cards; system lines; tombstoned messages; reactions (🔥 💪 👏 😂 ❤️) with a visible
// React row (6.7); the COMEBACK banner (V39). A6: one summary line under the author (item.post.summary); A5/E9: a "…" menu with
// Report post / Block {name} on others' posts. Mirrors ios StreamList + PostCard + MessageRow.
import { useState } from "react";
import { PostMenu } from "@/components/PostMenu";
import type { MemberDot } from "@/lib/crew-stream";
import type { StreamItem } from "@/lib/api-client-crew";
import { mealTagEmoji, type MealTag } from "@/lib/engine/meal-tag";
import { SpecConstants } from "@/generated/spec-constants";

export interface Moderation { onReport: (postId: string) => Promise<void>; onBlock: (userId: string) => Promise<void> }

function PostCard({ item, author, myUserId, onReact, moderation }: { item: StreamItem; author: string; myUserId: string; onReact: (emoji: string) => void; moderation: Moderation }) {
  const [open, setOpen] = useState(false);
  const grouped = new Map<string, string[]>();
  for (const reaction of item.reactions ?? []) grouped.set(reaction.emoji, [...(grouped.get(reaction.emoji) ?? []), reaction.userId]);
  const postId = item.post?.id ?? "";
  return (
    <article className="card stack stack--tight">
      {item.comeback ? <p className="ember-text whisper">Comeback 🎉</p> : null}
      <div className="row row--between">
        <span className="whisper">{author.toUpperCase()}</span>
        <span className="row">
          <span className="whisper">{item.post?.type === "workout" ? "Workout ✓" : item.post?.mealTag ? mealTagEmoji[item.post.mealTag as MealTag] : ""}</span>
          {item.userId === myUserId ? null : <PostMenu authorName={author} onReport={() => moderation.onReport(postId)} onBlock={() => moderation.onBlock(item.userId)} />}
        </span>
      </div>
      {item.post?.summary ? <p className="muted">{item.post.summary}</p> : null}
      {item.post?.photoKey ? <img className="photo" src={`/api/v1/photos/${item.post.photoKey}`} alt="" /> : null}
      {item.post?.caption ? <p>{item.post.caption}</p> : null}
      <div className="row">
        {[...grouped.entries()].map(([emoji, who]) => <span key={emoji} className="chip" aria-pressed={who.includes(myUserId)}>{emoji} {who.length}</span>)}
        <button type="button" className="button button--text" onClick={() => setOpen(!open)} aria-expanded={open}>React</button>
      </div>
      {open ? <div className="row" role="group" aria-label="Reactions">{SpecConstants.reactionEmojis.map((emoji) => <button key={emoji} type="button" className="toggle" onClick={() => { onReact(emoji); setOpen(false); }} aria-label={`React ${emoji}`}>{emoji}</button>)}</div> : null}
    </article>
  );
}

export function StreamList({ items, members, myUserId, onReact, moderation }: { items: StreamItem[]; members: MemberDot[]; myUserId: string; onReact: (postId: string, emoji: string) => void; moderation: Moderation }) {
  const name = (userId: string) => (userId === myUserId ? "You" : members.find((member) => member.id === userId)?.displayName ?? "Someone");
  return (
    <div className="stack stack--tight" aria-live="polite">
      {items.map((item) => {
        const key = item.id ?? item.post?.id ?? item.at;
        if (item.kind === "post" && item.post) return <PostCard key={key} item={item} author={name(item.userId)} myUserId={myUserId} onReact={(emoji) => onReact(item.post!.id, emoji)} moderation={moderation} />;
        if (item.kind === "system") return <p key={key} className="whisper center">{item.body}</p>;
        return <div key={key} className="stack" style={{ gap: 0 }}><span className="whisper">{name(item.userId)} · {new Date(item.at).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })}</span><p className={item.deleted ? "missed" : ""}>{item.deleted ? "Message deleted" : item.body}</p></div>;
      })}
    </div>
  );
}
