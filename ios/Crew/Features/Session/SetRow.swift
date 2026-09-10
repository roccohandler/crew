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
    let isOpen: Bool  // A10: the first not-done work set — the only row that carries the tape, so rows stay compact
    let canRemove: Bool // A11: false on the last work set — the control is simply absent (V55)
    let onSetWeight: (Double) -> Void
    let onRemove: () -> Void
    let onCheck: () -> Void
    let onReps: (Int) -> Void
    let onWeight: (Int) -> Void
    @State private var plateLine: String?
    @ScaledMetric private var minTarget: CGFloat = CGFloat(SpecConstants.minTouchTargetPt) // 6.5: the row grows with Dynamic Type
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    private var increaseContrast: Bool { contrast == .increased }

    private var weightText: String {
        guard let weight = set.weight else { return "—" }
        return weight.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(weight))" : "\(weight)"
    }

    // 6.7: one line where it fits (iPad, landscape); on a phone the steppers wrap under the set label — the row's fixed parts
    // (label, two 44-pt-button steppers, the check) are wider than any iPhone, and an HStack never shrinks them, so the row
    // pushed every card past the edge (run 34360394481: the session's Complete button measured 516 pt on a 402 pt window).
    // The web twin is .setrow's flex-wrap.
    var body: some View {
        // SPEC: Flow 3 — the plate line sits IN the layout now. It used to be an .overlay at .offset(y: 16), drawn
        // outside the row's own bounds on top of whatever followed, and `plateLine` was never cleared, so once shown it
        // stayed for the life of the row. It now takes space when present and clears on the next interaction.
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: EmberTokens.Spacing.space12) {
                    setLabel
                    steppers
                    Spacer(minLength: 0)
                    check
                }
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
                    HStack(spacing: EmberTokens.Spacing.space12) {
                        setLabel
                        Spacer(minLength: 0)
                        check
                    }
                    steppers
                }
            }
            tape
            if let plateLine {
                Text(plateLine).font(.caption).foregroundStyle(EmberColors.secondaryText)
                    .accessibilityLabel("Plates: \(plateLine)")
            }
        }
        // SPEC: 6.5 — a ghost row is quieter, but never below the 3:1 component gate, and never quieter at all when the
        // reader has asked for more contrast or less transparency (both are accessibility settings, not preferences)
        .opacity(isGhost && !reduceTransparency && !increaseContrast ? EmberTokens.Opacity.disabled : 1)
        .frame(minHeight: minTarget)
        .contentShape(Rectangle())
        .onTapGesture { plateLine = nil; onCheck() }
        // SPEC: A11 · 6.3 — the swipe reveals a real Remove button (SwipeToRemove; `.swipeActions` does nothing outside a
        // List and this screen is a ScrollView), and the same action is an accessibility action so the gesture is never the
        // only way in. On the last work set the engine refuses (V55), so `canRemove` is false and neither path is offered.
        .accessibilityAction(named: "Remove this set") { if canRemove { onRemove() } }
        // E20: to VoiceOver and to XCUITest the row IS its check button (below, carrying the whole "Bench press, set 3 of 3 …"
        // label), and the steppers stay reachable as their own "Decrease reps" / "Increase weight" buttons. A single element
        // spanning the wrapped row was activated at its centre — which on a phone is the weight stepper's minus (run
        // 34364030257: the tap that was meant to check set 1 set its weight to 0 instead).
        .accessibilityElement(children: .contain)
    }

    // "Machine Chest Press, set 1 of 3, 10 reps, 135 lb, done" — the one line VoiceOver and the journeys read for a set (E20)
    private var rowLabel: String {
        "\(exerciseName), \(set.isWarmup ? "warm-up" : "set \(index) of \(count)"), \(set.actualReps) reps\(set.weight == nil ? "" : ", \(weightText) \(units)")\(set.done ? ", done" : "")"
    }

    private var setLabel: some View {
        Text(set.isWarmup ? "Warm-up" : "Set \(index)").font(.subheadline).foregroundStyle(EmberColors.secondaryText).frame(minWidth: CGFloat(SpecConstants.minTouchTargetPt), alignment: .leading)
            .accessibilityHidden(true) // spoken by the check button's label
    }

    private var steppers: some View {
        HStack(spacing: EmberTokens.Spacing.space12) {
            Stepper(label: "\(set.actualReps) reps", noun: "reps", onStep: onReps)
            if equipment != "bodyweight", !isOpen {
                // A10: a row you are NOT on keeps the compact stepper — exactly one tape is on screen, on the set you are doing
                Stepper(label: "\(weightText) \(units)", noun: "weight", onStep: onWeight)
                    .onLongPressGesture(minimumDuration: Double(SpecConstants.longPressStepIntervalMs) / Double(TimeUnits.msPerSecond)) {
                        if equipment == "barbell", let weight = set.weight { plateLine = PlateMath.plateLine(totalWeight: weight, units: units) }
                    }
            }
        }
    }

    // SPEC: A10 — the open row gets the big readout, the ruler and a ± pair for a single-notch nudge (6.3: the drag
    // gesture keeps its visible-button equivalent). Plate math stays on a long press of the whole strip.
    @ViewBuilder
    private var tape: some View {
        if isOpen, equipment != "bodyweight" {
            HStack(spacing: EmberTokens.Spacing.space12) {
                StepButton(symbol: "minus", noun: "weight") { onWeight(-1) }
                WeightTape(weight: set.weight, unit: units, onSelect: onSetWeight, onStep: onWeight)
                StepButton(symbol: "plus", noun: "weight") { onWeight(1) }
            }
            .onLongPressGesture(minimumDuration: Double(SpecConstants.longPressStepIntervalMs) / Double(TimeUnits.msPerSecond)) {
                if equipment == "barbell", let weight = set.weight { plateLine = PlateMath.plateLine(totalWeight: weight, units: units) }
            }
        }
    }

    private var check: some View {
        Button(action: onCheck) {
            Image(systemName: set.done ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(set.done ? EmberColors.inkText : EmberColors.secondaryText)
                .frame(width: CGFloat(SpecConstants.minTouchTargetPt), height: CGFloat(SpecConstants.minTouchTargetPt))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(rowLabel)
        .accessibilityHint(set.done ? "Double-tap to undo" : "Double-tap to complete")
    }
}

// A stepper with ± buttons ≥ 44 pt; long-press repeats (Flow 3 fast-scroll). `noun` names what the buttons change to
// VoiceOver ("Decrease reps", "Increase weight") — a row holds two steppers, so a bare "Decrease" says nothing (E20)
struct Stepper: View {
    let label: String
    let noun: String
    let onStep: (Int) -> Void
    @ScaledMetric private var minTarget: CGFloat = CGFloat(SpecConstants.minTouchTargetPt)

    var body: some View {
        HStack(spacing: EmberTokens.Spacing.space4) {
            StepButton(symbol: "minus", noun: noun) { onStep(-1) }
            // SPEC: 6.3 — the readout swallows its own taps. It had no gesture of its own, so a tap on "135 lb" fell
            // through to the row's onTapGesture and CHECKED the set: a ~44×22 pt trap sitting exactly where a user aiming
            // to change the value taps. It is not yet a control (A10 makes it one); until then it must at least not lie.
            Text(label)
                .font(.body.monospacedDigit())
                .foregroundStyle(EmberColors.inkText)
                .frame(minWidth: minTarget) // a touch target's width, not the ring's: two steppers must share a 375-pt row (6.7)
                .contentShape(Rectangle())
                .onTapGesture {}
                .accessibilityHidden(true) // the value is spoken by the row's check button (E20)
            StepButton(symbol: "plus", noun: noun) { onStep(1) }
        }
    }
}

// SPEC: 6.3 (≥ 44 pt) · Flow 3 (long-press fast-scroll). Two defects fixed 2026-09-09, both found by the A9/A10 review:
// ① the 44 pt circle was DRAWN but not hittable — an Image's hit rect is the glyph (~16 pt) plus the 1 pt stroke, so
//    `.contentShape` is what makes the frame the target;
// ② the repeat loop double-fired and never stopped — `pressing(true)` fired `action()` at touch-down while
//    `.onTapGesture` fired it again on lift, and each press started a NEW recursive chain with no cancellation token,
//    so two quick presses left two chains ticking at once. Now one generation counter owns the loop: a press starts a
//    generation, release invalidates it, and the tap is the only single-step path.
struct StepButton: View {
    let symbol: String
    let noun: String
    let action: () -> Void
    @State private var generation = 0
    @ScaledMetric private var minTarget: CGFloat = CGFloat(SpecConstants.minTouchTargetPt) // 6.5: grows with Dynamic Type

    var body: some View {
        Image(systemName: symbol)
            .font(.body.weight(.semibold))
            .foregroundStyle(EmberColors.inkText)
            .frame(width: minTarget, height: minTarget)
            .overlay(Circle().stroke(EmberColors.hairline, lineWidth: EmberTokens.Size.hairline))
            .contentShape(Circle()) // the whole 44 pt circle is the target, not the glyph inside it
            .onTapGesture(perform: action)
            .onLongPressGesture(minimumDuration: Double(SpecConstants.autoAdvanceDelayMs) / Double(TimeUnits.msPerSecond), pressing: { pressing in
                generation += 1 // every press and every release invalidates whatever chain was running
                if pressing { repeatWhilePressed(generation) }
            }, perform: {})
            .accessibilityLabel(symbol == "plus" ? "Increase \(noun)" : "Decrease \(noun)")
    }

    // The first step of a hold comes from this loop; the tap gesture handles the single-step case, so a hold never
    // double-counts its own first step
    private func repeatWhilePressed(_ mine: Int) {
        guard generation == mine else { return }
        action()
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(SpecConstants.longPressStepIntervalMs)) { repeatWhilePressed(mine) }
    }
}
