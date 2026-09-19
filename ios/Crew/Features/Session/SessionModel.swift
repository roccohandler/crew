// SPEC: 5.6.2 SessionModel as amended by A28 (c), (d) (owner-approved 2026-09-19) — ONE SET PER SCREEN: state session, focusIndex
// (the exercise on screen), selectedSetOrder (a ledger row picked to correct), celebration; actions logSet (pre-fill → done, the
// set-done haptic, the next open set or the next exercise) · adjust(reps|weight) · addSet · addWarmup · skip · toggleHold ·
// markAllHolds · jumpTo · complete (engine.apply → CelebrationOutcome) · saveForLater · discard. A28 (c): NO TIMERS — the rest
// timer and the hold countdown are gone (RestTimer, MobilityHoldRow); a hold is a check. A28 (d): the in-session unit question is
// gone — lb/kg lives in Settings. Flow 3 stands: pre-fill from reality, out-of-order, neutral skips, crash-proof (every tap saves).
// WRITTEN — UNVERIFIED. T025 · R2

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class SessionModel {
    let session: LocalSession
    var focusIndex = 0
    var selectedSetOrder: Int?  // A28 (d): a logged set picked from the ledger, shown on the card to correct it
    var celebration: CelebrationOutcome?
    var completeError: String?
    var lastRemoved: RemovedSet? // A11: what "Undo" puts back (SessionModel+Units.swift)
    var units: String        // A9: the WEIGHT unit — the card, plate math, the last-time line
    var distanceUnit: String // A9: the DISTANCE unit — a cardio block

    private let store: Store

    init(session: LocalSession, store: Store = .shared, units: String? = nil, distanceUnit: String? = nil) {
        self.session = session
        self.store = store
        self.units = units ?? AuthStore.shared.weightUnit
        self.distanceUnit = distanceUnit ?? AuthStore.shared.distanceUnit
        focusIndex = firstOpenIndex ?? 0 // a resumed session opens where it was left
    }

    var exercises: [LocalSessionExercise] { session.exercises.sorted { $0.order < $1.order } }
    var facts: CompletionFacts { Completion.completionFacts(SessionActions.setFacts(session)) }
    var canComplete: Bool { facts.complete }

    // SPEC: A28 (d) — the count under the bar and on the sheet: "1 of 6 sets" (the engine's facts — holds and cardio count, warm-ups never)
    var countLine: String { "\(facts.setsDone) of \(facts.setsPlanned) sets" }

    func sets(of exercise: LocalSessionExercise) -> [LocalSetLog] { exercise.sets.sorted { $0.order < $1.order } }
    func workSets(of exercise: LocalSessionExercise) -> [LocalSetLog] { sets(of: exercise).filter { !$0.isWarmup } }

    var focused: LocalSessionExercise? { exercises.indices.contains(focusIndex) ? exercises[focusIndex] : nil }

    // SPEC: A28 (f) — the checklist screen: every mobility hold of the workout, one row each (a hold is one set, Flow 2 "18/18")
    var holds: [LocalSessionExercise] { exercises.filter { $0.type == "mobility" } }
    var isOnChecklist: Bool { focused?.type == "mobility" }

    // SPEC: A28 (d) — the set the card shows: a ledger row picked to correct, else the first open set (a warm-up before the work
    // sets), else the exercise's last set
    func displayedSet(of exercise: LocalSessionExercise) -> LocalSetLog? {
        let all = sets(of: exercise)
        if let selectedSetOrder, let picked = all.first(where: { $0.order == selectedSetOrder }) { return picked }
        return all.first { !$0.done } ?? all.last
    }

    // "Set 2 of 3" · "Warm-up" — the work sets are numbered, warm-ups are named (Flow 3: warm-ups never count)
    func setNumber(_ set: LocalSetLog, in exercise: LocalSessionExercise) -> Int {
        (workSets(of: exercise).firstIndex { $0 === set } ?? 0) + 1
    }

    // Flow 3 "pre-fill from reality": the last ACTUAL performance of this exercise — "8 · 8 · 8 @ 150 lb"
    func lastTime(for exercise: LocalSessionExercise) -> String? {
        guard exercise.type == "strength",
              let previous = try? store.context.fetch(FetchDescriptor<LocalSession>(predicate: #Predicate { $0.status == "completed" }, sortBy: [SortDescriptor(\.completedAt, order: .reverse)])).first(where: { $0.clientId != session.clientId && $0.exercises.contains { $0.exerciseId == exercise.exerciseId } }),
              let row = previous.exercises.first(where: { $0.exerciseId == exercise.exerciseId }) else { return nil }
        let done = sets(of: row).filter { $0.done && !$0.isWarmup }
        guard !done.isEmpty else { return nil }
        let reps = done.map { String($0.actualReps) }.joined(separator: " · ")
        if let weight = done.compactMap(\.weight).max() { return "\(reps) @ \(formatted(weight))" }
        return reps
    }

    // SPEC: A28 (d) · Flow 3 base loop — "Log set N": the set is done at the numbers on the card; the set-done haptic (6.4 — GAP 2
    // read conservatively, R-085); the last open set of an exercise → the exercise-done haptic and the next open exercise
    func logSet(_ set: LocalSetLog, in exercise: LocalSessionExercise) {
        set.done = true
        // SPEC: A9 — a set completed at its pre-filled weight was still ENTERED in today's unit; stamp it here too
        if set.weight != nil, set.weightUnit == nil { set.weightUnit = units }
        set.asPlanned = Completion.asPlanned(SetFacts(targetReps: set.targetReps, actualReps: set.actualReps, done: set.done, isWarmup: set.isWarmup))
        selectedSetOrder = nil
        save()
        Haptics.play(.tick)
        if sets(of: exercise).allSatisfy(\.done) {
            Haptics.play(.double)
            advanceFocus(after: exercise)
        }
    }

    // Smart steppers — reps ±1 · invalid values impossible; a typed count is clamped the same way
    func adjustReps(_ set: LocalSetLog, by delta: Int) { setReps(set, to: set.actualReps + delta * SpecConstants.repsStep) }

    func setReps(_ set: LocalSetLog, to reps: Int) {
        set.actualReps = min(max(0, reps), SpecConstants.planTargetRepsMax)
        if set.done { set.asPlanned = Completion.asPlanned(SetFacts(targetReps: set.targetReps, actualReps: set.actualReps, done: true, isWarmup: set.isWarmup)) }
        save()
    }

    // SPEC: E7 — mid-workout swap: candidates that do the same job; [Just today] rewrites the snapshot, [Update my plan] also the plan
    func swapCandidates(for exercise: LocalSessionExercise) -> [SeedExercise] {
        SessionSwap.candidates(for: exercise, in: session)
    }

    func swap(_ exercise: LocalSessionExercise, with replacement: SeedExercise, scope: SwapScope) {
        do {
            try SessionSwap.swap(exercise, in: session, with: replacement, scope: scope, store: store)
        } catch {
            completeError = AppError.storage("session").userLine
        }
    }

    // Neutral skips: no reasons, no red, no guilt; a skipped exercise hands the screen to the next open one
    func skip(_ exercise: LocalSessionExercise) {
        exercise.skipped.toggle()
        selectedSetOrder = nil
        save()
        if exercise.skipped { advanceFocus(after: exercise) }
    }

    // SPEC: A28 (c) — a hold is a check, never a countdown: done and as planned, or open again
    func toggleHold(_ hold: LocalSessionExercise) {
        let open = sets(of: hold).contains { !$0.done }
        for set in hold.sets { set.done = open; set.asPlanned = open }
        save()
        if open { Haptics.play(.tick) }
    }

    // SPEC: A28 (c) — "Mark all done" in the checklist's header
    func markAllHolds() {
        for hold in holds { for set in hold.sets { set.done = true; set.asPlanned = true } }
        save()
        Haptics.play(.double)
    }

    func jumpTo(_ exercise: LocalSessionExercise) {
        focusIndex = exercises.firstIndex { $0.order == exercise.order } ?? focusIndex
        selectedSetOrder = nil
    }

    // SPEC: S10 — numbers match the engine exactly; partial always counts (Flow 3). A21.9: no post yet — the celebration's tapped
    // button names the visibility (HomeModel.answerCelebration)
    func complete() {
        do {
            guard let outcome = try SessionActions.complete(session, store: store) else {
                completeError = "Log at least one set and this counts."
                return
            }
            Haptics.play(.thump)
            celebration = outcome
        } catch {
            completeError = AppError.storage("session").userLine
        }
    }

    func saveForLater() { save() }

    func discard() {
        session.status = "discarded"
        session.updatedAt = Date()
        save()
        try? SyncQueue.shared.enqueue(.patchSession, payload: PatchSessionPayload(sessionId: session.clientId, timezone: session.timezone, exercises: nil, status: "discarded", completedAt: nil, post: nil))
    }

    func formatted(_ weight: Double) -> String {
        weight.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(weight)) \(units)" : "\(weight) \(units)"
    }

    // Every exercise is done or skipped: nothing is left but Finish (the whole-workout sheet opens itself — A28 (d))
    var nothingOpen: Bool { firstOpenIndex == nil }

    private var firstOpenIndex: Int? {
        exercises.firstIndex { !$0.skipped && sets(of: $0).contains { !$0.done } }
    }

    func advanceFocus(after exercise: LocalSessionExercise) { // internal: a cardio block's log advances too (SessionModel+Units.swift)
        let list = exercises
        guard let index = list.firstIndex(where: { $0.order == exercise.order }) else { return }
        let isOpen: (LocalSessionExercise) -> Bool = { !$0.skipped && self.sets(of: $0).contains { !$0.done } }
        if let next = list[(index + 1)...].first(where: isOpen) ?? list[..<index].first(where: isOpen) {
            focusIndex = list.firstIndex { $0.order == next.order } ?? focusIndex
        }
    }

    // A9/A10/A11 (SessionModel+Units.swift) writes through this too — internal, not private
    func save() {
        session.updatedAt = Date()
        try? store.save()
    }
}
