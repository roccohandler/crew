// SPEC: nutrition addendum §4 — "Saved meals & template" carries a two-way segment [Saved meals | Template]. On web the two halves
// are two routes and this is the one control on both (the ProgressSegments precedent, A19.4): aria-current names the current half,
// so the state is never colour alone. Twin of the iOS segmented Picker at the top of SavedMealsScreen.
import Link from "next/link";

export function NutritionSegments({ active }: { active: "meals" | "template" }) {
  return (
    <nav className="segments" aria-label="Saved meals or template">
      <Link className="segments__item" href="/nutrition/meals" aria-current={active === "meals" ? "page" : undefined}>Saved meals</Link>
      <Link className="segments__item" href="/nutrition/template" aria-current={active === "template" ? "page" : undefined}>Template</Link>
    </nav>
  );
}
