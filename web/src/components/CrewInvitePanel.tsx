"use client";
// SPEC: Flow 6 — [Start a Crew] → name + emoji → invite link (share sheet or copy); S13 Captain tools only for the Captain
// (regenerate link, remove members), "crew full" explicit; leave. Mirrors ios InviteScreen + CreateCrewScreen.
import { useState } from "react";
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

export function CrewInvitePanel({ crew, members, onCreate, onChanged }: { crew: CrewSummary | null; members: MemberDot[]; onCreate: (name: string, emoji: string) => Promise<void>; onChanged: () => Promise<void> }) {
  const [open, setOpen] = useState(false);
  const [copied, setCopied] = useState(false);
  if (crew === null) return <CreateForm onCreate={onCreate} />;
  const isCaptain = members.some((member) => member.isCaptain && crew.captainId === member.id && crew.inviteLink !== null);
  const share = async () => {
    if (!crew.inviteLink) return;
    if (navigator.share) await navigator.share({ title: `Join ${crew.name} on Crew`, url: crew.inviteLink }).catch(() => undefined);
    else { await navigator.clipboard.writeText(crew.inviteLink); setCopied(true); }
  };
  return (
    <details className="card" open={open} onToggle={(event) => setOpen((event.target as HTMLDetailsElement).open)}>
      <summary>Invite · {members.length}/{SpecConstants.crewMaxMembers}</summary>
      <div className="stack stack--tight">
        {members.length >= SpecConstants.crewMaxMembers ? <p>Crew full — {SpecConstants.crewMaxMembers} is the max.</p> : crew.inviteLink ? <button type="button" className="button button--primary" onClick={share}>{copied ? "Link copied" : "Send invite link"}</button> : <p className="muted">Ask your Captain for the link.</p>}
        {isCaptain ? <button type="button" className="button button--secondary" onClick={async () => { await regenerateInvite(crew.id); await onChanged(); }}>Regenerate link (old one dies)</button> : null}
        {isCaptain ? members.filter((member) => !member.isCaptain).map((member) => <div key={member.id} className="row row--between"><span>{member.displayName}</span><button type="button" className="button button--text danger" onClick={async () => { await leaveOrRemove(crew.id, member.id); await onChanged(); }}>Remove</button></div>) : null}
        <button type="button" className="button button--text danger" onClick={async () => { await leaveOrRemove(crew.id); await onChanged(); }}>Leave crew</button>
      </div>
    </details>
  );
}
