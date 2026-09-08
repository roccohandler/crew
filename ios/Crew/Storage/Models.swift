// SPEC: 5.2 Storage/Models.swift — @Model classes mirroring Part IX (Plan → WorkoutTemplate → ExerciseTemplate;
// Session → SessionExercise → SetLog). Local truth for the offline-first loop (E6). Social + gamification models
// are in ModelsSocial.swift (C9 cap). Every optional mirrors Part IX's `?`. WRITTEN — UNVERIFIED (needs Mac).

import Foundation
import SwiftData

@Model
final class LocalPlan {
    @Attribute(.unique) var userId: String
    var updatedAt: Date
    @Relationship(deleteRule: .cascade) var workouts: [LocalWorkoutTemplate]

    init(userId: String, updatedAt: Date, workouts: [LocalWorkoutTemplate]) {
        self.userId = userId
        self.updatedAt = updatedAt
        self.workouts = workouts
    }
}

@Model
final class LocalWorkoutTemplate {
    var weekday: Int          // ISO 1 = Monday … 7 = Sunday (E20)
    var name: String
    var kind: String          // push | pull | legs | fullBodyA | fullBodyB | custom
    @Relationship(deleteRule: .cascade) var exercises: [LocalExerciseTemplate]

    init(weekday: Int, name: String, kind: String, exercises: [LocalExerciseTemplate]) {
        self.weekday = weekday
        self.name = name
        self.kind = kind
        self.exercises = exercises
    }
}

@Model
final class LocalExerciseTemplate {
    var exerciseId: String
    var name: String
    var pattern: String
    var equipment: String
    var type: String          // strength | mobility
    var targetSets: Int
    var targetReps: Int
    var targetRepsMax: Int?
    var targetWeight: Double?
    var holdSeconds: Int?
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
    var isPlannedDay: Bool                       // snapshot — immune to later plan edits
    var startedAt: Date
    var completedAt: Date?
    var timezone: String
    var updatedAt: Date
    var syncedAt: Date?
    @Relationship(deleteRule: .cascade) var exercises: [LocalSessionExercise]

    init(clientId: String, userId: String, dayKey: String, status: String, workoutName: String, isPlannedDay: Bool, startedAt: Date, timezone: String, exercises: [LocalSessionExercise]) {
        self.clientId = clientId
        self.userId = userId
        self.dayKey = dayKey
        self.status = status
        self.workoutName = workoutName
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
    var type: String
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
    var isWarmup: Bool
    var done: Bool
    var asPlanned: Bool

    init(order: Int, targetReps: Int, actualReps: Int, weight: Double?, holdSeconds: Int?, isWarmup: Bool) {
        self.order = order
        self.targetReps = targetReps
        self.actualReps = actualReps
        self.weight = weight
        self.holdSeconds = holdSeconds
        self.isWarmup = isWarmup
        self.done = false
        self.asPlanned = false
    }
}
