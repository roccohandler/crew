// SPEC: 6.1 Empty — an invitation, never an apology; exactly one CTA. Mirrors ios Shared/EmptyState. A5: the solo Crew tab
// explains the loop in three lines (children, rendered between the title and the invitation line) before its one CTA.
import Link from "next/link";
import type { ReactNode } from "react";

export function EmptyState({ title, line, ctaTitle, href, onClick, children }: { title: string; line: string; ctaTitle: string; href?: string; onClick?: () => void; children?: ReactNode }) {
  return (
    <section className="stack center" aria-live="polite">
      <h1>{title}</h1>{/* every use is the whole page (6.1: an invitation, exactly one CTA) — the invitation is the page heading */}
      {children}
      <p className="muted">{line}</p>
      {href ? <Link className="button button--primary" href={href}>{ctaTitle}</Link> : <button className="button button--primary" type="button" onClick={onClick}>{ctaTitle}</button>}
    </section>
  );
}

// SPEC: 6.1 Error — what happened + what to do, one sentence, no codes, always a retry path
export function ErrorState({ line, onRetry }: { line: string; onRetry: () => void }) {
  return (
    <section className="stack center" role="alert">
      <p>{line}</p>
      <button className="button button--secondary" type="button" onClick={onRetry}>Try again</button>
    </section>
  );
}
