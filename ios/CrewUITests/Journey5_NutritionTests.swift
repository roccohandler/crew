// SPEC: 8.4 journey ⑤ (W064) · nutrition addendum §4, §6 (RATIFIED 2026-09-18) · A22 G4 — macro logging on the phone, end to end
// and BOTH WAYS through the server: the member's targets, saved meal and template are seeded through the API as another device
// would have left them, so what Today shows proves the PULL (NutritionHydrate); then one tap logs a slot, a quick add is added and
// deleted, the same tap undoes the slot — and the server is asked what it holds, which proves the QUEUE delivered the phone's ops
// (createMealLog · deleteMealLog). Then Saved meals & template, and a meal from a chain's own published numbers. The lines are read
// through the ONE sentence VoiceOver hears (MacroDay.spokenLine), so the test pins clause ②'s ink words too. And A16.c: a
// 15-year-old's Home has no "Log macros" row and Settings no Nutrition rows — with no copy about it. Every screen is photographed
// into the storyboard. WRITTEN — UNVERIFIED (needs Mac + simulator).

import XCTest

@MainActor
final class Journey5_NutritionTests: XCTestCase {
    private let app = XCUIApplication()
    private let seed = SeedClient()

    private func launch(_ member: SeedSession) {
        app.launchArguments = ["-uiTest", "-seededReturningUser"]
        app.launchEnvironment["CREW_SEED_SESSION"] = member.json
        app.launch()
    }

    // Anything on screen whose accessibility label starts with `text` — a macro line is one combined element, a row is a button
    private func labelled(_ text: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", text)).firstMatch
    }

    private func expectLine(_ sentence: String, _ why: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(labelled(sentence).waitForExistence(timeout: 20), "\(why) — expected \"\(sentence)\"; the screen says: \(app.staticTexts.allElementsBoundByIndex.prefix(6).map(\.label).joined(separator: " | "))", file: file, line: line)
    }

    // The 3 AM day in the device's zone (E8) — the day the server stamps on a log made now (E15)
    private func todayKey() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date().addingTimeInterval(-3 * 60 * 60))
    }

    // What the SERVER holds for today — asked directly, with the query string URLComponents builds (SeedClient.call encodes a path)
    private func serverLogNames(as member: SeedSession) async throws -> [String] {
        var components = URLComponents(url: seed.baseURL.appending(path: "nutrition/logs"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "dayKey", value: todayKey())]
        var request = URLRequest(url: components.url!)
        request.setValue("ios", forHTTPHeaderField: "X-Crew-Client")
        request.setValue("Bearer \(member.accessToken)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: request)
        let reply = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return ((reply?["items"] as? [[String: Any]]) ?? []).compactMap { $0["name"] as? String }
    }

    func testMacrosArePulledLoggedUndoneAndDelivered() async throws {
        continueAfterFailure = false
        dismissSystemPrompts()
        let member = try await seed.register(name: "Journey Five")
        try await seed.putPlanForEveryDay(as: member)
        try await seed.logCardio(as: member) // the log rows sit behind the first post (1D)
        try await seed.seedNutrition(as: member)
        launch(member)

        // A22 G4 as amended by A28 (d) — the quiet Macros fact row is the way in (Q3); nothing logged yet, so it reports nothing (A8)
        let row = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Macros'")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 20), "Home never showed the Macros row — the screen says: \(app.staticTexts.allElementsBoundByIndex.prefix(4).map(\.label).joined(separator: " | "))")
        XCTAssertEqual(row.label, "Macros, nothing logged yet")
        row.tap()

        // The pull: this phone wrote none of this — another device did (V58: 176 lb derives 145 · 385 · 60)
        expectLine("Protein: 0 / 145 g, 145 to go", "Today never showed the targets the server holds")
        expectLine("Calories: 0 / 2660 kcal, 2660 to go", "Q2: calories are the fourth line")
        let slot = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Breakfast · Oats and whey'")).firstMatch
        XCTAssertTrue(slot.waitForExistence(timeout: 20), "the template the server holds never reached Today")
        expectOnScreen(slot, in: app, "the template slot")
        shoot(app, "N1 Today — targets and template pulled")

        slot.tap() // ONE tap logs it
        expectLine("Protein: 30 / 145 g, 115 to go", "one tap on the slot did not log the meal")
        shoot(app, "N1 Today — a slot logged")

        // 6.9 (A25) — Today keeps ONE job. Quick add is a destination one tap away: two steps of protein, then Add — that screen's one
        // filled primary — and the phone is back on Today, where the lines have moved
        XCTAssertFalse(labelled("Increase Protein").exists, "6.9: the quick-add steppers are still stacked on Today")
        app.buttons["Quick add"].tap()
        let more = labelled("Increase Protein")
        XCTAssertTrue(more.waitForExistence(timeout: 15), "Quick add never opened")
        shoot(app, "N3 Quick add")
        more.tap()
        more.tap()
        app.buttons["Add"].tap()
        expectLine("Protein: 40 / 145 g, 105 to go", "the quick add did not count")
        // …and the day's log is the other destination, each entry with its visible Delete (6.3: never a swipe alone)
        let logged = app.buttons["Logged today, 2"] // R-090: a row button reads its name, then its value
        XCTAssertTrue(logged.waitForExistence(timeout: 15), "Today never offered the day's log")
        logged.tap()
        XCTAssertTrue(labelled("Delete Quick add").waitForExistence(timeout: 15), "the day's log never opened")
        shoot(app, "N4 Logged today")
        labelled("Delete Quick add").tap()
        app.navigationBars.buttons.element(boundBy: 0).tap() // back to Today
        expectLine("Protein: 30 / 145 g, 115 to go", "deleting the quick add did not take it off the day")

        // The queue: the server holds exactly the slot's log — createMealLog ×2 and deleteMealLog ×1 were delivered, in order
        var names: [String] = []
        for _ in 0..<20 {
            names = try await serverLogNames(as: member)
            if names == ["Oats and whey"] { break }
            try await Task.sleep(for: .seconds(1))
        }
        XCTAssertEqual(names, ["Oats and whey"], "the phone's nutrition ops never reached the server in order")

        slot.tap() // the same tap undoes it, in place
        expectLine("Protein: 0 / 145 g, 145 to go", "the same tap did not undo the slot")

        // Saved meals & template, and a meal copied from a chain's own published numbers
        app.buttons["Saved meals & template"].tap()
        XCTAssertTrue(labelled("Oats and whey").waitForExistence(timeout: 15), "the saved meal the server holds is not in the list")
        shoot(app, "N2 Saved meals — the list")
        app.buttons["Add from a chain"].tap()
        let chain = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Chipotle'")).firstMatch
        XCTAssertTrue(chain.waitForExistence(timeout: 15), "the chain list never opened")
        shoot(app, "N2 Add from a chain — chains")
        chain.tap()
        let item = app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Chicken, '")).firstMatch
        XCTAssertTrue(item.waitForExistence(timeout: 15), "the chain's items never opened")
        shoot(app, "N2 Add from a chain — items")
        item.tap()
        let save = app.buttons["Save meal"]
        XCTAssertTrue(save.waitForExistence(timeout: 15), "the picked item never reached the meal form")
        shoot(app, "N2 Meal form — a chain item's numbers, copied")
        save.tap()
        XCTAssertTrue(labelled("Edit Chicken").waitForExistence(timeout: 15), "the meal copied from the chain is not in the list")
        app.buttons["Template"].tap() // the segment's other half
        XCTAssertTrue(labelled("Move Oats and whey up").waitForExistence(timeout: 15), "the Template half never showed the slot")
        shoot(app, "N2 Template")
    }

    // A16.c · A22 G3 — under 18 the surface does not exist: no row, no Settings rows, and no copy about it
    func testUnder18ThereIsNoRowAndNoSettingsSection() async throws {
        continueAfterFailure = false
        dismissSystemPrompts()
        let minor = try await seed.register(name: "Journey Five Minor", birthYear: Calendar.current.component(.year, from: Date()) - 15)
        try await seed.putPlanForEveryDay(as: minor)
        try await seed.logCardio(as: minor)
        launch(minor)
        XCTAssertTrue(app.buttons["home.add"].waitForExistence(timeout: 20), "never landed on Home")
        XCTAssertFalse(app.buttons.containing(NSPredicate(format: "label BEGINSWITH 'Macros'")).firstMatch.exists, "A16.c: an under-18 Home shows the macros row")
        shoot(app, "S07 Home — under 18, no macros row")
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["Nutrition"].exists, "A16.c: an under-18 Settings shows the Nutrition row")
        XCTAssertFalse(app.buttons["Nutrition targets"].exists)
    }
}
