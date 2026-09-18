// SPEC: 8.4 journey ③ on iOS — A21.3 / W4 (owner-approved 2026-09-17): a friend's crew, its invite CODE pasted on the hero's
// "I have an invite" → the crew's preview line → the two questions (A21.1) → the reveal → the email save → the phone lands INSIDE
// the crew (the Crew tab selected, the "joined the crew" system line in the stream) → the 1C photo prompt, once. The captain and the
// crew ("Night Shift 🌙") are seeded through the real API (SeedClient). WRITTEN — UNVERIFIED (needs Mac + simulator).

import XCTest

@MainActor
final class Journey3_InviteCodeTests: XCTestCase {
    private let app = XCUIApplication()
    private let seed = SeedClient()
    private var token = ""

    override func setUp() async throws {
        continueAfterFailure = false
        dismissSystemPrompts() // JourneySteps.swift: a signed build shows system prompts (Save Password, permissions)
        let captain = try await seed.register(name: "Captain Three")
        try await seed.putPlanForEveryDay(as: captain)
        token = try await seed.createCrew(as: captain).token
        app.launchArguments = ["-uiTest", "-resetState"]
        app.launch()
    }

    func testAPastedCodeLandsInsideTheCrew() {
        // S02 hero → the code screen (A21.3: the second CTA asks for the code first)
        XCTAssertTrue(app.staticTexts["One plan. Every week. Your crew sees you show up."].waitForExistence(timeout: 5))
        app.buttons["I have an invite"].tap()
        let field = app.textFields["Invite code"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "no invite-code field — the screen says: \(app.staticTexts.allElementsBoundByIndex.prefix(4).map(\.label).joined(separator: " | "))")
        typeInto(field, token, in: app) // typed, not pasted: the simulator's pasteboard is not the test's
        app.buttons["Find my crew"].tap()
        // S13: the public preview names the crew and its count
        let preview = app.staticTexts["invitePreview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 15), "no crew preview for the pasted code — the field holds \"\(field.value as? String ?? "?")\", the seed's token is \"\(token)\"; the screen says: \(app.staticTexts.allElementsBoundByIndex.prefix(4).map(\.label).joined(separator: " | "))")
        XCTAssertTrue(preview.label.hasPrefix("Night Shift 🌙 · 1 of "), preview.label)
        shoot(app, "S13 invite code — the preview")
        app.buttons["Continue"].tap()

        // the same two questions (A21.1), the reveal, the save
        XCTAssertTrue(app.staticTexts["3 days a week — solid."].waitForExistence(timeout: 15))
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["How experienced are you?"].waitForExistence(timeout: 15))
        app.buttons["Some"].tap()
        XCTAssertTrue(app.staticTexts["Your week, built."].waitForExistence(timeout: 15))
        app.buttons["Looks good"].tap()
        XCTAssertTrue(app.staticTexts["Save your plan"].waitForExistence(timeout: 15))
        typeInto(app.textFields["Name"], "Journey Three", in: app)
        typeInto(app.textFields["Email"], "journey3-\(Int(Date().timeIntervalSince1970))@example.com", in: app)
        typeInto(app.secureTextFields["Password"], "journey password 3", in: app)
        typeInto(app.textFields["Birth year"], "1996", in: app)
        saveThePlan(in: app) // A20.11: Done first — the save must not read Birth year mid-keystroke (JourneySteps)

        // A21.3: lands INSIDE the crew — the Crew tab is the one selected and the stream carries the join line (within a poll, Part IV)
        let joined = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "Journey Three joined the crew")).firstMatch
        XCTAssertTrue(joined.waitForExistence(timeout: 30), "did not land in the crew — the screen says: \(app.staticTexts.allElementsBoundByIndex.prefix(5).map(\.label).joined(separator: " | "))")
        XCTAssertTrue(app.tabBars.buttons["Crew"].isSelected, "the tab bar did not open on Crew (A21.3)")
        shoot(app, "S12 crew — landed by code")

        // 1C: the photo prompt, once; Not now is remembered
        let notNow = app.buttons["Not now"]
        XCTAssertTrue(notNow.waitForExistence(timeout: 10), "the photo prompt never appeared at the first join (1C)")
        XCTAssertTrue(app.staticTexts["Add a photo so your crew knows it's you."].exists)
        shoot(app, "1C photo prompt")
        notNow.tap()
        XCTAssertFalse(app.buttons["Not now"].waitForExistence(timeout: 2))
    }
}
