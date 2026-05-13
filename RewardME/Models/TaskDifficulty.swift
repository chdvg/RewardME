import SwiftUI

enum TaskDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case epic = "Epic"

    var id: String { rawValue }

    /// Points earned for completing a task of this difficulty (before streak bonus).
    var basePoints: Int {
        switch self {
        case .easy:   return 10
        case .medium: return 25
        case .hard:   return 50
        case .epic:   return 100
        }
    }

    var icon: String {
        switch self {
        case .easy:   return "leaf.fill"
        case .medium: return "bolt.fill"
        case .hard:   return "flame.fill"
        case .epic:   return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .easy:   return Color.green
        case .medium: return Color.blue
        case .hard:   return Color.orange
        case .epic:   return Color.purple
        }
    }

    var label: String {
        switch self {
        case .easy:   return "Easy (+\(basePoints) pts)"
        case .medium: return "Medium (+\(basePoints) pts)"
        case .hard:   return "Hard (+\(basePoints) pts)"
        case .epic:   return "Epic (+\(basePoints) pts)"
        }
    }

    var sortOrder: Int {
        switch self {
        case .easy: return 0; case .medium: return 1
        case .hard: return 2; case .epic:   return 3
        }
    }
}

// MARK: - Filter / Sort options

enum TaskStatusFilter: String, CaseIterable, Identifiable {
    case pending = "Pending", done = "Done", cancelled = "Cancelled"
    var id: String { rawValue }
}

enum DifficultyFilter: String, CaseIterable, Identifiable {
    case all = "All", easy = "Easy", medium = "Medium", hard = "Hard", epic = "Epic"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .all:    return "square.grid.2x2"
        case .easy:   return "leaf.fill"
        case .medium: return "bolt.fill"
        case .hard:   return "flame.fill"
        case .epic:   return "star.fill"
        }
    }
    var color: Color {
        switch self {
        case .all:    return .primary
        case .easy:   return .green
        case .medium: return .blue
        case .hard:   return .orange
        case .epic:   return .purple
        }
    }
}

enum DueFilter: String, CaseIterable, Identifiable {
    case all = "All", overdue = "Overdue", dueToday = "Today", upcoming = "Upcoming", noDue = "No Date"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .all:      return "calendar"
        case .overdue:  return "exclamationmark.circle.fill"
        case .dueToday: return "sun.max.fill"
        case .upcoming: return "arrow.forward.circle"
        case .noDue:    return "minus.circle"
        }
    }
    var color: Color {
        switch self {
        case .overdue:  return .red
        case .dueToday: return .orange
        case .upcoming: return .blue
        default:        return .secondary
        }
    }
}

enum SortOption: String, CaseIterable, Identifiable {
    case dateCreated = "Date Created"
    case dueDate     = "Due Date"
    case difficulty  = "Difficulty"
    case points      = "Points"
    case title       = "Name"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .dateCreated: return "clock"
        case .dueDate:     return "calendar"
        case .difficulty:  return "flame"
        case .points:      return "star"
        case .title:       return "textformat.abc"
        }
    }
}
