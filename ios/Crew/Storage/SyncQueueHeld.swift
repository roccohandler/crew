// SPEC: E19 — a held op past the 24 h mark needs the user’s choice: Retry · Post without photo · Delete (FailedUploadSheet).
//
// Split from SyncQueue.swift for the C9 200-line cap, the way HomeModel+Edges.swift already splits HomeModel and
// SyncDelivery.swift already holds the delivered half. The file header of SyncQueue.swift names this half as E19’s, so
// this is where it lives rather than an arbitrary cut: the queue DELIVERS, this decides what happens to what it could not.
// WRITTEN — UNVERIFIED (needs Mac). T014

import Foundation
import SwiftData

extension SyncQueue {
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
}
