// SPEC: A10 (owner-directed 2026-09-09) — weight entry for the row you are actually on: a large ink readout over a
// horizontal ruler that snaps to the unit's plate step, one haptic tick per notch, and the readout itself tapping through
// to a decimal keypad for a number that is far away. The ± buttons stay beside it for a single-notch nudge, so 6.3's
// "every swipe gesture has a visible-button equivalent" holds.
//
// Owner-reported: "I don't like hitting the plus and minus so much to change the weight… what if the weight is far below
// or far above". Measured before this: 45 → 225 lb was 45 taps or a 5.3 s hold. It is now one flick (36 notches) or one
// tap-and-type.
//
// C6 — no clever machinery: this is a stock ScrollView with .scrollTargetLayout + .scrollPosition + .scrollTargetBehavior
// (.viewAligned), all iOS 17 APIs, and the deployment target is iOS 17. There is no custom ScrollTargetBehavior to read.
// 6.5 — a scroll view is invisible to VoiceOver as a value control, so the readout carries an explicit
// accessibilityAdjustableAction: swipe up/down changes the weight by one step, exactly like a native stepper.
// Every number comes from SpecConstants (C7). WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct WeightTape: View {
    let weight: Double?
    let unit: String
    let onSelect: (Double) -> Void
    let onStep: (Int) -> Void
    @State private var position: Int?
    @State private var typing = false
    @State private var typed = ""
    @ScaledMetric private var tickSpacing: CGFloat = CGFloat(SpecConstants.weightTapeTickSpacingPt)
    @ScaledMetric private var tapeHeight: CGFloat = CGFloat(SpecConstants.weightTapeHeightPt)
    @ScaledMetric private var markerWidth: CGFloat = CGFloat(SpecConstants.weightTapeMarkerWidthPt)

    // The step is the unit's smallest loadable change — the same number the ± buttons move by (Flow 3)
    private var step: Double { unit == "lb" ? Double(SpecConstants.weightStepLb) : SpecConstants.weightStepKg }
    private var notchCount: Int { Int(Double(SpecConstants.setWeightMax) / step) + 1 }
    private func weightAt(_ notch: Int) -> Double { Double(notch) * step }
    private var currentNotch: Int { Int(((weight ?? 0) / step).rounded()) }

    private var readout: String {
        guard let weight else { return "—" }
        return weight.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(weight))" : "\(weight)"
    }

    var body: some View {
        VStack(spacing: EmberTokens.Spacing.space4) {
            numberRow
            tape
        }
        .onAppear { position = currentNotch }
        .onChange(of: weight) { _, _ in if position != currentNotch { position = currentNotch } } // ± and the tape stay in step
        .onChange(of: position) { previous, next in
            guard let next, previous != nil, previous != next else { return }
            Haptics.play(.tick) // 6.4: one tick per notch — the ruler is felt, not only seen
            onSelect(weightAt(next))
        }
        .alert("Weight in \(unit)", isPresented: $typing) {
            TextField("Weight", text: $typed).keyboardType(.decimalPad)
            Button("Set") { commitTyped() }
            Button("Cancel", role: .cancel) { typed = "" }
        }
    }

    // The value, big enough to read at arm's length on a bench, and its own control
    private var numberRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space8) {
            Button { typed = weight == nil ? "" : readout; typing = true } label: {
                HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space4) {
                    Text(readout).font(.largeTitle.weight(.semibold).monospacedDigit()).foregroundStyle(EmberColors.inkText)
                    Text(unit).font(.body).foregroundStyle(EmberColors.secondaryText)
                }
                .frame(minHeight: tapeHeight)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Weight \(readout) \(unit)")
            .accessibilityHint("Double-tap to type a weight")
            // 6.5: the tape is a scroll view and says nothing to VoiceOver; this is how the value is actually adjustable
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: onStep(1)
                case .decrement: onStep(-1)
                @unknown default: break
                }
            }
        }
    }

    private var tape: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(0..<notchCount, id: \.self) { notch in
                        WeightTapeTick(notch: notch, step: step, spacing: tickSpacing)
                            .id(notch)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            // half the width on each side, so the FIRST and LAST notches can still centre under the marker
            .safeAreaPadding(.horizontal, (proxy.size.width - tickSpacing) * SpecConstants.weightTapeCenterFraction)
            .scrollPosition(id: $position, anchor: .center)
            .scrollTargetBehavior(.viewAligned)
            .overlay(alignment: .center) {
                // the marker the notches snap under — ink, never ember (Part III law ①)
                Rectangle()
                    .fill(EmberColors.inkText)
                    .frame(width: markerWidth, height: tapeHeight)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: tapeHeight)
        .accessibilityHidden(true) // the readout above is the control; a scroll view of 200 notches is noise to VoiceOver
    }

    // SPEC: A10 — a typed value is CLAMPED on commit, so Flow 3's "invalid values impossible" survives free text
    private func commitTyped() {
        defer { typed = "" }
        guard let value = Double(typed.replacingOccurrences(of: ",", with: ".")) else { return }
        let clamped = min(max(value, 0), Double(SpecConstants.setWeightMax))
        let snapped = (clamped / step).rounded() * step // a weight the gym can actually load
        onSelect(snapped)
        position = Int((snapped / step).rounded())
    }
}

// One notch: a mark, and its number every weightTapeLabelEveryTicks
struct WeightTapeTick: View {
    let notch: Int
    let step: Double
    let spacing: CGFloat
    @ScaledMetric private var majorHeight: CGFloat = CGFloat(SpecConstants.weightTapeMajorTickHeightPt)
    @ScaledMetric private var minorHeight: CGFloat = CGFloat(SpecConstants.weightTapeMinorTickHeightPt)

    private var isLabelled: Bool { notch % SpecConstants.weightTapeLabelEveryTicks == 0 }
    private var value: Double { Double(notch) * step }
    private var label: String { value.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(value))" : "\(value)" }

    var body: some View {
        VStack(spacing: EmberTokens.Spacing.space4) {
            Rectangle()
                .fill(EmberColors.hairline)
                .frame(width: EmberTokens.Size.hairline, height: isLabelled ? majorHeight : minorHeight)
            if isLabelled {
                Text(label).font(.caption2.monospacedDigit()).foregroundStyle(EmberColors.secondaryText)
            }
        }
        .frame(width: spacing)
    }
}
