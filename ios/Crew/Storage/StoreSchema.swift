// SPEC: W9 (owner order 2026-09-18, item 6) · docs/debt.md ("no SwiftData migration in the beta"; "LocalPost keeps four legacy
// stored properties"; "four @Model classes joined the schema without a migration plan") · 1C · S01 · E6 — THE STORE HAS VERSIONS NOW.
// V1 is the schema TestFlight build 150 shipped: eleven models, and a LocalPost that still carried the plate journal's four stored
// properties (photoKey · localPhotoPath · mealTag · earlierToday — nothing has written them since A22, 2026-09-18). V2 is today: the
// same models, LocalPost without those four, plus the four nutrition models (W8). V1 → V2 is a LIGHTWEIGHT stage — entities added,
// attributes removed, nothing renamed and nothing re-typed — so SwiftData performs it on its own and the phone keeps its plan, its
// sessions, its queued ops and its journal across the update.
//
// WHAT HAPPENS WHEN A STORE MATCHES NO VERSION (a build older than 150, whose schema this plan has never seen): ModelContainer throws,
// and Store.init's F31 path does what it has always done — it starts the store over and the server refills it (1C: the phone is not the
// source of truth). The migration plan makes the COMMON update lossless; it does not remove the safety net under the uncommon one.
//
// V1's LocalPost is a NESTED class with the same name — SwiftData names an entity after its class, so the nested copy IS the old
// entity, property for property. It exists only so the plan can recognise an old store; nothing in the app constructs it.
// A future change to any model: copy the changed class into a new CrewSchemaV3 the same way and add one stage. Never edit V1 or V2.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation
import SwiftData

enum CrewSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            LocalPlan.self, LocalWorkoutTemplate.self, LocalExerciseTemplate.self,
            LocalSession.self, LocalSessionExercise.self, LocalSetLog.self,
            CrewSchemaV1.LocalPost.self, LocalGamificationState.self, LocalPause.self, LocalCrewSnapshot.self,
            OpRecord.self,
        ]
    }

    // The plate-journal-era post, exactly as build 150 stored it (ModelsSocial.swift at 016721f)
    @Model
    final class LocalPost {
        @Attribute(.unique) var clientId: String
        var serverId: String?
        var userId: String
        var type: String
        var sessionClientId: String?
        var photoKey: String?
        var localPhotoPath: String?
        var caption: String
        var mealTag: String?
        var shareToCrew: Bool
        var dayKey: String
        var isPlannedDay: Bool
        var workoutCompleted: Bool
        var earlierToday: Bool
        var summary: String?
        var createdAt: Date
        var deliveredAt: Date?
        var deletedAt: Date?

        init(clientId: String, userId: String, type: String, caption: String, shareToCrew: Bool, dayKey: String, isPlannedDay: Bool, workoutCompleted: Bool, earlierToday: Bool, createdAt: Date) {
            self.clientId = clientId
            self.userId = userId
            self.type = type
            self.caption = caption
            self.shareToCrew = shareToCrew
            self.dayKey = dayKey
            self.isPlannedDay = isPlannedDay
            self.workoutCompleted = workoutCompleted
            self.earlierToday = earlierToday
            self.createdAt = createdAt
        }
    }
}

enum CrewSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(SpecConstants.storeSchemaVersion, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            LocalPlan.self, LocalWorkoutTemplate.self, LocalExerciseTemplate.self,
            LocalSession.self, LocalSessionExercise.self, LocalSetLog.self,
            LocalPost.self, LocalGamificationState.self, LocalPause.self, LocalCrewSnapshot.self,
            LocalNutritionTargets.self, LocalSavedMeal.self, LocalDayTemplate.self, LocalMealLog.self, // W8 (nutrition addendum §2)
            OpRecord.self,
        ]
    }
}

enum CrewMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [CrewSchemaV1.self, CrewSchemaV2.self] }

    // Entities added and attributes removed: SwiftData can do this without a custom step
    static var stages: [MigrationStage] { [.lightweight(fromVersion: CrewSchemaV1.self, toVersion: CrewSchemaV2.self)] }
}
