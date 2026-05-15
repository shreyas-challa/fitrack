import SwiftUI
import SwiftData

@main
struct FitrackApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(.dark)
                .tint(Theme.Color.accent)
        }
        .modelContainer(FitrackModelContainer.shared)
    }
}
