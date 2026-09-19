// SPEC: 1C (a Crew user authenticates ONCE per device — the Keychain outlives a reinstall, so a signed-in phone can wake with an
// empty Store) · 1D (the bridge persists until the first post EXISTS — the account's journal counts, not this phone's) · E6 (the
// phone holds the truth it judges from: plan, journal, sessions, gamification, crew) · 5.6.3 (gamification: server state
// REPLACES local). A signed-in phone whose Store holds neither a plan nor a post pulls everything once; a phone with any local
// truth pulls nothing here — the queue and the reconcile keep it current. OWNER-DIRECTED 2026-09-18 ("launch: real UI first"):
// the pull no longer gates any screen. Home draws at once from the Store; the four independent pulls (plan, journal, sessions,
// account) run IN PARALLEL and each landing bumps `state.revision`, which Home answers by re-reading the Store — the real screen
// fills progressively; the crew follows. `state.isPulling` is what Home reads to say "syncing" instead of "build your week" on an
// empty Store, and `state.failedOffline` is what turns that into a retryable line when the plan could not be reached at all
// (E6: offline is not a failure of the account). A1/A2/A6 (2026-09-08): the plan arrives with its trainingWeekdays (PlanLocal), a
// session with its workoutKind and set distances, a post with its summary line. Plain functions (C2) plus one @Observable state
// holder. WRITTEN — UNVERIFIED (needs Mac). T024 / T035 / T042

import Foundation
import Observation
import SwiftData

// The hydrate's three facts, published for Home (5.6.6: the screen reads them, decides nothing)
@Observable
@MainActor
final class HydrationState {
    var isPulling = false
    var failedOffline = false // the plan could not be reached at all — a retry line, never "build your week"
    var revision = 0          // bumps as each piece lands; Home re-reads the Store on every bump (progressive fill)
}

@MainActor
enum ServerHydrate {
    static let state = HydrationState()

    static func isEmpty(userId: String, store: Store) -> Bool {
        let hasPlan = (try? store.plan(for: userId)) != nil
        let hasPost = !((try? store.allPosts(for: userId)) ?? []).isEmpty
        return !hasPlan && !hasPost
    }

    // SPEC: owner-directed 2026-09-18 — background sync, progressive fill: the four independent pulls run at once; nothing waits on
    // anything else; the crew snapshot follows through the writer the Crew tab uses (6.1 offline: last-synced)
    static func pullIfEmpty(userId: String, store: Store) async {
        guard isEmpty(userId: userId, store: store), !state.isPulling else { return }
        state.isPulling = true
        state.failedOffline = false
        defer { state.isPulling = false }
        async let plan: Void = pullPlan(userId: userId, store: store)
        async let journal: Void = pullJournal(userId: userId, store: store)
        async let sessions: Void = pullSessions(userId: userId, store: store)
        async let account: Void = pullAccount(userId: userId, store: store)
        _ = await (plan, journal, sessions, account)
        await CrewModel(store: store).refresh()
        state.revision += 1
    }

    // The plan is the one pull whose failure Home must be able to name: offline → a retry line; a 404 (no plan on the server) or a
    // server fault → Home's real empty state, and the next foreground pulls again
    private static func pullPlan(userId: String, store: Store) async {
        do {
            let plan = try await Api.shared.getPlan()
            try? PlanLocal.replace(plan.draft, userId: userId, updatedAt: plan.updatedAt ?? Date(), history: plan.trainingDaysHistory, store: store)
        } catch AppError.offline {
            state.failedOffline = true
        } catch {}
        state.revision += 1
    }

    private static func pullJournal(userId: String, store: Store) async {
        if let journal = try? await Api.shared.myPosts() { try? writeJournal(journal.items, userId: userId, store: store) }
        state.revision += 1
    }

    private static func pullSessions(userId: String, store: Store) async {
        if let history = try? await Api.shared.mySessions() { try? writeSessions(history.items, userId: userId, store: store) }
        state.revision += 1
    }

    private static func pullAccount(userId: String, store: Store) async {
        if let me = try? await Api.shared.me() {
            try? replaceGamification(me.gamification, userId: userId, store: store)
            try? writePause(me.pause, userId: userId, store: store) // A20.10: `me` already carries it — no second request
        }
        state.revision += 1
    }

    // SPEC: A20.10 (2026-09-11) · Flow 7 — A PAUSE IS A SERVER FACT AND THE PHONE MUST BE ABLE TO LEARN IT.
    // `LocalPause` had exactly ONE writer in the whole app — SettingsModel.pause(until:) — and this file pulled every
    // other server truth (plan, journal, sessions, gamification, crew) and not this one. So a pause created on the web,
    // or any pause that predates a reinstall, never reached the Store: Settings read `me.pause` from the network and
    // said "Plan paused" while Home, which reads `store.activePause` and nothing else, rendered a training day, offered
    // Start workout and stamped `isPlannedDay: true` on the session. Two surfaces, one device, opposite answers — which
    // is exactly the "things don't look like they're syncing" the owner reported. HomeStatesTests
    // .testPausedFreezesTheReportAndOffersTheWayOut has been failing on this since the day it was written: it seeds a
    // pause through the real API and then asserts Home names the state, and Home said "Push day".
    static func writePause(_ pause: PauseDTO?, userId: String, store: Store, now: Date = Date()) throws {
        try store.clearPauses(for: userId) // the server is the truth: an ended pause has to be able to leave too
        guard let pause else { return }
        store.context.insert(LocalPause(userId: userId, startDay: pause.startDay, endDay: pause.endDay, createdAt: now))
        try store.save()
    }

    // The ongoing half: `pullIfEmpty` only fires on an EMPTY Store, so it cannot catch a pause created after this phone
    // already held a plan. SyncDriver calls this on launch and on every foreground — the two moments the app is already
    // allowed to touch the network. Home stays Store-only (S07: correct today-state < 500 ms warm, nothing waits on the
    // network), which is why this writes the Store rather than being read by the screen.
    static func pullPause(userId: String, store: Store) async {
        guard let reply = try? await Api.shared.currentPause() else { return } // offline is not a failure (E6): keep what we have
        try? writePause(reply.pause, userId: userId, store: store)
    }

    // GET posts → LocalPost rows, delivered already (never re-queued); a row the phone has is left alone. A workout post's
    // session is known by its server id only, so sessionClientId stays nil here (the session row itself arrives below).
    static func writeJournal(_ items: [PostDTO], userId: String, store: Store) throws {
        for item in items {
            let clientId = item.clientId ?? item.id
            if try store.post(clientId: clientId) != nil { continue }
            let post = LocalPost(clientId: clientId, userId: userId, type: item.type, sessionClientId: nil, caption: item.caption, shareToCrew: item.crewId != nil, dayKey: item.dayKey, isPlannedDay: item.isPlannedDay, workoutCompleted: item.workoutCompleted, createdAt: item.createdAt) // A22: no meal tag, no backfill label, no photo
            post.serverId = item.id
            post.summary = item.summary // A6: the line the server wrote at completion
            post.deliveredAt = item.createdAt
            store.context.insert(post)
        }
        try store.save()
    }

    // GET sessions → LocalSession rows with their snapshots: "done today" (Quick Complete hides), the weekly ring, Progress
    static func writeSessions(_ items: [SessionDTO], userId: String, store: Store) throws {
        for item in items {
            if try store.session(clientId: item.clientId) != nil { continue }
            let exercises = item.exercises.map { exercise -> LocalSessionExercise in
                let sets = exercise.sets.enumerated().map { index, set -> LocalSetLog in
                    let row = LocalSetLog(order: index, targetReps: set.targetReps, actualReps: set.actualReps, weight: set.weight, holdSeconds: set.holdSeconds, isWarmup: set.isWarmup, weightUnit: set.weightUnit) // A9
                    row.distanceMeters = set.distanceMeters // A2
                    row.done = set.done
                    row.asPlanned = Completion.asPlanned(SetFacts(targetReps: set.targetReps, actualReps: set.actualReps, done: set.done, isWarmup: set.isWarmup)) // V33, the same rule the server applied
                    return row
                }
                let local = LocalSessionExercise(exerciseId: exercise.exerciseId, name: exercise.name, equipment: exercise.equipment, type: exercise.type, targetSets: exercise.targetSets, targetReps: exercise.targetReps, holdSeconds: exercise.holdSeconds, order: exercise.order, sets: sets)
                local.skipped = exercise.skipped
                return local
            }
            let session = LocalSession(clientId: item.clientId, userId: userId, dayKey: item.dayKey, status: item.status, workoutName: item.workoutName, workoutKind: item.workoutKind, isPlannedDay: item.isPlannedDay, startedAt: item.startedAt, timezone: item.timezone, exercises: exercises)
            session.completedAt = item.completedAt
            session.updatedAt = item.updatedAt
            session.syncedAt = item.updatedAt
            store.context.insert(session)
        }
        try store.save()
    }

    // SPEC: 5.6.3 — server state REPLACES local, silently (the second copy of SyncQueue.reconcile's body; a third extracts, C1)
    static func replaceGamification(_ server: GamificationStateDTO, userId: String, store: Store) throws {
        let local = try store.gamificationState(for: userId)
        local.currentStreak = server.currentStreak
        local.longestStreak = server.longestStreak
        local.totalXP = server.totalXP
        local.level = server.level
        local.shields = server.shields
        local.lastCountedDayKey = server.lastCountedDayKey
        local.earnedAchievementIds = server.earnedAchievementIds
        local.updatedAt = Date()
        try store.save()
    }
}
