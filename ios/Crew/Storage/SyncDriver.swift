// SPEC: E6 (offline-first; "reconnect → auto-send, silent reconcile") · 8.6 (post queued with chip · reconnect → auto-send ·
// kill mid-queue → nothing lost) · 5.6.3 — the moments the queue runs: launch (MainTabs), every enqueue (SyncQueue.enqueue),
// every foreground (CrewApp) and the network coming back (NWPathMonitor — Apple's Network framework, not a dependency).
// Plain functions (C2); one drain pass at a time. WRITTEN — UNVERIFIED (needs Mac). T014

import Foundation
import Network
import SwiftData

extension SyncQueue {
    // SPEC: 5.6.3 — one pass sends in order until nothing is pending: a backoff on the head is waited out here; offline ends
    // the pass, and the next moment (foreground, enqueue, network back) starts another
    func drain() async {
        guard !isDraining else { return }
        isDraining = true
        defer { isDraining = false }
        while !Task.isCancelled {
            switch await processNext() {
            case .idle, .offline, .signedOut: return
            case .sent, .held, .retryScheduled: continue
            case .waiting(let until): try? await Task.sleep(for: .seconds(max(0, until.timeIntervalSinceNow)))
            }
        }
    }

    // SPEC: 8.6 kill mid-queue → nothing lost: an op the last run left in flight goes back to pending before the first drain
    func recoverInFlight() throws {
        let inFlight = OpState.inFlight.rawValue
        for record in try store.context.fetch(FetchDescriptor<OpRecord>(predicate: #Predicate { $0.state == inFlight })) {
            record.state = OpState.pending.rawValue
        }
        try store.save()
    }
}

@MainActor
enum SyncDriver {
    private static let monitor = NWPathMonitor()
    private static var started = false

    // Once the user is signed in: recover, drain, then drain again whenever the network returns
    static func start() {
        guard !started else { return }
        started = true
        try? SyncQueue.shared.recoverInFlight()
        monitor.pathUpdateHandler = { path in
            guard path.status == .satisfied else { return }
            Task { @MainActor in await SyncQueue.shared.drain() }
        }
        monitor.start(queue: DispatchQueue(label: "com.yourteam.crew.sync-path"))
        Task { await SyncQueue.shared.drain() }
    }

    // CrewApp: scenePhase → .active
    static func foreground() {
        guard started else { return }
        Task { await SyncQueue.shared.drain() }
    }
}
