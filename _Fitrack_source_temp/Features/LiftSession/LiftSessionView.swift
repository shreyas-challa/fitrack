import SwiftUI
import SwiftData

struct LiftSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let template: WorkoutTemplate

    @State private var session: WorkoutSession
    @State private var loggedExercises: [LoggedExercise] = []
    @State private var restTimer = RestTimer()
    @State private var currentRestTotal: Int = 120
    @State private var elapsed: TimeInterval = 0
    @State private var elapsedTimerCancellable: Any?
    @State private var showingFinishConfirm = false
    @State private var showingCancelConfirm = false

    init(template: WorkoutTemplate) {
        self.template = template
        _session = State(initialValue: WorkoutSession(
            kind: .lift,
            sourceTemplateId: template.id,
            sourceTemplateName: template.name
        ))
    }

    var body: some View {
        ZStack {
            Theme.Color.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    header
                    ForEach(loggedExercises) { logged in
                        ExerciseLogCard(
                            loggedExercise: logged,
                            onCompleteSet: { restSec in
                                currentRestTotal = restSec
                                restTimer.start(seconds: restSec)
                                #if canImport(UIKit)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                #endif
                            }
                        )
                    }

                    finishButton
                        .padding(.top, Theme.Spacing.m)
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, 120)
            }

            VStack {
                Spacer()
                RestTimerBar(timer: restTimer, totalSec: currentRestTotal)
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.bottom, Theme.Spacing.l)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: restTimer.isRunning)
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
            ToolbarItem(placement: .principal) {
                Text(formattedElapsed)
                    .font(Theme.Font.numeric(15, weight: .semibold))
                    .foregroundStyle(Theme.Color.textPrimary)
                    .monospacedDigit()
            }
        }
        .toolbarBackground(Theme.Color.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear { setupSession() }
        .onDisappear { stopElapsedTimer() }
        .confirmationDialog(
            "Finish workout?",
            isPresented: $showingFinishConfirm,
            titleVisibility: .visible
        ) {
            Button("Finish") { finishSession() }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Discard this workout?",
            isPresented: $showingCancelConfirm,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) { discardSession() }
            Button("Keep going", role: .cancel) {}
        }
    }

    private var header: some View {
        Card {
            HStack(spacing: Theme.Spacing.m) {
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(Theme.Color.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(Theme.Font.body(17, weight: .semibold))
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text("\(template.exercises.count) exercises planned")
                        .font(Theme.Font.body(12))
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                Spacer()
            }
        }
    }

    private var finishButton: some View {
        PrimaryButton(title: "Finish Workout", systemImage: "checkmark") {
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
            return String(format: "%d:%02d", m, s)
        }
    }

    private func setupSession() {
        guard loggedExercises.isEmpty else { return }
        context.insert(session)
        let sorted = template.exercises.sorted { $0.orderIndex < $1.orderIndex }
        for (i, item) in sorted.enumerated() {
            guard let ex = item.exercise else { continue }
            let logged = LoggedExercise(exercise: ex, orderIndex: i)
            logged.session = session
            context.insert(logged)
            for setIdx in 0..<item.targetSets {
                let set = LoggedSet(
                    orderIndex: setIdx,
                    weightKg: 0,
                    reps: 0,
                    restAfterSec: item.targetRestSec
                )
                set.loggedExercise = logged
                context.insert(set)
                logged.sets.append(set)
            }
            loggedExercises.append(logged)
        }
        try? context.save()
        startElapsedTimer()
    }

    private func startElapsedTimer() {
        let start = session.startedAt
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsed = Date().timeIntervalSince(start)
        }
        elapsedTimerCancellable = timer
        elapsed = Date().timeIntervalSince(start)
    }

    private func stopElapsedTimer() {
        (elapsedTimerCancellable as? Timer)?.invalidate()
    }

    private func finishSession() {
        for logged in loggedExercises {
            logged.sets.removeAll { !$0.isCompleted }
        }
        loggedExercises.removeAll { $0.sets.isEmpty }
        for (i, logged) in loggedExercises.enumerated() {
            logged.orderIndex = i
        }
        session.endedAt = .now
        session.updatedAt = .now
        PRDetector.detectAndPersist(for: session, context: context)
        try? context.save()
        restTimer.stop()
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
        dismiss()
    }

    private func discardSession() {
        for logged in loggedExercises {
            for set in logged.sets { context.delete(set) }
            context.delete(logged)
        }
        context.delete(session)
        try? context.save()
        restTimer.stop()
        dismiss()
    }
}

private extension LoggedSet {
    var isCompleted: Bool { weightKg > 0 || reps > 0 }
}
