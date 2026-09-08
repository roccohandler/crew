// SPEC: README kind achievements — the counter derivations the vectors do not cover: prCount (Flow 3 / Flow 9 layer 3),
// crew full-pulse days and weeks (V37/V38/V40 membership rules), the local solo counters, and the unlock riding a
// completion (E8). The thresholds themselves are V45–V50 (VectorRunnerTests). Same cases as
// web/tests/engine/achievements.test.ts. WRITTEN — UNVERIFIED (needs Mac).

import XCTest
@testable import Crew

final class AchievementsTests: XCTestCase {
    private func session(_ completedAt: String, _ exerciseId: String, _ weights: [Double?]) -> RecordSession {
        RecordSession(completedAt: ISO8601DateFormatter().date(from: completedAt)!, exercises: [RecordExercise(exerciseId: exerciseId, name: exerciseId, sets: weights.map { RecordSet(done: true, isWarmup: false, weight: $0) })])
    }

    func testPersonalRecordsCountOnlyAgainstAnEarlierLoggedWeight() {
        let history = [session("2026-09-01T10:00:00Z", "bench", [100, 100]), session("2026-09-03T10:00:00Z", "bench", [105]), session("2026-09-05T10:00:00Z", "bench", [105]), session("2026-09-07T10:00:00Z", "bench", [110])]
        XCTAssertEqual(PersonalRecords.prCount(history), 2)
        XCTAssertEqual(PersonalRecords.prCount([session("2026-09-01T10:00:00Z", "squat", [nil, nil])]), 0)
        XCTAssertEqual(PersonalRecords.prCount([session("2026-09-01T10:00:00Z", "squat", [135])]), 0)
    }

    func testPersonalRecordsIgnoreWarmUpsAndUndoneSetsRegardlessOfOrder() {
        let later = session("2026-09-09T10:00:00Z", "row", [90])
        let earlier = RecordSession(completedAt: ISO8601DateFormatter().date(from: "2026-09-02T10:00:00Z")!, exercises: [RecordExercise(exerciseId: "row", name: "row", sets: [RecordSet(done: true, isWarmup: true, weight: 200), RecordSet(done: false, isWarmup: false, weight: 150), RecordSet(done: true, isWarmup: false, weight: 80)])])
        XCTAssertEqual(PersonalRecords.prCount([later, earlier]), 1)
        XCTAssertEqual(PersonalRecords.newRecords(later.exercises, earlier: [earlier]), ["row"])
    }

    private func everyDay(_ userId: String, from: String, count: Int) -> [MemberPostFacts] {
        (0..<count).map { MemberPostFacts(userId: userId, dayKey: DayKey.addDays(from, $0)) }
    }

    func testFullPulseDaysNeedEveryonePresentAndAtLeastTheMinimumCrew() {
        let members = [MemberFacts(userId: "A", joinedDayKey: "2026-08-31", leftDayKey: nil), MemberFacts(userId: "B", joinedDayKey: "2026-08-31", leftDayKey: nil), MemberFacts(userId: "C", joinedDayKey: "2026-09-03", leftDayKey: nil)]
        let posts = everyDay("A", from: "2026-09-01", count: 7) + everyDay("B", from: "2026-09-01", count: 7) + everyDay("C", from: "2026-09-03", count: 4)
        XCTAssertEqual(CrewRules.fullPulseDays(members: members, posts: posts, fromDay: "2026-09-01", toDay: "2026-09-07"), 6)
        XCTAssertEqual(CrewRules.fullPulseDays(members: [members[0]], posts: everyDay("A", from: "2026-09-01", count: 7), fromDay: "2026-09-01", toDay: "2026-09-07"), 0)
    }

    func testFullPulseWeeksCountOnlyCompleteWeeksStartingAfterTheJoin() {
        let pair = [MemberFacts(userId: "A", joinedDayKey: "2026-08-31", leftDayKey: nil), MemberFacts(userId: "B", joinedDayKey: "2026-08-31", leftDayKey: nil)]
        let posts = everyDay("A", from: "2026-08-31", count: 14) + everyDay("B", from: "2026-08-31", count: 14)
        XCTAssertEqual(CrewRules.fullPulseWeeks(members: pair, posts: posts, fromDay: "2026-08-31", toDay: "2026-09-13"), 2)
        XCTAssertEqual(CrewRules.fullPulseWeeks(members: pair, posts: posts, fromDay: "2026-09-01", toDay: "2026-09-13"), 1)
        XCTAssertEqual(CrewRules.fullPulseWeeks(members: pair, posts: posts, fromDay: "2026-08-31", toDay: "2026-09-12"), 1)
    }

}
