// SPEC: S03 — 3 questions, all tappable, no keyboard; day toggles ≥ 56 pt with Mon/Wed/Fri pre-selected and a live
// encouragement line plus the neutral whisper (A1, owner-directed 2026-09-08: PPL rotates at every day count, so the
// picker steers nobody — "Most people start at 3 days."); single-selects auto-advance with a selection haptic after a
// 250 ms beat (1B); "1 of 3" whisper; SF Symbols at consistent weight; copy survives Dynamic Type XXL. Pure ink-on-bone
// (Part III onboarding rule). WRITTEN — UNVERIFIED (needs Mac). T021

import SwiftUI

enum OnboardingQuestion: Int {
    case days = 1, experience, equipment
}

struct DaysQuestionScreen: View {
    @Bindable var model: OnboardingModel
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space24) {
            QuestionHeader(number: OnboardingQuestion.days.rawValue, title: "Which days do you train?")
            // GAP: S03 asks for seven ≥ 56 pt circles in one row, but 7 × 56 pt plus gaps is wider than every iPhone inside the
            // 24 pt margins (the first simulator run clipped both edges). Conservative call: the TAP AREA keeps ≥ 56 pt of height
            // and the full column of width (≥ 44 pt, 6.3); the circle itself draws at the column width. R-052.
            HStack(spacing: EmberTokens.Spacing.space4) {
                ForEach(1...TimeUnits.daysPerWeek, id: \.self) { weekday in
                    DayToggle(letter: DayToggle.letters[weekday - 1], selected: model.selectedDays.contains(weekday)) {
                        Haptics.selection()
                        model.toggleDay(weekday)
                    }
                }
            }
            Text(model.encouragementLine).font(.body).foregroundStyle(EmberColors.secondaryText)
            Text(DayToggle.whisper).font(.footnote).foregroundStyle(EmberColors.secondaryText)
            Spacer()
            PrimaryButton(title: "Continue") { model.continueFromDays(); onContinue() }
                .disabled(!model.canContinueFromDays)
                .opacity(model.canContinueFromDays ? 1 : EmberTokens.Opacity.disabled)
        }
        .padding(EmberTokens.Spacing.space24)
        .background(EmberColors.canvas.ignoresSafeArea())
    }
}

struct DayToggle: View {
    static let letters = ["M", "T", "W", "T", "F", "S", "S"]
    // SPEC: A1 — the neutral line under the picker (the default pick is Mon/Wed/Fri, so the number is the default's count)
    static let whisper = "Most people start at \(SpecConstants.defaultTrainingWeekdays.count) days."

    let letter: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(letter)
                .font(.headline)
                .foregroundStyle(selected ? EmberColors.primaryButtonLabel : EmberColors.inkText)
                .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.dayToggleMinPt)) // the tap area: the full column, ≥ 56 pt tall (1B)
                .background(selected ? EmberColors.primaryButtonFill : EmberColors.card, in: Circle()) // inscribed: as wide as the column, never taller than 56
                .overlay(Circle().stroke(EmberColors.hairline, lineWidth: EmberTokens.Size.hairline))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(letter)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

struct ExperienceQuestionScreen: View {
    @Bindable var model: OnboardingModel
    let onAdvance: () -> Void

    var body: some View {
        SingleSelectQuestion(number: OnboardingQuestion.experience.rawValue, title: "How experienced are you?", options: [
            ("brandNew", "Brand new", "figure.walk"),
            ("some", "Some", "figure.strengthtraining.traditional"),
            ("experienced", "Experienced", "dumbbell"),
        ], selected: model.experience) { value in
            model.choose(experience: value)
            onAdvance()
        }
    }
}

struct EquipmentQuestionScreen: View {
    @Bindable var model: OnboardingModel
    let onAdvance: () -> Void

    var body: some View {
        SingleSelectQuestion(number: OnboardingQuestion.equipment.rawValue, title: "What do you have access to?", options: [
            ("fullGym", "Full gym", "building.2"),
            ("dumbbells", "Dumbbells", "dumbbell"),
            ("bodyweight", "Bodyweight", "house"),
        ], selected: model.equipment) { value in
            model.choose(equipment: value)
            onAdvance()
        }
    }
}

// 1B: one input per screen, one obvious action; tapping answers and advances after the beat
struct SingleSelectQuestion: View {
    let number: Int
    let title: String
    let options: [(value: String, label: String, symbol: String)]
    let selected: String?
    let onChoose: (String) -> Void
    @State private var chosen: String?

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
            QuestionHeader(number: number, title: title)
            ForEach(options, id: \.value) { option in
                Button {
                    Haptics.selection()
                    chosen = option.value
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(SpecConstants.autoAdvanceDelayMs)) { onChoose(option.value) }
                } label: {
                    Card {
                        Label(option.label, systemImage: option.symbol)
                            .font(.headline)
                            .foregroundStyle(EmberColors.inkText)
                            .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                    }
                    .overlay(RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous).stroke((chosen ?? selected) == option.value ? EmberColors.inkText : EmberColors.hairline, lineWidth: EmberTokens.Size.hairline))
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(EmberTokens.Spacing.space24)
        .background(EmberColors.canvas.ignoresSafeArea())
    }
}

struct QuestionHeader: View {
    let number: Int
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
            Text(title).font(.title.weight(.bold)).foregroundStyle(EmberColors.inkText)
            Text("\(number) of \(SpecConstants.onboardingQuestionCount)").font(.footnote).foregroundStyle(EmberColors.secondaryText) // the whisper, never a progress bar
        }
    }
}
