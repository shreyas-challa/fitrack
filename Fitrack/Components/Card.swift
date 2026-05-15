import SwiftUI

struct Card<Content: View>: View {
    var padding: CGFloat = Theme.Spacing.l
    var elevated: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(elevated ? Theme.Color.surfaceElevated : Theme.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .stroke(Theme.Color.border, lineWidth: 0.5)
            )
    }
}
