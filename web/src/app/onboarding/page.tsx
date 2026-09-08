// SPEC: S03–S05 on web (Part IV full parity) — the three questions, the reveal, the save. The Apple href is built server-side
// (env) and handed to the client flow; the state carries the timezone and the EULA acceptance (docs/api.md apple/callback).
import { OnboardingClient } from "@/components/onboarding/OnboardingClient";
import { appleAuthorizeUrl } from "@/lib/apple-auth";
import { readSession } from "@/lib/session";

export default async function OnboardingPage({ searchParams }: { searchParams: Promise<{ invite?: string }> }) {
  const { invite } = await searchParams;
  const session = await readSession();
  const state = new URLSearchParams({ eula: "1", next: invite ? "/crew" : "/home" });
  return (
    <main className="app-column">
      <OnboardingClient appleHref={appleAuthorizeUrl(state.toString())} invite={invite && invite.length > 0 ? invite : null} signedIn={session.kind === "signedIn"} />
    </main>
  );
}
