// SPEC: A6 (owner-directed 2026-09-08) — "Push day · 12/12 sets · 44 min" · "Walk · 25 min · 2.1 km"; A2 distance in
// meters, shown at one decimal in the poster's distanceUnit (A9). Twin of web/tests/engine/session-summary-line.test.ts: identical cases.
// Runs on the open-source toolchain (ios/Package.swift) and under Xcode.

import XCTest
@testable import Crew

final class SessionSummaryLineTests: XCTestCase {
    func testAStrengthSessionReadsSetsAndWallClockMinutes() {
        XCTAssertEqual(SessionSummaryLine.sessionSummaryLine(workoutName: "Push day", isCardio: false, setsDone: 12, setsPlanned: 12, minutes: 44, cardioMinutes: nil, distanceMeters: nil, distanceUnit: "km"), "Push day · 12/12 sets · 44 min")
        XCTAssertEqual(SessionSummaryLine.sessionSummaryLine(workoutName: "Leg day", isCardio: false, setsDone: 1, setsPlanned: 15, minutes: 3, cardioMinutes: nil, distanceMeters: nil, distanceUnit: "mi"), "Leg day · 1/15 sets · 3 min")
    }

    func testACardioLogReadsItsMinutesAndTheDistanceInThePostersUnits() {
        XCTAssertEqual(SessionSummaryLine.sessionSummaryLine(workoutName: "Walk", isCardio: true, setsDone: 1, setsPlanned: 1, minutes: 0, cardioMinutes: 25, distanceMeters: 2100, distanceUnit: "km"), "Walk · 25 min · 2.1 km")
        XCTAssertEqual(SessionSummaryLine.sessionSummaryLine(workoutName: "Walk", isCardio: true, setsDone: 1, setsPlanned: 1, minutes: 0, cardioMinutes: 25, distanceMeters: 2100, distanceUnit: "mi"), "Walk · 25 min · 1.3 mi")
        XCTAssertEqual(SessionSummaryLine.sessionSummaryLine(workoutName: "Run", isCardio: true, setsDone: 1, setsPlanned: 1, minutes: 0, cardioMinutes: 30, distanceMeters: nil, distanceUnit: "mi"), "Run · 30 min")
        XCTAssertEqual(SessionSummaryLine.sessionSummaryLine(workoutName: "Bike", isCardio: true, setsDone: 1, setsPlanned: 1, minutes: 12, cardioMinutes: nil, distanceMeters: nil, distanceUnit: "km"), "Bike · 12 min") // no logged minutes → the session's own
    }

    func testDistanceRoundsHalfUpToTenthsIdenticallyOnBothEngines() {
        XCTAssertEqual(SessionSummaryLine.distanceText(distanceMeters: 2250, distanceUnit: "km"), "2.3 km") // an exact half
        XCTAssertEqual(SessionSummaryLine.distanceText(distanceMeters: 2249, distanceUnit: "km"), "2.2 km")
        XCTAssertEqual(SessionSummaryLine.distanceText(distanceMeters: 1000, distanceUnit: "km"), "1.0 km")
        XCTAssertEqual(SessionSummaryLine.distanceText(distanceMeters: 0, distanceUnit: "km"), "0.0 km")
        XCTAssertEqual(SessionSummaryLine.distanceText(distanceMeters: 950, distanceUnit: "km"), "1.0 km")
        XCTAssertEqual(SessionSummaryLine.distanceText(distanceMeters: 1609, distanceUnit: "mi"), "1.0 mi")
        XCTAssertEqual(SessionSummaryLine.distanceText(distanceMeters: 16093, distanceUnit: "mi"), "10.0 mi")
        XCTAssertEqual(SessionSummaryLine.distanceText(distanceMeters: 100000, distanceUnit: "mi"), "62.1 mi")
    }
}
