import Foundation
import SwiftData

@Model
final class LoggedSet {
    @Attribute(.unique) var id: UUID
    var orderIndex: Int
    var weightKg: Double
    var reps: Int
    var rpe: Double?
    var restAfterSec: Int?
    var isWarmup: Bool
    var completedAt: Date
    var updatedAt: Date

    var loggedExercise: LoggedExercise?

    init(
        id: UUID = UUID(),
        orderIndex: Int,
        weightKg: Double,
        reps: Int,
        rpe: Double? = nil,
        restAfterSec: Int? = nil,
        isWarmup: Bool = false,
        completedAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.weightKg = weightKg
        self.reps = reps
        self.rpe = rpe
        self.restAfterSec = restAfterSec
        self.isWarmup = isWarmup
        self.completedAt = completedAt
        self.updatedAt = updatedAt
    }

    var volume: Double { weightKg * Double(reps) }
}
