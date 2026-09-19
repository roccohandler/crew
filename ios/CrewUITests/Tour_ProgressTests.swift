// SPEC: Appendix A 2026-09-18 A24 (1) — the screenshot tour, PROGRESS as A28 (d) draws it (design/targets 12): the top, filled and
// empty, light and dark; Charts and the Journal, one tap below it. Seeded through the real
// API (TourSeed.swift); asserts nothing and never fails CI (TourSteps.swift says why); every step is a shot named
// NN_<tab>_<screen>_<state> for design/baselines/.
// WRITTEN — UNVERIFIED (needs Mac + simulator).

import XCTest

@MainActor
final class Tour_ProgressTests: XCTestCase {
    private let app = XCUIApplication()
    private let seed = SeedClient()

    override func setUp() async throws { continueAfterFailure = true }

    func testFilled() async throws {
        let member = try await tourFilledMember(seed)
        tourLaunch(app, as: member)
        tourWaitForHome(app)
        tourTap(app.tabBars.buttons["Progress"])
        _ = app.buttons["Journal"].waitForExistence(timeout: 15)
        tourShot(app, "progress_top_filled", "tapped the Progress tab — the season, the heat map")
        if tourTap(app.buttons["Charts"]) {
            tourShot(app, "progress_charts_filled", "tapped Charts")
            app.swipeUp()
            tourShot(app, "progress_charts_filled_lower", "scrolled the charts")
            tourBack(app)
        }
        if tourTap(app.buttons["Journal"]) {
            tourShot(app, "progress_journal_filled", "tapped Journal")
        }
        tourLaunch(app, as: member, dark: true) // A28 (a): Progress in Midnight (mockup 12 dark)
        tourWaitForHome(app)
        tourTap(app.tabBars.buttons["Progress"])
        _ = app.buttons["Journal"].waitForExistence(timeout: 15)
        tourShot(app, "progress_top_filled_dark", "the same Progress in dark mode")
    }

    func testEmpty() async throws {
        tourLaunch(app, as: try await tourEmptyMember(seed, "Progress Empty"))
        _ = app.tabBars.buttons["Progress"].waitForExistence(timeout: 25)
        tourTap(app.tabBars.buttons["Progress"])
        _ = app.buttons["Go to today"].waitForExistence(timeout: 15)
        tourShot(app, "progress_top_empty", "tapped the Progress tab with nothing logged — one invitation, no rows")
    }
}
