"use client";
// SPEC: A28 (c) (owner-approved 2026-09-19) — a mobility hold is a CHECK, never a countdown: tap it and it is done. No seconds are
// shown and nothing counts (holdSeconds stays in the seed as data read by no screen). No reps, no weight, ever. Mirrors the iOS
// checklist's row (MobilityChecklist.swift); the web keeps its own layout until its parity session (docs/debt.md).
export function HoldRow({ name, done, onFinished }: { name: string; done: boolean; onFinished: () => void }) {
  return (
    <button type="button" className="row row--between button--text" disabled={done} onClick={onFinished} aria-pressed={done} aria-label={`${name}${done ? ", done" : ""}`}>
      <span>{name}</span>
      <span className="muted">{done ? "✓" : "○"}</span>
    </button>
  );
}
