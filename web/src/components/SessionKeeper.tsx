"use client";
// SPEC: 1C (authenticate once per device, ever) — keeps the 15-minute access cookie fresh from the 30-day refresh cookie
// (G11 rotation). Mounted once in the app layout; when a server page found an expired access cookie it renders this in
// `reload` mode: refresh, then reload the page.
import { useEffect } from "react";
import { TimeUnits } from "@/lib/time-units";
import { SpecConstants } from "@/generated/spec-constants";

const REFRESH_EVERY_MS = (SpecConstants.jwtAccessTokenMinutes - 1) * TimeUnits.msPerMinute;

export function SessionKeeper({ mode }: { mode: "keep" | "reload" }) {
  useEffect(() => {
    let cancelled = false;
    const refresh = async () => {
      const response = await fetch("/api/v1/auth/refresh", { method: "POST", credentials: "include" });
      if (cancelled) return;
      if (mode === "reload") window.location.href = response.ok ? window.location.href : "/login";
    };
    void refresh();
    const timer = window.setInterval(() => void refresh(), REFRESH_EVERY_MS);
    return () => {
      cancelled = true;
      window.clearInterval(timer);
    };
  }, [mode]);
  return mode === "reload" ? <p className="muted">Signing you back in…</p> : null;
}
