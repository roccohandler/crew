// The steps three journeys share (extracted on the third occurrence, C-doctrine: plain functions, no fixture layer) and the
// iOS twin of the web's expectNoHorizontalScroll (tests/e2e/helpers.ts).
// SPEC: 6.7 (nothing scrolls sideways; nothing sits past the edge) · 8.4 (the journeys are the record) · 8.9. Run 34360394481's
// accessibility dump showed the session's rows 484 pt wide and its Complete button 516 pt wide on a 402 pt window — a layout
// no screenshot of a passing test would have flagged, so the journeys now measure the elements they are about to use.
// WRITTEN — UNVERIFIED (needs Mac + simulator).

import XCTest

extension XCUIApplication {
    // The seven day toggles carry their letter as the label (M T W T F S S), in Monday-first order (S03)
    func dayToggle(_ index: Int) -> XCUIElement {
        buttons.matching(NSPredicate(format: "label IN {'M', 'T', 'W', 'F', 'S'}")).element(boundBy: index)
    }
}

extension XCTestCase {
    // 6.7: the element lies inside the window — not beside it, not clipped by the edge
    func expectOnScreen(_ element: XCUIElement, in app: XCUIApplication, _ what: String, file: StaticString = #filePath, line: UInt = #line) {
        let window = app.frame
        let frame = element.frame
        XCTAssertTrue(frame.minX >= window.minX && frame.maxX <= window.maxX, "\(what) sits past the edge: \(frame) in a \(window.width) pt window", file: file, line: line)
    }
}
