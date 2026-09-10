// SPEC: Flow 2 ("weekly ring 2/4") · Part III law ④ (ring FILLS are ember; the track is the ember tint; the ring is
// the reward layer, never a control) · 5.6.2 HomeModel.weeklyRing: [DayRingState]. WRITTEN — UNVERIFIED (needs Mac).
//
// H003 (2026-09-10): the `days: [DayRingState]` parameter is GONE. It was declared, passed by three call sites, and
// never read by the body — the exact defect (F12) that WeekStrip was built to fix, left in place beside the fix. A
// parameter nothing reads is a loaded gun: the next reader passes richer state, expects it to render, and it
// silently does not. The per-day states live in WeekStrip, which actually draws them.

import SwiftUI

// A String raw value so the WeekSummary twin can take `[String]` and stay byte-identical to the TypeScript side,
// which has no enum to share. `rawValue` is the contract: "done" | "missed" | "rest" | "today" | "nextUp" | "upcoming".
enum DayRingState: String, Equatable {
    case done          // planned workout completed
    case missed        // planned, not done, day over — gray, never red
    case rest          // no workout planned
    case today         // the open day
    case nextUp        // A17.4: the NEXT planned training day — the one question a rest day actually raises
    case upcoming      // a planned day after that one
}

struct WeeklyRing: View {
    let done: Int
    let planned: Int
    // H010: the ring grew with nothing. Its fraction scales with Dynamic Type while the circle around it was a hard
    // 64 pt, so at AX4 three glyphs sat inside a frame that never moved. @ScaledMetric makes the ring grow with them.
    @ScaledMetric private var diameter: CGFloat = EmberTokens.Size.ringDiameter

    private var fraction: Double { planned == 0 ? 0 : Double(done) / Double(planned) }

    var body: some View {
        ZStack {
            Circle().stroke(EmberColors.emberTint, lineWidth: EmberTokens.Spacing.space8)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(EmberColors.ember, style: StrokeStyle(lineWidth: EmberTokens.Spacing.space8, lineCap: .round))
                .rotationEffect(.degrees(EmberTokens.Size.ringStartAngleDegrees))
                .animation(.crewSpring, value: fraction)
            Text("\(done)/\(planned)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(EmberColors.inkText)
        }
        .frame(width: diameter, height: diameter)
        // H004: the label needs `children: .ignore` or the inner Text can win and announce "one slash three".
        // StreakFlame and WeekStrip both already do this; the ring was the one that did not.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(done) of \(planned) workouts done this week")
    }
}
