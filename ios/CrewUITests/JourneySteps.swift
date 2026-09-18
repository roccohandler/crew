// The steps three journeys share (extracted on the third occurrence, C-doctrine: plain functions, no fixture layer) and the
// iOS twin of the web's expectNoHorizontalScroll (tests/e2e/helpers.ts).
// SPEC: 6.7 (nothing scrolls sideways; nothing sits past the edge) · 8.4 (the journeys are the record) · 8.9. Run 34360394481's
// accessibility dump showed the session's rows 484 pt wide and its Complete button 516 pt wide on a 402 pt window — a layout
// no screenshot of a passing test would have flagged, so the journeys now measure the elements they are about to use.
// WRITTEN — UNVERIFIED (needs Mac + simulator).
//
// TIMEOUT CONVENTION (2026-09-10, run 34542854485). A POSITIVE wait — `XCTAssertTrue(x.waitForExistence(timeout:))` —
// returns the moment the element appears, so a generous timeout costs a fast run NOTHING and is the only thing standing
// between a loaded runner and a false red. Sixteen of them sat at 2–3 s; the retired CameraDenied's wait for "Your week, built."
// blew one on a run where synthesizing a single tap took 10 s, and the suite was only 47% slower overall. They are 15 s.
// A NEGATIVE wait — `XCTAssertFalse(x.waitForExistence(timeout:))` — is the opposite: it burns its WHOLE timeout every
// time it passes, so those three stay at 2–3 s, and `share || done` stays too (a solo member waits out the first branch
// before the second is checked). Raise positives freely; never raise a negative.

import XCTest

extension XCUIApplication {
    // The seven day toggles carry their letter as the label (M T W T F S S), in Monday-first order (S03)
    func dayToggle(_ index: Int) -> XCUIElement {
        buttons.matching(NSPredicate(format: "label IN {'M', 'T', 'W', 'F', 'S'}")).element(boundBy: index)
    }
}

extension XCTestCase {
    // A signed build gets the system's prompts — Save Password, notifications, camera — which sit over the app until answered.
    // XCTest asks this monitor only when a tap is blocked; the answer is always the quiet one (Not Now / Don't Allow / OK).
    func dismissSystemPrompts() {
        addUIInterruptionMonitor(withDescription: "system prompt") { prompt in
            for label in ["Not Now", "Don't Allow", "OK", "Cancel", "Allow"] where prompt.buttons[label].exists {
                prompt.buttons[label].tap()
                return true
            }
            return false
        }
    }

    // SPEC: 8.4 · A20 (2026-09-11) — the third occurrence of "tap a field and type into it", extracted as a plain
    // function (C5). Journey ① and OfflineSession each walk S05's five fields.
    //
    // WHY IT IS NOT `field.tap(); field.typeText(…)`. Run 34590287373 failed those three tests on the identical
    // diagnostic at the identical field — "Failed to synthesize event: Neither element nor any descendant has keyboard
    // focus", on S05's `Birth year`. That field is the only `.numberPad` on the screen AND the last of five, so
    // reaching it makes iOS tear down the alphabetic keyboard and build a numeric one; A19.2 then added a
    // `ToolbarItemGroup(placement: .keyboard)` that animates in above it, and A19.1 added a `safeAreaInset` bottom bar
    // that lays out against the same edge. `typeText` synthesises against whatever is focused AT THAT INSTANT, so it
    // began racing an animation that A19 made longer. Nothing about the app is wrong; the step was never synchronised.
    //
    // Waiting for the DIGIT keyboard is what proves focus actually moved — `app.keyboards` stays up between two text
    // fields and so proves nothing, while a `1` key exists only once the numberPad is the first responder. Positive
    // waits cost a passing run nothing (the timeout convention above).
    func typeInto(_ field: XCUIElement, _ text: String, in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(field.waitForExistence(timeout: 15), "the field never appeared", file: file, line: line)
        field.tap()
        if text.allSatisfy(\.isNumber) && !app.keys["1"].waitForExistence(timeout: 5) {
            field.tap() // one retry: a tap that lands while the previous keyboard is still dismissing is swallowed
            XCTAssertTrue(app.keys["1"].waitForExistence(timeout: 10), "the numeric keyboard never came up", file: file, line: line)
        }
        // A20.11 (run 35069768536) — THE DIGIT WAIT ABOVE ONLY COVERS A NUMBERPAD, and the race was never numeric.
        // The same "Neither element nor any descendant has keyboard focus" failed `Password` on THREE journeys, one
        // field earlier than Birth year. The note above is right that `app.keyboards` proves nothing between two text
        // fields — but `hasKeyboardFocus` on the field ITSELF does, whatever keyboard it raises, and a SecureTextField
        // offers no key to wait for. So the general proof runs for every field and the digit wait stays for the
        // numberPad's extra teardown-and-rebuild.
        if !waitForKeyboardFocus(field, timeout: 5) {
            field.tap() // the same swallowed tap, on a field whose keyboard type gives no key worth waiting for
            XCTAssertTrue(waitForKeyboardFocus(field, timeout: 10), "the field never took keyboard focus", file: file, line: line)
        }
        field.typeText(text)
    }

    // The one probe that answers "is THIS element the first responder" rather than "is A keyboard up".
    func waitForKeyboardFocus(_ field: XCUIElement, timeout: TimeInterval) -> Bool {
        let focused = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hasKeyboardFocus == true"), object: field)
        return XCTWaiter().wait(for: [focused], timeout: timeout) == .completed
    }

    // SPEC: A19.2 · A20.11 (run 35073421853) — SAVE S05 THE WAY A PERSON DOES: dismiss the numberPad, then save.
    // The three journeys tapped "Save your plan" 0.34 s after `typeText` began on `Birth year`, and the save read the
    // binding before every digit had landed: the hierarchy dump shows the field holding `1994` beside the server's
    // "birthYear: Too small: expected number to be >=1900", which is what `Int("19")` earns. The app is right —
    // SaveAuthScreen:88 guards `let year = Int(birthYear) else { return }` and never sends a placeholder.
    // Tapping A19.2's Done bar resigns first responder, which COMMITS the field, and it is the flow that bar exists
    // for; it is also the only test anywhere that exercises it. Third occurrence, so it is a plain function (C5).
    func saveThePlan(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let done = app.buttons["Done"] // A19.2: present only while a numberPad/decimalPad is up
        if done.waitForExistence(timeout: 5) { done.tap() }
        let save = app.buttons["Save your plan"]
        XCTAssertTrue(save.waitForExistence(timeout: 15), "S05 never offered Save your plan", file: file, line: line)
        save.tap()
    }

    // 6.7: the element lies inside the window — not beside it, not clipped by the edge
    func expectOnScreen(_ element: XCUIElement, in app: XCUIApplication, _ what: String, file: StaticString = #filePath, line: UInt = #line) {
        let window = app.frame
        let frame = element.frame
        XCTAssertTrue(frame.minX >= window.minX && frame.maxX <= window.maxX, "\(what) sits past the edge: \(frame) in a \(window.width) pt window", file: file, line: line)
    }
}
