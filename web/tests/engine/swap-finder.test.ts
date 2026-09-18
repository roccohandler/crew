// SPEC: T020 · 8.3 SwapFinder: candidates share the job (same type; tiers swapGroup → pattern → region), never return the
// incumbent · Flow 1 step 4 (3–5 alternatives that do the same job) for EVERY exercise in every template list · A21.1
// (owner-approved 2026-09-17): no equipment tier — the pool is the whole gym catalog, so a candidate's equipment is any of the
// five tags · A26 (owner-approved 2026-09-18): the templates are three flat lists, and every swap the owner NAMED for a row is
// offered at every experience.
import { describe, expect, it } from "vitest";
import { swapCandidates } from "@/lib/engine/swap-finder";
import { exercises, planTemplates, regionOfPattern, type Equipment, type Experience } from "@/generated/seed";
import { SpecConstants } from "@/generated/spec-constants";

const byId = new Map(exercises.map((exercise) => [exercise.id, exercise]));
const experiences: Experience[] = ["brandNew", "some", "experienced"];
const equipmentTags: Equipment[] = ["barbell", "dumbbell", "machine", "cable", "bodyweight"];

describe("swapCandidates", () => {
  it("every templated exercise gets 3–5 same-job alternatives from the gym catalog, never itself", () => {
    for (const ids of Object.values(planTemplates.templates)) {
      for (const experience of experiences) {
        for (const id of ids) {
          const incumbent = byId.get(id)!;
          const candidates = swapCandidates(incumbent, experience, exercises);
          expect(candidates.length, `${id} / ${experience}`).toBeGreaterThanOrEqual(SpecConstants.swapCandidatesMin);
          expect(candidates.length).toBeLessThanOrEqual(SpecConstants.swapCandidatesMax);
          for (const candidate of candidates) {
            expect(candidate.id).not.toBe(incumbent.id);
            expect(candidate.type).toBe(incumbent.type);
            expect(equipmentTags).toContain(candidate.equipment);
            expect(regionOfPattern[candidate.pattern]).toBe(regionOfPattern[incumbent.pattern]);
          }
        }
      }
    }
  });

  it("offers every swap the owner named for a template row, at every experience (A26)", () => {
    expect(Object.keys(planTemplates.namedSwaps).length).toBeGreaterThan(0);
    for (const [rowId, named] of Object.entries(planTemplates.namedSwaps)) {
      for (const experience of experiences) {
        const offered = swapCandidates(byId.get(rowId)!, experience, exercises).map((candidate) => candidate.id);
        for (const id of named) expect(offered, `${rowId} / ${experience}`).toContain(id);
      }
    }
    const offeredForRow = swapCandidates(byId.get("machine-row")!, "brandNew", exercises).map((candidate) => candidate.name);
    expect(offeredForRow).toEqual(expect.arrayContaining(["One-Arm Dumbbell Row", "Barbell Row"]));
  });

  it("prefers the same swapGroup, then the same pattern, and ranks same-or-lower level first", () => {
    const bench = byId.get("barbell-bench-press")!;
    const candidates = swapCandidates(bench, "brandNew", exercises);
    expect(candidates.every((candidate) => candidate.swapGroup === "chestPress")).toBe(true);
    expect(candidates[0]?.level).toBe("brandNew");
    const holds = swapCandidates(byId.get("couch-stretch")!, "some", exercises);
    expect(holds.every((candidate) => candidate.type === "mobility")).toBe(true);
  });
});
