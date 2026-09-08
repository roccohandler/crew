"use client";
// SPEC: S05 — after a Sign in with Apple redirect the onboarding draft is still in localStorage: save it, then reload Home.
import { useEffect } from "react";
import { putPlan } from "@/lib/api-client";
import { joinCrew } from "@/lib/api-client-crew";
import { DRAFT_KEY } from "@/components/onboarding/OnboardingFlow";
import type { PlanDraft } from "@/lib/engine/plan-generator";

export function DraftFlusher() {
  useEffect(() => {
    const flush = async () => {
      let raw: string | null = null;
      try { raw = window.localStorage.getItem(DRAFT_KEY); } catch { return; }
      if (raw === null) return;
      const draft = JSON.parse(raw) as { plan: PlanDraft | null; invite: string | null };
      if (draft.plan) await putPlan(draft.plan);
      if (draft.invite) await joinCrew(draft.invite).catch(() => undefined);
      window.localStorage.removeItem(DRAFT_KEY);
      window.location.reload();
    };
    void flush();
  }, []);
  return null;
}
