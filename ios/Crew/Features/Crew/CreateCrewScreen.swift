// SPEC: Flow 6 — [Start a Crew] → name (≤ crewNameMaxChars) + emoji → the crew exists and the invite link follows (S13) · Part
// III (ink acts: monochrome controls) · C10 one screen per file (split out of InviteScreen.swift, R-055). A28 (f) · R-092: the
// system's sheet, sized to its job — the title in the content with Cancel beside it (a statement, not "Name your crew", A28 (e)),
// the field with an inkSecondary prompt, the emoji choices wrapping on the gutter (eight in one row ran off a 390 pt screen), and
// the one filled button in the thumb zone at the medium detent. WRITTEN — UNVERIFIED (needs Mac). T031

import SwiftUI

struct CreateCrewScreen: View {
    @Bindable var model: CrewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var emoji = "🌅"
    private let emojis = ["🌅", "🔥", "💪", "🏋️", "🌊", "⚡️", "🦍", "🥑"]

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
            HStack(alignment: .firstTextBaseline, spacing: EmberTokens.Spacing.space12) {
                Text("Your new crew").typeRole(EmberTokens.Typography.sheetTitle).foregroundStyle(EmberColors.ink).accessibilityAddTraits(.isHeader)
                Spacer(minLength: EmberTokens.Spacing.space8)
                TextActionButton(title: "Cancel", horizontalPadding: 0, role: EmberTokens.Typography.textButton) { dismiss() } // 6.3: the pull has a visible twin
            }
            TextField("Crew name", text: $name, prompt: Text("A name, like Dawn Patrol").foregroundStyle(EmberColors.inkSecondary))
                .typeRole(EmberTokens.Typography.cardSubheading)
                .foregroundStyle(EmberColors.ink)
                .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt)) // R-083 (11): the platform's field, without field chrome
                .accessibilityLabel("Crew name")
                .onChange(of: name) { _, value in if value.count > SpecConstants.crewNameMaxChars { name = String(value.prefix(SpecConstants.crewNameMaxChars)) } }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: CGFloat(SpecConstants.minTouchTargetPt)), spacing: EmberTokens.Spacing.space8)], alignment: .leading, spacing: EmberTokens.Spacing.space8) {
                ForEach(emojis, id: \.self) { option in
                    Button(option) { emoji = option }.font(.title2)
                        .frame(width: CGFloat(SpecConstants.minTouchTargetPt), height: CGFloat(SpecConstants.minTouchTargetPt))
                        .overlay(Circle().strokeBorder(EmberColors.ink, lineWidth: emoji == option ? EmberTokens.Focus.checkRing : 0)) // the chosen one: an ink ring, like a check
                        .accessibilityAddTraits(emoji == option ? .isSelected : [])
                }
            }
            if let error = model.loadError { Text(error).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.ink) } // A28 (a): red only in a destructive confirm
            Spacer(minLength: 0)
            PrimaryButton(title: "Start a crew") { Task { await model.create(name: name.trimmingCharacters(in: .whitespaces), emoji: emoji); if model.crew != nil { dismiss() } } }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, EmberTokens.Focus.gutter)
        .padding(.top, EmberTokens.Spacing.space32)
        .padding(.bottom, EmberTokens.Spacing.space12)
        .background(EmberColors.card.ignoresSafeArea()) // A28 (f): the sheet surface
        .tint(EmberColors.ink)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(EmberTokens.Focus.cardRadius)
    }
}
