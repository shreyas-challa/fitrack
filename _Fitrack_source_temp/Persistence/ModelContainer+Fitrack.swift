import Foundation
import SwiftData

enum FitrackModelContainer {
    static let shared: ModelContainer = {
        do {
            let schema = Schema(FitrackSchema.allModels)
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [config])
            SeedData.seedIfNeeded(container: container)
            return container
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}

enum FitrackSchema {
    static var allModels: [any PersistentModel.Type] {
        [
            Exercise.self,
            WorkoutTemplate.self,
            TemplateExercise.self,
            CardioTemplate.self,
            WorkoutSession.self,
            LoggedExercise.self,
            LoggedSet.self,
            LoggedCardio.self,
            PersonalRecord.self,
        ]
    }
}
