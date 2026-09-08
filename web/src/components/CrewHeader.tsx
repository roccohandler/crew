"use client";
// SPEC: Flow 6 — "DAWN PATROL 🌅 4/5 today" (CREW PULSE, V37) + the member strip (streak + today-dot + ⏸) + the chat composer
// (E20 ≤ 1,000 chars). Mirrors ios MemberStrip + the CrewScreen composer.
import { useState } from "react";
import type { CrewSummary, StreamReply } from "@/lib/api-client-crew";
import { SpecConstants } from "@/generated/spec-constants";

export function CrewHeader({ crew, feed }: { crew: CrewSummary; feed: StreamReply | null }) {
  const full = feed !== null && feed.pulse.total > 0 && feed.pulse.posted === feed.pulse.total;
  return (
    <div className="stack stack--tight">
      <div className="row row--between">
        <h1>{crew.name} {crew.emoji}</h1>
        <span className={full ? "ember-text" : "muted"} aria-label={`${feed?.pulse.posted ?? 0} of ${feed?.pulse.total ?? 0} posted today`}>{feed?.pulse.posted ?? 0}/{feed?.pulse.total ?? 0} today</span>
      </div>
      <div className="members" aria-label="Members">
        {feed?.members.map((member) => (
          <div key={member.id} className="member" aria-label={`${member.displayName}, streak ${member.streak}, ${member.paused ? "paused" : member.postedToday ? "posted today" : "not yet today"}`}>
            <span className="avatar" aria-hidden="true">{member.displayName.slice(0, 1)}<span className={member.postedToday ? "avatar__dot avatar__dot--posted" : "avatar__dot"} /></span>
            <span className="whisper" aria-hidden="true">{member.paused ? "⏸" : member.streak}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

export function Composer({ onSend }: { onSend: (body: string) => Promise<void> }) {
  const [draft, setDraft] = useState("");
  const send = async () => {
    const body = draft.trim().slice(0, SpecConstants.chatMessageMaxChars);
    if (body.length === 0) return;
    setDraft("");
    await onSend(body);
  };
  return (
    <div className="composer">
      <input aria-label="Message" value={draft} maxLength={SpecConstants.chatMessageMaxChars} onChange={(event) => setDraft(event.target.value)} onKeyDown={(event) => { if (event.key === "Enter") void send(); }} placeholder="Say something" />
      <button type="button" className="button button--primary" style={{ width: "auto" }} onClick={send} disabled={draft.trim().length === 0}>Send</button>
    </div>
  );
}
