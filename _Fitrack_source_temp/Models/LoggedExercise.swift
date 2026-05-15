import Foundation
import SwiftData

@Model
final class LoggedExercise {
    @Attribute(.unique) var id: UUID
    var orderIndex: Int
    var updatedAt: Date

    var session: WorkoutSession?
    var exercise: Exercise?

    @Relationship(deleteRule: .cascade, inverse: \LoggedSet.loggedExercise)
    var sets: [LoggedSet] = []

    init(
        id: UUID = UUID(),
        exercise: Exercise,
        orderIndex: Int,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.exercise = exercise
        self.orderIndex = orderIndex
        self.updatedAt = updatedAt
    }
}
