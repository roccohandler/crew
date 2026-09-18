// SPEC: Appendix A 2026-09-18 A24 (1) — the screenshot tour, SETTINGS (the list · blocked people · profile · the photo dialog · pause,
// and the paused Home it produces). Seeded through the real API (TourSeed.swift); asserts nothing and never fails CI
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
        tourLaunch(app, as: try await tourFilledMember(seed))
        tourWaitForHome(app)
        tourTap(app.tabBars.buttons["Settings"])
        _ = app.staticTexts["Units"].waitForExistence(timeout: 15)
        tourShot(app, "settings_settings_top", "tapped the Settings tab")
        app.swipeUp()
        tourShot(app, "settings_settings_bottom", "scrolled to the account rows")
        if tourTap(app.buttons["Blocked people"], timeout: 5) {
            tourShot(app, "settings_blocked_empty", "tapped Blocked people")
            tourBack(app)
        }
        app.swipeDown()
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
        _ = app.buttons["End the pause now"].waitForExistence(timeout: 15)
        tourShot(app, "home_home_paused", "went Home with the plan paused")
    }
}
