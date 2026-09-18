// SPEC: T020 · 8.3 SwapFinder: candidates share the job (same type; tiers swapGroup → pattern → region), never return the
// incumbent · Flow 1 step 4 (3–5) · A21.1 (owner-approved 2026-09-17): no equipment tier — the pool is the whole gym catalog.
// Twin of web/tests/engine/swap-finder.test.ts. WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

final class SwapFinderTests: XCTestCase {
    private let seed = SeedCatalog.shared
    private let equipmentTags: Set<String> = ["barbell", "dumbbell", "machine", "cable", "bodyweight"]

    func testEveryTemplatedExerciseHasThreeToFiveSameJobAlternatives() {
        for (_, byLevel) in seed.planTemplates.templates {
            for (experience, ids) in byLevel {
                for id in ids {
                    let incumbent = seed.exercise(id)!
                    let candidates = SwapFinder.swapCandidates(for: incumbent, experience: experience, seed: seed)
                    XCTAssertGreaterThanOrEqual(candidates.count, SpecConstants.swapCandidatesMin, "\(id) / \(experience)")
                    XCTAssertLessThanOrEqual(candidates.count, SpecConstants.swapCandidatesMax)
                    for candidate in candidates {
                        XCTAssertNotEqual(candidate.id, incumbent.id)
                        XCTAssertEqual(candidate.type, incumbent.type)
                        XCTAssertTrue(equipmentTags.contains(candidate.equipment))
                        XCTAssertEqual(seed.regionOfPattern[candidate.pattern], seed.regionOfPattern[incumbent.pattern])
                    }
                }
            }
        }
    }

    func testRankingPrefersSameGroupAndFittingLevel() {
        let bench = seed.exercise("barbell-bench-press")!
        let candidates = SwapFinder.swapCandidates(for: bench, experience: "brandNew", seed: seed)
        XCTAssertTrue(candidates.allSatisfy { $0.swapGroup == "chestPress" })
        XCTAssertEqual(candidates.first?.level, "brandNew")
    }
}
