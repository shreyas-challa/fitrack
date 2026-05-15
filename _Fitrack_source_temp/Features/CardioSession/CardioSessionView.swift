import SwiftUI
import SwiftData

struct CardioSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let template: CardioTemplate

    @State private var session: WorkoutSession
    @State private var logged: LoggedCardio
    @State private var durationText: String
    @State private var distanceText: String
    @State private var hrText: String
    @State private var rpe: Int
    @State private var notes: String
    @State private var intervalSpecText: String
    @State private var startedTimer = false
    @State private var elapsed: TimeInterval = 0
    @State private var elapsedTimerCancellable: Any?
    @State private var showingCancelConfirm = false
    @State private var showingFinishConfirm = false

    init(template: CardioTemplate) {
        self.template = template
        let newSession = WorkoutSession(
            kind: .cardio,
            sourceTemplateId: template.id,
            sourceTemplateName: template.name
        )
        _session = State(initialValue: newSession)
        let initialLogged = LoggedCardio(
            type: template.type,
            intensity: template.intensity,
            durationMin: template.plannedDurationMin ?? 0,
            distanceKm: template.plannedDistanceKm,
            avgHR: nil,
            rpe: 5,
            notes: nil,
            intervalsJSON: template.intervalSpec,
            sourceTemplateId: template.id,
            sourceTemplateName: template.name
        )
        _logged = State(initialValue: initialLogged)
        _durationText = State(initialValue: template.plannedDurationMin.map { "\($0)" } ?? "")
        _distanceText = State(initialValue: template.plannedDistanceKm.map { String(format: "%.1f", $0) } ?? "")
        _hrText = State(initialValue: "")
        _rpe = State(initialValue: 5)
        _notes = State(initialValue: "")
        _intervalSpecText = State(initialValue: template.intervalSpec ?? "")
    }

    var body: some View {
        ZStack {
            Theme.Color.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    headerCard
                    timerCard
                    inputsCard
                    rpeCard
                    if template.intensity == .intervals {
                        intervalCard
                    }
                    notesCard
                    finishButton
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.xxl)
            }
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { showingCancelConfirm = true }
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
        .toolbarBackground(Theme.Color.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear { startElapsedTimer() }
        .onDisappear { stopElapsedTimer() }
        .confirmationDialog(
            "Discard this session?",
            isPresented: $showingCancelConfirm,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) { discardSession() }
            Button("Keep going", role: .cancel) {}
        }
        .confirmationDialog(
            "Finish session?",
            isPresented: $showingFinishConfirm,
            titleVisibility: .visible
        ) {
            Button("Finish") { finishSession() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var headerCard: some View {
        Card {
            HStack(spacing: Theme.Spacing.m) {
                Image(systemName: template.type.systemImage)
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.Color.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.type.display)
                        .font(Theme.Font.body(17, weight: .semibold))
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text(template.intensity.display)
                        .font(Theme.Font.body(12))
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                Spacer()
            }
        }
    }

    private var timerCard: some View {
        Card(elevated: true) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text("ELAPSED")
                    .font(Theme.Font.sectionHeader)
                    .foregroundStyle(Theme.Color.textTertiary)
                Text(formattedElapsed)
                    .font(Theme.Font.numeric(40, weight: .bold))
                    .foregroundStyle(Theme.Color.textPrimary)
                    .monospacedDigit()
                Text("Auto-fills duration when you finish. Override below if you want.")
                    .font(Theme.Font.body(11))
                    .foregroundStyle(Theme.Color.textTertiary)
            }
        }
    }

    private var inputsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                fieldRow(label: "Duration", trailing: {
                    AnyView(
                        HStack(spacing: 4) {
                            TextField("min", text: $durationText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 70)
                                .font(Theme.Font.numeric(17, weight: .semibold))
                                .foregroundStyle(Theme.Color.textPrimary)
                            Text("min")
                                .font(Theme.Font.body(13))
                                .foregroundStyle(Theme.Color.textSecondary)
                        }
                    )
                })

                Divider().background(Theme.Color.border)

                fieldRow(label: "Distance", trailing: {
                    AnyView(
                        HStack(spacing: 4) {
                            TextField("optional", text: $distanceText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 80)
                                .font(Theme.Font.numeric(17, weight: .semibold))
                                .foregroundStyle(Theme.Color.textPrimary)
                            Text("km")
                                .font(Theme.Font.body(13))
                                .foregroundStyle(Theme.Color.textSecondary)
                        }
                    )
                })

                Divider().background(Theme.Color.border)

                fieldRow(label: "Avg HR", trailing: {
                    AnyView(
                        HStack(spacing: 4) {
                            TextField("optional", text: $hrText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: 70)
                                .font(Theme.Font.numeric(17, weight: .semibold))
                                .foregroundStyle(Theme.Color.textPrimary)
                            Text("bpm")
                                .font(Theme.Font.body(13))
                                .foregroundStyle(Theme.Color.textSecondary)
                        }
                    )
                })
            }
        }
    }

    private func fieldRow(label: String, @ViewBuilder trailing: () -> AnyView) -> some View {
        HStack {
            Text(label)
                .font(Theme.Font.body(15))
                .foregroundStyle(Theme.Color.textSecondary)
            Spacer()
            trailing()
        }
    }

    private var rpeCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                HStack {
                    Text("RPE")
                        .font(Theme.Font.body(15))
                        .foregroundStyle(Theme.Color.textSecondary)
                    Spacer()
                    Text("\(rpe) / 10")
                        .font(Theme.Font.numeric(17, weight: .semibold))
                        .foregroundStyle(Theme.Color.accent)
                }
                HStack(spacing: 4) {
                    ForEach(1...10, id: \.self) { v in
                        Button { rpe = v } label: {
                            Text("\(v)")
                                .font(Theme.Font.numeric(13, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(rpe == v ? Theme.Color.accent : Theme.Color.surfaceElevated)
                                .foregroundStyle(rpe == v ? Theme.Color.background : Theme.Color.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var intervalCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text("Interval spec")
                    .font(Theme.Font.body(13, weight: .semibold))
                    .foregroundStyle(Theme.Color.textSecondary)
                TextField("e.g. 4x4min @ hard / 3min rest", text: $intervalSpecText, axis: .vertical)
                    .lineLimit(2...4)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .padding(Theme.Spacing.s)
                    .background(Theme.Color.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous))
            }
        }
    }

    private var notesCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text("Notes")
                    .font(Theme.Font.body(13, weight: .semibold))
                    .foregroundStyle(Theme.Color.textSecondary)
                TextField("Optional", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .padding(Theme.Spacing.s)
                    .background(Theme.Color.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous))
            }
        }
    }

    private var finishButton: some View {
        PrimaryButton(title: "Finish Session", systemImage: "checkmark") {
            showingFinishConfirm = true
        }
    }

    private var formattedElapsed: String {
        let total = Int(elapsed)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }

    private func startElapsedTimer() {
        guard !startedTimer else { return }
        startedTimer = true
        let start = session.startedAt
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsed = Date().timeIntervalSince(start)
        }
        elapsedTimerCancellable = timer
    }

    private func stopElapsedTimer() {
        (elapsedTimerCancellable as? Timer)?.invalidate()
    }

    private func finishSession() {
        context.insert(session)
        context.insert(logged)
        logged.session = session

        let parsedDuration = Int(durationText) ?? max(1, Int(elapsed / 60))
        logged.durationMin = parsedDuration
        if let d = Double(distanceText.replacingOccurrences(of: ",", with: ".")), d > 0 {
            logged.distanceKm = d
        } else {
            logged.distanceKm = nil
        }
        if let hr = Int(hrText), hr > 0 {
            logged.avgHR = hr
        } else {
            logged.avgHR = nil
        }
        logged.rpe = rpe
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)
        logged.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        let trimmedSpec = intervalSpecText.trimmingCharacters(in: .whitespaces)
        logged.intervalsJSON = trimmedSpec.isEmpty ? nil : trimmedSpec
        logged.updatedAt = .now

        session.endedAt = .now
        session.updatedAt = .now
        try? context.save()
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
        dismiss()
    }

    private func discardSession() {
        dismiss()
    }
}
