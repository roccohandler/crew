"use client";
// SPEC: A2 (owner-directed 2026-09-08) · plan 2.6 — a cardio row inside a workout: {Activity} · target {min} min · minutes
// stepper (±cardioMinutesStep within cardioMinutesMin..Max, pre-filled with the target) · optional distance in the user's units
// (km for kg, mi for lb; stored as whole meters) · Done → the set is done with holdSeconds = minutes × 60 and distanceMeters.
// Skippable like any exercise. No pace, effort, calories, heart rate, goals or targets — ever. Twin: ios CardioRow.swift.
// CardioFields (minutes + distance + the action) is the same block the standalone log (/log-cardio) renders.
import { useState } from "react";
import { Stepper } from "@/components/SetRow";
import { distanceText } from "@/lib/engine/session-summary-line";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

export const unitLabel = (distanceUnit: "mi" | "km") => distanceUnit; // A9: the label IS the stored preference now

// SPEC: A2 — distance is typed in the user's unit and stored as whole meters (metersPerKilometer / metersPerMile), never above
// cardioDistanceMaxMeters; blank = no distance (R7: never "no distance recorded")
export function metersFrom(text: string, distanceUnit: "mi" | "km"): number | null {
  const value = Number(text.trim());
  if (text.trim() === "" || !Number.isFinite(value) || value <= 0) return null;
  const perUnit = distanceUnit === "km" ? SpecConstants.metersPerKilometer : SpecConstants.metersPerMile;
  return Math.min(SpecConstants.cardioDistanceMaxMeters, Math.round(value * perUnit));
}

// SPEC: A2 — minutes live inside cardioMinutesMin..cardioMinutesMax; invalid values are impossible
const clampMinutes = (minutes: number) => Math.min(SpecConstants.cardioMinutesMax, Math.max(SpecConstants.cardioMinutesMin, minutes));

export function CardioFields({ name, defaultMinutes, distanceUnit, action, disabled, onSubmit }: { name: string; defaultMinutes: number; distanceUnit: "mi" | "km"; action: string; disabled: boolean; onSubmit: (seconds: number, distanceMeters: number | null) => void }) {
  const [minutes, setMinutes] = useState(clampMinutes(defaultMinutes));
  const [distance, setDistance] = useState("");
  return (
    <div className="stack stack--tight">
      <Stepper label={`${minutes} min`} ariaLabel={`${name} minutes`} onStep={(direction) => setMinutes(clampMinutes(minutes + direction * SpecConstants.cardioMinutesStep))} />
      <label className="field field--short">
        <span>Distance ({unitLabel(distanceUnit)}, optional)</span>
        <input type="number" inputMode="decimal" min={0} step="any" value={distance} onChange={(event) => setDistance(event.target.value)} />
      </label>
      <p className="whisper">{"Skip it if you don't know."}</p>
      <button type="button" className="button button--primary" disabled={disabled} onClick={() => onSubmit(minutes * TimeUnits.secondsPerMinute, metersFrom(distance, distanceUnit))}>{action}</button>
    </div>
  );
}

export function CardioRow({ name, seconds, distanceMeters, distanceUnit, done, onDone }: { name: string; seconds: number; distanceMeters: number | null; distanceUnit: "mi" | "km"; done: boolean; onDone: (seconds: number, distanceMeters: number | null) => void }) {
  const minutes = Math.round(seconds / TimeUnits.secondsPerMinute); // rounded like the server's summary line
  const distance = done && distanceMeters !== null ? ` · ${distanceText(distanceMeters, distanceUnit)}` : "";
  return (
    <div className="stack stack--tight">
      <p className="muted">{name} · {minutes} min{distance}{done ? " ✓" : ""}</p>
      {done ? null : <CardioFields name={name} defaultMinutes={minutes} distanceUnit={distanceUnit} action="Done" disabled={false} onSubmit={onDone} />}
    </div>
  );
}
