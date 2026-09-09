"use client";
// SPEC: Flow 6 — "DAWN PATROL 🌅 4/5 today" (CREW PULSE, V37) + the member strip (streak + today-dot + ⏸) + the chat composer
// (E20 ≤ 1,000 chars). A5: the header is pinned at the top of the tab; A8: the pulse never reads "0/n" — "No posts yet today".
// E1/A7: a member's profile photo fills the avatar when a key exists, initials until then. Mirrors ios MemberStrip + composer.
import { useState } from "react";
import type { MemberDot } from "@/lib/crew-stream";
import type { CrewSummary, StreamReply } from "@/lib/api-client-crew";
import { SpecConstants } from "@/generated/spec-constants";

// SPEC: E1 — initials on warm gray until a picture is set (up to initialsMaxLetters)
export function initialsOf(displayName: string): string {
  return displayName.split(" ").filter((word) => word.length > 0).map((word) => word.slice(0, 1)).join("").slice(0, SpecConstants.initialsMaxLetters).toUpperCase();
}

// SPEC: A5 · A8 — "{n}/{m} today" when n ≥ 1; "No posts yet today" in secondary ink when n = 0 (a zero is never a verdict)
function Pulse({ pulse }: { pulse: StreamReply["pulse"] | undefined }) {
  if (!pulse || pulse.posted === 0) return <span className="muted">No posts yet today</span>;
  const full = pulse.total > 0 && pulse.posted === pulse.total;
  return <span className={full ? "ember-text" : "muted"} aria-label={`${pulse.posted} of ${pulse.total} posted today`}>{pulse.posted}/{pulse.total} today</span>;
}

function Avatar({ member }: { member: MemberDot }) {
  return (
    <span className="avatar" aria-hidden="true">
      {member.profilePhotoKey ? <img className="avatar__photo" src={`/api/v1/photos/${member.profilePhotoKey}`} alt="" /> : initialsOf(member.displayName)}
      <span className={member.postedToday ? "avatar__dot avatar__dot--posted" : "avatar__dot"} />
    </span>
  );
}

export function CrewHeader({ crew, feed }: { crew: CrewSummary; feed: StreamReply | null }) {
  return (
    <div className="crew-header stack stack--tight">
      <div className="row row--between row--wrap">{/* 6.7: a long crew name and the pulse share a line where they fit; under wide fonts at 375 the pulse drops beneath the name instead of past the edge */}
        <h1>{crew.name} {crew.emoji}</h1>
        <Pulse pulse={feed?.pulse} />
      </div>
      <div className="members" aria-label="Members">
        {feed?.members.map((member) => (
          <div key={member.id} className="member" aria-label={`${member.displayName}, streak ${member.streak}, ${member.paused ? "paused" : member.postedToday ? "posted today" : "not yet today"}`}>
            <Avatar member={member} />
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
