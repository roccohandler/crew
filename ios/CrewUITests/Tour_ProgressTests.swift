// SPEC: Appendix A 2026-09-18 A24 (1) — the screenshot tour, PROGRESS (charts and journal, filled and empty). Seeded through the real
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
        tourLaunch(app, as: try await tourFilledMember(seed))
        tourWaitForHome(app)
        tourTap(app.tabBars.buttons["Progress"])
        _ = app.buttons["Journal"].waitForExistence(timeout: 15)
        tourShot(app, "progress_charts_filled", "tapped the Progress tab — six logged days")
        app.swipeUp()
        tourShot(app, "progress_charts_filled_lower", "scrolled the charts")
        app.swipeDown()
        if tourTap(app.buttons["Journal"]) {
            tourShot(app, "progress_journal_filled", "tapped Journal")
        }
    }

    func testEmpty() async throws {
        tourLaunch(app, as: try await tourEmptyMember(seed, "Progress Empty"))
        _ = app.tabBars.buttons["Progress"].waitForExistence(timeout: 25)
        tourTap(app.tabBars.buttons["Progress"])
        _ = app.buttons["Journal"].waitForExistence(timeout: 15)
        tourShot(app, "progress_charts_empty", "tapped the Progress tab with nothing logged")
        if tourTap(app.buttons["Journal"]) {
            tourShot(app, "progress_journal_empty", "tapped Journal with nothing logged")
        }
    }
}
