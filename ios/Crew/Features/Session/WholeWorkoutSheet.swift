// SPEC: A28 (d) (owner-approved 2026-09-19; design/targets 09) — the whole-workout sheet (system §7's sheet: a grabber, a title
// row, row buttons, one filled button). Each exercise is a row button with its done-of count and its own small segment row; the
// holds are one row ("Mobility · 4 holds"); the row on screen is tinted one step off the sheet. It CARRIES FINISH — the one way to
// end a workout early (R-083 (21): the checklist's Finish ends it at the end). Job (R-083 (24)): jump between exercises, finish.
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct WholeWorkoutSheet: View {
    let model: SessionModel
    let onJump: (LocalSessionExercise) -> Void
    let onFinish: () -> Void
    // mockup 09 sizes the sheet to its title row, rows and Finish, with the Logger dimmed above it: a large detent left ~290 pt of
    // empty sheet (ui-reviewer, run 35447860873 · R-094); a height past the screen clamps to large, and the rows still scroll
    @State private var rowsHeight: CGFloat = 0
    @State private var footHeight: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space12) {
                        Text(model.session.workoutName).typeRole(EmberTokens.Typography.sheetTitle).foregroundStyle(EmberColors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: EmberTokens.Spacing.space8)
                        Text(numerals: model.countLine).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
                    }
                    .padding(.horizontal, EmberTokens.Focus.gutter)
                    .padding(.top, EmberTokens.Focus.gutter)
                    .padding(.bottom, EmberTokens.Spacing.space12)
                    ForEach(model.exercises.filter { $0.type != "mobility" }, id: \.order) { exercise in
                        seam
                        row(exercise.name, value: value(of: exercise), segments: exercise, isCurrent: model.focused?.order == exercise.order) { onJump(exercise) }
                    }
                    if let first = model.holds.first {
                        seam
                        let count = model.holds.count
                        row("Mobility", value: "\(count) \(count == 1 ? "hold" : "holds")", segments: nil, isCurrent: model.isOnChecklist) { onJump(first) }
                    }
                }
                .background(GeometryReader { proxy in Color.clear.onAppear { rowsHeight = proxy.size.height } })
            }
            VStack(spacing: EmberTokens.Spacing.space8) {
                if let error = model.completeError { Text(error).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.ink) }
                PrimaryButton(title: "Finish workout", action: onFinish)
            }
            .padding(.horizontal, EmberTokens.Focus.gutter)
            .padding(.vertical, EmberTokens.Spacing.space12)
            .background(GeometryReader { proxy in Color.clear.onAppear { footHeight = proxy.size.height } })
        }
        .background(EmberColors.card.ignoresSafeArea())
        // the whole list, Mobility (its last row) included, above Finish — never the medium detent that hid it (run 35444308817)
        .presentationDetents(rowsHeight > 0 ? [.height(rowsHeight + footHeight + EmberTokens.Focus.gutter)] : [.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(EmberTokens.Focus.cardRadius)
    }

    private var seam: some View {
        Rectangle().fill(EmberColors.hairlineOnCard).frame(height: EmberTokens.Size.hairline)
    }

    private func value(of exercise: LocalSessionExercise) -> String {
        if exercise.skipped { return "Skipped" }
        let work = model.workSets(of: exercise)
        return "\(work.filter(\.done).count) of \(work.count)"
    }

    // SPEC: A28 (f) — the row button (§8): name, value, chevron, 56 pt minimum; the current row tinted one step off the sheet
    private func row(_ name: String, value: String, segments exercise: LocalSessionExercise?, isCurrent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: EmberTokens.Spacing.space12) {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
                    Text(name).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let exercise { miniSegments(exercise) }
                }
                Spacer(minLength: EmberTokens.Spacing.space8)
                Text(numerals: value).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
                Image(systemName: "chevron.right").foregroundStyle(EmberColors.chevron)
            }
            .padding(.horizontal, EmberTokens.Focus.gutter)
            .padding(.vertical, EmberTokens.Spacing.space12)
            .frame(maxWidth: .infinity, minHeight: EmberTokens.Focus.rowButton, alignment: .leading)
            .background(isCurrent ? EmberColors.canvas : .clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(name), \(value)")
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    // The exercise's own sets, in the bar's colours: done ink, the set on screen segmentCurrent, pending segmentEmpty
    private func miniSegments(_ exercise: LocalSessionExercise) -> some View {
        let shown = model.focused?.order == exercise.order ? model.displayedSet(of: exercise) : nil
        return HStack(spacing: EmberTokens.Focus.segmentGap) {
            ForEach(Array(model.workSets(of: exercise).enumerated()), id: \.offset) { _, set in
                RoundedRectangle(cornerRadius: EmberTokens.Focus.segmentRadius, style: .continuous)
                    .fill(set.done ? EmberColors.ink : (set === shown ? EmberColors.segmentCurrent : EmberColors.segmentEmpty))
                    .frame(height: EmberTokens.Focus.segmentHeight)
            }
        }
        .accessibilityHidden(true) // the row's value says it
    }
}
