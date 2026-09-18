// SPEC: S03–S05 on web (Part IV full parity) — the three questions, the reveal, the save. The Apple href is built server-side
// (env) and handed to the client flow; W5 (2026-09-17): the href is the server's start route, which binds the attempt (signed state,
// nonce cookie, id_token nonce) and carries the EULA acceptance and where to land (docs/api.md auth/apple/start).
import { OnboardingClient } from "@/components/onboarding/OnboardingClient";
import { appleStartUrl } from "@/lib/apple-auth";
import { readSession } from "@/lib/session";

export default async function OnboardingPage({ searchParams }: { searchParams: Promise<{ invite?: string }> }) {
  const { invite } = await searchParams;
  const session = await readSession();
  return (
    <main className="app-column">
      <OnboardingClient appleHref={appleStartUrl({ eula: true, next: invite ? "/crew" : "/home" })} invite={invite && invite.length > 0 ? invite : null} signedIn={session.kind === "signedIn"} />
    </main>
  );
}
