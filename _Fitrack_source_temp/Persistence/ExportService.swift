import Foundation
import SwiftData

enum ExportService {
    struct ExportPayload: Codable {
        let schemaVersion: Int
        let exportedAt: Date
        let exercises: [ExerciseDTO]
        let liftTemplates: [LiftTemplateDTO]
        let cardioTemplates: [CardioTemplateDTO]
        let sessions: [SessionDTO]
        let personalRecords: [PRDTO]
    }

    struct ExerciseDTO: Codable {
        let id: UUID
        let name: String
        let primaryMuscle: String
        let secondaryMuscles: [String]
        let equipment: String
        let isCustom: Bool
        let createdAt: Date
    }

    struct LiftTemplateDTO: Codable {
        struct Item: Codable {
            let exerciseId: UUID
            let orderIndex: Int
            let targetSets: Int
            let targetRepsLow: Int
            let targetRepsHigh: Int
            let targetRestSec: Int
        }
        let id: UUID
        let name: String
        let notes: String?
        let exercises: [Item]
        let createdAt: Date
    }

    struct CardioTemplateDTO: Codable {
        let id: UUID
        let name: String
        let type: String
        let intensity: String
        let plannedDurationMin: Int?
        let plannedDistanceKm: Double?
        let intervalSpec: String?
        let notes: String?
        let createdAt: Date
    }

    struct SessionDTO: Codable {
        struct LoggedSetDTO: Codable {
            let orderIndex: Int
            let weightKg: Double
            let reps: Int
            let rpe: Double?
            let restAfterSec: Int?
            let isWarmup: Bool
            let completedAt: Date
        }
        struct LoggedExerciseDTO: Codable {
            let exerciseId: UUID
            let orderIndex: Int
            let sets: [LoggedSetDTO]
        }
        struct LoggedCardioDTO: Codable {
            let type: String
            let intensity: String
            let durationMin: Int
            let distanceKm: Double?
            let avgHR: Int?
            let rpe: Int
            let notes: String?
            let intervalsJSON: String?
        }
        let id: UUID
        let startedAt: Date
        let endedAt: Date?
        let kind: String
        let sourceTemplateId: UUID?
        let sourceTemplateName: String?
        let loggedExercises: [LoggedExerciseDTO]
        let loggedCardio: LoggedCardioDTO?
    }

    struct PRDTO: Codable {
        let exerciseId: UUID
        let repBucket: Int
        let weightKg: Double
        let achievedAt: Date
        let sessionId: UUID?
    }

    static func exportJSON(context: ModelContext) throws -> URL {
        let payload = try buildPayload(context: context)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)

        let filename = "fitrack-\(Self.timestamp()).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func buildPayload(context: ModelContext) throws -> ExportPayload {
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        let liftTemplates = try context.fetch(FetchDescriptor<WorkoutTemplate>())
        let cardioTemplates = try context.fetch(FetchDescriptor<CardioTemplate>())
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.startedAt)]))
        let prs = try context.fetch(FetchDescriptor<PersonalRecord>())

        return ExportPayload(
            schemaVersion: 1,
            exportedAt: .now,
            exercises: exercises.map { ex in
                ExerciseDTO(
                    id: ex.id,
                    name: ex.name,
                    primaryMuscle: ex.primaryMuscle.rawValue,
                    secondaryMuscles: ex.secondaryMuscles.map(\.rawValue),
                    equipment: ex.equipment.rawValue,
                    isCustom: ex.isCustom,
                    createdAt: ex.createdAt
                )
            },
            liftTemplates: liftTemplates.map { t in
                LiftTemplateDTO(
                    id: t.id,
                    name: t.name,
                    notes: t.notes,
                    exercises: t.exercises.sorted { $0.orderIndex < $1.orderIndex }.compactMap { te in
                        guard let ex = te.exercise else { return nil }
                        return LiftTemplateDTO.Item(
                            exerciseId: ex.id,
                            orderIndex: te.orderIndex,
                            targetSets: te.targetSets,
                            targetRepsLow: te.targetRepsLow,
                            targetRepsHigh: te.targetRepsHigh,
                            targetRestSec: te.targetRestSec
                        )
                    },
                    createdAt: t.createdAt
                )
            },
            cardioTemplates: cardioTemplates.map { t in
                CardioTemplateDTO(
                    id: t.id,
                    name: t.name,
                    type: t.type.rawValue,
                    intensity: t.intensity.rawValue,
                    plannedDurationMin: t.plannedDurationMin,
                    plannedDistanceKm: t.plannedDistanceKm,
                    intervalSpec: t.intervalSpec,
                    notes: t.notes,
                    createdAt: t.createdAt
                )
            },
            sessions: sessions.map { s in
                SessionDTO(
                    id: s.id,
                    startedAt: s.startedAt,
                    endedAt: s.endedAt,
                    kind: s.kind.rawValue,
                    sourceTemplateId: s.sourceTemplateId,
                    sourceTemplateName: s.sourceTemplateName,
                    loggedExercises: s.loggedExercises.sorted { $0.orderIndex < $1.orderIndex }.compactMap { le in
                        guard let ex = le.exercise else { return nil }
                        return SessionDTO.LoggedExerciseDTO(
                            exerciseId: ex.id,
                            orderIndex: le.orderIndex,
                            sets: le.sets.sorted { $0.orderIndex < $1.orderIndex }.map { set in
                                SessionDTO.LoggedSetDTO(
                                    orderIndex: set.orderIndex,
                                    weightKg: set.weightKg,
                                    reps: set.reps,
                                    rpe: set.rpe,
                                    restAfterSec: set.restAfterSec,
                                    isWarmup: set.isWarmup,
                                    completedAt: set.completedAt
                                )
                            }
                        )
                    },
                    loggedCardio: s.loggedCardio.map { lc in
                        SessionDTO.LoggedCardioDTO(
                            type: lc.type.rawValue,
                            intensity: lc.intensity.rawValue,
                            durationMin: lc.durationMin,
                            distanceKm: lc.distanceKm,
                            avgHR: lc.avgHR,
                            rpe: lc.rpe,
                            notes: lc.notes,
                            intervalsJSON: lc.intervalsJSON
                        )
                    }
                )
            },
            personalRecords: prs.compactMap { pr in
                guard let ex = pr.exercise else { return nil }
                return PRDTO(
                    exerciseId: ex.id,
                    repBucket: pr.repBucket,
                    weightKg: pr.weightKg,
                    achievedAt: pr.achievedAt,
                    sessionId: pr.sessionId
                )
            }
        )
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: .now)
    }
}
