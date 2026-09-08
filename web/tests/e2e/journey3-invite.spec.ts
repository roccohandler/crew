// SPEC: 8.4 journey ③ — invite link → landing → join → react (the growth loop; W1; S13; 1A invite-aware hero) · T038/T039
import { expect, test } from "@playwright/test";
import { buildWeekAndSave, expectNoHorizontalScroll, fromFreshIp, unique } from "./helpers";

test("an invite link lands, joins on web, and a reaction shows in the stream", async ({ browser }) => {
  const captainContext = await browser.newContext();
  const captain = await captainContext.newPage();
  await buildWeekAndSave(captain, { label: "captain" });
  await expect(captain.getByText("Your first flame lights today.")).toBeVisible({ timeout: 15_000 });
  const created = await captain.request.post("/api/v1/crews", { data: { name: unique("Dawn Patrol").slice(0, 30), emoji: "🌅" } });
  expect(created.status()).toBe(201);
  const { crew } = (await created.json()) as { crew: { name: string; inviteLink: string } };
  const token = crew.inviteLink.split("/join/")[1] ?? "";
  const shared = await captain.request.post("/api/v1/posts", { data: { clientId: crypto.randomUUID(), type: "meal", caption: "who's in at 6am", shareToCrew: true, timezone: "UTC", isPlannedDay: false } });
  expect(shared.status()).toBe(201);

  const joinerContext = await browser.newContext();
  const joiner = await joinerContext.newPage();
  await fromFreshIp(joiner);
  await joiner.goto(`/join/${token}`);
  await expect(joiner.getByRole("heading", { name: `${crew.name} 🌅` })).toBeVisible();
  await expectNoHorizontalScroll(joiner);
  await joiner.getByRole("link", { name: "Continue on web" }).click();
  await expect(joiner).toHaveURL(/\/onboarding\?invite=/);
  await joiner.getByRole("button", { name: "Continue" }).click();
  await joiner.getByRole("button", { name: "Some" }).click();
  await joiner.getByRole("button", { name: "Dumbbells" }).click();
  await joiner.getByRole("button", { name: "Looks good" }).click();
  await joiner.getByLabel("Name").fill("Jordan");
  await joiner.getByLabel("Email").fill(`${unique("jordan")}@example.com`);
  await joiner.getByLabel("Password").fill("journey password 1");
  await joiner.getByLabel("Birth year").fill("1992");
  await joiner.getByRole("button", { name: "Save your plan" }).click();
  await expect(joiner).toHaveURL(/\/crew$/, { timeout: 15_000 });
  await expect(joiner.getByRole("heading", { name: `${crew.name} 🌅` })).toBeVisible({ timeout: 15_000 });
  await expect(joiner.getByText("Jordan joined the crew")).toBeVisible();

  const later = await captain.request.post("/api/v1/posts", { data: { clientId: crypto.randomUUID(), type: "meal", caption: "second plate", shareToCrew: true, timezone: "UTC", isPlannedDay: false } });
  expect(later.status()).toBe(201);
  await expect(joiner.getByText("second plate")).toBeVisible({ timeout: 15_000 });
  await joiner.getByRole("button", { name: "React" }).last().click();
  await joiner.getByRole("button", { name: "React 🔥" }).click();
  await expect(joiner.getByText("🔥 1")).toBeVisible({ timeout: 15_000 });
  await expectNoHorizontalScroll(joiner);
  await captainContext.close();
  await joinerContext.close();
});
