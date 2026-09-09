// SPEC: E9 · A7 — the privacy policy the Settings row and the App Store listing point at. Static placeholder: the owner
// replaces this text before submission (docs/OWNER-REVIEW.md, T047). Public page, one main, one h1.
import Link from "next/link";

export default function PrivacyPage() {
  return (
    <main className="app-column stack">
      <h1>Privacy policy</h1>
      <p className="muted" role="note">Draft — replaced by the owner before submission.</p>
      <p>Crew keeps what it needs to run your plan and your crew: your email, your name, an optional photo, the workouts you log, and what you post. Nothing is sold, and there is no public feed.</p>
      <p>Your posts are visible only to the members of the crew you shared them with. Photos are resized and stripped of location data before they are stored.</p>
      <p>We only email you for password resets and account deletion. You can export everything as one JSON file or delete your account from Settings at any time; deletion removes your plan, workouts, posts and photos everywhere.</p>
      <Link className="button button--text" href="/">Back to Crew</Link>
    </main>
  );
}
