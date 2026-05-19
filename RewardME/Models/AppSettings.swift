import Foundation

// MARK: - History Retention

enum HistoryRetention: String, CaseIterable, Identifiable {
    case days30  = "30 Days"
    case days90  = "90 Days"
    case months6 = "6 Months"
    case year1   = "1 Year"
    case forever = "Forever"

    var id: String { rawValue }

    /// The earliest date to keep records for, or nil to keep everything.
    var cutoffDate: Date? {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .days30:  return cal.date(byAdding: .day,   value: -30, to: now)
        case .days90:  return cal.date(byAdding: .day,   value: -90, to: now)
        case .months6: return cal.date(byAdding: .month, value: -6,  to: now)
        case .year1:   return cal.date(byAdding: .year,  value: -1,  to: now)
        case .forever: return nil
        }
    }

    var storageNote: String {
        switch self {
        case .days30:  return "~30 entries kept (~6 KB)"
        case .days90:  return "3 months of history (~18 KB)"
        case .months6: return "Half-year history (~36 KB)"
        case .year1:   return "Full year history (~73 KB)"
        case .forever: return "All-time history — grows over years"
        }
    }
}

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

    @Published var historyRetention: HistoryRetention {
        didSet { UserDefaults.standard.set(historyRetention.rawValue, forKey: "historyRetention") }
    }

    @Published var userName: String {
        didSet { UserDefaults.standard.set(userName, forKey: "userName") }
    }

    @Published var avatarImageData: Data? {
        didSet {
            if let data = avatarImageData {
                UserDefaults.standard.set(data, forKey: "avatarImageData")
            } else {
                UserDefaults.standard.removeObject(forKey: "avatarImageData")
            }
        }
    }

    init() {
        let levelRaw       = UserDefaults.standard.string(forKey: "celebrationLevel") ?? CelebrationLevel.medium.rawValue
        celebrationLevel   = CelebrationLevel(rawValue: levelRaw) ?? .medium
        notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        notificationHour   = UserDefaults.standard.object(forKey: "notificationHour")   as? Int ?? 9
        notificationMinute = UserDefaults.standard.object(forKey: "notificationMinute") as? Int ?? 0
        let retentionRaw   = UserDefaults.standard.string(forKey: "historyRetention") ?? HistoryRetention.days90.rawValue
        historyRetention   = HistoryRetention(rawValue: retentionRaw) ?? .days90
        userName         = UserDefaults.standard.string(forKey: "userName") ?? ""
        avatarImageData  = UserDefaults.standard.data(forKey: "avatarImageData")
    }
}
