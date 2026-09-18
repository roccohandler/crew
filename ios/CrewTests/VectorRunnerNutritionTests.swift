// SPEC: 8.1 V57–V65 (kind `nutrition`, shared/vectors/README.md) — the nutrition twins against the shared fixtures: target
// derivation, the carbs floor, remaining macros, idempotent logging, no game event for an entry (clause ③), the bodyweight inside
// the targets, the 18+ gate. The third vector runner (VectorRunnerTests and VectorRunnerCrewTests hold the rest, C9).
// WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

final class VectorRunnerNutritionTests: XCTestCase {
    func testEveryNutritionVectorMatchesTheSwiftEngine() throws {
        var checked = 0
        for loaded in try VectorFiles.load() {
            for vector in loaded.vectors where vector["kind"] as? String == "nutrition" && vector["retired"] == nil {
                let id = vector["id"] as? String ?? "?"
                for item in vector["cases"] as? [[String: Any]] ?? [] { try run(id: id, item: item) }
                checked += 1
            }
        }
        XCTAssertGreaterThan(checked, 0)
    }

    private func run(id: String, item: [String: Any]) throws {
        let expect = item["expect"] as Any
        switch item["op"] as? String {
        case "derive":
            let derived = NutritionTargets.deriveTargets(item["bodyweightTenths"] as? Int ?? 0, item["unit"] as? String ?? "")
            XCTAssertEqual(derived, try VectorFiles.decode(MacroTargets.self, from: expect), id)
        case "carbs":
            let rest = NutritionTargets.carbs(item["energyKcal"] as? Int ?? 0, item["proteinG"] as? Int ?? 0, item["fatG"] as? Int ?? 0)
            XCTAssertEqual(rest, try VectorFiles.decode(CarbsResult.self, from: expect), id)
        case "remaining":
            let targets = try VectorFiles.decode(MacroGrams.self, from: item["targets"] as Any)
            let logs = try VectorFiles.decode([MealLogFacts].self, from: item["logs"] as Any)
            XCTAssertEqual(MacroDay.remaining(targets, logs), try VectorFiles.decode(MacroRemaining.self, from: expect), id)
        case "logging":
            var logs = try VectorFiles.decode([MealLogFacts].self, from: item["logs"] as Any)
            for entry in try VectorFiles.decode([MealLogFacts].self, from: item["entries"] as Any) { logs = MacroDay.logging(entry, logs) }
            XCTAssertEqual(logs, try VectorFiles.decode([MealLogFacts].self, from: expect), id)
        case "gameEvents":
            let logs = try VectorFiles.decode([MealLogFacts].self, from: item["logs"] as Any)
            XCTAssertEqual(MacroDay.gameEvents(logs).count, (expect as? [String: Any])?["eventCount"] as? Int, id)
        case "bodyweightOf":
            let facts = item["targets"] is NSNull ? nil : try VectorFiles.decode(TargetsFacts.self, from: item["targets"] as Any)
            let expected = expect is NSNull ? nil : try VectorFiles.decode(BodyweightFacts.self, from: expect)
            XCTAssertEqual(NutritionTargets.bodyweightOf(facts), expected, id)
        case "availability":
            let answer = NutritionGate.availability(item["birthYear"] as? Int, item["currentYear"] as? Int ?? 0)
            XCTAssertEqual(answer.rawValue, expect as? String, id)
        default:
            XCTFail("\(id): no nutrition op \(item["op"] ?? "?")")
        }
    }
}
