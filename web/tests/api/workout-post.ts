// A22 (owner-approved 2026-09-18): the plate journal is gone, so "a post" in a fixture is a WORKOUT post — created the one way the
// product creates one: a session completed with `post` (S10 · A21.9), through the real create + complete handlers. A standalone
// cardio log (A2) is the cheapest: one done set, never a planned slot; a strength session marks a work set first (V32).
import { randomUUID } from "node:crypto";
import { expect } from "vitest";
import { GET as listPosts } from "@/app/api/v1/posts/route";
import { PATCH as patchSession } from "@/app/api/v1/sessions/[id]/route";
import { POST as createSession } from "@/app/api/v1/sessions/route";
import type { TestUser } from "./fixtures";
import { readJson, request } from "./http";
import { doneSets, sampleCardioSessionBody, sampleSessionBody } from "./plans-sessions";

export interface JournalItem { id: string; clientId: string; type: string; caption: string; dayKey: string; sessionId: string | null; crewId: string | null }
export interface PostedWorkout {
  sessionId: string;
  postId: string;
  clientId: string;
  gamification: { currentStreak: number; totalXP: number; newAchievementIds: string[]; earnedAchievementIds: string[] };
}

export async function postWorkout(user: TestUser, options: { shareToCrew?: boolean; caption?: string; cardio?: boolean; clientId?: string; timezone?: string } = {}): Promise<PostedWorkout> {
  const timezone = options.timezone ?? "America/Los_Angeles";
  const body = options.cardio === true ? sampleCardioSessionBody({ timezone }) : sampleSessionBody({ timezone });
  const created = await readJson<{ session: { id: string } }>(await createSession(request("POST", "/sessions", { token: user.accessToken, body })));
  const clientId = options.clientId ?? randomUUID();
  const post: Record<string, unknown> = { clientId, shareToCrew: options.shareToCrew ?? false };
  if (options.caption !== undefined) post.caption = options.caption;
  const patch: Record<string, unknown> = { timezone, status: "completed", post };
  if (options.cardio !== true) patch.exercises = doneSets(body as ReturnType<typeof sampleSessionBody>, 1);
  const done = await patchSession(request("PATCH", `/sessions/${created.session.id}`, { token: user.accessToken, body: patch }), { params: Promise.resolve({ id: created.session.id }) });
  expect(done.status).toBe(200);
  const reply = await readJson<{ gamification: PostedWorkout["gamification"] }>(done);
  const journal = await readJson<{ items: JournalItem[] }>(await listPosts(request("GET", "/posts", { token: user.accessToken })));
  const written = journal.items.find((item) => item.clientId === clientId);
  if (written === undefined) throw new Error("the completion wrote no post");
  return { sessionId: created.session.id, postId: written.id, clientId, gamification: reply.gamification };
}
