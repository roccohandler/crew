// SPEC: nutrition addendum §2–§6 (RATIFIED 2026-09-18) · Flow 4 clauses ③ ④ · A16.c · A22 G3 · 8.2 — the nutrition routes against
// real handlers and a real MongoDB (C4): the 18+ gate (absent under 18, the birth year asked once when it is missing), targets
// (derived · manual · Recalculate · delete), saved meals (manual · seed copy · idempotent · template slots follow a delete), logs
// (the saved meal's grams are copied · idempotent · the server's day), NO XP and NO post for any of it, export, both cascades, and
// the phone's six sync ops. Verify: npm test tests/api/nutrition
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { ObjectId } from "mongodb";
import { POST as register } from "@/app/api/v1/auth/register/route";
import { DELETE as deleteLogRoute } from "@/app/api/v1/nutrition/logs/[id]/route";
import { GET as listLogs, POST as createLog } from "@/app/api/v1/nutrition/logs/route";
import { DELETE as deleteMeal, PATCH as patchMeal } from "@/app/api/v1/nutrition/saved-meals/[id]/route";
import { GET as listMeals, POST as createMeal } from "@/app/api/v1/nutrition/saved-meals/route";
import { DELETE as deleteTargets, GET as getTargets, PUT as putTargets } from "@/app/api/v1/nutrition/targets/route";
import { GET as getTemplate, PUT as putTemplate } from "@/app/api/v1/nutrition/template/route";
import { POST as sync } from "@/app/api/v1/sync/route";
import { GET as exportData } from "@/app/api/v1/users/me/export/route";
import { DELETE as deleteMe, GET as getMe, PATCH as patchMe } from "@/app/api/v1/users/me/route";
import { closeDb, dayTemplates, gamificationStates, mealLogs, nutritionTargets, posts, resetDbForTests, savedMeals, users } from "@/lib/db";
import { dayKeyFor } from "@/lib/engine/day-key";
import { fastFood } from "@/generated/seed";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";

let me: TestUser;
const TZ = "America/Los_Angeles";
const params = (id: string) => ({ params: Promise.resolve({ id }) });
const thisYear = new Date().getUTCFullYear();
interface Targets { bodyweight: number; unit: string; proteinG: number; carbsG: number; fatG: number; source: string; estimate: { energyKcal: number } }
interface Meal { id: string; clientId: string; name: string; proteinG: number; carbsG: number; fatG: number; source: { kind: string } }
interface Log { id: string; clientId: string; dayKey: string; name: string; proteinG: number; carbsG: number; fatG: number; savedMealId: string | null }

async function registered(label: string, birthYear: number, ip: string): Promise<TestUser> {
  const body = { email: `${label}-${Date.now()}@example.com`, password: "test password 123", displayName: label, timezone: TZ, eulaAccepted: true, birthYear };
  const reply = await readJson<{ user: { id: string }; accessToken: string; refreshToken: string }>(await register(request("POST", "/auth/register", { ip, body })));
  return { id: reply.user.id, email: body.email, accessToken: reply.accessToken, refreshToken: reply.refreshToken };
}
const newMeal = (name: string, grams: [number, number, number]) => ({ clientId: randomUUID(), name, proteinG: grams[0], carbsG: grams[1], fatG: grams[2] });

beforeAll(async () => {
  await resetDbForTests();
  me = await createUser("macros", TZ);
});
afterAll(async () => {
  await closeDb();
});

describe("the 18+ gate (A16.c · A22 G3 · V65)", () => {
  it("under 18 the surface does not exist: every route is a 404 and the account reads `absent`", async () => {
    const teen = await registered("teen", thisYear - 17, "198.51.100.201");
    expect((await readJson<{ user: { nutrition: string } }>(await getMe(request("GET", "/users/me", { token: teen.accessToken })))).user.nutrition).toBe("absent");
    expect((await getTargets(request("GET", "/nutrition/targets", { token: teen.accessToken }))).status).toBe(404);
    expect((await putTargets(request("PUT", "/nutrition/targets", { token: teen.accessToken, body: { bodyweight: 60, unit: "kg" } }))).status).toBe(404);
    expect((await createLog(request("POST", "/nutrition/logs", { token: teen.accessToken, body: { clientId: randomUUID(), timezone: TZ, name: "x", proteinG: 1, carbsG: 1, fatG: 1, quickAdd: true } }))).status).toBe(404);
  });

  it("an account with no birth year is asked once — then it is available, and the year never changes again", async () => {
    const apple = await createUser("no-year", TZ);
    await (await users()).updateOne({ _id: new ObjectId(apple.id) }, { $unset: { birthYear: "" } });
    const blocked = await getTargets(request("GET", "/nutrition/targets", { token: apple.accessToken }));
    expect(blocked.status).toBe(403);
    expect((await readJson<{ error: { code: string } }>(blocked)).error.code).toBe("birthYearRequired");
    const asked = await readJson<{ nutrition: string }>(await patchMe(request("PATCH", "/users/me", { token: apple.accessToken, body: { birthYear: thisYear - 30 } })));
    expect(asked.nutrition).toBe("available");
    expect((await getTargets(request("GET", "/nutrition/targets", { token: apple.accessToken }))).status).toBe(200);
    expect((await patchMe(request("PATCH", "/users/me", { token: apple.accessToken, body: { birthYear: thisYear - 40 } }))).status).toBe(409);
  });
});

describe("targets (addendum §3 · V57 · V64)", () => {
  it("derives from the bodyweight, keeps typed grams as manual, recalculates, refuses a typo, and deletes the bodyweight with the targets", async () => {
    const derived = await readJson<{ targets: Targets }>(await putTargets(request("PUT", "/nutrition/targets", { token: me.accessToken, body: { bodyweight: 80, unit: "kg" } })));
    expect(derived.targets).toMatchObject({ bodyweight: 80, unit: "kg", proteinG: 145, carbsG: 385, fatG: 60, source: "derived" });
    expect(derived.targets.estimate.energyKcal).toBe(2650);
    const manual = await readJson<{ targets: Targets }>(await putTargets(request("PUT", "/nutrition/targets", { token: me.accessToken, body: { bodyweight: 80, unit: "kg", proteinG: 180, carbsG: 300, fatG: 70 } })));
    expect(manual.targets).toMatchObject({ proteinG: 180, carbsG: 300, fatG: 70, source: "manual" });
    const again = await readJson<{ targets: Targets }>(await putTargets(request("PUT", "/nutrition/targets", { token: me.accessToken, body: { bodyweight: 176, unit: "lb" } })));
    expect(again.targets).toMatchObject({ bodyweight: 176, unit: "lb", proteinG: 145, carbsG: 385, fatG: 60, source: "derived" }); // V58
    expect((await putTargets(request("PUT", "/nutrition/targets", { token: me.accessToken, body: { bodyweight: 5, unit: "kg" } }))).status).toBe(400);
    expect((await putTargets(request("PUT", "/nutrition/targets", { token: me.accessToken, body: { bodyweight: 80, unit: "kg", proteinG: 100 } }))).status).toBe(400);
    expect((await deleteTargets(request("DELETE", "/nutrition/targets", { token: me.accessToken }))).status).toBe(200);
    expect((await readJson<{ targets: Targets | null }>(await getTargets(request("GET", "/nutrition/targets", { token: me.accessToken })))).targets).toBeNull();
    expect(await (await nutritionTargets()).countDocuments({ userId: new ObjectId(me.id) })).toBe(0); // V64: no bodyweight is left anywhere
  });
});

describe("saved meals, the template and logs (addendum §2 · V62)", () => {
  it("saves a meal once per clientId, copies a seed item's grams, and a deleted meal takes its template slot with it", async () => {
    const body = newMeal("Chicken and rice", [45, 60, 12]);
    const first = await createMeal(request("POST", "/nutrition/saved-meals", { token: me.accessToken, body }));
    expect(first.status).toBe(201);
    const meal = (await readJson<{ meal: Meal }>(first)).meal;
    expect((await readJson<{ meal: Meal }>(await createMeal(request("POST", "/nutrition/saved-meals", { token: me.accessToken, body })))).meal.id).toBe(meal.id);
    const item = fastFood.items[0];
    if (item === undefined) throw new Error("the fast-food seed is empty");
    const fromSeed = await readJson<{ meal: Meal }>(await createMeal(request("POST", "/nutrition/saved-meals", { token: me.accessToken, body: { ...newMeal(item.name, [item.proteinG, item.carbsG, item.fatG]), seed: { chainId: item.chainId, itemId: item.id } } })));
    expect(fromSeed.meal.source.kind).toBe("seed");
    expect((await createMeal(request("POST", "/nutrition/saved-meals", { token: me.accessToken, body: { ...newMeal("ghost", [1, 1, 1]), seed: { chainId: "nowhere", itemId: "nowhere/nothing" } } }))).status).toBe(400);
    const renamed = await readJson<{ meal: Meal }>(await patchMeal(request("PATCH", `/nutrition/saved-meals/${meal.clientId}`, { token: me.accessToken, body: { name: "Chicken, rice, greens" } }), params(meal.clientId)));
    expect(renamed.meal.name).toBe("Chicken, rice, greens");
    const slots = await readJson<{ slots: { savedMealId: string; label: string }[] }>(await putTemplate(request("PUT", "/nutrition/template", { token: me.accessToken, body: { slots: [{ savedMealId: meal.id, label: "Lunch" }, { savedMealId: fromSeed.meal.clientId }] } })));
    expect(slots.slots.map((slot) => slot.label)).toEqual(["Lunch", ""]);
    expect((await deleteMeal(request("DELETE", `/nutrition/saved-meals/${fromSeed.meal.id}`, { token: me.accessToken }), params(fromSeed.meal.id))).status).toBe(200);
    expect((await readJson<{ slots: unknown[] }>(await getTemplate(request("GET", "/nutrition/template", { token: me.accessToken })))).slots).toHaveLength(1);
    expect((await readJson<{ items: Meal[] }>(await listMeals(request("GET", "/nutrition/saved-meals", { token: me.accessToken })))).items.map((saved) => saved.id)).toEqual([meal.id]);
  });

  it("a slot log copies the saved meal's grams, is idempotent, lands on the server's day, and pays NOTHING (clauses ③ ④ · V63)", async () => {
    const meal = (await readJson<{ items: Meal[] }>(await listMeals(request("GET", "/nutrition/saved-meals", { token: me.accessToken })))).items[0];
    if (meal === undefined) throw new Error("no saved meal");
    const body = { clientId: randomUUID(), timezone: TZ, savedMealId: meal.id, name: "whatever the phone had", proteinG: 1, carbsG: 1, fatG: 1, quickAdd: false };
    const logged = await createLog(request("POST", "/nutrition/logs", { token: me.accessToken, body }));
    expect(logged.status).toBe(201);
    const log = (await readJson<{ log: Log }>(logged)).log;
    expect(log).toMatchObject({ name: meal.name, proteinG: 45, carbsG: 60, fatG: 12, savedMealId: meal.id, dayKey: dayKeyFor(new Date(), TZ) });
    expect((await createLog(request("POST", "/nutrition/logs", { token: me.accessToken, body }))).status).toBe(200); // V62
    await createLog(request("POST", "/nutrition/logs", { token: me.accessToken, body: { clientId: randomUUID(), timezone: TZ, name: "Quick add", proteinG: 30, carbsG: 0, fatG: 10, quickAdd: true } }));
    const day = await readJson<{ items: Log[] }>(await listLogs(request("GET", `/nutrition/logs?dayKey=${log.dayKey}`, { token: me.accessToken })));
    expect(day.items).toHaveLength(2);
    expect((await listLogs(request("GET", "/nutrition/logs", { token: me.accessToken }))).status).toBe(400); // the day is named, never guessed
    const state = await (await gamificationStates()).findOne({ userId: new ObjectId(me.id) });
    expect(state).toMatchObject({ totalXP: 0, currentStreak: 0, earnedAchievementIds: [] }); // clause ③: no XP, no streak, no achievement
    expect(await (await posts()).countDocuments({ userId: new ObjectId(me.id) })).toBe(0); // clause ④: a log is never a post — no stream, no pulse
    expect((await deleteLogRoute(request("DELETE", `/nutrition/logs/${log.clientId}`, { token: me.accessToken }), params(log.clientId))).status).toBe(200);
    expect((await deleteLogRoute(request("DELETE", `/nutrition/logs/${log.clientId}`, { token: me.accessToken }), params(log.clientId))).status).toBe(404);
  });
});

describe("export, the two cascades and the phone's ops", () => {
  it("rides the export, clears with `everything`, and replays the six sync ops — refusing them per op for a gated account", async () => {
    await putTargets(request("PUT", "/nutrition/targets", { token: me.accessToken, body: { bodyweight: 80, unit: "kg" } }));
    const exported = await readJson<{ nutrition: { targets: unknown; savedMeals: unknown[]; logs: unknown[] } }>(await exportData(request("GET", "/users/me/export", { token: me.accessToken })));
    expect(exported.nutrition.targets).not.toBeNull();
    expect(exported.nutrition.savedMeals.length).toBeGreaterThan(0);
    expect(exported.nutrition.logs.length).toBeGreaterThan(0);
    expect((await deleteTargets(request("DELETE", "/nutrition/targets", { token: me.accessToken, body: { everything: true } }))).status).toBe(200);
    const mine = { userId: new ObjectId(me.id) };
    expect([await (await nutritionTargets()).countDocuments(mine), await (await savedMeals()).countDocuments(mine), await (await dayTemplates()).countDocuments(mine), await (await mealLogs()).countDocuments(mine)]).toEqual([0, 0, 0, 0]);

    const meal = newMeal("Oats", [20, 60, 10]);
    const logId = randomUUID();
    const ops = [
      { opId: "t", kind: "putNutritionTargets", payload: { bodyweight: 176, unit: "lb" } },
      { opId: "m", kind: "upsertSavedMeal", payload: meal },
      { opId: "m2", kind: "upsertSavedMeal", payload: { ...meal, name: "Overnight oats" } },
      { opId: "p", kind: "putDayTemplate", payload: { slots: [{ savedMealId: meal.clientId, label: "Breakfast" }] } },
      { opId: "l", kind: "createMealLog", payload: { clientId: logId, savedMealId: meal.clientId, name: meal.name, proteinG: 20, carbsG: 60, fatG: 10, quickAdd: false } },
      { opId: "d", kind: "deleteMealLog", payload: { id: logId } },
    ];
    const replay = await readJson<{ results: { ok: boolean }[] }>(await sync(request("POST", "/sync", { token: me.accessToken, body: { timezone: TZ, ops } })));
    expect(replay.results.map((result) => result.ok)).toEqual([true, true, true, true, true, true]);
    // a queued delete is idempotent: the log is already gone, which IS what the op asked for — delivered, never held as poison
    const again = await readJson<{ results: { ok: boolean }[] }>(await sync(request("POST", "/sync", { token: me.accessToken, body: { timezone: TZ, ops: [{ opId: "d2", kind: "deleteMealLog", payload: { id: logId } }, { opId: "d3", kind: "deleteSavedMeal", payload: { id: randomUUID() } }] } })));
    expect(again.results.map((result) => result.ok)).toEqual([true, true]);
    expect((await readJson<{ items: Meal[] }>(await listMeals(request("GET", "/nutrition/saved-meals", { token: me.accessToken })))).items.map((saved) => saved.name)).toEqual(["Overnight oats"]);
    const teen = await registered("teen-sync", thisYear - 16, "198.51.100.202");
    const refused = await readJson<{ results: { ok: boolean; error?: string; retryable?: boolean }[] }>(await sync(request("POST", "/sync", { token: teen.accessToken, body: { timezone: TZ, ops: [ops[0]] } })));
    expect(refused.results[0]).toMatchObject({ ok: false, error: "notFound", retryable: false });

    expect((await deleteMe(request("DELETE", "/users/me", { token: me.accessToken, body: { confirm: "delete" } }))).status).toBe(200);
    expect([await (await nutritionTargets()).countDocuments(mine), await (await savedMeals()).countDocuments(mine), await (await dayTemplates()).countDocuments(mine)]).toEqual([0, 0, 0]);
  });
});
