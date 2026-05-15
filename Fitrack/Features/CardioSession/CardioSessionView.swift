import SwiftUI
import SwiftData

// Stub. Full implementation in M4.
struct CardioSessionView: View {
    @Environment(\.dismiss) private var dismiss
    let template: CardioTemplate

    var body: some View {
        ZStack {
            Theme.Color.background.ignoresSafeArea()
            VStack(spacing: Theme.Spacing.l) {
                Text(template.name)
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("Cardio logging UI lands in M4.")
                    .foregroundStyle(Theme.Color.textSecondary)
                PrimaryButton(title: "Close") { dismiss() }
                    .padding(.horizontal, Theme.Spacing.xl)
            }
        }
    }
}
