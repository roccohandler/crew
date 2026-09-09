// SPEC: 8.4 journey ① on web — fresh visitor → questions → plan → save → first post → the bridge is gone, the flame is lit · T036/T039
import { expect, test } from "@playwright/test";
import { dayKeyFor, isoWeekday } from "../../src/lib/engine/day-key";
import { buildWeekAndSave, expectNoHorizontalScroll, fillWhenHydrated } from "./helpers";

test("fresh visitor builds a week, saves it, and lights the first flame with a meal post", async ({ page }) => {
  await buildWeekAndSave(page, { label: "j1" });
  await expect(page.getByText("Your first flame lights today.")).toBeVisible({ timeout: 15_000 });
  await expectNoHorizontalScroll(page);
  const workoutCta = page.getByRole("link", { name: "Start your first workout" });
  const mealCta = page.getByRole("link", { name: "Start your streak — post a meal" });
  await expect(workoutCta.or(mealCta)).toBeVisible();
  await page.goto("/post");
  await fillWhenHydrated(page, "Say something (or don't)", "protein shake post-gym", "Post");
  await expectNoHorizontalScroll(page);
  await page.getByRole("button", { name: "Post" }).click();
  await expect(page).toHaveURL(/\/home(\?earned=.+)?$/); // E8: the first post unlocks First flame and the ids ride the URL
  await expect(page.getByText("Your first flame lights today.")).toHaveCount(0);
  await expect(page.getByText("First flame")).toBeVisible();
  await expect(page.getByLabel("Streak 1")).toBeVisible();
  await expectNoHorizontalScroll(page);
  // A1/A4: the week map — Mon/Wed/Fri rotate Push → Pull → Legs from today; a training day already past this week reads "—"
  await page.goto("/plan");
  await expect(page.getByRole("heading", { name: "Your week" })).toBeVisible();
  await expect(page.getByText("Workouts rotate Push → Pull → Legs, so each gets equal time. Changes apply from your next workout on.")).toBeVisible();
  const me = (await (await page.request.get("/api/v1/users/me")).json()) as { user: { timezone: string } };
  const today = isoWeekday(dayKeyFor(new Date(), me.user.timezone));
  if (today <= 5) await expect(page.getByRole("link", { name: /· Push day/ })).toBeVisible(); // the first planned day from today gets Push
  else await expect(page.getByText("Monday · —")).toBeVisible(); // a weekend run: every training day is behind us, no word, no red
  await expect(page.getByRole("button", { name: "Change days" })).toBeVisible();
  await expect(page.getByRole("link", { name: "Rebuild my week" })).toBeVisible();
  await expectNoHorizontalScroll(page);
});
