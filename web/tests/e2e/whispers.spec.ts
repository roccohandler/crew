// SPEC: A23 (Appendix A 2026-09-18, the education layer) · docs/education-copy-draft.md §A, §C, §D — a whisper shows ONCE, leaves on
// the first tap anywhere, and its seen-state is SERVER-SIDE: the two reveal whispers a visitor saw before the account existed join
// the account at the first signed-in load, a dismissal survives a reload, and it survives the browser forgetting everything (the
// phone and the web agree). And S19: the page prints every whisper verbatim in trigger order — twelve for an adult, nine under 18,
// where the Protein section also drops its numeric sentence and its source, with no copy about the omission (A16.c).
import { expect, test, type Page } from "@playwright/test";
import { buildWeekAndSave } from "./helpers";

const PAUSE = "Away a while? Pause the plan. The streak stays whole.";

async function seenOnServer(page: Page): Promise<string[]> {
  return ((await (await page.request.get("/api/v1/users/me")).json()) as { user: { whispersSeen: string[] } }).user.whispersSeen;
}

test("a whisper shows once, leaves on the first tap, and the account remembers it on any device", async ({ page }) => {
  await buildWeekAndSave(page, { label: "whisper" }); // the helper asserts the 1C swap whisper on the reveal, now part of the system
  await expect(page.getByText(/^Your (first flame lights today|plan rests today)\./)).toBeVisible({ timeout: 15_000 });
  await page.goto("/settings");
  await expect(page.getByText(PAUSE)).toBeVisible({ timeout: 15_000 });
  await expect.poll(() => seenOnServer(page), { timeout: 15_000 }).toEqual(expect.arrayContaining(["why.ppl", "how.revealSwap"])); // seen before the account existed
  await page.getByRole("heading", { name: "Settings" }).click(); // the first tap ANYWHERE on the screen
  await expect(page.getByText(PAUSE)).toHaveCount(0);
  await expect.poll(() => seenOnServer(page), { timeout: 15_000 }).toContain("how.pause");
  await page.evaluate(() => window.localStorage.clear()); // another browser, another device: only the server remembers
  await page.reload();
  await expect(page.getByRole("heading", { name: "Settings" })).toBeVisible({ timeout: 15_000 });
  await page.waitForLoadState("networkidle");
  await expect(page.getByText(PAUSE)).toHaveCount(0);
});

// A23 RATIFIED 2026-09-19 (R-081): the page prints the owner's amended lines from the generated copy — the note, the rest-day
// sentence the streak section gained, and the two new whisper lines in the list — and says "Draft" nowhere.
test("S19 How Crew works: the ratified note, the sections and the whispers — twelve for an adult, nine under 18", async ({ page }) => {
  await buildWeekAndSave(page, { label: "s19" });
  await expect(page.getByText(/^Your (first flame lights today|plan rests today)\./)).toBeVisible({ timeout: 15_000 });
  await page.goto("/settings");
  await page.waitForLoadState("networkidle"); // Blocked people loads after the first paint and moves everything under it — the About link included
  await page.getByRole("link", { name: "How Crew works" }).click();
  await expect(page.getByRole("heading", { name: "How Crew works" })).toBeVisible({ timeout: 15_000 });
  await expect(page.getByRole("heading", { name: "A note from Max" })).toBeVisible();
  await expect(page.getByText(/everything in here is what I do myself/)).toBeVisible();
  await expect(page.getByText("Draft", { exact: true })).toHaveCount(0);
  await expect(page.getByText(/Rest days are free: the flame counts your training days, and a rest day never breaks it\./)).toBeVisible();
  await expect(page.locator("ol > li")).toHaveCount(12);
  await expect(page.locator("ol > li", { hasText: "Your crew sees you show up. That's the whole system." })).toHaveCount(1);
  await expect(page.locator("ol > li", { hasText: "Same breakfast and lunch every day. Dinner's yours." })).toHaveCount(1);
  await expect(page.getByText(/1 g per pound is the easy target/)).toBeVisible();
  await expect(page.getByRole("link", { name: /^Morton et al\./ })).toBeVisible();
});

test("S19 under 18: no protein numbers, no protein source, no nutrition whispers — and no copy about it", async ({ page }) => {
  await buildWeekAndSave(page, { label: "s19-minor", birthYear: String(new Date().getFullYear() - 15) });
  await expect(page.getByText(/^Your (first flame lights today|plan rests today)\./)).toBeVisible({ timeout: 15_000 });
  await page.goto("/how-crew-works");
  await expect(page.getByRole("heading", { name: "Protein first" })).toBeVisible({ timeout: 15_000 });
  await expect(page.locator("ol > li")).toHaveCount(9);
  await expect(page.locator("ol > li", { hasText: "Your crew sees you show up. That's the whole system." })).toHaveCount(1); // gate: all
  await expect(page.locator("ol > li", { hasText: "Same breakfast and lunch every day. Dinner's yours." })).toHaveCount(0); // gate: adult
  await expect(page.getByText(/per pound/)).toHaveCount(0);
  await expect(page.getByRole("link", { name: /^Morton et al\./ })).toHaveCount(0);
  await expect(page.getByRole("link", { name: /^Schoenfeld/ })).toBeVisible(); // the training source is for every age
});
