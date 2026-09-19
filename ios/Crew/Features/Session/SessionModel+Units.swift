// SPEC: A9 (owner-directed 2026-09-09) as amended by A28 (d) (2026-09-19) — the set writers: weight, the set count, a cardio block's
// minutes and distance, and set removal. The in-session unit
// confirm is GONE (lb/kg lives in Settings only; the unit is a word beside the number), and with it unitsConfirmed and the flip.
// Split from SessionModel.swift for the C9 200-line cap.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation

extension SessionModel {
    // SPEC: A9 — a weight is stamped with the unit it was ENTERED in, at the moment it is entered; nothing reinterprets it
    // later. A12 — decrementing off the floor returns to "—" instead of sticking at 0: before prefill, the only way into a
    // weight was to press +, so 0 was where you started; now a row can OPEN carrying a weight, and a bodyweight exercise
    // needs a way back out. "—" is a complete set forever (Flow 3), so it has to remain reachable.
    func adjustWeight(_ set: LocalSetLog, by direction: Int) {
        let step = units == "lb" ? Double(SpecConstants.weightStepLb) : SpecConstants.weightStepKg
        let next = (set.weight ?? 0) + Double(direction) * step
        if next < 0 || (next == 0 && direction < 0) {
            set.weight = nil
            set.weightUnit = nil
        } else {
            set.weight = next
            set.weightUnit = units
        }
        save()
    }

    // SPEC: A28 (f) — the value button's keypad sets a weight outright. Clamped and snapped to a loadable step on commit, so Flow 3's
    // "invalid values impossible" holds for a typed number too; stamped with today's unit like every other weight (A9).
    func setWeight(_ set: LocalSetLog, to weight: Double) {
        let step = units == "lb" ? Double(SpecConstants.weightStepLb) : SpecConstants.weightStepKg
        set.weight = (min(max(weight, 0), Double(SpecConstants.setWeightMax)) / step).rounded() * step
        set.weightUnit = units
        save()
    }

    // SPEC: A28 (d) — "+ set" under ⋯: one more work set at the last one's numbers
    func addSet(to exercise: LocalSessionExercise) {
        guard let last = workSets(of: exercise).last else { return }
        let clone = LocalSetLog(order: exercise.sets.count, targetReps: last.targetReps, actualReps: last.actualReps, weight: last.weight, holdSeconds: last.holdSeconds, isWarmup: false, weightUnit: last.weightUnit ?? units) // A9
        exercise.sets.append(clone)
        selectedSetOrder = nil
        save()
    }

    // "+ warm-up" under ⋯ — a warm-up opens the exercise and is excluded from x/y (Flow 3)
    func addWarmup(to exercise: LocalSessionExercise) {
        let first = sets(of: exercise).first
        let warmup = LocalSetLog(order: -1, targetReps: first?.targetReps ?? exercise.targetReps, actualReps: first?.targetReps ?? exercise.targetReps, weight: nil, holdSeconds: nil, isWarmup: true)
        for set in exercise.sets { set.order += 1 }
        warmup.order = 0
        exercise.sets.append(warmup)
        selectedSetOrder = nil
        save()
    }

    // SPEC: A2 · A28 (c) · GAP 4 as R-084 (2) read it — a cardio block's minutes are what the user ENTERS (a target, never a clock):
    // they open at the plan's target, move in cardioMinutesStep within cardioMinutesMin…Max, and are stored as seconds
    func cardioMinutes(of set: LocalSetLog, in exercise: LocalSessionExercise) -> Int {
        let seconds = set.holdSeconds ?? exercise.holdSeconds ?? 0
        return min(max(seconds / TimeUnits.secondsPerMinute, SpecConstants.cardioMinutesMin), SpecConstants.cardioMinutesMax)
    }

    func adjustCardioMinutes(_ set: LocalSetLog, by delta: Int, in exercise: LocalSessionExercise) {
        setCardioMinutes(set, to: cardioMinutes(of: set, in: exercise) + delta * SpecConstants.cardioMinutesStep, in: exercise)
    }

    func setCardioMinutes(_ set: LocalSetLog, to minutes: Int, in exercise: LocalSessionExercise) {
        set.holdSeconds = min(max(minutes, SpecConstants.cardioMinutesMin), SpecConstants.cardioMinutesMax) * TimeUnits.secondsPerMinute
        save()
    }

    // SPEC: A2 — the typed distance, in the user's unit (A9), stored in meters and capped at cardioDistanceMaxMeters; zero clears it
    func setDistance(_ set: LocalSetLog, to value: Double) {
        let metersPerUnit = distanceUnit == "km" ? Double(SpecConstants.metersPerKilometer) : SpecConstants.metersPerMile
        let meters = Int((value * metersPerUnit).rounded())
        set.distanceMeters = meters > 0 ? min(meters, SpecConstants.cardioDistanceMaxMeters) : nil
        save()
    }

    // "Log set 1" on a cardio block: done at the minutes and distance on the card
    func logCardio(_ set: LocalSetLog, in exercise: LocalSessionExercise) {
        finishCardio(set, minutes: cardioMinutes(of: set, in: exercise), distanceMeters: set.distanceMeters)
    }

    // SPEC: A2 — a cardio block is done with holdSeconds = minutes × 60 and the optional distance in meters, both bounded; the set is
    // done and as planned (targetReps 0, V51). Part of the +100, never extra XP. The next open exercise takes the screen.
    func finishCardio(_ set: LocalSetLog, minutes: Int, distanceMeters: Int?) {
        let bounded = min(max(minutes, SpecConstants.cardioMinutesMin), SpecConstants.cardioMinutesMax)
        set.holdSeconds = bounded * TimeUnits.secondsPerMinute
        set.distanceMeters = distanceMeters.map { min(max($0, 0), SpecConstants.cardioDistanceMaxMeters) }
        set.done = true
        set.asPlanned = true
        selectedSetOrder = nil
        save()
        Haptics.play(.tick)
        if let exercise = exercises.first(where: { $0.sets.contains { $0 === set } }) { advanceFocus(after: exercise) }
    }

    // SPEC: A11 (V54/V55) — remove a set. The engine decides whether it may go and how the survivors renumber; this only
    // applies that decision to the stored rows. `undo` keeps the removed row's numbers so the snackbar can put it back.
    func canRemove(_ set: LocalSetLog, in exercise: LocalSessionExercise) -> Bool {
        SetRemoval.removeSet(removable(exercise), order: set.order).removed
    }

    func removeSet(_ set: LocalSetLog, in exercise: LocalSessionExercise) {
        let result = SetRemoval.removeSet(removable(exercise), order: set.order)
        guard result.removed else { return }
        lastRemoved = RemovedSet(exerciseOrder: exercise.order, order: set.order, targetReps: set.targetReps, actualReps: set.actualReps, weight: set.weight, weightUnit: set.weightUnit, holdSeconds: set.holdSeconds, isWarmup: set.isWarmup)
        exercise.sets.removeAll { $0.order == set.order }
        renumber(exercise, to: result.sets)
        selectedSetOrder = nil
        save()
        Haptics.play(.tick)
    }

    // SPEC: A11 — "Set removed · Undo": the row goes back where it was, and the rest renumber around it again
    func undoRemove(in exercises: [LocalSessionExercise]) {
        guard let removed = lastRemoved, let exercise = exercises.first(where: { $0.order == removed.exerciseOrder }) else { return }
        for row in exercise.sets where row.order >= removed.order { row.order += 1 }
        let restored = LocalSetLog(order: removed.order, targetReps: removed.targetReps, actualReps: removed.actualReps, weight: removed.weight, holdSeconds: removed.holdSeconds, isWarmup: removed.isWarmup, weightUnit: removed.weightUnit)
        exercise.sets.append(restored)
        lastRemoved = nil
        save()
    }

    private func removable(_ exercise: LocalSessionExercise) -> [RemovableSet] {
        sets(of: exercise).map { RemovableSet(order: $0.order, isWarmup: $0.isWarmup) }
    }

    // The engine returns the survivors in their new order; the stored rows follow it position by position
    private func renumber(_ exercise: LocalSessionExercise, to survivors: [RemovableSet]) {
        let stored = sets(of: exercise)
        for (index, row) in stored.enumerated() where index < survivors.count { row.order = survivors[index].order }
    }
}

// SPEC: A11 — what "Undo" needs to put a row back exactly as it was
struct RemovedSet: Equatable {
    let exerciseOrder: Int
    let order: Int
    let targetReps: Int
    let actualReps: Int
    let weight: Double?
    let weightUnit: String?
    let holdSeconds: Int?
    let isWarmup: Bool
}
