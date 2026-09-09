// SPEC: E6 (offline-first: the plan lives on the phone) · Part IX Plan → WorkoutTemplate → ExerciseTemplate — the one writer of
// LocalPlan: the server's plan (or the accepted draft) REPLACES the local copy, forward-only (Flow 8). Called after signup,
// after login, after a rebuild, after an editor save and after a mid-workout "Update my plan". A1 (owner-directed 2026-09-08):
// the draft is trainingWeekdays plus workouts in rotation order; `draft(_:)` is the read twin the editor and the swap start from.
// WRITTEN — UNVERIFIED (needs Mac). T042 (found while wiring Rebuild: no writer existed)

import Foundation
import SwiftData

@MainActor
enum PlanLocal {
    // SPEC: A1 — the whole plan is replaced: training days, then the workouts with their stored position (the rotation order)
    static func replace(_ draft: PlanDraft, userId: String, updatedAt: Date = Date(), store: Store) throws {
        if let existing = try store.plan(for: userId) { store.context.delete(existing) }
        let templates = draft.workouts.enumerated().map { position, workout in
            LocalWorkoutTemplate(name: workout.name, kind: workout.kind, order: position, exercises: workout.exercises.map { row in
                LocalExerciseTemplate(exerciseId: row.exerciseId, name: row.name, pattern: row.pattern, equipment: row.equipment, type: row.type, targetSets: row.targetSets, targetReps: row.targetReps, targetRepsMax: row.targetRepsMax, targetWeight: nil, holdSeconds: row.holdSeconds, perSide: row.perSide ?? false, order: row.order)
            })
        }
        store.context.insert(LocalPlan(userId: userId, trainingWeekdays: draft.trainingWeekdays, updatedAt: updatedAt, workouts: templates))
        try store.save()
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

    // After login the server copy wins; a 404 (no plan yet) leaves the phone empty so Home invites "Build my week"
    static func pullFromServer(userId: String, store: Store) async {
        guard let plan = try? await Api.shared.getPlan() else { return }
        try? replace(plan.draft, userId: userId, updatedAt: plan.updatedAt ?? Date(), store: store)
    }
}
