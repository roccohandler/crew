// SPEC: 5.6.2 PlanModel — state: week: [DayProjection] + rows: [WeekMapRow], editing drafts (one WorkoutDraft per workout
// kind); actions: edit(kind:) · swap · adjust · reorder · move · remove (undo) · add · addCardio · setTrainingWeekdays ·
// save(kind:) · rebuild (the questions again, PlanScreen). A1: the week map is PlanRotation.projectWeek over the plan's
// cycle and the pointer derived from completed sessions, never stored. A4: two disclosure levels — the map holds zero
// controls; Save replaces the phone's plan (PlanLocal) and the server's through the queue (E6), forward-only (Flow 8;
// running sessions keep their snapshot, E7). C14. WRITTEN — UNVERIFIED (needs Mac).

import Foundation
import Observation

@Observable
@MainActor
final class PlanModel {
    var plan: PlanDraft?
    var week: [DayProjection] = []
    var rows: [WeekMapRow] = []
    var nextWeekStartsWith: String?          // the quiet line's workout name; nil when the cycle divides the training days
    var drafts: [String: WorkoutDraft] = [:] // one editor draft per workout kind (A4)
    var savedLine: String?
    var errorLine: String?

    private let store: Store
    private let userId: String
    private let seed: SeedCatalog
    private let syncQueue: SyncQueue?
    private let timeZone: TimeZone

    init(store: Store = .shared, userId: String? = nil, seed: SeedCatalog = .shared, syncQueue: SyncQueue? = nil, timeZone: TimeZone = .current) {
        self.store = store
        self.userId = userId ?? AuthStore.shared.currentUser?.id ?? "local"
        self.seed = seed
        self.syncQueue = syncQueue
        self.timeZone = timeZone
    }

    var hasPlan: Bool { plan != nil }

    func load(now: Date = Date()) {
        do {
            drafts = [:]
            try project(now: now)
            errorLine = nil
        } catch {
            errorLine = AppError.storage("plan").userLine
        }
    }

    func workout(kind: String) -> PlanDraftWorkout? { plan?.workouts.first { $0.kind == kind } }
    func name(ofKind kind: String) -> String { workout(kind: kind)?.name ?? kind }
    func cueLine(for exerciseId: String) -> String? { seed.exercise(exerciseId)?.cueLine }
    func dismissSaved() { savedLine = nil }

    // SPEC: A1 — done · planned · open · rest for Mon..Sun; the pointer is the kind after the LAST COMPLETED rotation
    // workout (a miss, a pause and a plan edit leave no completed session, so none of them moves it); this week's done
    // days come from the latest completed rotation session of each day (a cardio log, A2, is outside the cycle)
    private func project(now: Date) throws {
        guard let local = try store.plan(for: userId) else { plan = nil; week = []; rows = []; nextWeekStartsWith = nil; return }
        let draft = PlanLocal.draft(local)
        plan = draft
        let cycle = draft.workouts.map(\.kind)
        guard !cycle.isEmpty else { week = []; rows = []; nextWeekStartsWith = nil; return }
        let todayKey = DayKey.dayKey(for: now, tz: timeZone)
        let weekKey = DayKey.weekKey(for: todayKey)
        let next = PlanRotation.nextWorkoutKind(lastCompletedKind: try store.lastCompletedRotationKind(for: userId, cycle: cycle), cycle: cycle)
        var doneByDay: [String: String] = [:]
        for session in try store.completedSessions(for: userId) where session.dayKey >= weekKey && doneByDay[session.dayKey] == nil {
            let one = RotationSession(kind: session.workoutKind, name: session.workoutName, completedAt: session.completedAt, status: session.status)
            if let kind = PlanRotation.lastRotationKind(sessions: [one], cycle: cycle) { doneByDay[session.dayKey] = kind }
        }
        week = PlanRotation.projectWeek(weekKey: weekKey, todayKey: todayKey, trainingWeekdays: draft.trainingWeekdays, cycle: cycle, nextKind: next, completedKindByDay: doneByDay)
        rows = week.map { WeekMapRow.make($0, workouts: draft.workouts) }
        var after = next
        for _ in week.filter({ $0.state == .planned }) { after = PlanRotation.nextWorkoutKind(lastCompletedKind: after, cycle: cycle) }
        nextWeekStartsWith = cycle.count > 1 && draft.trainingWeekdays.count % cycle.count != 0 ? name(ofKind: after) : nil
    }

    // MARK: The workout editor (A4) — one draft per kind, opened from the saved plan, dirty until saved or discarded

    func edit(kind: String) {
        guard drafts[kind] == nil, let workout = workout(kind: kind) else { return }
        drafts[kind] = WorkoutDraft(workout: workout)
    }

    func discard(kind: String) { drafts[kind] = nil }
    func isDirty(kind: String) -> Bool { drafts[kind]?.isDirty ?? false }

    private func mutate(kind: String, _ change: (inout WorkoutDraft) -> Void) {
        guard var draft = drafts[kind] else { return }
        change(&draft)
        drafts[kind] = draft
        savedLine = nil
    }

    func swap(kind: String, order: Int, with replacement: SeedExercise) { mutate(kind: kind) { $0.swap(order: order, with: replacement) } }
    func adjust(kind: String, order: Int, setsBy: Int = 0, repsBy: Int = 0, minutesBy: Int = 0) { mutate(kind: kind) { $0.adjust(order: order, setsBy: setsBy, repsBy: repsBy, minutesBy: minutesBy) } }
    func move(kind: String, from source: IndexSet, to destination: Int) { mutate(kind: kind) { $0.move(from: source, to: destination) } }
    func remove(kind: String, order: Int) { mutate(kind: kind) { $0.remove(order: order) } }
    func undoRemove(kind: String) { mutate(kind: kind) { $0.undoRemove() } }
    func add(kind: String, _ exercise: SeedExercise) { mutate(kind: kind) { $0.add(exercise, seed: seed) } }
    func addCardio(kind: String, _ activity: SeedExercise) { mutate(kind: kind) { $0.addCardio(activity, seed: seed) } }

    // Move up / Move down from the exercise sheet: the sheet follows the row to its new order
    @discardableResult
    func reorder(kind: String, order: Int, direction: Int) -> Int? {
        var moved: Int?
        mutate(kind: kind) { moved = $0.reorder(order: order, direction: direction) }
        return moved
    }

    func canReorder(kind: String, order: Int, direction: Int) -> Bool { drafts[kind]?.canReorder(order: order, direction: direction) ?? false }
    func swapCandidates(kind: String, order: Int) -> [SeedExercise] { drafts[kind]?.swapCandidates(order: order, seed: seed) ?? [] }
    func addCandidates(kind: String) -> [SeedExercise] { drafts[kind]?.addCandidates(seed: seed) ?? [] }
    func cardioCandidates(kind: String) -> [SeedExercise] { drafts[kind]?.cardioCandidates(seed: seed) ?? [] }

    // SPEC: A4 · Flow 8 — Save commits one workout: the phone's plan is replaced now, the server's through the queue; the
    // pointer never moves (a plan edit is not a completion)
    @discardableResult
    func save(kind: String, now: Date = Date()) -> Bool {
        guard let plan, let draft = drafts[kind] else { return false }
        let next = PlanDraft(trainingWeekdays: plan.trainingWeekdays, workouts: plan.workouts.map { $0.kind == kind ? draft.workout : $0 })
        guard persist(next, now: now) else { return false }
        drafts[kind] = nil
        savedLine = "Saved · applies from your next \(draft.name)"
        return true
    }

    // SPEC: A4 — training days change without a rebuild (≥ minTrainingDaysToContinue); workouts and pointer untouched
    func canSaveDays(_ days: Set<Int>) -> Bool { days.count >= SpecConstants.minTrainingDaysToContinue }

    @discardableResult
    func setTrainingWeekdays(_ days: Set<Int>, now: Date = Date()) -> Bool {
        guard let plan, canSaveDays(days) else { return false }
        guard persist(PlanDraft(trainingWeekdays: days.sorted(), workouts: plan.workouts), now: now) else { return false }
        savedLine = "Saved · your week is updated"
        return true
    }

    private func persist(_ next: PlanDraft, now: Date) -> Bool {
        do {
            try PlanLocal.replace(next, userId: userId, updatedAt: now, store: store)
            try (syncQueue ?? SyncQueue.shared).enqueue(.putPlan, payload: PutPlanRequestDTO(trainingWeekdays: next.trainingWeekdays, workouts: next.workouts), now: now)
            try project(now: now)
            errorLine = nil
            return true
        } catch {
            errorLine = "Couldn't save. Your changes are still here."
            return false
        }
    }
}
