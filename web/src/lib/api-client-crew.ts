// SPEC: 5.6.5 — the crew, safety and settings endpoints, names identical to ApiCrews.swift / SettingsModel actions. No generics (C1).
import { apiFetch, deleteJson, patchJson, postJson } from "@/lib/api-client";
import type { MemberDot } from "@/lib/crew-stream";
import type { PublicUser } from "@/lib/users";

export interface CrewSummary { id: string; name: string; emoji: string; captainId: string; inviteLink: string | null; muted?: boolean }
export interface StreamPost { id: string; type: string; caption: string; photoKey: string | null; mealTag: string | null; dayKey: string }
export interface StreamItem { kind: "post" | "message" | "system"; at: string; userId: string; id?: string; body?: string; deleted?: boolean; comeback?: boolean; reactions?: { emoji: string; userId: string }[]; post?: StreamPost }
export interface StreamReply { items: StreamItem[]; pulse: { posted: number; total: number }; members: MemberDot[]; serverTime: string }
export interface MyCrewReply { crew: CrewSummary | null; members?: MemberDot[]; pulse?: { posted: number; total: number } }
export interface CrewPreview { name: string; emoji: string; memberCount: number; full: boolean }

export const myCrew = async () => (await apiFetch("/crews")) as MyCrewReply;
export const createCrew = async (name: string, emoji: string) => (await postJson("/crews", { name, emoji })) as { crew: CrewSummary };
export const crewPreview = async (token: string) => (await apiFetch(`/crews/join?token=${encodeURIComponent(token)}`)) as CrewPreview;
export const joinCrew = async (token: string) => (await postJson("/crews/join", { token })) as { crewId: string; name: string; emoji: string };
export const stream = async (crewId: string, since?: string) => (await apiFetch(`/crews/${crewId}/stream${since ? `?since=${encodeURIComponent(since)}` : ""}`)) as StreamReply;
export const sendMessage = async (crewId: string, clientId: string, body: string) => (await postJson(`/crews/${crewId}/messages`, { clientId, body })) as { message: { id: string } };
export const deleteMessage = async (crewId: string, messageId: string) => (await deleteJson(`/crews/${crewId}/messages/${messageId}`)) as { ok: true };
export const react = async (postId: string, emoji: string) => (await postJson(`/posts/${postId}/reactions`, { emoji })) as { ok: true };
export const unreact = async (postId: string) => (await deleteJson(`/posts/${postId}/reactions`)) as { ok: true };
export const leaveOrRemove = async (crewId: string, userId?: string) => (await deleteJson(`/crews/${crewId}/members`, userId ? { userId } : {})) as { ok: true };
export const regenerateInvite = async (crewId: string) => (await postJson(`/crews/${crewId}/invite`, {})) as { inviteLink: string };
export const renameCrew = async (crewId: string, body: { name?: string; emoji?: string }) => (await patchJson(`/crews/${crewId}`, body)) as { crew: CrewSummary };
export const muteCrew = async (crewId: string, muted: boolean) => (await patchJson(`/crews/${crewId}/mute`, { muted })) as { muted: boolean };
export const report = async (targetType: string, targetId: string, reason: string) => (await postJson("/reports", { targetType, targetId, reason })) as { reportId: string };
export const block = async (userId: string) => (await postJson("/blocks", { userId })) as { ok: true };

export type MeUpdate = Partial<Pick<PublicUser, "displayName" | "units" | "timezone" | "reminderTime" | "profilePhotoKey" | "welcomeBackAckDay">>;
export const updateMe = async (body: MeUpdate) => (await patchJson("/users/me", body)) as PublicUser;
export const deleteAccount = async () => (await deleteJson("/users/me", { confirm: "delete" })) as { ok: true };
export const getPause = async () => (await apiFetch("/pause")) as { pause: { startDay: string; endDay: string } | null };
export const createPause = async (startDay: string, endDay: string, timezone: string) => (await postJson("/pause", { startDay, endDay, timezone })) as { pause: { startDay: string; endDay: string } };
export const endPause = async () => (await deleteJson("/pause")) as { ok: true };
