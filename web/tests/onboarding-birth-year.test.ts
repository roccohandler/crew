// SPEC: E9 (EULA at signup, age floor 13+) · S05 (birth year on "Save your plan") · A20.11 — THE CLIENT MUST REFUSE
// EXACTLY WHAT THE SERVER REFUSES. Until A20.11 it did not: iOS asked only whether the text PARSED, so "19" raised no
// error and was POSTed, and the user read the server's raw "birthYear: Too small: expected number to be >=1900" under
// a field whose own message promises four digits (run 35073421853, CameraDeniedTests). Web checked the four-digit
// shape but neither client checked the two BOUNDS. This pins the PARITY, not the wording.
import { describe, expect, it } from "vitest";
import { SpecConstants } from "@/generated/spec-constants";
import { validateField } from "@/components/onboarding/SaveForm";
import { requireSignupGates } from "@/lib/users";

// A fixed clock: the rule is arithmetic against a year, not "today", and a test that drifts with the calendar is the
// exact shape that went red on a Friday twice in this repo (F04, F43).
const now = new Date(Date.UTC(2026, 0, 15));
const thisYear = now.getUTCFullYear();

// The two halves the server actually applies: validate.ts birthYearSchema, then users.ts requireSignupGates.
function serverAccepts(year: number): boolean {
  if (!Number.isInteger(year) || year < SpecConstants.birthYearMin || year > thisYear) return false;
  try {
    requireSignupGates(true, year, now);
    return true;
  } catch {
    return false;
  }
}

describe("S05 birth year — the client refuses exactly what the server refuses (E9)", () => {
  it("catches the two-digit year that run 35073421853 sent to the server", () => {
    expect(validateField("birthYear", "19", now)).toBe("Four digits, like 1994.");
  });

  it("four digits is not enough on its own — a year under the floor is still a typo", () => {
    expect(validateField("birthYear", "0999", now)).toBe("Four digits, like 1994.");
  });

  it("someone under the age floor is told the rule in the sentence the screen already carries", () => {
    const tooYoung = String(thisYear - SpecConstants.minimumAgeYears + 1);
    expect(validateField("birthYear", tooYoung, now)).toBe(`Crew is for people ${SpecConstants.minimumAgeYears} and up.`);
  });

  it("EXACTLY the age floor is accepted — the client must never be stricter than the server", () => {
    expect(validateField("birthYear", String(thisYear - SpecConstants.minimumAgeYears), now)).toBe("");
  });

  it("the floor year itself is accepted", () => {
    expect(validateField("birthYear", String(SpecConstants.birthYearMin), now)).toBe("");
  });

  it("an ordinary year is accepted and the other fields are untouched by this change", () => {
    expect(validateField("birthYear", "1994", now)).toBe("");
    expect(validateField("displayName", "Rocco", now)).toBe("");
    expect(validateField("email", "a@b.co", now)).toBe("");
  });

  it("agrees with the server on every year from before the floor to past today", () => {
    for (let year = SpecConstants.birthYearMin - 2; year <= thisYear + 1; year += 1) {
      const clientAccepts = validateField("birthYear", String(year), now) === "";
      expect(clientAccepts, `year ${year}`).toBe(serverAccepts(year));
    }
  });
});
