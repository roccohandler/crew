// SPEC: Flow 3 haptic language (tick = set · double = exercise · thump = workout) · 6.4 (fixed language named in
// design-tokens.json → EmberTokens.Haptic; softTap = reaction received, G8) · Part III voice (feedback = haptics only,
// no sound effects). WRITTEN — UNVERIFIED (needs Mac).

import UIKit

enum Haptics {
    static func play(_ haptic: EmberTokens.Haptic) {
        switch haptic {
        case .tick:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .double:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(SpecConstants.autoAdvanceDelayMs)) {
                generator.impactOccurred()
            }
        case .thump:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .softTap:
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }

    // 1B: single-select answers auto-advance with a selection haptic
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
