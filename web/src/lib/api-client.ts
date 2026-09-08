// SPEC: 5.6.5 lib/api-client.ts — one typed function per endpoint, names identical to Api.swift (createSession, createPost…).
// Cookie auth (credentials: include); on 401 the client refreshes once through auth/refresh and retries (G11 rotation).
// No generics (C1): apiFetch returns unknown and every endpoint function names its reply type. Crews + settings live in
// api-client-crew.ts (C9 cap).
import type { PlanDraft } from "@/lib/engine/plan-generator";
import type { PublicState } from "@/lib/engine/gamification";
import type { PublicUser } from "@/lib/users";

export interface ApiClientError {
  isApiClientError: true;
  code: string;
  message: string;
  status: number;
}

export function isApiClientError(value: unknown): value is ApiClientError {
  return typeof value === "object" && value !== null && (value as ApiClientError).isApiClientError === true;
}

const UNAUTHORIZED = 401;

async function refreshOnce(): Promise<boolean> {
  const response = await fetch("/api/v1/auth/refresh", { method: "POST", credentials: "include" });
  return response.ok;
}

export async function apiFetch(path: string, init: RequestInit = {}, retry = true): Promise<unknown> {
  const headers = new Headers(init.headers);
  if (init.body !== undefined && !(init.body instanceof FormData)) headers.set("content-type", "application/json");
  const response = await fetch(`/api/v1${path}`, { ...init, headers, credentials: "include" });
  if (response.status === UNAUTHORIZED && retry && !path.startsWith("/auth/")) {
    if (await refreshOnce()) return apiFetch(path, init, false);
  }
  const body = (await response.json().catch(() => ({}))) as { error?: { code: string; message: string } };
  if (!response.ok) throw { isApiClientError: true, code: body.error?.code ?? "unknown", message: body.error?.message ?? "Something went wrong. Try again.", status: response.status } satisfies ApiClientError;
  return body;
}

export const postJson = (path: string, body: unknown) => apiFetch(path, { method: "POST", body: JSON.stringify(body) });
export const putJson = (path: string, body: unknown) => apiFetch(path, { method: "PUT", body: JSON.stringify(body) });
export const patchJson = (path: string, body: unknown) => apiFetch(path, { method: "PATCH", body: JSON.stringify(body) });
export const deleteJson = (path: string, body?: unknown) => apiFetch(path, { method: "DELETE", body: body === undefined ? undefined : JSON.stringify(body) });

export interface SignedIn { user: PublicUser }
export interface RegisterInput { email: string; password: string; displayName: string; timezone: string; eulaAccepted: boolean; birthYear: number }

export const register = async (body: RegisterInput) => (await postJson("/auth/register", body)) as SignedIn;
export const login = async (body: { email: string; password: string }) => (await postJson("/auth/login", body)) as SignedIn;
export const logout = async () => (await postJson("/auth/logout", {})) as { ok: true };
export const requestPasswordReset = async (email: string) => (await postJson("/auth/reset", { email })) as { accepted: true };
export const confirmPasswordReset = async (token: string, newPassword: string) => (await postJson("/auth/reset/confirm", { token, newPassword })) as { ok: true };

export interface PlanReply { workouts: PlanDraft["workouts"]; updatedAt: string }
export const getPlan = async () => (await apiFetch("/plans")) as PlanReply;
export const putPlan = async (draft: { workouts: object[] }) => (await putJson("/plans", draft)) as PlanReply;

export interface SessionSummary { id: string; clientId: string; status: string; setsDone: number; setsPlanned: number; workoutName: string; dayKey: string; exercises: SessionExerciseView[] }
export interface SetView { targetReps: number; actualReps: number; weight: number | null; holdSeconds: number | null; isWarmup: boolean; done: boolean; asPlanned: boolean }
export interface SessionExerciseView { exerciseId: string; name: string; equipment: string; type: "strength" | "mobility"; targetSets: number; targetReps: number; holdSeconds: number | null; order: number; skipped: boolean; sets: SetView[] }
export type GamificationReply = PublicState & { newAchievementIds?: string[] }; // E8: what this mutation unlocked
export const earnedQuery = (ids: string[] | undefined) => (ids !== undefined && ids.length > 0 ? `?earned=${ids.join(",")}` : "");
export interface SessionReply { session: SessionSummary; gamification?: GamificationReply }
export const createSession = async (body: unknown) => (await postJson("/sessions", body)) as SessionReply;
export const getSession = async (id: string) => (await apiFetch(`/sessions/${id}`)) as SessionReply;
export const patchSession = async (id: string, body: unknown) => (await patchJson(`/sessions/${id}`, body)) as SessionReply;

export interface PostReply { post: { id: string; dayKey: string }; gamification: GamificationReply }
export const createPost = async (body: unknown) => (await postJson("/posts", body)) as PostReply;
export const deletePost = async (id: string) => (await deleteJson(`/posts/${id}`)) as { ok: true; gamification: PublicState };

export async function uploadPhoto(file: File, purpose: "post" | "profile"): Promise<{ photoKey: string }> {
  const form = new FormData();
  form.set("file", file);
  form.set("purpose", purpose);
  return (await apiFetch("/photos", { method: "POST", body: form })) as { photoKey: string };
}
