// SPEC: 8.4 journey ② on web — returning → fast-log → crew reaction received (S07: ≤ 3 taps launch → fast-logged, Quick
// Complete hidden once today counts; 1C: authenticate once per device; Flow 6: the reaction lands on the poster's own card).
// The crewmate's side is journey ③; here only the receipt matters, so the mate acts through the API. T035 (web half) / T039
import { expect, test } from "@playwright/test";
import { buildWeekAndSave, ensureTodayHasAWorkout, expectNoHorizontalScroll, fromFreshIp, unique, waitForHydration } from "./helpers";

// Yesterday's member: the first flame is already lit (a meal post) and today is a planned day whatever the weekday — the
// journey starts where a returning user starts, not on day one.
async function makeReturning(page: import("@playwright/test").Page): Promise<void> {
  const me = (await (await page.request.get("/api/v1/users/me")).json()) as { user: { timezone: string } };
  const lit = await page.request.post("/api/v1/posts", { data: { clientId: crypto.randomUUID(), type: "meal", caption: "overnight oats", shareToCrew: true, timezone: me.user.timezone, isPlannedDay: false } });
  expect(lit.status()).toBe(201);
  await ensureTodayHasAWorkout(page);
}

test("a returning member logs in, fast-logs today in three taps, and a crewmate's reaction lands on the post", async ({ browser }) => {
  const captainContext = await browser.newContext();
  const captain = await captainContext.newPage();
  const email = await buildWeekAndSave(captain, { label: "returning" });
  await expect(captain.getByText("Your first flame lights today.")).toBeVisible({ timeout: 15_000 });
  await makeReturning(captain);
  const created = await captain.request.post("/api/v1/crews", { data: { name: unique("Night Shift").slice(0, 30), emoji: "🌙" } });
  expect(created.status()).toBe(201);
  const { crew } = (await created.json()) as { crew: { id: string; inviteLink: string } };
  const token = crew.inviteLink.split("/join/")[1] ?? "";

  // the crewmate is already in (their join is journey ③)
  const mateContext = await browser.newContext();
  const mate = await mateContext.newPage();
  const headers = { "x-forwarded-for": await fromFreshIp(mate) };
  const registered = await mate.request.post("/api/v1/auth/register", { headers, data: { email: `${unique("mate")}@example.com`, password: "journey password 1", displayName: "Sam", timezone: "UTC", eulaAccepted: true, birthYear: 1993 } });
  expect(registered.status()).toBe(201);
  const joined = await mate.request.post("/api/v1/crews/join", { headers, data: { token } });
  expect(joined.status()).toBe(201);

  // returning: log out, log back in — Home opens in its normal state, the bridge long gone
  await captain.goto("/settings");
  await waitForHydration(captain, "button");
  await captain.getByRole("button", { name: "Log out" }).click();
  await expect(captain).toHaveURL(/\/$/, { timeout: 15_000 });
  await captain.goto("/login");
  await waitForHydration(captain, "input");
  await captain.getByLabel("Email").fill(email);
  await captain.getByLabel("Password").fill("journey password 1");
  await captain.getByRole("button", { name: "Log in" }).click();
  await expect(captain).toHaveURL(/\/home$/, { timeout: 15_000 });
  await expect(captain.getByText("Your first flame lights today.")).toHaveCount(0);
  await expectNoHorizontalScroll(captain);

  // fast-log: Home → Quick complete → celebration → Done (three taps, S07)
  await waitForHydration(captain, "button");
  await captain.getByRole("button", { name: "Quick complete" }).click();
  await expect(captain).toHaveURL(/\/session\/[a-f0-9]+\/done(\?earned=.+)?$/, { timeout: 15_000 });
  await expect(captain.getByText(/^\d+\/\d+ sets · \d+ min/)).toBeVisible();
  await expect(captain.getByText("Showed up")).toBeVisible(); // E8: the first completion unlocks Showed up
  await expectNoHorizontalScroll(captain);
  await captain.getByRole("link", { name: "Done" }).click();
  await expect(captain.getByRole("heading", { name: "Done for today." })).toBeVisible();
  await expect(captain.getByRole("button", { name: "Quick complete" })).toHaveCount(0); // hidden once today counts

  // the crewmate sees the workout drop into the stream and reacts
  const feed = (await (await mate.request.get(`/api/v1/crews/${crew.id}/stream`, { headers })).json()) as { items: { kind: string; post?: { id: string; type: string } }[] };
  const workoutPost = feed.items.find((item) => item.kind === "post" && item.post?.type === "workout")?.post;
  expect(workoutPost).toBeDefined();
  const reacted = await mate.request.post(`/api/v1/posts/${workoutPost?.id ?? ""}/reactions`, { headers, data: { emoji: "🔥" } });
  expect(reacted.status()).toBe(200);

  // received: the returning member opens the crew and the reaction sits on their own workout card
  await captain.goto("/crew");
  await expect(captain.getByText("Workout ✓")).toBeVisible({ timeout: 15_000 });
  await expect(captain.getByText("🔥 1")).toBeVisible({ timeout: 15_000 });
  await expectNoHorizontalScroll(captain);
  await captainContext.close();
  await mateContext.close();
});
