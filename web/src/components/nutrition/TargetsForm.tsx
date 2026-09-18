"use client";
// SPEC: nutrition addendum §3–§4 (RATIFIED 2026-09-18; Q1: no goal) · E1's one exception — Nutrition targets: the bodyweight (the
// ONLY body stat in the system, in the account's weight unit), the three grams, Recalculate. With no targets yet it is the first-run
// state: one number, one button, and the estimate does the rest. Every number is the user's to overwrite (source → manual); the
// derivation is offered again only by "Recalculate". A carbs floor is a measurement on its own line, never a warning (V60).
// Ink only — no macro fill, no semantic colour. Twin: ios Features/Nutrition/NutritionTargetsScreen.swift.
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { GramFields } from "@/components/nutrition/GramField";
import { Whisper } from "@/components/Whisper";
import { isApiClientError } from "@/lib/api-client";
import { putNutritionTargets } from "@/lib/api-client-nutrition";
import { bodyweightTenthsFrom } from "@/lib/engine/nutrition-targets";
import { weightIn, type WeightUnit } from "@/lib/engine/weight-units";
import type { TargetsResponse } from "@/lib/nutrition-targets-store";
import { SpecConstants } from "@/generated/spec-constants";

function EstimateLines({ targets }: { targets: TargetsResponse }) {
  const estimate = targets.estimate;
  return (
    <div className="stack stack--tight">
      <p className="muted">{targets.source === "derived" ? "Estimated from your bodyweight." : "Set by you."} The estimate at this bodyweight: {estimate.energyKcal} kcal · P {estimate.proteinG} · C {estimate.carbsG} · F {estimate.fatG}.</p>
      {estimate.carbsOverageKcal > 0 ? <p className="muted">Protein and fat alone come to {estimate.carbsOverageKcal} kcal more than the energy estimate, so carbs sit at 0.</p> : null}
      <Link className="button button--text" href="/nutrition/method">How targets are estimated</Link>
    </div>
  );
}

export function TargetsForm({ targets, unit, next }: { targets: TargetsResponse | null; unit: WeightUnit; next: string | null }) {
  const router = useRouter();
  const [weight, setWeight] = useState(targets === null ? "" : String(weightIn(targets.bodyweight, targets.unit, unit)));
  const [grams, setGrams] = useState({ proteinG: targets?.proteinG ?? 0, carbsG: targets?.carbsG ?? 0, fatG: targets?.fatG ?? 0 });
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [saved, setSaved] = useState(false);
  const save = async (manual: boolean) => {
    const tenths = bodyweightTenthsFrom(weight, unit);
    if (tenths === null) return setError(`Type your bodyweight in ${unit}, like ${unit === "kg" ? "80" : "176"}.`);
    setBusy(true);
    setError(null);
    setSaved(false);
    try {
      const reply = await putNutritionTargets({ bodyweight: tenths / SpecConstants.bodyweightEntryScale, unit, ...(manual ? grams : {}) });
      setGrams({ proteinG: reply.targets.proteinG, carbsG: reply.targets.carbsG, fatG: reply.targets.fatG });
      setSaved(next === null);
      if (next !== null) router.push(next);
      router.refresh();
    } catch (caught) {
      setError(isApiClientError(caught) ? caught.message : "Couldn't save that. Try again.");
    }
    setBusy(false);
  };
  return (
    <div className="stack">
      <label className="field field--short"><span>Bodyweight ({unit})</span><input type="text" inputMode="decimal" autoComplete="off" value={weight} onChange={(event) => setWeight(event.target.value)} /></label>
      <p className="whisper">Used for the estimate and nothing else. Only you can see it.</p>
      {targets === null ? null : <GramFields value={grams} max={SpecConstants.macroTargetGramsMax} onChange={setGrams} />}
      {targets === null ? null : <Whisper id="why.protein" />}
      {error ? <p className="notice" role="alert">{error}</p> : null}
      {saved ? <p className="muted" role="status">Saved.</p> : null}
      {targets === null ? <button type="button" className="button button--primary" disabled={busy} onClick={() => void save(false)}>Estimate my targets</button> : null}
      {targets === null ? null : <button type="button" className="button button--primary" disabled={busy} onClick={() => void save(true)}>Save targets</button>}
      {targets === null ? null : <button type="button" className="button button--secondary" disabled={busy} onClick={() => void save(false)}>Recalculate from bodyweight</button>}
      {targets === null ? <Link className="button button--text" href="/nutrition/method">How targets are estimated</Link> : <EstimateLines targets={targets} />}
    </div>
  );
}
