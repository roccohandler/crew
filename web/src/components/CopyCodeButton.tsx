"use client";
// SPEC: A21.3 / W4 + the owner's 2026-09-17 addition (Appendix A, "Copy code button on the web landing page") — a friend who
// opened the link on the phone's browser copies the CODE here and pastes it into the app's "I have an invite". The code is the
// crew's inviteToken (the A21.3 GAP reading, owner-confirmed). Clipboard denied or absent (an old WebKit): the code stays
// readable in the line above and the label says so — never a dead end (6.1).
import { useState } from "react";

export function CopyCodeButton({ token }: { token: string }) {
  const [state, setState] = useState<"idle" | "copied" | "manual">("idle");
  const copy = async () => {
    try {
      await navigator.clipboard.writeText(token);
      setState("copied");
    } catch {
      setState("manual");
    }
  };
  const label = state === "copied" ? "Code copied — paste it in the Crew app" : state === "manual" ? "Select the code above and copy it" : "Copy code";
  return <button type="button" className="button button--secondary" onClick={copy} aria-live="polite">{label}</button>;
}
