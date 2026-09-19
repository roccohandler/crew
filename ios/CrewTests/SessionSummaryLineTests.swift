// SPEC: A6 (owner-directed 2026-09-08) as amended by A28 (c) (2026-09-19) — "Push day · 12 of 12 sets" (no minutes: nothing shows the
// time a workout took) · "Walk · 25 min · 2.1 km" (a cardio log's ENTERED minutes stand, GAP 4 in A28); A2 distance in meters, shown
// at one decimal in the poster's distanceUnit (A9). Twin of web/tests/engine/session-summary-line.test.ts: identical cases.
// Runs on the open-source toolchain (ios/Package.swift) and under Xcode.

import XCTest
@testable import Crew

final class SessionSummaryLineTests: XCTestCase {
    func testAStrengthSessionReadsItsSetsAndNothingOfTheClock() {
        XCTAssertEqual(SessionSummaryLine.sessionSummaryLine(workoutName: "Push day", isCardio: false, setsDone: 12, setsPlanned: 12, cardioMinutes: nil, distanceMeters: nil, distanceUnit: "km"), "Push day · 12 of 12 sets")
        XCTAssertEqual(SessionSummaryLine.sessionSummaryLine(workoutName: "Leg day", isCardio: false, setsDone: 1, setsPlanned: 15, cardioMinutes: nil, distanceMeters: nil, distanceUnit: "mi"), "Leg day · 1 of 15 sets")
    }

    func testACardioLogReadsItsEnteredMinutesAndTheDistanceInThePostersUnits() {
        XCTAssertEqual(SessionSummaryLine.sessionSummaryLine(workoutName: "Walk", isCardio: true, setsDone: 1, setsPlanned: 1, cardioMinutes: 25, distanceMeters: 2100, distanceUnit: "km"), "Walk · 25 min · 2.1 km")
        XCTAssertEqual(SessionSummaryLine.sessionSummaryLine(workoutName: "Walk", isCardio: true, setsDone: 1, setsPlanned: 1, cardioMinutes: 25, distanceMeters: 2100, distanceUnit: "mi"), "Walk · 25 min · 1.3 mi")
        XCTAssertEqual(SessionSummaryLine.sessionSummaryLine(workoutName: "Run", isCardio: true, setsDone: 1, setsPlanned: 1, cardioMinutes: 30, distanceMeters: nil, distanceUnit: "mi"), "Run · 30 min")
        // A28 (c): no logged minutes no longer falls back to the session's clock
        XCTAssertEqual(SessionSummaryLine.sessionSummaryLine(workoutName: "Bike", isCardio: true, setsDone: 1, setsPlanned: 1, cardioMinutes: nil, distanceMeters: nil, distanceUnit: "km"), "Bike")
        XCTAssertEqual(SessionSummaryLine.sessionSummaryLine(workoutName: "Bike", isCardio: true, setsDone: 1, setsPlanned: 1, cardioMinutes: nil, distanceMeters: 5000, distanceUnit: "km"), "Bike · 5.0 km")
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

    // SPEC: A28 (c) · R-086 — a summary stored before A28 reads without the workout's minutes; everything else reads as stored
    func testAStoredSummaryReadsWithoutTheWorkoutsMinutes() {
        XCTAssertEqual(SessionSummaryLine.withoutWorkoutMinutes("Push day · 12/12 sets · 44 min"), "Push day · 12 of 12 sets")
        XCTAssertEqual(SessionSummaryLine.withoutWorkoutMinutes("Push day · 12 of 12 sets"), "Push day · 12 of 12 sets")
        XCTAssertEqual(SessionSummaryLine.withoutWorkoutMinutes("Walk · 25 min · 2.1 km"), "Walk · 25 min · 2.1 km")
        XCTAssertEqual(SessionSummaryLine.withoutWorkoutMinutes("Walk · 25 min"), "Walk · 25 min")
        XCTAssertEqual(SessionSummaryLine.withoutWorkoutMinutes("Leg day · 3/x sets · 9 min"), "Leg day · 3/x sets · 9 min")
    }
}
