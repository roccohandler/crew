// SPEC: A3 (owner-directed 2026-09-08) — the what's-next line: "Tomorrow: Pull day · 5 exercises" when the next planned
// day is tomorrow, else "Next workout: Wed · Pull day"; nothing on an undone training day; the bridge on a rest-day install
// reads "Tomorrow: Push day — your first workout." (1D: nothing else competes). A1 — the names come from the rotation
// projection: the pointer is DERIVED from history (the latest completed session whose kind is in the plan's cycle), never
// stored. Plain functions mirroring web/src/lib/today-state.ts (rotationFor · kindOn · whatsNext) so the Home card, the
// bonus list and the Plan week map read one projection. The view is one ink line. WRITTEN — UNVERIFIED (needs Mac).

import Foundation
import SwiftUI

struct Rotation: Equatable {
    let cycle: [String]
    let nextKind: String?       // nil when the plan has no workouts
    let week: [DayProjection]   // Mon..Sun of the week holding todayKey; empty without a cycle
}

// SPEC: A18.3 — the what's-next fact, split so the block can title it and the bridge card can say it as one sentence.
// Twin of web/src/lib/today-state.ts NextUpFacts.
struct NextUpFacts: Equatable {
    let heading: String  // "Tomorrow" · "Next workout"
    let detail: String   // "Leg day · 5 exercises" · "Sun · Leg day"
}

@MainActor
enum NextUp {
    // SPEC: A1 — cycle = the plan's workouts in stored order; the pointer from Store.lastCompletedRotationKind (every completed
    // session on the phone); this week's done days keyed by dayKey so projectWeek can mark them (a cardio log, A2, is outside
    // the cycle and never counts)
    static func rotationFor(userId: String, plan: LocalPlan, todayKey: String, store: Store) throws -> Rotation {
        let cycle = plan.workouts.sorted { $0.order < $1.order }.map(\.kind)
        guard !cycle.isEmpty else { return Rotation(cycle: [], nextKind: nil, week: []) }
        let lastKind = try store.lastCompletedRotationKind(for: userId, cycle: cycle)
        let nextKind = PlanRotation.nextWorkoutKind(lastCompletedKind: lastKind, cycle: cycle)
        let weekKey = DayKey.weekKey(for: todayKey)
        var completedKindByDay: [String: String] = [:]
        for session in try store.completedSessions(for: userId) where session.dayKey >= weekKey && completedKindByDay[session.dayKey] == nil {
            guard let kind = session.workoutKind ?? PlanRotation.workoutKindFromName(session.workoutName), cycle.contains(kind) else { continue }
            completedKindByDay[session.dayKey] = kind
        }
        let week = PlanRotation.projectWeek(weekKey: weekKey, todayKey: todayKey, trainingWeekdays: plan.trainingWeekdays, cycle: cycle, nextKind: nextKind, completedKindByDay: completedKindByDay)
        return Rotation(cycle: cycle, nextKind: nextKind, week: week)
    }

    // The kind a training day gets: from this week's projection, or continuing the sequence past this week's planned days
    static func kindOn(_ dayKey: String, rotation: Rotation) -> String? {
        if let kind = rotation.week.first(where: { $0.dayKey == dayKey })?.kind { return kind }
        guard var kind = rotation.nextKind else { return nil }
        for _ in rotation.week.filter({ $0.state == .planned }) { kind = PlanRotation.nextWorkoutKind(lastCompletedKind: kind, cycle: rotation.cycle) }
        return kind
    }

    // SPEC: A3 · A18.3 — the what's-next fact in TWO halves, because it now renders in two shapes: inside the bridge
    // card as one sentence ("Tomorrow: Push day — your first workout.") and, on rest / all-done / paused, as a titled
    // BLOCK in the space above the card, where repeating the label in the heading AND the line would read
    // "NEXT UP / Next workout: Sun · Leg day". One computation, two shapes — the alternative is two code paths that
    // drift, which is the defect WeekSummary was written to avoid.
    static func nextUpFacts(todayKey: String, plan: LocalPlan, rotation: Rotation, bridge: Bool) -> NextUpFacts? {
        guard let nextDay = PlanRotation.nextTrainingDayKey(afterDayKey: todayKey, trainingWeekdays: plan.trainingWeekdays),
              let workout = plan.workouts.first(where: { $0.kind == kindOn(nextDay, rotation: rotation) }) else { return nil }
        let weekday = DayLabel.weekdayNames[DayKey.isoWeekday(nextDay) - 1]
        guard nextDay == DayKey.addDays(todayKey, 1) else { return NextUpFacts(heading: "Next workout", detail: "\(weekday) · \(workout.name)") }
        if bridge { return NextUpFacts(heading: "Tomorrow", detail: "\(workout.name) — your first workout.") }
        let count = strengthCount(workout)
        return NextUpFacts(heading: "Tomorrow", detail: "\(workout.name) · \(count) \(count == 1 ? "exercise" : "exercises")")
    }

    // SPEC: A3 — the one-sentence form, unchanged byte for byte: "Tomorrow: Pull day · 5 exercises" / "Next workout:
    // Wed · Pull day". Derived from the facts above so the two can never say different things.
    static func whatsNext(todayKey: String, plan: LocalPlan, rotation: Rotation, bridge: Bool) -> String? {
        nextUpFacts(todayKey: todayKey, plan: plan, rotation: rotation, bridge: bridge).map { "\($0.heading): \($0.detail)" }
    }

    // SPEC: A3 — the bonus sheet lists the plan's workouts with the next rotation workout first
    static func bonusOrder(_ workouts: [LocalWorkoutTemplate], nextKind: String?) -> [LocalWorkoutTemplate] {
        let ordered = workouts.sorted { $0.order < $1.order }   // A1: a SwiftData to-many keeps no order of its own
        guard let index = ordered.firstIndex(where: { $0.kind == nextKind }) else { return ordered }
        return Array(ordered[index...]) + Array(ordered[..<index])
    }

    static func strengthCount(_ workout: LocalWorkoutTemplate) -> Int {
        workout.exercises.filter { $0.type == "strength" }.count
    }

    static func hasCardio(_ workout: LocalWorkoutTemplate) -> Bool {
        workout.exercises.contains { $0.type == "cardio" }
    }

    // SPEC: Flow 2 ("5 exercises + mobility") · A2 (" + cardio" when the workout carries a cardio block)
    static func sizeLine(exerciseCount: Int, hasCardio: Bool) -> String {
        "\(exerciseCount) \(exerciseCount == 1 ? "exercise" : "exercises") + mobility\(hasCardio ? " + cardio" : "")"
    }
}

// The one ink line: no chrome, no orange, never a control (Part III law ①). Still used by the BRIDGE card, where
// §1D allows exactly one CTA plus this line and nothing else.
struct NextUpLine: View {
    let line: String

    var body: some View {
        Text(line)
            .font(.subheadline)
            .foregroundStyle(EmberColors.inkText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(line)
    }
}

// SPEC: A18.3 — the what's-next fact as a titled block, in the space that used to be empty. It renders ONLY on the
// idle states (rest · all-done · paused): on a workout day the card already IS what is next, and that state is the
// tallest one on the smallest phone (H009). Ink detail under a secondaryText caption; never a control (law ①),
// never orange (law ③) — tapping it would give Home a second destination, which is the Plan tab's job.
struct NextUpBlock: View {
    let facts: NextUpFacts

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.rowGap) {
            Text(facts.heading.uppercased())
                .font(.caption)
                .foregroundStyle(EmberColors.secondaryText)
            Text(facts.detail)
                .font(.title3.weight(.semibold))
                .foregroundStyle(EmberColors.inkText)
                .fixedSize(horizontal: false, vertical: true) // 6.7: a long workout name wraps, it never widens the column
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // E20 — one stop, one sentence: "Next workout, Sun · Leg day" rather than a caption and a fragment
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(facts.heading), \(facts.detail)")
    }
}
