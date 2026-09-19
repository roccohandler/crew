// SPEC: A4 (owner-directed 2026-09-08) · S14 as amended by A28 (c), (f) — the workout editor, one workout, pushed full screen:
// title `{name}`, `Cancel` / `Save` (Save disabled until dirty), the header `{n} exercises + mobility` (A28 (c): the time estimate is
// gone), rows `{name}` / `{sets} × {reps} · {Equipment}` as ONE tap target opening the exercise sheet, `Add exercise`, `Add cardio`
// (one block, after the strength rows), the mobility block (read-only names, "Mobility · 3 holds · closes the workout"),
// `Discard changes to {name}?` on a dirty Cancel. ONE reorder idiom (A27's hand-off, R-087): Move up / Move down in the exercise
// sheet — visible buttons, so the drag handle and its Reorder mode are gone. The removed row's Undo is a quiet row at the top of the
// page, not a snackbar (A28 (f)). The groups are the system's cards on the gutter, not the platform's inset-grouped list
// (ui-reviewer, run 35444308817). Forward-only (Flow 8). Screens hold zero logic (5.6.6). WRITTEN — UNVERIFIED (needs Mac). R4

import SwiftUI

struct WorkoutEditorScreen: View {
    let model: PlanModel
    let kind: String
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var editing: Int?        // the order of the row open in the exercise sheet
    @State private var adding = false
    @State private var addingCardio = false
    @State private var confirmingDiscard = false

    var body: some View {
        Group {
            if let draft = model.drafts[kind] { page(draft) } else { LoadingLine(line: "Opening the workout…").padding(EmberTokens.Focus.gutter) } // 6.1 (2026-09-18): a line, not a skeleton
        }
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationTitle(model.name(ofKind: kind))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { cancel() } } }
        // SPEC: 6.3 · 6.7 (DESIGN.md 4.2) — Save commits the screen, so it is the one filled button, bottom-anchored in the thumb zone
        // (it sat top-right in the bar — ui-reviewer, run 35447860873 · R-094); Cancel stays at the top as text
        .crewBottomBar {
            if model.drafts[kind] != nil {
                PrimaryButton(title: "Save changes") { if model.save(kind: kind) { onSaved() } }
                    .disabled(!model.isDirty(kind: kind))
            }
        }
        .onAppear { model.edit(kind: kind) }
        .confirmationDialog(model.drafts[kind]?.discardTitle ?? "", isPresented: $confirmingDiscard, titleVisibility: .visible) {
            Button("Discard changes", role: .destructive) { model.discard(kind: kind); dismiss() }
            Button("Keep editing", role: .cancel) {}
        }
        .sheet(isPresented: Binding(get: { editing != nil }, set: { if !$0 { editing = nil } })) {
            ExerciseSheet(model: model, kind: kind, order: $editing)
        }
        .sheet(isPresented: $adding) {
            SwapSheet(title: "Add exercise", candidates: model.addCandidates(kind: kind)) { model.add(kind: kind, $0); adding = false }
        }
        .sheet(isPresented: $addingCardio) {
            SwapSheet(title: "Add cardio", candidates: model.cardioCandidates(kind: kind)) { model.addCardio(kind: kind, $0); addingCardio = false }
        }
        .tint(EmberColors.ink)
    }

    private func page(_ draft: WorkoutDraft) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space24) {
                VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
                    Text(numerals: draft.headerLine).typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
                    // SPEC: A4 — `Removed {name} · Undo`: one step back inside the draft, until Undo or the next edit (no timer, A28 (c))
                    if let name = draft.removedName {
                        HStack(spacing: EmberTokens.Spacing.space12) {
                            Text("Removed \(name)").typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
                            Spacer(minLength: EmberTokens.Spacing.space8)
                            TextActionButton(title: "Undo", horizontalPadding: 0, accessibilityLabel: "Undo. Removed \(name)", role: EmberTokens.Typography.textButton) { model.undoRemove(kind: kind) }
                        }
                    }
                }
                group("Exercises", numerals: false) {
                    ForEach(Array(draft.rows.enumerated()), id: \.element.order) { index, row in
                        if index > 0 { seam }
                        Button { editing = row.order } label: {
                            ExerciseListRow(title: WorkoutDraft.title(of: row), detail: WorkoutDraft.detail(of: row), equipment: row.type == "cardio" ? nil : row.equipment)
                                .padding(.horizontal, EmberTokens.Focus.setCardInset)
                        }
                        .buttonStyle(.plain)
                    }
                    if draft.isEmpty { seamless(Text(draft.emptyLine)) }
                    if draft.isFull {
                        seam
                        seamless(Text(numerals: draft.fullLine))
                    } else {
                        if !draft.isEmpty { seam }
                        addRow("Add exercise") { adding = true }
                        if !draft.hasCardio {
                            seam
                            addRow("Add cardio") { addingCardio = true }
                        }
                    }
                }
                group(draft.mobilityLine, numerals: true) {
                    ForEach(Array(draft.holds.enumerated()), id: \.element.order) { index, hold in
                        if index > 0 { seam }
                        Text(WorkoutDraft.holdLine(hold)).typeRole(EmberTokens.Typography.body).foregroundStyle(EmberColors.ink)
                            .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.minTouchTargetPt), alignment: .leading)
                            .padding(.horizontal, EmberTokens.Focus.setCardInset)
                    }
                }
            }
            .padding(.horizontal, EmberTokens.Focus.gutter)
            .padding(.vertical, EmberTokens.Spacing.space16)
        }
    }

    // An eyebrow over one card of rows (A28 (f): cards on the gutter, seams inset like the rows they separate)
    private func group<Rows: View>(_ title: String, numerals: Bool, @ViewBuilder rows: () -> Rows) -> some View {
        let built = rows() // built here: FocusCard's content closure escapes, and a non-escaping builder cannot go with it
        return VStack(alignment: .leading, spacing: EmberTokens.Spacing.space8) {
            (numerals ? Text(numerals: title) : Text(title)).typeRole(EmberTokens.Typography.eyebrow).foregroundStyle(EmberColors.inkSecondary)
                .accessibilityAddTraits(.isHeader)
            FocusCard(padding: 0) { VStack(spacing: 0) { built } }
        }
    }

    private func seamless(_ text: Text) -> some View {
        text.typeRole(EmberTokens.Typography.secondary).foregroundStyle(EmberColors.inkSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, EmberTokens.Focus.setCardInset)
            .padding(.vertical, EmberTokens.Spacing.space16)
    }

    private var seam: some View {
        Rectangle().fill(EmberColors.hairlineOnCard).frame(height: EmberTokens.Size.hairline).padding(.leading, EmberTokens.Focus.setCardInset)
    }

    private func addRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: "plus").typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                .frame(maxWidth: .infinity, minHeight: EmberTokens.Focus.rowButton, alignment: .leading)
                .padding(.horizontal, EmberTokens.Focus.setCardInset)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // A clean draft just pops; a dirty one asks (never silently discards, never silently saves)
    private func cancel() {
        if model.isDirty(kind: kind) { confirmingDiscard = true } else { model.discard(kind: kind); dismiss() }
    }
}

// SPEC: A28 (f) — one row button per exercise (§8: name, value, chevron, 56 pt minimum): no steppers, arrows or links inside it (A4)
struct ExerciseListRow: View {
    let title: String
    let detail: String?
    var equipment: String? = nil // A26: the tag follows the targets — "3 × 8 · [symbol] Barbell" — the symbol against its own word

    var body: some View {
        HStack(spacing: EmberTokens.Spacing.space12) {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                Text(numerals: title).typeRole(EmberTokens.Typography.bodySemibold).foregroundStyle(EmberColors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail {
                    HStack(spacing: EmberTokens.Spacing.space4) {
                        Text(numerals: equipment == nil ? detail : "\(detail) ·")
                        if let equipment {
                            if let symbol = EquipmentLabel.symbol(for: equipment) { Image(systemName: symbol).accessibilityHidden(true) }
                            Text(equipment.capitalized)
                        }
                    }
                    .typeRole(EmberTokens.Typography.secondary)
                    .foregroundStyle(EmberColors.inkSecondary)
                }
            }
            Spacer(minLength: EmberTokens.Spacing.space8)
            Image(systemName: "chevron.right").foregroundStyle(EmberColors.chevron)
        }
        .padding(.vertical, EmberTokens.Spacing.space8)
        .frame(maxWidth: .infinity, minHeight: EmberTokens.Focus.rowButton, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the exercise")
    }
}
