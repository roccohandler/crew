// SPEC: A28 (a) (owner-approved 2026-09-19: light is the default, dark is supported and reviewed like light — amending A21.10's
// "light always") · W6. No machine here can look at a screen, so this journey PHOTOGRAPHS every tab for the owner's review in the
// xcresult (CrewUITests/Screenshots.swift) and asserts only what a screenshot cannot: each tab opens, Progress's Charts and Journal rows
// are there (A19.4 as A28 (f) redraws it) and the Journal opens, the W6 Units section exists. Its dark half is back: the phone is put in Midnight (-uiDark, Debug
// builds only) and every tab is photographed there. Seeded like journey ② (a member with a plan, a post and a crew).
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
        app.launchArguments = ["-uiTest", "-seededReturningUser", "-uiDark"] // A28 (a): dark is supported again — every tab photographed in Midnight
        app.launchEnvironment["CREW_SEED_SESSION"] = member.json
        app.launch()
    }

    private func screenSays() -> String { app.staticTexts.allElementsBoundByIndex.prefix(4).map(\.label).joined(separator: " | ") }

    func testEveryTabOpensAndIsPhotographed() {
        XCTAssertTrue(app.buttons["home.add"].waitForExistence(timeout: 20), "never landed on Home — the screen says: \(screenSays())")
        shoot(app, "S07 Home")
        app.tabBars.buttons["Plan"].tap()
        XCTAssertTrue(app.buttons["Change days"].waitForExistence(timeout: 10), "Plan did not open, or lost its Change days row") // R-087: the title is the page's own
        shoot(app, "S14 Plan")
        app.tabBars.buttons["Crew"].tap()
        XCTAssertTrue(app.staticTexts["Crew"].waitForExistence(timeout: 10), "Crew did not open") // R-092: the title is the page's own, no bar
        shoot(app, "S12 Crew")
        app.tabBars.buttons["Progress"].tap()
        // A28 (d) · R-086: Progress is the data screen (its own title, no bar); Charts and the Journal are its two row buttons
        XCTAssertTrue(app.buttons["Charts"].waitForExistence(timeout: 10), "Progress did not open, or lost its Charts row")
        XCTAssertTrue(app.buttons["Journal"].exists, "A19.4: the Journal is no longer one tap from the tab")
        shoot(app, "S15 Progress")
        app.buttons["Journal"].tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH 'Your journal keeps everything'")).firstMatch.waitForExistence(timeout: 10), "the Journal row did not open the journal — the screen says: \(screenSays())")
        shoot(app, "S16 Journal")
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: 10), "Settings did not open")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Units'")).firstMatch.waitForExistence(timeout: 5), "W6 · R-089: the Units row is missing")
        // A23 — a whisper shows ONCE, under the element it explains, and the first tap anywhere on the screen clears it for good
        let pauseWhisper = app.staticTexts["Away a while? Pause the plan. The streak stays whole."]
        XCTAssertTrue(pauseWhisper.waitForExistence(timeout: 15), "A23: the pause whisper never showed under Pause my plan — the screen says: \(screenSays())")
        shoot(app, "S17 Settings — the pause whisper, once")
        app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Version'")).firstMatch.tap() // a tap on a line that opens nothing
        XCTAssertFalse(pauseWhisper.waitForExistence(timeout: 2), "A23 rule 4: the first tap anywhere did not clear the whisper")
        shoot(app, "S17 Settings")
        // A23 · S19 — the page behind the whispers, a row above Version; the note from Max is the owner's, ratified (R-081)
        let howItWorks = app.buttons["How Crew works"]
        // About is the LAST section of a list that is three pages long since W8 (run 35340692297: one swipe stopped at Account), and a
        // List builds its rows lazily — so scroll until the row exists, a page at a time. EXISTING is not enough (run 35400020876): a
        // List also builds rows just past the screen's edge, so after one swipe the row "existed" UNDER the tab bar, the tap landed on
        // the Settings tab instead (the dump shows the list scrolled back to its top — the tab's scroll-to-top) and S19 never opened.
        // So scroll until the whole row sits above the tab bar.
        let tabBarTop = app.tabBars.firstMatch.frame.minY
        for _ in 0..<6 where !(howItWorks.waitForExistence(timeout: 2) && howItWorks.frame.maxY <= tabBarTop) { app.swipeUp() }
        XCTAssertTrue(howItWorks.waitForExistence(timeout: 15), "A23: Settings → About has no How Crew works row — the screen says: \(screenSays())")
        XCTAssertLessThanOrEqual(howItWorks.frame.maxY, tabBarTop, "the How Crew works row never cleared the tab bar — the screen says: \(screenSays())")
        howItWorks.tap()
        XCTAssertTrue(app.navigationBars["How Crew works"].waitForExistence(timeout: 15), "S19 did not open")
        // A23 ratified 2026-09-19 (R-081): the page prints the owner's own words from the generated copy, and says "Draft" nowhere
        let ratifiedNote = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "everything in here is what I do myself")).firstMatch
        XCTAssertTrue(ratifiedNote.waitForExistence(timeout: 5), "S19 does not print the ratified note from Max — the screen says: \(screenSays())")
        XCTAssertFalse(app.staticTexts["Draft"].exists, "the note from Max is ratified: no Draft label")
        shoot(app, "S19 How Crew works")
    }
}
