// SPEC: Flow 3 rest timer — a quiet inline countdown ("rest 1:12"), per-workout length, off-able. WRITTEN — UNVERIFIED. T025

import SwiftUI

struct RestTimerView: View {
    let timer: RestTimer
    @State private var now = Date()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: EmberTokens.Spacing.space8) {
            if timer.isRunning {
                Text("rest \(clock(timer.remaining(at: now)))").font(.subheadline.monospacedDigit()).foregroundStyle(EmberColors.secondaryText)
                Button("Skip") { timer.stop() }.font(.subheadline).foregroundStyle(EmberColors.inkText)
            } else {
                Button(timer.enabled ? "Rest \(clock(timer.lengthSeconds))" : "Rest timer off") { timer.enabled.toggle() }
                    .font(.subheadline)
                    .foregroundStyle(EmberColors.secondaryText)
                if timer.enabled {
                    Button("−") { timer.lengthSeconds = max(SpecConstants.restTimerAdjustStepSeconds, timer.lengthSeconds - SpecConstants.restTimerAdjustStepSeconds) }.accessibilityLabel("Shorter rest")
                    Button("+") { timer.lengthSeconds += SpecConstants.restTimerAdjustStepSeconds }.accessibilityLabel("Longer rest")
                }
            }
        }
        .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt))
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
