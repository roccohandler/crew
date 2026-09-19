// SPEC: A27 (b) (owner-approved 2026-09-18) as drawn by A28 (f) — Manage crew, reached from the Crew tab. Its job: "Let me rename
// the crew, replace the link, remove a member, or leave." E2's powers are unchanged: rename, replace the link and remove are the
// Captain's; anyone may leave (captaincy passes on, server-side). The Captain's name and emoji sit in one card with the screen's
// one filled button, Save name; the link, the members and Leave are row buttons, each destructive one behind its confirm — the
// only place red appears (A28 (a)). The fields are the platform's, without field chrome (R-083 (11)). R-092: no uppercase label
// stacked over a field (system §11) — the emoji and the name sit in one row, the name at card-sub-heading size with an inkSecondary
// prompt; Save name is bottom-anchored in the thumb zone; Replace the link and Leave share one card. WRITTEN — UNVERIFIED. R5

import SwiftUI

// SPEC: E2 · A27 (b) — which of the four jobs this member sees: all four for the Captain, Leave alone for everyone else
enum ManageCrewAction: Equatable {
    case rename, replaceLink, removeMember, leave

    static func actions(isCaptain: Bool) -> [ManageCrewAction] { isCaptain ? [.rename, .replaceLink, .removeMember, .leave] : [.leave] }
}

struct ManageCrewScreen: View {
    @Bindable var model: CrewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var emoji = ""
    @State private var replacing = false
    @State private var removing: MemberDot?
    @State private var leaving = false

    private var actions: [ManageCrewAction] { ManageCrewAction.actions(isCaptain: model.isCaptain) }

    var body: some View {
        ScrollView {
            if let crew = model.crew {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space16) {
                    if actions.contains(.rename) { renameCard }
                    if actions.contains(.removeMember), !model.members.filter({ $0.id != crew.captainId }).isEmpty { membersCard(crew) }
                    FocusCard(padding: 0) {
                        VStack(spacing: 0) {
                            if actions.contains(.replaceLink) {
                                RowButton(title: "Replace the invite link") { replacing = true }
                                cardSeam()
                            }
                            RowButton(title: "Leave the crew") { leaving = true }
                        }
                    }
                    if let notice = model.noticeLine {
                        Text(notice).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary).accessibilityAddTraits(.updatesFrequently)
                    }
                }
                .padding(.horizontal, EmberTokens.Focus.gutter)
                .padding(.vertical, EmberTokens.Spacing.space16)
            }
        }
        // SPEC: 6.3 · 6.7 — the screen's one filled button, bottom-anchored (the Captain's alone: rename is E2's Captain power)
        .crewBottomBar {
            if actions.contains(.rename), let crew = model.crew {
                PrimaryButton(title: "Save name") { Task { await model.rename(name: name, emoji: emoji) } }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || emoji.isEmpty || (name == crew.name && emoji == crew.emoji))
            }
        }
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationTitle("Manage crew")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { name = model.crew?.name ?? ""; emoji = model.crew?.emoji ?? "" }
        .confirmationDialog("Replace the invite link? The old one stops working.", isPresented: $replacing, titleVisibility: .visible) {
            Button("Replace the link", role: .destructive) { Task { await model.regenerateLink() } }
        }
        .confirmationDialog(removing.map { "Remove \($0.displayName) from the crew?" } ?? "", isPresented: Binding(get: { removing != nil }, set: { if !$0 { removing = nil } }), titleVisibility: .visible) {
            Button("Remove", role: .destructive) { if let removing { Task { await model.captainRemove(memberId: removing.id) } }; removing = nil }
        }
        .confirmationDialog("Leave the crew?", isPresented: $leaving, titleVisibility: .visible) {
            Button("Leave", role: .destructive) { Task { await model.leave(); dismiss() } }
        }
    }

    // SPEC: E2 · W3 — the name (≤ crewNameMaxChars) and the emoji (≤ crewEmojiMaxChars), the limits the server enforces
    private var renameCard: some View {
        FocusCard {
            HStack(spacing: EmberTokens.Spacing.space12) {
                field("Emoji", text: $emoji, limit: SpecConstants.crewEmojiMaxChars)
                    .frame(width: CGFloat(SpecConstants.minTouchTargetPt))
                field("Crew name", text: $name, limit: SpecConstants.crewNameMaxChars)
            }
        }
    }

    // the label is VoiceOver's and the prompt's, never a caption stacked over the value
    private func field(_ label: String, text: Binding<String>, limit: Int) -> some View {
        TextField(label, text: text, prompt: Text(label).foregroundStyle(EmberColors.inkSecondary))
            .typeRole(EmberTokens.Typography.cardSubheading)
            .foregroundStyle(EmberColors.ink)
            .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt))
            .onChange(of: text.wrappedValue) { _, next in if next.count > limit { text.wrappedValue = String(next.prefix(limit)) } }
            .accessibilityLabel(label)
    }

    // SPEC: E2 — the Captain removes a member; the Captain's own row is not offered (leaving is the row below)
    private func membersCard(_ crew: CrewDTO) -> some View {
        FocusCard(padding: 0) {
            VStack(spacing: 0) {
                ForEach(Array(model.members.filter { $0.id != crew.captainId }.enumerated()), id: \.element.id) { index, member in
                    if index > 0 { cardSeam() }
                    // R-095: the member's name, then Remove as the kit's ink text button — an action in a row button's quiet value slot,
                    // with a chevron, read as a fact that led somewhere; the confirm still asks (the red lives there)
                    HStack(spacing: EmberTokens.Spacing.space12) {
                        Text(member.displayName).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                        Spacer(minLength: EmberTokens.Spacing.space8)
                        TextActionButton(title: "Remove", horizontalPadding: 0, accessibilityLabel: "Remove \(member.displayName)", role: EmberTokens.Typography.textButton) { removing = member }
                    }
                    .padding(.horizontal, EmberTokens.Focus.setCardInset)
                    .frame(minHeight: EmberTokens.Focus.rowButton)
                }
            }
        }
    }
}
