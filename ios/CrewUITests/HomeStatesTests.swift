// SPEC: S07 (all five states) · 8.4 (the journeys are the record) · 8.9 (the snapshot matrix these shots are the first
// step toward) · A18 (J029 / J034).
//
// WHY THIS FILE EXISTS. The owner sent a photograph of Home's REST DAY and asked four questions about it, and nothing
// in CI had ever rendered that screen with an assertion on it. Journey ② seeds a member who trains every day, so its
// Home is always a workout day; OfflineSessionTests asserts the bridge; CameraDeniedTests reaches a rest day and then
// only checks that one string is absent. The paused state — the one that contradicted its own copy for a whole
// release — had never been on screen in any test, on either engine.
//
// So this walks Home's four non-bridge states, asserts what A17.4 and A18 promise each of them, and PHOTOGRAPHS each
// one into the run's xcresult. From a machine with no Mac, those artifacts are the only way to look at the app; the
// assertions are what makes a regression go red rather than merely look wrong to whoever opens the bundle.
//
// Each state gets its own account, seeded through the real API against the local harness (SeedClient), with a plan
// whose single training day is positioned RELATIVE TO TODAY — so a state is deterministic on whatever day CI runs.
// WRITTEN — UNVERIFIED (needs Mac + simulator).

import XCTest

@MainActor
final class HomeStatesTests: XCTestCase {
    private let app = XCUIApplication()
    private let seed = SeedClient()

    // Every state below needs the bridge gone (§1D: it survives until the first POST exists), so every seed posts once.
    private func launchHome(trainingDayOffset: Int, name: String, paused: Bool = false) async throws {
        continueAfterFailure = false
        dismissSystemPrompts()
        let member = try await seed.register(name: name)
        try await seed.putPlan(oneTrainingDayOffsetFromToday: trainingDayOffset, as: member)
        try await seed.postMeal(as: member)
        if paused { try await seed.pause(untilDaysFromNow: 7, as: member) }
        app.launchArguments = ["-uiTest", "-seededReturningUser"]
        app.launchEnvironment["CREW_SEED_SESSION"] = member.json
        app.launch()
    }

    // A17.4 — the nav title NAMES THE STATE. This is the assertion that tells the four tests apart, and the one that
    // would catch a regression to the constant "Today" that A17.4 removed.
    private func expectTitle(_ title: String) {
        XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 20), "expected Home's title to name the state (\(title)); the screen says: \(app.staticTexts.allElementsBoundByIndex.prefix(4).map(\.label).joined(separator: " | "))")
        XCTAssertFalse(app.staticTexts["Your first flame lights today."].exists, "the bridge is still on screen — the seeded post did not land")
    }

    // A18.5 — the three logging vectors, verb-first, on every non-bridge state. The owner called their predecessors
    // "three strange divs"; a noun title over a value is a stat readout, and 6.6 requires a verb.
    private func expectLogRows() {
        for verb in ["Log workout", "Log cardio", "Log a meal"] {
            XCTAssertTrue(app.buttons.containing(NSPredicate(format: "label BEGINSWITH %@", verb)).firstMatch.exists, "the \(verb) row is missing — A18.5 puts all three on every non-bridge state")
        }
    }

    // THE SCREEN THE OWNER PHOTOGRAPHED.
    func testRestDayNamesItsNumbersAndStatesThePremise() async throws {
        try await launchHome(trainingDayOffset: 1, name: "Home Rest") // today trains nothing; tomorrow does
        expectTitle("Rest day")

        // A18.1 — the two bare numerals are named where they sit. The ring is NOT asserted here: A18.2 renders it only
        // once the week holds a completed workout, and this member has posted a meal rather than trained.
        XCTAssertTrue(app.staticTexts["day streak"].exists, "A18.1 — the flame's numeral is unnamed again")
        // A17.1 — the sentence that names the strip's colours in place
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH 'This week:'")).firstMatch.exists)
        // A18.4 — the card states the PREMISE, not only the reward: why a rest day asks for anything at all
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH 'Rest days count too'")).firstMatch.exists, "A18.4 — the rest card is back to stating only its reward")
        // A18.3 — the what's-next fact is its own block above the card, not the card's quietest caption
        XCTAssertTrue(app.staticTexts["TOMORROW"].exists || app.staticTexts["NEXT WORKOUT"].exists, "A18.3 — the next-up block is missing from the space it was added to fill")
        // A18.10 — and the toolbar camera is gone, because the card already asks for a meal
        XCTAssertFalse(app.buttons["Post a meal"].exists && app.navigationBars["Rest day"].buttons["Post a meal"].exists, "A18.10 — the nav glyph is a third route to a destination the card already offers")
        expectLogRows()
        shoot(app, "S07 Home — rest day (the screen the owner photographed)")
    }

    func testWorkoutDayShowsTheDaysWorkAndItsSinglePrimary() async throws {
        try await launchHome(trainingDayOffset: 0, name: "Home Workout")
        expectTitle("Push day")
        XCTAssertTrue(app.buttons["Start workout"].exists, "the day's single ink-filled primary")
        XCTAssertTrue(app.staticTexts["Push-Up"].exists, "A14 — the card lists the day's actual work, not a count of it")
        // A18.3 — no next-up block on a training day: the card already IS what is next, and this is the tallest state
        XCTAssertFalse(app.staticTexts["TOMORROW"].exists)
        expectLogRows()
        shoot(app, "S07 Home — workout day")
    }

    func testAllDoneReportsTheDayAndAsksForNothing() async throws {
        try await launchHome(trainingDayOffset: 0, name: "Home Done")
        expectTitle("Push day")
        app.buttons["Quick complete"].tap()
        // the celebration, then back to Home (S10)
        let done = app.buttons["Done"]
        let share = app.buttons["Share to crew"]
        XCTAssertTrue(share.waitForExistence(timeout: 10) || done.waitForExistence(timeout: 2))
        (share.exists ? share : done).tap()

        expectTitle("Done for today")
        // A18.9 — the day, reported in the journal's own sentence, and no control: the day is closed
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH 'Push day · '")).firstMatch.waitForExistence(timeout: 10), "A18.9 — the all-done card reports nothing about the day it just closed")
        expectLogRows()
        shoot(app, "S07 Home — all done")
    }

    // The state that contradicted its own copy for a whole release, and that no test had ever rendered.
    func testPausedFreezesTheReportAndOffersTheWayOut() async throws {
        try await launchHome(trainingDayOffset: 0, name: "Home Paused", paused: true)
        expectTitle("Plan paused")
        // A18.6c — the one control the paused card was missing, in the wording Settings already uses
        XCTAssertTrue(app.buttons["End the pause now"].exists, "A18.6c — a paused user still has no route off the pause that any word on this screen names")
        // A18.6d / J021 — nothing on a frozen plan offers planned work
        XCTAssertFalse(app.buttons["Quick complete"].exists, "A18.6d — a frozen plan is offering planned-day credit again")
        // A18.6a — and the header no longer states a penalty the card denies
        XCTAssertFalse(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'missed'")).firstMatch.exists, "A18.6a — the week strip is reporting misses inside a pause window again")
        shoot(app, "S07 Home — plan paused")
    }
}
