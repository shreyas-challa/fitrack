import SwiftUI

struct HistoryView: View {
    var body: some View {
        ScreenScaffold(title: "History") {
            Card {
                Text("Calendar heatmap and session list arrive in M5.")
                    .font(Theme.Font.body(14))
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
    }
}
