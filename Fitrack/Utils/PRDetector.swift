import Foundation
import SwiftData

enum PRDetector {
    static let repBuckets = [1, 3, 5, 8, 10]

    /// Scans the just-finished session for new PRs against the persisted PR table,
    /// updates rows in place, and inserts new PR records for any exercise whose
    /// best weight at a rep-bucket improved.
    static func detectAndPersist(for session: WorkoutSession, context: ModelContext) {
        guard session.kind == .lift else { return }

        for logged in session.loggedExercises {
            guard let exercise = logged.exercise else { continue }
            for set in logged.sets where set.weightKg > 0 && set.reps > 0 && !set.isWarmup {
                for bucket in repBuckets where set.reps >= bucket {
                    upgradePR(
                        exercise: exercise,
                        repBucket: bucket,
                        weightKg: set.weightKg,
                        achievedAt: set.completedAt,
                        sessionId: session.id,
                        context: context
                    )
                }
            }
        }
    }

    private static func upgradePR(
        exercise: Exercise,
        repBucket: Int,
        weightKg: Double,
        achievedAt: Date,
        sessionId: UUID,
        context: ModelContext
    ) {
        let exerciseId = exercise.id
        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate { record in
                record.exercise?.id == exerciseId && record.repBucket == repBucket
            }
        )
        let existing = (try? context.fetch(descriptor))?.first
        if let existing {
            if weightKg > existing.weightKg {
                existing.weightKg = weightKg
                existing.achievedAt = achievedAt
                existing.sessionId = sessionId
                existing.updatedAt = .now
            }
        } else {
            let record = PersonalRecord(
                exercise: exercise,
                repBucket: repBucket,
                weightKg: weightKg,
                achievedAt: achievedAt,
                sessionId: sessionId
            )
            context.insert(record)
        }
    }
}
