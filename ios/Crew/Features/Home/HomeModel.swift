// SPEC: 5.6.2 HomeModel — state: today: TodayState (TodayState.swift), streak, shields, weeklyRing: [DayRingState],
// crewStrip: [MemberDot]?; actions: refresh() (Store-only, < 500 ms) · startWorkout ·
// quickComplete · startBonus. S07: bridge until the first post (1D); Quick Complete hidden once today counts; Resume banner;
// crew strip ABSENT (nil) for solo (Flow 10). A1: today's workout comes from the rotation projection (the training-day check
// plus nextWorkoutKind), never from a weekday slot. A3: the what's-next line and the bonus list (next up first). C14.
// WRITTEN — UNVERIFIED (needs Mac). T024

import Foundation
import Observation

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
    var vectors = VectorSlots(workoutDone: false, cardioMinutes: nil, meals: 0) // A14: today's Workout · Cardio · Meals row
    var nextUpLine: String?                        // A3: nil on an undone training day, when paused, and on a workout-day bridge
    var bonusWorkouts: [LocalWorkoutTemplate] = [] // A3: the plan's workouts, the next rotation workout first
    private var todayWorkout: LocalWorkoutTemplate? // A1: the rotation workout due today; nil on rest, done, paused, no plan

    private let store: Store
    private let userId: String
    private let timeZone: TimeZone
    private let syncQueue: SyncQueue?
    private var welcomeBackAckDay: String?

    // A default argument is evaluated in a NONISOLATED context, even on a @MainActor type — so it cannot read the account
    // (AuthStore is main-actor since F32). The ack day is passed in: by HomeScreen from the account, by the tests explicitly.
    init(store: Store = .shared, userId: String? = nil, timeZone: TimeZone = .current, syncQueue: SyncQueue? = nil, welcomeBackAckDay: String? = nil) {
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
            let plan = try store.plan(for: userId)
            let rotation = try plan.map { try NextUp.rotationFor(userId: userId, plan: $0, todayKey: todayKey, store: store) }
            let todayEntry = rotation?.week.first(where: { $0.dayKey == todayKey })
            todayWorkout = todayEntry?.state == .planned ? plan?.workouts.first(where: { $0.kind == todayEntry?.kind }) : nil
            let postedToday = !(try store.posts(for: userId, dayKey: todayKey)).isEmpty
            let lastPostDay = try store.allPosts(for: userId).map(\.dayKey).max()
            let state = try store.gamificationState(for: userId)
            streak = state.currentStreak
            longestStreak = state.longestStreak
            shields = state.shields
            hasPlan = plan != nil
            resumeSession = try store.openSession(for: userId)
            today = todayState(restDay: todayEntry == nil || todayEntry?.state == .rest, postedToday: postedToday, hasEverPosted: lastPostDay != nil, pause: try store.activePause(for: userId, today: todayKey), todayKey: todayKey)
            // A8 · Flow 7 — a paused plan offers nothing to complete: `today` is decided above, so the flag reads the
            // STATE rather than the raw workout, which is what put "Quick complete" under a card saying the plan is paused
            quickCompleteAvailable = todayWorkout != nil && resumeSession == nil && !isPaused
            nextUpLine = whatsNext(plan: plan, rotation: rotation, todayKey: todayKey)
            bonusWorkouts = NextUp.bonusOrder(plan?.workouts ?? [], nextKind: rotation?.nextKind)
            vectors = try HomeModel.slots(userId: userId, dayKey: todayKey, store: store) // A14
            try refreshRing(plan: plan, todayKey: todayKey)
            crewStrip = try crewStripFromSnapshot()
            try refreshEdges(lastPostDay: lastPostDay, todayKey: todayKey, now: now)
            loadError = nil
        } catch {
            loadError = AppError.storage("home").userLine
        }
    }

    private var isPaused: Bool { if case .paused = today { return true } else { return false } }

    // SPEC: A1 — done = a completed ROTATION workout today (projectWeek); a standalone cardio log (A2) leaves the day planned
    private func todayState(restDay: Bool, postedToday: Bool, hasEverPosted: Bool, pause: LocalPause?, todayKey: String) -> TodayState {
        if let pause { return .paused(until: DayLabel.dayLabel(pause.endDay, todayKey: todayKey)) }
        if !hasEverPosted { return .bridge(todayWorkout == nil ? .rest : .workout) } // 1D: the bridge persists until the first post exists
        if restDay { return .rest(posted: postedToday) }
        guard let workout = todayWorkout else { return .allDone }
        // A14: the card carries the day's rows, built by the HomeLines twin so the web card reads word-for-word the same
        let rows = HomeModel.homeExercises(workout)
        return .workout(name: workout.name, exerciseCount: NextUp.strengthCount(workout), hasCardio: NextUp.hasCardio(workout), lines: HomeLines.strengthLines(rows), tail: HomeLines.tailLine(rows))
    }

    // SPEC: A3 — nothing on an undone training day or while paused; the bridge shows it only on a rest-day install (1D)
    private func whatsNext(plan: LocalPlan?, rotation: Rotation?, todayKey: String) -> String? {
        guard let plan, let rotation else { return nil }
        switch today {
        case .workout, .paused, .bridge(.workout): return nil
        case .bridge(.rest): return NextUp.whatsNext(todayKey: todayKey, plan: plan, rotation: rotation, bridge: true)
        case .rest, .allDone: return NextUp.whatsNext(todayKey: todayKey, plan: plan, rotation: rotation, bridge: false)
        }
    }

    // SPEC: Flow 2 ("weekly ring 2/4") — one segment per ISO weekday from trainingWeekdays (A1); missed = gray, never red;
    // A2 — a standalone cardio log never fills a planned slot
    private func refreshRing(plan: LocalPlan?, todayKey: String) throws {
        let weekKey = DayKey.weekKey(for: todayKey)
        var done = 0
        var planned = 0
        weeklyRing = try (0..<TimeUnits.daysPerWeek).map { offset in
            let dayKey = DayKey.addDays(weekKey, offset)
            guard plan?.trainingWeekdays.contains(offset + 1) ?? false else { return dayKey == todayKey ? .today : .rest }
            planned += 1
            let completed = try store.sessions(for: userId, dayKey: dayKey).contains { $0.status == "completed" && $0.workoutKind != "cardio" }
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

    // The rotation workout due today — the planned workout, isPlannedDay true (V25: +100 on completion)
    func startWorkout(now: Date = Date()) -> LocalSession? {
        guard let workout = todayWorkout else { return resumeSession }
        return startBonus(workout, now: now)
    }

    // SPEC: A3 — a bonus workout is any plan workout started from Home: isPlannedDay only when today is an undone training day
    // (then it is simply the planned workout); on a rest or done day it is unplanned (+25, V30/V31 — never expected, Flow 5)
    func startBonus(_ workout: LocalWorkoutTemplate, now: Date = Date()) -> LocalSession? {
        if let resumeSession { return resumeSession }
        let session = try? SessionActions.startSession(from: workout, kind: workout.kind, isPlannedDay: todayWorkout != nil, userId: userId, timeZone: timeZone, now: now, store: store)
        refresh(now: now)
        return session
    }

    func quickComplete(shareToCrew: Bool, now: Date = Date()) -> CelebrationOutcome? {
        guard quickCompleteAvailable, let workout = todayWorkout else { return nil }
        let outcome = try? SessionActions.quickComplete(from: workout, userId: userId, shareToCrew: shareToCrew, now: now, store: store)
        refresh(now: now)
        return outcome
    }
}
