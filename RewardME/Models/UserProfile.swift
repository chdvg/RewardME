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
    /// Total points spent on rewards.
    var spentPoints: Int

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
        spentPoints  = 0
    }

    // MARK: - Migration-safe Codable

    enum CodingKeys: String, CodingKey {
        case totalPoints, currentStreak, longestStreak, lastCompletionDay,
             totalTasksCompleted, hardTasksCompleted, epicTasksCompleted,
             dailyStats, weeklyStats, monthlyStats, yearlyStats, earnedBadges,
             spentPoints
    }

    init(from decoder: Decoder) throws {
        let c               = try decoder.container(keyedBy: CodingKeys.self)
        totalPoints         = try c.decodeIfPresent(Int.self,              forKey: .totalPoints)         ?? 0
        currentStreak       = try c.decodeIfPresent(Int.self,              forKey: .currentStreak)       ?? 0
        longestStreak       = try c.decodeIfPresent(Int.self,              forKey: .longestStreak)       ?? 0
        lastCompletionDay   = try c.decodeIfPresent(Date.self,             forKey: .lastCompletionDay)
        totalTasksCompleted = try c.decodeIfPresent(Int.self,              forKey: .totalTasksCompleted) ?? 0
        hardTasksCompleted  = try c.decodeIfPresent(Int.self,              forKey: .hardTasksCompleted)  ?? 0
        epicTasksCompleted  = try c.decodeIfPresent(Int.self,              forKey: .epicTasksCompleted)  ?? 0
        dailyStats          = try c.decodeIfPresent([String: Int].self,    forKey: .dailyStats)          ?? [:]
        weeklyStats         = try c.decodeIfPresent([String: Int].self,    forKey: .weeklyStats)         ?? [:]
        monthlyStats        = try c.decodeIfPresent([String: Int].self,    forKey: .monthlyStats)        ?? [:]
        yearlyStats         = try c.decodeIfPresent([String: Int].self,    forKey: .yearlyStats)         ?? [:]
        earnedBadges        = try c.decodeIfPresent([EarnedBadge].self,    forKey: .earnedBadges)        ?? []
        spentPoints         = try c.decodeIfPresent(Int.self,              forKey: .spentPoints)         ?? 0
    }

    // MARK: - Computed

    /// Points available to spend on rewards.
    var availablePoints: Int { max(0, totalPoints - spentPoints) }

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

    // MARK: - Key builders (cached formatters — DateFormatter is expensive to create)

    private static let dailyKeyFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()
    private static let weeklyKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-'W'ww"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
    private static let monthlyKeyFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM"; return f
    }()
    private static let yearlyKeyFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy"; return f
    }()

    static func dailyKey(for date: Date) -> String {
        dailyKeyFormatter.string(from: date)
    }

    static func weeklyKey(for date: Date) -> String {
        weeklyKeyFormatter.string(from: date)
    }

    static func monthlyKey(for date: Date) -> String {
        monthlyKeyFormatter.string(from: date)
    }

    static func yearlyKey(for date: Date) -> String {
        yearlyKeyFormatter.string(from: date)
    }
}
