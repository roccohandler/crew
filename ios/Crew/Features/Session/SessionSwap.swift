// SPEC: E7 — mid-workout Swap asks [Just today] [Update my plan]; Flow 1 step 4 swap-don't-interrogate (3–5 alternatives that do
// the same job). "Just today" rewrites this session's snapshot only (running sessions are snapshots); "Update my plan" also
// replaces the exercise in the plan's workout for this weekday, forward-only (Flow 8), through PlanLocal + a putPlan op.
// Plain helpers of the Session feature (5.6.6; the SessionModel map names no swap — E7 does). Twin of web SessionSwap.tsx.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation

enum SwapScope {
    case today, plan
}

@MainActor
enum SessionSwap {
    // The access tier is read off the gear in the session (the snapshot carries no answers), like the plan editor does
    static func access(for exercises: [LocalSessionExercise]) -> String {
        let gear = Set(exercises.map(\.equipment))
        if !gear.isDisjoint(with: ["barbell", "machine", "cable"]) { return "fullGym" }
        return gear.contains("dumbbell") ? "dumbbells" : "bodyweight"
    }

    static func candidates(for exercise: LocalSessionExercise, in session: LocalSession, seed: SeedCatalog = .shared) -> [SeedExercise] {
        guard let incumbent = seed.exercise(exercise.exerciseId) else { return [] }
        return SwapFinder.swapCandidates(for: incumbent, access: access(for: session.exercises), experience: "experienced", seed: seed)
    }

    static func swap(_ exercise: LocalSessionExercise, in session: LocalSession, with replacement: SeedExercise, scope: SwapScope, store: Store, now: Date = Date()) throws {
        let previousId = exercise.exerciseId
        exercise.exerciseId = replacement.id
        exercise.name = replacement.name
        exercise.equipment = replacement.equipment
        session.updatedAt = now
        try store.save()
        try SyncQueue.shared.enqueue(.patchSession, payload: PatchSessionPayload(sessionId: session.clientId, timezone: session.timezone, exercises: SessionActions.exerciseDTOs(session), status: nil, completedAt: nil, post: nil), now: now)
        guard scope == .plan else { return }
        try updatePlan(userId: session.userId, weekday: DayKey.isoWeekday(session.dayKey), previousId: previousId, replacement: replacement, store: store, now: now)
    }

    // Flow 8: the plan's workout for this weekday gets the same replacement; other days untouched; applies forward
    private static func updatePlan(userId: String, weekday: Int, previousId: String, replacement: SeedExercise, store: Store, now: Date) throws {
        guard let plan = try store.plan(for: userId) else { return }
        let workouts = PlanModel.draftWorkouts(plan).map { workout -> PlanDraftWorkout in
            guard workout.weekday == weekday else { return workout }
            return PlanDraftWorkout(weekday: workout.weekday, name: workout.name, kind: workout.kind, exercises: workout.exercises.map { row in
                guard row.exerciseId == previousId else { return row }
                return PlanDraftExercise(exerciseId: replacement.id, name: replacement.name, pattern: replacement.pattern, equipment: replacement.equipment, type: row.type, targetSets: row.targetSets, targetReps: row.targetReps, targetRepsMax: row.targetRepsMax, holdSeconds: row.holdSeconds, perSide: row.perSide, order: row.order)
            })
        }
        try PlanLocal.replace(workouts, userId: userId, updatedAt: now, store: store)
        try SyncQueue.shared.enqueue(.putPlan, payload: PutPlanRequestDTO(workouts: workouts), now: now)
    }
}
