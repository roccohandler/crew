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
    var nextUp: NextUpFacts?                       // A3 / A18.3: nil on an undone training day, when paused, and on a workout-day bridge
    var todaySummaryLines: [String] = []           // A18.9: what today actually held, in the journal's own sentence
    var offline = false                            // A18.12: the sync queue could not reach the network (E6 — not a failure)
    var bonusWorkouts: [LocalWorkoutTemplate] = [] // A3: the plan's workouts, the next rotation workout first
    private var todayWorkout: LocalWorkoutTemplate? // A1: the rotation workout due today; nil on rest, done, paused, no plan

    // A3 — the one-sentence form the BRIDGE card renders (§1D: one CTA plus this line, nothing else). Derived, never
    // stored beside `nextUp`, so the block and the line can never say different things.
    var nextUpLine: String? { nextUp.map { "\($0.heading): \($0.detail)" } }

    // C9/C10: `internal` rather than `private` because HomeModel+Edges.swift needs them and Swift's `private` is
    // file-scoped — the same reason HomeModel+Facts.swift is written as static functions that take what they need.
    let store: Store
    let userId: String
    let timeZone: TimeZone
    let syncQueue: SyncQueue?
    var welcomeBackAckDay: String?

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
            let pause = try store.activePause(for: userId, today: todayKey)
            today = todayState(restDay: todayEntry == nil || todayEntry?.state == .rest, postedToday: postedToday, hasEverPosted: lastPostDay != nil, pause: pause, todayKey: todayKey)
            // SPEC: Flow 7 · V25 — H002, and F14 recurring verbatim. The rotation projection (NextUp.rotationFor →
            // projectWeek) takes only trainingWeekdays and the cycle and NEVER consults the pause, so on a paused
            // training day `todayWorkout` stayed non-nil and every reader of it could hand out full planned-day credit
            // (+100) from a screen that says the streak is frozen — reachable by tapping the vector row's Workout slot.
            // One assignment at the source makes every present and future reader safe; a guard per call site does not
            // (that is exactly how F14 came back). A bonus workout is still REACHABLE while paused and it is allowed —
            // "pauses without penalty" never meant "pauses pay planned credit". CORRECTION (A18.6, 2026-09-10): the
            // previous version of this comment said it "correctly earns the unplanned +25 (V30/V31)". It earns ZERO.
            // V20 expects `awardsByEvent: [[], []]` for a meal AND a completed workout inside a pause window, and
            // both engines implement it (GamificationPost.swift:64, gamification-post.ts:72 return [] while paused).
            if isPaused { todayWorkout = nil }
            // A8 · Flow 7 — a paused plan offers nothing to complete: `today` is decided above, so the flag reads the
            // STATE rather than the raw workout, which is what put "Quick complete" under a card saying the plan is paused
            quickCompleteAvailable = todayWorkout != nil && resumeSession == nil && !isPaused
            nextUp = whatsNext(plan: plan, rotation: rotation, todayKey: todayKey)
            bonusWorkouts = NextUp.bonusOrder(plan?.workouts ?? [], nextKind: rotation?.nextKind)
            vectors = try HomeModel.slots(userId: userId, dayKey: todayKey, store: store) // A14
            todaySummaryLines = try HomeModel.todaySummary(userId: userId, dayKey: todayKey, distanceUnit: AuthStore.shared.distanceUnit, store: store) // A18.9
            let marks = try HomeModel.weekMarks(userId: userId, plan: plan, todayKey: todayKey, pause: pause, store: store) // Flow 2 · A17.4 · A18.6a/A18.7
            weeklyRing = marks.days
            ringDone = marks.done
            ringPlanned = marks.planned
            crewStrip = try crewStripFromSnapshot()
            offline = (syncQueue ?? SyncQueue.shared).offline // A18.12: the state Home declared and could never enter
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

    // SPEC: A3 — nothing on an undone training day or while paused; the bridge shows it only on a rest-day install (1D).
    // A18.3: on rest and all-done this is now the titled BLOCK above the card rather than the card's last caption.
    // PAUSED still gets nothing, and deliberately: `nextTrainingDayKey` would name a day INSIDE the pause window, so
    // the block would promise a workout on a day the app has already frozen. The paused card answers the question
    // instead, with the return date it already prints and the control A18.6c gives it.
    private func whatsNext(plan: LocalPlan?, rotation: Rotation?, todayKey: String) -> NextUpFacts? {
        guard let plan, let rotation else { return nil }
        switch today {
        case .workout, .paused, .bridge(.workout): return nil
        case .bridge(.rest): return NextUp.nextUpFacts(todayKey: todayKey, plan: plan, rotation: rotation, bridge: true)
        case .rest, .allDone: return NextUp.nextUpFacts(todayKey: todayKey, plan: plan, rotation: rotation, bridge: false)
        }
    }


    // SPEC: E4 (14 quiet days) · S01 (stale in-progress session) · E19 (held uploads past 24 h) — the edge screens' triggers (T042)
    private func refreshEdges(lastPostDay: String?, todayKey: String, now: Date) throws {
        welcomeBack = LapsedUser.shouldShowWelcomeBack(lastActivityDay: lastPostDay, ackDay: welcomeBackAckDay, today: todayKey)
        staleSession = resumeSession.flatMap { LapsedUser.isStaleSession(startedAt: $0.startedAt, now: now) ? $0 : nil }
        heldUploads = try (syncQueue ?? SyncQueue.shared).heldOver24h(now: now)
    }

    // Flow 10: nil (absent) when solo — Home never shows an empty social panel.
    // A17.1 / H033: nil below crewMinMembers too. A crew of ONE has a snapshot whose members are `[you]`, so Home was
    // showing the user their own face back to them, unlabelled, and calling it a crew. The Crew tab has always known
    // better (CrewModel.isCrewOfOne, the same predicate) — Home was the last surface that did not. True solo was
    // already correct (no snapshot → nil), so S07 and Flow 10 were satisfied; this is the crew-of-one state A5 governs.
    private func crewStripFromSnapshot() throws -> [MemberDot]? {
        guard let snapshot = try store.crewSnapshot() else { return nil }
        let members = try JSONDecoder.crew.decode([MemberDot].self, from: snapshot.membersJSON)
        return members.count < SpecConstants.crewMinMembers ? nil : members
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

    // SPEC: A18.6c — the one control the paused card was missing. Flow 7 gave that state zero controls, which left a
    // paused user reading "your streak is frozen until Sat Sep 12" with no route off it that any word on the screen
    // named. The call and the wording are SettingsModel.endPause and PauseScreen.swift:22's "End the pause now" — one
    // action, one string, two entry points (6.6), never a third phrasing.
    //
    // It is network-only, like Settings' copy of it: there is no endPause OpKind in the 5.6.3 queue map, so offline it
    // fails and says so rather than pretending. Recorded in debt.md rather than solved by inventing an op kind here.
    func endPause() async {
        do {
            _ = try await Api.shared.endPause()
            try? store.clearPauses(for: userId)
            refresh()
        } catch let error as AppError {
            loadError = error.userLine
        } catch {
            loadError = AppError.storage("home").userLine
        }
    }

    func quickComplete(shareToCrew: Bool, now: Date = Date()) -> CelebrationOutcome? {
        guard quickCompleteAvailable, let workout = todayWorkout else { return nil }
        let outcome = try? SessionActions.quickComplete(from: workout, userId: userId, shareToCrew: shareToCrew, now: now, store: store)
        refresh(now: now)
        return outcome
    }
}
