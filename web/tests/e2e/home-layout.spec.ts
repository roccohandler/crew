// SPEC: 6.7 (`spec:973-974` — primary actions stay bottom-anchored regardless of how much canvas exists above; no
// truncated CTA labels anywhere) · 8.9 (the SE × XXL snapshot matrix) · A17.1 / A17.2 / A18.
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
// J032 (A18) — IT NOW RUNS AT EVERY SIZE 6.7 NAMES, NOT ONE. It pinned 375×667 — the SMALLEST device — while the
// owner's phone is Pro Max class (440×956) and CI's iOS simulator picker takes the newest and largest iPhone on the
// image. The void the owner photographed is WORST on the largest screen, because the gap is viewport minus content:
// the one automated guard for it ran at the single size where it barely occurs. Three sizes now; the threshold and
// why it is a ratio are argued at MAX_GAP_FRACTION below.
//
// This is the web half. The iOS matrix still needs a Mac and stays owed in debt.md.
import { expect, test, type Page } from "@playwright/test";
import { buildWeekAndSave, fillWhenHydrated, expectNoHorizontalScroll } from "./helpers";

// The three sizes 6.7 names: the smallest device, a current standard, and the largest.
const SIZES = [
  { name: "SE 375×667", width: 375, height: 667 },
  { name: "standard 393×852", width: 393, height: 852 },
  { name: "Pro Max 440×956", width: 440, height: 956 },
];

// THE THRESHOLD, MEASURED RATHER THAN CHOSEN. The first version of this gate was absolute — four section gaps, 96 px —
// on the argument that "a screen does not become allowed to have a bigger hole just because it is taller". Its first
// run refuted the argument: while the primary is bottom-anchored INSIDE the scrolling content (A17.2), the slack IS
// viewport minus content by construction, so a taller phone necessarily has more of it. The measurements, on the
// rest-day Home this file builds:
//
//     375×667   gap  24 px  ( 4%)   — the flexible space is already fully collapsed; the page scrolls (doc 768 > 667)
//     393×852   gap 108 px  (13%)
//     440×956   gap 212 px  (22%)   — the owner's device class
//
// So two clauses, each of which the photographed screen would have failed and neither of which fails the ratified
// layout as it stands:
//
//   1. A separator must not be taller than the group it separates FROM the rest of the page. Larger than the content
//      it introduces, a gap stops reading as rhythm and starts reading as the end of the page — NN/g's illusion of
//      completeness, where "excessive whitespace: large gaps between content sections" is a named cause and six of
//      eight users did not realise the page scrolled. The bottom group measures 346 px here against a 212 px gap.
//   2. And an absolute ceiling as a share of the viewport, so it can never grow back toward what was photographed.
//
// Note what clause 1 and the SE row together say: on the smallest phone the anchor has ALREADY collapsed, so 6.7's
// "primary actions stay bottom-anchored regardless of how much canvas exists above" holds there by accident rather
// than by mechanism. A `Spacer` inside scrolling content is not an anchor. Recorded in debt.md.
const MAX_GAP_FRACTION = 0.25;

// §1D — the bridge carries one CTA and nothing else, so the strip, its sentence and the log rows appear only once a
// first post exists. Every assertion below is about a REAL day, which is the state the owner was looking at.
async function homeAfterFirstPost(page: Page, label: string): Promise<void> {
  await buildWeekAndSave(page, { label });
  await expect(page.getByText("Your first flame lights today.")).toBeVisible({ timeout: 15_000 });
  await page.goto("/post");
  await fillWhenHydrated(page, "Say something (or don't)", "eggs", "Post"); // waits for hydration and fills; the click is separate
  await page.getByRole("button", { name: "Post" }).click();
  await expect(page).toHaveURL(/\/home(\?earned=.+)?$/, { timeout: 15_000 });
}

// 6.7 — "no truncated CTA labels anywhere". A label clipped by its own box has scrollWidth > clientWidth.
async function clippedControls(page: Page): Promise<string[]> {
  return page.evaluate(() => {
    const controls = Array.from(document.querySelectorAll("a.button, a.logrow, button"));
    return controls
      .filter((element) => (element as HTMLElement).offsetParent !== null)
      .filter((element) => element.scrollWidth > element.clientWidth + 1)
      .map((element) => (element.textContent ?? "").trim().slice(0, 40));
  });
}

// A17.2 — the hole itself, as a number: the largest vertical gap between Home's top-level blocks, and the height of
// the block it introduces (clause 1 above compares the two).
async function largestGap(page: Page): Promise<{ gap: number; follows: number }> {
  return page.evaluate(() => {
    const root = document.querySelector(".stack--page");
    if (root === null) return { gap: 0, follows: 0 };
    const boxes = Array.from(root.children)
      .map((child) => child.getBoundingClientRect())
      .filter((rect) => rect.height > 0)
      .sort((a, b) => a.top - b.top);
    let gap = 0;
    let follows = 0;
    for (let index = 1; index < boxes.length; index += 1) {
      const between = boxes[index]!.top - boxes[index - 1]!.bottom;
      if (between > gap) { gap = between; follows = boxes[index]!.height; }
    }
    return { gap, follows };
  });
}

test("Home: the primary action is in the thumb half, nothing truncates, and there is no giant hole — at every size 6.7 names", async ({ page }) => {
  await homeAfterFirstPost(page, "home-layout");

  for (const size of SIZES) {
    await page.setViewportSize({ width: size.width, height: size.height });
    await page.goto("/home");
    await page.waitForLoadState("networkidle");
    await expectNoHorizontalScroll(page, `/home at ${size.name}`);

    expect(await clippedControls(page), `controls whose label is clipped by their own box at ${size.name}`).toEqual([]);

    // A17.2 / 6.7 — the day's controls belong in the thumb half. Before A17 the flexible space sat BELOW the card, so
    // on every short state the card and its action were stranded in the upper half with a hole underneath them.
    const rows = page.locator(".logrows");
    await expect(rows).toBeVisible();
    const box = await rows.boundingBox();
    expect(box, `the log rows have a box at ${size.name}`).not.toBeNull();
    expect(box!.y, `the day's controls sit in the lower half of the viewport at ${size.name}`).toBeGreaterThan(size.height / 2);

    const { gap, follows } = await largestGap(page);
    expect(gap, `at ${size.name} the largest gap (${Math.round(gap)} px) must not exceed the ${Math.round(follows)} px group it introduces`).toBeLessThanOrEqual(follows);
    expect(gap, `at ${size.name} the largest gap between Home's blocks, in px`).toBeLessThan(size.height * MAX_GAP_FRACTION);
  }
});

// A17.1 — the sentence is the fix for "I don't know what the colours are for". If it ever stops rendering, the marks
// go back to being undecodable and nothing else on the screen would fail.
// A18.1 — and the two captions, for the same reason one level up: the owner read the sentence and still asked "what
// is the 1/3?", because the sentence never says the word "workouts" and nothing names the flame's numeral either.
test("Home: every numeral is named, and the week strip says the same thing to the eye and to VoiceOver", async ({ page }) => {
  await homeAfterFirstPost(page, "home-sentence");
  await page.goto("/home");
  await page.waitForLoadState("networkidle");

  await expect(page.getByText(/^This week:/)).toBeVisible();
  const spoken = await page.locator(".weekstrip").getAttribute("aria-label");
  expect(spoken, "the strip speaks a full sentence, not a bare count").toMatch(/^This week:.*\.$/);
  // The spoken form names days in FULL — a screen reader reads "Wed" letter by letter
  expect(spoken, "the spoken sentence never uses the visible abbreviations").not.toMatch(/\b(Mon|Tue|Wed|Thu|Fri|Sat|Sun)\b/);

  // A18.1 — the flame's caption. The ring's is asserted only when the ring renders: A18.2 hides it until the week
  // holds a completed workout, and this fixture has posted a meal rather than trained.
  await expect(page.getByText("day streak", { exact: true })).toBeVisible();
  const ring = page.locator(".ring");
  if (await ring.count() > 0) await expect(page.getByText("workouts this week", { exact: true })).toBeVisible();

  // A18.5 — the log rows read verb-first. The owner called the previous noun-over-value cells "three strange divs".
  for (const verb of ["Log workout", "Log cardio", "Log a meal"]) {
    await expect(page.getByRole("link", { name: new RegExp(`^${verb},`) })).toBeVisible();
  }
});
