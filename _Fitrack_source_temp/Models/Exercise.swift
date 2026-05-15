import Foundation
import SwiftData

enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest, back, shoulders, biceps, triceps, forearms
    case quads, hamstrings, glutes, calves
    case core, traps, lats, fullBody
    var id: String { rawValue }

    var display: String {
        switch self {
        case .fullBody: return "Full Body"
        default: return rawValue.capitalized
        }
    }
}

enum Equipment: String, Codable, CaseIterable {
    case barbell, dumbbell, machine, cable, bodyweight, kettlebell, band, other
    var display: String { rawValue.capitalized }
}

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var primaryMuscleRaw: String
    var secondaryMusclesRaw: [String]
    var equipmentRaw: String
    var isCustom: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        primaryMuscle: MuscleGroup,
        secondaryMuscles: [MuscleGroup] = [],
        equipment: Equipment,
        isCustom: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.primaryMuscleRaw = primaryMuscle.rawValue
        self.secondaryMusclesRaw = secondaryMuscles.map(\.rawValue)
        self.equipmentRaw = equipment.rawValue
        self.isCustom = isCustom
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var primaryMuscle: MuscleGroup {
        get { MuscleGroup(rawValue: primaryMuscleRaw) ?? .fullBody }
        set { primaryMuscleRaw = newValue.rawValue }
    }

    var secondaryMuscles: [MuscleGroup] {
        get { secondaryMusclesRaw.compactMap { MuscleGroup(rawValue: $0) } }
        set { secondaryMusclesRaw = newValue.map(\.rawValue) }
    }

    var equipment: Equipment {
        get { Equipment(rawValue: equipmentRaw) ?? .other }
        set { equipmentRaw = newValue.rawValue }
    }
}
