// SPEC: Flow 9 layer 3 as amended by A28 (b), (f) — per-exercise charts, last-vs-today, a new best stated IN INK and in words (A28
// (b): every PR accent goes; R-083 (12): no emoji) — ONLY where weights were logged. The system's card; the line and its points are
// ink (no accent on Progress). First-party Swift Charts (no dependency). WRITTEN — UNVERIFIED (needs Mac). T040 · R3

import Charts
import SwiftUI

struct ExerciseChartView: View {
    let trend: ExerciseTrend
    let units: String

    private var isNewBest: Bool {
        guard trend.points.count > 1, let last = trend.points.last?.best else { return false }
        return last > trend.points.dropLast().map(\.best).max() ?? 0
    }

    var body: some View {
        FocusCard {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
                HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space8) {
                    Text(trend.name).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: EmberTokens.Spacing.space8)
                    if isNewBest { Text("New best").typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.ink) }
                }
                Chart(Array(trend.points.enumerated()), id: \.offset) { _, point in
                    LineMark(x: .value("Day", point.dayKey), y: .value("Best", point.best)).foregroundStyle(EmberColors.ink)
                    PointMark(x: .value("Day", point.dayKey), y: .value("Best", point.best)).foregroundStyle(EmberColors.ink)
                }
                .chartXAxis(.hidden)
                // the axis is the table's, not the platform's grey: seam-weight gridlines, secondary-ink numerals, Rounded Bold (§4;
                // ui-reviewer, run 35444308817)
                .chartYAxis {
                    AxisMarks(position: .trailing) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: EmberTokens.Size.hairline)).foregroundStyle(EmberColors.hairlineOnCard)
                        AxisValueLabel {
                            if let weight = value.as(Double.self) { Text(numerals: "\(Int(weight))").typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.inkSecondary) }
                        }
                    }
                }
                .frame(height: EmberTokens.Size.skeletonHero)
                .accessibilityLabel("\(trend.name): \(trend.points.map { "\(Int($0.best))" }.joined(separator: ", ")) \(units)")
                if let last = trend.points.last, let previous = trend.points.dropLast().last {
                    Text(numerals: "Last \(Int(previous.best)) \(units) · today \(Int(last.best)) \(units)").typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
                }
            }
        }
    }
}
