// SPEC: Flow 3 set row — "Set 3 [ 8 ] [ 135 lb ] ○"; tap the row → ✓ at the pre-filled numbers; steppers only on the open row;
// "—" is a complete set forever (weight invisible until invited; bodyweight = no weight chip); plate math on tap-hold of a
// barbell weight; VoiceOver: "Bench press, set 3 of 3 … double-tap to complete" (E20). WRITTEN — UNVERIFIED. T025

import SwiftUI

struct SetRow: View {
    let exerciseName: String
    let equipment: String
    let set: LocalSetLog
    let index: Int
    let count: Int
    let units: String
    let isGhost: Bool // the pre-cloned next set (Flow 3 "same again")
    let onCheck: () -> Void
    let onReps: (Int) -> Void
    let onWeight: (Int) -> Void
    @State private var plateLine: String?

    private var weightText: String {
        guard let weight = set.weight else { return "—" }
        return weight.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(weight))" : "\(weight)"
    }

    var body: some View {
        HStack(spacing: EmberTokens.Spacing.space12) {
            Text(set.isWarmup ? "Warm-up" : "Set \(index)").font(.subheadline).foregroundStyle(EmberColors.secondaryText).frame(minWidth: EmberTokens.Size.ringDiameter, alignment: .leading)
            Stepper(label: "\(set.actualReps) reps", onStep: onReps)
            if equipment != "bodyweight" {
                Stepper(label: "\(weightText) \(units)", onStep: onWeight)
                    .onLongPressGesture(minimumDuration: Double(SpecConstants.longPressStepIntervalMs) / Double(TimeUnits.msPerSecond)) {
                        if equipment == "barbell", let weight = set.weight { plateLine = PlateMath.plateLine(totalWeight: weight, units: units) }
                    }
            }
            Spacer()
            Button(action: onCheck) {
                Image(systemName: set.done ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(set.done ? EmberColors.inkText : EmberColors.secondaryText)
                    .frame(width: CGFloat(SpecConstants.minTouchTargetPt), height: CGFloat(SpecConstants.minTouchTargetPt))
            }
            .buttonStyle(.plain)
        }
        .opacity(isGhost ? EmberTokens.Opacity.disabled : 1)
        .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt))
        .contentShape(Rectangle())
        .onTapGesture(perform: onCheck)
        .overlay(alignment: .bottomLeading) {
            if let plateLine { Text(plateLine).font(.caption).foregroundStyle(EmberColors.secondaryText).offset(y: EmberTokens.Spacing.space16) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(exerciseName), \(set.isWarmup ? "warm-up" : "set \(index) of \(count)"), \(set.actualReps) reps\(set.weight.map { ", \($0) \(units)" } ?? "")\(set.done ? ", done" : "")")
        .accessibilityHint(set.done ? "Double-tap to undo" : "Double-tap to complete")
    }
}

// A stepper with ± buttons ≥ 44 pt; long-press repeats (Flow 3 fast-scroll)
struct Stepper: View {
    let label: String
    let onStep: (Int) -> Void

    var body: some View {
        HStack(spacing: EmberTokens.Spacing.space4) {
            StepButton(symbol: "minus") { onStep(-1) }
            Text(label).font(.body.monospacedDigit()).foregroundStyle(EmberColors.inkText).frame(minWidth: EmberTokens.Size.ringDiameter)
            StepButton(symbol: "plus") { onStep(1) }
        }
    }
}

struct StepButton: View {
    let symbol: String
    let action: () -> Void
    @State private var repeating = false

    var body: some View {
        Image(systemName: symbol)
            .font(.body.weight(.semibold))
            .foregroundStyle(EmberColors.inkText)
            .frame(width: CGFloat(SpecConstants.minTouchTargetPt), height: CGFloat(SpecConstants.minTouchTargetPt))
            .overlay(Circle().stroke(EmberColors.hairline, lineWidth: EmberTokens.Size.hairline))
            .onTapGesture(perform: action)
            .onLongPressGesture(minimumDuration: Double(SpecConstants.autoAdvanceDelayMs) / Double(TimeUnits.msPerSecond), pressing: { pressing in
                repeating = pressing
                if pressing { repeatWhilePressed() }
            }, perform: {})
            .accessibilityLabel(symbol == "plus" ? "Increase" : "Decrease")
    }

    private func repeatWhilePressed() {
        guard repeating else { return }
        action()
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(SpecConstants.longPressStepIntervalMs)) { repeatWhilePressed() }
    }
}
