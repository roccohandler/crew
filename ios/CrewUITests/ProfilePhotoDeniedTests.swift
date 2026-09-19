// SPEC: E5 (camera denied → the library still works; one calm line; nothing dead-ends, nothing re-prompts) · E1 / A7 (the profile
// picture is the one photo left — A22 G2, owner-approved 2026-09-18) · 8.4 state probe "camera-denied path", repointed from the
// retired plate journal (CameraDeniedTests) to the profile picture. A simulator has no camera, so `CameraCapture.isAvailable` is
// false there exactly as it is on a phone that refused the permission: the photo sheet offers the library and never a dead
// "Take photo". WRITTEN — UNVERIFIED (needs Mac + simulator). T041 / T043

import XCTest

@MainActor
final class ProfilePhotoDeniedTests: XCTestCase {
    private let app = XCUIApplication()
    private let seed = SeedClient()

    override func setUp() async throws {
        continueAfterFailure = false
        dismissSystemPrompts() // JourneySteps.swift: a signed build shows system prompts (Save Password, permissions)
        let member = try await seed.register(name: "No Camera")
        try await seed.putPlanForEveryDay(as: member)
        try await seed.logCardio(as: member) // a post exists (1D): Home is past the bridge and the tab bar is up
        app.launchArguments = ["-uiTest", "-seededReturningUser"]
        app.launchEnvironment["CREW_SEED_SESSION"] = member.json
        app.launch()
    }

    func testNoCameraStillOffersTheLibraryForTheProfilePicture() {
        XCTAssertTrue(app.buttons["home.add"].waitForExistence(timeout: 20), "never landed on Home — the screen says: \(app.staticTexts.allElementsBoundByIndex.prefix(3).map(\.label).joined(separator: " | "))")
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10), "Settings did not open")
        // E1 — the profile row is the member's own name and picture; it opens the Profile screen
        let profileRow = app.buttons["No Camera"].firstMatch // R-089: the profile row is a button named for its member
        XCTAssertTrue(profileRow.waitForExistence(timeout: 10), "Settings shows no profile row")
        profileRow.tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 10), "the Profile screen did not open")
        app.buttons["Change photo"].tap()
        // E5 — the library is offered; "Take photo" is absent rather than present and dead
        XCTAssertTrue(app.buttons["Choose photo"].waitForExistence(timeout: 5), "the photo sheet offers no library")
        XCTAssertFalse(app.buttons["Take photo"].exists, "a dead camera route is offered on a device with no camera")
        shoot(app, "S17 Profile — camera off, the library offered")
        let cancel = app.buttons["Cancel"]
        if cancel.exists { cancel.tap() }
    }
}
