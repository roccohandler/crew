// SPEC: W1 web invite landing (web-only) — renders crew name/emoji without auth; App Store + Continue-on-web; the growth loop's
// front door. Dead or full links are explicit states (S13). A signed-in visitor joins in one interaction.
import Link from "next/link";
import { JoinButton } from "@/components/JoinButton";
import { crewMemberships, crews } from "@/lib/db";
import { readSession } from "@/lib/session";
import { SpecConstants } from "@/generated/spec-constants";

export default async function JoinPage({ params }: { params: Promise<{ token: string }> }) {
  const { token } = await params;
  const crew = await (await crews()).findOne({ inviteToken: token, archivedAt: null });
  if (crew === null) {
    return (
      <main className="app-column stack">
        <h1>{"That invite isn't live anymore"}</h1>
        <p className="muted">Ask your crew for a fresh link — the Captain can make one in a tap.</p>
        <Link className="button button--secondary" href="/">Build your own week instead</Link>
      </main>
    );
  }
  const memberCount = await (await crewMemberships()).countDocuments({ crewId: crew._id });
  const full = memberCount >= SpecConstants.crewMaxMembers;
  const session = await readSession();
  const appStore = process.env.APP_STORE_URL ?? "https://apps.apple.com";
  return (
    <main className="app-column stack">
      <p className="muted">{"You're invited to"}</p>
      <h1>{crew.name} {crew.emoji}</h1>
      <p className="muted">{memberCount} of {SpecConstants.crewMaxMembers} in the crew</p>
      {full ? <p role="status">Crew full — {SpecConstants.crewMaxMembers} is the max. Ask about a second crew.</p> : null}
      {!full && session.kind === "signedIn" ? <JoinButton token={token} /> : null}
      {!full && session.kind !== "signedIn" ? (
        <>
          <a className="button button--primary" href={appStore}>Get the iPhone app</a>
          <Link className="button button--secondary" href={`/onboarding?invite=${encodeURIComponent(token)}`}>Continue on web</Link>
        </>
      ) : null}
    </main>
  );
}
