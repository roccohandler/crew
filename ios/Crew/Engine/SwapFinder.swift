// SPEC: Flow 1 step 4 (3–5 alternatives that do the same job) · 5.6.1 swapCandidates (same pattern, ≤5, never incumbent)
// · 8.3 · exercises.json swapRule (tiers swapGroup → pattern → region, widening only while fewer than swapCandidatesMin
// exist; same-or-lower level first). Twin of swap-finder.ts. WRITTEN — UNVERIFIED (needs Mac).

import Foundation

enum SwapFinder {
    private static let levels = ["brandNew", "some", "experienced"]
    private static var levelRank: [String: Int] { Dictionary(uniqueKeysWithValues: levels.enumerated().map { ($1, $0) }) }

    static func swapCandidates(for incumbent: SeedExercise, access: String, experience: String, seed: SeedCatalog) -> [SeedExercise] {
        let available = Set(seed.equipmentAccess[access] ?? [])
        let usable = seed.exercises.filter { $0.id != incumbent.id && $0.type == incumbent.type && available.contains($0.equipment) }
        let tiers: [(SeedExercise) -> Bool] = [
            { $0.swapGroup == incumbent.swapGroup },
            { $0.pattern == incumbent.pattern },
            { seed.regionOfPattern[$0.pattern] == seed.regionOfPattern[incumbent.pattern] },
        ]
        var found: [SeedExercise] = []
        for tier in tiers {
            found = usable.filter(tier)
            if found.count >= SpecConstants.swapCandidatesMin { break }
        }
        let userRank = levelRank[experience] ?? 0
        let ranked = found.sorted { left, right in
            let leftFits = (levelRank[left.level] ?? 0) <= userRank ? 0 : 1
            let rightFits = (levelRank[right.level] ?? 0) <= userRank ? 0 : 1
            if leftFits != rightFits { return leftFits < rightFits }
            let leftLevel = levelRank[left.level] ?? 0
            let rightLevel = levelRank[right.level] ?? 0
            if leftLevel != rightLevel { return leftLevel < rightLevel }
            return left.name < right.name
        }
        return Array(ranked.prefix(SpecConstants.swapCandidatesMax))
    }
}
