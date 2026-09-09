// SPEC: A4 (owner-directed 2026-09-08) · Flow 8 · S14 — one workout's editing draft: every mutation is a pure value change
// that keeps invalid states unreachable (1…planMaxSetsPerExercise sets, 1…planTargetRepsMax reps, cardioMinutesMin…Max
// minutes, ≤ planMaxExercisesPerDay rows, mobility always closes the workout), dirty until saved, one-step undo after a
// remove. Rows are addressed by `order` (unique inside a workout), never by exercise id. Plain struct (C14).
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation

struct RemovedRow: Equatable {
    let row: PlanDraftExercise
    let index: Int
}

struct WorkoutDraft: Equatable {
    let kind: String
    let name: String
    private(set) var exercises: [PlanDraftExercise]
    private(set) var removed: RemovedRow?
    private let saved: [PlanDraftExercise]

    init(workout: PlanDraftWorkout) {
        kind = workout.kind
        name = workout.name
        exercises = workout.exercises
        saved = workout.exercises
    }

    var isDirty: Bool { exercises != saved }
    var workout: PlanDraftWorkout { PlanDraftWorkout(name: name, kind: kind, exercises: exercises) }
    var rows: [PlanDraftExercise] { exercises.filter { $0.type != "mobility" } }   // the editable list: strength, then a cardio block
    var holds: [PlanDraftExercise] { exercises.filter { $0.type == "mobility" } }
    var strengthCount: Int { exercises.filter { $0.type == "strength" }.count }
    var hasCardio: Bool { exercises.contains { $0.type == "cardio" } }
    var isFull: Bool { exercises.count >= SpecConstants.planMaxExercisesPerDay }

    func row(order: Int) -> PlanDraftExercise? { exercises.first { $0.order == order } }

    // The access tier a workout was built for is read off its gear — the plan stores no answers (Part IX Plan)
    var access: String {
        let gear = Set(exercises.map(\.equipment))
        if !gear.isDisjoint(with: ["barbell", "machine", "cable"]) { return "fullGym" }
        return gear.contains("dumbbell") ? "dumbbells" : "bodyweight"
    }

    // SPEC: A4 — header `{n} exercises + mobility · ~{minutes} min`; ~ = strength sets × restTimerDefaultSeconds + hold
    // seconds (per-side holds run twice) + cardio seconds, rounded to the app's minute step
    var estimatedMinutes: Int {
        let seconds = exercises.reduce(0) { total, row in
            switch row.type {
            case "strength": return total + row.targetSets * SpecConstants.restTimerDefaultSeconds
            case "mobility": return total + (row.holdSeconds ?? 0) * ((row.perSide ?? false) ? SpecConstants.perSideHoldRepeats : 1)
            default: return total + (row.holdSeconds ?? 0)
            }
        }
        // SPEC: A4 — the estimate rounds to planEstimateRoundingMinutes
        let step = SpecConstants.planEstimateRoundingMinutes
        return Int((Double(seconds) / Double(TimeUnits.secondsPerMinute * step)).rounded()) * step
    }

    var headerLine: String { "\(strengthCount) exercises + mobility\(hasCardio ? " + cardio" : "") · ~\(estimatedMinutes) min" }

    var mobilityLine: String {
        let seconds = holds.reduce(0) { $0 + ($1.holdSeconds ?? 0) * (($1.perSide ?? false) ? SpecConstants.perSideHoldRepeats : 1) }
        return "Mobility · \(holds.count) holds · ~\(Int((Double(seconds) / Double(TimeUnits.secondsPerMinute)).rounded())) min · closes the workout"
    }

    // MARK: Mutations (each renumbers so `order` stays 0..<count with mobility last)

    // Flow 8 swap keeps the row's targets: the job changes, the volume doesn't
    mutating func swap(order: Int, with replacement: SeedExercise) {
        removed = nil
        exercises = Self.renumbered(exercises.map { $0.order == order ? Self.updated($0, exercise: replacement) : $0 })
    }

    // SPEC: G3 · A4 — sets 1…planMaxSetsPerExercise, reps 1…planTargetRepsMax (a rep range moves as a unit), cardio minutes
    // cardioMinutesMin…cardioMinutesMax — the stepper cannot reach an invalid value
    mutating func adjust(order: Int, setsBy setsDelta: Int = 0, repsBy repsDelta: Int = 0, minutesBy minutesDelta: Int = 0) {
        removed = nil
        exercises = Self.renumbered(exercises.map { row in
            guard row.order == order else { return row }
            if row.type == "cardio" {
                let minutes = (row.holdSeconds ?? 0) / TimeUnits.secondsPerMinute + minutesDelta
                let bounded = min(SpecConstants.cardioMinutesMax, max(SpecConstants.cardioMinutesMin, minutes))
                return Self.updated(row, holdSeconds: bounded * TimeUnits.secondsPerMinute)
            }
            let span = row.targetRepsMax.map { $0 - row.targetReps } ?? 0
            let sets = min(SpecConstants.planMaxSetsPerExercise, max(1, row.targetSets + setsDelta))
            let reps = min(SpecConstants.planTargetRepsMax - span, max(1, row.targetReps + repsDelta))
            return Self.updated(row, targetSets: sets, targetReps: reps)
        })
    }

    // Move up / Move down: one slot among the editable rows; returns the row's new order (nil at the edge)
    @discardableResult
    mutating func reorder(order: Int, direction: Int) -> Int? {
        var list = rows
        guard let from = list.firstIndex(where: { $0.order == order }), list.indices.contains(from + direction) else { return nil }
        list.swapAt(from, from + direction)
        removed = nil
        exercises = Self.renumbered(list + holds)
        return from + direction
    }

    // Reorder mode (EditButton + onMove) over the editable rows; mobility never moves
    mutating func move(from source: IndexSet, to destination: Int) {
        var list = rows
        list.move(fromOffsets: source, toOffset: destination)
        removed = nil
        exercises = Self.renumbered(list + holds)
    }

    // SPEC: A4 — Remove is one tap plus Undo, never a confirmation; the last row stays (the server requires ≥ 1)
    mutating func remove(order: Int) {
        guard exercises.count > 1, let index = exercises.firstIndex(where: { $0.order == order }) else { return }
        removed = RemovedRow(row: exercises[index], index: index)
        exercises = Self.renumbered(exercises.filter { $0.order != order })
    }

    mutating func undoRemove() {
        guard let removed else { return }
        var list = exercises
        list.insert(removed.row, at: min(removed.index, list.count))
        exercises = Self.renumbered(list)
        self.removed = nil
    }

    // A new strength row copies the workout's own targets (the plan stores no answers); it lands before any cardio block
    mutating func add(_ exercise: SeedExercise, seed: SeedCatalog) {
        guard !isFull else { return }
        let targets = exercises.first { $0.type == "strength" }
        let fallback = seed.planTemplates.targets["some"]
        let row = PlanDraftExercise(exerciseId: exercise.id, name: exercise.name, pattern: exercise.pattern, equipment: exercise.equipment, type: "strength", targetSets: targets?.targetSets ?? fallback?.sets ?? 1, targetReps: targets?.targetReps ?? fallback?.reps ?? 1, targetRepsMax: targets?.targetRepsMax ?? fallback?.repsMax, holdSeconds: nil, perSide: nil, order: exercises.count)
        removed = nil
        exercises = Self.renumbered(exercises.filter { $0.type == "strength" } + [row] + exercises.filter { $0.type == "cardio" } + holds)
    }

    // SPEC: A2 · A4 — one cardio block per workout, after the strength rows, before the mobility block
    mutating func addCardio(_ activity: SeedExercise, seed: SeedCatalog) {
        guard !isFull, !hasCardio, let row = PlanGenerator.cardioRow(activity.id, order: exercises.count, seed: seed) else { return }
        removed = nil
        exercises = Self.renumbered(rows + [row] + holds)
    }

    // MARK: Pickers

    func swapCandidates(order: Int, seed: SeedCatalog) -> [SeedExercise] {
        guard let row = row(order: order), let incumbent = seed.exercise(row.exerciseId) else { return [] }
        let present = Set(exercises.map(\.exerciseId))
        if row.type == "cardio" { return seed.exercises.filter { $0.type == "cardio" && $0.id != row.exerciseId } }
        return SwapFinder.swapCandidates(for: incumbent, access: access, experience: "experienced", seed: seed).filter { !present.contains($0.id) }
    }

    func addCandidates(seed: SeedCatalog) -> [SeedExercise] {
        let present = Set(exercises.map(\.exerciseId))
        let allowed = Set(seed.equipmentAccess[access] ?? [])
        return seed.exercises.filter { $0.type == "strength" && allowed.contains($0.equipment) && !present.contains($0.id) }
    }

    func cardioCandidates(seed: SeedCatalog) -> [SeedExercise] {
        seed.exercises.filter { $0.type == "cardio" }
    }

    // MARK: Row copies (PlanDraftExercise is immutable by design)

    private static func renumbered(_ list: [PlanDraftExercise]) -> [PlanDraftExercise] {
        list.enumerated().map { index, row in updated(row, order: index) }
    }

    private static func updated(_ row: PlanDraftExercise, exercise: SeedExercise? = nil, targetSets: Int? = nil, targetReps: Int? = nil, holdSeconds: Int? = nil, order: Int? = nil) -> PlanDraftExercise {
        let reps = targetReps ?? row.targetReps
        return PlanDraftExercise(exerciseId: exercise?.id ?? row.exerciseId, name: exercise?.name ?? row.name, pattern: exercise?.pattern ?? row.pattern, equipment: exercise?.equipment ?? row.equipment, type: row.type, targetSets: targetSets ?? row.targetSets, targetReps: reps, targetRepsMax: row.targetRepsMax.map { $0 + reps - row.targetReps }, holdSeconds: holdSeconds ?? row.holdSeconds, perSide: row.perSide, order: order ?? row.order)
    }
}
