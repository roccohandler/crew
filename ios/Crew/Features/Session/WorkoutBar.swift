// SPEC: A28 (d), (f) (owner-approved 2026-09-19; design/targets 07–10) — the segmented workout bar (system §8): one group per
// exercise, one segment per work set (warm-ups never count, Flow 3), the mobility holds as ONE group at the end (the checklist is
// one screen). 4 pt between segments, 14 pt between groups; the current exercise's segments are 8 pt tall and the rest 6 pt. Done
// is ink, the set on screen is segmentCurrent, pending is segmentEmpty — never accent (§11: the bar is ink). Each group is a 44 pt
// tall button that jumps to its exercise; the whole-workout sheet is the full-size way to the same place, which matters when a
// long workout makes a group narrower than a fingertip (docs/debt.md). WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct WorkoutBar: View {
    let model: SessionModel
    @ScaledMetric private var barHeight: CGFloat = CGFloat(SpecConstants.minTouchTargetPt)

    var body: some View {
        // Every segment is the same width, so a group is as wide as its sets (mockup 07: three, three, then the holds as one)
        GeometryReader { proxy in
            let all = groups
            let count = all.reduce(0) { $0 + $1.segments.count }
            let gaps = CGFloat(max(all.count - 1, 0)) * EmberTokens.Focus.segmentGroupGap + CGFloat(max(count - all.count, 0)) * EmberTokens.Focus.segmentGap
            let unit = count > 0 ? max(proxy.size.width - gaps, 0) / CGFloat(count) : 0
            HStack(spacing: EmberTokens.Focus.segmentGroupGap) {
                ForEach(all, id: \.order) { group in
                    Button { model.jumpTo(group.exercise) } label: {
                        HStack(spacing: EmberTokens.Focus.segmentGap) {
                            ForEach(Array(group.segments.enumerated()), id: \.offset) { _, state in segment(state, current: group.isCurrent).frame(width: unit) }
                        }
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(group.label)
                    .accessibilityAddTraits(group.isCurrent ? .isSelected : [])
                }
            }
        }
        .frame(height: barHeight)
    }

    private func segment(_ state: Segment, current: Bool) -> some View {
        let radius = current ? EmberTokens.Focus.segmentRadiusCurrent : EmberTokens.Focus.segmentRadius
        return RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(color(state))
            .frame(height: current ? EmberTokens.Focus.segmentHeightCurrent : EmberTokens.Focus.segmentHeight)
    }

    private func color(_ state: Segment) -> Color {
        switch state {
        case .done: return EmberColors.ink
        case .onScreen: return EmberColors.segmentCurrent
        case .pending: return EmberColors.segmentEmpty
        }
    }

    enum Segment { case done, onScreen, pending }

    struct ExerciseGroup {
        let exercise: LocalSessionExercise
        let order: Int
        let segments: [Segment]
        let isCurrent: Bool
        let label: String
    }

    // SPEC: A28 (d) — the groups, in the workout's order, with the checklist's holds folded into one at the end
    private var groups: [ExerciseGroup] {
        let focused = model.focused
        var result: [ExerciseGroup] = []
        for exercise in model.exercises where exercise.type != "mobility" {
            let isCurrent = focused?.order == exercise.order
            let shown = isCurrent ? model.displayedSet(of: exercise) : nil
            let work = model.workSets(of: exercise)
            let segments: [Segment] = work.map { $0.done ? .done : ($0 === shown ? .onScreen : .pending) }
            let done = work.filter(\.done).count
            let label = "\(exercise.name), \(exercise.skipped ? "skipped" : "\(done) of \(work.count) sets done")"
            result.append(ExerciseGroup(exercise: exercise, order: exercise.order, segments: segments, isCurrent: isCurrent, label: label))
        }
        if let first = model.holds.first {
            let done = model.holds.filter { hold in model.sets(of: hold).allSatisfy(\.done) }.count
            let all = done == model.holds.count
            let segment: Segment = all ? .done : (model.isOnChecklist ? .onScreen : .pending)
            result.append(ExerciseGroup(exercise: first, order: first.order, segments: [segment], isCurrent: model.isOnChecklist, label: "Mobility, \(done) of \(model.holds.count) holds done"))
        }
        return result
    }
}
