// The steps three journeys share (extracted on the third occurrence, C-doctrine: plain functions, no fixture layer) and the
// iOS twin of the web's expectNoHorizontalScroll (tests/e2e/helpers.ts).
// SPEC: 6.7 (nothing scrolls sideways; nothing sits past the edge) · 8.4 (the journeys are the record) · 8.9. Run 34360394481's
// accessibility dump showed the session's rows 484 pt wide and its Complete button 516 pt wide on a 402 pt window — a layout
// no screenshot of a passing test would have flagged, so the journeys now measure the elements they are about to use.
// WRITTEN — UNVERIFIED (needs Mac + simulator).
//
// TIMEOUT CONVENTION (2026-09-10, run 34542854485). A POSITIVE wait — `XCTAssertTrue(x.waitForExistence(timeout:))` —
// returns the moment the element appears, so a generous timeout costs a fast run NOTHING and is the only thing standing
// between a loaded runner and a false red. Sixteen of them sat at 2–3 s; CameraDenied's wait for "Your week, built."
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

    // 6.7: the element lies inside the window — not beside it, not clipped by the edge
    func expectOnScreen(_ element: XCUIElement, in app: XCUIApplication, _ what: String, file: StaticString = #filePath, line: UInt = #line) {
        let window = app.frame
        let frame = element.frame
        XCTAssertTrue(frame.minX >= window.minX && frame.maxX <= window.maxX, "\(what) sits past the edge: \(frame) in a \(window.width) pt window", file: file, line: line)
    }
}
