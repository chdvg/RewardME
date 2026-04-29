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
}
