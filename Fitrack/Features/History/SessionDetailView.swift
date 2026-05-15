import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var session: WorkoutSession
    @State private var showingDeleteConfirm = false

    var body: some View {
        ZStack {
            Theme.Color.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    header
                    if session.kind == .lift {
                        liftBody
                    } else {
                        cardioBody
                    }
                }
                .padding(Theme.Spacing.l)
            }
        }
        .navigationTitle(session.sourceTemplateName ?? "Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(Theme.Color.danger)
                }
            }
        }
        .toolbarBackground(Theme.Color.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .confirmationDialog(
            "Delete this session?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                context.delete(session)
                try? context.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var header: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text(session.startedAt.formatted(date: .complete, time: .shortened))
                    .font(Theme.Font.body(13))
                    .foregroundStyle(Theme.Color.textSecondary)
                HStack(spacing: Theme.Spacing.l) {
                    stat("Duration", value: session.durationMin.map { "\($0) min" } ?? "—")
                    if session.kind == .lift {
                        let sets = session.loggedExercises.reduce(0) { $0 + $1.sets.count }
                        stat("Sets", value: "\(sets)")
                        let volume = session.loggedExercises.reduce(0.0) { acc, le in
                            acc + le.sets.reduce(0.0) { $0 + $1.volume }
                        }
                        stat("Volume", value: "\(Int(volume)) kg")
                    } else if let lc = session.loggedCardio {
                        stat("RPE", value: "\(lc.rpe)/10")
                        if let hr = lc.avgHR { stat("Avg HR", value: "\(hr)") }
                    }
                }
            }
        }
    }

    private func stat(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.Color.textTertiary)
            Text(value)
                .font(Theme.Font.numeric(18, weight: .semibold))
                .foregroundStyle(Theme.Color.textPrimary)
        }
    }

    private var liftBody: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            ForEach(session.loggedExercises.sorted { $0.orderIndex < $1.orderIndex }) { le in
                Card {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Text(le.exercise?.name ?? "—")
                            .font(Theme.Font.body(16, weight: .semibold))
                            .foregroundStyle(Theme.Color.textPrimary)
                        ForEach(Array(le.sets.sorted { $0.orderIndex < $1.orderIndex }.enumerated()), id: \.element.id) { idx, set in
                            HStack {
                                Text("Set \(idx + 1)")
                                    .font(Theme.Font.body(13))
                                    .foregroundStyle(Theme.Color.textSecondary)
                                    .frame(width: 56, alignment: .leading)
                                Text("\(format(set.weightKg)) kg × \(set.reps)")
                                    .font(Theme.Font.numeric(15, weight: .semibold))
                                    .foregroundStyle(Theme.Color.textPrimary)
                                if let rpe = set.rpe {
                                    Text("RPE \(format(rpe))")
                                        .font(Theme.Font.body(12))
                                        .foregroundStyle(Theme.Color.textTertiary)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }
        }
    }

    private var cardioBody: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                if let lc = session.loggedCardio {
                    row("Type", lc.type.display)
                    row("Intensity", lc.intensity.display)
                    row("Duration", "\(lc.durationMin) min")
                    if let km = lc.distanceKm { row("Distance", String(format: "%.2f km", km)) }
                    if let hr = lc.avgHR { row("Avg HR", "\(hr) bpm") }
                    row("RPE", "\(lc.rpe)/10")
                    if let n = lc.notes, !n.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes").font(Theme.Font.body(11)).foregroundStyle(Theme.Color.textTertiary)
                            Text(n).font(Theme.Font.body(14)).foregroundStyle(Theme.Color.textPrimary)
                        }
                    }
                }
            }
        }
    }

    private func row(_ k: String, _ v: String) -> some View {
        HStack {
            Text(k).foregroundStyle(Theme.Color.textSecondary).font(Theme.Font.body(14))
            Spacer()
            Text(v).foregroundStyle(Theme.Color.textPrimary).font(Theme.Font.numeric(15, weight: .semibold))
        }
    }

    private func format(_ d: Double) -> String {
        d.rounded() == d ? String(Int(d)) : String(format: "%.1f", d)
    }
}
