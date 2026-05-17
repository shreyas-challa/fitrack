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
    @State private var editingLift: WorkoutTemplate?
    @State private var editingCardio: CardioTemplate?
    @State private var startingLift: WorkoutTemplate?
    @State private var startingCardio: CardioTemplate?

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
                emptyState
            }

            if !liftTemplates.isEmpty {
                section("Lift Templates") {
                    ForEach(liftTemplates) { template in
                        Card {
                            HStack(spacing: Theme.Spacing.m) {
                                Button { startingLift = template } label: {
                                    HStack(spacing: Theme.Spacing.m) {
                                        Image(systemName: "dumbbell.fill")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(Theme.Color.accent)
                                            .frame(width: 32)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(template.name)
                                                .font(Theme.Font.body(16, weight: .semibold))
                                                .foregroundStyle(Theme.Color.textPrimary)
                                            Text("\(template.exercises.count) exercises")
                                                .font(Theme.Font.body(13))
                                                .foregroundStyle(Theme.Color.textSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Theme.Color.textTertiary)
                                    }
                                }
                                .buttonStyle(.plain)

                                Menu {
                                    Button { editingLift = template } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        context.delete(template)
                                        try? context.save()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Theme.Color.textTertiary)
                                        .padding(.vertical, 8)
                                        .padding(.leading, Theme.Spacing.s)
                                }
                            }
                        }
                    }
                }
            }

            if !cardioTemplates.isEmpty {
                section("Cardio Templates") {
                    ForEach(cardioTemplates) { template in
                        Card {
                            HStack(spacing: Theme.Spacing.m) {
                                Button { startingCardio = template } label: {
                                    HStack(spacing: Theme.Spacing.m) {
                                        Image(systemName: template.type.systemImage)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(Theme.Color.accent)
                                            .frame(width: 32)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(template.name)
                                                .font(Theme.Font.body(16, weight: .semibold))
                                                .foregroundStyle(Theme.Color.textPrimary)
                                            Text(cardioSubtitle(template))
                                                .font(Theme.Font.body(13))
                                                .foregroundStyle(Theme.Color.textSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Theme.Color.textTertiary)
                                    }
                                }
                                .buttonStyle(.plain)

                                Menu {
                                    Button { editingCardio = template } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        context.delete(template)
                                        try? context.save()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(Theme.Color.textTertiary)
                                        .padding(.vertical, 8)
                                        .padding(.leading, Theme.Spacing.s)
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewLift) {
            NavigationStack { LiftTemplateEditorView(template: nil) }
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingNewCardio) {
            NavigationStack { CardioTemplateEditorView(template: nil) }
                .preferredColorScheme(.dark)
        }
        .sheet(item: $editingLift) { tpl in
            NavigationStack { LiftTemplateEditorView(template: tpl) }
                .preferredColorScheme(.dark)
        }
        .sheet(item: $editingCardio) { tpl in
            NavigationStack { CardioTemplateEditorView(template: tpl) }
                .preferredColorScheme(.dark)
        }
        .fullScreenCover(item: $startingLift) { tpl in
            NavigationStack { LiftSessionView(template: tpl) }
                .preferredColorScheme(.dark)
        }
        .fullScreenCover(item: $startingCardio) { tpl in
            NavigationStack { CardioSessionView(template: tpl) }
                .preferredColorScheme(.dark)
        }
    }

    private var emptyState: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text("No templates yet")
                    .font(Theme.Font.body(17, weight: .semibold))
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("Tap + to create your first lift or cardio template, then tap any template to start a session.")
                    .font(Theme.Font.body(14))
                    .foregroundStyle(Theme.Color.textSecondary)
            }
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


}
