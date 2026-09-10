// SPEC: A14 (owner-directed 2026-09-09) — "a cardio log gets its own post type: today a standalone cardio session writes
// type 'workout', so every count of workouts silently includes walks."
//
// The load-bearing assertion in this file is the SECOND one. Splitting the post type is only safe because the gamification
// engine never sees it: `PostKind` stays "workout" | "meal" | "text" and gamification-store maps a cardio post to "workout"
// at the boundary. So a walk still earns +25, still sustains the streak, and V24/V25/V26/V30/V31 stay green WITHOUT being
// re-expected — which is what lets A14 ship with no vector change at all. If someone ever "tidies" that map away, the
// recompute test below goes red instead of a user silently losing XP.
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { PUT as putPlan } from "@/app/api/v1/plans/route";
import { PATCH as patchSession } from "@/app/api/v1/sessions/[id]/route";
import { POST as createSession } from "@/app/api/v1/sessions/route";
import { closeDb, posts, resetDbForTests } from "@/lib/db";
import { recomputeAndStore } from "@/lib/gamification-store";
import { isRestDay, postLine } from "@/app/(app)/journal/rows";
import type { PostDoc } from "@/lib/documents-social";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { doneSets, sampleCardioSessionBody, samplePlanBody, sampleSessionBody } from "./plans-sessions";

let me: TestUser;
interface SessionReply { session: { id: string; workoutKind: string | null }; gamification?: { currentStreak: number; totalXP: number } }

const params = (id: string) => ({ params: Promise.resolve({ id }) });

// A cardio log arrives already done (its one set, V51); a strength session needs its work sets marked before V32 lets it
// complete — without that the patch is a no-op and no post is written at all
async function completeSession(body: ReturnType<typeof sampleSessionBody> | ReturnType<typeof sampleCardioSessionBody>, clientId: string, workSets = 0): Promise<SessionReply> {
  const created = await readJson<SessionReply>(await createSession(request("POST", "/sessions", { token: me.accessToken, body })));
  const patch: Record<string, unknown> = { timezone: "America/Los_Angeles", status: "completed", post: { clientId, shareToCrew: false } };
  if (workSets > 0) patch.exercises = doneSets(body as ReturnType<typeof sampleSessionBody>, workSets);
  return readJson<SessionReply>(await patchSession(request("PATCH", `/sessions/${created.session.id}`, { token: me.accessToken, body: patch }), params(created.session.id)));
}

const postFor = async (clientId: string) => (await (await posts()).findOne({ clientId })) as PostDoc;

beforeAll(async () => {
  await resetDbForTests();
  me = await createUser("post-types");
  await putPlan(request("PUT", "/plans", { token: me.accessToken, body: samplePlanBody() }));
});
afterAll(async () => {
  await closeDb();
});

describe("A14 post types", () => {
  it("a workout completion writes a workout post and a standalone cardio log writes a CARDIO post", async () => {
    await completeSession(sampleSessionBody(), "6a1c0e2a-8f9b-4c1e-9d10-00000000a001", 1);
    await completeSession(sampleCardioSessionBody({ minutes: 25 }), "6a1c0e2a-8f9b-4c1e-9d10-00000000a002");
    expect((await postFor("6a1c0e2a-8f9b-4c1e-9d10-00000000a001")).type).toBe("workout");
    expect((await postFor("6a1c0e2a-8f9b-4c1e-9d10-00000000a002")).type).toBe("cardio");
  });

  // The boundary: to XP and the streak a walk is still a workout, so nothing about the engine or its vectors moves
  it("a cardio post still earns the bonus workout XP through the engine, on the live recompute path", async () => {
    const before = await recomputeAndStore(me.id);
    await completeSession(sampleCardioSessionBody({ activity: "Bike", minutes: 30 }), "6a1c0e2a-8f9b-4c1e-9d10-00000000a003");
    const after = await recomputeAndStore(me.id);
    expect((await postFor("6a1c0e2a-8f9b-4c1e-9d10-00000000a003")).type).toBe("cardio");
    expect(after.totalXP - before.totalXP).toBe(25); // V30/V31 — an unplanned completed workout, cardio or not
    expect(after.currentStreak).toBe(before.currentStreak); // already counted today; the day does not count twice (V01)
  });

  // A6 — the words do not change: both row types read the summary the completion wrote
  it("the journal reads a cardio row from the same summary a workout row uses", async () => {
    const cardio = await postFor("6a1c0e2a-8f9b-4c1e-9d10-00000000a002");
    const workout = await postFor("6a1c0e2a-8f9b-4c1e-9d10-00000000a001");
    expect(postLine(cardio, "America/Los_Angeles", null, true)).toBe("Walk · 25 min");
    expect(postLine(workout, "America/Los_Angeles", null, true)).toContain("Push day");
  });

  // A day you walked is not tagged "Rest day" — the tag describes what you did, and this is exactly the pre-A14 reading
  // (a cardio log WAS a workout post then, so it suppressed the tag; the split must not quietly change that)
  it("a cardio post suppresses the Rest day tag exactly as it did before the split", async () => {
    const cardio = await postFor("6a1c0e2a-8f9b-4c1e-9d10-00000000a002");
    expect(isRestDay(cardio.dayKey, [cardio], [])).toBe(false);
    const meal = { ...cardio, type: "meal" } as PostDoc;
    expect(isRestDay(meal.dayKey, [meal], [])).toBe(true);
  });
});
