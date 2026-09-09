// SPEC: E6 (offline-first; "reconnect → auto-send, silent reconcile") · 8.6 (post queued with chip · reconnect → auto-send ·
// kill mid-queue → nothing lost) · 5.6.3 — the moments the queue runs: launch (MainTabs), every enqueue (SyncQueue.enqueue),
// every foreground (CrewApp) and the network coming back (NWPathMonitor — Apple's Network framework, not a dependency).
// A3 (2026-09-08): foreground and network return first give a young held op another chance (SyncQueue.releaseHeldForRetry).
// A7 (2026-09-08): a real log out (CrewApp.resetState deletes the ops) — every moment the driver would run first checks
// AuthStore.shared.isSignedIn, so a signed-out phone never sends (D7: a later sign-in never replays the previous account's ops;
// MainTabs' .task calls start() again after the next sign-in and the recover + drain run for that account). The path monitor
// is started once per process: NWPathMonitor cannot be restarted after cancel. Plain functions (C2); one drain pass at a time.
// WRITTEN — UNVERIFIED (needs Mac). T014

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

    // Every signed-in first frame (MainTabs): recover, drain, then release-and-drain whenever the network returns
    static func start() {
        guard AuthStore.shared.isSignedIn else { return }
        try? SyncQueue.shared.recoverInFlight()
        if !started {
            started = true
            monitor.pathUpdateHandler = { path in
                guard path.status == .satisfied else { return }
                Task { @MainActor in await releaseAndDrain() }
            }
            monitor.start(queue: DispatchQueue(label: "com.yourteam.crew.sync-path"))
        }
        Task { await SyncQueue.shared.drain() }
    }

    // CrewApp: scenePhase → .active
    static func foreground() {
        guard started else { return }
        Task { await releaseAndDrain() }
    }

    // SPEC: A3 (2026-09-08) — a held op younger than the 24 h choice goes out again on these two moments; A7 — never signed out
    private static func releaseAndDrain() async {
        guard AuthStore.shared.isSignedIn else { return }
        try? SyncQueue.shared.releaseHeldForRetry()
        await SyncQueue.shared.drain()
    }
}
