import SwiftUI
import Combine

@Observable
final class RestTimer {
    var remainingSec: Int = 0
    var isRunning: Bool = false
    private var endDate: Date?
    private var cancellable: AnyCancellable?

    func start(seconds: Int) {
        remainingSec = seconds
        endDate = Date().addingTimeInterval(TimeInterval(seconds))
        isRunning = true
        cancellable?.cancel()
        cancellable = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    func stop() {
        isRunning = false
        endDate = nil
        cancellable?.cancel()
        cancellable = nil
        remainingSec = 0
    }

    private func tick() {
        guard let endDate else { return }
        let remaining = Int(endDate.timeIntervalSinceNow.rounded(.up))
        if remaining <= 0 {
            stop()
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
        } else {
            remainingSec = remaining
        }
    }
}

struct RestTimerBar: View {
    let timer: RestTimer
    let totalSec: Int

    var body: some View {
        if timer.isRunning {
            VStack(spacing: Theme.Spacing.s) {
                HStack {
                    Image(systemName: "timer")
                        .foregroundStyle(Theme.Color.accent)
                    Text("Rest")
                        .font(Theme.Font.body(13, weight: .medium))
                        .foregroundStyle(Theme.Color.textSecondary)
                    Spacer()
                    Text(format(timer.remainingSec))
                        .font(Theme.Font.numeric(20, weight: .bold))
                        .foregroundStyle(Theme.Color.textPrimary)
                        .monospacedDigit()
                    Button {
                        timer.stop()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
                ProgressView(value: Double(totalSec - timer.remainingSec), total: Double(totalSec))
                    .tint(Theme.Color.accent)
            }
            .padding(Theme.Spacing.m)
            .background(Theme.Color.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private func format(_ s: Int) -> String {
        String(format: "%d:%02d", s / 60, s % 60)
    }
}
