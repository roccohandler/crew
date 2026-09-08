// SPEC: Part IV (full-parity web app) · Part III law ① (navigation and chrome are monochrome forever) · 6.7 (single column) ·
// 6.5 (semantic landmarks, keyboard-complete). Signed-out visitors go to the hero; expired sessions refresh silently (1C).
import Link from "next/link";
import { redirect } from "next/navigation";
import type { ReactNode } from "react";
import { SessionKeeper } from "@/components/SessionKeeper";
import { readSession } from "@/lib/session";

const TABS = [
  { href: "/home", label: "Home" },
  { href: "/plan", label: "Plan" },
  { href: "/crew", label: "Crew" },
  { href: "/progress", label: "Progress" },
  { href: "/settings", label: "Settings" },
];

export default async function AppLayout({ children }: { children: ReactNode }) {
  const session = await readSession();
  if (session.kind === "signedOut") redirect("/");
  if (session.kind === "needsRefresh") {
    return (
      <main className="app-column">
        <SessionKeeper mode="reload" />
      </main>
    );
  }
  return (
    <div className="app-shell">
      <SessionKeeper mode="keep" />
      <main className="app-column" id="main">
        {children}
      </main>
      <nav className="tabs" aria-label="Sections">
        {TABS.map((tab) => (
          <Link key={tab.href} href={tab.href} className="tabs__item">
            {tab.label}
          </Link>
        ))}
      </nav>
    </div>
  );
}
