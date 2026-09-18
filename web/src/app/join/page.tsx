// SPEC: A21.3 / W4 — "I have an invite" without a token in hand: paste the code (or the whole link) and the landing page for that
// crew opens. A signed-in visitor gets the same form (the landing page then offers Join). Pure ink-on-bone (Part III).
import Link from "next/link";
import { InviteCodeForm } from "@/components/InviteCodeForm";

export default function JoinByCodePage() {
  return (
    <main className="app-column stack">
      <h1>Paste your invite</h1>
      <p className="muted">The code or the whole link your friend sent — either works.</p>
      <InviteCodeForm />
      <Link className="button button--text" href="/">Build your own week instead</Link>
    </main>
  );
}
