import Foundation

// MARK: - Celebration Level

enum CelebrationLevel: String, CaseIterable, Identifiable {
    case off                = "Off"
    case mild               = "Mild"
    case medium             = "Medium"
    case wild               = "Wild"
    case absolutelyUnhinged = "Absolutely Unhinged"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .off:                return "speaker.slash"
        case .mild:               return "sparkles"
        case .medium:             return "party.popper.fill"
        case .wild:               return "fireworks"
        case .absolutelyUnhinged: return "flame.fill"
        }
    }

    var description: String {
        switch self {
        case .off:                return "No celebration effects"
        case .mild:               return "Subtle confetti burst"
        case .medium:             return "Confetti + haptic feedback"
        case .wild:               return "Full-screen confetti + strong haptic"
        case .absolutelyUnhinged: return "Fireworks, haptics, and chaos! 🎆"
        }
    }
}

// MARK: - App Settings

final class AppSettings: ObservableObject {

    static let shared = AppSettings()

    @Published var celebrationLevel: CelebrationLevel {
        didSet { UserDefaults.standard.set(celebrationLevel.rawValue, forKey: "celebrationLevel") }
    }

    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }

    @Published var notificationHour: Int {
        didSet { UserDefaults.standard.set(notificationHour, forKey: "notificationHour") }
    }

    @Published var notificationMinute: Int {
        didSet { UserDefaults.standard.set(notificationMinute, forKey: "notificationMinute") }
    }

    init() {
        let levelRaw       = UserDefaults.standard.string(forKey: "celebrationLevel") ?? CelebrationLevel.medium.rawValue
        celebrationLevel   = CelebrationLevel(rawValue: levelRaw) ?? .medium
        notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        notificationHour   = UserDefaults.standard.object(forKey: "notificationHour")   as? Int ?? 9
        notificationMinute = UserDefaults.standard.object(forKey: "notificationMinute") as? Int ?? 0
    }
}
