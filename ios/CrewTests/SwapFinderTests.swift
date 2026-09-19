// SPEC: T020 · 8.3 SwapFinder: candidates share the job (same type; tiers swapGroup → pattern → region), never return the
// incumbent · Flow 1 step 4 (3–5) · A21.1 (owner-approved 2026-09-17): no equipment tier — the pool is the whole gym catalog
// · A26 (owner-approved 2026-09-18): three flat template lists; every swap the owner NAMED is offered at every experience.
// Twin of web/tests/engine/swap-finder.test.ts. WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

final class SwapFinderTests: XCTestCase {
    private let seed = SeedCatalog.shared
    private let equipmentTags: Set<String> = ["barbell", "dumbbell", "machine", "cable", "bodyweight"]
    private let experiences = ["brandNew", "some", "experienced"]

    func testEverySwapTheOwnerNamedIsOfferedAtEveryExperience() {
        XCTAssertFalse(seed.planTemplates.namedSwaps.isEmpty)
        for (rowId, named) in seed.planTemplates.namedSwaps {
            for experience in experiences {
                let offered = SwapFinder.swapCandidates(for: seed.exercise(rowId)!, experience: experience, seed: seed).map(\.id)
                for id in named { XCTAssertTrue(offered.contains(id), "\(rowId) / \(experience): \(id) is not offered") }
                // ui-reviewer, run 35405384572: the flat bench's dumbbell swap ranked FIFTH for a brand-new lifter (level "some" sorts
                // behind the level gate) — under the fold of the half-height sheet. The owner's FIRST named swap leads the list.
                let lead = offered.firstIndex(of: named[0]) ?? offered.count
                XCTAssertLessThan(lead, SpecConstants.swapCandidatesMin, "\(rowId) / \(experience): \(named[0]) is not near the top")
            }
        }
        XCTAssertEqual(Set(seed.equipmentSymbol.keys), equipmentTags) // A26: one SF Symbol per equipment tag, in one place
    }

    func testEveryTemplatedExerciseHasThreeToFiveSameJobAlternatives() {
        for (_, ids) in seed.planTemplates.templates {
            for experience in experiences {
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
