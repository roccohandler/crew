// SPEC: Flow 3 plate math ("45 + 25 + 2.5 per side") · T025
import { describe, expect, it } from "vitest";
import { plateLine, platesPerSide } from "@/lib/engine/plate-math";

describe("platesPerSide", () => {
  it("reads the spec's example: 190 lb = 45 + 25 + 2.5 per side", () => {
    expect(platesPerSide(190, "lb")).toEqual({ perSide: [45, 25, 2.5], reachableTotal: 190, exact: true });
    expect(plateLine(190, "lb")).toBe("45 + 25 + 2.5 per side");
  });
  it("handles the bar alone, kilograms, and an unreachable total", () => {
    expect(plateLine(45, "lb")).toBe("just the bar");
    expect(platesPerSide(100, "kg")).toEqual({ perSide: [25, 15], reachableTotal: 100, exact: true });
    expect(platesPerSide(47, "lb")).toEqual({ perSide: [], reachableTotal: 45, exact: false });
  });
});
