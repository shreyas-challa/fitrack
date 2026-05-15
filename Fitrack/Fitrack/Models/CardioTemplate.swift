import Foundation
import SwiftData

enum CardioType: String, Codable, CaseIterable {
    case run, bike, row, walk, elliptical, stair, swim, other
    var display: String { rawValue.capitalized }
    var systemImage: String {
        switch self {
        case .run: return "figure.run"
        case .bike: return "bicycle"
        case .row: return "figure.rower"
        case .walk: return "figure.walk"
        case .elliptical: return "figure.elliptical"
        case .stair: return "figure.stairs"
        case .swim: return "figure.pool.swim"
        case .other: return "heart.fill"
        }
    }
}

enum CardioIntensity: String, Codable, CaseIterable {
    case zone2, intervals, tempo, recovery
    var display: String {
        switch self {
        case .zone2: return "Zone 2"
        case .intervals: return "Intervals"
        case .tempo: return "Tempo"
        case .recovery: return "Recovery"
        }
    }
}

@Model
final class CardioTemplate: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var typeRaw: String
    var intensityRaw: String
    var plannedDurationMin: Int?
    var plannedDistanceKm: Double?
    var intervalSpec: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        type: CardioType,
        intensity: CardioIntensity,
        plannedDurationMin: Int? = nil,
        plannedDistanceKm: Double? = nil,
        intervalSpec: String? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.typeRaw = type.rawValue
        self.intensityRaw = intensity.rawValue
        self.plannedDurationMin = plannedDurationMin
        self.plannedDistanceKm = plannedDistanceKm
        self.intervalSpec = intervalSpec
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var type: CardioType {
        get { CardioType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    var intensity: CardioIntensity {
        get { CardioIntensity(rawValue: intensityRaw) ?? .zone2 }
        set { intensityRaw = newValue.rawValue }
    }
}
