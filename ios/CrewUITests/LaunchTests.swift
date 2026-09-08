// SPEC: S01 (warm start bypasses splash < 1 s) · 6.2 (launch budgets measured by signposts) · T007 scaffold.
// WRITTEN — UNVERIFIED (needs Mac).

import XCTest

final class LaunchTests: XCTestCase {
    func testLaunchShowsTheBoneFrameWithoutASplash() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTest", "-resetState"] // a signed-in simulator (journey ②) would land on Home instead of the hero
        app.launch()
        XCTAssertTrue(app.staticTexts["One plan. Every week. Your crew sees you show up."].waitForExistence(timeout: 2))
    }
}
