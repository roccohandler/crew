// SPEC: Appendix A 2026-09-18 A24 (1) — the screenshot tour, PLAN (week map · change days · workout editor · exercise sheet · swap ·
// add exercise · the discard dialog · empty). Seeded through the real API (TourSeed.swift); asserts nothing and never fails CI
// (TourSteps.swift says why); every step is a shot named NN_<tab>_<screen>_<state> for design/baselines/.
// WRITTEN — UNVERIFIED (needs Mac + simulator).

import XCTest

@MainActor
final class Tour_PlanTests: XCTestCase {
    private let app = XCUIApplication()
    private let seed = SeedClient()

    override func setUp() async throws { continueAfterFailure = true }

    func testFilled() async throws {
        let member = try await tourFilledMember(seed)
        tourLaunch(app, as: member)
        tourWaitForHome(app)
        tourTap(app.tabBars.buttons["Plan"])
        _ = app.buttons["Change days"].waitForExistence(timeout: 15)
        tourShot(app, "plan_week_filled", "tapped the Plan tab")
        if tourTap(app.buttons["Change days"]) {
            tourShot(app, "plan_days_sheet", "tapped Change days")
            tourDismissSheet(app, button: "Cancel")
        }
        guard tourTap(tourButton(app, containing: "Push day")) else { return }
        _ = app.buttons["Add exercise"].waitForExistence(timeout: 10)
        tourShot(app, "plan_editor_filled", "tapped Push day")
        if tourTap(tourButton(app, startingWith: "Barbell Bench Press")) {
            tourShot(app, "plan_exercise_sheet", "tapped Barbell Bench Press")
            if tourTap(app.buttons["Swap exercise"], timeout: 5) {
                tourShot(app, "plan_swap_sheet", "tapped Swap exercise")
                tourDismissSheet(app, button: "Cancel")
            }
            tourDismissSheet(app, button: "Done")
        }
        if tourTap(app.buttons["Add exercise"], timeout: 5) {
            tourShot(app, "plan_addexercise_sheet", "tapped Add exercise")
            tourDismissSheet(app, button: "Cancel")
        }
        if tourTap(app.buttons["Cancel"], timeout: 5), app.buttons["Discard changes"].waitForExistence(timeout: 3) {
            tourShot(app, "plan_discard_dialog", "tapped Cancel with unsaved changes")
            tourTap(app.buttons["Discard changes"])
        }
        tourLaunch(app, as: member, dark: true) // A28 (a): Plan in Midnight (no mockup: DESIGN.md alone)
        tourWaitForHome(app)
        tourTap(app.tabBars.buttons["Plan"])
        _ = app.buttons["Change days"].waitForExistence(timeout: 15)
        tourShot(app, "plan_week_filled_dark", "the same week in dark mode")
        if tourTap(tourButton(app, containing: "Push day")) {
            _ = app.buttons["Add exercise"].waitForExistence(timeout: 10)
            tourShot(app, "plan_editor_filled_dark", "the editor in dark mode")
        }
    }

    func testEmpty() async throws {
        tourLaunch(app, as: try await tourEmptyMember(seed, "Plan Empty"))
        _ = app.tabBars.buttons["Plan"].waitForExistence(timeout: 25)
        tourTap(app.tabBars.buttons["Plan"])
        _ = app.staticTexts["No plan yet"].waitForExistence(timeout: 15)
        tourShot(app, "plan_week_empty", "tapped the Plan tab with no plan")
    }
}
