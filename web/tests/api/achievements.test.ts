// SPEC: seed achievements rules · V35 (earned achievements survive deletion/undo — server side) · E8 (unlocks ride the
// completion reply) · 5.6.4 (every mutation ends with recomputeAndStore, which now runs the awarding pass). T006 debt repaid.
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { DELETE as deletePost } from "@/app/api/v1/posts/[id]/route";
import { PATCH as patchSession } from "@/app/api/v1/sessions/[id]/route";
import { POST as createSession } from "@/app/api/v1/sessions/route";
import { GET as getMe } from "@/app/api/v1/users/me/route";
import { closeDb, resetDbForTests } from "@/lib/db";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { doneSets, sampleSessionBody } from "./plans-sessions";
import { postWorkout } from "./workout-post";

let me: TestUser;
const params = (id: string) => ({ params: Promise.resolve({ id }) });
type Reply = { post?: { id: string }; session?: { id: string }; gamification: { earnedAchievementIds: string[]; newAchievementIds: string[] } };

beforeAll(async () => {
  await resetDbForTests();
  me = await createUser("achiever", "UTC");
});

afterAll(async () => {
  await closeDb();
});

describe("achievements awarding pass", () => {
  // A22 (2026-09-18): the first post is the first workout's post, so the completion that writes it lights First flame AND Showed up
  it("the first posted workout earns First flame (and Showed up) once; deleting the post never takes them back (V35)", async () => {
    const first = await postWorkout(me, { timezone: "UTC" });
    expect(first.gamification.newAchievementIds).toEqual(["first-flame", "showed-up"]);
    expect(first.gamification.earnedAchievementIds).toEqual(["first-flame", "showed-up"]);
    const second = await postWorkout(me, { timezone: "UTC" });
    expect(second.gamification.newAchievementIds).toEqual([]);
    const gone = await readJson<Reply>(await deletePost(request("DELETE", `/posts/${first.postId}`, { token: me.accessToken }), params(first.postId)));
    expect(gone.gamification.earnedAchievementIds).toEqual(["first-flame", "showed-up"]);
    const profile = await readJson<{ gamification: { earnedAchievementIds: string[] } }>(await getMe(request("GET", "/users/me", { token: me.accessToken })));
    expect(profile.gamification.earnedAchievementIds).toEqual(["first-flame", "showed-up"]);
  });

  // A21.9: a completion without `post` records the workout and creates NO post — Showed up, no First flame
  it("completing the first workout without posting it earns Showed up alone on the completion reply (E8)", async () => {
    const runner = await createUser("runner", "UTC");
    const body = sampleSessionBody({ timezone: "UTC", isPlannedDay: false });
    const created = await readJson<Reply>(await createSession(request("POST", "/sessions", { token: runner.accessToken, body })));
    const sessionId = created.session?.id ?? "";
    expect(sessionId).not.toBe("");
    const done = await readJson<Reply>(await patchSession(request("PATCH", `/sessions/${sessionId}`, { token: runner.accessToken, body: { timezone: "UTC", exercises: doneSets(body, 3), status: "completed" } }), params(sessionId)));
    expect(done.gamification.newAchievementIds).toEqual(["showed-up"]);
    expect(done.gamification.earnedAchievementIds).toEqual(["showed-up"]);
  });
});
