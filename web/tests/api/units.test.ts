// SPEC: A9 (owner-directed 2026-09-09) — the two unit fields. Signup defaults them per-quantity from the device's own
// measurement system (.us → lb+mi, .uk → kg+mi, .metric → kg+km); each is switchable independently; an account written
// before the split derives both from the legacy `units` field on read, with no bulk write; and the legacy field stays a
// mirror of weightUnit so the shipped TestFlight build keeps working.
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { POST as register } from "@/app/api/v1/auth/register/route";
import { GET as getMe, PATCH as patchMe } from "@/app/api/v1/users/me/route";
import { closeDb, resetDbForTests, users } from "@/lib/db";
import { ObjectId } from "mongodb";
import { readJson, request } from "./http";

interface MeBody {
  units: "lb" | "kg";
  weightUnit: "lb" | "kg";
  distanceUnit: "mi" | "km";
}

let seq = 0;

async function signUp(measurementSystem?: "us" | "uk" | "metric"): Promise<{ id: string; token: string; user: MeBody }> {
  seq += 1;
  const body: Record<string, unknown> = {
    email: `units-${seq}-${Date.now()}@example.com`,
    password: "test password 123",
    displayName: "Units",
    timezone: "America/Los_Angeles",
    eulaAccepted: true,
    birthYear: 1990,
  };
  if (measurementSystem !== undefined) body.measurementSystem = measurementSystem;
  const response = await register(request("POST", "/auth/register", { ip: `198.51.101.${seq % 250}`, body }));
  expect(response.status).toBe(201);
  const parsed = await readJson<{ user: MeBody & { id: string }; accessToken: string }>(response);
  return { id: parsed.user.id, token: parsed.accessToken, user: parsed.user };
}

// GET wraps the user alongside gamification, pause and crew; PATCH returns the user alone
async function me(token: string): Promise<MeBody> {
  const response = await getMe(request("GET", "/users/me", { token }));
  expect(response.status).toBe(200);
  return (await readJson<{ user: MeBody }>(response)).user;
}

async function patch(token: string, changes: Record<string, unknown>): Promise<MeBody> {
  const response = await patchMe(request("PATCH", "/users/me", { token, body: changes }));
  expect(response.status).toBe(200);
  return readJson<MeBody>(response);
}

beforeAll(async () => { await resetDbForTests(); });
afterAll(async () => { await closeDb(); });

describe("units at signup", () => {
  it("defaults a US phone to pounds and miles", async () => {
    const { user } = await signUp("us");
    expect(user.weightUnit).toBe("lb");
    expect(user.distanceUnit).toBe("mi");
  });

  it("defaults a metric phone to kilograms and kilometres", async () => {
    const { user } = await signUp("metric");
    expect(user.weightUnit).toBe("kg");
    expect(user.distanceUnit).toBe("km");
  });

  it("defaults a UK phone to kilograms and MILES — the case one field cannot express", async () => {
    const { user } = await signUp("uk");
    expect(user.weightUnit).toBe("kg");
    expect(user.distanceUnit).toBe("mi");
  });

  it("falls back to pounds and miles when the client sends no measurement system", async () => {
    const { user } = await signUp();
    expect(user.weightUnit).toBe("lb");
    expect(user.distanceUnit).toBe("mi");
  });
});

describe("units are switchable independently", () => {
  it("changes the weight unit without touching distance", async () => {
    const { token } = await signUp("us");
    const updated = await patch(token, { weightUnit: "kg" });
    expect(updated.weightUnit).toBe("kg");
    expect(updated.distanceUnit).toBe("mi"); // still imperial roads
  });

  it("changes the distance unit without touching weight", async () => {
    const { token } = await signUp("us");
    const updated = await patch(token, { distanceUnit: "km" });
    expect(updated.distanceUnit).toBe("km");
    expect(updated.weightUnit).toBe("lb");
  });

  it("keeps the legacy mirror consistent whichever field the client sends", async () => {
    const { token } = await signUp("us");
    // a new build sends weightUnit — the legacy field follows, so an older build on the same account still reads right
    expect((await patch(token, { weightUnit: "kg" })).units).toBe("kg");
    // an older build sends units — the new field follows, so the two never disagree
    const back = await patch(token, { units: "lb" });
    expect(back.units).toBe("lb");
    expect(back.weightUnit).toBe("lb");
  });
});

describe("an account written before the split", () => {
  it("derives both fields from the legacy units field, with no bulk write", async () => {
    const { id, token } = await signUp("us");
    // exactly what a pre-A9 document looks like: one field, driving both quantities
    await (await users()).updateOne({ _id: new ObjectId(id) }, { $set: { units: "kg" }, $unset: { weightUnit: "", distanceUnit: "" } });
    const derived = await me(token);
    expect(derived.weightUnit).toBe("kg");
    expect(derived.distanceUnit).toBe("km"); // the old rule: kg implied km
  });

  it("derives miles for a legacy pounds account", async () => {
    const { id, token } = await signUp("metric");
    await (await users()).updateOne({ _id: new ObjectId(id) }, { $set: { units: "lb" }, $unset: { weightUnit: "", distanceUnit: "" } });
    const derived = await me(token);
    expect(derived.weightUnit).toBe("lb");
    expect(derived.distanceUnit).toBe("mi");
  });

  it("stops deriving as soon as the user makes a real choice", async () => {
    const { id, token } = await signUp("us");
    await (await users()).updateOne({ _id: new ObjectId(id) }, { $set: { units: "lb" }, $unset: { weightUnit: "", distanceUnit: "" } });
    await patch(token, { distanceUnit: "km" }); // lb + km: unreachable before A9
    const stored = await me(token);
    expect(stored.weightUnit).toBe("lb");
    expect(stored.distanceUnit).toBe("km");
  });
});

describe("validation", () => {
  it("refuses a distance unit that is not mi or km", async () => {
    const { token } = await signUp("us");
    const response = await patchMe(request("PATCH", "/users/me", { token, body: { distanceUnit: "furlong" } }));
    expect(response.status).toBe(400);
  });

  it("refuses a weight unit that is not lb or kg", async () => {
    const { token } = await signUp("us");
    const response = await patchMe(request("PATCH", "/users/me", { token, body: { weightUnit: "stone" } }));
    expect(response.status).toBe(400);
  });

  it("refuses a measurement system it does not know at signup", async () => {
    const response = await register(request("POST", "/auth/register", {
      ip: "198.51.102.9",
      body: { email: `units-bad-${randomUUID()}@example.com`, password: "test password 123", displayName: "Units", timezone: "America/Los_Angeles", eulaAccepted: true, birthYear: 1990, measurementSystem: "imperial" },
    }));
    expect(response.status).toBe(400);
  });
});
