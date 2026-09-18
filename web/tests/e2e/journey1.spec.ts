// SPEC: 8.4 journey ① on web — fresh visitor → questions → plan → save → the first workout → the bridge is gone, the flame is lit ·
// T036/T039. A22 (owner-approved 2026-09-18): the plate journal is gone, so the first post IS the first workout (S10 · A21.9);
// the bridge offers "Start your first workout" on a training day and a bonus workout on a rest day (R-070).
import { expect, test } from "@playwright/test";
import { buildWeekAndSave, completeWorkoutViaApi, ensureTodayHasAWorkout, expectNoHorizontalScroll } from "./helpers";

test("fresh visitor builds a week, saves it, and lights the first flame with the first workout", async ({ page }) => {
  await buildWeekAndSave(page, { label: "j1" });
  await expect(page.getByText(/^Your (first flame lights today|plan rests today)\./)).toBeVisible({ timeout: 15_000 });
  await expectNoHorizontalScroll(page);
  const workoutCta = page.getByRole("link", { name: "Start your first workout" });
  const bonusCta = page.getByRole("link", { name: "Start a bonus workout" });
  await expect(workoutCta.or(bonusCta)).toBeVisible();
  // The first workout on a day the plan trains (whatever weekday this runs on), completed with its post the way the session screen
  // completes one; the celebration shows what it unlocked (E8: the ids ride the URL)
  await ensureTodayHasAWorkout(page);
  const done = await completeWorkoutViaApi(page, {});
  await page.goto(`/session/${done.sessionId}/done${done.earned.length > 0 ? `?earned=${done.earned.join(",")}` : ""}`);
  await expect(page.getByText("First flame")).toBeVisible();
  await expectNoHorizontalScroll(page);
  await page.getByRole("link", { name: "Done" }).click();
  await expect(page.getByRole("heading", { name: "Done for today", exact: true })).toBeVisible({ timeout: 15_000 }); // the page title; the card's own heading ends with a full stop
  await expect(page.getByText(/^Your (first flame lights today|plan rests today)\./)).toHaveCount(0);
  await expect(page.getByLabel("Streak 1")).toBeVisible();
  await expectNoHorizontalScroll(page);
  // A1/A4: the week map — Mon/Wed/Fri rotate Push → Pull → Legs from today; a training day already past this week reads "—"
  await page.goto("/plan");
  await expect(page.getByRole("heading", { name: "Your week" })).toBeVisible();
  await expect(page.getByText("Workouts rotate Push → Pull → Legs, so each gets equal time. Changes apply from your next workout on.")).toBeVisible();
  await expect(page.getByRole("link", { name: /· ✓ Push day/ })).toBeVisible(); // today trains (ensureTodayHasAWorkout) and is done: the week map says so, whatever weekday this runs on
  await expect(page.getByRole("button", { name: "Change days" })).toBeVisible();
  await expect(page.getByRole("link", { name: "Rebuild my week" })).toBeVisible();
  await expectNoHorizontalScroll(page);
});
