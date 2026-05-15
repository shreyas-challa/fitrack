import Foundation
import SwiftData

@Model
final class LoggedCardio {
    @Attribute(.unique) var id: UUID
    var typeRaw: String
    var intensityRaw: String
    var durationMin: Int
    var distanceKm: Double?
    var avgHR: Int?
    var rpe: Int
    var notes: String?
    var intervalsJSON: String?
    var sourceTemplateId: UUID?
    var sourceTemplateName: String?
    var updatedAt: Date

    var session: WorkoutSession?

    init(
        id: UUID = UUID(),
        type: CardioType,
        intensity: CardioIntensity,
        durationMin: Int,
        distanceKm: Double? = nil,
        avgHR: Int? = nil,
        rpe: Int = 5,
        notes: String? = nil,
        intervalsJSON: String? = nil,
        sourceTemplateId: UUID? = nil,
        sourceTemplateName: String? = nil,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.intensityRaw = intensity.rawValue
        self.durationMin = durationMin
        self.distanceKm = distanceKm
        self.avgHR = avgHR
        self.rpe = rpe
        self.notes = notes
        self.intervalsJSON = intervalsJSON
        self.sourceTemplateId = sourceTemplateId
        self.sourceTemplateName = sourceTemplateName
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
