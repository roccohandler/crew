// SPEC: 8.4 journey ① — fresh install → questions → plan → save/auth → first workout incl. mobility hold → post → celebration ·
// T028 (Phase 2 gate). Runs against the local server (web: `node tests/e2e/dev-server.mjs` — in-memory Mongo + next dev on :3000,
// the harness Playwright uses); every run registers a fresh account, so the server needs no special-casing.
// WRITTEN — UNVERIFIED (needs Mac + simulator).

import XCTest

final class Journey1_NewUserTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        dismissSystemPrompts() // JourneySteps.swift: a signed build shows system prompts (Save Password, permissions)
        app.launchArguments = ["-uiTest", "-resetState"]
        app.launch()
    }

    func testFreshInstallToFirstPostAndCelebration() {
        // S02 hero: three CTAs on one screen, no carousel
        XCTAssertTrue(app.staticTexts["One plan. Every week. Your crew sees you show up."].waitForExistence(timeout: 5))
        shoot(app, "S02 hero")
        app.buttons["Build my week"].tap()

        // S03 days: Mon/Wed/Fri pre-selected, the encouragement line reads live
        XCTAssertTrue(app.staticTexts["3 days a week — solid."].waitForExistence(timeout: 15))
        shoot(app, "S03 days")
        // Every day trains, so today is a workout day whatever the calendar says and the journey always logs a set (the
        // rest-day bridge offers a bonus workout instead — A22 / R-070). Until 2026-09-09 this ran Mon/Wed/Fri and took a different branch
        // each weekday — the set row's defect (run 34360394481) hid behind a Tuesday.
        for unselected in [1, 3, 5, 6] { app.dayToggle(unselected).tap() }
        app.buttons["Continue"].tap()

        // single-selects auto-advance; A21.1: two questions — the experience answer is the last one and builds the plan
        XCTAssertTrue(app.staticTexts["How experienced are you?"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["2 of 2"].exists, "the whisper counts two questions (A21.1)")
        app.buttons["Brand new"].tap()

        // S04 reveal
        XCTAssertTrue(app.staticTexts["Your week, built."].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Tap any exercise to swap it."].exists)
        shoot(app, "S04 the week, built")
        app.buttons["Looks good"].tap()

        // S05 save with email (Sign in with Apple needs a device)
        XCTAssertTrue(app.staticTexts["Save your plan"].waitForExistence(timeout: 15))
        shoot(app, "S05 save your plan")
        // A20.11 — ALL FIVE fields go through the synchronised step. Run 35069768536 lost keyboard focus at Password,
        // one field before Birth year, so the bare tap-then-type was never safe on any of them (JourneySteps).
        typeInto(app.textFields["Name"], "Journey One", in: app)
        typeInto(app.textFields["Email"], "journey1-\(Int(Date().timeIntervalSince1970))@example.com", in: app)
        typeInto(app.secureTextFields["Password"], "journey password 1", in: app)
        typeInto(app.textFields["Birth year"], "1994", in: app)
        saveThePlan(in: app) // A20.11: Done first — the save must not read Birth year mid-keystroke (JourneySteps)

        // S07 bridge state on Home as A28 (d) draws it: no reward block, one card, one CTA (the wait covers a cold dev server hashing
        // the first password)
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Your season starts today'")).firstMatch.waitForExistence(timeout: 20), "Home never showed the bridge — the save screen says: \(app.staticTexts.allElementsBoundByIndex.map(\.label).joined(separator: " | "))")
        shoot(app, "S07 Home — the bridge")
        let startFirst = app.buttons["Start your first workout"]
        let bonus = app.buttons["Start a bonus workout"] // A22 / R-070: the rest-day bridge's one control
        XCTAssertTrue(startFirst.exists || bonus.exists)
        XCTAssertTrue(startFirst.exists, "the plan trains every day, so the bridge must offer the first workout, not the bonus")
        if startFirst.exists {
            startFirst.tap()
            // S09: check the first set, run one hold, complete
            let firstSet = app.buttons.matching(NSPredicate(format: "label CONTAINS 'set 1 of'")).firstMatch
            XCTAssertTrue(firstSet.waitForExistence(timeout: 5))
            // 6.7: the row, its Skip and the Complete button all lie inside the window (the iOS overflow check, JourneySteps.swift)
            expectOnScreen(firstSet, in: app, "the first set row")
            // A20.11 — A19 (cb84202) gave this button a REAL VoiceOver name, `Skip \(exercise.name)`
            // (SessionScreen.swift:115), so `app.buttons["Skip"]` matched the bare title before A19 and matches
            // nothing after it. The app is right — E20 wants a control that says what it skips — and the query was
            // stale; it had simply never run, the last executed ios job (334ad67) predating A19 by a day.
            // The rest timer's "Skip the rest timer" is excluded: it is a different control on a different surface.
            let firstSkip = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Skip ' AND NOT (label CONTAINS 'rest timer')")).firstMatch
            XCTAssertTrue(firstSkip.waitForExistence(timeout: 5), "the session offered no Skip for its first exercise")
            expectOnScreen(firstSkip, in: app, "the first Skip")
            expectOnScreen(app.buttons["Complete workout"], in: app, "Complete workout")
            firstSet.tap()
            shoot(app, "S09 session")
            app.buttons["Complete workout"].tap()
            // S10 celebration: XP counts in, then Done (A21.9: a solo user's one button — the post follows the tap)
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH '+'")).firstMatch.waitForExistence(timeout: 5))
            shoot(app, "S10 celebration")
            app.buttons["Done"].tap()
            // A21.4 / W4 — after the FIRST completed workout, once: the reminder opt-in (7:30 pre-filled, G12); Not now is remembered (E5)
            let notNow = app.buttons["Not now"]
            XCTAssertTrue(notNow.waitForExistence(timeout: 10), "the reminder opt-in never followed the first celebration (A21.4) — the screen says: \(app.staticTexts.allElementsBoundByIndex.prefix(4).map(\.label).joined(separator: " | "))")
            XCTAssertTrue(app.staticTexts["Get a nudge on workout days?"].exists)
            shoot(app, "1D reminder opt-in")
            notNow.tap()
        }
        // Back on Home the bridge is gone forever; the reward block (the lit flame) takes its place
        XCTAssertFalse(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Your season starts today'")).firstMatch.waitForExistence(timeout: 2))
        shoot(app, "S07 Home — the flame lit")
    }
}
