// SPEC: E6 (offline-first: the plan lives on the phone) · Part IX Plan → WorkoutTemplate → ExerciseTemplate — the one writer of
// LocalPlan: the server's plan (or the accepted draft) REPLACES the local copy, forward-only (Flow 8). Called after signup,
// after login, after a rebuild, after an editor save and after a mid-workout "Update my plan". A1 (owner-directed 2026-09-08):
// the draft is trainingWeekdays plus workouts in rotation order; `draft(_:)` is the read twin the editor and the swap start from.
// A27 (a) (owner-ruled 2026-09-18): also the one writer of the training-days history (LocalTrainingDays) and its one reader.
// WRITTEN — UNVERIFIED (needs Mac). T042 (found while wiring Rebuild: no writer existed)

import Foundation
import SwiftData

@MainActor
enum PlanLocal {
    // SPEC: A1 — the whole plan is replaced: training days, then the workouts with their stored position (the rotation order).
    // A27 (a) — `history` is the server's training-days history and REPLACES the local rows; without it the draft is a local edit,
    // and a change of days is APPENDED, in effect from the day it was saved (the device's zone, E8) — never an edit of a row
    static func replace(_ draft: PlanDraft, userId: String, updatedAt: Date = Date(), history: [TrainingDaysEntry]? = nil, timeZone: TimeZone = .current, store: Store) throws {
        let before = try trainingDays(for: userId, store: store)
        if let existing = try store.plan(for: userId) { store.context.delete(existing) }
        let templates = draft.workouts.enumerated().map { position, workout in
            LocalWorkoutTemplate(name: workout.name, kind: workout.kind, order: position, exercises: workout.exercises.map { row in
                LocalExerciseTemplate(exerciseId: row.exerciseId, name: row.name, pattern: row.pattern, equipment: row.equipment, type: row.type, targetSets: row.targetSets, targetReps: row.targetReps, targetRepsMax: row.targetRepsMax, targetWeight: nil, holdSeconds: row.holdSeconds, perSide: row.perSide ?? false, order: row.order)
            })
        }
        store.context.insert(LocalPlan(userId: userId, trainingWeekdays: draft.trainingWeekdays, updatedAt: updatedAt, workouts: templates))
        if let history {
            for row in try historyRows(for: userId, store: store) { store.context.delete(row) }
            insert(history, from: 0, userId: userId, store: store)
        } else {
            let next = TrainingDays.appendTrainingDays(before, weekdays: draft.trainingWeekdays, savedDayKey: DayKey.dayKey(for: updatedAt, tz: timeZone))
            if next.count > before.count { insert(next, from: try historyRows(for: userId, store: store).count, userId: userId, store: store) } // only the rows not yet stored
        }
        try store.save()
    }

    // SPEC: A27 (a) — the history every local reader judges by, in append order. An install from before A27 holds no rows until its
    // plan next arrives or its days next change; its one plan has only ever had its current days (R-082) — a single entry, which a
    // day before it also takes. No plan: nothing is planned.
    static func trainingDays(for userId: String, store: Store) throws -> [TrainingDaysEntry] {
        let rows = try historyRows(for: userId, store: store)
        if !rows.isEmpty { return rows.map { TrainingDaysEntry(from: $0.effectiveFrom, weekdays: $0.weekdays) } }
        guard let plan = try store.plan(for: userId) else { return [] }
        return [TrainingDaysEntry(from: DayKey.dayKey(for: plan.updatedAt, tz: .current), weekdays: plan.trainingWeekdays)]
    }

    private static func historyRows(for userId: String, store: Store) throws -> [LocalTrainingDays] {
        try store.context.fetch(FetchDescriptor<LocalTrainingDays>(predicate: #Predicate { $0.userId == userId }, sortBy: [SortDescriptor(\.position)]))
    }

    private static func insert(_ history: [TrainingDaysEntry], from first: Int, userId: String, store: Store) {
        for (position, entry) in history.enumerated() where position >= first {
            store.context.insert(LocalTrainingDays(userId: userId, effectiveFrom: entry.from, weekdays: entry.weekdays, position: position))
        }
    }

    // SPEC: A1 — the local plan back as the engine's draft: workouts in rotation order, rows in their order
    static func draft(_ plan: LocalPlan) -> PlanDraft {
        let workouts = plan.workouts.sorted { $0.order < $1.order }.map { workout in
            PlanDraftWorkout(name: workout.name, kind: workout.kind, exercises: workout.exercises.sorted { $0.order < $1.order }.map { row in
                PlanDraftExercise(exerciseId: row.exerciseId, name: row.name, pattern: row.pattern, equipment: row.equipment, type: row.type, targetSets: row.targetSets, targetReps: row.targetReps, targetRepsMax: row.targetRepsMax, holdSeconds: row.holdSeconds, perSide: row.perSide, order: row.order)
            })
        }
        return PlanDraft(trainingWeekdays: plan.trainingWeekdays, workouts: workouts)
    }

    // After login the server copy wins — the plan and its training-days history (A27 (a)); a 404 (no plan yet) leaves the phone
    // empty so Home invites "Build my week"
    static func pullFromServer(userId: String, store: Store) async {
        guard let plan = try? await Api.shared.getPlan() else { return }
        try? replace(plan.draft, userId: userId, updatedAt: plan.updatedAt ?? Date(), history: plan.trainingDaysHistory, store: store)
    }
}
