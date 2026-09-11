// SPEC: Flow 3 rest timer — a quiet inline countdown ("rest 1:12"), per-workout length, off-able. It renders INSIDE the
// current exercise card (2026-09-09): as a single view after the last card it was off-screen for any workout longer than
// one card, so the countdown a lifter starts by checking a set could not be seen while it ran. 6.3: every control here is
// its own ≥ 44 pt target. WRITTEN — UNVERIFIED. T025

import SwiftUI

struct RestTimerView: View {
    let timer: RestTimer
    @State private var now = Date()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @ScaledMetric private var minTarget: CGFloat = CGFloat(SpecConstants.minTouchTargetPt)

    var body: some View {
        HStack(spacing: EmberTokens.Spacing.space8) {
            if timer.isRunning {
                Text("rest \(clock(timer.remaining(at: now)))").font(.subheadline.monospacedDigit()).foregroundStyle(EmberColors.secondaryText)
                // SPEC: 6.3 — the `minHeight` below sizes this HStack, not the buttons inside it, so both of these were
                // hit-tested at their text box. The comment at the top of this file already claimed "every control here is
                // its own ≥ 44 pt target"; that is now true rather than asserted.
                TextActionButton(title: "Skip", horizontalPadding: 0, accessibilityLabel: "Skip the rest timer") { timer.stop() }
            } else {
                TextActionButton(title: timer.enabled ? "Rest \(clock(timer.lengthSeconds))" : "Rest timer off",
                                 color: EmberColors.secondaryText,
                                 horizontalPadding: 0,
                                 accessibilityLabel: timer.enabled ? "Rest timer on, \(clock(timer.lengthSeconds)). Turn it off." : "Rest timer off. Turn it on.") { timer.enabled.toggle() }
                if timer.enabled {
                    StepButton(symbol: "minus", noun: "rest") { timer.lengthSeconds = max(SpecConstants.restTimerAdjustStepSeconds, timer.lengthSeconds - SpecConstants.restTimerAdjustStepSeconds) }
                    StepButton(symbol: "plus", noun: "rest") { timer.lengthSeconds += SpecConstants.restTimerAdjustStepSeconds }
                }
            }
        }
        .frame(minHeight: minTarget)
        .onReceive(ticker) { tickNow in
            now = tickNow
            _ = timer.tick(now: tickNow)
        }
    }

    private func clock(_ seconds: Int) -> String {
        let minutes = seconds / TimeUnits.secondsPerMinute
        let rest = seconds % TimeUnits.secondsPerMinute
        return String(format: "%d:%02d", minutes, rest)
    }
}
