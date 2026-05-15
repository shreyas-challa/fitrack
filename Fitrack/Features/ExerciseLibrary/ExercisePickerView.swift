import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var searchText = ""
    @State private var muscleFilter: MuscleGroup? = nil
    @State private var showingAddCustom = false

    let onPick: (Exercise) -> Void

    private var filtered: [Exercise] {
        exercises.filter { ex in
            let matchesSearch = searchText.isEmpty || ex.name.localizedCaseInsensitiveContains(searchText)
            let matchesMuscle = muscleFilter == nil || ex.primaryMuscle == muscleFilter
            return matchesSearch && matchesMuscle
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Color.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    muscleFilterStrip
                    List {
                        ForEach(filtered) { ex in
                            Button {
                                onPick(ex)
                                dismiss()
                            } label: {
                                row(ex)
                            }
                            .listRowBackground(Theme.Color.surface)
                            .listRowSeparatorTint(Theme.Color.border)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Theme.Color.background)
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddCustom = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Theme.Color.accent)
                    }
                }
            }
            .toolbarBackground(Theme.Color.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showingAddCustom) {
                AddCustomExerciseView { newEx in
                    onPick(newEx)
                    dismiss()
                }
                .preferredColorScheme(.dark)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var muscleFilterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.s) {
                chip("All", isSelected: muscleFilter == nil) { muscleFilter = nil }
                ForEach(MuscleGroup.allCases) { mg in
                    chip(mg.display, isSelected: muscleFilter == mg) { muscleFilter = mg }
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.s)
        }
        .background(Theme.Color.background)
    }

    private func chip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Theme.Font.body(13, weight: .medium))
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, 6)
                .background(isSelected ? Theme.Color.accent : Theme.Color.surfaceElevated)
                .foregroundStyle(isSelected ? Theme.Color.background : Theme.Color.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func row(_ ex: Exercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(ex.name)
                    .font(Theme.Font.body(15, weight: .medium))
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("\(ex.primaryMuscle.display) · \(ex.equipment.display)")
                    .font(Theme.Font.body(12))
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            Spacer()
            if ex.isCustom {
                Text("CUSTOM")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Theme.Color.surfaceElevated)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
        }
        .padding(.vertical, 4)
    }
}
