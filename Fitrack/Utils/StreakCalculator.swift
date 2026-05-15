import Foundation

enum StreakCalculator {
    /// Current streak = consecutive days ending today (or yesterday) on which a session occurred.
    /// Longest streak = max consecutive days observed.
    static func compute(sessions: [Date], now: Date = .now) -> (current: Int, longest: Int, thisMonth: Int) {
        let cal = Calendar.current
        let days = Set(sessions.map { cal.startOfDay(for: $0) })
        guard !days.isEmpty else { return (0, 0, 0) }

        // Current: walk back from today
        var current = 0
        var cursor = cal.startOfDay(for: now)
        if days.contains(cursor) {
            while days.contains(cursor) {
                current += 1
                cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
            }
        } else {
            // allow grace: if today wasn't trained but yesterday was, count from yesterday
            cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
            while days.contains(cursor) {
                current += 1
                cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
            }
        }

        // Longest: scan sorted days
        let sorted = days.sorted()
        var longest = 1
        var run = 1
        for i in 1..<sorted.count {
            let prev = sorted[i - 1]
            let day = sorted[i]
            if let next = cal.date(byAdding: .day, value: 1, to: prev), cal.isDate(next, inSameDayAs: day) {
                run += 1
                longest = max(longest, run)
            } else {
                run = 1
            }
        }

        // This month
        let monthStart = cal.startOfMonth(for: now)
        let thisMonth = days.filter { $0 >= monthStart }.count

        return (current, longest, thisMonth)
    }
}
