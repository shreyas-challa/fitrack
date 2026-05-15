import SwiftUI
import SwiftData

struct AddCustomExerciseView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var primary: MuscleGroup = .chest
    @State private var equipment: Equipment = .barbell

    let onCreate: (Exercise) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Color.background.ignoresSafeArea()
                Form {
                    Section {
                        TextField("Exercise name", text: $name)
                            .foregroundStyle(Theme.Color.textPrimary)
                    } header: {
                        Text("Name").foregroundStyle(Theme.Color.textTertiary)
                    }
                    .listRowBackground(Theme.Color.surface)

                    Section {
                        Picker("Primary muscle", selection: $primary) {
                            ForEach(MuscleGroup.allCases) { Text($0.display).tag($0) }
                        }
                        Picker("Equipment", selection: $equipment) {
                            ForEach(Equipment.allCases, id: \.self) { Text($0.display).tag($0) }
                        }
                    }
                    .listRowBackground(Theme.Color.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Custom Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let ex = Exercise(
                            name: name.trimmingCharacters(in: .whitespaces),
                            primaryMuscle: primary,
                            equipment: equipment,
                            isCustom: true
                        )
                        context.insert(ex)
                        try? context.save()
                        onCreate(ex)
                        dismiss()
                    }
                    .foregroundStyle(name.trimmingCharacters(in: .whitespaces).isEmpty
                                     ? Theme.Color.textTertiary
                                     : Theme.Color.accent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .toolbarBackground(Theme.Color.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}
