import SwiftUI

struct SettingsView: View {
    var body: some View {
        ScreenScaffold(title: "Settings") {
            Card {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text("Fitrack")
                        .font(Theme.Font.body(17, weight: .semibold))
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text("Personal workout tracker")
                        .font(Theme.Font.body(13))
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
            Card {
                Text("Export and template management land in later milestones.")
                    .font(Theme.Font.body(14))
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
    }
}
