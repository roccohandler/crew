"use client";
// SPEC: Flow 3 mobility holds — tap → countdown → auto-check; per-side holds run twice (perSideHoldRepeats); no reps, no weight,
// ever. Mirrors ios MobilityHoldRow.
import { useEffect, useState } from "react";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

export function HoldRow({ name, seconds, perSide, done, onFinished }: { name: string; seconds: number; perSide: boolean; done: boolean; onFinished: () => void }) {
  const [remaining, setRemaining] = useState<number | null>(null);
  const [sidesLeft, setSidesLeft] = useState(perSide ? SpecConstants.perSideHoldRepeats : 1);

  useEffect(() => {
    if (remaining === null) return;
    const timer = window.setTimeout(() => {
      if (remaining > 1) { setRemaining(remaining - 1); return; }
      if (sidesLeft > 1) { setSidesLeft(sidesLeft - 1); setRemaining(seconds); return; }
      setRemaining(null);
      onFinished();
    }, TimeUnits.msPerSecond);
    return () => window.clearTimeout(timer);
  }, [remaining, sidesLeft, seconds, onFinished]);

  const label = done ? `${seconds}s${perSide ? " each" : ""}` : remaining === null ? `${seconds}s${perSide ? " each" : ""}` : `${remaining}s${perSide && sidesLeft > 1 ? " · side 1" : ""}`;
  return (
    <button type="button" className="row row--between button--text" disabled={done} onClick={() => setRemaining(remaining === null ? seconds : null)} aria-label={`${name}, ${seconds} seconds${perSide ? " each side" : ""}${done ? ", done" : ""}`}>
      <span>{name}</span>
      <span className="muted">{label} {done ? "✓" : remaining === null ? "▶" : "⏸"}</span>
    </button>
  );
}
