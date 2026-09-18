// SPEC: A21.10 (owner-approved 2026-09-17; W6) — LIGHT MODE IS THE PRIMARY and dark must render correctly on every screen. No
// machine here can look at a screen, so this journey PHOTOGRAPHS every tab twice — light, then dark (`-AppleInterfaceStyle Dark`,
// the simulator's user-defaults override) — for the owner's review in the xcresult (CrewUITests/Screenshots.swift). It asserts only
// what a screenshot cannot: each tab opens, the A19.4 Charts | Journal segment is there and switches, the W6 Units section exists.
// Seeded like journey ② (a member with a plan, a post and a crew). WRITTEN — UNVERIFIED (needs Mac + simulator).

import XCTest

@MainActor
final class Journey4_ScreensTests: XCTestCase {
    private let app = XCUIApplication()
    private let seed = SeedClient()

    private func launch(dark: Bool) async throws {
        continueAfterFailure = false
        dismissSystemPrompts() // JourneySteps.swift: a signed build shows system prompts (Save Password, permissions)
        let member = try await seed.register(name: dark ? "Screens Dark" : "Screens Light")
        try await seed.putPlanForEveryDay(as: member)
        try await seed.postMeal(as: member)
        _ = try await seed.createCrew(as: member)
        app.launchArguments = ["-uiTest", "-seededReturningUser"] + (dark ? ["-AppleInterfaceStyle", "Dark"] : [])
        app.launchEnvironment["CREW_SEED_SESSION"] = member.json
        app.launch()
    }

    private func screenSays() -> String { app.staticTexts.allElementsBoundByIndex.prefix(4).map(\.label).joined(separator: " | ") }

    private func walkTheTabs(_ mode: String) {
        XCTAssertTrue(app.buttons["Post a meal"].waitForExistence(timeout: 20), "never landed on Home (\(mode)) — the screen says: \(screenSays())")
        shoot(app, "S07 Home — \(mode)")
        app.tabBars.buttons["Plan"].tap()
        XCTAssertTrue(app.navigationBars["Plan"].waitForExistence(timeout: 10), "Plan did not open (\(mode))")
        shoot(app, "S14 Plan — \(mode)")
        app.tabBars.buttons["Crew"].tap()
        XCTAssertTrue(app.navigationBars["Crew"].waitForExistence(timeout: 10), "Crew did not open (\(mode))")
        shoot(app, "S12 Crew — \(mode)")
        app.tabBars.buttons["Progress"].tap()
        XCTAssertTrue(app.navigationBars["Progress"].waitForExistence(timeout: 10), "Progress did not open (\(mode))")
        XCTAssertTrue(app.buttons["Charts"].exists && app.buttons["Journal"].exists, "A19.4: the Charts | Journal segment is missing")
        shoot(app, "S15 Progress charts — \(mode)")
        app.buttons["Journal"].tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH 'Your journal keeps everything'")).firstMatch.waitForExistence(timeout: 10), "the Journal segment did not show the journal (\(mode)) — the screen says: \(screenSays())")
        shoot(app, "S16 Journal segment — \(mode)")
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10), "Settings did not open (\(mode))")
        XCTAssertTrue(app.staticTexts["Units"].waitForExistence(timeout: 5), "W6: the Units section is missing")
        shoot(app, "S17 Settings — \(mode)")
    }

    func testEveryTabInLight() async throws {
        try await launch(dark: false)
        walkTheTabs("light")
    }

    func testEveryTabInDark() async throws {
        try await launch(dark: true)
        walkTheTabs("dark")
    }
}
