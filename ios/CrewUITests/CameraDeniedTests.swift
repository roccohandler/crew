// SPEC: 8.4 state probe "camera-denied path" · E5 (camera denied → text-first posting; nothing dead-ends, nothing re-prompts)
// · S11 (permission-denied state; text-only ≤ 3 taps). A simulator has no camera, so `CameraCapture.isAvailable` is false there
// exactly as it is on a phone that refused the permission: the post screen must explain once, offer the library and a line of
// text, and the post must count. The member is built the journey ① way (fresh install, email save) with ONE training day that is
// not today, so Home is a rest day and the bridge CTA is the meal path. WRITTEN — UNVERIFIED (needs Mac + simulator). T027 / T043

import XCTest

final class CameraDeniedTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launchArguments = ["-uiTest", "-resetState"]
        app.launch()
    }

    // The seven day toggles carry their letter as the label (M T W T F S S), in Monday-first order
    private func dayToggle(_ index: Int) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label IN {'M', 'T', 'W', 'F', 'S'}")).element(boundBy: index)
    }

    func testNoCameraMeansTextFirstPostingStillCounts() {
        XCTAssertTrue(app.staticTexts["One plan. Every week. Your crew sees you show up."].waitForExistence(timeout: 5))
        app.buttons["Build my week"].tap()
        XCTAssertTrue(app.staticTexts["3 days a week — solid."].waitForExistence(timeout: 2))

        // Mon/Wed/Fri arrive pre-selected (1B): switch them off, then switch on tomorrow alone, so today is a rest day
        for preselected in [0, 2, 4] { dayToggle(preselected).tap() }
        let mondayFirstToday = (Calendar.current.component(.weekday, from: Date()) + 5) % 7 // Foundation: Sunday = 1 … Saturday = 7 → Monday = 0 … Sunday = 6
        dayToggle((mondayFirstToday + 1) % 7).tap()
        app.buttons["Continue"].tap()
        app.buttons["Brand new"].tap()
        XCTAssertTrue(app.staticTexts["What do you have access to?"].waitForExistence(timeout: 2))
        app.buttons["Full gym"].tap()
        XCTAssertTrue(app.staticTexts["Your week, built."].waitForExistence(timeout: 2))
        app.buttons["Looks good"].tap()

        XCTAssertTrue(app.staticTexts["Save your plan"].waitForExistence(timeout: 2))
        let name = app.textFields["Name"]
        name.tap(); name.typeText("Camera Denied")
        let email = app.textFields["Email"]
        email.tap(); email.typeText("camera-denied-\(Int(Date().timeIntervalSince1970))@example.com")
        let password = app.secureTextFields["Password"]
        password.tap(); password.typeText("journey password 1")
        let year = app.textFields["Birth year"]
        year.tap(); year.typeText("1994")
        app.buttons["Save your plan"].tap()

        // Rest day → the bridge's meal path (1D)
        XCTAssertTrue(app.staticTexts["Your first flame lights today."].waitForExistence(timeout: 20))
        let postMeal = app.buttons["Start your streak — post a meal"]
        XCTAssertTrue(postMeal.waitForExistence(timeout: 5), "today should be a rest day: the plan has one training day and it is tomorrow")
        postMeal.tap()

        // S11 permission-denied state: one calm line, no Snap button, the library and text still offered
        XCTAssertTrue(app.staticTexts["Camera's off for Crew — text posts count just the same. Turn it on in Settings whenever."].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Snap"].exists)
        XCTAssertTrue(app.buttons["Library"].exists)
        shoot(app, "S11 post — camera off")
        let caption = app.textFields["Say something (or don't)"]
        XCTAssertTrue(caption.exists)
        caption.tap(); caption.typeText("protein shake post-gym")
        app.buttons["Post"].tap()

        // The text post counted: the bridge is gone, the flame is lit
        XCTAssertFalse(app.staticTexts["Your first flame lights today."].waitForExistence(timeout: 3))
        shoot(app, "S07 Home — text post counted without a camera")
    }
}
