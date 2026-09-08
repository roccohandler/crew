"use client";
// SPEC: S01 — a stale (> a day) in-progress session triggers the stale-session prompt: keep going or discard; nothing is counted
// until it is completed (V32), and a discard never touches XP. Web twin of ios Features/Home/StaleSessionPrompt. T042
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { patchSession } from "@/lib/api-client";

export function StaleSessionPrompt({ id, workoutName, timezone }: { id: string; workoutName: string; timezone: string }) {
  const router = useRouter();
  const [busy, setBusy] = useState(false);
  const discard = async () => {
    setBusy(true);
    await patchSession(id, { timezone, status: "discarded" }).catch(() => undefined);
    router.refresh();
  };
  return (
    <section className="card stack stack--tight" aria-label="Still working out?">
      <h2>Still working out?</h2>
      <p className="muted">{workoutName} has been open since yesterday. Keep going, or let it go — nothing is lost either way.</p>
      <div className="row row--wrap">
        <Link className="button button--primary" href={`/session/${id}`}>Keep going</Link>
        <button type="button" className="button button--secondary" disabled={busy} onClick={discard}>Discard it</button>
      </div>
    </section>
  );
}
