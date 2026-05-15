import SwiftUI

struct ScreenScaffold<Content: View>: View {
    let title: String
    var trailing: AnyView? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Color.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                        content()
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.vertical, Theme.Spacing.m)
                }
            }
            .navigationTitle(title)
            .toolbarBackground(Theme.Color.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                if let trailing {
                    ToolbarItem(placement: .topBarTrailing) { trailing }
                }
            }
        }
    }
}
