// SPEC: Appendix A 2026-09-18 A24 (1) — the screenshot tour, CREW (stream · react dialog · invite sheet · solo · create crew · join by
// code). Seeded through the real API (TourSeed.swift); asserts nothing and never fails CI (TourSteps.swift says why); every step
// is a shot named NN_<tab>_<screen>_<state> for design/baselines/.
// WRITTEN — UNVERIFIED (needs Mac + simulator).

import XCTest

@MainActor
final class Tour_CrewTests: XCTestCase {
    private let app = XCUIApplication()
    private let seed = SeedClient()

    override func setUp() async throws { continueAfterFailure = true }

    func testFilled() async throws {
        tourLaunch(app, as: try await tourFilledMember(seed))
        tourWaitForHome(app)
        tourTap(app.tabBars.buttons["Crew"])
        _ = tourButton(app, startingWith: "React").waitForExistence(timeout: 20)
        tourShot(app, "crew_stream_filled", "tapped the Crew tab — two crew-mates trained today")
        if tourTap(tourButton(app, startingWith: "React"), timeout: 5) {
            tourShot(app, "crew_react_dialog", "tapped React on the first post")
            tourDismissDialog(app)
        }
        if tourTap(app.buttons["Invite"], timeout: 5) {
            _ = app.buttons["Copy code"].waitForExistence(timeout: 10)
            tourShot(app, "crew_invite_sheet", "tapped Invite")
            app.swipeUp()
            tourShot(app, "crew_invite_sheet_lower", "scrolled the invite sheet to the captain's controls")
            tourDismissSheet(app, button: "Done")
        }
    }

    func testEmpty() async throws {
        let member = try await tourEmptyMember(seed, "Solo Tour")
        do { try await seed.putTourPlan(as: member); try await seed.logCardio(as: member) } catch { throw XCTSkip("the tour seed failed: \(error)") }
        tourLaunch(app, as: member)
        tourWaitForHome(app)
        tourTap(app.tabBars.buttons["Crew"])
        _ = app.buttons["Start a crew"].waitForExistence(timeout: 15)
        tourShot(app, "crew_solo_empty", "tapped the Crew tab with no crew")
        if tourTap(app.buttons["Start a crew"]) {
            tourShot(app, "crew_create_sheet", "tapped Start a crew")
            tourDismissSheet(app, button: "Cancel")
        }
        if tourTap(app.buttons["I have an invite"]) {
            tourShot(app, "crew_joincode_sheet", "tapped I have an invite")
            tourDismissSheet(app, button: "Cancel")
        }
    }
}
