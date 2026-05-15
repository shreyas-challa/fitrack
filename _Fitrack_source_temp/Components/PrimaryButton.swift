import SwiftUI

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var isProminent: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.s) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).font(Theme.Font.body(16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isProminent ? Theme.Color.accent : Theme.Color.surfaceElevated)
            .foregroundStyle(isProminent ? Theme.Color.background : Theme.Color.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.s) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).font(Theme.Font.body(15, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Theme.Color.surfaceElevated)
            .foregroundStyle(Theme.Color.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                    .stroke(Theme.Color.border, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
