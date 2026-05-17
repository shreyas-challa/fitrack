import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.startedAt, order: .reverse)
    private var sessions: [WorkoutSession]

    @State private var monthAnchor: Date = Calendar.current.startOfMonth(for: .now)
    @State private var selectedDay: Date?

    var body: some View {
        ScreenScaffold(title: "History") {
            monthHeader
            heatmap
            sessionList
        }
        .sheet(item: $selectedDay.identifiableBinding()) { day in
            DaySessionsSheet(day: day, sessions: sessionsOn(day: day.date))
                .preferredColorScheme(.dark)
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation {
                    monthAnchor = Calendar.current.date(byAdding: .month, value: -1, to: monthAnchor) ?? monthAnchor
                }
            } label: {
                Image(systemName: "chevron.left")
                    .padding(8)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            Spacer()
            Text(monthAnchor.formatted(.dateTime.month(.wide).year()))
                .font(Theme.Font.body(17, weight: .semibold))
                .foregroundStyle(Theme.Color.textPrimary)
            Spacer()
            Button {
                withAnimation {
                    monthAnchor = Calendar.current.date(byAdding: .month, value: 1, to: monthAnchor) ?? monthAnchor
                }
            } label: {
                Image(systemName: "chevron.right")
                    .padding(8)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
    }

    private var heatmap: some View {
        Card {
            VStack(spacing: Theme.Spacing.s) {
                HStack {
                    ForEach(["S","M","T","W","T","F","S"], id: \.self) { d in
                        Text(d)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.Color.textTertiary)
                            .frame(maxWidth: .infinity)
                    }
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                    ForEach(monthGrid(), id: \.self) { day in
                        cellFor(day: day)
                    }
                }
                legend
            }
        }
    }

    private func cellFor(day: Date?) -> some View {
        Group {
            if let day {
                let kinds = kindsOn(day: day)
                Button { selectedDay = day } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(fillFor(kinds: kinds, day: day))
                        Text("\(Calendar.current.component(.day, from: day))")
                            .font(Theme.Font.numeric(12, weight: .semibold))
                            .foregroundStyle(textColorFor(kinds: kinds, day: day))
                        if Calendar.current.isDateInToday(day) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Theme.Color.accent, lineWidth: 1.5)
                        }
                    }
                    .frame(height: 36)
                }
                .buttonStyle(.plain)
                .disabled(kinds.isEmpty)
            } else {
                Color.clear.frame(height: 36)
            }
        }
    }

    private var legend: some View {
        HStack(spacing: Theme.Spacing.m) {
            legendChip(color: Theme.Color.surfaceElevated, label: "Rest")
            legendChip(color: Color(hex: 0x22C55E), label: "Lift")
            legendChip(color: Color(hex: 0x22C55E).opacity(0.55), label: "Cardio")
            legendChip(color: Color(hex: 0x4ADE80), label: "Both")
            Spacer()
        }
        .padding(.top, Theme.Spacing.s)
    }

    private func legendChip(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(Theme.Font.body(11))
                .foregroundStyle(Theme.Color.textSecondary)
        }
    }

    private func fillFor(kinds: Set<WorkoutKind>, day: Date) -> Color {
        if kinds.contains(.lift) && kinds.contains(.cardio) { return Color(hex: 0x4ADE80) }
        if kinds.contains(.lift) { return Color(hex: 0x22C55E) }
        if kinds.contains(.cardio) { return Color(hex: 0x22C55E).opacity(0.55) }
        return Theme.Color.surfaceElevated
    }

    private func textColorFor(kinds: Set<WorkoutKind>, day: Date) -> Color {
        kinds.isEmpty ? Theme.Color.textTertiary : Theme.Color.background
    }

    private var sessionList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("RECENT")
                .font(Theme.Font.sectionHeader)
                .foregroundStyle(Theme.Color.textTertiary)
                .padding(.leading, Theme.Spacing.xs)
            if sessions.isEmpty {
                Card {
                    Text("No sessions yet. Finish a workout from Today to see it here.")
                        .font(Theme.Font.body(13))
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            } else {
                ForEach(Array(sessions.prefix(15))) { session in
                    NavigationLink {
                        SessionDetailView(session: session)
                    } label: {
                        sessionRow(session)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func sessionRow(_ session: WorkoutSession) -> some View {
        Card {
            HStack(spacing: Theme.Spacing.m) {
                Image(systemName: session.kind == .lift ? "dumbbell.fill" : "heart.fill")
                    .foregroundStyle(Theme.Color.accent)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.sourceTemplateName ?? (session.kind == .lift ? "Lift Session" : "Cardio Session"))
                        .font(Theme.Font.body(15, weight: .semibold))
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text(subtitle(for: session))
                        .font(Theme.Font.body(12))
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                Spacer()
                Text(session.startedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(Theme.Font.body(12))
                    .foregroundStyle(Theme.Color.textTertiary)
            }
        }
    }

    private func subtitle(for s: WorkoutSession) -> String {
        if s.kind == .lift {
            let totalSets = s.loggedExercises.reduce(0) { $0 + $1.sets.filter { ($0.weightKg > 0 || $0.reps > 0) }.count }
            return "\(s.loggedExercises.count) exercises · \(totalSets) sets" + (s.durationMin.map { " · \($0) min" } ?? "")
        } else if let lc = s.loggedCardio {
            var parts = ["\(lc.durationMin) min"]
            if let km = lc.distanceKm { parts.append(String(format: "%.1f km", km)) }
            if let hr = lc.avgHR { parts.append("\(hr) bpm") }
            return parts.joined(separator: " · ")
        }
        return ""
    }

    private func monthGrid() -> [Date?] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: monthAnchor),
              let first = cal.date(from: cal.dateComponents([.year, .month], from: monthAnchor)) else { return [] }
        let leading = cal.component(.weekday, from: first) - 1
        var cells: [Date?] = Array(repeating: nil, count: leading)
        for d in range {
            if let date = cal.date(byAdding: .day, value: d - 1, to: first) {
                cells.append(date)
            }
        }
        while cells.count % 7 != 0 { cells.append(nil) }
        return cells
    }

    private func kindsOn(day: Date) -> Set<WorkoutKind> {
        let cal = Calendar.current
        var kinds: Set<WorkoutKind> = []
        for s in sessions {
            if cal.isDate(s.startedAt, inSameDayAs: day) {
                kinds.insert(s.kind)
            }
        }
        return kinds
    }

    private func sessionsOn(day: Date) -> [WorkoutSession] {
        let cal = Calendar.current
        return sessions.filter { cal.isDate($0.startedAt, inSameDayAs: day) }
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}

extension Binding where Value == Optional<Date> {
    func identifiableBinding() -> Binding<IdentifiableDate?> {
        Binding<IdentifiableDate?>(
            get: { wrappedValue.map { IdentifiableDate(date: $0) } },
            set: { wrappedValue = $0?.date }
        )
    }
}

struct IdentifiableDate: Identifiable {
    let date: Date
    var id: Date { date }
}

private struct DaySessionsSheet: View {
    let day: IdentifiableDate
    let sessions: [WorkoutSession]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Color.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: Theme.Spacing.m) {
                        ForEach(sessions) { session in
                            NavigationLink {
                                SessionDetailView(session: session)
                            } label: {
                                Card {
                                    HStack {
                                        Image(systemName: session.kind == .lift ? "dumbbell.fill" : "heart.fill")
                                            .foregroundStyle(Theme.Color.accent)
                                        Text(session.sourceTemplateName ?? (session.kind == .lift ? "Lift" : "Cardio"))
                                            .foregroundStyle(Theme.Color.textPrimary)
                                            .font(Theme.Font.body(15, weight: .semibold))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(Theme.Color.textTertiary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Theme.Spacing.l)
                }
            }
            .navigationTitle(day.date.formatted(date: .long, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(Theme.Color.accent)
                }
            }
            .toolbarBackground(Theme.Color.background, for: .navigationBar)
        }
    }
}
