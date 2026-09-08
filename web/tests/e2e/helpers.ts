// Shared journey steps — the same taps a person makes (8.4), reused across the viewport matrix (8.9).
import { expect, type Page } from "@playwright/test";
import { dayKeyFor, isoWeekday } from "../../src/lib/engine/day-key";

export const unique = (label: string) => `${label}-${Date.now()}-${Math.floor(Math.random() * 1e6)}`;

// The G11 auth limiter is 10 req/min per IP and every journey registers; each test context arrives from its own address
// (x-forwarded-for, as Vercel would set it) so the matrix never trips the limit it is not testing.
let ipCounter = 0;
export async function fromFreshIp(page: Page): Promise<string> {
  ipCounter += 1;
  const address = `203.0.113.${(ipCounter + process.pid) % 250}`;
  await page.context().setExtraHTTPHeaders({ "x-forwarded-for": address });
  return address; // API calls made outside the page (page.request) pass it as a header themselves
}

// Hero → three questions → reveal → email save → Home (Flow 1; ≤ 5 decisions before Home)
export async function buildWeekAndSave(page: Page, options: { invite?: string; label?: string } = {}): Promise<string> {
  const email = `${unique(options.label ?? "journey")}@example.com`;
  await fromFreshIp(page);
  await page.goto(options.invite ? `/?invite=${options.invite}` : "/");
  await expect(page.getByRole("heading", { name: "One plan. Every week. Your crew sees you show up." })).toBeVisible();
  await page.getByRole("link", { name: "Build my week" }).click();
  await expect(page.getByText("3 days a week — solid.")).toBeVisible();
  await page.getByRole("button", { name: "Continue" }).click();
  await page.getByRole("button", { name: "Brand new" }).click();
  await expect(page.getByRole("heading", { name: "What do you have access to?" })).toBeVisible();
  await page.getByRole("button", { name: "Full gym" }).click();
  await expect(page.getByRole("heading", { name: "Your week, built." })).toBeVisible();
  await expect(page.getByText("Tap any exercise to swap it.")).toBeVisible();
  await page.getByRole("button", { name: "Looks good" }).click();
  await expect(page.getByRole("heading", { name: "Save your plan" })).toBeVisible();
  await page.getByLabel("Name").fill("Journey");
  await page.getByLabel("Email").fill(email);
  await page.getByLabel("Password").fill("journey password 1");
  await page.getByLabel("Birth year").fill("1994");
  await page.getByRole("button", { name: "Save your plan" }).click();
  return email;
}

// The generated week is Mon/Wed/Fri (1B); a journey that logs a workout must not depend on the weekday it runs on, so the
// member's own plan (Flow 8: theirs to edit) gains today as a planned day — a copy of the first workout — when it lacks one.
// The 3 AM day (E8) in the member's zone is "today", the same day Home judges.
export async function ensureTodayHasAWorkout(page: Page): Promise<void> {
  const me = (await (await page.request.get("/api/v1/users/me")).json()) as { user: { timezone: string } };
  const today = isoWeekday(dayKeyFor(new Date(), me.user.timezone));
  const plan = (await (await page.request.get("/api/v1/plans")).json()) as { workouts: { weekday: number }[] };
  if (plan.workouts.some((workout) => workout.weekday === today)) return;
  const saved = await page.request.put("/api/v1/plans", { data: { workouts: [...plan.workouts, { ...plan.workouts[0], weekday: today }] } });
  expect(saved.status()).toBe(200);
}

// Server-rendered pages hydrate after load; a fill that lands before React attaches its handlers never reaches state (seen on
// WebKit at 375). React marks a mounted element with its internal props key — wait for it, then fill.
export async function waitForHydration(page: Page, selector: string): Promise<void> {
  await page.waitForFunction((target) => {
    const element = document.querySelector(target);
    return element !== null && Object.keys(element).some((key) => key.startsWith("__reactProps"));
  }, selector, { timeout: 15_000 });
}

export async function fillWhenHydrated(page: Page, label: string, text: string, buttonName: string): Promise<void> {
  await waitForHydration(page, "textarea, input");
  await expect(async () => {
    await page.getByLabel(label).fill(text);
    await expect(page.getByRole("button", { name: buttonName })).toBeEnabled({ timeout: 1_000 });
  }).toPass({ timeout: 15_000 });
}

// 6.7 / 8.9: no horizontal scroll at any width from 360 to 1920
export async function expectNoHorizontalScroll(page: Page): Promise<void> {
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
  expect(overflow).toBeLessThanOrEqual(0);
}
