// SPEC: Flow 9 layer 3 — per-exercise charts, last-vs-today, PR moments 🎉 — ONLY where weights were logged. First-party Swift
// Charts (no dependency). WRITTEN — UNVERIFIED (needs Mac). T040

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
        Card {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
                HStack {
                    Text(trend.name).font(.headline).foregroundStyle(EmberColors.inkText)
                    Spacer()
                    if isNewBest { Text("New best 🎉").font(.caption.weight(.semibold)).foregroundStyle(EmberColors.emberText) }
                }
                Chart(Array(trend.points.enumerated()), id: \.offset) { _, point in
                    LineMark(x: .value("Day", point.dayKey), y: .value("Best", point.best)).foregroundStyle(EmberColors.ember)
                    PointMark(x: .value("Day", point.dayKey), y: .value("Best", point.best)).foregroundStyle(EmberColors.ember)
                }
                .chartXAxis(.hidden)
                .frame(height: EmberTokens.Size.skeletonHero)
                .accessibilityLabel("\(trend.name): \(trend.points.map { "\(Int($0.best))" }.joined(separator: ", ")) \(units)")
                if let last = trend.points.last, let previous = trend.points.dropLast().last {
                    Text("Last \(Int(previous.best)) \(units) · today \(Int(last.best)) \(units)").font(.caption).foregroundStyle(EmberColors.secondaryText)
                }
            }
        }
    }
}
