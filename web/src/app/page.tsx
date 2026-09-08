// SPEC: S02 hero (AMENDED v1.9) — ONE screen, three CTAs (Build my week · I have an invite · Log in); an invite token renders
// the crew's name/emoji ("Dawn Patrol 🌅 is waiting for you", 1A); pure ink-on-bone (Part III). A signed-in visitor goes to Home.
import Link from "next/link";
import { redirect } from "next/navigation";
import { FunnelStep } from "@/components/FunnelStep";
import { crews } from "@/lib/db";
import { readSession } from "@/lib/session";

export default async function HeroPage({ searchParams }: { searchParams: Promise<{ invite?: string }> }) {
  const session = await readSession();
  const { invite } = await searchParams;
  if (session.kind === "signedIn") redirect(invite ? `/join/${invite}` : "/home");
  const crew = invite ? await (await crews()).findOne({ inviteToken: invite, archivedAt: null }) : null;
  const inviteQuery = invite ? `?invite=${encodeURIComponent(invite)}` : "";
  return (
    <main className="app-column stack" style={{ justifyContent: "flex-end", minHeight: "100vh" }}>
      <FunnelStep name="onboarding_hero" props={{ invited: crew !== null }} />
      {crew ? <p className="muted">{crew.name} {crew.emoji} is waiting for you</p> : null}
      <h1>One plan. Every week. Your crew sees you show up.</h1>
      <Link className="button button--primary" href={`/onboarding${inviteQuery}`}>Build my week</Link>
      <Link className="button button--secondary" href="/onboarding?invite=">I have an invite</Link>
      <Link className="button button--text" href="/login">Log in</Link>
    </main>
  );
}
