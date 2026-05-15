import Foundation
import SwiftData

enum SessionHelpers {
    /// Returns the most recent fully-logged session's sets for a given exercise,
    /// sorted by orderIndex. Used to show "last session" hint while logging.
    static func lastSets(for exercise: Exercise, before date: Date = .distantFuture, context: ModelContext) -> [LoggedSet] {
        guard let exerciseId = exercise.id as UUID? else { return [] }
        let descriptor = FetchDescriptor<LoggedExercise>(
            predicate: #Predicate { logged in
                logged.exercise?.id == exerciseId
            },
            sortBy: [SortDescriptor(\.session?.startedAt, order: .reverse)]
        )
        guard let logged = try? context.fetch(descriptor) else { return [] }
        for entry in logged {
            if let started = entry.session?.startedAt, started < date, !entry.sets.isEmpty {
                return entry.sets.sorted { $0.orderIndex < $1.orderIndex }
            }
        }
        return []
    }
}
