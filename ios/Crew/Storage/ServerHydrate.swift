// SPEC: 1C (a Crew user authenticates ONCE per device — the Keychain outlives a reinstall, so a signed-in phone can wake with an
// empty Store) · 1D (the bridge persists until the first post EXISTS — the account's journal counts, not this phone's) · E6 (the
// phone holds the truth it judges from: plan, journal, sessions, gamification, crew) · 5.6.3 (gamification: server state
// REPLACES local). A signed-in phone whose Store holds neither a plan nor a post pulls everything once, before Home judges today
// (RootView); a login without a draft pulls the same way (OnboardingModel). A phone with any local truth pulls nothing here —
// the queue and the reconcile keep it current. A1/A2/A6 (2026-09-08): the plan arrives with its trainingWeekdays (PlanLocal), a
// session with its workoutKind and set distances, a post with its summary line. Plain functions (C2). WRITTEN — UNVERIFIED
// (needs Mac). T024 / T035 / T042

import Foundation
import SwiftData

@MainActor
enum ServerHydrate {
    static func isEmpty(userId: String, store: Store) -> Bool {
        let hasPlan = (try? store.plan(for: userId)) != nil
        let hasPost = !((try? store.allPosts(for: userId)) ?? []).isEmpty
        return !hasPlan && !hasPost
    }

    static func pullIfEmpty(userId: String, store: Store) async {
        guard isEmpty(userId: userId, store: store) else { return }
        await PlanLocal.pullFromServer(userId: userId, store: store)
        if let journal = try? await Api.shared.myPosts() { try? writeJournal(journal.items, userId: userId, store: store) }
        if let history = try? await Api.shared.mySessions() { try? writeSessions(history.items, userId: userId, store: store) }
        if let me = try? await Api.shared.me() { try? replaceGamification(me.gamification, userId: userId, store: store) }
        await CrewModel(store: store).refresh() // the crew snapshot (6.1 offline: last-synced) through the writer the Crew tab uses
    }

    // 1A/6.1: RootView shows Home's skeleton while the pull runs, but never longer than hydrationMaxWaitSeconds — after that Home
    // opens with what has arrived and the pull finishes behind it (Home re-reads the Store on its next foreground)
    static func pullIfEmptyBounded(userId: String, store: Store) async {
        guard isEmpty(userId: userId, store: store) else { return }
        let pull = Task { await pullIfEmpty(userId: userId, store: store) }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await pull.value }
            group.addTask { _ = try? await Task.sleep(for: .seconds(SpecConstants.hydrationMaxWaitSeconds)) }
            _ = await group.next()
            group.cancelAll()
        }
    }

    // GET posts → LocalPost rows, delivered already (never re-queued); a row the phone has is left alone. A workout post's
    // session is known by its server id only, so sessionClientId stays nil here (the session row itself arrives below).
    static func writeJournal(_ items: [PostDTO], userId: String, store: Store) throws {
        for item in items {
            let clientId = item.clientId ?? item.id
            if try store.post(clientId: clientId) != nil { continue }
            let post = LocalPost(clientId: clientId, userId: userId, type: item.type, sessionClientId: nil, caption: item.caption, mealTag: item.mealTag, shareToCrew: item.crewId != nil, dayKey: item.dayKey, isPlannedDay: item.isPlannedDay, workoutCompleted: item.workoutCompleted, earlierToday: item.earlierToday, createdAt: item.createdAt)
            post.serverId = item.id
            post.photoKey = item.photoKey
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
                    let row = LocalSetLog(order: index, targetReps: set.targetReps, actualReps: set.actualReps, weight: set.weight, holdSeconds: set.holdSeconds, isWarmup: set.isWarmup)
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
