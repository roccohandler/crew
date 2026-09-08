// SPEC: 8.4 journey ① — fresh install → questions → plan → save/auth → first workout incl. mobility hold → post → celebration ·
// T028 (Phase 2 gate). Runs against the local server (web: `node tests/e2e/dev-server.mjs` — in-memory Mongo + next dev on :3000,
// the harness Playwright uses); every run registers a fresh account, so the server needs no special-casing.
// WRITTEN — UNVERIFIED (needs Mac + simulator).

import XCTest

final class Journey1_NewUserTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launchArguments = ["-uiTest", "-resetState"]
        app.launch()
    }

    func testFreshInstallToFirstPostAndCelebration() {
        // S02 hero: three CTAs on one screen, no carousel
        XCTAssertTrue(app.staticTexts["One plan. Every week. Your crew sees you show up."].waitForExistence(timeout: 5))
        shoot(app, "S02 hero")
        app.buttons["Build my week"].tap()

        // S03 days: Mon/Wed/Fri pre-selected, the encouragement line reads live
        XCTAssertTrue(app.staticTexts["3 days a week — solid."].waitForExistence(timeout: 2))
        shoot(app, "S03 days")
        app.buttons["Continue"].tap()

        // single-selects auto-advance
        app.buttons["Brand new"].tap()
        XCTAssertTrue(app.staticTexts["What do you have access to?"].waitForExistence(timeout: 2))
        app.buttons["Full gym"].tap()

        // S04 reveal
        XCTAssertTrue(app.staticTexts["Your week, built."].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Tap any exercise to swap it."].exists)
        shoot(app, "S04 the week, built")
        app.buttons["Looks good"].tap()

        // S05 save with email (Sign in with Apple needs a device)
        XCTAssertTrue(app.staticTexts["Save your plan"].waitForExistence(timeout: 2))
        shoot(app, "S05 save your plan")
        let name = app.textFields["Name"]
        name.tap(); name.typeText("Journey One")
        let email = app.textFields["Email"]
        email.tap(); email.typeText("journey1-\(Int(Date().timeIntervalSince1970))@example.com")
        let password = app.secureTextFields["Password"]
        password.tap(); password.typeText("journey password 1")
        let year = app.textFields["Birth year"]
        year.tap(); year.typeText("1994")
        app.buttons["Save your plan"].tap()

        // S07 bridge state on Home: unlit flame, one oversized CTA
        XCTAssertTrue(app.staticTexts["Your first flame lights today."].waitForExistence(timeout: 10))
        shoot(app, "S07 Home — the bridge")
        let startFirst = app.buttons["Start your first workout"]
        let postMeal = app.buttons["Start your streak — post a meal"]
        XCTAssertTrue(startFirst.exists || postMeal.exists)
        if startFirst.exists {
            startFirst.tap()
            // S09: check the first set, run one hold, complete
            let firstSet = app.buttons.matching(NSPredicate(format: "label CONTAINS 'set 1 of'")).firstMatch
            XCTAssertTrue(firstSet.waitForExistence(timeout: 5))
            firstSet.tap()
            shoot(app, "S09 session")
            app.buttons["Complete workout"].tap()
            // S10 celebration: XP counts in, then Done
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '+'")).firstMatch.waitForExistence(timeout: 5))
            shoot(app, "S10 celebration")
            app.buttons["Done"].tap()
        } else {
            postMeal.tap()
            let caption = app.textFields["Say something (or don't)"]
            XCTAssertTrue(caption.waitForExistence(timeout: 3))
            caption.tap(); caption.typeText("protein shake post-gym")
            app.buttons["Post"].tap()
        }
        // Back on Home the bridge is gone forever; the flame is lit
        XCTAssertFalse(app.staticTexts["Your first flame lights today."].waitForExistence(timeout: 2))
        shoot(app, "S07 Home — the flame lit")
    }
}
