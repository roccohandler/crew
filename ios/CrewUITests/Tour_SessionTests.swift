// SPEC: Appendix A 2026-09-18 A24 (1) — the screenshot tour, THE WORKOUT LOGGER (start · weight entry · mid-set with the rest timer ·
// swap · the discard dialog · complete → celebration → the reminder sheet → Home, done). The tab bar is hidden from the first
// shot to the celebration (A21.11) — these are the shots that show it. Seeded through the real API (TourSeed.swift); asserts
// nothing and never fails CI (TourSteps.swift says why); every step is a shot named NN_<tab>_<screen>_<state>.
// WRITTEN — UNVERIFIED (needs Mac + simulator).

import XCTest

@MainActor
final class Tour_SessionTests: XCTestCase {
    private let app = XCUIApplication()
    private let seed = SeedClient()

    override func setUp() async throws { continueAfterFailure = true }

    func testLoggerStartMidSetComplete() async throws {
        let member = try await tourFilledMember(seed)
        tourLaunch(app, as: member)
        tourWaitForHome(app)
        guard tourTap(app.buttons["Start workout"]) else { return }
        let firstSet = app.buttons.matching(NSPredicate(format: "label CONTAINS 'set 1 of'")).firstMatch
        _ = firstSet.waitForExistence(timeout: 15)
        tourShot(app, "session_logger_start", "tapped Start workout")
        if tourTap(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Weight '")).firstMatch, timeout: 5) {
            tourShot(app, "session_weight_alert", "tapped the weight")
            tourTap(app.buttons["Cancel"], timeout: 3)
        }
        if tourTap(firstSet, timeout: 5) {
            tourShot(app, "session_logger_midset", "checked set 1 — the rest timer is running")
        }
        if tourTap(tourButton(app, startingWith: "Swap"), timeout: 5) {
            tourShot(app, "session_swap_sheet", "tapped Swap")
            tourDismissSheet(app, button: "Cancel")
        }
        // ui-reviewer, run 35400020876: the active card was only ever shot with the plan's SHORTEST name — the header row (name · tag ·
        // Swap · Skip) has to be seen with the longest one too (A26: "Cable Rope Triceps Extension", the second row of Push)
        let openLongName = app.buttons["Open Cable Rope Triceps Extension"]
        tourScrollClearOfBottomBar(app, until: openLongName) // the compact rows sit under the Complete bar, where a tap goes nowhere
        if tourTap(openLongName, timeout: 5) {
            // opening a lower exercise collapses the one above it, and the opened card's header lands under the navigation bar (run
            // 35405384572; debt.md) — pull the page down a quarter of the screen, in the gutter, so the header is in the shot
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.4)).press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.65)))
            tourShot(app, "session_logger_longname", "opened the second exercise — the longest name in the template")
        }
        if tourTap(app.buttons["Discard"].firstMatch, timeout: 5) {
            tourShot(app, "session_discard_dialog", "tapped Discard")
            tourDismissDialog(app)
        }
        guard tourTap(app.buttons["Complete workout"], timeout: 5) else { return }
        _ = app.buttons["Share to crew"].waitForExistence(timeout: 15)
        tourShot(app, "session_celebration_complete", "tapped Complete workout")
        tourTap(app.buttons["Share to crew"], timeout: 5)
        if app.buttons["Not now"].waitForExistence(timeout: 8) {
            tourShot(app, "home_reminder_sheet", "shared the workout — the first-workout reminder opt-in")
            tourTap(app.buttons["Not now"])
        }
        tourShot(app, "home_home_done", "back on Home with today's workout done")
        tourLaunch(app, as: member, dark: true) // A28 (a): the done Home in Midnight
        tourWaitForHome(app)
        tourShot(app, "home_home_done_dark", "the same done Home in dark mode")
    }
}
