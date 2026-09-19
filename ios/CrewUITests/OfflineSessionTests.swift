// SPEC: 8.4 state probe "Resume-after-kill" · S07 (Resume banner when a session is open) · S09 ("survives kill"; every tap
// saves) · Flow 3 crash-proof ("Resume workout" survives anything) · E17 (an in-progress workout finishes on the device it
// started on). The airplane-mode half of 8.4/8.6 needs a phone (a simulator cannot drop its own network) and stays on the manual
// device checklist (OWNER-REVIEW §6). The member is built the journey ① way with EVERY day selected, so today is a workout day
// whatever the calendar says. WRITTEN — UNVERIFIED (needs Mac + simulator). T025 / T043

import XCTest

final class OfflineSessionTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        dismissSystemPrompts() // JourneySteps.swift: a signed build shows system prompts (Save Password, permissions)
        app.launchArguments = ["-uiTest", "-resetState"]
        app.launch()
    }

    func testACheckedSetSurvivesAKillAndHomeOffersResume() {
        XCTAssertTrue(app.staticTexts["One plan. Every week. Your crew sees you show up."].waitForExistence(timeout: 5))
        app.buttons["Build my week"].tap()
        XCTAssertTrue(app.staticTexts["3 days a week — solid."].waitForExistence(timeout: 15))
        for unselected in [1, 3, 5, 6] { app.dayToggle(unselected).tap() } // Mon/Wed/Fri are pre-selected; now all seven
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["How experienced are you?"].waitForExistence(timeout: 15))
        app.buttons["Brand new"].tap() // A21.1: the last question — this answer builds the plan
        XCTAssertTrue(app.staticTexts["Your week, built."].waitForExistence(timeout: 15))
        app.buttons["Looks good"].tap()

        XCTAssertTrue(app.staticTexts["Save your plan"].waitForExistence(timeout: 15))
        // A20.11 — ALL FIVE fields go through the synchronised step. Run 35069768536 lost keyboard focus at Password,
        // one field before Birth year, so the bare tap-then-type was never safe on any of them (JourneySteps).
        typeInto(app.textFields["Name"], "Kill Survivor", in: app)
        typeInto(app.textFields["Email"], "resume-\(Int(Date().timeIntervalSince1970))@example.com", in: app)
        typeInto(app.secureTextFields["Password"], "journey password 1", in: app)
        typeInto(app.textFields["Birth year"], "1994", in: app)
        saveThePlan(in: app) // A20.11: Done first — the save must not read Birth year mid-keystroke (JourneySteps)

        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Your season starts today'")).firstMatch.waitForExistence(timeout: 20)) // A28 (e): the first-day card's line
        let startFirst = app.buttons["Start your first workout"]
        XCTAssertTrue(startFirst.waitForExistence(timeout: 5), "every day is a training day, so the bridge CTA is the workout")
        startFirst.tap()

        // One tap logs set 1 at its pre-filled numbers — and that tap is saved before anything else happens (Flow 3)
        let firstSet = app.buttons.matching(NSPredicate(format: "label CONTAINS 'set 1 of'")).firstMatch
        XCTAssertTrue(firstSet.waitForExistence(timeout: 5))
        expectOnScreen(firstSet, in: app, "the first set row") // 6.7 (JourneySteps.swift)
        firstSet.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'set 1 of' AND label CONTAINS 'done'")).firstMatch.waitForExistence(timeout: 15))
        shoot(app, "S09 session — set 1 done, about to be killed")

        // The kill: no warning, no save button. A relaunch (signed in, nothing reset) must offer the open session back.
        app.terminate()
        app.launchArguments = ["-uiTest"]
        app.launch()
        // 1C / S01: the session outlives the kill because the Keychain holds it, not memory. An UNSIGNED simulator build cannot write
        // the Keychain at all (errSecMissingEntitlement, -34018) and wakes on the hero — run 34367618719 landed exactly there, so
        // the CI job signs simulator builds ad hoc. This assertion names that state instead of a missing banner.
        // The season line is deliberate and is the BRIDGE, not a stale constant: this member finished onboarding and checked one
        // set but never POSTED, and 1D holds the bridge until the first post exists — so this is the one state whose card says
        // "Your season starts today" (A28 (e)). Journey ② asserts the opposite for the same reason, and both are right. Do not
        // "align" them: if this ever starts failing, the member reached Home in some OTHER state, which is itself the bug worth seeing.
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Your season starts today'")).firstMatch.waitForExistence(timeout: 20), "signed out after a kill, or Home is no longer the bridge — the Keychain may not have kept the session; the screen says: \(app.staticTexts.allElementsBoundByIndex.prefix(3).map(\.label).joined(separator: " | "))")
        // A18.8 / A20.11 — THE BRIDGE ABSORBS AN OPEN SESSION (TodayCard.swift:24-26). Because this member never
        // posted, Home is the bridge, and §1D lets it carry ONE CTA: HomeScreen.swift:65 suppresses the Resume
        // BANNER with `!isBridge` and TodayCard.swift:110 turns the bridge's own button into "Resume your first
        // workout". Run 35073421853's hierarchy dump shows exactly that button — so the session was never lost and
        // this assertion's old message was accusing the app of a bug A18 had deliberately designed away. Matching on
        // "Resume" alone covers both shapes: the bridge's CTA here, and "Resume workout · <name>" once a post exists.
        let resume = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Resume'")).firstMatch
        XCTAssertTrue(resume.waitForExistence(timeout: 20), "the bridge offers no way back into the open session after a kill; Home says: \(app.staticTexts.allElementsBoundByIndex.prefix(3).map(\.label).joined(separator: " | "))")
        shoot(app, "S07 Home — the bridge resumes the open session after a kill")
        resume.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'set 1 of' AND label CONTAINS 'done'")).firstMatch.waitForExistence(timeout: 5), "the checked set did not survive the kill")
        XCTAssertTrue(app.buttons["Complete workout"].exists) // always visible (S09)
        shoot(app, "S09 session — resumed with set 1 still done")
    }
}
