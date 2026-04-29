import Foundation

struct UserProfile: Codable {
    var totalPoints: Int
    var currentStreak: Int
    var longestStreak: Int
    /// The calendar day (midnight) of the most recent task completion.
    var lastCompletionDay: Date?

    var totalTasksCompleted: Int
    var hardTasksCompleted: Int
    var epicTasksCompleted: Int

    /// key: "yyyy-MM-dd"  value: tasks completed that day
    var dailyStats: [String: Int]
    /// key: "yyyy-Www"    value: tasks completed that ISO week
    var weeklyStats: [String: Int]
    /// key: "yyyy-MM"     value: tasks completed that month
    var monthlyStats: [String: Int]
    /// key: "yyyy"        value: tasks completed that year
    var yearlyStats: [String: Int]

    var earnedBadges: [EarnedBadge]

    init() {
        totalPoints = 0
        currentStreak = 0
        longestStreak = 0
        lastCompletionDay = nil
        totalTasksCompleted = 0
        hardTasksCompleted = 0
        epicTasksCompleted = 0
        dailyStats = [:]
        weeklyStats = [:]
        monthlyStats = [:]
        yearlyStats = [:]
        earnedBadges = []
    }

    // MARK: - Computed

    var earnedBadgeIDs: Set<BadgeID> {
        Set(earnedBadges.map(\.id))
    }

    /// Total points earned from badge bonuses.
    var badgeBonusPoints: Int {
        earnedBadges
            .compactMap { BadgeDefinition.catalog[$0.id]?.bonusPoints }
            .reduce(0, +)
    }

    // MARK: - Stat helpers

    func tasksCompleted(on day: Date) -> Int {
        dailyStats[Self.dailyKey(for: day)] ?? 0
    }

    func tasksCompleted(inWeekOf date: Date) -> Int {
        weeklyStats[Self.weeklyKey(for: date)] ?? 0
    }

    func tasksCompleted(inMonthOf date: Date) -> Int {
        monthlyStats[Self.monthlyKey(for: date)] ?? 0
    }

    func tasksCompleted(inYearOf date: Date) -> Int {
        yearlyStats[Self.yearlyKey(for: date)] ?? 0
    }

    // MARK: - Key builders

    static func dailyKey(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }

    static func weeklyKey(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-'W'ww"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.string(from: date)
    }

    static func monthlyKey(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM"
        return fmt.string(from: date)
    }

    static func yearlyKey(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy"
        return fmt.string(from: date)
    }
}
