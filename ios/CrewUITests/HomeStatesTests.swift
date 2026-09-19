// SPEC: S07 as amended by A28 (d), (e) (owner-approved 2026-09-19; design/targets 03–06) · 8.4 (the journeys are the record) ·
// 8.9 (the snapshot matrix these shots are the first step toward) · A22 G1 (a) (a rest day asks nothing).
//
// WHY THIS FILE EXISTS. The owner sent a photograph of Home's REST DAY and asked four questions about it, and nothing in CI had
// ever rendered that screen with an assertion on it. So this walks Home's four non-bridge states, asserts what the Focus Card
// promises each of them, and PHOTOGRAPHS each one into the run's xcresult. The assertions are what makes a regression go red
// rather than merely look wrong to whoever opens the bundle.
//
// A28 (d) moved the state's name from the nav bar into the card (the card's header is one VoiceOver passage, so it is read with
// CONTAINS), put cardio and the bonus workout behind the "+", and left one filled primary on a card that has one.
//
// Each state gets its own account, seeded through the real API against the local harness (SeedClient), with a plan whose single
// training day is positioned RELATIVE TO TODAY — so a state is deterministic on whatever day CI runs.
// WRITTEN — UNVERIFIED (needs Mac + simulator).

import XCTest

@MainActor
final class HomeStatesTests: XCTestCase {
    private let app = XCUIApplication()
    private let seed = SeedClient()

    // Every state below needs the bridge gone (§1D: it survives until the first POST exists), so every seed posts once. A22: the
    // post is a standalone cardio log (A2), which never fills the planned slot, so today's state is judged as it would be with no
    // seed at all.
    private func launchHome(trainingDayOffset: Int, name: String, paused: Bool = false) async throws {
        continueAfterFailure = false
        dismissSystemPrompts()
        let member = try await seed.register(name: name)
        try await seed.putPlan(oneTrainingDayOffsetFromToday: trainingDayOffset, as: member)
        try await seed.logCardio(as: member)
        if paused { try await seed.pause(untilDaysFromNow: 7, as: member) }
        app.launchArguments = ["-uiTest", "-seededReturningUser"]
        app.launchEnvironment["CREW_SEED_SESSION"] = member.json
        app.launch()
        XCTAssertTrue(app.buttons["home.add"].waitForExistence(timeout: 20), "never landed on Home")
    }

    private func element(containing text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    // A28 (d) — the card's title NAMES THE STATE (the nav bar carries only the "+"), and the bridge's line is gone for good
    private func expectCard(_ title: String) {
        XCTAssertTrue(element(containing: title).waitForExistence(timeout: 20), "expected Home's card to name the state (\(title)); the screen says: \(app.staticTexts.allElementsBoundByIndex.prefix(4).map(\.label).joined(separator: " | "))")
        XCTAssertFalse(element(containing: "Your season starts today").exists, "the bridge is still on screen — the seeded post did not land")
    }

    // A28 (d) — no verb rows on Home any more: cardio and the bonus workout live behind the "+", and no meal control survived A22
    private func expectNoVerbRows() {
        XCTAssertFalse(app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Log workout'")).firstMatch.exists, "A28 (d) — a verb row is back on Home")
        XCTAssertFalse(app.buttons.containing(NSPredicate(format: "label CONTAINS 'meal'")).firstMatch.exists, "A22 — a meal control survived the plate journal's removal")
    }

    // THE SCREEN THE OWNER PHOTOGRAPHED.
    func testRestDayAsksNothing() async throws {
        try await launchHome(trainingDayOffset: 1, name: "Home Rest") // today trains nothing; tomorrow does
        expectCard("Rest day")
        // A28 (e) — the settled rest-day line; A22 G1 (a) — no control, no stake
        XCTAssertTrue(element(containing: "Rest is part of the season. Nothing to do today.").exists, "A28 (e) — the rest card lost its settled line")
        XCTAssertFalse(app.buttons["Start workout"].exists, "a rest day's card carries no filled button")
        // A28 (d) — tomorrow sits INSIDE the card now (was A18.3's block above it)
        XCTAssertTrue(element(containing: "Tomorrow").exists, "the card no longer carries tomorrow")
        expectNoVerbRows()
        XCTAssertTrue(app.buttons["home.add"].label.contains("bonus"), "A28 (d) — a rest day's + offers the bonus workout")
        shoot(app, "S07 Home — rest day (the screen the owner photographed)")
    }

    func testWorkoutDayShowsTheDaysWorkAndItsSinglePrimary() async throws {
        try await launchHome(trainingDayOffset: 0, name: "Home Workout")
        expectCard("Push day")
        XCTAssertTrue(app.buttons["Start workout"].exists, "the day's single ink-filled primary")
        XCTAssertTrue(element(containing: "Push-Up").exists, "A14 — the card lists the day's actual work, not a count of it")
        XCTAssertTrue(app.buttons["Quick complete"].exists, "A28 (d) — Quick complete, as text, under a training day's card")
        XCTAssertFalse(element(containing: "Tomorrow").exists, "a training day's card IS what is next")
        expectNoVerbRows()
        shoot(app, "S07 Home — workout day")
    }

    func testAllDoneReportsTheDayAndAsksForNothing() async throws {
        try await launchHome(trainingDayOffset: 0, name: "Home Done")
        expectCard("Push day")
        app.buttons["Quick complete"].tap()
        // the celebration, then back to Home (S10)
        let done = app.buttons["Done"]
        let share = app.buttons["Share to crew"]
        XCTAssertTrue(share.waitForExistence(timeout: 10) || done.waitForExistence(timeout: 2))
        (share.exists ? share : done).tap()
        let notNow = app.buttons["Not now"] // A21.4: the first completed workout's reminder opt-in follows the celebration, once
        if notNow.waitForExistence(timeout: 5) { notNow.tap() }

        expectCard("Done for today")
        // A18.1 — the planned workout counted the day (V67), so the flame's numeral is named where it sits
        XCTAssertTrue(element(containing: "Streak ").waitForExistence(timeout: 10), "A18.1 — the reward block lost the flame")
        // A18.9 · A28 (c) — the day, reported in the journal's own sentence and without the clock
        XCTAssertTrue(element(containing: "Push day · ").waitForExistence(timeout: 10), "A18.9 — the done card reports nothing about the day it just closed")
        XCTAssertTrue(app.buttons["Edit today's log"].exists, "A28 (d) — the done card's text button")
        XCTAssertFalse(app.buttons["Start workout"].exists, "a done day's card carries no filled button")
        expectNoVerbRows()
        shoot(app, "S07 Home — all done")
    }

    // The state that contradicted its own copy for a whole release. It is also the state that proves A20.10: the pause is seeded
    // through the REAL API, so it can only reach this screen if ServerHydrate pulls it.
    func testPausedIsOffSeasonAndOffersTheWayOut() async throws {
        try await launchHome(trainingDayOffset: 0, name: "Home Paused", paused: true)
        expectCard("Plan paused")
        // A28 (e) — off-season, in the settled words, with the one filled way out (mockup 06)
        XCTAssertTrue(element(containing: "Off-season until ").exists, "A28 (e) — the off-season line is missing")
        XCTAssertTrue(app.buttons["End the pause"].exists, "A18.6c / A28 (e) — a paused user has no route off the pause")
        // A18.6d / J021 — nothing on a frozen plan offers planned work
        XCTAssertFalse(app.buttons["Quick complete"].exists, "A18.6d — a frozen plan is offering planned-day credit again")
        XCTAssertFalse(element(containing: "missed").exists, "A18.6a — Home reports a miss inside a pause window again")
        shoot(app, "S07 Home — off-season")
    }
}
