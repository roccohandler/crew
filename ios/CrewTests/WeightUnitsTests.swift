// SPEC: A9 (owner-directed 2026-09-09) — the conversion twin. Twin of web/tests/engine/weight-units.test.ts: identical
// cases, so the two engines print the same digit (8.1). Runs on the open-source toolchain (ios/Package.swift) and Xcode.

import XCTest
@testable import Crew

final class WeightUnitsTests: XCTestCase {
    func testAWeightIsUntouchedWhenTheUnitDoesNotChange() {
        // the number the user typed is never re-rounded by a no-op conversion
        XCTAssertEqual(WeightUnits.weightIn(137.5, from: "lb", to: "lb"), 137.5)
        XCTAssertEqual(WeightUnits.weightIn(102.3, from: "kg", to: "kg"), 102.3)
    }

    func testPoundsConvertToKilogramsAndSnapToTheQuarter() {
        XCTAssertEqual(WeightUnits.weightIn(225, from: "lb", to: "kg"), 102)      // 102.0582 → 102.00
        XCTAssertEqual(WeightUnits.weightIn(135, from: "lb", to: "kg"), 61.25)    // 61.2350 → 61.25
        XCTAssertEqual(WeightUnits.weightIn(45, from: "lb", to: "kg"), 20.5)      // 20.4116 → 20.50
    }

    func testKilogramsConvertToPoundsAndSnapToTheHalf() {
        XCTAssertEqual(WeightUnits.weightIn(100, from: "kg", to: "lb"), 220.5)    // 220.4623 → 220.5
        XCTAssertEqual(WeightUnits.weightIn(20, from: "kg", to: "lb"), 44)        // 44.0925 → 44.0
        XCTAssertEqual(WeightUnits.weightIn(60, from: "kg", to: "lb"), 132.5)     // 132.2774 → 132.5
    }

    func testARoundTripStaysWithinOneDisplayIncrement() {
        // the snap is lossy by design; what must hold is that a value never drifts away over a round trip
        for pounds in [45.0, 95, 135, 185, 225, 315, 405] {
            let back = WeightUnits.weightIn(WeightUnits.weightIn(pounds, from: "lb", to: "kg"), from: "kg", to: "lb")
            XCTAssertLessThanOrEqual(abs(back - pounds), 1 / Double(SpecConstants.weightDisplayScaleLb))
        }
    }

    func testTheBoundariesNeedNoSpecialCase() {
        XCTAssertEqual(WeightUnits.weightIn(0, from: "lb", to: "kg"), 0)
        XCTAssertEqual(WeightUnits.weightIn(Double(SpecConstants.setWeightMax), from: "lb", to: "kg"), 453.5) // 453.59237 → 453.50
    }

    func testEachUnitNamesItsLoadableIncrement() {
        XCTAssertEqual(WeightUnits.displayScale("lb"), SpecConstants.weightDisplayScaleLb)
        XCTAssertEqual(WeightUnits.displayScale("kg"), SpecConstants.weightDisplayScaleKg)
    }

    func testCompareNormalisationPutsBothUnitsOnTheKilogramScale() {
        XCTAssertEqual(WeightUnits.normalizedForCompare(100, unit: "kg"), 100)
        XCTAssertEqual(WeightUnits.normalizedForCompare(225, unit: "lb"), 102.05828325, accuracy: 0.000001)
    }

    func testCompareNormalisationDoesNotSnapSoARealRecordIsNeverHidden() {
        // 225 lb and 226 lb both snap to the same quarter for display; compared, they must still differ
        XCTAssertGreaterThan(WeightUnits.normalizedForCompare(226, unit: "lb"), WeightUnits.normalizedForCompare(225, unit: "lb"))
    }

    func testAHeavierPoundLiftOrdersAboveALighterKilogramLift() {
        // the defect this closes: before A9 a unit switch fired a false "new best" in one direction
        XCTAssertGreaterThan(WeightUnits.normalizedForCompare(225, unit: "lb"), WeightUnits.normalizedForCompare(100, unit: "kg"))
    }

    func testCompareNormalisationIsMonotonicWithinAUnit() {
        for unit in ["lb", "kg"] {
            XCTAssertLessThan(WeightUnits.normalizedForCompare(50, unit: unit), WeightUnits.normalizedForCompare(51, unit: unit))
        }
    }
}
