"use client";
// The onboarding flow reads its saved draft from localStorage at first render (S05), so it renders on the client only — no
// server HTML to mismatch.
import dynamic from "next/dynamic";

const OnboardingFlow = dynamic(() => import("@/components/onboarding/OnboardingFlow").then((module) => module.OnboardingFlow), { ssr: false, loading: () => <div className="skeleton" aria-hidden="true" /> });

export function OnboardingClient({ appleHref, invite, signedIn }: { appleHref: string; invite: string | null; signedIn: boolean }) {
  return <OnboardingFlow appleHref={appleHref} invite={invite} signedIn={signedIn} />;
}
