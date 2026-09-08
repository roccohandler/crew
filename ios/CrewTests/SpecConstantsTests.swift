// SPEC: C7 (every spec number lives in the Generated file) · T007 scaffold test — proves the generated
// constants compile and carry the spec's values. WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

final class SpecConstantsTests: XCTestCase {
    func testGeneratedConstantsCarryTheSpecValues() {
        XCTAssertEqual(SpecConstants.dayBoundaryHour, 3)          // SPEC: E8
        XCTAssertEqual(SpecConstants.maxShields, 2)               // SPEC: Flow 7
        XCTAssertEqual(SpecConstants.xpPlannedWorkout, 100)       // SPEC: Part IV table
        XCTAssertEqual(SpecConstants.crewMaxMembers, 10)          // SPEC: Flow 6
        XCTAssertEqual(SpecConstants.reactionEmojis.count, 5)     // SPEC: Flow 6
    }

    func testSeedDataDecodesAsJSON() throws {
        for json in [SeedData.exercisesJSON, SeedData.planTemplatesJSON, SeedData.achievementsJSON] {
            let data = try XCTUnwrap(json.data(using: .utf8))
            XCTAssertNoThrow(try JSONSerialization.jsonObject(with: data))
        }
    }
}
