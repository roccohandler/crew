// SPEC: E6 (offline-first: the plan lives on the phone) · Part IX Plan → WorkoutTemplate → ExerciseTemplate — the one writer of
// LocalPlan: the server's plan (or the accepted draft) REPLACES the local copy, forward-only (Flow 8). Called after signup,
// after login, and after a rebuild. WRITTEN — UNVERIFIED (needs Mac). T042 (found while wiring Rebuild: no writer existed)

import Foundation
import SwiftData

@MainActor
enum PlanLocal {
    static func replace(_ workouts: [PlanDraftWorkout], userId: String, updatedAt: Date = Date(), store: Store) throws {
        if let existing = try store.plan(for: userId) { store.context.delete(existing) }
        let templates = workouts.map { workout in
            LocalWorkoutTemplate(weekday: workout.weekday, name: workout.name, kind: workout.kind, exercises: workout.exercises.map { row in
                LocalExerciseTemplate(exerciseId: row.exerciseId, name: row.name, pattern: row.pattern, equipment: row.equipment, type: row.type, targetSets: row.targetSets, targetReps: row.targetReps, targetRepsMax: row.targetRepsMax, targetWeight: nil, holdSeconds: row.holdSeconds, perSide: row.perSide ?? false, order: row.order)
            })
        }
        store.context.insert(LocalPlan(userId: userId, updatedAt: updatedAt, workouts: templates))
        try store.save()
    }

    // After login the server copy wins; a 404 (no plan yet) leaves the phone empty so Home invites "Build my week"
    static func pullFromServer(userId: String, store: Store) async {
        guard let plan = try? await Api.shared.getPlan() else { return }
        try? replace(plan.workouts, userId: userId, updatedAt: plan.updatedAt ?? Date(), store: store)
    }
}
