// SPEC: 5.6.2 ProgressModel — state: heatMap [DayCell], weeks [RingRecord], totals, strength [ExerciseTrend] (only where weight
// logged); actions: select(dayKey) → DayDetail (the day's workouts; A22: the plates left with the plate journal). Flow 9 layers 1–3, all from the local Store (offline-first).
// A2/A6 (owner-directed 2026-09-08): sets = strength work sets; cardio and mobility are minutes per week (facts, never targets);
// A1 · A27 (a): planned = the days the training days in effect on each of them plan. Twin of web/src/lib/progress-facts.ts.
// WRITTEN — UNVERIFIED (needs Mac). T040

import Foundation
import Observation
import SwiftData

// A14: three marks — a standalone cardio log is not a workout. Same ember hue, different fill treatment (law ⑥).
struct DayCell: Equatable, Identifiable {
    let dayKey: String
    let workout: Bool
    let cardio: Bool
    let posted: Bool
    var future = false // A28 (d): the grid runs to Sunday, so this week's days still to come draw empty and answer no tap
    var id: String { dayKey }
}

struct RingRecord: Equatable, Identifiable {
    let weekKey: String
    let done: Int
    let planned: Int
    let sets: Int            // strength work sets (A6)
    let cardioMinutes: Int   // A2 — a fact, never a target
    let mobilityMinutes: Int
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
    let workouts: [String]      // A6 lines: "Push day · 12/12 sets · 44 min" · "Walk · 25 min · 2.1 km"
}

@Observable
@MainActor
final class ProgressModel {
    var heatMap: [DayCell] = []
    var season: SeasonFacts?   // A28 (e) · GAP 10 (R-086): "This season · N weeks · N workouts"
    var weeks: [RingRecord] = []
    var totals = (workouts: 0, posts: 0, longestStreak: 0, currentStreak: 0)
    var strength: [ExerciseTrend] = []
    var balance = (push: 0, pull: 0, legs: 0, fullBody: 0)
    var isEmpty = true
    var todayKey = ""

    private let store: Store
    private let userId: String
    private let timeZone: TimeZone
    private let units: String       // A9: weight — the strength trends
    private let distanceUnit: String // A9: distance — the day-detail summary lines
    private let heatMapWeeks = SpecConstants.progressHeatMapWeeks
    private let ringWeeks = SpecConstants.progressRingHistoryWeeks

    init(store: Store = .shared, userId: String? = nil, timeZone: TimeZone = .current, units: String? = nil, distanceUnit: String? = nil) {
        self.store = store
        self.userId = userId ?? AuthStore.shared.currentUser?.id ?? "local"
        self.timeZone = timeZone
        self.units = units ?? AuthStore.shared.weightUnit // A9
        self.distanceUnit = distanceUnit ?? AuthStore.shared.distanceUnit
    }

    // SPEC: 6.1 — a Store error is thrown to the screen (its failed state), never swallowed into a blank
    func refresh(now: Date = Date()) throws {
        let userId = self.userId
        let posts = try store.allPosts(for: userId)
        let state = try store.gamificationState(for: userId)
        let plan = try store.plan(for: userId) // nil until onboarding wrote one — the heat map still renders, the rings plan 0
        let completed = try store.context.fetch(FetchDescriptor<LocalSession>(predicate: #Predicate { $0.userId == userId && $0.status == "completed" }, sortBy: [SortDescriptor(\.dayKey)]))
        isEmpty = posts.isEmpty
        todayKey = DayKey.dayKey(for: now, tz: timeZone)
        // SPEC: A1 · A27 (a) — a week's planned count is its days that the training days in effect ON each of them plan
        let history = try plan == nil ? [] : PlanLocal.trainingDays(for: userId, store: store)
        let today = todayKey
        let ended = try store.context.fetch(FetchDescriptor<LocalPause>(predicate: #Predicate { $0.userId == userId && $0.endDay <= today })).map(.endDay)
        season = SeasonFacts.of(history: history, endedPauseDays: ended, workoutDayKeys: completed.filter { $0.workoutKind != "cardio" }.map(.dayKey), todayKey: todayKey)
        heatMap = heatMapCells(completed: completed, posts: posts)
        weeks = (0..<ringWeeks).reversed().map { offset in
            let weekKey = DayKey.addDays(DayKey.weekKey(for: todayKey), -offset * TimeUnits.daysPerWeek)
            let planned = (0..<TimeUnits.daysPerWeek).filter { TrainingDays.isPlannedOn(history, DayKey.addDays(weekKey, $0)) }.count
            return weekRecord(weekKey, completed: completed, planned: planned)
        }
        totals = (completed.count, posts.count, state.longestStreak, state.currentStreak)
        balance = balanceOf(completed)
        strength = strengthTrends(completed)
    }

    // LAYER 1 · A28 (d) — one row per week of the season (mockup 12: six weeks, six rows), never more than progressHeatMapWeeks,
    // Monday-aligned (E20) and run to Sunday; with no season, the last progressHeatMapWeeks
    private func heatMapCells(completed: [LocalSession], posts: [LocalPost]) -> [DayCell] {
        let thisWeek = DayKey.weekKey(for: todayKey)
        let earliest = DayKey.addDays(thisWeek, -(heatMapWeeks - 1) * TimeUnits.daysPerWeek)
        let from = max(season.map { DayKey.weekKey(for: $0.startDayKey) } ?? earliest, earliest)
        // A14: a standalone cardio session is its own mark — it used to land in workoutDays, so a week of walks read as
        // a week of workouts on the one screen whose question is "did I show up?"
        let workoutDays = Set(completed.filter { $0.workoutKind != "cardio" }.map(\.dayKey))
        let cardioDays = Set(completed.filter { $0.workoutKind == "cardio" }.map(\.dayKey))
        let postDays = Set(posts.map(\.dayKey))
        var cells: [DayCell] = []
        var day = from
        let last = DayKey.addDays(thisWeek, TimeUnits.daysPerWeek - 1)
        while day <= last { cells.append(DayCell(dayKey: day, workout: workoutDays.contains(day), cardio: cardioDays.contains(day), posted: postDays.contains(day), future: day > todayKey)); day = DayKey.addDays(day, 1) }
        return cells
    }

    // SPEC: A6 — sets = strength work sets; A2 — cardio and mobility minutes are the rounded sum of done seconds (facts, never targets)
    private func weekRecord(_ weekKey: String, completed: [LocalSession], planned: Int) -> RingRecord {
        let end = DayKey.addDays(weekKey, TimeUnits.daysPerWeek)
        let inWeek = completed.filter { $0.dayKey >= weekKey && $0.dayKey < end }
        return RingRecord(weekKey: weekKey, done: Set(inWeek.map(\.dayKey)).count, planned: planned, sets: doneSets(inWeek, type: "strength").count,
                          cardioMinutes: minutes(of: doneSets(inWeek, type: "cardio")), mobilityMinutes: minutes(of: doneSets(inWeek, type: "mobility")))
    }

    private func doneSets(_ sessions: [LocalSession], type: String) -> [LocalSetLog] {
        sessions.flatMap { JournalFacts.doneSets($0, type: type) }
    }

    private func minutes(of sets: [LocalSetLog]) -> Int {
        JournalFacts.minutes(ofSeconds: sets.reduce(0) { $0 + ($1.holdSeconds ?? 0) })
    }

    // SPEC: Flow 9 layer 2 — Push/Pull/Legs balance by the session's kind (a legacy session infers it from its name, A1); a
    // standalone cardio log is not a split day (A2)
    private func balanceOf(_ completed: [LocalSession]) -> (push: Int, pull: Int, legs: Int, fullBody: Int) {
        var tally = (push: 0, pull: 0, legs: 0, fullBody: 0)
        for session in completed {
            switch session.workoutKind ?? PlanRotation.workoutKindFromName(session.workoutName) ?? "" {
            case "cardio": break
            case "push": tally.push += 1
            case "pull": tally.pull += 1
            case "legs": tally.legs += 1
            default: tally.fullBody += 1
            }
        }
        return tally
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

    // SPEC: Flow 9 layer 1 — tap a day: that day's workouts; every session reads its A6 line ("Push day · 12/12 sets ·
    // 44 min" · "Walk · 25 min · 2.1 km"), so a hold-only day never says "0 sets" (A8)
    func select(_ dayKey: String) -> DayDetail {
        let sessions = ((try? store.sessions(for: userId, dayKey: dayKey)) ?? []).filter { $0.status == "completed" }
        return DayDetail(dayKey: dayKey, workouts: sessions.map { JournalFacts.summaryLine($0, distanceUnit: distanceUnit) })
    }
}
