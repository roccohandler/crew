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

    // SPEC: A19.5 / R10 · 6.7 ("content that can grow lives in ScrollViews") — the overflow valve. Seven day toggles
    // at ≥ 56 pt, a header, two lines of copy and a CTA do not fit an SE at accessibility-XXL, and without a scroll
    // view the Continue button is simply clipped off the bottom with no way to reach it. The Spacer here was already
    // in the right place (above the CTA, which is R9's rule); this is the other half of the same fix.
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
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
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .topLeading)
            }
        }
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
                // A18.11 — the day toggle, the only control on the days question: a control boundary, so controlOutline (3.32:1 on a card, 3.13:1 on the canvas) and never
                // the 1.26:1 hairline family, which is for the seam between two surfaces.
                .overlay(Circle().stroke(EmberColors.controlOutline, lineWidth: EmberTokens.Size.hairline))
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

    // SPEC: A19.5 / R9 · 6.7 ("reachability holds at Pro Max: primary actions stay bottom-anchored regardless of how
    // much canvas exists above") — THE SPACER MOVED ABOVE THE OPTIONS. It was below them, so the header sat at the top,
    // the options sat directly under it, and roughly 400 pt of dead canvas sat beneath the only thing on the screen a
    // finger can act on — on a Pro Max, in the hardest-to-reach third. This is the exact defect A17.2 diagnosed on Home
    // and fixed only there; R9 applies it where it was never applied. Two lines, and the highest ergonomic return in
    // the A19 audit.
    //
    // A19.5 / R10 — and the whole thing is inside a ScrollView, because at accessibility-XXL a header plus four option
    // cards overflows an SE and 6.7 makes an overflow valve non-negotiable ("content that can grow lives in ScrollViews").
    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                    QuestionHeader(number: number, title: title)
                    Spacer(minLength: 0)
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
                            // A18.11 — an option is a CONTROL, so its boundary is controlOutline (3.32:1) and never
                            // the 1.26:1 hairline family; the chosen one goes to full ink, which is the selection signal.
                            .overlay(RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous).stroke((chosen ?? selected) == option.value ? EmberColors.inkText : EmberColors.controlOutline, lineWidth: EmberTokens.Size.hairline))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(EmberTokens.Spacing.space24)
                // R9 — the Spacer needs a floor to push against, and R10's ScrollView is what lets the content exceed
                // it at accessibility-XXL instead of clipping. Same shape Home uses (HomeScreen.content).
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .topLeading)
            }
        }
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
