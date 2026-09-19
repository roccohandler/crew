// SPEC: Appendix A 2026-09-18 A24 (1)(2) — the steps every tour flow shares. A tour is NOT a journey: it asserts nothing. A step
// whose element never shows is photographed as it stands and the tour moves on, so a tooling flake can never turn master red and
// hold a TestFlight build; the evidence is the `ui-tour` artifact's CHANGES.md, which lists the screen as removed.
// Every shot is "NN_<tab>_<screen>_<state> — <action taken>": ios/scripts/storyboard.mjs writes the file as NN_<tab>_<screen>_<state>.png
// and the row into TOUR.md; ios/scripts/tour-diff.mjs compares it with design/baselines/.
// WRITTEN — UNVERIFIED (needs Mac + simulator).

import XCTest

extension XCTestCase {
    // The settle pause lets a sheet's spring and a push's slide finish — a shot taken mid-animation would differ on every run
    func tourShot(_ app: XCUIApplication, _ name: String, _ action: String) {
        Thread.sleep(forTimeInterval: 0.8)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = String(format: "%02d_%@ — %@", StoryboardStep.next(for: self.name), name, action)
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // A soft tap: true when the element showed up and took the tap. Never an assertion (A24 (2)).
    @discardableResult
    func tourTap(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        guard element.waitForExistence(timeout: timeout), element.isHittable else { return false }
        element.tap()
        return true
    }

    // Sheets come down by their own button when they have one, by the pull otherwise. The pull starts just below the middle of the
    // screen — on a half-height sheet that is its header, on a full one its content at rest, and both drag the sheet away.
    func tourDismissSheet(_ app: XCUIApplication, button: String? = nil) {
        // the swap sheets say Cancel now (A26 round), and so does the editor they open over: firstMatch never raises "multiple matches"
        if let button, tourTap(app.buttons[button].firstMatch, timeout: 3) { return }
        let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.55))
        from.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.99)))
    }

    // First tour run (35324724476): on iOS 26 a confirmationDialog is a POPOVER with no Cancel row, so "tap Cancel" left it up and
    // it swallowed every later tap in the flow. Second run (35327451545): a tap on the status bar does not reach the popover's
    // dismiss region either. A tap in the lower-middle of the window does — a popover eats the first outside tap, so nothing under it fires.
    // Run 35340692297: the lower-MIDDLE of the session logger is the weight tape, and the flow lost "Complete workout" right after
    // this tap — so the tap now lands in the canvas GUTTER at the left edge (every screen keeps 16 pt there, and a popover keeps its
    // own margin from the edge): outside the popover, and on nothing if it is ever delivered to the screen underneath.
    func tourDismissDialog(_ app: XCUIApplication) {
        let cancel = app.buttons["Cancel"]
        if cancel.waitForExistence(timeout: 2), cancel.isHittable { cancel.tap(); return }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.62)).tap()
        Thread.sleep(forTimeInterval: 0.6)
    }

    // A long list is scrolled a page at a time until the element exists (a List builds its rows lazily); never an assertion
    func tourScroll(_ app: XCUIApplication, until element: XCUIElement, down: Bool = false, pages: Int = 4) {
        for _ in 0..<pages where !(element.waitForExistence(timeout: 1) && element.isHittable) {
            if down { app.swipeDown() } else { app.swipeUp() }
        }
    }

    // A screen with a BOTTOM BAR (A19.1's safeAreaInset) reports a row under the bar as existing AND hittable, so `tourScroll` stops
    // too early there: run 35403203894 shot the reveal unscrolled and tapped "Open …" through the session's bar to no effect. This
    // one swipes up until the element's frame is clear of the bottom quarter of the screen, where those bars live; never an assertion
    func tourScrollClearOfBottomBar(_ app: XCUIApplication, until element: XCUIElement, pages: Int = 4) {
        let clearBelow = app.frame.height * 0.75
        for _ in 0..<pages where !(element.waitForExistence(timeout: 1) && element.frame.maxY <= clearBelow) {
            // a slow drag of 40% of the screen, not a flick (a flick's momentum can carry a short page's row past the TOP edge), and in
            // the canvas GUTTER: mid-screen on the logger is the weight tape, which takes a drag for itself
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.7)).press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.3)))
        }
    }

    // A pushed screen goes back by the navigation bar's first button; a sheet has none and takes the pull
    func tourBack(_ app: XCUIApplication) {
        let back = app.navigationBars.buttons.element(boundBy: 0)
        if back.exists && back.isHittable { back.tap() } else { app.swipeDown(velocity: .fast) }
    }

    // The signed-in launch the journeys use (CrewApp.seedReturningUser, Debug builds only)
    // A28 (a) — `dark` relaunches the same account with the phone in Midnight (-uiDark: CrewApp forces the scheme, Debug builds only)
    func tourLaunch(_ app: XCUIApplication, as session: SeedSession, dark: Bool = false) {
        dismissSystemPrompts()
        app.launchArguments = ["-uiTest", "-seededReturningUser"] + (dark ? ["-uiDark"] : [])
        app.launchEnvironment["CREW_SEED_SESSION"] = session.json
        app.launch()
    }

    // A seed that cannot be built SKIPS the flow — the tour reports, it never reds the run (A24 (2))
    func tourFilledMember(_ seed: SeedClient) async throws -> SeedSession {
        do { return try await seed.seedTourMember().member } catch { throw XCTSkip("the tour seed failed: \(error)") }
    }

    // A signed-in account with nothing in it: no plan, no post, no crew
    func tourEmptyMember(_ seed: SeedClient, _ name: String) async throws -> SeedSession {
        do { return try await seed.register(name: name) } catch { throw XCTSkip("the tour seed failed: \(error)") }
    }

    // Home has landed once its "+" is up (A28 (d): every Home state carries it) and the card has left the syncing line
    func tourWaitForHome(_ app: XCUIApplication) {
        _ = app.buttons["home.add"].waitForExistence(timeout: 25)
        _ = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Start' OR label BEGINSWITH 'Resume' OR label BEGINSWITH 'End the pause' OR label BEGINSWITH 'Build'")).firstMatch.waitForExistence(timeout: 5)
    }

    func tourButton(_ app: XCUIApplication, containing text: String) -> XCUIElement {
        app.buttons.containing(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    func tourButton(_ app: XCUIApplication, startingWith prefix: String) -> XCUIElement {
        app.buttons.containing(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }
}
