// SPEC: A21.3 / W4 (owner-approved 2026-09-17) — ONE entry surface for a pasted invite code, used by the hero's "I have an invite"
// (InviteCodeScreen, pre-auth) and by the empty Crew tab (JoinByCodeSheet, signed in). States explicit (S13): looking up · a live
// crew ("Dawn Patrol 🌅 · 3 of 10 in the crew") · dead code · crew full. Screens hold ZERO logic (5.6.6): the models look the code
// up (GET crews/join?token=, public). A18.11: the field is a control, so its boundary is controlOutline. Ink acts (Part III law ①).
// R-092: the line states (A28 (e)), the prompt is inkSecondary (4.5:1 — the platform's placeholder grey was ~1.6:1), Paste is the
// kit's text button. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct InviteCodeEntry: View {
    @Binding var code: String
    let preview: CrewPreviewDTO?
    let errorLine: String?
    let isLookingUp: Bool
    let continueTitle: String
    let onLookUp: () -> Void
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
            Text("Your friend's code or their whole link works here.").typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.inkSecondary)
            HStack(spacing: EmberTokens.Spacing.space8) {
                TextField("Invite code", text: $code, prompt: Text("Invite code").foregroundStyle(EmberColors.inkSecondary))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.asciiCapable)
                    .submitLabel(.search)
                    .onSubmit(onLookUp)
                    .typeRole(EmberTokens.Typography.cardSubheading)
                    .foregroundStyle(EmberColors.ink)
                    .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt)) // R-083 (11): the platform's field, without field chrome
                    .accessibilityLabel("Invite code")
                TextActionButton(title: "Paste", horizontalPadding: 0, accessibilityLabel: "Paste the invite code", role: EmberTokens.Typography.textButton) { if let pasted = UIPasteboard.general.string { code = pasted } }
            }
            if let preview {
                Text(numerals: "\(preview.name) \(preview.emoji) · \(preview.memberCount) of \(SpecConstants.crewMaxMembers) in the crew")
                    .typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                    .accessibilityIdentifier("invitePreview")
            }
            if let errorLine { Text(errorLine).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.ink).accessibilityAddTraits(.updatesFrequently) }
            if let preview, !preview.full {
                PrimaryButton(title: continueTitle, action: onContinue)
            } else {
                PrimaryButton(title: isLookingUp ? "Looking…" : "Find my crew", action: onLookUp) // A28 (f): the one filled button until a crew is found
                    .disabled(isLookingUp || code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
