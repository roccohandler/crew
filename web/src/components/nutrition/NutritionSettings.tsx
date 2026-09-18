"use client";
// SPEC: nutrition addendum §4 ("Settings gains three rows": Nutrition targets · How targets are estimated (A16.a) · Delete my
// nutrition data — two-step, "can't be undone": targets + bodyweight + saved meals + template + logs in one cascade) · §6: under 18
// the rows are ABSENT, with no copy — SettingsView renders this section only when the surface exists. E18: the one red thing on the
// page stays Delete account, so this delete is ink. Twin: ios Features/Settings/NutritionSettingsRows.swift.
import Link from "next/link";
import { useState } from "react";
import { isApiClientError } from "@/lib/api-client";
import { deleteNutritionTargets } from "@/lib/api-client-nutrition";

export function NutritionSettings() {
  const [step, setStep] = useState<"idle" | "confirming" | "deleted">("idle");
  const [error, setError] = useState<string | null>(null);
  const erase = async () => {
    setError(null);
    try {
      await deleteNutritionTargets(true);
      setStep("deleted");
    } catch (caught) {
      setError(isApiClientError(caught) ? caught.message : "Couldn't delete that. Try again.");
    }
  };
  return (
    <section className="card stack stack--tight" aria-label="Nutrition">
      <h2>Nutrition</h2>
      <Link className="button button--text" href="/nutrition/targets">Nutrition targets</Link>
      <Link className="button button--text" href="/nutrition/method">How targets are estimated</Link>
      {step === "idle" ? <button type="button" className="button button--text" onClick={() => setStep("confirming")}>Delete my nutrition data</button> : null}
      {step === "confirming" ? (
        <div className="card stack stack--tight">
          <p>{"This deletes your targets, your bodyweight, your saved meals, your template and every logged meal. It can't be undone."}</p>
          <button type="button" className="button button--primary" onClick={() => void erase()}>Delete my nutrition data</button>
          <button type="button" className="button button--text" onClick={() => setStep("idle")}>Keep it</button>
        </div>
      ) : null}
      {step === "deleted" ? <p className="muted" role="status">Deleted.</p> : null}
      {error ? <p className="notice" role="alert">{error}</p> : null}
    </section>
  );
}
