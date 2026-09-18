// SPEC: E9 · A7 · W9 (owner order 2026-09-18, item 6) — the terms the signup line ("By saving you agree to the terms") and the Settings row point at. Drafted from what the code actually does
// (shared/copy/legal.json names the files); the OWNER REVIEWS IT before submission (docs/OWNER-REVIEW.md). The contact address is the
// server's SUPPORT_EMAIL — until it is set the page points at the App Store listing's support link. Public page, one main, one h1.
import Link from "next/link";
import { legal } from "@/generated/copy";

export default function TermsPage() {
  const page = legal.terms;
  const contact = process.env.SUPPORT_EMAIL ?? "";
  return (
    <main className="app-column stack stack--sections">
      <h1>{page.title}</h1>
      <p>{page.lead}</p>
      {page.sections.map((section) => (
        <section key={section.heading} className="stack stack--tight">
          <h2>{section.heading}</h2>
          {section.paragraphs.map((paragraph) => <p key={paragraph}>{paragraph}</p>)}
        </section>
      ))}
      <section className="stack stack--tight">
        <h2>Contact</h2>
        {contact === "" ? <p>Write to the support address on Crew&apos;s App Store page.</p> : <p>Write to <a href={`mailto:${contact}`}>{contact}</a>.</p>}
      </section>
      <p className="whisper">Last updated {legal.updated}.</p>
      <Link className="button button--text" href="/">Back to Crew</Link>
    </main>
  );
}
