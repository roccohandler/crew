"use client";
// SPEC: A16.c · nutrition addendum §6 — an account with no birth year (Sign in with Apple, or made before the year was stored) is
// asked ONCE, here, the first time Nutrition is opened — never at launch, never retroactively. Signup's own validators (birthYearMin,
// the 13+ floor on the server). The year is stored once and never shown again; if it puts the account under 18 the surface simply
// does not exist: back to Home, where the row is now absent — no copy, no upsell, no "unlock at 18".
// Twin: ios Features/Nutrition/BirthYearAskScreen.swift.
import { useRouter } from "next/navigation";
import { useState } from "react";
import { isApiClientError } from "@/lib/api-client";
import { updateMe } from "@/lib/api-client-crew";
import { SpecConstants } from "@/generated/spec-constants";

export function BirthYearAsk() {
  const router = useRouter();
  const [year, setYear] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const submit = async () => {
    if (!/^\d{4}$/.test(year) || Number(year) < SpecConstants.birthYearMin || Number(year) > new Date().getFullYear()) return setError("Four digits, like 1994.");
    setBusy(true);
    setError(null);
    try {
      const user = await updateMe({ birthYear: Number(year) });
      if (user.nutrition !== "available") router.replace("/home");
      router.refresh();
    } catch (caught) {
      setError(isApiClientError(caught) ? caught.message : "Couldn't save that. Try again.");
      setBusy(false);
    }
  };
  return (
    <div className="stack">
      <h1>Your birth year</h1>
      <p className="muted">{"Nutrition needs it once. It's never shown to anyone."}</p>
      <label className="field field--short"><span>Birth year</span><input type="text" inputMode="numeric" autoComplete="bday-year" value={year} onChange={(event) => setYear(event.target.value)} /></label>
      {error ? <p className="notice" role="alert">{error}</p> : null}
      <button type="button" className="button button--primary" disabled={busy} onClick={() => void submit()}>Continue</button>
    </div>
  );
}
