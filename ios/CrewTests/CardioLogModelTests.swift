// SPEC: A2 (owner-directed 2026-09-08) as A28 (d) draws it — the Home cardio log's minutes move in cardioMinutesStep steps and a
// typed number is clamped to the bounds (an invalid value is unreachable, not rejected); the distance numeral is a dash until a
// readable distance is typed, because the distance is optional. In-memory Store (C4). WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

@MainActor
final class CardioLogModelTests: XCTestCase {
    private func model() -> CardioLogModel {
        CardioLogModel(store: Store(inMemory: true), userId: "cardio-user", distanceUnit: "km", timeZone: TimeZone(identifier: "America/Los_Angeles")!)
    }

    func testMinutesStepAndClampToTheBounds() {
        let model = model()
        model.setMinutes(SpecConstants.cardioMinutesMin)
        model.stepMinutes(by: 1)
        XCTAssertEqual(model.minutes, SpecConstants.cardioMinutesMin + SpecConstants.cardioMinutesStep)
        model.stepMinutes(by: -1)
        model.stepMinutes(by: -1)
        XCTAssertEqual(model.minutes, SpecConstants.cardioMinutesMin)
        model.setMinutes(SpecConstants.cardioMinutesMax + 1)
        XCTAssertEqual(model.minutes, SpecConstants.cardioMinutesMax)
        model.setMinutes(0)
        XCTAssertEqual(model.minutes, SpecConstants.cardioMinutesMin)
    }

    func testTheDistanceIsADashUntilOneIsTyped() {
        let model = model()
        XCTAssertEqual(model.distanceValue, "—")
        XCTAssertNil(model.distanceMeters)
        model.distanceText = "2.5"
        XCTAssertEqual(model.distanceValue, "2.5")
        XCTAssertNotNil(model.distanceMeters)
        model.distanceText = "abc"
        XCTAssertEqual(model.distanceValue, "—")
    }
}
