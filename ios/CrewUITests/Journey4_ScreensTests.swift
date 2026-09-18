// SPEC: A21.10 as amended 2026-09-18 (owner-approved: LIGHT ALWAYS, whatever the phone is set to) · W6. No machine here can look
// at a screen, so this journey PHOTOGRAPHS every tab for the owner's review in the xcresult (CrewUITests/Screenshots.swift) and
// asserts only what a screenshot cannot: each tab opens, the A19.4 Charts | Journal segment is there and switches, the W6 Units
// section exists. The dark half of this journey was retired with the 2026-09-18 ruling — the app renders light regardless, so a
// dark launch would photograph the same screens. Seeded like journey ② (a member with a plan, a post and a crew).
// WRITTEN — UNVERIFIED (needs Mac + simulator).

import XCTest

@MainActor
final class Journey4_ScreensTests: XCTestCase {
    private let app = XCUIApplication()
    private let seed = SeedClient()

    override func setUp() async throws {
        continueAfterFailure = false
        dismissSystemPrompts() // JourneySteps.swift: a signed build shows system prompts (Save Password, permissions)
        let member = try await seed.register(name: "Screens")
        try await seed.putPlanForEveryDay(as: member)
        try await seed.logCardio(as: member) // A22: the first post is a workout post
        _ = try await seed.createCrew(as: member)
        app.launchArguments = ["-uiTest", "-seededReturningUser", "-AppleInterfaceStyle", "Dark"] // the phone says dark; Crew stays light (A21.10 amended)
        app.launchEnvironment["CREW_SEED_SESSION"] = member.json
        app.launch()
    }

    private func screenSays() -> String { app.staticTexts.allElementsBoundByIndex.prefix(4).map(\.label).joined(separator: " | ") }

    func testEveryTabOpensAndIsPhotographed() {
        XCTAssertTrue(app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Log workout'")).firstMatch.waitForExistence(timeout: 20), "never landed on Home — the screen says: \(screenSays())")
        shoot(app, "S07 Home")
        app.tabBars.buttons["Plan"].tap()
        XCTAssertTrue(app.navigationBars["Plan"].waitForExistence(timeout: 10), "Plan did not open")
        shoot(app, "S14 Plan")
        app.tabBars.buttons["Crew"].tap()
        XCTAssertTrue(app.navigationBars["Crew"].waitForExistence(timeout: 10), "Crew did not open")
        shoot(app, "S12 Crew")
        app.tabBars.buttons["Progress"].tap()
        XCTAssertTrue(app.navigationBars["Progress"].waitForExistence(timeout: 10), "Progress did not open")
        XCTAssertTrue(app.buttons["Charts"].exists && app.buttons["Journal"].exists, "A19.4: the Charts | Journal segment is missing")
        shoot(app, "S15 Progress charts")
        app.buttons["Journal"].tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH 'Your journal keeps everything'")).firstMatch.waitForExistence(timeout: 10), "the Journal segment did not show the journal — the screen says: \(screenSays())")
        shoot(app, "S16 Journal segment")
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10), "Settings did not open")
        XCTAssertTrue(app.staticTexts["Units"].waitForExistence(timeout: 5), "W6: the Units section is missing")
        shoot(app, "S17 Settings")
    }
}
