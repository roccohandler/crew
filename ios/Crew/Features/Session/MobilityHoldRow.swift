// SPEC: Flow 3 mobility holds — duration-based: tap a hold → countdown runs → auto-check. No reps, no weight, ever. "90s each"
// runs twice for per-side holds. WRITTEN — UNVERIFIED (needs Mac). T025

import SwiftUI

struct MobilityHoldRow: View {
    let name: String
    let set: LocalSetLog
    let perSide: Bool
    let onFinished: () -> Void
    @State private var remaining: Int?
    @State private var sidesLeft = 1
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var seconds: Int { set.holdSeconds ?? 0 }

    var body: some View {
        Button(action: tap) {
            HStack(spacing: EmberTokens.Spacing.space12) {
                Text(name).font(.body).foregroundStyle(EmberColors.inkText)
                Spacer()
                Text(label).font(.body.monospacedDigit()).foregroundStyle(EmberColors.secondaryText)
                Image(systemName: set.done ? "checkmark.circle.fill" : (remaining == nil ? "play.circle" : "pause.circle"))
                    .font(.title2)
                    .foregroundStyle(set.done ? EmberColors.inkText : EmberColors.secondaryText)
            }
            .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear { sidesLeft = perSide ? SpecConstants.perSideHoldRepeats : 1 }
        .onReceive(timer) { _ in tick() }
        .accessibilityLabel("\(name), \(seconds) seconds\(perSide ? " each side" : "")\(set.done ? ", done" : "")")
        .accessibilityHint(set.done ? "" : "Double-tap to start the hold")
    }

    private var label: String {
        if set.done { return "\(seconds)s\(perSide ? " each" : "")" }
        if let remaining { return "\(remaining)s\(perSide && sidesLeft > 1 ? " · side 1" : "")" }
        return "\(seconds)s\(perSide ? " each" : "")"
    }

    private func tap() {
        guard !set.done else { return }
        remaining = remaining == nil ? seconds : nil
    }

    private func tick() {
        guard var left = remaining else { return }
        left -= 1
        if left > 0 { remaining = left; return }
        sidesLeft -= 1
        if sidesLeft > 0 {
            Haptics.play(.tick)
            remaining = seconds
            return
        }
        remaining = nil
        onFinished()
    }
}
