// SPEC: 5.6.2 SessionModel — state: session, focusIndex, restTimer, celebration; actions: checkSet (pre-fill → done, ghost
// row, haptic, rest start) · adjust(reps|weight) · addSet · addWarmup · skip · startHold (countdown → auto-check) · jumpTo ·
// complete (engine.apply → CelebrationOutcome) · saveForLater · discard. Flow 3: management by exception, pre-fill from
// reality, log without looking, out-of-order, neutral skips, crash-proof (every tap saves). WRITTEN — UNVERIFIED. T025

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class SessionModel {
    let session: LocalSession
    var focusIndex = 0
    var restTimer = RestTimer()
    var celebration: CelebrationOutcome?
    var completeError: String?
    var unitsConfirmed: Bool // A9: answered once per account; the line never returns
    var lastRemoved: RemovedSet? // A11: what the "Set removed · Undo" row puts back (SessionModel+Units.swift)
    var units: String        // A9: the WEIGHT unit — set rows, plate math, the last-time line
    var distanceUnit: String // A9: the DISTANCE unit — a cardio block's last-time line

    private let store: Store

    init(session: LocalSession, store: Store = .shared, units: String? = nil, distanceUnit: String? = nil) {
        self.session = session
        self.store = store
        self.units = units ?? AuthStore.shared.weightUnit
        self.distanceUnit = distanceUnit ?? AuthStore.shared.distanceUnit
        self.unitsConfirmed = SessionModel.storedUnitsConfirmed() // A9 (SessionModel+Units.swift)
    }

    var exercises: [LocalSessionExercise] { session.exercises.sorted { $0.order < $1.order } }
    var facts: CompletionFacts { Completion.completionFacts(SessionActions.setFacts(session)) }
    var canComplete: Bool { facts.complete }

    // SPEC: S09 · A2 — the live line above Complete: "x/y sets" (holds and cardio count, warm-ups never) + " + Walk 25 min"
    // for every cardio block with a done set
    var liveSummaryLine: String { "\(facts.setsDone)/\(facts.setsPlanned) sets\(JournalFacts.cardioSuffix(session))" }

    func sets(of exercise: LocalSessionExercise) -> [LocalSetLog] { exercise.sets.sorted { $0.order < $1.order } }

    // Flow 3 "pre-fill from reality": the last ACTUAL performance of this exercise, tiny and gray under the name
    func lastTimeLine(for exercise: LocalSessionExercise) -> String? {
        guard let previous = try? store.context.fetch(FetchDescriptor<LocalSession>(predicate: #Predicate { $0.status == "completed" }, sortBy: [SortDescriptor(\.completedAt, order: .reverse)])).first(where: { $0.clientId != session.clientId && $0.exercises.contains { $0.exerciseId == exercise.exerciseId } }),
              let row = previous.exercises.first(where: { $0.exerciseId == exercise.exerciseId }) else { return nil }
        let done = sets(of: row).filter { $0.done && !$0.isWarmup }
        guard !done.isEmpty, row.type != "mobility" else { return nil } // holds have no "last": no reps, no weight, ever
        if row.type == "cardio" { return cardioLastLine(done) }
        let reps = done.map { String($0.actualReps) }.joined(separator: " · ")
        if let weight = done.compactMap(\.weight).max() { return "last: \(reps) @ \(formatted(weight))" }
        return "last: \(reps)"
    }

    // SPEC: A2 — a cardio block's last time reads its minutes and, when logged, its distance in the user's units
    private func cardioLastLine(_ done: [LocalSetLog]) -> String {
        let minutes = JournalFacts.minutes(ofSeconds: done.reduce(0) { $0 + ($1.holdSeconds ?? 0) })
        let distance = done.compactMap(\.distanceMeters).reduce(0, +)
        guard distance > 0 else { return "last: \(minutes) min" }
        return "last: \(minutes) min · \(SessionSummaryLine.distanceText(distanceMeters: distance, distanceUnit: distanceUnit))"
    }

    // SPEC: Flow 3 base loop — tap a set → ✓ at pre-filled numbers · haptic tick · rest timer starts · last set → next exercise opens
    func checkSet(_ set: LocalSetLog, in exercise: LocalSessionExercise) {
        set.done.toggle()
        // SPEC: A9 — a set completed at its pre-filled weight was still ENTERED in today's unit; stamp it here too, or a
        // one-tap log (the commonest path in Flow 3) would store a weight with no unit at all
        if set.done, set.weight != nil, set.weightUnit == nil { set.weightUnit = units }
        set.asPlanned = Completion.asPlanned(SetFacts(targetReps: set.targetReps, actualReps: set.actualReps, done: set.done, isWarmup: set.isWarmup))
        save()
        guard set.done else { return }
        Haptics.play(.tick)
        restTimer.start()
        if sets(of: exercise).allSatisfy({ $0.done || $0.isWarmup }) {
            Haptics.play(.double)
            restTimer.stop()
            advanceFocus(after: exercise)
        }
    }

    // Smart steppers — reps ±1 · weight ±5 lb / ±2.5 kg · invalid values impossible
    func adjustReps(_ set: LocalSetLog, by delta: Int) {
        set.actualReps = max(0, set.actualReps + delta * SpecConstants.repsStep)
        save()
    }

    func addSet(after set: LocalSetLog, in exercise: LocalSessionExercise) {
        let clone = LocalSetLog(order: exercise.sets.count, targetReps: set.targetReps, actualReps: set.actualReps, weight: set.weight, holdSeconds: set.holdSeconds, isWarmup: false, weightUnit: set.weightUnit ?? units) // A9
        exercise.sets.append(clone)
        save()
    }

    // "+ warm-up" rows are excluded from x/y (Flow 3)
    func addWarmup(to exercise: LocalSessionExercise) {
        let first = sets(of: exercise).first
        let warmup = LocalSetLog(order: -1, targetReps: first?.targetReps ?? exercise.targetReps, actualReps: first?.targetReps ?? exercise.targetReps, weight: nil, holdSeconds: nil, isWarmup: true)
        for set in exercise.sets { set.order += 1 }
        warmup.order = 0
        exercise.sets.append(warmup)
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

    // Neutral skips: gray, no reasons, no red, no guilt
    func skip(_ exercise: LocalSessionExercise) {
        exercise.skipped.toggle()
        save()
        if exercise.skipped { advanceFocus(after: exercise) }
    }

    // Mobility holds: tap → countdown → auto-check (the row runs the timer and calls this at zero)
    func finishHold(_ set: LocalSetLog) {
        set.done = true
        set.asPlanned = true
        save()
        Haptics.play(.tick)
    }

    // SPEC: A2 — a cardio block is duration-based: Done stores the minutes as seconds (holdSeconds = minutes × 60) and the
    // optional distance in meters, both bounded; the set is done and as planned (targetReps 0, V51). Part of the +100, never
    // extra XP. The next open exercise opens, as after a finished set.
    func finishCardio(_ set: LocalSetLog, minutes: Int, distanceMeters: Int?) {
        let bounded = min(max(minutes, SpecConstants.cardioMinutesMin), SpecConstants.cardioMinutesMax)
        set.holdSeconds = bounded * TimeUnits.secondsPerMinute
        set.distanceMeters = distanceMeters.map { min(max($0, 0), SpecConstants.cardioDistanceMaxMeters) }
        set.done = true
        set.asPlanned = true
        save()
        Haptics.play(.tick)
        if let exercise = exercises.first(where: { $0.sets.contains { $0 === set } }) { advanceFocus(after: exercise) }
    }

    func jumpTo(_ exercise: LocalSessionExercise) {
        focusIndex = exercises.firstIndex { $0.order == exercise.order } ?? focusIndex
    }

    // SPEC: S10 — numbers match the engine exactly; partial always counts (Flow 3)
    func complete(shareToCrew: Bool) {
        do {
            guard let outcome = try SessionActions.complete(session, shareToCrew: shareToCrew, store: store) else {
                completeError = "Check off at least one set and this counts."
                return
            }
            Haptics.play(.thump)
            restTimer.stop()
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

    private func advanceFocus(after exercise: LocalSessionExercise) {
        let list = exercises
        if let index = list.firstIndex(where: { $0.order == exercise.order }), let next = list[(index + 1)...].first(where: { !$0.skipped && !sets(of: $0).allSatisfy { $0.done } }) {
            focusIndex = list.firstIndex { $0.order == next.order } ?? focusIndex
        }
    }

    // A9/A10 (SessionModel+Units.swift) writes through this too — internal, not private
    func save() {
        session.updatedAt = Date()
        try? store.save()
    }
}
