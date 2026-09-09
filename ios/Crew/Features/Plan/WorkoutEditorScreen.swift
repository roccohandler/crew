// SPEC: A4 (owner-directed 2026-09-08) · S14 — the workout editor, one workout, pushed full screen: title `{name}`,
// `Cancel` / `Save` (Save disabled until dirty), header `{n} exercises + mobility · ~{min} min`, section `Exercises` with
// `Reorder` ↔ `Done` (edit mode + onMove), rows `{name}` / `{sets} × {reps} · {Equipment}` as ONE tap target opening the
// exercise sheet, `Add exercise`, `Add cardio` (one block, after the strength rows), the mobility footer (read-only, closes
// the workout), the Undo snackbar after a remove, `Discard changes to {name}?` on a dirty Cancel. Forward-only (Flow 8).
// Screens hold zero logic (5.6.6). Ink on bone, never orange. WRITTEN — UNVERIFIED (needs Mac).

import SwiftUI

struct WorkoutEditorScreen: View {
    let model: PlanModel
    let kind: String
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var editMode: EditMode = .inactive
    @State private var editing: Int?        // the order of the row open in the exercise sheet
    @State private var adding = false
    @State private var addingCardio = false
    @State private var confirmingDiscard = false

    var body: some View {
        Group {
            if let draft = model.drafts[kind] { list(draft) } else { ListSkeleton() }
        }
        .background(EmberColors.canvas.ignoresSafeArea())
        .navigationTitle(model.name(ofKind: kind))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { cancel() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { if model.save(kind: kind) { onSaved() } }.disabled(!model.isDirty(kind: kind))
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
        .overlay(alignment: .bottom) {
            if let name = model.drafts[kind]?.removedName {
                UndoSnackbar(line: "Removed \(name)") { model.undoRemove(kind: kind) }
            }
        }
        .tint(EmberColors.inkText)
    }

    private func list(_ draft: WorkoutDraft) -> some View {
        List {
            Section {
                Text(draft.headerLine).font(.subheadline).foregroundStyle(EmberColors.secondaryText).listRowBackground(EmberColors.canvas)
            }
            Section {
                ForEach(draft.rows, id: \.order) { row in
                    Button { editing = row.order } label: {
                        ExerciseListRow(title: WorkoutDraft.title(of: row), detail: WorkoutDraft.detail(of: row), chevron: !editMode.isEditing)
                    }
                    .buttonStyle(.plain)
                    .disabled(editMode.isEditing)
                    .listRowBackground(EmberColors.card)
                }
                .onMove { model.move(kind: kind, from: $0, to: $1) }
                if draft.isEmpty { Text(draft.emptyLine).font(.subheadline).foregroundStyle(EmberColors.secondaryText).listRowBackground(EmberColors.card) }
                if draft.isFull {
                    Text(draft.fullLine).font(.subheadline).foregroundStyle(EmberColors.secondaryText).listRowBackground(EmberColors.card)
                } else {
                    addRow("Add exercise") { adding = true }
                    if !draft.hasCardio { addRow("Add cardio") { addingCardio = true } }
                }
            } header: {
                HStack {
                    Text("Exercises")
                    Spacer()
                    Button(editMode.isEditing ? "Done" : "Reorder") { withAnimation(.crewSpring) { editMode = editMode.isEditing ? .inactive : .active } }
                        .font(.subheadline.weight(.semibold)).foregroundStyle(EmberColors.inkText).textCase(nil)
                        .frame(minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                        .disabled(draft.rows.count <= 1)
                }
            }
            Section {
                ForEach(draft.holds, id: \.order) { hold in
                    Text(WorkoutDraft.holdLine(hold)).font(.subheadline).foregroundStyle(EmberColors.secondaryText).listRowBackground(EmberColors.card)
                }
            } header: {
                Text(draft.mobilityLine).textCase(nil)
            }
        }
        .environment(\.editMode, $editMode)
        .scrollContentBackground(.hidden)
        .safeAreaPadding(.bottom, draft.removedName == nil ? 0 : CGFloat(SpecConstants.dayToggleMinPt) + EmberTokens.Spacing.space32) // the snackbar's height plus its margins
    }

    private func addRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: "plus").font(.body.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.minTouchTargetPt), alignment: .leading)
        }
        .buttonStyle(.plain)
        .disabled(editMode.isEditing)
        .listRowBackground(EmberColors.card)
    }

    // A clean draft just pops; a dirty one asks (never silently discards, never silently saves)
    private func cancel() {
        if model.isDirty(kind: kind) { confirmingDiscard = true } else { model.discard(kind: kind); dismiss() }
    }
}

// One tap target per row: no steppers, arrows or links inside it (A4)
struct ExerciseListRow: View {
    let title: String
    let detail: String?
    let chevron: Bool

    var body: some View {
        HStack(spacing: EmberTokens.Spacing.space12) {
            VStack(alignment: .leading, spacing: EmberTokens.Spacing.space4) {
                Text(title).font(.body.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                if let detail { Text(detail).font(.subheadline.monospacedDigit()).foregroundStyle(EmberColors.secondaryText) }
            }
            Spacer()
            if chevron { Image(systemName: "chevron.right").font(.subheadline.weight(.semibold)).foregroundStyle(EmberColors.secondaryText) }
        }
        .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.dayToggleMinPt), alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the exercise")
    }
}

// SPEC: A4 — `Removed {name} · Undo`: one step back inside the draft; it stays until Undo or the next edit (no timer,
// so no bare number — a duration constant is requested from C1 in the handoff)
struct UndoSnackbar: View {
    let line: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: EmberTokens.Spacing.space12) {
            Text(line).font(.subheadline).foregroundStyle(EmberColors.inkText)
            Spacer()
            Button("Undo", action: onUndo)
                .font(.subheadline.weight(.semibold)).foregroundStyle(EmberColors.inkText)
                .frame(minWidth: CGFloat(SpecConstants.minTouchTargetPt), minHeight: CGFloat(SpecConstants.minTouchTargetPt))
                .accessibilityLabel("Undo. \(line)")
        }
        .padding(.horizontal, EmberTokens.Spacing.space16)
        .frame(maxWidth: .infinity, minHeight: CGFloat(SpecConstants.dayToggleMinPt))
        .background(EmberColors.card, in: RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: EmberTokens.Size.cornerRadius, style: .continuous).stroke(EmberColors.hairline, lineWidth: EmberTokens.Size.hairline))
        .padding(EmberTokens.Spacing.space16)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
