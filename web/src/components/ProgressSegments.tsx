// SPEC: A19.4 (owner-ruled) · W6 (2026-09-17) — Progress carries a two-way segment at the top, Charts | Journal, so both halves of
// Flow 9 are one tap from the tab and neither hides in chrome; the five-tab bar is unchanged. On web the two halves are two routes
// and this is the one control on both; aria-current names the current half (state is never colour alone). Twin of the iOS Picker.
import Link from "next/link";

export function ProgressSegments({ active }: { active: "charts" | "journal" }) {
  return (
    <nav className="segments" aria-label="Progress view">
      <Link className="segments__item" href="/progress" aria-current={active === "charts" ? "page" : undefined}>Charts</Link>
      <Link className="segments__item" href="/journal" aria-current={active === "journal" ? "page" : undefined}>Journal</Link>
    </nav>
  );
}
