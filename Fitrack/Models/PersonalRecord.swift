import Foundation
import SwiftData

@Model
final class PersonalRecord {
    @Attribute(.unique) var id: UUID
    var repBucket: Int
    var weightKg: Double
    var achievedAt: Date
    var sessionId: UUID?
    var updatedAt: Date

    var exercise: Exercise?

    init(
        id: UUID = UUID(),
        exercise: Exercise,
        repBucket: Int,
        weightKg: Double,
        achievedAt: Date = .now,
        sessionId: UUID? = nil,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.exercise = exercise
        self.repBucket = repBucket
        self.weightKg = weightKg
        self.achievedAt = achievedAt
        self.sessionId = sessionId
        self.updatedAt = updatedAt
    }
}
