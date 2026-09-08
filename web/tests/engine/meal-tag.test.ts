// SPEC: Flow 4 time-smart tags · G10 boundaries · T027
import { describe, expect, it } from "vitest";
import { mealTagFor } from "@/lib/engine/meal-tag";

const minutes = (hour: number, minute = 0) => hour * 60 + minute;

describe("mealTagFor", () => {
  it("matches Flow 4's examples and G10's boundaries", () => {
    expect(mealTagFor(minutes(7))).toBe("breakfast");
    expect(mealTagFor(minutes(12, 30))).toBe("lunch");
    expect(mealTagFor(minutes(19))).toBe("dinner");
    expect(mealTagFor(minutes(2))).toBe("snack");
    expect(mealTagFor(minutes(4))).toBe("breakfast");
    expect(mealTagFor(minutes(10, 29))).toBe("breakfast");
    expect(mealTagFor(minutes(10, 30))).toBe("lunch");
    expect(mealTagFor(minutes(15, 30))).toBe("dinner");
    expect(mealTagFor(minutes(21))).toBe("snack");
    expect(mealTagFor(minutes(23, 59))).toBe("snack");
  });
});
