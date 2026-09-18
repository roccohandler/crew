// SPEC: E9 (no AI scanning; a human reviews — the emailed report IS the queue) · docs/api.md reports · W5 (owner-approved
// 2026-09-17): resolution is a HUMAN act from the laptop — scripts/resolve-reports.ts calls these two functions; no route ever sets
// `resolved` (there is no admin surface, on purpose — docs/MVP_STATE_REPORT.md §9). Plain functions on the real collection (C2, C4).
import { ObjectId } from "mongodb";
import { reports } from "@/lib/db";
import type { ReportDoc } from "@/lib/documents-social";

export async function openReports(): Promise<ReportDoc[]> {
  return (await reports()).find({ status: "open" }).sort({ createdAt: 1 }).toArray();
}

// Marks the named OPEN reports resolved (status + resolvedAt) and returns exactly the ones it changed; an unknown, malformed or
// already-resolved id changes nothing and is simply absent from the result — the caller prints what happened.
export async function resolveReports(ids: string[], now: Date = new Date()): Promise<ReportDoc[]> {
  const objectIds = ids.filter((id) => ObjectId.isValid(id)).map((id) => new ObjectId(id));
  if (objectIds.length === 0) return [];
  const collection = await reports();
  const targets = await collection.find({ _id: { $in: objectIds }, status: "open" }).toArray();
  if (targets.length === 0) return [];
  await collection.updateMany({ _id: { $in: targets.map((report) => report._id) } }, { $set: { status: "resolved", resolvedAt: now } });
  return targets.map((report) => ({ ...report, status: "resolved" as const, resolvedAt: now }));
}
