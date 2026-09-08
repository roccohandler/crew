"use client";
// SPEC: 1C ("measured, funnel-instrumented") — a server-rendered screen records that it was seen. Renders nothing; the step
// is queued by lib/funnel.ts and flushed once the account exists. Web twin of the ios Funnel mark on IntroScreen.
import { useEffect } from "react";
import { markFunnelStep } from "@/lib/funnel";

export function FunnelStep({ name, props }: { name: string; props?: Record<string, string | number | boolean | null> }) {
  useEffect(() => {
    markFunnelStep(name, props); // a re-render with a fresh props object is harmless: the queue keeps one step per name
  }, [name, props]);
  return null;
}
