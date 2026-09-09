// SPEC: E9 · A7 — the terms the signup line ("By saving you agree to the terms") and the Settings row point at. Static
// placeholder: the owner replaces this text before submission (docs/OWNER-REVIEW.md, T047). Public page, one main, one h1.
import Link from "next/link";

export default function TermsPage() {
  return (
    <main className="app-column stack">
      <h1>Terms</h1>
      <p className="muted" role="note">Draft — replaced by the owner before submission.</p>
      <p>Crew is for people 13 and up. You are responsible for what you post; a Captain can remove members, anyone can report a post, and reports are read by a person.</p>
      <p>Crew is a beta. It may change, pause, or end; your data stays yours and can be exported from Settings while your account exists.</p>
      <p>Content that harasses, threatens, or exposes another person is removed and may end your account.</p>
      <Link className="button button--text" href="/">Back to Crew</Link>
    </main>
  );
}
