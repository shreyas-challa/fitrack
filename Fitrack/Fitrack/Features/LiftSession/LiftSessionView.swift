import SwiftUI
import SwiftData

struct LiftSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let template: WorkoutTemplate

    @State private var phase: Phase = .setup
    @State private var plannedItems: [TemplateExercise] = []

    @State private var session: WorkoutSession
    @State private var loggedExercises: [LoggedExercise] = []
    @State private var currentPage = 0
    @State private var restTimer = RestTimer()
    @State private var currentRestTotal: Int = 120
    @State private var elapsed: TimeInterval = 0
    @State private var elapsedTimerCancellable: Any?
    @State private var showingFinishConfirm = false
    @State private var showingCancelConfirm = false

    enum Phase { case setup, active }

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
            if phase == .setup {
                setupView
            } else {
                activeView
            }
        }
        .navigationTitle(template.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    if phase == .setup { dismiss() }
                    else { showingCancelConfirm = true }
                }
                .foregroundStyle(Theme.Color.textSecondary)
            }
            if phase == .active {
                ToolbarItem(placement: .principal) {
                    Text(formattedElapsed)
                        .font(Theme.Font.numeric(15, weight: .semibold))
                        .foregroundStyle(Theme.Color.textPrimary)
                        .monospacedDigit()
                }
            }
        }
        .toolbarBackground(Theme.Color.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onDisappear { stopElapsedTimer() }
        .confirmationDialog("Finish workout?", isPresented: $showingFinishConfirm, titleVisibility: .visible) {
            Button("Finish") { finishSession() }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Discard this workout?", isPresented: $showingCancelConfirm, titleVisibility: .visible) {
            Button("Discard", role: .destructive) { discardSession() }
            Button("Keep going", role: .cancel) {}
        }
    }

    // MARK: - Setup

    private var setupView: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    if plannedItems.isEmpty {
                        Text("All exercises removed. Add exercises to the template first.")
                            .font(Theme.Font.body(13))
                            .foregroundStyle(Theme.Color.textSecondary)
                            .listRowBackground(Theme.Color.surface)
                    } else {
                        ForEach(plannedItems) { item in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.exercise?.name ?? "—")
                                    .font(Theme.Font.body(15, weight: .semibold))
                                    .foregroundStyle(Theme.Color.textPrimary)
                                Text("\(item.targetSets) sets · \(item.targetRepsLow)–\(item.targetRepsHigh) reps")
                                    .font(Theme.Font.body(12))
                                    .foregroundStyle(Theme.Color.textSecondary)
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(Theme.Color.surface)
                        }
                        .onMove { from, to in plannedItems.move(fromOffsets: from, toOffset: to) }
                        .onDelete { offsets in plannedItems.remove(atOffsets: offsets) }
                    }
                } header: {
                    Text("Drag to reorder · swipe left to remove")
                        .foregroundStyle(Theme.Color.textTertiary)
                }
            }
            .scrollContentBackground(.hidden)
            .environment(\.editMode, .constant(.active))

            VStack(spacing: Theme.Spacing.s) {
                PrimaryButton(title: "Start Session", systemImage: "play.fill") {
                    startSession()
                }
                .disabled(plannedItems.isEmpty)
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.l)
            }
            .padding(.top, Theme.Spacing.m)
            .background(Theme.Color.background)
        }
        .onAppear {
            if plannedItems.isEmpty {
                plannedItems = template.exercises.sorted { $0.orderIndex < $1.orderIndex }
            }
        }
    }

    // MARK: - Active

    private var activeView: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                progressStrip

                TabView(selection: $currentPage) {
                    ForEach(Array(loggedExercises.enumerated()), id: \.offset) { i, logged in
                        ScrollView {
                            VStack(spacing: Theme.Spacing.l) {
                                ExerciseLogCard(loggedExercise: logged) { restSec in
                                    currentRestTotal = restSec
                                    restTimer.start(seconds: restSec)
                                    #if canImport(UIKit)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    #endif
                                }

                                if i == loggedExercises.count - 1 {
                                    PrimaryButton(title: "Finish Workout", systemImage: "checkmark") {
                                        showingFinishConfirm = true
                                    }
                                } else {
                                    Button {
                                        withAnimation { currentPage = i + 1 }
                                    } label: {
                                        Label("Next Exercise", systemImage: "arrow.right")
                                            .font(Theme.Font.body(15, weight: .semibold))
                                            .foregroundStyle(Theme.Color.accent)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, Theme.Spacing.m)
                                            .background(Theme.Color.surface)
                                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, Theme.Spacing.l)
                            .padding(.bottom, 140)
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            RestTimerBar(timer: restTimer, totalSec: currentRestTotal)
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.bottom, Theme.Spacing.l)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: restTimer.isRunning)
        }
    }

    private var progressStrip: some View {
        HStack {
            Text("Exercise \(currentPage + 1) of \(loggedExercises.count)")
                .font(Theme.Font.body(13, weight: .semibold))
                .foregroundStyle(Theme.Color.textSecondary)
            Spacer()
            HStack(spacing: 5) {
                ForEach(0..<loggedExercises.count, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(i <= currentPage ? Theme.Color.accent : Theme.Color.border)
                        .frame(width: i == currentPage ? 16 : 6, height: 4)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.vertical, Theme.Spacing.m)
    }

    // MARK: - Helpers

    private var formattedElapsed: String {
        let total = Int(elapsed)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    private func startSession() {
        context.insert(session)
        for (i, item) in plannedItems.enumerated() {
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
        withAnimation { phase = .active }
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
