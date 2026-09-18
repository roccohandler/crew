// SPEC: nutrition addendum §4 (Today: P / C / F and, fourth, Calories — Q2) · ux-plan §7.4 — ALL FIVE redundant encoders, so the
// screen is fully correct with every macro token forced to plain ink: ① fixed order Protein → Carbs → Fat, never sorted; ② a P / C / F
// letter in INK on every coloured element; ③ direct numbers on every bar; ④ fill treatment (protein solid · carbs solid + ink
// hairline · fat outline + hairline, in app.css); ⑤ state is never colour — "N to go" / "N over" are ink words on their own line
// (clause ②) and an overage shows as LENGTH past the target hairline. Calories is ink text with no bar: it has no macro identity.
// No ember element and no semantic token renders here (law ⑥'s exception). Twin: ios Features/Nutrition/MacroLines.swift.
import { amountText, barPercent, horizonText, restText, spokenLine, type MacroLine, type MacroRemaining } from "@/lib/engine/macro-day";
import { SpecConstants } from "@/generated/spec-constants";

function MacroRow({ letter, name, tone, line }: { letter: string; name: string; tone: "protein" | "carbs" | "fat"; line: MacroLine }) {
  const percent = barPercent(line);
  const rest = restText(line);
  return (
    <div className="macro" role="group" aria-label={spokenLine(name, line, "g")}>
      <div className="row row--between" aria-hidden="true">
        <span className="macro__name"><span className="macro__letter">{letter}</span> {name}</span>
        <span className="macro__amount">{amountText(line, "g")}</span>
      </div>
      <div className={`macro__track macro__track--${tone}`} aria-hidden="true">
        {percent > 0 ? <div className={`macro__fill macro__fill--${tone}`} style={{ width: `${percent}%` }} /> : null}
        <div className="macro__marker" style={{ left: `${SpecConstants.macroBarTargetPercent}%` }} />
      </div>
      {rest === null ? null : <p className="macro__rest" aria-hidden="true">{rest}</p>}
    </div>
  );
}

export function MacroLines({ remaining }: { remaining: MacroRemaining }) {
  const calories = restText(remaining.calories);
  const horizon = horizonText(remaining); // clause ②: an overage names tomorrow in the same breath — a fact, in ink
  return (
    <section className="stack" aria-label="Today's macros">
      <MacroRow letter="P" name="Protein" tone="protein" line={remaining.protein} />
      <MacroRow letter="C" name="Carbs" tone="carbs" line={remaining.carbs} />
      <MacroRow letter="F" name="Fat" tone="fat" line={remaining.fat} />
      <div className="macro" role="group" aria-label={spokenLine("Calories", remaining.calories, "kcal")}>
        <div className="row row--between" aria-hidden="true">
          <span className="macro__name">Calories</span>
          <span className="macro__amount">{amountText(remaining.calories, "kcal")}</span>
        </div>
        {calories === null ? null : <p className="macro__rest" aria-hidden="true">{calories}</p>}
      </div>
      {horizon === null ? null : <p className="macro__rest">{horizon}</p>}
    </section>
  );
}
