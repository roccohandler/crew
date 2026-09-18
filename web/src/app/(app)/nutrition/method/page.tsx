// SPEC: A16.a (REQUIRED, not optional — App Review 1.4.1 covers "calculations") · nutrition addendum §3 — How targets are estimated:
// names every factor, its source as a LINK, and the estimate-and-clinician line. The words are shared/copy/nutrition-method.json, so
// iOS prints the same page and every number in it is a constant. Behind the 18+ gate like the rest of the surface.
// Twin: ios NutritionMethodScreen.
import { nutritionMethod } from "@/generated/copy";
import { openNutrition } from "@/app/(app)/nutrition/gate";

export default async function NutritionMethodPage() {
  await openNutrition();
  return (
    <article className="stack">
      <h1>{nutritionMethod.title}</h1>
      <p>{nutritionMethod.lead}</p>
      {nutritionMethod.steps.map((step) => (
        <section key={step.heading} className="stack stack--tight">
          <h2>{step.heading}</h2>
          <p>{step.body}</p>
          {nutritionMethod.sources.filter((source) => step.sourceIds.includes(source.id)).map((source) => (
            <a key={source.id} className="whisper" href={source.url} target="_blank" rel="noreferrer">{source.label}</a>
          ))}
        </section>
      ))}
      <p className="muted">{nutritionMethod.clinician}</p>
    </article>
  );
}
