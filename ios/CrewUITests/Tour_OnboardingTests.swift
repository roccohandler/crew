// SPEC: Appendix A 2026-09-18 A24 (1) — the screenshot tour, ONBOARDING (Flow 1: hero → invite code → log in → days → experience →
// the week, built → swap → save). Asserts nothing and never fails CI (TourSteps.swift says why); every step is a shot named
// NN_<tab>_<screen>_<state> for design/baselines/. Journey ① carries the assertions for this flow.
// WRITTEN — UNVERIFIED (needs Mac + simulator).

import XCTest

@MainActor
final class Tour_OnboardingTests: XCTestCase {
    private let app = XCUIApplication()

    func testOnboardingFlow() {
        continueAfterFailure = true
        dismissSystemPrompts()
        app.launchArguments = ["-uiTest", "-resetState"]
        app.launch()

        _ = app.buttons["Build my week"].waitForExistence(timeout: 20)
        tourShot(app, "onboarding_intro_default", "fresh install, first launch")
        if tourTap(app.buttons["I have an invite"]) {
            tourShot(app, "onboarding_invitecode_empty", "tapped I have an invite")
            tourBack(app)
        }
        if tourTap(app.buttons["Log in"]) {
            tourShot(app, "onboarding_login_empty", "tapped Log in")
            tourBack(app)
        }
        tourTap(app.buttons["Build my week"])
        _ = app.buttons["Continue"].waitForExistence(timeout: 15)
        tourShot(app, "onboarding_days_default", "tapped Build my week")
        tourTap(app.buttons["Continue"])
        _ = app.buttons["Brand new"].waitForExistence(timeout: 15)
        tourShot(app, "onboarding_experience_default", "tapped Continue")
        tourTap(app.buttons["Brand new"])
        _ = app.buttons["Looks good"].waitForExistence(timeout: 15)
        tourShot(app, "onboarding_plan_built", "answered Brand new")
        // A26: the first row of every plan is the owner's flat bench. The workout cards start BELOW the week rows, so the step scrolls
        // to the row before it shoots and taps (run 35400020876 lost the swap-sheet shot to the old "second button whose label says
        // Press" query, and run 35403203894 shot the rows still hidden under the bottom bar — TourSteps says why)
        let exercise = tourButton(app, startingWith: "Barbell Bench Press")
        tourScrollClearOfBottomBar(app, until: exercise)
        if exercise.exists { tourShot(app, "onboarding_plan_rows", "scrolled to the workout cards — every row with its equipment chip") } // ui-reviewer, run 35400020876: the chip was in no shot
        if tourTap(exercise, timeout: 5) {
            tourShot(app, "onboarding_swap_sheet", "tapped an exercise")
            tourDismissSheet(app, button: "Cancel")
        }
        tourTap(app.buttons["Looks good"])
        _ = app.buttons["Save your plan"].waitForExistence(timeout: 15)
        tourShot(app, "onboarding_save_empty", "tapped Looks good")
        let name = app.textFields["Name"]
        if tourTap(name, timeout: 5), waitForKeyboardFocus(name, timeout: 5) {
            name.typeText("Maya")
            tourShot(app, "onboarding_save_typing", "typed a name — the keyboard is up")
        }
    }
}
