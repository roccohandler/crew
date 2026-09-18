// Resolve moderation reports — LOCAL ONLY, a human's act after acting on the emailed report (E9: the email IS the queue; there is
// no admin surface). Run from web/ with the database in the environment:
//     cd web && node scripts/resolve-reports.ts --list                 # every open report, oldest first
//     cd web && node scripts/resolve-reports.ts <reportId> [<reportId> …]   # mark those resolved (status + resolvedAt)
// It prints what it resolved and nothing else changes; an unknown, malformed or already-resolved id is reported as skipped.
// It is never callable from the server: this file lives outside src/app (Next routes nothing here) and it refuses to run when
// Vercel's environment is present. SPEC: W5 (owner-approved 2026-09-17) · E9 · docs/api.md reports · C5 (lib/reports.ts is the one place).
import { register } from "node:module";

register("./alias-hooks.mjs", import.meta.url); // plain node cannot resolve the app's `@/` alias; see alias-hooks.mjs
const { openReports, resolveReports } = await import("@/lib/reports");
const { closeDb } = await import("@/lib/db");

if (process.env.VERCEL !== undefined || process.env.NEXT_RUNTIME !== undefined) {
  console.error("resolve-reports runs on a laptop against the database, never on a server.");
  process.exit(1);
}

const args = process.argv.slice(2).filter((arg) => arg.length > 0);

if (args.length === 0 || args.includes("--list")) {
  const open = await openReports();
  if (open.length === 0) console.log("No open reports.");
  for (const report of open) console.log(`${report._id.toHexString()}  ${report.createdAt.toISOString()}  ${report.targetType} ${report.targetId.toHexString()}  by ${report.reporterId.toHexString()}  — ${report.reason}`);
  if (args.length === 0) console.log("\nUsage: node scripts/resolve-reports.ts <reportId> [<reportId> …]");
  await closeDb();
  process.exit(0);
}

const resolved = await resolveReports(args);
const resolvedIds = new Set(resolved.map((report) => report._id.toHexString()));
for (const report of resolved) console.log(`resolved  ${report._id.toHexString()}  ${report.targetType} ${report.targetId.toHexString()}  — ${report.reason}`);
for (const id of args) if (!resolvedIds.has(id)) console.log(`skipped   ${id}  (not an open report)`);
console.log(`${resolved.length} resolved, ${args.length - resolved.length} skipped.`);
await closeDb();
