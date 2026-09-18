// SPEC: Appendix A 2026-09-18 A24 (1) and (5) ("macros join the tour when W8 ships") · docs/nutrition-addendum.md §4 · 6.9 — the
// screenshot tour, NUTRITION: Home's "Log macros" row → Today (pulled from the server, then a slot logged) → Quick add → Logged today →
// Saved meals & template (the list · the meal form · the chain picker and a chain's items · the Template half) → Settings' Nutrition
// targets and How targets are estimated; and the first-run Today of an account with no targets yet. Seeded through the real API
// (TourSeed.swift + SeedClient.seedNutrition — another device's targets, saved meal and one-slot template); asserts nothing and never
// fails CI (TourSteps.swift says why); every step is a shot named NN_<tab>_<screen>_<state> for design/baselines/.
// WRITTEN — UNVERIFIED (needs Mac + simulator).

import XCTest

@MainActor
final class Tour_NutritionTests: XCTestCase {
    private let app = XCUIApplication()
    private let seed = SeedClient()

    override func setUp() async throws { continueAfterFailure = true }

    private func labelled(_ prefix: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    func testNutrition() async throws {
        let member = try await tourFilledMember(seed)
        do { try await seed.seedNutrition(as: member) } catch { throw XCTSkip("the nutrition seed failed: \(error)") }
        tourLaunch(app, as: member)
        tourWaitForHome(app)
        app.swipeUp() // the log rows sit under the card
        tourShot(app, "home_home_macrosrow", "scrolled Home to the log rows — Log macros is the third")
        guard tourTap(tourButton(app, startingWith: "Log macros"), timeout: 10) else { return }
        _ = labelled("Protein: ").waitForExistence(timeout: 20)
        tourShot(app, "nutrition_today_filled", "tapped Log macros")
        if tourTap(tourButton(app, startingWith: "Breakfast"), timeout: 10) {
            tourShot(app, "nutrition_today_logged", "tapped the Breakfast slot")
        }
        if tourTap(app.buttons["Quick add"], timeout: 5) {
            tourShot(app, "nutrition_quickadd_default", "tapped Quick add")
            tourBack(app)
        }
        if tourTap(tourButton(app, startingWith: "Logged today"), timeout: 5) {
            tourShot(app, "nutrition_log_filled", "tapped Logged today")
            tourBack(app)
        }
        if tourTap(app.buttons["Saved meals & template"], timeout: 5) { tourSavedMeals() }
        tourBack(app)
        tourSettingsRows()
    }

    private func tourSavedMeals() {
        _ = labelled("Oats and whey").waitForExistence(timeout: 15)
        tourShot(app, "nutrition_meals_filled", "tapped Saved meals & template")
        if tourTap(app.buttons["Add a meal"], timeout: 5) {
            tourShot(app, "nutrition_mealform_sheet", "tapped Add a meal")
            tourDismissSheet(app, button: "Cancel")
        }
        if tourTap(app.buttons["Add from a chain"], timeout: 5) {
            tourShot(app, "nutrition_chains_sheet", "tapped Add from a chain")
            if tourTap(tourButton(app, startingWith: "Chipotle"), timeout: 5) {
                tourShot(app, "nutrition_chainitems_sheet", "tapped Chipotle")
            }
            tourBack(app) // run 35347725730: the items list has no Cancel and the pull scrolled the list — back to the chains, whose Cancel closes the sheet
            tourDismissSheet(app, button: "Cancel")
        }
        if tourTap(app.buttons["Template"], timeout: 5) {
            tourShot(app, "nutrition_template_filled", "tapped the Template segment")
        }
        tourBack(app)
    }

    private func tourSettingsRows() {
        guard tourTap(app.tabBars.buttons["Settings"]) else { return }
        _ = app.staticTexts["Units"].waitForExistence(timeout: 15)
        tourScroll(app, until: app.buttons["Nutrition targets"])
        tourShot(app, "settings_settings_nutrition", "scrolled Settings to the Nutrition rows")
        if tourTap(app.buttons["Nutrition targets"], timeout: 5) {
            tourShot(app, "settings_nutritiontargets_filled", "tapped Nutrition targets")
            tourBack(app)
        }
        if tourTap(app.buttons["How targets are estimated"], timeout: 5) {
            tourShot(app, "settings_nutritionmethod_default", "tapped How targets are estimated")
            tourBack(app)
        }
    }

    // An adult account that has never opened Nutrition: one number, one button
    func testNutritionFirstRun() async throws {
        let member = try await tourFilledMember(seed)
        tourLaunch(app, as: member)
        tourWaitForHome(app)
        tourScroll(app, until: tourButton(app, startingWith: "Log macros")) // under the fold while Home's first-visit whispers show
        guard tourTap(tourButton(app, startingWith: "Log macros"), timeout: 10) else { return }
        _ = app.buttons["Estimate my targets"].waitForExistence(timeout: 20)
        tourShot(app, "nutrition_today_firstrun", "tapped Log macros on an account with no targets yet")
    }
}
