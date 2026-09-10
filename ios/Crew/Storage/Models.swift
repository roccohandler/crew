// SPEC: 5.2 Storage/Models.swift — @Model classes mirroring Part IX (Plan → WorkoutTemplate → ExerciseTemplate;
// Session → SessionExercise → SetLog). Local truth for the offline-first loop (E6). Social + gamification models
// are in ModelsSocial.swift (C9 cap). Every optional mirrors Part IX's `?`. A1 (owner-directed 2026-09-08): a plan is
// trainingWeekdays plus an ORDERED list of workouts — no weekday on a workout. A2: a session knows its kind, a set its
// distance. The beta phone reinstalls; no SwiftData migration is written (debt.md). WRITTEN — UNVERIFIED (needs Mac).

import Foundation
import SwiftData

@Model
final class LocalPlan {
    @Attribute(.unique) var userId: String
    var trainingWeekdays: [Int]   // ISO 1 = Monday … 7 = Sunday (E20), sorted and unique (A1)
    var updatedAt: Date
    @Relationship(deleteRule: .cascade) var workouts: [LocalWorkoutTemplate]

    init(userId: String, trainingWeekdays: [Int], updatedAt: Date, workouts: [LocalWorkoutTemplate]) {
        self.userId = userId
        self.trainingWeekdays = trainingWeekdays
        self.updatedAt = updatedAt
        self.workouts = workouts
    }
}

// SPEC: A1 — the rotation order is the stored order; a SwiftData to-many relationship keeps no order of its own, so
// each workout carries its position (PlanLocal writes it, PlanLocal.draft reads the list back sorted by it)
@Model
final class LocalWorkoutTemplate {
    var name: String
    var kind: String          // push | pull | legs | fullBodyA | fullBodyB | custom
    var order: Int
    @Relationship(deleteRule: .cascade) var exercises: [LocalExerciseTemplate]

    init(name: String, kind: String, order: Int, exercises: [LocalExerciseTemplate]) {
        self.name = name
        self.kind = kind
        self.order = order
        self.exercises = exercises
    }
}

@Model
final class LocalExerciseTemplate {
    var exerciseId: String
    var name: String
    var pattern: String
    var equipment: String
    var type: String          // strength | mobility | cardio (A2)
    var targetSets: Int
    var targetReps: Int
    var targetRepsMax: Int?
    var targetWeight: Double?
    var holdSeconds: Int?     // mobility holds and cardio blocks: seconds
    var perSide: Bool
    var order: Int

    init(exerciseId: String, name: String, pattern: String, equipment: String, type: String, targetSets: Int, targetReps: Int, targetRepsMax: Int?, targetWeight: Double?, holdSeconds: Int?, perSide: Bool, order: Int) {
        self.exerciseId = exerciseId
        self.name = name
        self.pattern = pattern
        self.equipment = equipment
        self.type = type
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetRepsMax = targetRepsMax
        self.targetWeight = targetWeight
        self.holdSeconds = holdSeconds
        self.perSide = perSide
        self.order = order
    }
}

@Model
final class LocalSession {
    @Attribute(.unique) var clientId: String     // idempotency (8.2 ④)
    var userId: String
    var dayKey: String
    var status: String                           // inProgress | completed | discarded
    var workoutName: String
    var workoutKind: String?                     // the plan kind the snapshot ran (A1: the rotation pointer reads it); "cardio" for a log (A2); nil on legacy rows
    var isPlannedDay: Bool                       // snapshot — immune to later plan edits
    var startedAt: Date
    var completedAt: Date?
    var timezone: String
    var updatedAt: Date
    var syncedAt: Date?
    @Relationship(deleteRule: .cascade) var exercises: [LocalSessionExercise]

    init(clientId: String, userId: String, dayKey: String, status: String, workoutName: String, workoutKind: String?, isPlannedDay: Bool, startedAt: Date, timezone: String, exercises: [LocalSessionExercise]) {
        self.clientId = clientId
        self.userId = userId
        self.dayKey = dayKey
        self.status = status
        self.workoutName = workoutName
        self.workoutKind = workoutKind
        self.isPlannedDay = isPlannedDay
        self.startedAt = startedAt
        self.completedAt = nil
        self.timezone = timezone
        self.updatedAt = startedAt
        self.syncedAt = nil
        self.exercises = exercises
    }
}

@Model
final class LocalSessionExercise {
    var exerciseId: String
    var name: String
    var equipment: String
    var type: String                             // strength | mobility | cardio (A2)
    var targetSets: Int
    var targetReps: Int
    var holdSeconds: Int?
    var order: Int
    var skipped: Bool
    @Relationship(deleteRule: .cascade) var sets: [LocalSetLog]

    init(exerciseId: String, name: String, equipment: String, type: String, targetSets: Int, targetReps: Int, holdSeconds: Int?, order: Int, sets: [LocalSetLog]) {
        self.exerciseId = exerciseId
        self.name = name
        self.equipment = equipment
        self.type = type
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.holdSeconds = holdSeconds
        self.order = order
        self.skipped = false
        self.sets = sets
    }
}

@Model
final class LocalSetLog {
    var order: Int
    var targetReps: Int
    var actualReps: Int
    var weight: Double?
    var holdSeconds: Int?
    var distanceMeters: Int?                     // A2: a cardio set's optional distance, meters; nil everywhere else
    var weightUnit: String?                      // A9: the unit this weight was ENTERED in; nil on a row written before the split (read it through weightUnitOrLegacy)
    var isWarmup: Bool
    var done: Bool
    var asPlanned: Bool

    init(order: Int, targetReps: Int, actualReps: Int, weight: Double?, holdSeconds: Int?, isWarmup: Bool, weightUnit: String? = nil) {
        self.order = order
        self.targetReps = targetReps
        self.actualReps = actualReps
        self.weight = weight
        self.holdSeconds = holdSeconds
        self.distanceMeters = nil
        self.weightUnit = weightUnit
        self.isWarmup = isWarmup
        self.done = false
        self.asPlanned = false
    }
}
