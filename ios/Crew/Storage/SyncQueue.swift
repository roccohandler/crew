// SPEC: 5.6.3 SyncQueue — the one concrete mechanism: OpRecord @Model · enqueue · processNext (FIFO, backoff
// 1s·2s·4s·8s·16s then .held) · reconcile (gamification: server state REPLACES local, silently — unless a counted post is
// still undelivered, A3/E19) · heldOver24h → UserChoice (E19). E6 offline-first; 8.3 retry/backoff, poison-message handling,
// ordering. The transport is a plain function passed at init (C3: concrete, no protocol) so tests use an in-memory container
// and a test-provided sender (C4: no mocks, no mocking frameworks). The delivered half (E19: counted vs delivered are separate
// facts) is SyncDelivery.swift; the moments the queue runs are SyncDriver.swift. WRITTEN — UNVERIFIED (needs Mac). T014

import Foundation
import SwiftData

enum OpKind: String, Codable, CaseIterable {
    case createSession, patchSession, createPost, deletePost, sendMessage, react, unreact, putPlan, pause, pushToken
}

enum OpState: String {
    case pending, inFlight, held
}

@Model
final class OpRecord {
    @Attribute(.unique) var id: String
    var kind: String
    var payload: Data
    var createdAt: Date
    var attempts: Int
    var state: String
    var nextAttemptAt: Date
    var lastError: String?

    init(id: String, kind: OpKind, payload: Data, createdAt: Date) {
        self.id = id
        self.kind = kind.rawValue
        self.payload = payload
        self.createdAt = createdAt
        self.attempts = 0
        self.state = OpState.pending.rawValue
        self.nextAttemptAt = createdAt
        self.lastError = nil
    }
}

enum UserChoice {
    case retry, postWithoutPhoto, delete
}

enum ProcessOutcome: Equatable {
    case idle                        // nothing pending
    case waiting(until: Date)        // the head op's backoff has not elapsed — FIFO: nothing behind it goes first
    case offline                     // no network: the head op waits as it is (E6 — offline is not a failed attempt)
    case signedOut                   // no session (1C: the refresh token died): the op waits for the next sign-in, untouched
    case sent(opId: String)
    case retryScheduled(opId: String, attempt: Int)
    case held(opId: String)
}

@MainActor
final class SyncQueue {
    static let shared = SyncQueue(store: Store.shared, send: SyncTransport.send, autoDrain: true)

    let store: Store
    var isDraining = false           // one drain pass at a time (SyncDriver.swift)
    private let send: (SyncOpDTO) async throws -> SyncResponseDTO
    private let autoDrain: Bool      // the app's queue goes out after every enqueue; a test's queue is stepped by hand

    init(store: Store, send: @escaping (SyncOpDTO) async throws -> SyncResponseDTO, autoDrain: Bool = false) {
        self.store = store
        self.send = send
        self.autoDrain = autoDrain
    }

    func enqueue(_ kind: OpKind, payload: some Encodable, now: Date = Date()) throws {
        let record = OpRecord(id: UUID().uuidString, kind: kind, payload: try JSONEncoder.crew.encode(payload), createdAt: now)
        store.context.insert(record)
        try store.save()
        if autoDrain { Task { await drain() } } // E6: what was just logged goes out now if it can
    }

    // SPEC: 5.6.3 — FIFO: the oldest pending op goes next and, while its backoff runs, nothing behind it overtakes it (8.3
    // ordering — createSession before patchSession, always); held ops never block the line; offline leaves the op untouched
    func processNext(now: Date = Date()) async -> ProcessOutcome {
        guard let record = try? nextPending() else { return .idle }
        if record.nextAttemptAt > now { return .waiting(until: record.nextAttemptAt) }
        record.state = OpState.inFlight.rawValue
        do {
            let response = try await send(SyncOpDTO(opId: record.id, kind: record.kind, payload: try JSONValue.from(record.payload)))
            let outcome = settle(record, response: response, now: now) // the op's own fate first: the reconcile guard reads the queue after it
            try reconcile(response)
            return outcome
        } catch AppError.offline {
            record.state = OpState.pending.rawValue // E6: no attempt is counted — the op waits for the network exactly as it was
            try? store.save()
            return .offline
        } catch AppError.unauthorized {
            record.state = OpState.pending.rawValue // not the op's fault either: it goes out after the next sign-in (validAccessToken signed out)
            try? store.save()
            return .signedOut
        } catch let error as AppError {
            if case .server(_, let message, let status) = error, HttpStatus.badRequest..<HttpStatus.tooManyRequests ~= status {
                return hold(record, error: message) // poison: the server will never accept it
            }
            return schedule(record, error: error.userLine, now: now)
        } catch {
            return schedule(record, error: error.localizedDescription, now: now)
        }
    }

    // SPEC: 5.6.3 · A3 (2026-09-08) — the server answered: ok → delivered (the post it carried is stamped, the op leaves the
    // queue); ok:false, retryable:false → held (poison, E19's choice later); ok:false, retryable:true → the ordinary backoff,
    // never deleted (the server may accept it next time)
    private func settle(_ record: OpRecord, response: SyncResponseDTO, now: Date) -> ProcessOutcome {
        if let result = response.results.first(where: { $0.opId == record.id }), !result.ok {
            if result.retryable == false { return hold(record, error: result.error ?? "rejected") }
            return schedule(record, error: result.error ?? "rejected", now: now)
        }
        try? markDelivered(record, now: now)
        store.context.delete(record)
        try? store.save()
        return .sent(opId: record.id)
    }

    // SPEC: 5.6.3 — gamification: server state REPLACES local, silently (server recompute overrides divergence) — except while a
    // counted post is still on its way (A3, 2026-09-08: E19 wins over 5.6.3 while undelivered post ops exist; the server has not
    // seen that post yet, so its lower streak is not the truth this phone judged from)
    func reconcile(_ response: SyncResponseDTO) throws {
        guard let serverState = response.gamification, let userId = AuthStore.shared.currentUser?.id else { return }
        guard try !hasUndeliveredPostOps() else { return }
        let local = try store.gamificationState(for: userId)
        local.currentStreak = serverState.currentStreak
        local.longestStreak = serverState.longestStreak
        local.totalXP = serverState.totalXP
        local.level = serverState.level
        local.shields = serverState.shields
        local.lastCountedDayKey = serverState.lastCountedDayKey
        local.earnedAchievementIds = serverState.earnedAchievementIds
        local.updatedAt = Date()
        try store.save()
    }

    // SPEC: E19 — after ~24 h a held op needs the user's choice: Retry · Post without photo · Delete
    func heldOver24h(now: Date = Date()) throws -> [OpRecord] {
        let held = OpState.held.rawValue
        let cutoff = now.addingTimeInterval(-TimeInterval(SpecConstants.failedUploadChoiceAfterHours * TimeUnits.secondsPerHour))
        return try store.context.fetch(FetchDescriptor<OpRecord>(predicate: #Predicate { $0.state == held && $0.createdAt < cutoff }, sortBy: [SortDescriptor(\.createdAt)]))
    }

    func resolve(_ record: OpRecord, choice: UserChoice, now: Date = Date()) throws {
        switch choice {
        case .retry:
            record.state = OpState.pending.rawValue
            record.attempts = 0
            record.nextAttemptAt = now
        case .postWithoutPhoto:
            record.payload = try PostPayloadPhotoStripper.strip(record.payload)
            record.state = OpState.pending.rawValue
            record.attempts = 0
            record.nextAttemptAt = now
        case .delete:
            store.context.delete(record)
        }
        try store.save()
    }

    private func nextPending() throws -> OpRecord? {
        let pending = OpState.pending.rawValue
        var descriptor = FetchDescriptor<OpRecord>(predicate: #Predicate { $0.state == pending }, sortBy: [SortDescriptor(\.createdAt)])
        descriptor.fetchLimit = 1
        return try store.context.fetch(descriptor).first
    }

    private func schedule(_ record: OpRecord, error: String, now: Date) -> ProcessOutcome {
        record.attempts += 1
        record.lastError = error
        if record.attempts >= SpecConstants.syncMaxAttemptsBeforeHeld { return hold(record, error: error) }
        let backoffSeconds = SpecConstants.syncBackoffSeconds[record.attempts - 1]
        record.nextAttemptAt = now.addingTimeInterval(TimeInterval(backoffSeconds))
        record.state = OpState.pending.rawValue
        try? store.save()
        return .retryScheduled(opId: record.id, attempt: record.attempts)
    }

    private func hold(_ record: OpRecord, error: String) -> ProcessOutcome {
        record.state = OpState.held.rawValue
        record.lastError = error
        try? store.save()
        return .held(opId: record.id)
    }
}
