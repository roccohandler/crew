// SPEC: Flow 2 ("weekly ring 2/4") · Part III law ④ (ring FILLS are ember; the track is the ember tint; the ring is
// the reward layer, never a control) · 5.6.2 HomeModel.weeklyRing: [DayRingState]. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

enum DayRingState: Equatable {
    case done          // planned workout completed
    case missed        // planned, not done, day over — gray, never red
    case rest          // no workout planned
    case today         // the open day
    case upcoming
}

struct WeeklyRing: View {
    let done: Int
    let planned: Int
    let days: [DayRingState]

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
        .frame(width: EmberTokens.Size.ringDiameter, height: EmberTokens.Size.ringDiameter)
        .accessibilityLabel("\(done) of \(planned) workouts done this week")
    }
}
