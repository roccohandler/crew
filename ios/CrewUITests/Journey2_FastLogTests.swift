// SPEC: 8.4 journey ② — returning user → fast-log → crew reaction received · S07 (≤3 taps launch→fast-logged; Quick Complete
// hidden once today counts) · Flow 6 (the reaction lands on the poster's own card) · T035 (Phase 3 gate). The returning member,
// their plan, first post, crew and crew-mate are seeded through the API by SeedClient against the local server; the app
// launches signed in (-seededReturningUser + CREW_SEED_SESSION) and hydrates its Store the way a reinstalled phone does.
// WRITTEN — UNVERIFIED (needs Mac + simulator).

import XCTest

@MainActor
final class Journey2_FastLogTests: XCTestCase {
    private let app = XCUIApplication()
    private let seed = SeedClient()
    private var mate: SeedSession!
    private var crewId = ""

    override func setUp() async throws {
        continueAfterFailure = false
        dismissSystemPrompts() // JourneySteps.swift: a signed build shows system prompts (Save Password, permissions)
        let member = try await seed.register(name: "Journey Two")
        try await seed.putPlanForEveryDay(as: member)
        try await seed.postMeal(as: member)
        let crew = try await seed.createCrew(as: member)
        crewId = crew.id
        mate = try await seed.register(name: "Sam")
        try await seed.join(token: crew.token, as: mate)
        app.launchArguments = ["-uiTest", "-seededReturningUser"]
        app.launchEnvironment["CREW_SEED_SESSION"] = member.json
        app.launch()
    }

    func testReturningUserFastLogsInThreeTapsAndSeesAReaction() async throws {
        // Warm start lands on Home — no splash, no bridge (the first post exists, 1D), today's card ready (S01, S07).
        // A17.4 made the title NAME THE STATE ("Push", "Rest day", "Done for today"); only the bridge still says "Today".
        // This member has posted and trains every day, so waiting for a navigation bar called "Today" waited for a screen
        // this state can never show — run 34540455856, and the ONE thing red in it. What marks a warm start on a
        // non-bridge Home is A3's camera toolbar button, which no other screen in the app carries; the title is then
        // asserted for what it must NOT be, so a regression back to the constant is still caught here.
        let postAMeal = app.buttons["Post a meal"]
        XCTAssertTrue(postAMeal.waitForExistence(timeout: 10), "never landed on Home — the screen says: \(app.staticTexts.allElementsBoundByIndex.prefix(3).map(\.label).joined(separator: " | "))")
        XCTAssertFalse(app.navigationBars["Today"].exists, "Home's title is the constant 'Today' again — A17.4 makes it name the state on every non-bridge day")
        XCTAssertFalse(app.staticTexts["Your first flame lights today."].exists)
        shoot(app, "S07 Home — a returning member")
        // Tap 1: Quick complete (visible only while today does not count yet)
        let quick = app.buttons["Quick complete"]
        XCTAssertTrue(quick.waitForExistence(timeout: 5))
        quick.tap()
        // Tap 2: the celebration's single CTA (share default remembered; a solo member would see Done)
        let share = app.buttons["Share to crew"]
        let done = app.buttons["Done"]
        XCTAssertTrue(share.waitForExistence(timeout: 5) || done.waitForExistence(timeout: 1))
        shoot(app, "S10 celebration — quick complete")
        (share.exists ? share : done).tap()
        // Quick Complete is hidden once today counts
        XCTAssertFalse(app.buttons["Quick complete"].waitForExistence(timeout: 2))
        // The crew-mate sees the workout drop into the stream (the phone's queue sent it) and reacts
        try await seed.reactToTheWorkoutPost(crewId: crewId, emoji: "💪", as: mate)
        // Tap 3: Crew tab — the card is in the stream and the reaction shows within a poll (Part IV: 5–10 s)
        app.tabBars.buttons["Crew"].tap()
        XCTAssertTrue(labelled("Workout ✓").waitForExistence(timeout: 10))
        XCTAssertTrue(labelled("💪 1").waitForExistence(timeout: 15))
        shoot(app, "S12 crew — the reaction received")
    }

    // A card combines its children into one accessibility element (PostCard); match on the label wherever it lives
    private func labelled(_ text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }
}
