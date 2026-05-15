import SwiftUI
import SwiftData

struct ExerciseLogCard: View {
    @Environment(\.modelContext) private var context
    @Bindable var loggedExercise: LoggedExercise
    let onCompleteSet: (Int) -> Void

    @State private var lastSets: [LoggedSet] = []
    @State private var showRPE = false

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                header
                columnHeaders
                ForEach(Array(loggedExercise.sets.sorted { $0.orderIndex < $1.orderIndex }.enumerated()), id: \.element.id) { idx, set in
                    SetRow(
                        set: set,
                        setNumber: idx + 1,
                        hint: lastSets.indices.contains(idx) ? lastSets[idx] : nil,
                        showRPE: showRPE,
                        onComplete: {
                            let rest = set.restAfterSec ?? 120
                            onCompleteSet(rest)
                        }
                    )
                }
                HStack(spacing: Theme.Spacing.s) {
                    Button {
                        addSet()
                    } label: {
                        Label("Add Set", systemImage: "plus.circle")
                            .font(Theme.Font.body(13, weight: .medium))
                            .foregroundStyle(Theme.Color.accent)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button {
                        showRPE.toggle()
                    } label: {
                        Label(showRPE ? "Hide RPE" : "Show RPE", systemImage: "gauge.with.dots.needle.50percent")
                            .font(Theme.Font.body(12, weight: .medium))
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear { loadLastSets() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(loggedExercise.exercise?.name ?? "—")
                .font(Theme.Font.body(17, weight: .semibold))
                .foregroundStyle(Theme.Color.textPrimary)
            if let muscle = loggedExercise.exercise?.primaryMuscle.display {
                Text(muscle)
                    .font(Theme.Font.body(12))
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
    }

    private var columnHeaders: some View {
        HStack(spacing: Theme.Spacing.s) {
            Text("SET").frame(width: 32, alignment: .leading)
            Text("LAST").frame(width: 76, alignment: .leading)
            Text("KG").frame(maxWidth: .infinity, alignment: .leading)
            Text("REPS").frame(maxWidth: .infinity, alignment: .leading)
            if showRPE {
                Text("RPE").frame(width: 48, alignment: .leading)
            }
            Text("").frame(width: 32)
        }
        .font(.system(size: 10, weight: .semibold))
        .foregroundStyle(Theme.Color.textTertiary)
    }

    private func loadLastSets() {
        guard let exercise = loggedExercise.exercise else { return }
        let sessionStart = loggedExercise.session?.startedAt ?? .now
        lastSets = SessionHelpers.lastSets(for: exercise, before: sessionStart, context: context)
    }

    private func addSet() {
        let next = LoggedSet(
            orderIndex: loggedExercise.sets.count,
            weightKg: 0,
            reps: 0,
            restAfterSec: loggedExercise.sets.last?.restAfterSec ?? 120
        )
        next.loggedExercise = loggedExercise
        context.insert(next)
        loggedExercise.sets.append(next)
    }
}

private struct SetRow: View {
    @Bindable var set: LoggedSet
    let setNumber: Int
    let hint: LoggedSet?
    let showRPE: Bool
    let onComplete: () -> Void

    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var rpeText: String = ""
    @State private var isCompleted: Bool = false

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            Text("\(setNumber)")
                .font(Theme.Font.numeric(15, weight: .semibold))
                .foregroundStyle(Theme.Color.textSecondary)
                .frame(width: 32, alignment: .leading)

            Text(hintLabel)
                .font(Theme.Font.body(12))
                .foregroundStyle(Theme.Color.textTertiary)
                .frame(width: 76, alignment: .leading)
                .lineLimit(1)

            numericField($weightText, placeholder: hint.map { trim($0.weightKg) } ?? "0")
                .onChange(of: weightText) { _, new in
                    set.weightKg = Double(new) ?? 0
                }
            numericField($repsText, placeholder: hint.map { "\($0.reps)" } ?? "0", isInt: true)
                .onChange(of: repsText) { _, new in
                    set.reps = Int(new) ?? 0
                }

            if showRPE {
                numericField($rpeText, placeholder: "—", width: 48)
                    .onChange(of: rpeText) { _, new in
                        set.rpe = Double(new)
                    }
            }

            Button {
                toggleComplete()
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isCompleted ? Theme.Color.success : Theme.Color.textTertiary)
            }
            .buttonStyle(.plain)
            .frame(width: 32)
        }
        .padding(.vertical, 4)
        .onAppear { syncFromModel() }
    }

    private func syncFromModel() {
        weightText = set.weightKg > 0 ? trim(set.weightKg) : ""
        repsText = set.reps > 0 ? "\(set.reps)" : ""
        rpeText = set.rpe.map { trim($0) } ?? ""
        isCompleted = (set.weightKg > 0 || set.reps > 0)
    }

    private func toggleComplete() {
        if isCompleted {
            isCompleted = false
            return
        }
        if (Double(weightText) ?? 0) > 0 || (Int(repsText) ?? 0) > 0 {
            isCompleted = true
            set.completedAt = .now
            onComplete()
        } else if let h = hint {
            weightText = trim(h.weightKg)
            repsText = "\(h.reps)"
            set.weightKg = h.weightKg
            set.reps = h.reps
            set.completedAt = .now
            isCompleted = true
            onComplete()
        }
    }

    private var hintLabel: String {
        guard let h = hint else { return "—" }
        return "\(trim(h.weightKg))×\(h.reps)"
    }

    private func trim(_ d: Double) -> String {
        if d.rounded() == d {
            return String(Int(d))
        }
        return String(format: "%.1f", d)
    }

    private func numericField(_ text: Binding<String>, placeholder: String, isInt: Bool = false, width: CGFloat? = nil) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(isInt ? .numberPad : .decimalPad)
            .font(Theme.Font.numeric(17, weight: .semibold))
            .foregroundStyle(Theme.Color.textPrimary)
            .multilineTextAlignment(.leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(Theme.Color.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous))
            .frame(maxWidth: width ?? .infinity)
    }
}
