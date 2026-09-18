// SPEC: 8.4 journey ⑤ (W065) · nutrition addendum §4, §6 (RATIFIED 2026-09-18) — macro logging end to end on web: Home's "Log
// macros" row → the first-run bodyweight → the estimate → a saved meal by hand → one from a chain → the template → ONE tap logs,
// the same tap undoes → quick add → delete → targets by hand + Recalculate → the methodology page and its links → Settings'
// two-step delete. It pins the clauses a screen could break: ② state is ink words on their own line, never a colour; ③ a log
// moves no XP; ④ a log is no post. And A16.c: a 15-year-old has no row, no page and no Settings rows — with no copy.
import { expect, test, type Page } from "@playwright/test";
import { buildWeekAndSave, completeWorkoutViaApi, expectNoHorizontalScroll, waitForHydration } from "./helpers";

const grams = (page: Page, name: string) => page.getByRole("spinbutton", { name: `${name} grams` });
const line = (page: Page, name: string) => page.getByRole("group", { name: new RegExp(`^${name}: `) });

async function xpAndPosts(page: Page): Promise<{ xp: number; posts: number }> {
  const me = (await (await page.request.get("/api/v1/users/me")).json()) as { gamification: { xp: number } };
  const posts = (await (await page.request.get("/api/v1/posts")).json()) as { items: object[] };
  return { xp: me.gamification.xp, posts: posts.items.length };
}

async function pastTheBridge(page: Page, label: string, birthYear?: string): Promise<void> {
  await buildWeekAndSave(page, { label, birthYear });
  await expect(page.getByText(/^Your (first flame lights today|plan rests today)\./)).toBeVisible({ timeout: 15_000 });
  await completeWorkoutViaApi(page, { cardio: true }); // the log rows sit behind the first post (1D)
  await page.goto("/home");
}

test("journey ⑤: targets, saved meals, the template, one-tap logging, quick add, delete", async ({ page }) => {
  await pastTheBridge(page, "j5");
  await page.getByRole("link", { name: "Log macros, nothing logged today" }).click();
  await expect(page.getByRole("heading", { name: "Today" })).toBeVisible({ timeout: 15_000 });
  await waitForHydration(page, "input"); // a fill that lands before React attaches never reaches state (helpers.ts)
  await page.getByLabel("Bodyweight (lb)").fill("176");
  await page.getByRole("button", { name: "Estimate my targets" }).click();
  await expect(line(page, "Protein")).toHaveAccessibleName("Protein: 0 / 145 g, 145 to go", { timeout: 15_000 }); // V58: 176 lb derives 80 kg's lines
  await expect(line(page, "Carbs")).toHaveAccessibleName("Carbs: 0 / 385 g, 385 to go");
  await expect(line(page, "Fat")).toHaveAccessibleName("Fat: 0 / 60 g, 60 to go");
  await expect(line(page, "Calories")).toHaveAccessibleName("Calories: 0 / 2660 kcal, 2660 to go");
  await expect(page.getByText("Build your usual day once. After that, one tap logs a meal.")).toBeVisible(); // the empty state is the invitation
  await expectNoHorizontalScroll(page, "today, empty");
  const before = await xpAndPosts(page);

  await page.getByRole("link", { name: "Saved meals & template" }).click();
  await expect(page.getByRole("heading", { name: "Saved meals & template" })).toBeVisible({ timeout: 15_000 });
  await waitForHydration(page, "button.button--secondary");
  await page.getByRole("button", { name: "Add a meal" }).click();
  await page.getByLabel("Name").fill("Oats and whey");
  await grams(page, "Protein").fill("30");
  await grams(page, "Carbs").fill("45");
  await grams(page, "Fat").fill("10");
  await page.getByRole("button", { name: "Save meal" }).click();
  await expect(page.getByText("Oats and whey · P 30 · C 45 · F 10")).toBeVisible();
  await page.getByRole("button", { name: "Add from a chain" }).click();
  await page.getByRole("button", { name: "Chipotle" }).click();
  await page.getByRole("button", { name: /^Chicken/ }).first().click(); // the chain's own published numbers, copied into the form
  await expect(page.getByLabel("Name")).not.toHaveValue("");
  await page.getByRole("button", { name: "Save meal" }).click();
  await expect(page.getByRole("button", { name: /^Edit / })).toHaveCount(2);
  await expectNoHorizontalScroll(page, "saved meals");

  await page.getByRole("link", { name: "Template" }).click();
  await expect(page.getByText("Your usual day, in order.")).toBeVisible({ timeout: 15_000 });
  await waitForHydration(page, "select");
  await page.getByLabel("Label (optional)").fill("Breakfast");
  await page.getByRole("button", { name: "Add to template" }).click();
  await expect(page.getByText("Breakfast · Oats and whey · P 30 · C 45 · F 10")).toBeVisible();
  await expectNoHorizontalScroll(page, "template");

  await page.goto("/nutrition");
  await waitForHydration(page, "button.logrow");
  const slot = page.getByRole("button", { name: /^Breakfast · Oats and whey/ });
  await slot.click(); // ONE tap logs it
  await expect(slot).toHaveAttribute("aria-pressed", "true");
  await expect(line(page, "Protein")).toHaveAccessibleName("Protein: 30 / 145 g, 115 to go");
  await slot.click(); // the same tap undoes it, in place
  await expect(slot).toHaveAttribute("aria-pressed", "false");
  await expect(line(page, "Protein")).toHaveAccessibleName("Protein: 0 / 145 g, 145 to go");
  await slot.click();
  await grams(page, "Protein").fill("120");
  await page.getByRole("button", { name: "Add", exact: true }).click();
  await expect(line(page, "Protein")).toHaveAccessibleName("Protein: 150 / 145 g, 5 over"); // clause ②: a fact in ink words, no colour
  await expect(page.getByText("Tomorrow starts from your full targets.")).toBeVisible(); // …naming tomorrow in the same breath
  await expect(page.locator(".macro__rest").first()).toHaveCSS("color", await page.locator("h1").evaluate((heading) => getComputedStyle(heading).color));
  // the screen is optimistic; the reload below must read what the SERVER holds, so the delete's own reply is awaited first
  await Promise.all([
    page.waitForResponse((reply) => reply.url().includes("/api/v1/nutrition/logs/") && reply.request().method() === "DELETE" && reply.ok()),
    page.getByRole("button", { name: /^Delete Quick add/ }).click(),
  ]);
  await expect(line(page, "Protein")).toHaveAccessibleName("Protein: 30 / 145 g, 115 to go");
  await expectNoHorizontalScroll(page, "today, logged");
  await page.reload();
  await expect(line(page, "Protein")).toHaveAccessibleName("Protein: 30 / 145 g, 115 to go"); // the server kept exactly one log
  expect(await xpAndPosts(page)).toEqual(before); // clauses ③ ④: no XP, no post
  await page.goto("/home");
  await expect(page.getByRole("link", { name: "Log macros, 1 logged today" })).toBeVisible();
});

test("journey ⑤: targets by hand, Recalculate, the methodology page, and the two-step delete", async ({ page }) => {
  await pastTheBridge(page, "j5-settings");
  await page.goto("/nutrition");
  await waitForHydration(page, "input");
  await page.getByLabel("Bodyweight (lb)").fill("176");
  await page.getByRole("button", { name: "Estimate my targets" }).click();
  await expect(line(page, "Protein")).toHaveAccessibleName("Protein: 0 / 145 g, 145 to go", { timeout: 15_000 });
  await page.goto("/settings");
  await page.getByRole("link", { name: "Nutrition targets" }).click();
  await expect(page.getByRole("heading", { name: "Nutrition targets" })).toBeVisible({ timeout: 15_000 });
  await expect(page.getByText(/^Estimated from your bodyweight\./)).toBeVisible();
  await waitForHydration(page, "input.gramfield__input");
  await grams(page, "Protein").fill("160");
  await page.getByRole("button", { name: "Save targets" }).click();
  await expect(page.getByText(/^Set by you\./)).toBeVisible({ timeout: 15_000 });
  await page.getByRole("button", { name: "Recalculate from bodyweight" }).click();
  await expect(grams(page, "Protein")).toHaveValue("145", { timeout: 15_000 });
  await expectNoHorizontalScroll(page, "targets");
  await page.getByRole("link", { name: "How targets are estimated" }).click();
  await expect(page.getByRole("heading", { name: "How targets are estimated" })).toBeVisible({ timeout: 15_000 });
  await expect(page.getByText(/not medical advice/)).toBeVisible();
  const sources = await page.locator("article a").evaluateAll((links) => links.map((link) => link.getAttribute("href") ?? ""));
  expect(sources.length).toBe(4); // A16.a: every source is a link
  expect(sources.every((href) => href.startsWith("https://"))).toBe(true);
  await expectNoHorizontalScroll(page, "method");
  await page.goto("/settings");
  await waitForHydration(page, "section[aria-label=Nutrition] button");
  await page.getByRole("button", { name: "Delete my nutrition data" }).click();
  await expect(page.getByText(/It can't be undone\./)).toBeVisible();
  await page.getByRole("button", { name: "Delete my nutrition data" }).click();
  await expect(page.getByRole("status")).toHaveText("Deleted.");
  await page.goto("/nutrition");
  await expect(page.getByRole("button", { name: "Estimate my targets" })).toBeVisible({ timeout: 15_000 }); // V64: the bodyweight went with the targets
});

test("A16.c: under 18 there is no row, no page and no Settings rows — and no copy about it", async ({ page }) => {
  await pastTheBridge(page, "j5-minor", String(new Date().getFullYear() - 15));
  await expect(page.getByRole("link", { name: /^Log workout/ })).toBeVisible({ timeout: 15_000 });
  await expect(page.getByRole("link", { name: /^Log macros/ })).toHaveCount(0);
  for (const path of ["/nutrition", "/nutrition/meals", "/nutrition/template", "/nutrition/targets", "/nutrition/method"]) expect((await page.goto(path))?.status(), path).toBe(404);
  await page.goto("/settings");
  await expect(page.getByRole("heading", { name: "Settings" })).toBeVisible({ timeout: 15_000 });
  await expect(page.getByRole("heading", { name: "Nutrition" })).toHaveCount(0);
  await expect(page.getByText(/unlock|18+|over 18|adults? only/i)).toHaveCount(0); // no upsell, no "unlock at 18"
});
