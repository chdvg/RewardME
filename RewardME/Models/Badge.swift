import Foundation

// MARK: - Badge Definition

/// Static metadata that describes a badge.
struct BadgeDefinition: Identifiable, Hashable {
    let id: BadgeID
    let name: String
    let description: String
    let icon: String   // SF Symbol name
    let bonusPoints: Int
}

// MARK: - Badge IDs

enum BadgeID: String, Codable, CaseIterable, Hashable {
    // ── Task-count milestones ──────────────────────────────────────────────
    case firstTask       = "first_task"
    case tasks5          = "tasks_5"
    case tasks10         = "tasks_10"
    case tasks25         = "tasks_25"
    case tasks50         = "tasks_50"
    case tasks100        = "tasks_100"

    // ── Streak milestones ─────────────────────────────────────────────────
    case streak3         = "streak_3"
    case streak7         = "streak_7"
    case streak14        = "streak_14"
    case streak30        = "streak_30"

    // ── Difficulty milestones ─────────────────────────────────────────────
    case firstHard       = "first_hard"
    case firstEpic       = "first_epic"
    case epicTen         = "epic_10"

    // ── Time-window milestones ────────────────────────────────────────────
    case dailyChampion   = "daily_champion"   // 5+ tasks in one day
    case weeklyWarrior   = "weekly_warrior"   // 20+ tasks in one week
    case monthlyMarathon = "monthly_marathon" // 50+ tasks in one month

    // ── Points milestones ─────────────────────────────────────────────────
    case points500       = "points_500"
    case points1000      = "points_1000"
    case points5000      = "points_5000"
}

// MARK: - Badge Catalog

extension BadgeDefinition {
    static let catalog: [BadgeID: BadgeDefinition] = [
        .firstTask:       BadgeDefinition(id: .firstTask,       name: "First Step",         description: "Complete your very first task.",          icon: "figure.walk",            bonusPoints: 25),
        .tasks5:          BadgeDefinition(id: .tasks5,          name: "Getting Started",     description: "Complete 5 tasks.",                       icon: "hand.thumbsup.fill",     bonusPoints: 50),
        .tasks10:         BadgeDefinition(id: .tasks10,         name: "On a Roll",           description: "Complete 10 tasks.",                      icon: "flame.fill",             bonusPoints: 75),
        .tasks25:         BadgeDefinition(id: .tasks25,         name: "Task Master",         description: "Complete 25 tasks.",                      icon: "checkmark.seal.fill",    bonusPoints: 150),
        .tasks50:         BadgeDefinition(id: .tasks50,         name: "Productivity Pro",    description: "Complete 50 tasks.",                      icon: "trophy.fill",            bonusPoints: 300),
        .tasks100:        BadgeDefinition(id: .tasks100,        name: "Century Champion",    description: "Complete 100 tasks.",                     icon: "rosette",                bonusPoints: 500),

        .streak3:         BadgeDefinition(id: .streak3,         name: "3-Day Streak",        description: "Maintain a 3-day completion streak.",     icon: "bolt.fill",              bonusPoints: 50),
        .streak7:         BadgeDefinition(id: .streak7,         name: "Week Warrior",        description: "Maintain a 7-day completion streak.",     icon: "bolt.circle.fill",       bonusPoints: 150),
        .streak14:        BadgeDefinition(id: .streak14,        name: "Two-Week Titan",      description: "Maintain a 14-day completion streak.",    icon: "bolt.heart.fill",        bonusPoints: 300),
        .streak30:        BadgeDefinition(id: .streak30,        name: "Monthly Master",      description: "Maintain a 30-day completion streak.",    icon: "crown.fill",             bonusPoints: 750),

        .firstHard:       BadgeDefinition(id: .firstHard,       name: "Rising Challenge",    description: "Complete your first Hard task.",          icon: "flame",                  bonusPoints: 100),
        .firstEpic:       BadgeDefinition(id: .firstEpic,       name: "Epic Achiever",       description: "Complete your first Epic task.",          icon: "star.fill",              bonusPoints: 200),
        .epicTen:         BadgeDefinition(id: .epicTen,         name: "Epic Legend",         description: "Complete 10 Epic tasks.",                 icon: "star.circle.fill",       bonusPoints: 500),

        .dailyChampion:   BadgeDefinition(id: .dailyChampion,   name: "Daily Champion",      description: "Complete 5 or more tasks in a single day.",  icon: "sun.max.fill",        bonusPoints: 100),
        .weeklyWarrior:   BadgeDefinition(id: .weeklyWarrior,   name: "Weekly Warrior",      description: "Complete 20 or more tasks in a single week.", icon: "calendar.badge.plus", bonusPoints: 250),
        .monthlyMarathon: BadgeDefinition(id: .monthlyMarathon, name: "Monthly Marathon",    description: "Complete 50 or more tasks in a month.",       icon: "calendar",            bonusPoints: 600),

        .points500:       BadgeDefinition(id: .points500,       name: "Point Collector",     description: "Earn 500 total points.",                  icon: "dollarsign.circle.fill", bonusPoints: 0),
        .points1000:      BadgeDefinition(id: .points1000,      name: "Point Hoarder",       description: "Earn 1 000 total points.",                icon: "dollarsign.square.fill", bonusPoints: 0),
        .points5000:      BadgeDefinition(id: .points5000,      name: "Points Legend",       description: "Earn 5 000 total points.",                icon: "dollarsign.arrow.circlepath", bonusPoints: 0),
    ]
}

// MARK: - Earned Badge Record

/// Lightweight record stored in UserProfile indicating a badge has been earned.
struct EarnedBadge: Codable, Hashable {
    let id: BadgeID
    let earnedDate: Date
}
