// SPEC: 8.5 Accessibility Pass (web) — axe-core is not in the approved dependency list, so the automated pass is this
// substitute: every page has one main landmark and one h1, every image has alt, every button/link has a name, every
// field has a label, and (8.9) nothing scrolls horizontally from 360 to 1920 · 6.5 semantic landmarks, keyboard-complete · T043
import { expect, test, type Page } from "@playwright/test";
import { buildWeekAndSave, expectNoHorizontalScroll } from "./helpers";

interface Audit { mains: number; h1s: number; unnamedImages: number; unnamedControls: string[]; unlabelledFields: string[] }

async function audit(page: Page): Promise<Audit> {
  return page.evaluate(() => {
    const visible = (element: Element) => (element as HTMLElement).offsetParent !== null || element.tagName === "MAIN";
    const named = (element: Element) => (element.textContent ?? "").trim().length > 0 || (element.getAttribute("aria-label") ?? "").trim().length > 0 || element.getAttribute("aria-labelledby") !== null || (element.getAttribute("title") ?? "").trim().length > 0;
    const labelled = (field: Element) => {
      if ((field.getAttribute("aria-label") ?? "").trim().length > 0 || field.getAttribute("aria-labelledby") !== null) return true;
      if (field.closest("label") !== null) return true;
      const id = field.getAttribute("id");
      return id !== null && document.querySelector(`label[for="${id}"]`) !== null;
    };
    const controls = Array.from(document.querySelectorAll("button, a[href]")).filter(visible);
    const fields = Array.from(document.querySelectorAll("input:not([type=hidden]), textarea, select")).filter(visible);
    return {
      mains: document.querySelectorAll("main").length,
      h1s: document.querySelectorAll("h1").length,
      unnamedImages: Array.from(document.querySelectorAll("img")).filter((image) => !image.hasAttribute("alt") && image.getAttribute("role") !== "presentation").length,
      unnamedControls: controls.filter((control) => !named(control)).map((control) => control.outerHTML.slice(0, 80)),
      unlabelledFields: fields.filter((field) => !labelled(field)).map((field) => field.outerHTML.slice(0, 80)),
    };
  });
}

async function expectAccessible(page: Page, path: string): Promise<void> {
  await page.goto(path);
  await page.waitForLoadState("networkidle");
  await page.locator("h1").first().waitFor({ state: "attached", timeout: 15_000 }); // client-fetched pages (crew) audit their ready state, not their skeleton
  const result = await audit(page);
  expect(result.mains, `${path}: one main landmark`).toBe(1);
  expect(result.h1s, `${path}: one h1`).toBe(1);
  expect(result.unnamedImages, `${path}: images without alt`).toBe(0);
  expect(result.unnamedControls, `${path}: controls without a name`).toEqual([]);
  expect(result.unlabelledFields, `${path}: fields without a label`).toEqual([]);
  await expectNoHorizontalScroll(page);
}

test("public pages: landmarks, names, labels, no sideways scroll", async ({ page }) => {
  for (const path of ["/", "/login", "/reset", "/onboarding"]) await expectAccessible(page, path);
});

test("signed-in pages: landmarks, names, labels, no sideways scroll", async ({ page }) => {
  await buildWeekAndSave(page, { label: "a11y" });
  await expect(page.getByText("Your first flame lights today.")).toBeVisible({ timeout: 15_000 });
  for (const path of ["/home", "/post", "/plan", "/crew", "/progress", "/journal", "/settings", "/session/new"]) await expectAccessible(page, path);
});

// 8.9: 360 → 1920, nothing scrolls sideways; 6.7 single column stays a column
test("responsiveness sweep on the two densest pages", async ({ page }) => {
  await buildWeekAndSave(page, { label: "widths" });
  await expect(page.getByText("Your first flame lights today.")).toBeVisible({ timeout: 15_000 });
  for (const width of [360, 414, 600, 1024, 1920]) {
    await page.setViewportSize({ width, height: 900 });
    for (const path of ["/plan", "/session/new"]) {
      await page.goto(path);
      await page.waitForLoadState("networkidle");
      await expectNoHorizontalScroll(page);
    }
  }
});

// 6.5 keyboard-complete: Tab reaches the first action on the hero and Enter follows it
test("keyboard: the hero's first action is reachable by Tab and works with Enter", async ({ page, isMobile }) => {
  test.skip(isMobile, "the phone descriptor has no hardware keyboard; keyboard completeness is a desktop/tablet check");
  await page.goto("/");
  await page.keyboard.press("Tab");
  const focused = await page.evaluate(() => document.activeElement?.textContent?.trim() ?? "");
  expect(focused.length).toBeGreaterThan(0);
  await page.keyboard.press("Enter");
  await expect(page).not.toHaveURL(/^http:\/\/localhost:3000\/$/);
});
