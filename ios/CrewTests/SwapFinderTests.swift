// SPEC: T020 · 8.3 SwapFinder: candidates share pattern + equipment, never return the incumbent · Flow 1 step 4 (3–5).
// Twin of web/tests/engine/swap-finder.test.ts. WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

final class SwapFinderTests: XCTestCase {
    private let seed = SeedCatalog.shared

    func testEveryTemplatedExerciseHasThreeToFiveSameJobAlternatives() {
        for (_, byLevel) in seed.planTemplates.templates {
            for (experience, byAccess) in byLevel {
                for (access, ids) in byAccess {
                    for id in ids {
                        let incumbent = seed.exercise(id)!
                        let candidates = SwapFinder.swapCandidates(for: incumbent, access: access, experience: experience, seed: seed)
                        XCTAssertGreaterThanOrEqual(candidates.count, SpecConstants.swapCandidatesMin, "\(id) / \(access)")
                        XCTAssertLessThanOrEqual(candidates.count, SpecConstants.swapCandidatesMax)
                        for candidate in candidates {
                            XCTAssertNotEqual(candidate.id, incumbent.id)
                            XCTAssertEqual(candidate.type, incumbent.type)
                            XCTAssertTrue(seed.equipmentAccess[access]!.contains(candidate.equipment))
                            XCTAssertEqual(seed.regionOfPattern[candidate.pattern], seed.regionOfPattern[incumbent.pattern])
                        }
                    }
                }
            }
        }
    }

    func testRankingPrefersSameGroupAndFittingLevel() {
        let bench = seed.exercise("barbell-bench-press")!
        let candidates = SwapFinder.swapCandidates(for: bench, access: "fullGym", experience: "brandNew", seed: seed)
        XCTAssertTrue(candidates.allSatisfy { $0.swapGroup == "chestPress" })
        XCTAssertEqual(candidates.first?.level, "brandNew")
    }
}
