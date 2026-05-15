import Foundation
import SwiftData

enum SeedData {
    private struct SeedEntry: Decodable {
        let name: String
        let primary: String
        let secondary: [String]
        let equipment: String
    }

    static func seedIfNeeded(container: ModelContainer) {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Exercise>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        guard let url = Bundle.main.url(forResource: "seed_exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("[SeedData] seed_exercises.json not found in bundle — skipping seed")
            return
        }

        do {
            let entries = try JSONDecoder().decode([SeedEntry].self, from: data)
            for entry in entries {
                let primary = MuscleGroup(rawValue: entry.primary) ?? .fullBody
                let secondary = entry.secondary.compactMap { MuscleGroup(rawValue: $0) }
                let equipment = Equipment(rawValue: entry.equipment) ?? .other
                let exercise = Exercise(
                    name: entry.name,
                    primaryMuscle: primary,
                    secondaryMuscles: secondary,
                    equipment: equipment,
                    isCustom: false
                )
                context.insert(exercise)
            }
            try context.save()
            print("[SeedData] seeded \(entries.count) exercises")
        } catch {
            print("[SeedData] failed to seed: \(error)")
        }
    }
}
