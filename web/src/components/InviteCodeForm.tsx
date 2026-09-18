"use client";
// SPEC: A21.3 / W4 (owner-approved 2026-09-17) — the hero's "I have an invite" used to route to /onboarding with an EMPTY token
// (docs/MVP_STATE_REPORT.md); now it asks for the code. Paste the code or the whole link; the landing page (/join/[token])
// does the rest: preview, dead/full states, the phone's App Store button or Continue on web. Twin of the iOS InviteCodeEntry.
import { useRouter } from "next/navigation";
import { useState } from "react";
import { inviteToken } from "@/lib/invite-code";

export function InviteCodeForm() {
  const router = useRouter();
  const [raw, setRaw] = useState("");
  const [error, setError] = useState<string | null>(null);
  const submit = (event: React.FormEvent) => {
    event.preventDefault();
    const token = inviteToken(raw);
    if (token === null) { setError("That doesn't look like an invite code. Paste the code or the whole link."); return; }
    router.push(`/join/${encodeURIComponent(token)}`);
  };
  return (
    <form className="stack" onSubmit={submit} noValidate>
      <label className="field"><span>Invite code or link</span><input type="text" autoComplete="off" autoCapitalize="none" spellCheck={false} value={raw} onChange={(event) => { setRaw(event.target.value); setError(null); }} required /></label>
      {error ? <p className="danger" role="alert">{error}</p> : null}
      <button type="submit" className="button button--primary">Find my crew</button>
    </form>
  );
}
