import Foundation
import SwiftData

@Model
final class TemplateExercise {
    @Attribute(.unique) var id: UUID
    var orderIndex: Int
    var targetSets: Int
    var targetRepsLow: Int
    var targetRepsHigh: Int
    var targetRestSec: Int
    var updatedAt: Date

    var template: WorkoutTemplate?
    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        exercise: Exercise,
        orderIndex: Int,
        targetSets: Int = 3,
        targetRepsLow: Int = 8,
        targetRepsHigh: Int = 12,
        targetRestSec: Int = 120,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.exercise = exercise
        self.orderIndex = orderIndex
        self.targetSets = targetSets
        self.targetRepsLow = targetRepsLow
        self.targetRepsHigh = targetRepsHigh
        self.targetRestSec = targetRestSec
        self.updatedAt = updatedAt
    }
}
