import SwiftUI
import SwiftData

struct LiftTemplateEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let template: WorkoutTemplate?

    @State private var name: String
    @State private var notes: String
    @State private var items: [TemplateExercise]
    @State private var showingPicker = false
    @State private var showingDeleteConfirm = false

    init(template: WorkoutTemplate?) {
        self.template = template
        _name = State(initialValue: template?.name ?? "")
        _notes = State(initialValue: template?.notes ?? "")
        _items = State(initialValue: (template?.exercises ?? []).sorted { $0.orderIndex < $1.orderIndex })
    }

    var body: some View {
        ZStack {
            Theme.Color.background.ignoresSafeArea()
            Form {
                Section {
                    TextField("Template name (e.g. Push A)", text: $name)
                        .foregroundStyle(Theme.Color.textPrimary)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(1...3)
                        .foregroundStyle(Theme.Color.textPrimary)
                } header: {
                    Text("Template").foregroundStyle(Theme.Color.textTertiary)
                }
                .listRowBackground(Theme.Color.surface)

                Section {
                    if items.isEmpty {
                        Text("No exercises yet — tap Add Exercise below.")
                            .font(Theme.Font.body(13))
                            .foregroundStyle(Theme.Color.textSecondary)
                    } else {
                        ForEach(items) { item in
                            exerciseRow(item)
                        }
                        .onMove { src, dst in
                            items.move(fromOffsets: src, toOffset: dst)
                            for (i, it) in items.enumerated() { it.orderIndex = i }
                        }
                        .onDelete { offsets in
                            for i in offsets {
                                context.delete(items[i])
                            }
                            items.remove(atOffsets: offsets)
                            for (i, it) in items.enumerated() { it.orderIndex = i }
                        }
                    }

                    Button {
                        showingPicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                            .foregroundStyle(Theme.Color.accent)
                    }
                } header: {
                    Text("Exercises").foregroundStyle(Theme.Color.textTertiary)
                }
                .listRowBackground(Theme.Color.surface)

                if template != nil {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Template")
                                Spacer()
                            }
                        }
                    }
                    .listRowBackground(Theme.Color.surface)
                }
            }
            .scrollContentBackground(.hidden)
            .environment(\.editMode, .constant(.active))
        }
        .navigationTitle(template == nil ? "New Lift Template" : "Edit Template")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if template == nil {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
                    .foregroundStyle(canSave ? Theme.Color.accent : Theme.Color.textTertiary)
                    .disabled(!canSave)
            }
        }
        .toolbarBackground(Theme.Color.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $showingPicker) {
            ExercisePickerView { exercise in
                let newItem = TemplateExercise(exercise: exercise, orderIndex: items.count)
                items.append(newItem)
            }
        }
        .confirmationDialog(
            "Delete this template?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let template { context.delete(template) }
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !items.isEmpty
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)
        let target: WorkoutTemplate
        if let existing = template {
            existing.name = trimmedName
            existing.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
            existing.updatedAt = .now
            target = existing
        } else {
            target = WorkoutTemplate(
                name: trimmedName,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes
            )
            context.insert(target)
        }

        for (i, it) in items.enumerated() {
            it.orderIndex = i
            it.template = target
            if it.modelContext == nil {
                context.insert(it)
            }
        }
        try? context.save()
        dismiss()
    }

    private func exerciseRow(_ item: TemplateExercise) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(item.exercise?.name ?? "—")
                .font(Theme.Font.body(15, weight: .semibold))
                .foregroundStyle(Theme.Color.textPrimary)

            HStack(spacing: Theme.Spacing.m) {
                stepperField(title: "Sets", value: Binding(
                    get: { item.targetSets },
                    set: { item.targetSets = max(1, $0) }
                ), range: 1...10)

                stepperField(title: "Rep low", value: Binding(
                    get: { item.targetRepsLow },
                    set: { item.targetRepsLow = max(1, $0); if item.targetRepsHigh < item.targetRepsLow { item.targetRepsHigh = item.targetRepsLow } }
                ), range: 1...50)

                stepperField(title: "Rep high", value: Binding(
                    get: { item.targetRepsHigh },
                    set: { item.targetRepsHigh = max(item.targetRepsLow, $0) }
                ), range: 1...50)
            }

            HStack {
                Text("Rest")
                    .font(Theme.Font.body(12))
                    .foregroundStyle(Theme.Color.textSecondary)
                Picker("Rest", selection: Binding(
                    get: { item.targetRestSec },
                    set: { item.targetRestSec = $0 }
                )) {
                    ForEach([60, 90, 120, 150, 180, 240, 300], id: \.self) { sec in
                        Text("\(sec / 60)m \(sec % 60 == 0 ? "" : "\(sec % 60)s")".trimmingCharacters(in: .whitespaces))
                            .tag(sec)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.Color.accent)
            }
        }
        .padding(.vertical, 4)
    }

    private func stepperField(title: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(Theme.Font.body(11))
                .foregroundStyle(Theme.Color.textSecondary)
            HStack(spacing: 4) {
                Button { if value.wrappedValue > range.lowerBound { value.wrappedValue -= 1 } } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                .buttonStyle(.plain)
                Text("\(value.wrappedValue)")
                    .font(Theme.Font.numeric(15))
                    .foregroundStyle(Theme.Color.textPrimary)
                    .frame(minWidth: 24)
                Button { if value.wrappedValue < range.upperBound { value.wrappedValue += 1 } } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Theme.Color.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
