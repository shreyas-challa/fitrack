import Foundation
import SwiftData

enum WorkoutKind: String, Codable {
    case lift, cardio
}

@Model
final class WorkoutTemplate: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var notes: String?
    var orderIndex: Int
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var exercises: [TemplateExercise] = []

    init(
        id: UUID = UUID(),
        name: String,
        notes: String? = nil,
        orderIndex: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.orderIndex = orderIndex
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
