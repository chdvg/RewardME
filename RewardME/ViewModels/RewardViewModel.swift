import Foundation
import Combine

// MARK: - Badge Thresholds

private enum BadgeThreshold {
    // Task counts
    static let tasks5  = 5
    static let tasks10 = 10
    static let tasks25 = 25
    static let tasks50 = 50
    static let tasks100 = 100

    // Streaks
    static let streak3  = 3
    static let streak7  = 7
    static let streak14 = 14
    static let streak30 = 30

    // Epic task count
    static let epicTen = 10

    // Daily / weekly / monthly task windows
    static let dailyChampion   = 5
    static let weeklyWarrior   = 20
    static let monthlyMarathon = 50

    // Points milestones
    static let points500  = 500
    static let points1000 = 1_000
    static let points5000 = 5_000
}

@MainActor
final class RewardViewModel: ObservableObject {

    // MARK: - Published state

    @Published var tasks: [TaskItem] = []
    @Published var profile: UserProfile = UserProfile()
    @Published var recentlyEarnedBadges: [BadgeDefinition] = []

    private let store = DataStore.shared

    // MARK: - Init

    init() {
        tasks   = store.loadTasks()
        profile = store.loadProfile()
    }

    // MARK: - Task management

    func addTask(title: String, notes: String = "", difficulty: TaskDifficulty = .easy, recurrence: RecurrenceRule = .none, dueDate: Date? = nil) {
        let task = TaskItem(title: title, notes: notes, difficulty: difficulty, recurrence: recurrence, dueDate: dueDate)
        tasks.insert(task, at: 0)
        persist()
    }

    func deleteTask(_ task: TaskItem) {
        // If the task was completed, we do NOT revert points/stats —
        // that keeps the history accurate.
        tasks.removeAll { $0.id == task.id }
        persist()
    }

    func deleteTask(at offsets: IndexSet, in filtered: [TaskItem]) {
        let ids = offsets.map { filtered[$0].id }
        tasks.removeAll { ids.contains($0.id) }
        persist()
    }

    /// Toggle completion state. Completing awards points & updates stats.
    /// Un-completing subtracts only the points that were awarded at completion time.
    func toggleCompletion(of task: TaskItem) {
        guard let idx = tasks.firstIndex(where: { $0.id == task.id }) else { return }

        if tasks[idx].isCompleted {
            // ── Undo completion ─────────────────────────────────────────
            let pts = tasks[idx].pointsAwarded
            profile.totalPoints = max(0, profile.totalPoints - pts)

            if let day = tasks[idx].completionDay {
                decrement(&profile.dailyStats,   key: UserProfile.dailyKey(for: day))
                decrement(&profile.weeklyStats,  key: UserProfile.weeklyKey(for: day))
                decrement(&profile.monthlyStats, key: UserProfile.monthlyKey(for: day))
                decrement(&profile.yearlyStats,  key: UserProfile.yearlyKey(for: day))
            }

            profile.totalTasksCompleted = max(0, profile.totalTasksCompleted - 1)
            if tasks[idx].difficulty == .hard { profile.hardTasksCompleted = max(0, profile.hardTasksCompleted - 1) }
            if tasks[idx].difficulty == .epic { profile.epicTasksCompleted = max(0, profile.epicTasksCompleted - 1) }

            tasks[idx].isCompleted   = false
            tasks[idx].completedDate = nil
            tasks[idx].pointsAwarded = 0

            recalculateStreak()
        } else {
            // ── Complete task ────────────────────────────────────────────
            let now = Date()
            tasks[idx].isCompleted   = true
            tasks[idx].completedDate = now

            let pts = calculatePoints(for: tasks[idx])
            tasks[idx].pointsAwarded = pts
            profile.totalPoints += pts

            let day = Calendar.current.startOfDay(for: now)
            increment(&profile.dailyStats,   key: UserProfile.dailyKey(for: day))
            increment(&profile.weeklyStats,  key: UserProfile.weeklyKey(for: day))
            increment(&profile.monthlyStats, key: UserProfile.monthlyKey(for: day))
            increment(&profile.yearlyStats,  key: UserProfile.yearlyKey(for: day))

            profile.totalTasksCompleted += 1
            if tasks[idx].difficulty == .hard { profile.hardTasksCompleted += 1 }
            if tasks[idx].difficulty == .epic { profile.epicTasksCompleted += 1 }

            updateStreak(completionDay: day)
            checkBadges()

            // Spawn next occurrence for recurring tasks
            let rule = tasks[idx].recurrence
            if let nextDue = rule.nextDueDate(from: now) {
                let completed = tasks[idx]
                let next = TaskItem(
                    title: completed.title,
                    notes: completed.notes,
                    difficulty: completed.difficulty,
                    recurrence: rule,
                    dueDate: nextDue
                )
                tasks.append(next)
            }
        }

        persist()
    }

    func updateTask(_ updated: TaskItem) {
        guard let idx = tasks.firstIndex(where: { $0.id == updated.id }) else { return }
        tasks[idx] = updated
        persist()
    }

    // MARK: - Points calculation

    /// Base difficulty points × streak multiplier.
    func calculatePoints(for task: TaskItem) -> Int {
        let base   = task.difficulty.basePoints
        let streak = profile.currentStreak
        // Streak bonus: +10 % per 5-day streak tier, capped at +100 %
        let tier   = min(streak / 5, 10)
        let bonus  = base * tier / 10
        return base + bonus
    }

    /// Preview points the user would earn if they completed a task *right now*.
    func previewPoints(difficulty: TaskDifficulty) -> Int {
        let base   = difficulty.basePoints
        let streak = profile.currentStreak
        let tier   = min(streak / 5, 10)
        let bonus  = base * tier / 10
        return base + bonus
    }

    // MARK: - Streak

    private func updateStreak(completionDay: Date) {
        let cal = Calendar.current
        if let last = profile.lastCompletionDay {
            let diff = cal.dateComponents([.day], from: last, to: completionDay).day ?? 0
            if diff == 0 {
                // Same day — streak unchanged
            } else if diff == 1 {
                // Consecutive day
                profile.currentStreak += 1
            } else {
                // Gap — reset
                profile.currentStreak = 1
            }
        } else {
            profile.currentStreak = 1
        }

        profile.lastCompletionDay = completionDay
        if profile.currentStreak > profile.longestStreak {
            profile.longestStreak = profile.currentStreak
        }
    }

    /// Recalculate streak from the completed tasks (called after un-completing).
    private func recalculateStreak() {
        let cal = Calendar.current
        let completedDays = tasks
            .compactMap(\.completionDay)
            .map { cal.startOfDay(for: $0) }

        let uniqueDays = Array(Set(completedDays)).sorted()
        guard !uniqueDays.isEmpty else {
            profile.currentStreak     = 0
            profile.lastCompletionDay = nil
            return
        }

        // Walk from the most recent day backwards counting consecutive days.
        var streak = 1
        for i in stride(from: uniqueDays.count - 1, through: 1, by: -1) {
            let diff = cal.dateComponents([.day], from: uniqueDays[i - 1], to: uniqueDays[i]).day ?? 0
            if diff == 1 { streak += 1 } else { break }
        }

        profile.currentStreak     = streak
        profile.lastCompletionDay = uniqueDays.last
        if profile.currentStreak > profile.longestStreak {
            profile.longestStreak = profile.currentStreak
        }
    }

    // MARK: - Badges

    private func checkBadges() {
        var newBadges: [BadgeDefinition] = []

        func award(_ id: BadgeID) {
            guard !profile.earnedBadgeIDs.contains(id),
                  let def = BadgeDefinition.catalog[id]
            else { return }
            profile.earnedBadges.append(EarnedBadge(id: id, earnedDate: Date()))
            profile.totalPoints += def.bonusPoints
            newBadges.append(def)
        }

        let total  = profile.totalTasksCompleted
        let streak = profile.currentStreak
        let pts    = profile.totalPoints
        let hard   = profile.hardTasksCompleted
        let epic   = profile.epicTasksCompleted

        // Task count
        if total >= 1                             { award(.firstTask) }
        if total >= BadgeThreshold.tasks5         { award(.tasks5) }
        if total >= BadgeThreshold.tasks10        { award(.tasks10) }
        if total >= BadgeThreshold.tasks25        { award(.tasks25) }
        if total >= BadgeThreshold.tasks50        { award(.tasks50) }
        if total >= BadgeThreshold.tasks100       { award(.tasks100) }

        // Streaks
        if streak >= BadgeThreshold.streak3       { award(.streak3) }
        if streak >= BadgeThreshold.streak7       { award(.streak7) }
        if streak >= BadgeThreshold.streak14      { award(.streak14) }
        if streak >= BadgeThreshold.streak30      { award(.streak30) }

        // Difficulty
        if hard >= 1                              { award(.firstHard) }
        if epic >= 1                              { award(.firstEpic) }
        if epic >= BadgeThreshold.epicTen         { award(.epicTen) }

        // Time-window
        let today = Calendar.current.startOfDay(for: Date())
        if profile.tasksCompleted(on: today) >= BadgeThreshold.dailyChampion       { award(.dailyChampion) }
        if profile.tasksCompleted(inWeekOf: today) >= BadgeThreshold.weeklyWarrior { award(.weeklyWarrior) }
        if profile.tasksCompleted(inMonthOf: today) >= BadgeThreshold.monthlyMarathon { award(.monthlyMarathon) }

        // Points milestones (checked against pts *before* badge bonuses to avoid double-counting)
        if pts >= BadgeThreshold.points500        { award(.points500) }
        if pts >= BadgeThreshold.points1000       { award(.points1000) }
        if pts >= BadgeThreshold.points5000       { award(.points5000) }

        if !newBadges.isEmpty {
            recentlyEarnedBadges = newBadges
        }
    }

    // MARK: - Persistence

    private func persist() {
        store.saveTasks(tasks)
        store.saveProfile(profile)
    }

    // MARK: - Computed helpers

    var pendingTasks: [TaskItem] {
        let now = Date()
        return tasks.filter { !$0.isCompleted && ($0.dueDate == nil || $0.dueDate! <= now) }
    }
    var completedTasks: [TaskItem] { tasks.filter { $0.isCompleted } }

    var allBadges: [(definition: BadgeDefinition, earned: EarnedBadge?)] {
        BadgeID.allCases.compactMap { id in
            guard let def = BadgeDefinition.catalog[id] else { return nil }
            let earned = profile.earnedBadges.first { $0.id == id }
            return (def, earned)
        }
    }

    // MARK: - Stats helpers

    struct PeriodStat: Identifiable {
        let id = UUID()
        let label: String
        let count: Int
        let points: Int
    }

    /// Last 7 days, oldest first.
    var last7DayStats: [PeriodStat] {
        let cal = Calendar.current
        return (0..<7).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: Date()))!
            let count = profile.tasksCompleted(on: day)
            let pts   = tasks
                .filter { $0.completionDay == day }
                .reduce(0) { $0 + $1.pointsAwarded }
            let fmt = DateFormatter()
            fmt.dateFormat = "EEE"
            return PeriodStat(label: fmt.string(from: day), count: count, points: pts)
        }
    }

    /// Last 4 ISO weeks, oldest first.
    var last4WeekStats: [PeriodStat] {
        let cal = Calendar.current
        return (0..<4).reversed().map { offset in
            let day   = cal.date(byAdding: .weekOfYear, value: -offset, to: Date())!
            let count = profile.tasksCompleted(inWeekOf: day)
            let key   = UserProfile.weeklyKey(for: day)
            let pts   = tasks
                .filter { t in
                    guard let c = t.completedDate else { return false }
                    return UserProfile.weeklyKey(for: c) == key
                }
                .reduce(0) { $0 + $1.pointsAwarded }
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM d"
            return PeriodStat(label: fmt.string(from: day), count: count, points: pts)
        }
    }

    /// Last 6 calendar months, oldest first.
    var last6MonthStats: [PeriodStat] {
        let cal = Calendar.current
        return (0..<6).reversed().map { offset in
            let day   = cal.date(byAdding: .month, value: -offset, to: Date())!
            let count = profile.tasksCompleted(inMonthOf: day)
            let key   = UserProfile.monthlyKey(for: day)
            let pts   = tasks
                .filter { t in
                    guard let c = t.completedDate else { return false }
                    return UserProfile.monthlyKey(for: c) == key
                }
                .reduce(0) { $0 + $1.pointsAwarded }
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM"
            return PeriodStat(label: fmt.string(from: day), count: count, points: pts)
        }
    }

    /// Current year's monthly breakdown.
    var currentYearMonthlyStats: [PeriodStat] {
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        return (1...12).map { month in
            var comps  = DateComponents()
            comps.year = year; comps.month = month; comps.day = 1
            let day    = cal.date(from: comps) ?? Date()
            let count  = profile.tasksCompleted(inMonthOf: day)
            let key    = UserProfile.monthlyKey(for: day)
            let pts    = tasks
                .filter { t in
                    guard let c = t.completedDate else { return false }
                    return UserProfile.monthlyKey(for: c) == key
                }
                .reduce(0) { $0 + $1.pointsAwarded }
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM"
            return PeriodStat(label: fmt.string(from: day), count: count, points: pts)
        }
    }

    // MARK: - Utilities

    private func increment(_ dict: inout [String: Int], key: String) {
        dict[key, default: 0] += 1
    }

    private func decrement(_ dict: inout [String: Int], key: String) {
        guard let val = dict[key] else { return }
        if val <= 1 { dict.removeValue(forKey: key) }
        else        { dict[key] = val - 1 }
    }
}
