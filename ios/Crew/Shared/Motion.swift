// SPEC: 6.4 — one spring curve app-wide, defined once in Shared/ (values from EmberTokens.Motion, G5); Reduce Motion gets a
// static equivalent with identical information. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

extension Animation {
    static let crewSpring = Animation.spring(response: EmberTokens.Motion.springResponse, dampingFraction: EmberTokens.Motion.springDampingFraction)
}

// Wrap any state change: the spring when motion is allowed, no animation under Reduce Motion (6.4)
func withCrewMotion(reduceMotion: Bool, _ change: () -> Void) {
    if reduceMotion {
        change()
    } else {
        withAnimation(.crewSpring, change)
    }
}
