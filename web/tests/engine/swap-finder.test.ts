// SPEC: T020 · 8.3 SwapFinder: candidates share pattern + equipment, never return the incumbent · Flow 1 step 4 (3–5
// alternatives that do the same job) for EVERY exercise in every template list at every equipment access.
import { describe, expect, it } from "vitest";
import { swapCandidates } from "@/lib/engine/swap-finder";
import { equipmentAccess, exercises, planTemplates, regionOfPattern, type EquipmentAccess, type Experience } from "@/generated/seed";
import { SpecConstants } from "@/generated/spec-constants";

const byId = new Map(exercises.map((exercise) => [exercise.id, exercise]));
const experiences: Experience[] = ["brandNew", "some", "experienced"];
const accesses: EquipmentAccess[] = ["fullGym", "dumbbells", "bodyweight"];

describe("swapCandidates", () => {
  for (const access of accesses) {
    it(`${access}: every templated exercise gets 3–5 same-job alternatives with available equipment, never itself`, () => {
      for (const byLevel of Object.values(planTemplates.templates)) {
        for (const experience of experiences) {
          for (const id of byLevel[experience][access]) {
            const incumbent = byId.get(id)!;
            const candidates = swapCandidates(incumbent, access, experience, exercises);
            expect(candidates.length, `${id} / ${access}`).toBeGreaterThanOrEqual(SpecConstants.swapCandidatesMin);
            expect(candidates.length).toBeLessThanOrEqual(SpecConstants.swapCandidatesMax);
            for (const candidate of candidates) {
              expect(candidate.id).not.toBe(incumbent.id);
              expect(candidate.type).toBe(incumbent.type);
              expect(equipmentAccess[access]).toContain(candidate.equipment);
              expect(regionOfPattern[candidate.pattern]).toBe(regionOfPattern[incumbent.pattern]);
            }
          }
        }
      }
    });
  }

  it("prefers the same swapGroup, then the same pattern, and ranks same-or-lower level first", () => {
    const bench = byId.get("barbell-bench-press")!;
    const candidates = swapCandidates(bench, "fullGym", "brandNew", exercises);
    expect(candidates.every((candidate) => candidate.swapGroup === "chestPress")).toBe(true);
    expect(candidates[0]?.level).toBe("brandNew");
    const holds = swapCandidates(byId.get("couch-stretch")!, "bodyweight", "some", exercises);
    expect(holds.every((candidate) => candidate.type === "mobility")).toBe(true);
  });
});
