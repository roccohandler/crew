// SPEC: A28 (b), (f) — the system's weekly ring (design/focus-card-system.md §8): a 140 pt box, radius 60, a 16 pt stroke with a
// round cap from −90°, `ringTrack` beneath and `accent` above — the ARC is one of the three places orange may appear; the track is
// a neutral, never a tint. Interior: the count at 46 pt Rounded Bold in ink over an 11 pt eyebrow in inkSecondary. What the count
// counts is A18.1's (completed planned workouts over the week's planned count) until the owner answers GAP 3 in A28 ("4 OF 7").
// The legacy WeeklyRing stays for Progress's history row until R3 redraws Progress. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct FocusRing: View {
    let done: Int
    let planned: Int
    // 6.5 / 6.7 — the numeral inside scales with Dynamic Type, so the ring grows with it (the H010 lesson)
    @ScaledMetric(relativeTo: .largeTitle) private var radius: CGFloat = EmberTokens.Focus.ringRadius
    @ScaledMetric(relativeTo: .largeTitle) private var box: CGFloat = EmberTokens.Focus.ringBox

    private var fraction: Double { planned == 0 ? 0 : min(1, Double(done) / Double(planned)) }

    var body: some View {
        ZStack {
            // The stroke straddles the radius-60 path (52…68 from the centre), inside the 140 box's 70
            ZStack {
                Circle().stroke(EmberColors.ringTrack, lineWidth: EmberTokens.Focus.ringStroke)
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(EmberColors.accent, style: StrokeStyle(lineWidth: EmberTokens.Focus.ringStroke, lineCap: .round))
                    .rotationEffect(.degrees(EmberTokens.Size.ringStartAngleDegrees))
                    .animation(.crewSpring, value: fraction)
            }
            .frame(width: radius + radius, height: radius + radius)
            VStack(spacing: 0) {
                Text("\(done)").typeRole(EmberTokens.Typography.ringNumeral).foregroundStyle(EmberColors.ink)
                (Text("of ") + Text("\(planned)").fontDesign(.rounded))
                    .typeRole(EmberTokens.Typography.eyebrowUnderRing)
                    .foregroundStyle(EmberColors.inkSecondary)
            }
        }
        .frame(width: box, height: box)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(done) of \(planned) workouts done this week")
    }
}
