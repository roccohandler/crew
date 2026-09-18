"use client";
// SPEC: Flow 1 (two questions → plan → save; A21.1, owner-approved 2026-09-17: every user has full commercial gym access, so the
// equipment question is gone and the experience answer builds the plan) · 1A invite-aware fast path (the token rides through and
// the user lands in the crew) · S05 (the draft survives auth abandon: localStorage) · C14 (plain objects + useState) · A1 (a draft
// is trainingWeekdays + the rotation; swap is keyed by kind; a pre-A1 draft is dropped). Web twin of ios OnboardingModel.
import { useRouter } from "next/navigation";
import { useState } from "react";
import { DaysQuestion } from "@/components/onboarding/DaysQuestion";
import { GeneratedPlan } from "@/components/onboarding/GeneratedPlan";
import { SaveForm } from "@/components/onboarding/SaveForm";
import { SingleSelect } from "@/components/onboarding/SingleSelect";
import { putPlan } from "@/lib/api-client";
import { joinCrew } from "@/lib/api-client-crew";
import { flushFunnel, markFunnelStep } from "@/lib/funnel";
import { dayKeyFor } from "@/lib/engine/day-key";
import { generatePlan, workoutFor, type PlanDraft, type PlanDraftWorkout, type SeedCatalog } from "@/lib/engine/plan-generator";
import { swapCandidates } from "@/lib/engine/swap-finder";
import { exercises, planTemplates, type Experience, type SeedExercise } from "@/generated/seed";
import { SpecConstants } from "@/generated/spec-constants";

const seed: SeedCatalog = { exercises, planTemplates };
export const DRAFT_KEY = "crew.onboardingDraft";
type Step = "days" | "experience" | "reveal" | "save";
// A pre-A21.1 draft in localStorage carries an `equipment` key; JSON.parse keeps it and nothing reads it
interface Draft { days: number[]; experience: Experience | null; plan: PlanDraft | null; invite: string | null }

function loadDraft(): Draft | null {
  try {
    const raw = window.localStorage.getItem(DRAFT_KEY);
    const saved = raw ? (JSON.parse(raw) as Draft) : null;
    return saved?.plan && !Array.isArray(saved.plan.trainingWeekdays) ? { ...saved, plan: null } : saved;
  } catch {
    return null;
  }
}

export function OnboardingFlow({ appleHref, invite, signedIn }: { appleHref: string; invite: string | null; signedIn: boolean }) {
  const router = useRouter();
  // S05: a saved draft resumes at the save step (this component renders on the client only — OnboardingClient); a signed-in
  // rebuild (Flow 8 / E4) always starts at the questions and never touches the pre-auth draft
  const [draft, setDraft] = useState<Draft>(() => {
    const saved = signedIn ? null : loadDraft();
    return saved?.plan ? { ...saved, invite: invite ?? saved.invite } : { days: [...SpecConstants.defaultTrainingWeekdays], experience: null, plan: null, invite };
  });
  const [step, setStep] = useState<Step>(() => (!signedIn && loadDraft()?.plan ? "save" : "days"));
  const [whisperShown, setWhisperShown] = useState(false);

  const persist = (next: Draft) => {
    setDraft(next);
    if (signedIn) return;
    try { window.localStorage.setItem(DRAFT_KEY, JSON.stringify(next)); } catch { /* private mode: the flow still works in memory */ }
  };

  const chooseExperience = (value: string) => {
    const experience = value as Experience;
    const plan = generatePlan(draft.days, experience, seed);
    persist({ ...draft, experience, plan });
    markFunnelStep("onboarding_plan_built", { days: draft.days.length, experience }); // 1C funnel
    setStep("reveal");
  };

  const swap = (kind: PlanDraftWorkout["kind"], exerciseId: string, replacement: SeedExercise) => {
    if (!draft.plan) return;
    const workouts = draft.plan.workouts.map((workout) => {
      if (workout.kind !== kind) return workout;
      const fresh = workoutFor(workout.kind, draft.experience ?? "brandNew", seed);
      const exercises = workout.exercises.map((row) => (row.exerciseId === exerciseId ? { ...(fresh.exercises.find((candidate) => candidate.type === "strength") ?? row), exerciseId: replacement.id, name: replacement.name, pattern: replacement.pattern, equipment: replacement.equipment, order: row.order } : row));
      return { ...workout, exercises };
    });
    persist({ ...draft, plan: { trainingWeekdays: draft.plan.trainingWeekdays, workouts } });
    setWhisperShown(true);
  };

  const finish = async () => {
    if (draft.plan) await putPlan({ trainingWeekdays: draft.plan.trainingWeekdays, workouts: draft.plan.workouts });
    if (draft.invite) await joinCrew(draft.invite).catch(() => undefined);
    try { window.localStorage.removeItem(DRAFT_KEY); } catch { /* nothing to clear */ }
    // 1C: hero → questions → plan built → saved, flushed now that the account exists (a rebuild by a member records nothing)
    if (!signedIn) { markFunnelStep("onboarding_saved", { invited: draft.invite !== null }); await flushFunnel(); }
    router.push(signedIn ? "/plan" : draft.invite ? "/crew" : "/home");
  };

  return <StepView step={step} draft={draft} whisperShown={whisperShown} appleHref={appleHref} signedIn={signedIn} persist={persist} setStep={setStep} chooseExperience={chooseExperience} swap={swap} finish={finish} />;
}

interface StepViewProps { step: Step; draft: Draft; whisperShown: boolean; appleHref: string; signedIn: boolean; persist: (next: Draft) => void; setStep: (step: Step) => void; chooseExperience: (value: string) => void; swap: (kind: PlanDraftWorkout["kind"], exerciseId: string, replacement: SeedExercise) => void; finish: () => Promise<void> }

function StepView({ step, draft, whisperShown, appleHref, signedIn, persist, setStep, chooseExperience, swap, finish }: StepViewProps) {
  if (step === "days") return <DaysQuestion days={draft.days} onToggle={(weekday) => persist({ ...draft, days: draft.days.includes(weekday) ? draft.days.filter((day) => day !== weekday) : [...draft.days, weekday] })} onContinue={() => { if (!signedIn) markFunnelStep("onboarding_days"); setStep("experience"); }} />;
  if (step === "experience") return <SingleSelect number={QUESTION.experience} title="How experienced are you?" selected={draft.experience} options={[{ value: "brandNew", label: "Brand new", symbol: "🚶" }, { value: "some", label: "Some", symbol: "🏋️" }, { value: "experienced", label: "Experienced", symbol: "🏆" }]} onChoose={(value) => { if (!signedIn) markFunnelStep("onboarding_experience"); chooseExperience(value); }} />;
  if (step === "reveal" && draft.plan) return <GeneratedPlan draft={draft.plan} todayKey={dayKeyFor(new Date(), Intl.DateTimeFormat().resolvedOptions().timeZone)} whisperShown={whisperShown} swapCandidates={(exerciseId) => { const incumbent = exercises.find((candidate) => candidate.id === exerciseId); return incumbent ? swapCandidates(incumbent, draft.experience ?? "brandNew", exercises) : []; }} onSwap={swap} onAccept={() => { persist(draft); if (signedIn) void finish(); else setStep("save"); }} />;
  return <SaveForm appleHref={appleHref} onSaved={finish} />;
}

// A21.1: two questions — days first, experience last (its number IS the question count, so the whisper reads "2 of 2")
const QUESTION = { days: 1, experience: SpecConstants.onboardingQuestionCount } as const;
