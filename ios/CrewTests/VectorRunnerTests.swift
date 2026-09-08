// SPEC: 8.1 — every shared vector against the Swift engine, EXACT match; twin of web/tests/vectors.test.ts. dayKey · apply ·
// completion · recompute · pauseValidation here; crew kinds in VectorRunnerCrewTests.swift. An unknown kind fails.
// WRITTEN — UNVERIFIED (needs Mac). T016–T019

import XCTest
@testable import Crew

final class VectorRunnerTests: XCTestCase {
    func testEveryNonCrewVectorMatchesTheSwiftEngine() throws {
        var checked = 0
        for loaded in try VectorFiles.load() {
            for vector in loaded.vectors {
                let id = vector["id"] as? String ?? "?"
                switch vector["kind"] as? String {
                case "dayKey": try runDayKey(id: id, vector: vector)
                case "apply": try runApply(id: id, vector: vector)
                case "completion": try runCompletion(id: id, vector: vector)
                case "recompute": try runRecompute(id: id, vector: vector)
                case "pauseValidation": try runPauseValidation(id: id, vector: vector)
                case "achievements": try runAchievements(id: id, vector: vector)
                case "crewPulse", "crewWeeklyRing", "comebackBanner": continue // VectorRunnerCrewTests
                default: XCTFail("\(id): no runner for kind \(vector["kind"] ?? "?")")
                }
                checked += 1
            }
        }
        // Every vector is run by one of the two runners: the counts must add up to the files' own total, or a fixture was
        // added that neither engine half sees (8.1 — the whole suite is the gate, not the part that happens to be wired).
        let total = try VectorFiles.load().reduce(0) { $0 + $1.vectors.count }
        let crewKinds = try VectorFiles.load().reduce(0) { count, loaded in count + loaded.vectors.filter { ["crewPulse", "crewWeeklyRing", "comebackBanner"].contains($0["kind"] as? String ?? "") }.count }
        XCTAssertEqual(checked, total - crewKinds)
        XCTAssertGreaterThan(checked, 0)
    }

    // README kind achievements (V45–V50): counters → seed-ordered awards not yet earned; earnedAfter = alreadyEarned + awarded
    private func runAchievements(id: String, vector: [String: Any]) throws {
        for item in vector["cases"] as? [[String: Any]] ?? [] {
            let raw = item["counters"] as? [String: Int] ?? [:]
            let counters = try JSONDecoder.crew.decode(AchievementCounters.self, from: try JSONSerialization.data(withJSONObject: raw))
            let already = item["alreadyEarned"] as? [String] ?? []
            let awards = Achievements.achievementsEarned(counters, alreadyEarned: already)
            let expect = item["expect"] as? [String: Any] ?? [:]
            let expectedIds = (expect["awards"] as? [[String: Any]] ?? []).compactMap { $0["id"] as? String }
            let awardedIds = awards.compactMap { award -> String? in if case .achievement(let achievementId) = award { return achievementId }; return nil }
            XCTAssertEqual(awardedIds, expectedIds, "\(id) awards for \(raw)")
            XCTAssertEqual(already + awardedIds, expect["earnedAfter"] as? [String] ?? [], "\(id) earnedAfter")
        }
    }

    private func runDayKey(id: String, vector: [String: Any]) throws {
        for item in vector["cases"] as? [[String: Any]] ?? [] {
            let dayKey = try VectorFiles.resolveDay(item)
            XCTAssertEqual(dayKey, item["dayKey"] as? String, "\(id) \(item["at"] ?? "") \(item["tz"] ?? "")")
            XCTAssertEqual(DayKey.weekKey(for: dayKey), item["weekKey"] as? String, "\(id) weekKey for \(dayKey)")
        }
    }

    private func event(from json: [String: Any]) throws -> GameEvent {
        let dayKey = try VectorFiles.resolveDay(json)
        switch json["type"] as? String {
        case "postCreated":
            let kind = try XCTUnwrap(PostKind(rawValue: try XCTUnwrap(json["kind"] as? String)))
            return .postCreated(kind: kind, dayKey: dayKey, isPlannedDay: json["isPlannedDay"] as? Bool ?? false, workoutCompleted: json["workoutCompleted"] as? Bool ?? false)
        case "postUndone": return .postUndone(dayKey: dayKey)
        case "dayRolledOver": return .dayRolledOver(dayKey: dayKey, hadRequirement: json["hadRequirement"] as? Bool ?? false)
        case "reactionGiven": return .reactionGiven(dayKey: dayKey)
        default: throw XCTSkip("unknown event type")
        }
    }

    private func runApply(id: String, vector: [String: Any]) throws {
        let initial = try VectorFiles.decode(PublicState.self, from: try XCTUnwrap(vector["initialState"]))
        var state = GamificationState()
        state.currentStreak = initial.currentStreak
        state.longestStreak = initial.longestStreak
        state.totalXP = initial.totalXP
        state.level = initial.level
        state.shields = initial.shields
        state.lastCountedDayKey = initial.lastCountedDayKey
        state.earnedAchievementIds = initial.earnedAchievementIds
        let pauses = try VectorFiles.pauses(vector["pauses"])
        let expect = try XCTUnwrap(vector["expect"] as? [String: Any])
        let expectedAwards = try XCTUnwrap(expect["awardsByEvent"] as? [[[String: Any]]])
        for (index, raw) in (vector["events"] as? [[String: Any]] ?? []).enumerated() {
            let (next, awards) = GamificationEngine.apply(try event(from: raw), to: state, pauses: pauses)
            state = next
            XCTAssertEqual(awards.map(VectorFiles.json(of:)) as NSArray, expectedAwards[index] as NSArray, "\(id) awards for events[\(index)]")
        }
        XCTAssertEqual(VectorFiles.publicStateJson(state.publicState) as NSDictionary, try XCTUnwrap(expect["state"] as? [String: Any]) as NSDictionary, "\(id) final state")
    }

    private func runCompletion(id: String, vector: [String: Any]) throws {
        for item in vector["cases"] as? [[String: Any]] ?? [] {
            let sets = try VectorFiles.decode([SetFacts].self, from: try XCTUnwrap(item["sets"]))
            let expected = try VectorFiles.decode(CompletionFacts.self, from: try XCTUnwrap(item["expect"]))
            XCTAssertEqual(Completion.completionFacts(sets), expected, id)
        }
    }

    private func runRecompute(id: String, vector: [String: Any]) throws {
        let pauses = try VectorFiles.pauses(vector["pauses"])
        let asOf = try XCTUnwrap(vector["asOfDayKey"] as? String)
        let expected = try VectorFiles.decode(PublicState.self, from: try XCTUnwrap((vector["expect"] as? [String: Any])?["state"]))
        for variant in vector["variants"] as? [[String: Any]] ?? [] {
            let sessions = try VectorFiles.decode([SessionFacts].self, from: variant["sessions"] ?? [])
            let posts = try VectorFiles.decode([PostFacts].self, from: variant["posts"] ?? [])
            let reactions = try VectorFiles.decode([ReactionFacts].self, from: variant["reactions"] ?? [])
            XCTAssertEqual(GamificationRecompute.recompute(sessions: sessions, posts: posts, reactions: reactions, pauses: pauses, asOfDayKey: asOf), expected, "\(id) \(variant["label"] ?? "")")
        }
    }

    private func runPauseValidation(id: String, vector: [String: Any]) throws {
        for item in vector["cases"] as? [[String: Any]] ?? [] {
            let existing = try VectorFiles.pauses(item["existingPauses"])
            let result = PauseValidation.validatePauseRequest(today: try XCTUnwrap(item["today"] as? String), startDay: try XCTUnwrap(item["startDay"] as? String), endDay: try XCTUnwrap(item["endDay"] as? String), existingPauses: existing)
            let expect = try XCTUnwrap(item["expect"] as? [String: Any])
            XCTAssertEqual(result.accepted, expect["accepted"] as? Bool, id)
            XCTAssertEqual(result.reason?.rawValue, expect["reason"] as? String, id)
        }
    }
}
