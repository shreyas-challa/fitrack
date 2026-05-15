import SwiftUI

struct TodayView: View {
    var body: some View {
        ScreenScaffold(title: "Today") {
            Card {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text("No workout in progress")
                        .font(Theme.Font.body(17, weight: .semibold))
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text("Pick a template to start a session.")
                        .font(Theme.Font.body(14))
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
            // Template picker will land in M2.
        }
    }
}

#Preview {
    TodayView().preferredColorScheme(.dark)
}
