import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\WorkoutTemplate.orderIndex), SortDescriptor(\WorkoutTemplate.createdAt)])
    private var liftTemplates: [WorkoutTemplate]
    @Query(sort: [SortDescriptor(\CardioTemplate.createdAt)])
    private var cardioTemplates: [CardioTemplate]

    @State private var showingNewLift = false
    @State private var showingNewCardio = false

    var body: some View {
        ScreenScaffold(
            title: "Today",
            trailing: AnyView(
                Menu {
                    Button {
                        showingNewLift = true
                    } label: {
                        Label("New Lift Template", systemImage: "dumbbell.fill")
                    }
                    Button {
                        showingNewCardio = true
                    } label: {
                        Label("New Cardio Template", systemImage: "heart.fill")
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Theme.Color.accent)
                }
            )
        ) {
            if liftTemplates.isEmpty && cardioTemplates.isEmpty {
                Card {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Text("No templates yet")
                            .font(Theme.Font.body(17, weight: .semibold))
                            .foregroundStyle(Theme.Color.textPrimary)
                        Text("Tap + to create your first lift or cardio template.")
                            .font(Theme.Font.body(14))
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                }
            }

            if !liftTemplates.isEmpty {
                section("Lift Templates") {
                    ForEach(liftTemplates) { template in
                        NavigationLink {
                            LiftTemplateEditorView(template: template)
                        } label: {
                            templateRow(
                                name: template.name,
                                subtitle: "\(template.exercises.count) exercises",
                                systemImage: "dumbbell.fill"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !cardioTemplates.isEmpty {
                section("Cardio Templates") {
                    ForEach(cardioTemplates) { template in
                        NavigationLink {
                            CardioTemplateEditorView(template: template)
                        } label: {
                            templateRow(
                                name: template.name,
                                subtitle: cardioSubtitle(template),
                                systemImage: template.type.systemImage
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewLift) {
            NavigationStack {
                LiftTemplateEditorView(template: nil)
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingNewCardio) {
            NavigationStack {
                CardioTemplateEditorView(template: nil)
            }
            .preferredColorScheme(.dark)
        }
    }

    private func cardioSubtitle(_ t: CardioTemplate) -> String {
        var parts: [String] = [t.intensity.display]
        if let mins = t.plannedDurationMin { parts.append("\(mins) min") }
        if let km = t.plannedDistanceKm { parts.append(String(format: "%.1f km", km)) }
        return parts.joined(separator: " · ")
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(title.uppercased())
                .font(Theme.Font.sectionHeader)
                .foregroundStyle(Theme.Color.textTertiary)
                .padding(.leading, Theme.Spacing.xs)
            content()
        }
    }

    private func templateRow(name: String, subtitle: String, systemImage: String) -> some View {
        Card {
            HStack(spacing: Theme.Spacing.m) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.Color.accent)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(Theme.Font.body(16, weight: .semibold))
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text(subtitle)
                        .font(Theme.Font.body(13))
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Color.textTertiary)
            }
        }
    }
}
