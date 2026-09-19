// SPEC: A28 (d) (owner-approved 2026-09-19; design/targets 07, 08) — the set screen between the bar and the buttons: the exercise
// title with "Set N of M", ONE card of two metric rows (reps and weight; a bodyweight exercise has one; a cardio block's are its
// minutes and its distance — GAP 4 as R-084 (2) read it), then the fact line: the last-time reference on set 1, and after it the
// RUNNING LEDGER of the sets already logged (the last-time values move up into the sub-line, mockup 08). A ledger row picks that
// set back onto the card to correct it (Flow 3: out of order). Tapping the title shows the exercise's cue. WRITTEN — UNVERIFIED.

import SwiftUI

struct SetScreenBody: View {
    let model: SessionModel
    let exercise: LocalSessionExercise
    let setLog: LocalSetLog
    let plateLine: String?
    let onCue: () -> Void
    let onTypeReps: () -> Void
    let onTypeWeight: () -> Void
    let onTypeMinutes: () -> Void
    let onTypeDistance: () -> Void
    @ScaledMetric private var rowTarget: CGFloat = CGFloat(SpecConstants.minTouchTargetPt)

    private var lastTime: String? { model.lastTime(for: exercise) }
    private var logged: [LocalSetLog] { model.sets(of: exercise).filter { $0.done && $0 !== setLog } }
    private var isCardio: Bool { exercise.type == "cardio" }
    private var hasWeight: Bool { exercise.equipment != "bodyweight" && !isCardio }

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                Button(action: onCue) {
                    Text(exercise.name).typeRole(EmberTokens.Typography.exerciseTitle).foregroundStyle(EmberColors.ink)
                        .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true) // 6.7: a long name wraps
                }
                .buttonStyle(.plain)
                .accessibilityHint("Double-tap for how to do it")
                subline.typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            card
            facts
        }
    }

    // "Set 1 of 3" · "Set 2 of 3 · last time 8 · 8 · 8 @ 150 lb" · "Warm-up" — numerals rounded and bold (§4)
    private var subline: Text {
        let count = model.workSets(of: exercise).count
        let head = setLog.isWarmup ? Text("Warm-up") : Text("Set ") + number(model.setNumber(setLog, in: exercise)) + Text(" of ") + number(count)
        guard !logged.isEmpty, let lastTime else { return head }
        return head + Text(" · last time ") + Text(lastTime).fontDesign(.rounded).bold()
    }

    private func number(_ value: Int) -> Text { Text("\(value)").fontDesign(.rounded).bold() }

    @ViewBuilder
    private var card: some View {
        if isCardio {
            // SPEC: A2 · A28 (c) — the minutes the user enters (a target, never a clock) and an optional distance in their unit (A9)
            SetCard {
                MetricRow(value: "\(model.cardioMinutes(of: setLog, in: exercise))", unit: "min", noun: "minutes", onType: onTypeMinutes) { model.adjustCardioMinutes(setLog, by: $0, in: exercise) }
            } second: {
                SetCardSecondRow { MetricRow(value: setLog.distanceMeters.map { SessionSummaryLine.distanceText(distanceMeters: $0, distanceUnit: model.distanceUnit).split(separator: " ").first.map(String.init) ?? "—" } ?? "—", unit: model.distanceUnit, noun: "distance", onType: onTypeDistance) }
            }
        } else if hasWeight {
            SetCard {
                MetricRow(value: "\(setLog.actualReps)", unit: "reps", noun: "reps", onType: onTypeReps) { model.adjustReps(setLog, by: $0) }
            } second: {
                SetCardSecondRow { MetricRow(value: weightText, unit: model.units, noun: "weight", onType: onTypeWeight) { model.adjustWeight(setLog, by: $0) } }
            }
        } else {
            SetCard {
                MetricRow(value: "\(setLog.actualReps)", unit: "reps", noun: "reps", onType: onTypeReps) { model.adjustReps(setLog, by: $0) }
            } second: { EmptyView() }
        }
    }

    private var weightText: String {
        guard let weight = setLog.weight else { return "—" }
        return weight.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(weight))" : "\(weight)"
    }

    // SPEC: A28 (d) — below the card: last time on the first set, the running ledger after it (never both: one fact, one rendering)
    @ViewBuilder
    private var facts: some View {
        if logged.isEmpty, let lastTime {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                Text("Last time").typeRole(EmberTokens.Typography.eyebrow).foregroundStyle(EmberColors.inkSecondary)
                Text(numerals: lastTime).typeRole(EmberTokens.Typography.cardSubheading).foregroundStyle(EmberColors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Whisper(.howOverload) // A23: under the first line that remembers last time (A12)
            }
            .padding(.horizontal, EmberTokens.Focus.space6)
        }
        if !logged.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(logged, id: \.order) { row in ledgerRow(row) }
            }
        }
        if let plateLine {
            Text(numerals: plateLine).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
                .accessibilityLabel("Plates: \(plateLine)")
        }
    }

    // "✓ Set 1 · 8 reps · 150 lb" — a fact, and the way back to that set to correct it
    private func ledgerRow(_ row: LocalSetLog) -> some View {
        let name = row.isWarmup ? "Warm-up" : "Set \(model.setNumber(row, in: exercise))"
        let weight = row.weight.map { " · \(model.formatted($0))" } ?? ""
        let line = isCardio ? "\(name) · \((row.holdSeconds ?? 0) / TimeUnits.secondsPerMinute) min" : "\(name) · \(row.actualReps) reps\(weight)"
        return Button { model.selectedSetOrder = row.order } label: {
            HStack(spacing: EmberTokens.Spacing.space8) {
                Image(systemName: "checkmark").font(.caption.weight(.bold)).foregroundStyle(EmberColors.ink)
                Text(numerals: line).typeRole(EmberTokens.Typography.caption).foregroundStyle(EmberColors.inkSecondary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, EmberTokens.Focus.space6)
            .frame(minHeight: rowTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(line), done")
        .accessibilityHint("Double-tap to change it")
    }
}

// SPEC: A28 (f) — what a value button's keypad is typing (the platform's alert and keypad, R-083 (11)); a count takes the number pad
enum TypedField {
    case reps, weight, minutes, distance

    var wholeNumber: Bool { self == .reps || self == .minutes }

    func title(units: String, distanceUnit: String) -> String {
        switch self {
        case .reps: return "Reps"
        case .weight: return "Weight in \(units)"
        case .minutes: return "Minutes"
        case .distance: return "Distance in \(distanceUnit)"
        }
    }
}
