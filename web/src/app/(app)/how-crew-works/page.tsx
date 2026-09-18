// SPEC: A23 (Appendix A 2026-09-18) · docs/education-copy-draft.md §C, §D — S19 "How Crew works": the one re-readable page behind
// the whispers, reached from Settings → About. One scrolling page, nothing interactive but links: the note from Max (marked Draft
// until the owner rewrites it), the seven sections in the owner's order, what the whispers said — verbatim, in trigger order — and
// the A16.a line. The page renders for every age; under 18, or with no birth year on file, the Protein section drops its numeric
// sentence and its source link and the three nutrition whispers are omitted — with no copy about the omission (A16.c: no upsell).
// Every word is shared/copy/education.json, so the phone prints the same page. Ink and secondary ink only: no orange text (law ③).
// Twin: ios Features/Settings/HowCrewWorksScreen.swift.
import { redirect } from "next/navigation";
import { education } from "@/generated/copy";
import { readSession } from "@/lib/session";

export default async function HowCrewWorksPage() {
  const session = await readSession();
  if (session.kind !== "signedIn") redirect("/");
  const adult = session.user.nutrition === "available";
  const page = education.page;
  return (
    <article className="stack stack--sections">
      <h1>{page.title}</h1>
      <section className="card stack stack--tight" aria-label={page.note.heading}>
        <h2>{page.note.heading}</h2>
        {page.note.draft ? <p className="whisper">Draft</p> : null}
        <p>{page.note.body}</p>
      </section>
      {page.sections.map((section) => (
        <section key={section.id} className="stack stack--tight">
          <h2>{section.heading}</h2>
          <p>{adult && section.adultBody !== "" ? `${section.body} ${section.adultBody}` : section.body}</p>
          {section.source !== null && (section.source.gate === "all" || adult) ? <a className="whisper" href={section.source.url} target="_blank" rel="noreferrer">{section.source.label}</a> : null}
        </section>
      ))}
      <section className="stack stack--tight">
        <h2>{page.whispersHeading}</h2>
        <ol className="stack stack--tight">
          {education.whispers.filter((whisper) => whisper.gate === "all" || adult).map((whisper) => (
            <li key={whisper.id}>{whisper.line} <span className="whisper">({whisper.moment})</span></li>
          ))}
        </ol>
      </section>
      <p className="muted">{page.clinician}</p>
    </article>
  );
}
