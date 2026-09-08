// SPEC: 5.6.2 ProgressModel — state: heatMap [DayCell], weeks [RingRecord], totals, strength [ExerciseTrend] (only where weight
// logged); actions: select(dayKey) → DayDetail (workout + plates). Flow 9 layers 1–3, all from the local Store (offline-first).
// WRITTEN — UNVERIFIED (needs Mac). T040

import Foundation
import Observation
import SwiftData

struct DayCell: Equatable, Identifiable {
    let dayKey: String
    let workout: Bool
    let posted: Bool
    var id: String { dayKey }
}

struct RingRecord: Equatable, Identifiable {
    let weekKey: String
    let done: Int
    let planned: Int
    let sets: Int
    let meals: Int
    var id: String { weekKey }
}

struct ExerciseTrend: Equatable, Identifiable {
    let exerciseId: String
    let name: String
    let points: [(dayKey: String, best: Double)]
    var id: String { exerciseId }
    static func == (lhs: ExerciseTrend, rhs: ExerciseTrend) -> Bool { lhs.exerciseId == rhs.exerciseId && lhs.points.map(\.best) == rhs.points.map(\.best) }
}

struct DayDetail: Equatable {
    let dayKey: String
    let workouts: [String]      // "Push day · 12 sets"
    let plates: [LocalPost]
}

@Observable
@MainActor
final class ProgressModel {
    var heatMap: [DayCell] = []
    var weeks: [RingRecord] = []
    var totals = (workouts: 0, posts: 0, longestStreak: 0, currentStreak: 0)
    var strength: [ExerciseTrend] = []
    var balance = (push: 0, pull: 0, legs: 0, fullBody: 0)
    var isEmpty = true

    private let store: Store
    private let userId: String
    private let timeZone: TimeZone
    private let heatMapWeeks = SpecConstants.progressHeatMapWeeks
    private let ringWeeks = SpecConstants.progressRingHistoryWeeks

    init(store: Store = .shared, userId: String? = nil, timeZone: TimeZone = .current) {
        self.store = store
        self.userId = userId ?? AuthStore.shared.currentUser?.id ?? "local"
        self.timeZone = timeZone
    }

    func refresh(now: Date = Date()) {
        guard let posts = try? store.allPosts(for: userId), let plan = try? store.plan(for: userId), let state = try? store.gamificationState(for: userId) else { return }
        let completed = (try? store.context.fetch(FetchDescriptor<LocalSession>(predicate: #Predicate { $0.userId == userId && $0.status == "completed" }, sortBy: [SortDescriptor(\.dayKey)]))) ?? []
        isEmpty = posts.isEmpty
        let todayKey = DayKey.dayKey(for: now, tz: timeZone)
        let from = DayKey.addDays(DayKey.weekKey(for: todayKey), -(heatMapWeeks - 1) * TimeUnits.daysPerWeek)
        let workoutDays = Set(completed.map(\.dayKey))
        let postDays = Set(posts.map(\.dayKey))
        var cells: [DayCell] = []
        var day = from
        while day <= todayKey { cells.append(DayCell(dayKey: day, workout: workoutDays.contains(day), posted: postDays.contains(day))); day = DayKey.addDays(day, 1) }
        heatMap = cells
        let plannedCount = plan?.workouts.count ?? 0
        weeks = (0..<ringWeeks).reversed().map { offset in
            let weekKey = DayKey.addDays(DayKey.weekKey(for: todayKey), -offset * TimeUnits.daysPerWeek)
            let end = DayKey.addDays(weekKey, TimeUnits.daysPerWeek)
            let inWeek = completed.filter { $0.dayKey >= weekKey && $0.dayKey < end }
            let sets = inWeek.reduce(0) { $0 + $1.exercises.flatMap(\.sets).filter { $0.done && !$0.isWarmup }.count }
            let meals = posts.filter { $0.type == "meal" && $0.dayKey >= weekKey && $0.dayKey < end }.count
            return RingRecord(weekKey: weekKey, done: Set(inWeek.map(\.dayKey)).count, planned: plannedCount, sets: sets, meals: meals)
        }
        totals = (completed.count, posts.count, state.longestStreak, state.currentStreak)
        balance = completed.reduce(into: (0, 0, 0, 0)) { acc, session in
            let name = session.workoutName.lowercased()
            if name.hasPrefix("push") { acc.0 += 1 } else if name.hasPrefix("pull") { acc.1 += 1 } else if name.hasPrefix("leg") { acc.2 += 1 } else { acc.3 += 1 }
        }
        strength = strengthTrends(completed)
    }

    // LAYER 3 — only where weights were logged; never logged weight → politely doesn't exist
    private func strengthTrends(_ completed: [LocalSession]) -> [ExerciseTrend] {
        var trends: [String: ExerciseTrend] = [:]
        for session in completed {
            for exercise in session.exercises {
                let weights = exercise.sets.filter { $0.done }.compactMap(\.weight)
                guard let best = weights.max() else { continue }
                let existing = trends[exercise.exerciseId]
                trends[exercise.exerciseId] = ExerciseTrend(exerciseId: exercise.exerciseId, name: exercise.name, points: (existing?.points ?? []) + [(session.dayKey, best)])
            }
        }
        return trends.values.sorted { $0.name < $1.name }
    }

    func select(_ dayKey: String) -> DayDetail {
        let sessions = (try? store.sessions(for: userId, dayKey: dayKey)) ?? []
        let plates = ((try? store.posts(for: userId, dayKey: dayKey)) ?? []).filter { $0.type != "workout" }
        return DayDetail(dayKey: dayKey, workouts: sessions.filter { $0.status == "completed" }.map { "\($0.workoutName) · \($0.exercises.flatMap(\.sets).filter { $0.done && !$0.isWarmup }.count) sets" }, plates: plates)
    }
}
