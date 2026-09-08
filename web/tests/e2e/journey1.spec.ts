// SPEC: 8.4 journey ① on web — fresh visitor → questions → plan → save → first post → the bridge is gone, the flame is lit · T036/T039
import { expect, test } from "@playwright/test";
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
});
