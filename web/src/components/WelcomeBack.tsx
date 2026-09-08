"use client";
// SPEC: E4 / S18 — the lapsed user: one warm screen, "Your record still stands", two choices (Keep my plan · Rebuild), zero guilt.
// Web twin of ios Features/Settings/WelcomeBackScreen. The choice is stored on the account so no device asks twice. T042
import { useRouter } from "next/navigation";
import { useState } from "react";
import { updateMe } from "@/lib/api-client-crew";

export function WelcomeBack({ todayKey, longestStreak }: { todayKey: string; longestStreak: number }) {
  const router = useRouter();
  const [busy, setBusy] = useState(false);
  const choose = async (destination: "/home" | "/onboarding") => {
    setBusy(true);
    await updateMe({ welcomeBackAckDay: todayKey }).catch(() => undefined);
    if (destination === "/home") router.refresh();
    else router.push(destination);
  };
  return (
    <section className="stack center" aria-label="Welcome back">
      <h1>Welcome back.</h1>
      <p className="ember-text">Your record still stands.</p>
      {longestStreak > 0 ? <p className="muted">Longest streak: {longestStreak} days. That happened, and it still counts.</p> : null}
      <p className="muted">Your plan is right where you left it.</p>
      <button type="button" className="button button--primary" disabled={busy} onClick={() => choose("/home")}>Keep my plan</button>
      <button type="button" className="button button--secondary" disabled={busy} onClick={() => choose("/onboarding")}>Rebuild</button>
    </section>
  );
}
