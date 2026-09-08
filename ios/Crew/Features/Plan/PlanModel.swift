// SPEC: 5.6.2 PlanModel — state: week: [DaySlot]; actions: swap · adjust · reorder · add · remove (undo always) · rebuild (the
// questions again) · save. S14: Mon–Sun at a glance; tiered editing (swap / tune / full); limits enforced by input constraints
// (≤ 15 exercises/day, ≤ 20 sets/exercise — G3); everything applies forward, history never rewrites (Flow 8). Optimistic: the
// phone's plan is replaced first (PlanLocal), the server follows through the queue (E6). WRITTEN — UNVERIFIED (needs Mac).
// The ledger names no iOS task for S14 (the web half is T038); written in the T042 session — see ratification R-034.

import Foundation
import Observation

struct DaySlot: Equatable, Identifiable {
    let weekday: Int
    let workout: PlanDraftWorkout?
    var id: Int { weekday }
}

@Observable
@MainActor
final class PlanModel {
    var week: [DaySlot] = []
    var workouts: [PlanDraftWorkout] = []
    var previous: [PlanDraftWorkout]?   // Flow 8: undo always — one step back
    var savedLine: String?
    var errorLine: String?
    var hasPlan = false

    private let store: Store
    private let userId: String
    private let seed: SeedCatalog
    private let syncQueue: SyncQueue?

    init(store: Store = .shared, userId: String? = nil, seed: SeedCatalog = .shared, syncQueue: SyncQueue? = nil) {
        self.store = store
        self.userId = userId ?? AuthStore.shared.currentUser?.id ?? "local"
        self.seed = seed
        self.syncQueue = syncQueue
    }

    func load() {
        do {
            let plan = try store.plan(for: userId)
            hasPlan = plan != nil
            workouts = plan.map(Self.draftWorkouts) ?? []
            previous = nil
            rebuildWeek()
            errorLine = nil
        } catch {
            errorLine = AppError.storage("plan").userLine
        }
    }

    static func draftWorkouts(_ plan: LocalPlan) -> [PlanDraftWorkout] {
        plan.workouts.sorted { $0.weekday < $1.weekday }.map { workout in
            PlanDraftWorkout(weekday: workout.weekday, name: workout.name, kind: workout.kind, exercises: workout.exercises.sorted { $0.order < $1.order }.map { row in
                PlanDraftExercise(exerciseId: row.exerciseId, name: row.name, pattern: row.pattern, equipment: row.equipment, type: row.type, targetSets: row.targetSets, targetReps: row.targetReps, targetRepsMax: row.targetRepsMax, holdSeconds: row.holdSeconds, perSide: row.perSide, order: row.order)
            })
        }
    }

    // The access tier a day was built for is read off its gear — the plan stores no answers (Part IX Plan)
    static func access(for workout: PlanDraftWorkout) -> String {
        let gear = Set(workout.exercises.map(\.equipment))
        if !gear.isDisjoint(with: ["barbell", "machine", "cable"]) { return "fullGym" }
        return gear.contains("dumbbell") ? "dumbbells" : "bodyweight"
    }

    private func rebuildWeek() {
        week = (1...TimeUnits.daysPerWeek).map { weekday in DaySlot(weekday: weekday, workout: workouts.first { $0.weekday == weekday }) }
    }

    private func edit(_ weekday: Int, _ change: (PlanDraftWorkout) -> PlanDraftWorkout) {
        previous = workouts
        savedLine = nil
        workouts = workouts.map { $0.weekday == weekday ? change($0) : $0 }
        rebuildWeek()
    }

    private static func renumbered(_ workout: PlanDraftWorkout, _ rows: [PlanDraftExercise]) -> PlanDraftWorkout {
        let ordered = rows.enumerated().map { index, row in
            PlanDraftExercise(exerciseId: row.exerciseId, name: row.name, pattern: row.pattern, equipment: row.equipment, type: row.type, targetSets: row.targetSets, targetReps: row.targetReps, targetRepsMax: row.targetRepsMax, holdSeconds: row.holdSeconds, perSide: row.perSide, order: index)
        }
        return PlanDraftWorkout(weekday: workout.weekday, name: workout.name, kind: workout.kind, exercises: ordered)
    }

    func undo() {
        guard let previous else { return }
        workouts = previous
        self.previous = nil
        rebuildWeek()
    }

    func swapCandidates(for exerciseId: String, in weekday: Int) -> [SeedExercise] {
        guard let workout = workouts.first(where: { $0.weekday == weekday }), let incumbent = seed.exercise(exerciseId) else { return [] }
        return SwapFinder.swapCandidates(for: incumbent, access: Self.access(for: workout), experience: "experienced", seed: seed)
    }

    // Flow 8 swap keeps the row's targets: the job changes, the volume doesn't
    func swap(exerciseId: String, in weekday: Int, with replacement: SeedExercise) {
        edit(weekday) { workout in
            Self.renumbered(workout, workout.exercises.map { row in
                guard row.exerciseId == exerciseId else { return row }
                return PlanDraftExercise(exerciseId: replacement.id, name: replacement.name, pattern: replacement.pattern, equipment: replacement.equipment, type: row.type, targetSets: row.targetSets, targetReps: row.targetReps, targetRepsMax: row.targetRepsMax, holdSeconds: row.holdSeconds, perSide: row.perSide, order: row.order)
            })
        }
    }

    // G3: 1…planMaxSetsPerExercise sets; reps ≥ 1 — invalid states are unreachable, not rejected
    func adjust(exerciseId: String, in weekday: Int, setsBy setsDelta: Int = 0, repsBy repsDelta: Int = 0) {
        edit(weekday) { workout in
            Self.renumbered(workout, workout.exercises.map { row in
                guard row.exerciseId == exerciseId else { return row }
                let sets = min(SpecConstants.planMaxSetsPerExercise, max(1, row.targetSets + setsDelta))
                let reps = max(1, row.targetReps + repsDelta)
                return PlanDraftExercise(exerciseId: row.exerciseId, name: row.name, pattern: row.pattern, equipment: row.equipment, type: row.type, targetSets: sets, targetReps: reps, targetRepsMax: row.targetRepsMax.map { max($0, reps) }, holdSeconds: row.holdSeconds, perSide: row.perSide, order: row.order)
            })
        }
    }

    func reorder(exerciseId: String, in weekday: Int, direction: Int) {
        edit(weekday) { workout in
            var rows = workout.exercises
            guard let from = rows.firstIndex(where: { $0.exerciseId == exerciseId }) else { return workout }
            let to = from + direction
            guard rows.indices.contains(to) else { return workout }
            rows.swapAt(from, to)
            return Self.renumbered(workout, rows)
        }
    }

    func remove(exerciseId: String, in weekday: Int) {
        edit(weekday) { workout in Self.renumbered(workout, workout.exercises.filter { $0.exerciseId != exerciseId }) }
    }

    func addCandidates(for weekday: Int) -> [SeedExercise] {
        guard let workout = workouts.first(where: { $0.weekday == weekday }) else { return [] }
        let present = Set(workout.exercises.map(\.exerciseId))
        let allowed: Set<String> = Self.access(for: workout) == "fullGym" ? ["barbell", "machine", "cable", "dumbbell", "bodyweight"] : (Self.access(for: workout) == "dumbbells" ? ["dumbbell", "bodyweight"] : ["bodyweight"])
        return seed.exercises.filter { $0.type == "strength" && allowed.contains($0.equipment) && !present.contains($0.id) }
    }

    func add(_ exercise: SeedExercise, to weekday: Int) {
        edit(weekday) { workout in
            guard workout.exercises.count < SpecConstants.planMaxExercisesPerDay else { return workout }
            let targets = workout.exercises.first { $0.type == "strength" }
            let fallback = seed.planTemplates.targets["some"]
            let row = PlanDraftExercise(exerciseId: exercise.id, name: exercise.name, pattern: exercise.pattern, equipment: exercise.equipment, type: "strength", targetSets: targets?.targetSets ?? fallback?.sets ?? 1, targetReps: targets?.targetReps ?? fallback?.reps ?? 1, targetRepsMax: targets?.targetRepsMax ?? fallback?.repsMax, holdSeconds: nil, perSide: nil, order: workout.exercises.count)
            let strength = workout.exercises.filter { $0.type == "strength" } + [row]
            return Self.renumbered(workout, strength + workout.exercises.filter { $0.type == "mobility" })
        }
    }

    // Forward-only: the phone's plan is replaced now, the server's through the queue; running sessions keep their snapshot (E7)
    func save(now: Date = Date()) {
        do {
            try PlanLocal.replace(workouts, userId: userId, updatedAt: now, store: store)
            try (syncQueue ?? SyncQueue.shared).enqueue(.putPlan, payload: PutPlanRequestDTO(workouts: workouts), now: now)
            previous = nil
            savedLine = "Saved. Changes apply from your next workout on — history never rewrites."
        } catch {
            errorLine = AppError.storage("plan").userLine
        }
    }
}
