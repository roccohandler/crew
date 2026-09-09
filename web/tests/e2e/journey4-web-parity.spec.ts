// SPEC: 8.4 journey ④ — full plan build + workout log on web (parity proof); keyboard-first logging; the celebration's numbers
// come from the engine · A4 (the plan edit goes week map → /plan/push → exercise sheet → Save → "Saved · applies from your
// next Push day") · T037/T039
import { expect, test } from "@playwright/test";
import { buildWeekAndSave, ensureTodayHasAWorkout, expectNoHorizontalScroll } from "./helpers";

test("plan build then a full workout log on web, keyboard-first", async ({ page }) => {
  await buildWeekAndSave(page, { label: "j4" });
  await expect(page.getByText("Your first flame lights today.")).toBeVisible({ timeout: 15_000 });
  await ensureTodayHasAWorkout(page); // Mon/Wed/Fri by default; the log must run on any weekday
  await page.goto("/session/new");
  await expect(page.getByText(/\/\d+ sets/)).toBeVisible({ timeout: 15_000 });
  await expectNoHorizontalScroll(page);
  const firstSet = page.getByRole("button", { name: /set 1 of/ }).first();
  await firstSet.focus();
  await page.keyboard.press("Enter");
  await expect(firstSet).toHaveAttribute("aria-pressed", "true");
  await expect(page.getByText(/^1\/\d+ sets/)).toBeVisible();
  await page.getByRole("button", { name: "Complete workout" }).click();
  await expect(page).toHaveURL(/\/session\/[a-f0-9]+\/done(\?earned=.+)?$/, { timeout: 15_000 }); // completion = PATCH + recompute + the first compile of /done under next dev
  await expect(page.getByText(/^1\/\d+ sets · \d+ min/)).toBeVisible();
  await expect(page.getByText("Showed up")).toBeVisible(); // E8: the first completion unlocks Showed up in the celebration
  await expect(page.getByText(/125 XP total/)).toBeVisible(); // V25: day-one total 125
  await expect(page.getByLabel("Streak 1")).toBeVisible();
  await expectNoHorizontalScroll(page);
  await page.getByRole("link", { name: "Done" }).click();
  await expect(page.getByRole("heading", { name: "Done for today." })).toBeVisible();
  await expect(page.getByRole("button", { name: "Quick complete" })).toHaveCount(0);
  await page.goto("/plan");
  await expect(page.getByRole("heading", { name: "Your week" })).toBeVisible();
  await expect(page.getByText(/^Monday · /)).toBeVisible(); // seven rows, Monday first — the day's word depends on the weekday the run lands on
  await expectNoHorizontalScroll(page);
  // A4: today's Push day is done (✓) and still a link into its editor; the rotation has moved on to Pull for the next planned day
  await page.getByRole("link", { name: /Push day/ }).first().click();
  await expect(page).toHaveURL(/\/plan\/push$/);
  await expect(page.getByRole("heading", { name: "Push day" })).toBeVisible();
  await expect(page.getByRole("button", { name: "Save" })).toBeDisabled();
  await page.getByRole("button", { name: /, \d+ × \d+/ }).first().click(); // the first exercise row opens the sheet
  await page.getByRole("button", { name: "Increase Sets" }).click();
  await expect(page.getByRole("button", { name: "Save" })).toBeEnabled();
  await page.getByRole("button", { name: "Done" }).click();
  await page.getByRole("button", { name: "Save" }).click();
  await expect(page).toHaveURL(/\/plan\?saved=push$/, { timeout: 15_000 });
  await expect(page.getByRole("status")).toHaveText("Saved · applies from your next Push day");
  await expectNoHorizontalScroll(page);
});
