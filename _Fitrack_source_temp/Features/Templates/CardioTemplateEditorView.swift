import SwiftUI
import SwiftData

struct CardioTemplateEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let template: CardioTemplate?

    @State private var name: String
    @State private var type: CardioType
    @State private var intensity: CardioIntensity
    @State private var hasDuration: Bool
    @State private var durationMin: Int
    @State private var hasDistance: Bool
    @State private var distanceKm: Double
    @State private var intervalSpec: String
    @State private var notes: String
    @State private var showingDeleteConfirm = false

    init(template: CardioTemplate?) {
        self.template = template
        _name = State(initialValue: template?.name ?? "")
        _type = State(initialValue: template?.type ?? .bike)
        _intensity = State(initialValue: template?.intensity ?? .zone2)
        _hasDuration = State(initialValue: template?.plannedDurationMin != nil)
        _durationMin = State(initialValue: template?.plannedDurationMin ?? 45)
        _hasDistance = State(initialValue: template?.plannedDistanceKm != nil)
        _distanceKm = State(initialValue: template?.plannedDistanceKm ?? 5.0)
        _intervalSpec = State(initialValue: template?.intervalSpec ?? "")
        _notes = State(initialValue: template?.notes ?? "")
    }

    var body: some View {
        ZStack {
            Theme.Color.background.ignoresSafeArea()
            Form {
                Section {
                    TextField("Template name (e.g. Z2 Bike 45)", text: $name)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Picker("Type", selection: $type) {
                        ForEach(CardioType.allCases, id: \.self) { t in
                            Label(t.display, systemImage: t.systemImage).tag(t)
                        }
                    }
                    Picker("Intensity", selection: $intensity) {
                        ForEach(CardioIntensity.allCases, id: \.self) { i in
                            Text(i.display).tag(i)
                        }
                    }
                } header: {
                    Text("Template").foregroundStyle(Theme.Color.textTertiary)
                }
                .listRowBackground(Theme.Color.surface)

                Section {
                    Toggle("Target duration", isOn: $hasDuration)
                        .tint(Theme.Color.accent)
                    if hasDuration {
                        Stepper(value: $durationMin, in: 5...240, step: 5) {
                            HStack {
                                Text("Duration")
                                Spacer()
                                Text("\(durationMin) min")
                                    .font(Theme.Font.numeric(15))
                                    .foregroundStyle(Theme.Color.accent)
                            }
                        }
                    }
                    Toggle("Target distance", isOn: $hasDistance)
                        .tint(Theme.Color.accent)
                    if hasDistance {
                        HStack {
                            Text("Distance")
                            Spacer()
                            TextField("km", value: $distanceKm, format: .number.precision(.fractionLength(1)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 80)
                                .foregroundStyle(Theme.Color.accent)
                            Text("km").foregroundStyle(Theme.Color.textSecondary)
                        }
                    }
                } header: {
                    Text("Targets").foregroundStyle(Theme.Color.textTertiary)
                }
                .listRowBackground(Theme.Color.surface)

                if intensity == .intervals {
                    Section {
                        TextField("e.g. 4x4min @ hard / 3min rest", text: $intervalSpec, axis: .vertical)
                            .lineLimit(1...3)
                            .foregroundStyle(Theme.Color.textPrimary)
                    } header: {
                        Text("Interval spec").foregroundStyle(Theme.Color.textTertiary)
                    }
                    .listRowBackground(Theme.Color.surface)
                }

                Section {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                        .foregroundStyle(Theme.Color.textPrimary)
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
        }
        .navigationTitle(template == nil ? "New Cardio Template" : "Edit Template")
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
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)
        let trimmedSpec = intervalSpec.trimmingCharacters(in: .whitespaces)

        if let existing = template {
            existing.name = trimmedName
            existing.type = type
            existing.intensity = intensity
            existing.plannedDurationMin = hasDuration ? durationMin : nil
            existing.plannedDistanceKm = hasDistance ? distanceKm : nil
            existing.intervalSpec = trimmedSpec.isEmpty ? nil : trimmedSpec
            existing.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
            existing.updatedAt = .now
        } else {
            let new = CardioTemplate(
                name: trimmedName,
                type: type,
                intensity: intensity,
                plannedDurationMin: hasDuration ? durationMin : nil,
                plannedDistanceKm: hasDistance ? distanceKm : nil,
                intervalSpec: trimmedSpec.isEmpty ? nil : trimmedSpec,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes
            )
            context.insert(new)
        }
        try? context.save()
        dismiss()
    }
}
