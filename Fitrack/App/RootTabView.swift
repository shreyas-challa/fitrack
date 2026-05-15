import SwiftUI

struct RootTabView: View {
    @State private var selection: Tab = .today

    enum Tab: Hashable {
        case today, history, stats, settings
    }

    var body: some View {
        TabView(selection: $selection) {
            TodayView()
                .tabItem { Label("Today", systemImage: "dumbbell.fill") }
                .tag(Tab.today)

            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
                .tag(Tab.history)

            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(Tab.stats)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .background(Theme.Color.background.ignoresSafeArea())
        .tint(Theme.Color.accent)
    }
}

#Preview {
    RootTabView()
        .preferredColorScheme(.dark)
}
