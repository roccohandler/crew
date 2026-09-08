// SPEC: 8.1 V37–V40 against CrewRules.swift, EXACT match; twin of the crew runners in web/tests/vectors.test.ts.
// WRITTEN — UNVERIFIED (needs Mac). T032 (engine part)

import XCTest
@testable import Crew

final class VectorRunnerCrewTests: XCTestCase {
    func testEveryCrewVectorMatchesTheSwiftEngine() throws {
        var checked = 0
        for loaded in try VectorFiles.load() {
            for vector in loaded.vectors {
                let id = vector["id"] as? String ?? "?"
                switch vector["kind"] as? String {
                case "crewPulse": try runCrewPulse(id: id, vector: vector)
                case "crewWeeklyRing": try runCrewWeeklyRing(id: id, vector: vector)
                case "comebackBanner": try runComebackBanner(id: id, vector: vector)
                default: continue // VectorRunnerTests
                }
                checked += 1
            }
        }
        let crewKinds = try VectorFiles.load().reduce(0) { count, loaded in count + loaded.vectors.filter { ["crewPulse", "crewWeeklyRing", "comebackBanner"].contains($0["kind"] as? String ?? "") }.count }
        XCTAssertEqual(checked, crewKinds)
        XCTAssertGreaterThan(checked, 0)
    }

    private func members(_ json: Any?) throws -> [MemberFacts] {
        try VectorFiles.decode([MemberFacts].self, from: json ?? [])
    }

    private func posts(_ json: Any?) throws -> [MemberPostFacts] {
        try (json as? [[String: Any]] ?? []).map { MemberPostFacts(userId: try XCTUnwrap($0["userId"] as? String), dayKey: try VectorFiles.resolveDay($0)) }
    }

    private func runCrewPulse(id: String, vector: [String: Any]) throws {
        let pulse = CrewRules.crewPulse(members: try members(vector["members"]), posts: try posts(vector["posts"]), dayKey: try XCTUnwrap(vector["dayKey"] as? String))
        let expected = try VectorFiles.decode(Pulse.self, from: try XCTUnwrap(vector["expect"]))
        XCTAssertEqual(pulse, expected, id)
    }

    private func runCrewWeeklyRing(id: String, vector: [String: Any]) throws {
        for item in vector["cases"] as? [[String: Any]] ?? [] {
            let ring = CrewRules.crewWeeklyRing(members: try members(item["members"]), posts: try posts(item["posts"]), asOfDayKey: try XCTUnwrap(item["asOfDayKey"] as? String))
            let expected = try VectorFiles.decode([DayPulse].self, from: try XCTUnwrap((item["expect"] as? [String: Any])?["days"]))
            XCTAssertEqual(ring, expected, "\(id) as of \(item["asOfDayKey"] ?? "")")
        }
    }

    private func runComebackBanner(id: String, vector: [String: Any]) throws {
        let dayKeys = try (vector["posts"] as? [[String: Any]] ?? []).map { try XCTUnwrap($0["dayKey"] as? String) }
        let flags = CrewRules.comebackBanner(postDayKeys: dayKeys, pauses: try VectorFiles.pauses(vector["pauses"]))
        XCTAssertEqual(flags, try XCTUnwrap((vector["expect"] as? [String: Any])?["comebackByPost"] as? [Bool]), id)
    }
}
