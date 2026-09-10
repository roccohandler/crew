// SPEC: 6.7 (`spec:973-974` — primary actions stay bottom-anchored regardless of how much canvas exists above; no
// truncated CTA labels anywhere) · 8.9 (the SE × XXL snapshot matrix) · A17.1 / A17.2.
//
// WHY THIS FILE EXISTS (H036, 2026-09-10). Spec 8.9 requires Home rendered at SE 375×667 and Pro Max 440×956 ×
// {default, accessibility-XXL} and DIFFED IN CI. That matrix has never been built, and its absence was itself
// unrecorded — so a ~22% contiguous void and an XXL label truncation shipped to TestFlight with every CI job green.
// Nothing anywhere looked at Home's layout.
//
// Pixel baselines have to be RECORDED on a Mac, and this project does not have one (docs/testing-without-a-mac.md).
// So this asserts the layout PROPERTIES the spec actually states, which need no baseline and no hardware. It earned
// its place immediately: on its first run it found that the web bottom anchor did nothing at all, because
// `min-height: 100%` resolved against a parent whose height was `auto`. The primary sat at y=186 on a 667 px phone.
//
// This is the web half. The iOS matrix still needs a Mac and stays owed in debt.md.
import { expect, test } from "@playwright/test";
import { buildWeekAndSave, fillWhenHydrated, expectNoHorizontalScroll } from "./helpers";

// The SE-class width the spec names, and the one CI's simulator picker has never selected.
const SE = { width: 375, height: 667 };

// §1D — the bridge carries one CTA and nothing else, so the strip, its sentence and the vector row appear only once a
// first post exists. Every assertion below is about a REAL day, which is the state the owner was looking at.
async function homeAfterFirstPost(page: Parameters<typeof buildWeekAndSave>[0], label: string): Promise<void> {
  await buildWeekAndSave(page, { label });
  await expect(page.getByText("Your first flame lights today.")).toBeVisible({ timeout: 15_000 });
  await page.goto("/post");
  await fillWhenHydrated(page, "Say something (or don't)", "eggs", "Post"); // waits for hydration and fills; the click is separate
  await page.getByRole("button", { name: "Post" }).click();
  await expect(page).toHaveURL(/\/home(\?earned=.+)?$/, { timeout: 15_000 });
  await page.setViewportSize(SE);
  await page.goto("/home");
  await page.waitForLoadState("networkidle");
}

test("Home: the primary action is in the thumb half, nothing truncates, and there is no giant hole", async ({ page }) => {
  await homeAfterFirstPost(page, "home-layout");
  await expectNoHorizontalScroll(page, "/home at 375");

  // 6.7 — "no truncated CTA labels anywhere". A label clipped by its own box has scrollWidth > clientWidth. This is
  // the shape of check that would have caught "Bonus workout" wrapping to "Bonus" / "worko…" at accessibility sizes.
  const clipped = await page.evaluate(() => {
    const controls = Array.from(document.querySelectorAll("a.button, a.vectorslot, button"));
    return controls
      .filter((element) => (element as HTMLElement).offsetParent !== null)
      .filter((element) => element.scrollWidth > element.clientWidth + 1)
      .map((element) => (element.textContent ?? "").trim().slice(0, 40));
  });
  expect(clipped, "controls whose label is clipped by their own box").toEqual([]);

  // A17.2 / 6.7 — the day's controls belong in the thumb half. Before A17 the flexible space sat BELOW the card, so
  // on every short state the card and its action were stranded in the upper half with a hole underneath them.
  const row = page.locator(".vectorrow");
  await expect(row).toBeVisible();
  const box = await row.boundingBox();
  expect(box, "the vector row has a box").not.toBeNull();
  expect(box!.y, "the day's controls sit in the lower half of the viewport").toBeGreaterThan(SE.height / 2);

  // A17.2 — and the hole itself, expressed as a number. The largest vertical gap between Home's top-level blocks must
  // not be a sizeable fraction of the screen; that gap IS the defect the owner reported.
  const largestGap = await page.evaluate(() => {
    const root = document.querySelector(".stack--page");
    if (root === null) return 0;
    const boxes = Array.from(root.children)
      .map((child) => child.getBoundingClientRect())
      .filter((rect) => rect.height > 0)
      .sort((a, b) => a.top - b.top);
    let gap = 0;
    for (let index = 1; index < boxes.length; index += 1) gap = Math.max(gap, boxes[index]!.top - boxes[index - 1]!.bottom);
    return gap;
  });
  expect(largestGap, "the largest gap between Home's blocks, in px").toBeLessThan(SE.height / 3);
});

// A17.1 — the sentence is the fix for "I don't know what the colours are for". If it ever stops rendering, the marks
// go back to being undecodable and nothing else on the screen would fail.
test("Home: the week strip carries its sentence, and says the same thing to VoiceOver", async ({ page }) => {
  await homeAfterFirstPost(page, "home-sentence");
  await expect(page.getByText(/^This week:/)).toBeVisible();
  const spoken = await page.locator(".weekstrip").getAttribute("aria-label");
  expect(spoken, "the strip speaks a full sentence, not a bare count").toMatch(/^This week:.*\.$/);
  // The spoken form names days in FULL — a screen reader reads "Wed" letter by letter
  expect(spoken, "the spoken sentence never uses the visible abbreviations").not.toMatch(/\b(Mon|Tue|Wed|Thu|Fri|Sat|Sun)\b/);
});
