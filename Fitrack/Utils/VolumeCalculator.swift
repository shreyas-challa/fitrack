import Foundation
import SwiftData

enum VolumeCalculator {
    struct MuscleVolume: Identifiable {
        let muscle: MuscleGroup
        let sets: Int
        var id: String { muscle.rawValue }
    }

    /// Working-set count per muscle group across sessions in the last `days`.
    static func weeklyVolume(sessions: [WorkoutSession], days: Int = 7, now: Date = .now) -> [MuscleVolume] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
        var counts: [MuscleGroup: Int] = [:]
        for session in sessions where session.kind == .lift && session.startedAt >= cutoff {
            for le in session.loggedExercises {
                guard let ex = le.exercise else { continue }
                let working = le.sets.filter { !$0.isWarmup && ($0.weightKg > 0 || $0.reps > 0) }.count
                guard working > 0 else { continue }
                counts[ex.primaryMuscle, default: 0] += working
            }
        }
        return counts
            .map { MuscleVolume(muscle: $0.key, sets: $0.value) }
            .sorted { $0.sets > $1.sets }
    }

    static func weeklyCardioMinutes(sessions: [WorkoutSession], days: Int = 7, now: Date = .now) -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
        return sessions
            .filter { $0.kind == .cardio && $0.startedAt >= cutoff }
            .compactMap { $0.loggedCardio?.durationMin }
            .reduce(0, +)
    }
}
