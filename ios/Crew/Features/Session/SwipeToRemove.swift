// SPEC: A11 (owner-directed 2026-09-09) · 6.3 ("every swipe gesture has a visible-button equivalent") — swipe a set row
// left to reveal Remove.
//
// Why this is hand-written rather than `.swipeActions`: that modifier only does anything inside a List, and the session
// screen is a ScrollView of Cards (it has to be — a List cannot carry the exercise cards, the tape or the rest timer).
// `.swipeActions` on a ScrollView row compiles, shows nothing, and fails silently, which is worse than not offering the
// gesture at all.
//
// C6 — a junior must be able to predict every line: a horizontal DragGesture moves the row by the drag distance, clamped
// to the button's width; letting go past the halfway point snaps open, otherwise closed. There is no velocity model, no
// custom gesture recogniser and no animation curve beyond the app's one spring (6.4). The revealed control is a real
// Button, so VoiceOver and Switch Control reach it without the gesture — and SetRow additionally carries the same action
// as an accessibilityAction, so the gesture is never the only way. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct SwipeToRemove<Content: View>: View {
    let isEnabled: Bool
    let label: String
    let onRemove: () -> Void
    @ViewBuilder let content: () -> Content
    @State private var offset: CGFloat = 0
    @State private var openWidth: CGFloat = 0
    @ScaledMetric private var buttonWidth: CGFloat = CGFloat(SpecConstants.swipeRemoveWidthPt)
    @Environment(\.accessibilityReduceMotion) private var reduceMotion // 6.4: the app's one spring, or none at all

    private var isOpen: Bool { offset < 0 }

    var body: some View {
        ZStack(alignment: .trailing) {
            if isEnabled {
                Button(role: .destructive) { close(); onRemove() } label: {
                    Text("Remove")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(EmberColors.primaryButtonLabel)
                        .frame(width: buttonWidth, height: rowHeight)
                        .background(EmberColors.danger, in: RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove \(label)")
                .opacity(isOpen ? 1 : 0) // never reachable by touch while closed; the row sits on top of it
            }
            content()
                .background(EmberColors.card)
                .offset(x: offset)
                .gesture(isEnabled ? drag : nil)
        }
        .onChange(of: isEnabled) { _, enabled in if !enabled { close() } }
        .background(GeometryReader { proxy in Color.clear.onAppear { openWidth = proxy.size.height }.onChange(of: proxy.size.height) { _, height in openWidth = height } })
    }

    // The revealed button is as tall as the row it belongs to
    private var rowHeight: CGFloat { max(openWidth, CGFloat(SpecConstants.minTouchTargetPt)) }

    private var drag: some Gesture {
        DragGesture(minimumDistance: CGFloat(SpecConstants.swipeRemoveMinimumDistancePt))
            .onChanged { value in
                guard value.translation.width < 0 || isOpen else { return } // a rightward drag on a closed row does nothing
                offset = max(-buttonWidth, min(0, value.translation.width + (isOpen ? -buttonWidth : 0)))
            }
            .onEnded { _ in
                let halfway = -buttonWidth * SpecConstants.swipeRemoveOpenFraction
                withCrewMotion(reduceMotion: reduceMotion) { offset = offset < halfway ? -buttonWidth : 0 }
            }
    }

    private func close() {
        withCrewMotion(reduceMotion: reduceMotion) { offset = 0 }
    }
}
