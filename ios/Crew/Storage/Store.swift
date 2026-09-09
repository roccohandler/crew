// SPEC: 5.2 Storage/Store.swift — the SwiftData container + typed fetch functions · C3 (Store.shared) · C4 (tests use
// an in-memory container: Store(inMemory: true)). Plain functions, no repository layer (C2). WRITTEN — UNVERIFIED.

import Foundation
import SwiftData

@MainActor
final class Store {
    static let shared = Store(inMemory: false)

    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    init(inMemory: Bool) {
        let schema = Schema([
            LocalPlan.self, LocalWorkoutTemplate.self, LocalExerciseTemplate.self,
            LocalSession.self, LocalSessionExercise.self, LocalSetLog.self,
            LocalPost.self, LocalGamificationState.self, LocalPause.self, LocalCrewSnapshot.self,
            OpRecord.self,
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("SwiftData container failed: \(error)")
        }
    }

    func save() throws {
        if context.hasChanges { try context.save() }
    }

    // MARK: Typed fetches (one per question a model asks)

    func plan(for userId: String) throws -> LocalPlan? {
        var descriptor = FetchDescriptor<LocalPlan>(predicate: #Predicate { $0.userId == userId })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func gamificationState(for userId: String) throws -> LocalGamificationState {
        var descriptor = FetchDescriptor<LocalGamificationState>(predicate: #Predicate { $0.userId == userId })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first { return existing }
        let fresh = LocalGamificationState(userId: userId)
        context.insert(fresh)
        return fresh
    }

    func openSession(for userId: String) throws -> LocalSession? {
        let inProgress = "inProgress"
        var descriptor = FetchDescriptor<LocalSession>(predicate: #Predicate { $0.userId == userId && $0.status == inProgress }, sortBy: [SortDescriptor(\.startedAt, order: .reverse)])
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func sessions(for userId: String, dayKey: String) throws -> [LocalSession] {
        try context.fetch(FetchDescriptor<LocalSession>(predicate: #Predicate { $0.userId == userId && $0.dayKey == dayKey }))
    }

    // SPEC: A1 — the history the rotation pointer is derived from: completed sessions, latest first
    func completedSessions(for userId: String) throws -> [LocalSession] {
        let completed = "completed"
        return try context.fetch(FetchDescriptor<LocalSession>(predicate: #Predicate { $0.userId == userId && $0.status == completed }, sortBy: [SortDescriptor(\.completedAt, order: .reverse)]))
    }

    // SPEC: A1 — the last completed rotation workout's kind (nil before the first one); a cardio log or a custom kind outside
    // the cycle never counts, a legacy row infers its kind from its name (PlanRotation)
    func lastCompletedRotationKind(for userId: String, cycle: [String]) throws -> String? {
        let history = try completedSessions(for: userId).map { RotationSession(kind: $0.workoutKind, name: $0.workoutName, completedAt: $0.completedAt, status: $0.status) }
        return PlanRotation.lastRotationKind(sessions: history, cycle: cycle)
    }

    func posts(for userId: String, dayKey: String) throws -> [LocalPost] {
        try context.fetch(FetchDescriptor<LocalPost>(predicate: #Predicate { $0.userId == userId && $0.dayKey == dayKey && $0.deletedAt == nil }, sortBy: [SortDescriptor(\.createdAt)]))
    }

    func allPosts(for userId: String) throws -> [LocalPost] {
        try context.fetch(FetchDescriptor<LocalPost>(predicate: #Predicate { $0.userId == userId && $0.deletedAt == nil }, sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
    }

    func activePause(for userId: String, today: String) throws -> LocalPause? {
        var descriptor = FetchDescriptor<LocalPause>(predicate: #Predicate { $0.userId == userId && $0.endDay > today }, sortBy: [SortDescriptor(\.startDay)])
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func crewSnapshot() throws -> LocalCrewSnapshot? {
        var descriptor = FetchDescriptor<LocalCrewSnapshot>(sortBy: [SortDescriptor(\.syncedAt, order: .reverse)])
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func pendingOps() throws -> [OpRecord] {
        let pending = "pending"
        return try context.fetch(FetchDescriptor<OpRecord>(predicate: #Predicate { $0.state == pending }, sortBy: [SortDescriptor(\.createdAt)]))
    }

    // ServerHydrate: a row that already exists on the phone (by its client id) is never written twice
    func post(clientId: String) throws -> LocalPost? {
        var descriptor = FetchDescriptor<LocalPost>(predicate: #Predicate { $0.clientId == clientId })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func session(clientId: String) throws -> LocalSession? {
        var descriptor = FetchDescriptor<LocalSession>(predicate: #Predicate { $0.clientId == clientId })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
