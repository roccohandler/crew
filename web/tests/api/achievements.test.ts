// SPEC: seed achievements rules · V35 (earned achievements survive deletion/undo — server side) · E8 (unlocks ride the
// completion reply) · 5.6.4 (every mutation ends with recomputeAndStore, which now runs the awarding pass). T006 debt repaid.
import { randomUUID } from "node:crypto";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { DELETE as deletePost } from "@/app/api/v1/posts/[id]/route";
import { POST as createPost } from "@/app/api/v1/posts/route";
import { PATCH as patchSession } from "@/app/api/v1/sessions/[id]/route";
import { POST as createSession } from "@/app/api/v1/sessions/route";
import { GET as getMe } from "@/app/api/v1/users/me/route";
import { closeDb, resetDbForTests } from "@/lib/db";
import { createUser, type TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { doneSets, sampleSessionBody } from "./plans-sessions";

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
  it("the first post earns First flame once; deleting the post never takes it back (V35)", async () => {
    const first = await readJson<Reply>(await createPost(request("POST", "/posts", { token: me.accessToken, body: { clientId: randomUUID(), type: "meal", caption: "eggs", shareToCrew: false, timezone: "UTC", isPlannedDay: false } })));
    expect(first.gamification.newAchievementIds).toEqual(["first-flame"]);
    expect(first.gamification.earnedAchievementIds).toEqual(["first-flame"]);
    const second = await readJson<Reply>(await createPost(request("POST", "/posts", { token: me.accessToken, body: { clientId: randomUUID(), type: "meal", caption: "lunch", shareToCrew: false, timezone: "UTC", isPlannedDay: false } })));
    expect(second.gamification.newAchievementIds).toEqual([]);
    const gone = await readJson<Reply>(await deletePost(request("DELETE", `/posts/${first.post?.id}`, { token: me.accessToken }), params(first.post?.id ?? "")));
    expect(gone.gamification.earnedAchievementIds).toEqual(["first-flame"]);
    const profile = await readJson<{ gamification: { earnedAchievementIds: string[] } }>(await getMe(request("GET", "/users/me", { token: me.accessToken })));
    expect(profile.gamification.earnedAchievementIds).toEqual(["first-flame"]);
  });

  it("completing the first workout earns Showed up on the completion reply (E8)", async () => {
    const body = sampleSessionBody({ timezone: "UTC", isPlannedDay: false });
    const created = await readJson<Reply>(await createSession(request("POST", "/sessions", { token: me.accessToken, body })));
    const sessionId = created.session?.id ?? "";
    expect(sessionId).not.toBe("");
    const done = await readJson<Reply>(await patchSession(request("PATCH", `/sessions/${sessionId}`, { token: me.accessToken, body: { timezone: "UTC", exercises: doneSets(body, 3), status: "completed" } }), params(sessionId)));
    expect(done.gamification.newAchievementIds).toEqual(["showed-up"]);
    expect(done.gamification.earnedAchievementIds).toEqual(["first-flame", "showed-up"]);
  });
});
