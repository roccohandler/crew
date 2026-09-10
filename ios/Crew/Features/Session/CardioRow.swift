// SPEC: A2 (owner-directed 2026-09-08) — a cardio block inside a planned workout: "{Activity} · Target {min} min", a minutes
// stepper (±cardioMinutesStep, pre-filled with the target, bounds cardioMinutesMin…cardioMinutesMax), an optional distance in
// the user's distanceUnit (A9: km or mi, chosen independently of the weight unit; stored in meters, capped at cardioDistanceMaxMeters), Done → the set is done with
// holdSeconds = minutes × 60 and distanceMeters, a haptic tick. Skippable like any exercise (the card's Skip). Part of the +100,
// never extra XP; no pace, effort or targets beyond the planned minutes, ever. Ink controls only (Part III law ①).
// WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct CardioRow: View {
    let name: String
    let setLog: LocalSetLog // not `set`: inside a computed property `{ set... }` reads as a setter accessor
    let targetSeconds: Int
    let distanceUnit: String // A9: km or mi — a distance never reads the weight unit
    let onDone: (Int, Int?) -> Void // minutes, distanceMeters
    @State private var minutes: Int
    @State private var distanceEntry = ""

    init(name: String, setLog: LocalSetLog, targetSeconds: Int, distanceUnit: String, onDone: @escaping (Int, Int?) -> Void) {
        self.name = name
        self.setLog = setLog
        self.targetSeconds = targetSeconds
        self.distanceUnit = distanceUnit
        self.onDone = onDone
        _minutes = State(initialValue: CardioRow.bounded(targetSeconds / TimeUnits.secondsPerMinute))
    }

    private var metric: Bool { distanceUnit == "km" }
    private var targetMinutes: Int { targetSeconds / TimeUnits.secondsPerMinute }

    // SPEC: A2 — cardioMinutesMin … cardioMinutesMax; invalid values impossible (Flow 3 smart steppers)
    private static func bounded(_ value: Int) -> Int {
        min(max(value, SpecConstants.cardioMinutesMin), SpecConstants.cardioMinutesMax)
    }

    // SPEC: A2 — the typed distance (one decimal, the user's unit) → meters, capped at cardioDistanceMaxMeters; blank → none
    var distanceMeters: Int? {
        guard let value = Double(distanceEntry.replacingOccurrences(of: ",", with: ".")), value > 0 else { return nil }
        let metersPerUnit = metric ? Double(SpecConstants.metersPerKilometer) : SpecConstants.metersPerMile
        return min(Int((value * metersPerUnit).rounded()), SpecConstants.cardioDistanceMaxMeters)
    }

    // "25 min · 2.1 km" once done — the same words the journal will use (A6)
    private var doneLine: String {
        let logged = (setLog.holdSeconds ?? 0) / TimeUnits.secondsPerMinute
        guard let distance = setLog.distanceMeters else { return "\(logged) min" }
        return "\(logged) min · \(SessionSummaryLine.distanceText(distanceMeters: distance, distanceUnit: distanceUnit))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
            HStack(spacing: EmberTokens.Spacing.space12) {
                Text(name).font(.body).foregroundStyle(EmberColors.inkText)
                Spacer()
                Text(setLog.done ? doneLine : "Target \(targetMinutes) min").font(.caption.monospacedDigit()).foregroundStyle(EmberColors.secondaryText)
                if setLog.done { Image(systemName: "checkmark.circle.fill").font(.title2).foregroundStyle(EmberColors.inkText) }
            }
            .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(name), \(setLog.done ? "\(doneLine), done" : "target \(targetMinutes) minutes")")
            if !setLog.done { controls }
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
            HStack(spacing: EmberTokens.Spacing.space12) {
                Stepper(label: "\(minutes) min", noun: "minutes") { minutes = CardioRow.bounded(minutes + $0 * SpecConstants.cardioMinutesStep) }
                Spacer()
                Button("Done") { onDone(minutes, distanceMeters) }
                    .font(.headline)
                    .foregroundStyle(EmberColors.inkText)
                    .frame(minWidth: EmberTokens.Size.ringDiameter, minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                    .overlay(RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous).stroke(EmberColors.hairline, lineWidth: EmberTokens.Size.hairline))
                    .accessibilityLabel("Mark \(name) done, \(minutes) minutes")
            }
            HStack(spacing: EmberTokens.Spacing.space8) {
                TextField("Distance, optional", text: $distanceEntry)
                    .keyboardType(.decimalPad)
                    .font(.body.monospacedDigit())
                    .foregroundStyle(EmberColors.inkText)
                    .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                    .accessibilityLabel("Distance in \(metric ? "kilometres" : "miles"), optional")
                Text(metric ? "km" : "mi").font(.body).foregroundStyle(EmberColors.secondaryText)
            }
        }
    }
}
