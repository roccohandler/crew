// SPEC: S07 (all five states) · 8.4 (the journeys are the record) · 8.9 (the snapshot matrix these shots are the first
// step toward) · A18 (J029 / J034) · A20 (2026-09-11, the fifth Home review).
//
// WHY THIS FILE EXISTS. The owner sent a photograph of Home and asked what was on it, and nothing in CI had ever
// rendered that screen with an assertion on it. Journey ② seeds a member who trains every day, so its Home is always a
// workout day; OfflineSessionTests asserts the bridge; CameraDeniedTests reaches a rest day and checks one absent
// string. The paused state — the one that contradicted its own copy for a whole release — had never been on screen.
//
// So this walks Home's four non-bridge states, asserts what A17.4, A18 and A20 promise each of them, and PHOTOGRAPHS
// each one into the run's xcresult. From a machine with no Mac, those artifacts are the only way to look at the app.
//
// A20.13 — AND IT PHOTOGRAPHS THE DARK APPEARANCE. Crew has shipped a full light+dark palette since 2026-09-04
// (EmberColors emits dynamic UIColors from the two hexes in design-tokens.json; project.yml is
// UIUserInterfaceStyle: Automatic) and NO test, e2e spec, layout gate, a11y sweep or CI screenshot on either engine
// had ever rendered a dark screen. Half the design system was unverified by construction, and the owner's own
// reference design for this pass was, in palette terms, the dark theme he already owned and had never seen.
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
    // NOTE WHAT THAT COSTS, because it invalidated an assertion for three releases: the meal lands TODAY, so every
    // state this file can reach has `posted == true`, and the unposted branch of any rest-day copy is unreachable here.
    // A20 is what makes that safe — the rest block states its premise on BOTH branches, so one assertion covers it.
    private func launchHome(trainingDayOffset: Int, name: String, paused: Bool = false, dark: Bool = false) async throws {
        continueAfterFailure = false
        dismissSystemPrompts()
        let member = try await seed.register(name: name)
        try await seed.putPlan(oneTrainingDayOffsetFromToday: trainingDayOffset, as: member)
        try await seed.postMeal(as: member)
        if paused { try await seed.pause(untilDaysFromNow: 7, as: member) }
        app.launchArguments = ["-uiTest", "-seededReturningUser"]
        // A20.13 — the documented way to force an appearance for a UI test without an in-app setting: the simulator
        // reads this the way it reads the system toggle, so the app's own dynamic colours resolve to their dark hexes.
        if dark { app.launchArguments += ["-AppleInterfaceStyle", "Dark"] }
        app.launchEnvironment["CREW_SEED_SESSION"] = member.json
        app.launch()
    }

    // A17.4(c) — the nav title NAMES THE STATE. This is the assertion that tells the tests apart, and the one that
    // would catch a regression to the constant "Today". A20.7 added a date line ABOVE it rather than in place of it.
    private func expectTitle(_ title: String) {
        XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 20), "expected Home's title to name the state (\(title)); the screen says: \(app.staticTexts.allElementsBoundByIndex.prefix(4).map(\.label).joined(separator: " | "))")
        XCTAssertFalse(app.staticTexts["Your first flame lights today."].exists, "the bridge is still on screen — the seeded post did not land")
    }

    // A20.1 / A20.2 — TODAY'S LOG: three rows, one grammar, in one order, on every non-bridge state. The verb is the
    // title (6.6, A18.5 reaffirmed) and the accessibility label is "<verb>, <status>", so BEGINSWITH matches the verb.
    private func expectLogRows() {
        XCTAssertTrue(app.staticTexts["TODAY'S LOG"].exists, "A20.1 — the log list lost its section label")
        for verb in ["Log workout", "Log cardio", "Log a meal"] {
            XCTAssertTrue(app.buttons.containing(NSPredicate(format: "label BEGINSWITH %@", verb)).firstMatch.exists, "the \(verb) row is missing — A20.1 puts all three on every non-bridge state")
        }
    }

    // THE SCREEN THE OWNER PHOTOGRAPHED.
    func testRestDayStatesItsPremiseAndOffersAllThreeVectors() async throws {
        try await launchHome(trainingDayOffset: 1, name: "Home Rest") // today trains nothing; tomorrow does
        expectTitle("Rest day")

        // A18.4, now UNCONDITIONAL (A20.1): the premise renders whether or not today has been posted, so the rule
        // survives being satisfied — and so CI can actually reach it. The old assertion demanded the unposted reward
        // line on a state that must post to exist, and had therefore never once passed.
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH 'Recovery is part of the plan'")).firstMatch.exists, "A18.4 — the rest day no longer states its premise")
        XCTAssertTrue(app.staticTexts["Today counts."].exists, "the posted branch no longer says what today was worth")
        // A17.1 — the sentence that names the strip's marks in place, kept inline under the strip (A20 ruling)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH 'This week:'")).firstMatch.exists)
        // A20.1 — the what's-next fact is the LAST row now, not a block above the card
        XCTAssertTrue(app.staticTexts["TOMORROW"].exists || app.staticTexts["NEXT WORKOUT"].exists, "A20.1 — the next-up row is missing from the tail of the page")
        // A17.3 / A18.9 — a day that asks nothing carries no filled primary, and A20.8 gives it no bar at all
        XCTAssertFalse(app.buttons["Start workout"].exists)
        expectLogRows()
        shoot(app, "S07 Home — rest day (the screen the owner photographed)")
    }

    func testWorkoutDayCarriesOneBottomAnchoredPrimaryAndTheDaysWorkOnRowOne() async throws {
        try await launchHome(trainingDayOffset: 0, name: "Home Workout")
        expectTitle("Push day")
        // A20.8 — the day's single ink-filled primary, out of the scroll and into the bar
        XCTAssertTrue(app.buttons["Start workout"].exists, "the day's single ink-filled primary")
        // A20.1 — the day's work is row one of the log, not a card above it. A8: it states the plan, never "0 of 15".
        let workoutRow = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Log workout'")).firstMatch
        XCTAssertTrue(workoutRow.exists)
        XCTAssertTrue(workoutRow.label.contains("Push day"), "row one names the day's workout — got \(workoutRow.label)")
        XCTAssertFalse(workoutRow.label.contains("0 of"), "A8 — an unstarted workout must never report a zero")
        // A20.3 — the ONE named exception: Quick complete is the row's trailing mark, not a separate button
        XCTAssertTrue(app.buttons["Quick complete"].exists, "S07 — the phone-free log is gone")
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
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH 'Push day · '")).firstMatch.waitForExistence(timeout: 10), "A18.9 — the all-done state reports nothing about the day it just closed")
        XCTAssertFalse(app.buttons["Start workout"].exists, "A17.3 / A20.8 — a finished day carries no primary and no bar")
        XCTAssertFalse(app.buttons["Quick complete"].exists, "S07 — Quick Complete is hidden once today counts")
        expectLogRows()
        shoot(app, "S07 Home — all done")
    }

    // The state that contradicted its own copy for a whole release, and that no test had ever rendered. It is also the
    // state that proves A20.10: the pause is seeded through the REAL API, so it can only reach this screen if
    // ServerHydrate pulls it — which it did not until 2026-09-12, and this assertion is what said so.
    func testPausedFreezesTheReportAndOffersTheWayOut() async throws {
        try await launchHome(trainingDayOffset: 0, name: "Home Paused", paused: true)
        expectTitle("Plan paused")
        // A18.6c — the one control the paused state was missing, in the wording Settings already uses, now in the bar
        XCTAssertTrue(app.buttons["End the pause now"].exists, "A18.6c — a paused user still has no route off the pause that any word on this screen names")
        // A18.6d / J021 — nothing on a frozen plan offers planned work
        XCTAssertFalse(app.buttons["Quick complete"].exists, "A18.6d — a frozen plan is offering planned-day credit again")
        XCTAssertFalse(app.buttons["Start workout"].exists)
        // A18.6a — and the header no longer states a penalty the card denies
        XCTAssertFalse(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'missed'")).firstMatch.exists, "A18.6a — the week strip is reporting misses inside a pause window again")
        expectLogRows()
        shoot(app, "S07 Home — plan paused")
    }

    // SPEC: A20.13 — THE FIRST TIME ANY TEST ON EITHER ENGINE RENDERS THE DARK APPEARANCE. It asserts the same
    // structural contract as the light rest day, so the shot is not merely decorative: if a colour token resolves to
    // something unreadable the assertions still pass, but the artifact is there to be LOOKED at, which is the whole
    // point — this half of Part III has been shipping unseen since 2026-09-04.
    func testTheRestDayRendersInTheDarkAppearanceToo() async throws {
        try await launchHome(trainingDayOffset: 1, name: "Home Rest Dark", dark: true)
        expectTitle("Rest day")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH 'Recovery is part of the plan'")).firstMatch.exists)
        expectLogRows()
        shoot(app, "S07 Home — rest day, DARK appearance (A20.13)")
    }

    func testTheWorkoutDayRendersInTheDarkAppearanceToo() async throws {
        try await launchHome(trainingDayOffset: 0, name: "Home Workout Dark", dark: true)
        expectTitle("Push day")
        XCTAssertTrue(app.buttons["Start workout"].exists)
        expectLogRows()
        shoot(app, "S07 Home — workout day, DARK appearance (A20.13)")
    }
}
