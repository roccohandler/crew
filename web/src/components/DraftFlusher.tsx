"use client";
// SPEC: S05 — after a Sign in with Apple redirect the onboarding draft is still in localStorage: save it, then reload Home.
// A1: only a draft in the rotation shape ({ trainingWeekdays, workouts }) is sent; a pre-A1 draft is dropped (the server
// would refuse it and the member rebuilds in three questions).
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
      if (draft.plan && Array.isArray(draft.plan.trainingWeekdays)) await putPlan({ trainingWeekdays: draft.plan.trainingWeekdays, workouts: draft.plan.workouts });
      if (draft.invite) await joinCrew(draft.invite).catch(() => undefined);
      window.localStorage.removeItem(DRAFT_KEY);
      window.location.reload();
    };
    void flush();
  }, []);
  return null;
}
