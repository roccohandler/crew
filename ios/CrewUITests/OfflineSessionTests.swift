// SPEC: 8.4 state probe "Resume-after-kill" · S07 (Resume banner when a session is open) · S09 ("survives kill"; every tap
// saves) · Flow 3 crash-proof ("Resume workout" survives anything) · E17 (an in-progress workout finishes on the device it
// started on). The airplane-mode half of 8.4/8.6 needs a phone (a simulator cannot drop its own network) and stays on the manual
// device checklist (OWNER-REVIEW §6). The member is built the journey ① way with EVERY day selected, so today is a workout day
// whatever the calendar says. WRITTEN — UNVERIFIED (needs Mac + simulator). T025 / T043

import XCTest

final class OfflineSessionTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launchArguments = ["-uiTest", "-resetState"]
        app.launch()
    }

    private func dayToggle(_ index: Int) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label IN {'M', 'T', 'W', 'F', 'S'}")).element(boundBy: index)
    }

    func testACheckedSetSurvivesAKillAndHomeOffersResume() {
        XCTAssertTrue(app.staticTexts["One plan. Every week. Your crew sees you show up."].waitForExistence(timeout: 5))
        app.buttons["Build my week"].tap()
        XCTAssertTrue(app.staticTexts["3 days a week — solid."].waitForExistence(timeout: 2))
        for unselected in [1, 3, 5, 6] { dayToggle(unselected).tap() } // Mon/Wed/Fri are pre-selected; now all seven
        app.buttons["Continue"].tap()
        app.buttons["Brand new"].tap()
        XCTAssertTrue(app.staticTexts["What do you have access to?"].waitForExistence(timeout: 2))
        app.buttons["Full gym"].tap()
        XCTAssertTrue(app.staticTexts["Your week, built."].waitForExistence(timeout: 2))
        app.buttons["Looks good"].tap()

        XCTAssertTrue(app.staticTexts["Save your plan"].waitForExistence(timeout: 2))
        let name = app.textFields["Name"]
        name.tap(); name.typeText("Kill Survivor")
        let email = app.textFields["Email"]
        email.tap(); email.typeText("resume-\(Int(Date().timeIntervalSince1970))@example.com")
        let password = app.secureTextFields["Password"]
        password.tap(); password.typeText("journey password 1")
        let year = app.textFields["Birth year"]
        year.tap(); year.typeText("1994")
        app.buttons["Save your plan"].tap()

        XCTAssertTrue(app.staticTexts["Your first flame lights today."].waitForExistence(timeout: 20))
        let startFirst = app.buttons["Start your first workout"]
        XCTAssertTrue(startFirst.waitForExistence(timeout: 5), "every day is a training day, so the bridge CTA is the workout")
        startFirst.tap()

        // One tap logs set 1 at its pre-filled numbers — and that tap is saved before anything else happens (Flow 3)
        let firstSet = app.buttons.matching(NSPredicate(format: "label CONTAINS 'set 1 of'")).firstMatch
        XCTAssertTrue(firstSet.waitForExistence(timeout: 5))
        firstSet.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'set 1 of' AND label CONTAINS 'done'")).firstMatch.waitForExistence(timeout: 3))
        shoot(app, "S09 session — set 1 done, about to be killed")

        // The kill: no warning, no save button. A relaunch (signed in, nothing reset) must offer the open session back.
        app.terminate()
        app.launchArguments = ["-uiTest"]
        app.launch()
        let resume = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Resume workout'")).firstMatch
        XCTAssertTrue(resume.waitForExistence(timeout: 20), "Home shows no Resume banner after a kill — the open session was lost")
        shoot(app, "S07 Home — Resume banner after a kill")
        resume.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'set 1 of' AND label CONTAINS 'done'")).firstMatch.waitForExistence(timeout: 5), "the checked set did not survive the kill")
        XCTAssertTrue(app.buttons["Complete workout"].exists) // always visible (S09)
        shoot(app, "S09 session — resumed with set 1 still done")
    }
}
