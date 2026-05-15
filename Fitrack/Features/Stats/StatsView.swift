import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.startedAt, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \PersonalRecord.updatedAt, order: .reverse) private var records: [PersonalRecord]

    @State private var selectedExercise: Exercise?

    var body: some View {
        ScreenScaffold(title: "Stats") {
            streakCard
            weeklyVolumeCard
            progressionCard
            prsCard
        }
    }

    private var streakCard: some View {
        Card(elevated: true) {
            let dates = sessions.map { $0.startedAt }
            let s = StreakCalculator.compute(sessions: dates)
            HStack(spacing: Theme.Spacing.xl) {
                stat("Current", value: "\(s.current)", suffix: s.current == 1 ? "day" : "days")
                stat("Longest", value: "\(s.longest)", suffix: s.longest == 1 ? "day" : "days")
                stat("This month", value: "\(s.thisMonth)", suffix: "days")
            }
        }
    }

    private func stat(_ label: String, value: String, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Theme.Color.textTertiary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value).font(Theme.Font.numeric(28, weight: .bold)).foregroundStyle(Theme.Color.textPrimary)
                Text(suffix).font(Theme.Font.body(12)).foregroundStyle(Theme.Color.textSecondary)
            }
        }
    }

    private var weeklyVolumeCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                HStack {
                    Text("Last 7 days")
                        .font(Theme.Font.body(15, weight: .semibold))
                        .foregroundStyle(Theme.Color.textPrimary)
                    Spacer()
                    let cardioMin = VolumeCalculator.weeklyCardioMinutes(sessions: sessions)
                    Label("\(cardioMin) min cardio", systemImage: "heart.fill")
                        .font(Theme.Font.body(12))
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                let volume = VolumeCalculator.weeklyVolume(sessions: sessions)
                if volume.isEmpty {
                    Text("No working sets logged yet this week.")
                        .font(Theme.Font.body(13))
                        .foregroundStyle(Theme.Color.textSecondary)
                } else {
                    Chart(volume) { item in
                        BarMark(
                            x: .value("Sets", item.sets),
                            y: .value("Muscle", item.muscle.display)
                        )
                        .foregroundStyle(Theme.Color.accent)
                        .cornerRadius(4)
                        .annotation(position: .trailing, alignment: .leading) {
                            Text("\(item.sets)")
                                .font(Theme.Font.numeric(11, weight: .semibold))
                                .foregroundStyle(Theme.Color.textSecondary)
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading) { _ in
                            AxisValueLabel().foregroundStyle(Theme.Color.textSecondary)
                        }
                    }
                    .frame(height: CGFloat(volume.count) * 24 + 20)
                }
            }
        }
    }

    private var progressionCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                HStack {
                    Text("Progression")
                        .font(Theme.Font.body(15, weight: .semibold))
                        .foregroundStyle(Theme.Color.textPrimary)
                    Spacer()
                    Menu {
                        ForEach(loggedExercisesList(), id: \.id) { ex in
                            Button(ex.name) { selectedExercise = ex }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(selectedExercise?.name ?? "Pick exercise")
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                        }
                        .font(Theme.Font.body(13, weight: .medium))
                        .foregroundStyle(Theme.Color.accent)
                    }
                }
                if let ex = selectedExercise {
                    let points = progressionPoints(for: ex)
                    if points.isEmpty {
                        Text("No logged sets for this exercise yet.")
                            .font(Theme.Font.body(13))
                            .foregroundStyle(Theme.Color.textSecondary)
                    } else {
                        Chart(points) { p in
                            LineMark(
                                x: .value("Date", p.date),
                                y: .value("e1RM", p.estimated1RM)
                            )
                            .foregroundStyle(Theme.Color.accent)
                            .interpolationMethod(.monotone)

                            PointMark(
                                x: .value("Date", p.date),
                                y: .value("e1RM", p.estimated1RM)
                            )
                            .foregroundStyle(Theme.Color.accent)
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                                AxisValueLabel().foregroundStyle(Theme.Color.textSecondary)
                                AxisGridLine().foregroundStyle(Theme.Color.border)
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisValueLabel().foregroundStyle(Theme.Color.textSecondary)
                                AxisGridLine().foregroundStyle(Theme.Color.border)
                            }
                        }
                        .frame(height: 180)
                        Text("Estimated 1RM (Epley)")
                            .font(Theme.Font.body(11))
                            .foregroundStyle(Theme.Color.textTertiary)
                    }
                } else {
                    Text("Pick an exercise to see weight × reps progression over time.")
                        .font(Theme.Font.body(13))
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
        }
        .onAppear {
            if selectedExercise == nil {
                selectedExercise = loggedExercisesList().first
            }
        }
    }

    private var prsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                Text("Personal Records")
                    .font(Theme.Font.body(15, weight: .semibold))
                    .foregroundStyle(Theme.Color.textPrimary)
                if records.isEmpty {
                    Text("PRs will appear here automatically as you log working sets.")
                        .font(Theme.Font.body(13))
                        .foregroundStyle(Theme.Color.textSecondary)
                } else {
                    let grouped = Dictionary(grouping: records, by: { $0.exercise?.id ?? UUID() })
                    ForEach(Array(grouped.values), id: \.first!.id) { group in
                        if let ex = group.first?.exercise {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ex.name)
                                    .font(Theme.Font.body(14, weight: .semibold))
                                    .foregroundStyle(Theme.Color.textPrimary)
                                HStack(spacing: Theme.Spacing.m) {
                                    ForEach(group.sorted { $0.repBucket < $1.repBucket }) { pr in
                                        VStack(spacing: 2) {
                                            Text("\(pr.repBucket)RM")
                                                .font(.system(size: 9, weight: .semibold))
                                                .foregroundStyle(Theme.Color.textTertiary)
                                            Text("\(format(pr.weightKg))")
                                                .font(Theme.Font.numeric(15, weight: .bold))
                                                .foregroundStyle(Theme.Color.accent)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Theme.Color.surfaceElevated)
                                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous))
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }

    private func loggedExercisesList() -> [Exercise] {
        var seen = Set<UUID>()
        var result: [Exercise] = []
        for s in sessions where s.kind == .lift {
            for le in s.loggedExercises {
                if let ex = le.exercise, !seen.contains(ex.id) {
                    seen.insert(ex.id)
                    result.append(ex)
                }
            }
        }
        return result.sorted { $0.name < $1.name }
    }

    private struct ProgressionPoint: Identifiable {
        let date: Date
        let estimated1RM: Double
        var id: Date { date }
    }

    private func progressionPoints(for exercise: Exercise) -> [ProgressionPoint] {
        var points: [ProgressionPoint] = []
        for session in sessions.sorted(by: { $0.startedAt < $1.startedAt }) where session.kind == .lift {
            var bestE1RM: Double = 0
            for le in session.loggedExercises where le.exercise?.id == exercise.id {
                for set in le.sets where set.weightKg > 0 && set.reps > 0 && !set.isWarmup {
                    let e1rm = set.weightKg * (1.0 + Double(set.reps) / 30.0)
                    if e1rm > bestE1RM { bestE1RM = e1rm }
                }
            }
            if bestE1RM > 0 {
                points.append(ProgressionPoint(date: session.startedAt, estimated1RM: bestE1RM.rounded()))
            }
        }
        return points
    }

    private func format(_ d: Double) -> String {
        d.rounded() == d ? String(Int(d)) : String(format: "%.1f", d)
    }
}

extension PersonalRecord: Identifiable {}
