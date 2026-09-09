"use client";
// SPEC: Flow 6 — [Start a Crew] → name + emoji → invite link; A5: a crew of one shows an open invite card ("Only your crew
// sees this.") with Invite friends (navigator.share) and Copy link / Text it fallbacks (r-crew R7); crews of two or more keep
// the collapsed panel; S13 Captain tools only for the Captain (regenerate link, remove members), "crew full" explicit; leave.
// Mirrors ios InviteScreen + CreateCrewScreen.
import { useState, useSyncExternalStore } from "react";
import type { MemberDot } from "@/lib/crew-stream";
import { leaveOrRemove, regenerateInvite, type CrewSummary } from "@/lib/api-client-crew";
import { SpecConstants } from "@/generated/spec-constants";

const EMOJIS = ["🌅", "🔥", "💪", "🏋️", "🌊", "⚡️", "🦍", "🥑"];

function CreateForm({ onCreate }: { onCreate: (name: string, emoji: string) => Promise<void> }) {
  const [name, setName] = useState("");
  const [emoji, setEmoji] = useState(EMOJIS[0] ?? "🌅");
  return (
    <form className="stack" onSubmit={(event) => { event.preventDefault(); void onCreate(name.trim(), emoji); }}>
      <h1>Name your crew</h1>
      <label className="field"><span>Name</span><input value={name} maxLength={SpecConstants.crewNameMaxChars} onChange={(event) => setName(event.target.value)} placeholder="Dawn Patrol" required /></label>
      <div className="row" role="group" aria-label="Emoji">{EMOJIS.map((option) => <button key={option} type="button" className="toggle" aria-pressed={emoji === option} onClick={() => setEmoji(option)}>{option}</button>)}</div>
      <button type="submit" className="button button--primary" disabled={name.trim().length === 0}>Start a crew</button>
    </form>
  );
}

// SPEC: A5 (r-crew R7/R8) — "Invite friends" opens the browser's share sheet where one exists (HTTPS + a gesture); without one,
// "Copy link" and "Text it" (sms:) carry the same pre-filled message. After a completed share: one quiet line, then silence.
const noSubscription = () => () => undefined;
const shareSheetExists = () => typeof navigator.share === "function";
const noShareSheet = () => false;

function ShareControls({ crew }: { crew: CrewSummary }) {
  const canShare = useSyncExternalStore(noSubscription, shareSheetExists, noShareSheet); // the server never has one; the browser answers after hydration
  const [copied, setCopied] = useState(false);
  const [sent, setSent] = useState(false);
  const link = crew.inviteLink ?? "";
  const message = `Join my crew on Crew: ${crew.name} ${crew.emoji}`;
  const copy = async () => { await navigator.clipboard.writeText(link); setCopied(true); };
  const share = async () => { try { await navigator.share({ title: message, text: message, url: link }); setSent(true); } catch { /* cancelled: no message (r-crew R8) */ } };
  return (
    <div className="stack stack--tight">
      {canShare ? <button type="button" className="button button--primary" onClick={share}>{sent ? "Invite more" : "Invite friends"}</button> : <button type="button" className="button button--primary" onClick={copy}>{copied ? "Link copied" : "Copy link"}</button>}
      {canShare ? <button type="button" className="button button--text" onClick={copy}>{copied ? "Link copied" : "Copy link"}</button> : <a className="button button--secondary" href={`sms:?&body=${encodeURIComponent(`${message} ${link}`)}`}>Text it</a>}
      {sent ? <p className="muted" role="status">{"Link sent. We'll show them here when they join."}</p> : null}
    </div>
  );
}

function InviteBody({ crew, members, onChanged }: { crew: CrewSummary; members: MemberDot[]; onChanged: () => Promise<void> }) {
  const isCaptain = members.some((member) => member.isCaptain && crew.captainId === member.id && crew.inviteLink !== null);
  return (
    <div className="stack stack--tight">
      {members.length >= SpecConstants.crewMaxMembers ? <p>Crew full — {SpecConstants.crewMaxMembers} is the max.</p> : crew.inviteLink ? <ShareControls crew={crew} /> : <p className="muted">Ask your Captain for the link.</p>}
      {isCaptain ? <button type="button" className="button button--secondary" onClick={async () => { await regenerateInvite(crew.id); await onChanged(); }}>Regenerate link (old one dies)</button> : null}
      {isCaptain ? members.filter((member) => !member.isCaptain).map((member) => <div key={member.id} className="row row--between"><span>{member.displayName}</span><button type="button" className="button button--text danger" onClick={async () => { await leaveOrRemove(crew.id, member.id); await onChanged(); }}>Remove</button></div>) : null}
      <button type="button" className="button button--text danger" onClick={async () => { await leaveOrRemove(crew.id); await onChanged(); }}>Leave crew</button>
    </div>
  );
}

export function CrewInvitePanel({ crew, members, onCreate, onChanged }: { crew: CrewSummary | null; members: MemberDot[]; onCreate: (name: string, emoji: string) => Promise<void>; onChanged: () => Promise<void> }) {
  const [open, setOpen] = useState(false);
  if (crew === null) return <CreateForm onCreate={onCreate} />;
  // SPEC: A5 — a crew of one: the invite card sits open under the strip with the privacy promise (Flow 6: straight to the invite)
  if (members.length < SpecConstants.crewMinMembers) {
    return (
      <section className="card stack stack--tight" aria-label="Invite">
        <p>Only your crew sees this.</p>
        <p className="muted">Send the link and your first post lands here for them.</p>
        <InviteBody crew={crew} members={members} onChanged={onChanged} />
      </section>
    );
  }
  return (
    <details className="card" open={open} onToggle={(event) => setOpen((event.target as HTMLDetailsElement).open)}>
      <summary>Invite · {members.length}/{SpecConstants.crewMaxMembers}</summary>
      <InviteBody crew={crew} members={members} onChanged={onChanged} />
    </details>
  );
}
