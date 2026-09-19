// SPEC: Appendix A 2026-09-18 A24 (1) — the screenshot tour, SETTINGS (the list · blocked people · profile · the photo dialog · pause,
// and the paused Home it produces · S19 How Crew works, A23). Seeded through the real API (TourSeed.swift); asserts nothing and never fails CI
// (TourSteps.swift says why); every step is a shot named NN_<tab>_<screen>_<state> for design/baselines/. The two legal rows open
// Safari on the deployed site, which the CI harness is not — they are not toured.
// WRITTEN — UNVERIFIED (needs Mac + simulator).

import XCTest

@MainActor
final class Tour_SettingsTests: XCTestCase {
    private let app = XCUIApplication()
    private let seed = SeedClient()

    override func setUp() async throws { continueAfterFailure = true }

    func testSettings() async throws {
        let member = try await tourFilledMember(seed)
        tourLaunch(app, as: member)
        tourWaitForHome(app)
        tourTap(app.tabBars.buttons["Settings"])
        _ = app.staticTexts["Units"].waitForExistence(timeout: 15)
        tourShot(app, "settings_settings_top", "tapped the Settings tab")
        tourScroll(app, until: app.staticTexts["Version"]) // three pages since W8: one swipe stops at Account
        tourShot(app, "settings_settings_bottom", "scrolled to the account rows")
        tourScroll(app, until: app.buttons["Blocked people"], down: true) // a no-op while the row is still on screen
        if tourTap(app.buttons["Blocked people"], timeout: 5) {
            _ = app.staticTexts["No one blocked."].waitForExistence(timeout: 10) // the baseline was a blank page: shot before the list had loaded
            tourShot(app, "settings_blocked_empty", "tapped Blocked people")
            tourBack(app)
        }
        tourScroll(app, until: tourButton(app, startingWith: "Maya Tour"), down: true) // back to the top, however long the list is
        app.swipeDown() // run 35347725730: "hittable" was true with the row still half under the navigation bar, and the tap missed it
        if tourTap(tourButton(app, startingWith: "Maya Tour"), timeout: 5) {
            tourShot(app, "settings_profile_default", "tapped the profile row")
            if tourTap(app.buttons["Change photo"], timeout: 5) {
                tourShot(app, "settings_photo_dialog", "tapped the avatar")
                tourDismissDialog(app)
            }
            tourBack(app)
        }
        guard tourTap(tourButton(app, startingWith: "Pause my plan"), timeout: 5) else { return }
        tourShot(app, "settings_pause_default", "tapped Pause my plan")
        guard tourTap(app.buttons["Pause until then"], timeout: 5) else { return }
        tourShot(app, "settings_pause_active", "tapped Pause until then")
        tourBack(app)
        tourTap(app.tabBars.buttons["Home"])
        _ = app.buttons["End the pause"].waitForExistence(timeout: 15)
        tourShot(app, "home_home_paused", "went Home with the plan paused")
        tourLaunch(app, as: member, dark: true) // A28 (a): off-season in Midnight
        _ = app.buttons["End the pause"].waitForExistence(timeout: 25)
        tourShot(app, "home_home_paused_dark", "the same off-season Home in dark mode")
    }

    // A23 RATIFIED 2026-09-19 (R-081): S19 had no tour shot, so the owner's amended page could not be reviewed. Three shots — the note
    // and the PPL section, the streak and crews sections, what the whispers said — in a method of its own, so the eight shots above
    // keep their numbers. The tour member is an adult, so the page carries all twelve lines.
    func testHowCrewWorks() async throws {
        tourLaunch(app, as: try await tourFilledMember(seed))
        tourWaitForHome(app)
        tourTap(app.tabBars.buttons["Settings"])
        _ = app.staticTexts["Units"].waitForExistence(timeout: 15)
        let row = app.buttons["How Crew works"]
        tourScrollClearOfBottomBar(app, until: row, pages: 8) // About is the list's last section; a row under the tab bar reports hittable
        guard tourTap(row, timeout: 5) else { return }
        _ = app.navigationBars["How Crew works"].waitForExistence(timeout: 15)
        tourShot(app, "settings_howcrewworks_top", "tapped How Crew works")
        tourScrollClearOfBottomBar(app, until: app.staticTexts["Mobility"], pages: 6) // the streak and crews sections sit right above it
        tourShot(app, "settings_howcrewworks_middle", "scrolled to the streak and crews sections")
        let clinician = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "These are estimates")).firstMatch
        tourScrollClearOfBottomBar(app, until: clinician, pages: 6) // the page's last line: the whisper list ends right above it
        tourShot(app, "settings_howcrewworks_whispers", "scrolled to what the whispers said")
    }
}
