// SPEC: Appendix A 2026-09-18 A24 (1) — the screenshot tour, THE WORKOUT LOGGER as A28 (d) draws it (design/targets 07–11): start ·
// the weight keypad · mid-set (the ledger) · swap · ⋯ and the discard dialog · the whole-workout sheet · the longest name · the
// checklist of holds · the Logger in Midnight · Finish → celebration → the reminder sheet → Home, done (A28 (c): no rest timer). The tab bar is hidden from the first
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
        _ = app.buttons["Log set 1"].waitForExistence(timeout: 15)
        tourShot(app, "session_logger_start", "tapped Start workout")
        if tourTap(app.buttons.matching(NSPredicate(format: "label ENDSWITH ' lb' OR label ENDSWITH ' kg'")).firstMatch, timeout: 5) {
            tourShot(app, "session_weight_alert", "tapped the weight")
            tourTap(app.buttons["Cancel"], timeout: 3)
        }
        if tourTap(app.buttons["Log set 1"], timeout: 5) {
            _ = app.buttons["Log set 2"].waitForExistence(timeout: 5)
            tourShot(app, "session_logger_midset", "logged set 1 — set 2 on the card, set 1 in the ledger")
        }
        if tourTap(app.buttons["Swap exercise"], timeout: 5) {
            tourShot(app, "session_swap_sheet", "tapped Swap exercise")
            tourDismissSheet(app, button: "Cancel")
        }
        if tourTap(app.buttons["More"], timeout: 5) {
            tourShot(app, "session_more_menu", "tapped ⋯ — + set, + warm-up, remove, discard")
            if tourTap(app.buttons["Discard workout"], timeout: 3) {
                tourShot(app, "session_discard_dialog", "tapped Discard workout")
                tourDismissDialog(app)
            }
        }
        // A28 (d) — the whole-workout sheet (mockup 09), then the second exercise through it: the longest name in the template (A26)
        if tourTap(app.buttons["Whole workout"], timeout: 5) {
            _ = app.buttons["Finish workout"].waitForExistence(timeout: 5)
            tourShot(app, "session_whole_workout_sheet", "tapped Whole workout")
            if tourTap(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Cable Rope Triceps Extension' AND NOT (label CONTAINS 'done')")).firstMatch, timeout: 3) {
                _ = app.buttons["Log set 1"].waitForExistence(timeout: 5)
                tourShot(app, "session_logger_longname", "jumped to the second exercise — the longest name in the template")
            }
        }
        // A28 (c), (f) — the holds' checklist (mockup 10), through the sheet's Mobility row
        if tourTap(app.buttons["Whole workout"], timeout: 5), tourTap(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Mobility' AND NOT (label CONTAINS 'done')")).firstMatch, timeout: 3) {
            _ = app.buttons["Finish workout"].waitForExistence(timeout: 5)
            tourShot(app, "session_logger_mobility", "jumped to the holds — the checklist")
        }
        tourLaunch(app, as: member, dark: true) // A28 (a): the Logger in Midnight — the open session resumes from Home
        tourWaitForHome(app)
        if tourTap(app.buttons["Resume workout"], timeout: 5) {
            _ = app.buttons["Whole workout"].waitForExistence(timeout: 10)
            tourShot(app, "session_logger_midset_dark", "the same Logger in dark mode")
            if tourTap(app.buttons["Whole workout"], timeout: 5) {
                _ = app.buttons["Finish workout"].waitForExistence(timeout: 5)
                tourShot(app, "session_whole_workout_sheet_dark", "the whole-workout sheet in dark mode")
                if tourTap(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Mobility' AND NOT (label CONTAINS 'done')")).firstMatch, timeout: 3) {
                    _ = app.buttons["Finish workout"].waitForExistence(timeout: 5)
                    tourShot(app, "session_logger_mobility_dark", "the checklist in dark mode")
                }
            }
        }
        tourLaunch(app, as: member) // back to light for the celebration and the done Home (the dark celebration: Tour_HomeTests)
        tourWaitForHome(app)
        guard tourTap(app.buttons["Resume workout"], timeout: 5), tourTap(app.buttons["Whole workout"], timeout: 10), tourTap(app.buttons["Finish workout"], timeout: 5) else { return }
        _ = app.buttons["Share to crew"].waitForExistence(timeout: 15)
        tourShot(app, "session_celebration_complete", "tapped Finish workout in the whole-workout sheet")
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
