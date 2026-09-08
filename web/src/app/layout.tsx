import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";
import "@/generated/ember.css";
import "./app.css";

// SPEC: Part IV (full-parity web app) · Part III (Ember tokens via generated ember.css) · 6.7 (single column)
export const metadata: Metadata = {
  title: "Crew",
  description: "One plan. Every week. Your crew sees you show up.",
};

export const viewport: Viewport = { width: "device-width", initialScale: 1 };

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
