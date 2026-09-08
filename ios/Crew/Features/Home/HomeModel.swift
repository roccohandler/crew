// SPEC: 5.6.2 HomeModel — state: today: TodayState, streak, shields, weeklyRing: [DayRingState], crewStrip: [MemberDot]?;
// enum TodayState { bridge · workout · rest · paused · allDone }; actions: refresh() (Store-only, < 500 ms) · startWorkout ·
// quickComplete · openDay. S07: bridge until the first post (1D); Quick Complete hidden once today counts; Resume banner;
// crew strip ABSENT (nil) for solo (Flow 10). C14. WRITTEN — UNVERIFIED (needs Mac). T024

import Foundation
import Observation

enum BridgeKind: Equatable {
    case workout, rest
}

enum TodayState: Equatable {
    case bridge(BridgeKind)
    case workout(name: String, exerciseCount: Int, done: Bool)
    case rest(posted: Bool)
    case paused(until: String)
    case allDone
}

struct MemberDot: Equatable, Identifiable {
    let id: String
    let displayName: String
    let streak: Int
    let postedToday: Bool
    let paused: Bool
}

@Observable
@MainActor
final class HomeModel {
    var today: TodayState = .bridge(.rest)
    var streak = 0
    var shields = 0
    var weeklyRing: [DayRingState] = []
    var ringDone = 0
    var ringPlanned = 0
    var crewStrip: [MemberDot]?
    var resumeSession: LocalSession?
    var quickCompleteAvailable = false
    var loadError: String?
    var lastAwards: [Award] = []
    var hasPlan = false
    var longestStreak = 0
    var welcomeBack = false          // E4 / S18: 14+ quiet days
    var staleSession: LocalSession?  // S01: in progress for more than a day
    var heldUploads: [OpRecord] = [] // E19: held for more than 24 h — the user chooses

    private let store: Store
    private let userId: String
    private let timeZone: TimeZone
    private let syncQueue: SyncQueue?
    private var welcomeBackAckDay: String?

    init(store: Store = .shared, userId: String? = nil, timeZone: TimeZone = .current, syncQueue: SyncQueue? = nil, welcomeBackAckDay: String? = AuthStore.shared.currentUser?.welcomeBackAckDay) {
        self.store = store
        self.userId = userId ?? AuthStore.shared.currentUser?.id ?? "local"
        self.timeZone = timeZone
        self.syncQueue = syncQueue
        self.welcomeBackAckDay = welcomeBackAckDay
    }

    // SPEC: S07 — correct today-state < 500 ms warm: everything comes from the Store, nothing waits on the network
    func refresh(now: Date = Date()) {
        do {
            lastAwards = try GamificationLocal.judgeElapsedDays(for: userId, store: store, now: now, timeZone: timeZone)
            let todayKey = DayKey.dayKey(for: now, tz: timeZone)
            let weekday = DayKey.isoWeekday(todayKey)
            let plan = try store.plan(for: userId)
            let workout = plan?.workouts.first { $0.weekday == weekday }
            let doneToday = try store.sessions(for: userId, dayKey: todayKey).contains { $0.status == "completed" }
            let postedToday = !(try store.posts(for: userId, dayKey: todayKey)).isEmpty
            let lastPostDay = try store.allPosts(for: userId).map(\.dayKey).max()
            let state = try store.gamificationState(for: userId)
            streak = state.currentStreak
            longestStreak = state.longestStreak
            shields = state.shields
            hasPlan = plan != nil
            resumeSession = try store.openSession(for: userId)
            today = todayState(workout: workout, doneToday: doneToday, postedToday: postedToday, hasEverPosted: lastPostDay != nil, pause: try store.activePause(for: userId, today: todayKey))
            quickCompleteAvailable = workout != nil && !doneToday && resumeSession == nil
            try refreshRing(plan: plan, todayKey: todayKey)
            crewStrip = try crewStripFromSnapshot()
            try refreshEdges(lastPostDay: lastPostDay, todayKey: todayKey, now: now)
            loadError = nil
        } catch {
            loadError = AppError.storage("home").userLine
        }
    }

    private func todayState(workout: LocalWorkoutTemplate?, doneToday: Bool, postedToday: Bool, hasEverPosted: Bool, pause: LocalPause?) -> TodayState {
        if let pause { return .paused(until: pause.endDay) }
        if !hasEverPosted { return .bridge(workout == nil ? .rest : .workout) } // 1D: the bridge persists until the first post exists
        guard let workout else { return .rest(posted: postedToday) }
        if doneToday { return .allDone }
        return .workout(name: workout.name, exerciseCount: workout.exercises.filter { $0.type == "strength" }.count, done: false)
    }

    // SPEC: Flow 2 ("weekly ring 2/4") — one segment per ISO weekday; missed = gray, never red
    private func refreshRing(plan: LocalPlan?, todayKey: String) throws {
        let weekKey = DayKey.weekKey(for: todayKey)
        var done = 0
        var planned = 0
        weeklyRing = try (0..<TimeUnits.daysPerWeek).map { offset in
            let dayKey = DayKey.addDays(weekKey, offset)
            let isPlanned = plan?.workouts.contains { $0.weekday == offset + 1 } ?? false
            guard isPlanned else { return dayKey == todayKey ? .today : .rest }
            planned += 1
            let completed = try store.sessions(for: userId, dayKey: dayKey).contains { $0.status == "completed" }
            if completed { done += 1; return .done }
            if dayKey == todayKey { return .today }
            return dayKey < todayKey ? .missed : .upcoming
        }
        ringDone = done
        ringPlanned = planned
    }

    // SPEC: E4 (14 quiet days) · S01 (stale in-progress session) · E19 (held uploads past 24 h) — the edge screens' triggers (T042)
    private func refreshEdges(lastPostDay: String?, todayKey: String, now: Date) throws {
        welcomeBack = LapsedUser.shouldShowWelcomeBack(lastActivityDay: lastPostDay, ackDay: welcomeBackAckDay, today: todayKey)
        staleSession = resumeSession.flatMap { LapsedUser.isStaleSession(startedAt: $0.startedAt, now: now) ? $0 : nil }
        heldUploads = try (syncQueue ?? SyncQueue.shared).heldOver24h(now: now)
    }

    // E4: the answer is stored on the account so no device asks twice this quiet spell; the phone remembers it even offline
    // GAP: a PATCH that fails offline is not queued (no such OpKind in the 5.6.3 map) — the web may ask once more; nothing is lost
    func acknowledgeWelcomeBack(now: Date = Date()) async {
        let today = DayKey.dayKey(for: now, tz: timeZone)
        welcomeBackAckDay = today
        welcomeBack = false
        if let user = try? await Api.shared.updateMe(UpdateMeRequestDTO(welcomeBackAckDay: today)) { AuthStore.shared.updateCurrentUser(user) }
    }

    // S01: "Keep going" hands the open session back to the normal Resume path
    func keepGoingWithStaleSession() -> LocalSession? {
        defer { staleSession = nil }
        return staleSession
    }

    // S01: a discard is the ordinary session discard — nothing was counted (V32), nothing is lost from XP
    func discardStaleSession(now: Date = Date()) {
        guard let session = staleSession else { return }
        session.status = "discarded"
        session.updatedAt = now
        try? store.save()
        try? (syncQueue ?? SyncQueue.shared).enqueue(.patchSession, payload: PatchSessionPayload(sessionId: session.clientId, timezone: session.timezone, exercises: nil, status: "discarded", completedAt: nil, post: nil))
        refresh(now: now)
    }

    // E19: Retry · Post without photo · Delete — straight to the queue's one resolve
    func resolveUpload(_ record: OpRecord, choice: UserChoice, now: Date = Date()) {
        try? (syncQueue ?? SyncQueue.shared).resolve(record, choice: choice, now: now)
        refresh(now: now)
    }

    // Flow 10: nil (absent) when solo — Home never shows an empty social panel
    private func crewStripFromSnapshot() throws -> [MemberDot]? {
        guard let snapshot = try store.crewSnapshot() else { return nil }
        return try JSONDecoder.crew.decode([MemberDot].self, from: snapshot.membersJSON)
    }

    func startWorkout(now: Date = Date()) -> LocalSession? {
        if let resumeSession { return resumeSession }
        guard let workout = try? store.plan(for: userId)?.workouts.first(where: { $0.weekday == DayKey.isoWeekday(DayKey.dayKey(for: now, tz: timeZone)) }) else { return nil }
        let session = try? SessionActions.startSession(from: workout, userId: userId, timeZone: timeZone, now: now, store: store)
        refresh(now: now)
        return session
    }

    func quickComplete(shareToCrew: Bool, now: Date = Date()) -> CelebrationOutcome? {
        guard quickCompleteAvailable, let workout = try? store.plan(for: userId)?.workouts.first(where: { $0.weekday == DayKey.isoWeekday(DayKey.dayKey(for: now, tz: timeZone)) }) else { return nil }
        let outcome = try? SessionActions.quickComplete(from: workout, userId: userId, shareToCrew: shareToCrew, now: now, store: store)
        refresh(now: now)
        return outcome
    }
}

extension MemberDot: Codable {}
