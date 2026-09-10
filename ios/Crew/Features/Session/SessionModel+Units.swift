// SPEC: A9 (owner-directed 2026-09-09) — everything about the unit a weight is written in: the in-context confirm, answered once at the first moment it matters (the
// top of the first Session screen). Split from SessionModel.swift for the C9 200-line cap, exactly as
// SettingsModel+Notifications.swift is split from SettingsModel.swift, and it carries the A9/A10 weight writers with it.
// WRITTEN — UNVERIFIED (needs Mac).

import Foundation

extension SessionModel {
    // SPEC: A9 — a per-device flag, not a server field: the question is "is this phone logging in the right unit", and a
    // signed-out phone must be able to answer it. A preference, so UserDefaults is right — 8.7 reserves the Keychain for tokens.
    static var unitsConfirmedKey: String { "unitsConfirmed" }

    static func storedUnitsConfirmed() -> Bool {
        UserDefaults.standard.bool(forKey: unitsConfirmedKey)
    }

    // Keeping the default only records the answer; nothing about the account changes
    func confirmUnits() {
        unitsConfirmed = true
        UserDefaults.standard.set(true, forKey: SessionModel.unitsConfirmedKey)
    }

    // SPEC: A9 — flipping switches the account too. Every set logged from here carries the new unit; every set already
    // logged keeps the unit it was ENTERED in, so nothing in the history is reinterpreted by this tap.
    func flipUnits() async {
        let flipped = units == "lb" ? "kg" : "lb"
        units = flipped
        confirmUnits()
        if let user = try? await Api.shared.updateMe(UpdateMeRequestDTO(weightUnit: flipped)) { AuthStore.shared.updateCurrentUser(user) }
    }

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

    // SPEC: A10 — the tape and the keypad set a weight outright rather than nudging it. Clamped on commit, so Flow 3's
    // "invalid values impossible" holds for a typed number too; stamped with today's unit like every other weight (A9).
    func setWeight(_ set: LocalSetLog, to weight: Double) {
        set.weight = min(max(weight, 0), Double(SpecConstants.setWeightMax))
        set.weightUnit = units
        save()
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
