// SPEC: V22 (never retroactive) · V23 (≤ pauseMaxDays) · V44 (one active pause at a time), checked in that order.
// Twin: ios/Crew/Engine/PauseValidation.swift.
import { daysBetween } from "@/lib/engine/day-key";
import type { Pause } from "@/lib/engine/gamification";
import { SpecConstants } from "@/generated/spec-constants";

export type PauseRejection = "retroactive" | "tooLong" | "alreadyPaused";

export interface PauseValidation {
  accepted: boolean;
  reason?: PauseRejection;
}

export function validatePauseRequest(today: string, startDay: string, endDay: string, existingPauses: Pause[]): PauseValidation {
  if (startDay < today) return { accepted: false, reason: "retroactive" };
  if (daysBetween(startDay, endDay) > SpecConstants.pauseMaxDays) return { accepted: false, reason: "tooLong" };
  if (existingPauses.some((pause) => pause.endDay > today)) return { accepted: false, reason: "alreadyPaused" };
  return { accepted: true };
}
