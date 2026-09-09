// SPEC: A4 (owner-directed 2026-09-08) · G3 — the editor's words and bounds, on the draft so the screens hold zero logic
// (5.6.6): a row reads `{name}` / `{sets} × {reps} · {Equipment}`, a cardio row `{Activity} · {min} min`, a hold
// `{name} · {s}s each`; stepper bounds come from the constants (a rep range moves as a unit); Move up / Move down know
// their edges; the Undo snackbar names the removed row. WRITTEN — UNVERIFIED (needs Mac).

import Foundation

extension WorkoutDraft {
    static let setsBounds = 1...SpecConstants.planMaxSetsPerExercise
    static let minutesBounds = SpecConstants.cardioMinutesMin...SpecConstants.cardioMinutesMax

    // SPEC: G3 · A4 — 1…planTargetRepsMax; a range keeps its width, so its ceiling is the max minus that width
    func repsBounds(order: Int) -> ClosedRange<Int> {
        let span = row(order: order).flatMap { row in row.targetRepsMax.map { $0 - row.targetReps } } ?? 0
        return 1...max(1, SpecConstants.planTargetRepsMax - span)
    }

    func canReorder(order: Int, direction: Int) -> Bool {
        guard let index = rows.firstIndex(where: { $0.order == order }) else { return false }
        return rows.indices.contains(index + direction)
    }

    var removedName: String? { removed?.row.name }
    var isEmpty: Bool { rows.isEmpty }

    var fullLine: String { "\(name) is full · \(SpecConstants.planMaxExercisesPerDay) exercises" }
    var emptyLine: String { "No exercises yet — add one to build \(name)" }
    var discardTitle: String { "Discard changes to \(name)?" }
    var removeTitle: String { "Remove from \(name)" }

    static func minutes(of row: PlanDraftExercise) -> Int { (row.holdSeconds ?? 0) / TimeUnits.secondsPerMinute }

    static func repsText(_ row: PlanDraftExercise) -> String {
        row.targetRepsMax.map { "\(row.targetReps)–\($0)" } ?? "\(row.targetReps)"
    }

    // SPEC: A4 — one line per row in the list; a cardio block carries its minutes in the title
    static func title(of row: PlanDraftExercise) -> String {
        row.type == "cardio" ? "\(row.name) · \(minutes(of: row)) min" : row.name
    }

    static func detail(of row: PlanDraftExercise) -> String? {
        row.type == "cardio" ? nil : "\(row.targetSets) × \(repsText(row)) · \(row.equipment.capitalized)"
    }

    // Flow 3: a hold is duration only — never sets, reps or weight
    static func holdLine(_ hold: PlanDraftExercise) -> String {
        "\(hold.name) · \(hold.holdSeconds ?? 0)s\((hold.perSide ?? false) ? " each" : "")"
    }
}
