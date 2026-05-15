import Foundation
import SwiftData

@Model
final class WorkoutSession: Identifiable {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var endedAt: Date?
    var kindRaw: String
    var sourceTemplateId: UUID?
    var sourceTemplateName: String?
    var notes: String?
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \LoggedExercise.session)
    var loggedExercises: [LoggedExercise] = []

    @Relationship(deleteRule: .cascade, inverse: \LoggedCardio.session)
    var loggedCardio: LoggedCardio?

    init(
        id: UUID = UUID(),
        startedAt: Date = .now,
        endedAt: Date? = nil,
        kind: WorkoutKind,
        sourceTemplateId: UUID? = nil,
        sourceTemplateName: String? = nil,
        notes: String? = nil,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.kindRaw = kind.rawValue
        self.sourceTemplateId = sourceTemplateId
        self.sourceTemplateName = sourceTemplateName
        self.notes = notes
        self.updatedAt = updatedAt
    }

    var kind: WorkoutKind {
        get { WorkoutKind(rawValue: kindRaw) ?? .lift }
        set { kindRaw = newValue.rawValue }
    }

    var durationMin: Int? {
        guard let endedAt else { return nil }
        return Int(endedAt.timeIntervalSince(startedAt) / 60)
    }
}
