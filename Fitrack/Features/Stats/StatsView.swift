import SwiftUI

struct StatsView: View {
    var body: some View {
        ScreenScaffold(title: "Stats") {
            Card {
                Text("Progression graphs, weekly volume, PRs, and streak arrive in M6.")
                    .font(Theme.Font.body(14))
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
    }
}
