// Playwright globalSetup (runs after the web server is up, before any test): `next dev` compiles each page and route on its
// first hit, and viewport workers hitting a cold server together pushed first-hit compiles past the journeys' waits.
// Two passes make the first test as warm as the last (CI starts cold every time): every API route once by fetch, and every
// page once IN A BROWSER, signed in — a page's client bundle compiles on its first browser hit, and every compile broadcasts
// a Fast Refresh to every open page; a page mid-mount loses its lazy chunk (seen on WebKit at 375 with eight workers: an empty
// <main> under the dev overlay). SPEC: 8.4 (web journeys against a seeded backend in CI) · T039
import { chromium, type FullConfig } from "@playwright/test";

const PAGES = ["/", "/onboarding", "/login", "/reset", "/join/warm-up", "/home", "/post", "/plan", "/crew", "/progress", "/journal", "/settings", "/session/new", "/session/warm-up", "/session/warm-up/done", "/plan/push", "/log-cardio", "/privacy", "/terms"];
const ROUTES = ["auth/register", "auth/login", "auth/logout", "auth/refresh", "auth/reset", "users/me", "plans", "sessions", "sessions/warm-up", "posts", "posts/warm-up", "posts/warm-up/reactions", "crews", "crews/join?token=warm-up", "crews/warm-up/stream", "crews/warm-up/messages", "crews/warm-up/members", "sync", "pause", "photos"];
const WARM_UP_IP = "203.0.113.250"; // outside the journeys' fresh-IP range (helpers.ts: % 250), so the G11 limiter never meets it

export default async function warmUp(config: FullConfig): Promise<void> {
  const baseURL = config.projects[0]?.use.baseURL ?? "http://localhost:3000";
  await Promise.all(ROUTES.map((route) => fetch(`${baseURL}/api/v1/${route}`, { redirect: "manual" }).then((reply) => reply.arrayBuffer()).catch(() => undefined)));
  const browser = await chromium.launch();
  const page = await browser.newPage({ baseURL });
  const email = `warm-up-${Date.now()}@example.com`;
  await page.request.post("/api/v1/auth/register", { headers: { "x-forwarded-for": WARM_UP_IP }, data: { email, password: "warm-up password 1", displayName: "Warm-up", timezone: "UTC", eulaAccepted: true, birthYear: 1990 } }).catch(() => undefined);
  for (const path of PAGES) await page.goto(path, { waitUntil: "networkidle" }).catch(() => undefined);
  await browser.close();
}
