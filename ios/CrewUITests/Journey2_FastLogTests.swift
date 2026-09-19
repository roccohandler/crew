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
        try await seed.logCardio(as: member) // A22: the first post is a workout post — a walk, which leaves today's planned slot open
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
        // A28 (d) — the Focus Card Home draws no nav title (the card's title names the state) and every state carries the "+";
        // this member has posted and trains every day, so the card offers today's workout and the bridge's line is gone for good.
        XCTAssertTrue(app.buttons["home.add"].waitForExistence(timeout: 10), "never landed on Home — the screen says: \(app.staticTexts.allElementsBoundByIndex.prefix(3).map(\.label).joined(separator: " | "))")
        XCTAssertTrue(app.buttons["Start workout"].waitForExistence(timeout: 10), "the training day's card has lost its one primary")
        XCTAssertFalse(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Your season starts today'")).firstMatch.exists)
        shoot(app, "S07 Home — a returning member")
        // Tap 1: Quick complete (visible only while today does not count yet)
        let quick = app.buttons["Quick complete"]
        XCTAssertTrue(quick.waitForExistence(timeout: 5))
        quick.tap()
        // Tap 2: the celebration's TWO buttons (A19.3 / A21.9) — this member has a crew, so "Share to crew" and "Keep it private";
        // no post exists before one is tapped
        let share = app.buttons["Share to crew"]
        XCTAssertTrue(share.waitForExistence(timeout: 5), "the celebration never showed its share button — the screen says: \(app.staticTexts.allElementsBoundByIndex.prefix(4).map(\.label).joined(separator: " | "))")
        XCTAssertTrue(app.buttons["Keep it private"].exists, "A21.9: the second button")
        shoot(app, "S10 celebration — quick complete")
        share.tap()
        // A21.4 — the seed logged a walk, so this is the member's FIRST completed WORKOUT and the reminder opt-in may follow, once
        let notNow = app.buttons["Not now"]
        if notNow.waitForExistence(timeout: 5) { notNow.tap() }
        // Quick Complete is hidden once today counts
        XCTAssertFalse(app.buttons["Quick complete"].waitForExistence(timeout: 2))
        // The crew-mate sees the workout drop into the stream (the phone's queue sent it) and reacts
        try await seed.reactToTheWorkoutPost(crewId: crewId, emoji: "💪", as: mate)
        // Tap 3: Crew tab — the card is in the stream and the reaction shows within a poll (Part IV: 5–10 s)
        app.tabBars.buttons["Crew"].tap()
        // A28 · R5 (R-088): the card says what was done in its summary line ("Push day · 0 of 15 sets"), not "Workout ✓"; only a
        // strength post's line counts sets, so this finds the quick-completed workout and not the seeded walk
        XCTAssertTrue(labelled(" sets").waitForExistence(timeout: 10), "the workout card never reached the stream — the screen says: \(app.staticTexts.allElementsBoundByIndex.prefix(6).map(\.label).joined(separator: " | "))")
        XCTAssertTrue(labelled("💪 1").waitForExistence(timeout: 15))
        shoot(app, "S12 crew — the reaction received")
    }

    // A card combines its children into one accessibility element (PostCard); match on the label wherever it lives
    private func labelled(_ text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }
}
