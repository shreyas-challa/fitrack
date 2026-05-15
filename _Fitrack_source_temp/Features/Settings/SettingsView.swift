import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var exportError: String?

    var body: some View {
        ScreenScaffold(title: "Settings") {
            aboutCard
            dataCard
            footer
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ShareSheet(items: [url])
                    .preferredColorScheme(.dark)
            }
        }
        .alert("Export failed", isPresented: Binding(
            get: { exportError != nil },
            set: { if !$0 { exportError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "")
        }
    }

    private var aboutCard: some View {
        Card(elevated: true) {
            HStack(spacing: Theme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.Color.accent.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.Color.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Fitrack")
                        .font(Theme.Font.body(18, weight: .bold))
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text("Personal workout tracker · v1.0")
                        .font(Theme.Font.body(12))
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
        }
    }

    private var dataCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                Text("DATA")
                    .font(Theme.Font.sectionHeader)
                    .foregroundStyle(Theme.Color.textTertiary)
                Button {
                    exportData()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(Theme.Color.accent)
                        Text("Export to JSON")
                            .foregroundStyle(Theme.Color.textPrimary)
                            .font(Theme.Font.body(15, weight: .medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Theme.Color.textTertiary)
                    }
                }
                .buttonStyle(.plain)
                Text("Save a complete snapshot of templates, sessions, and PRs. Use this for backup or when migrating to a backend later.")
                    .font(Theme.Font.body(12))
                    .foregroundStyle(Theme.Color.textTertiary)
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Text("Built for one user.")
                .font(Theme.Font.body(12))
                .foregroundStyle(Theme.Color.textTertiary)
            Text("Local-first. No accounts, no tracking.")
                .font(Theme.Font.body(11))
                .foregroundStyle(Theme.Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.l)
    }

    private func exportData() {
        do {
            let url = try ExportService.exportJSON(context: context)
            exportURL = url
            showShareSheet = true
        } catch {
            exportError = error.localizedDescription
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
