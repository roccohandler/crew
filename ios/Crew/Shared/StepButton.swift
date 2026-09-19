// SPEC: 6.3 (≥ 44 pt) · Flow 3 ("Reps ±1 · weight ±5 lb/±2.5 kg · long-press fast-scroll") · nutrition addendum §4 (the gram
// steppers) — the one ± button: the Logger's set card, the plan's exercise sheet (both in A28 (f)'s 52 pt `focus` form) and the
// gram fields use it (its third user moved it here, C5).
// ONE TAP IS ONE STEP. It was two: CI run 35340692297 (journey ⑤, the first test ever to tap one and read the number back) showed
// two taps on "Increase Protein" adding 20 g, not 10 — `pressing(true)` fired `action()` at touch-down and `.onTapGesture` fired it
// again on lift, which is F07 of the 2026-09-09 review, never actually fixed by W019. Now:
//   · the TAP is the only single-step path;
//   · a HOLD starts stepping only after the hold threshold (autoAdvanceDelayMs), then every longPressStepIntervalMs — so a finger
//     that merely starts a scroll on the button changes nothing;
//   · the long-press never "succeeds" (minimumDuration is infinite), so `pressing` is exactly finger-down / finger-up and the chain
//     stops at the lift, not at the threshold; the tap that follows a hold adds nothing (`steppedWhileHeld`).
// One generation counter owns the chain: every press and every release invalidates whatever was ticking.
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct StepButton: View {
    let symbol: String
    let noun: String
    var focus = false // A28 (f): the system's stepper — a 52 pt circle, a 1.5 pt controlBorder ring, a 22 pt ink glyph (redesigned screens)
    let action: () -> Void
    @State private var generation = 0
    @State private var steppedWhileHeld = false
    @ScaledMetric private var minTarget: CGFloat = CGFloat(SpecConstants.minTouchTargetPt) // 6.5: grows with Dynamic Type
    @ScaledMetric private var focusDiameter: CGFloat = EmberTokens.Focus.stepper
    @ScaledMetric private var focusGlyph: CGFloat = EmberTokens.Focus.stepperGlyph

    var body: some View {
        Image(systemName: symbol)
            .font(focus ? .system(size: focusGlyph, weight: .medium) : .body.weight(.semibold))
            .foregroundStyle(EmberColors.ink)
            .frame(width: focus ? focusDiameter : minTarget, height: focus ? focusDiameter : minTarget)
            // A18.11 — the plus/minus on every set: a control boundary, so controlOutline (3.32:1 on a card, 3.13:1 on the canvas) and
            // never the 1.26:1 hairline family, which is for the seam between two surfaces. A28 (f) / R-083 (2): the system's stepper
            // draws a ~1.6:1 controlBorder ring and is identified by its ink glyph, which clears 3:1.
            .overlay(Circle().stroke(focus ? EmberColors.controlBorder : EmberColors.controlOutline, lineWidth: focus ? EmberTokens.Focus.stepperBorder : EmberTokens.Size.hairline))
            .contentShape(Circle()) // the whole 44 pt circle is the target, not the glyph inside it
            .onTapGesture { if !steppedWhileHeld { action() } }
            .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                generation += 1 // every press and every release invalidates whatever chain was running
                if pressing {
                    steppedWhileHeld = false
                    stepWhileHeld(generation, afterMs: SpecConstants.autoAdvanceDelayMs)
                }
            }, perform: {})
            .accessibilityLabel(symbol == "plus" ? "Increase \(noun)" : "Decrease \(noun)")
    }

    // The hold's chain: nothing until the threshold, then one step per interval for as long as this press is still the current one
    private func stepWhileHeld(_ mine: Int, afterMs delay: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay)) {
            guard generation == mine else { return }
            steppedWhileHeld = true
            action()
            stepWhileHeld(mine, afterMs: SpecConstants.longPressStepIntervalMs)
        }
    }
}

