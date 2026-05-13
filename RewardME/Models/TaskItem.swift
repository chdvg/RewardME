import Foundation

// MARK: - Recurrence Rule

enum RecurrenceRule: String, Codable, CaseIterable, Identifiable {
    case none   = "None"
    case daily  = "Daily"
    case weekly = "Weekly"
    case yearly = "Yearly"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .none:   return "xmark.circle"
        case .daily:  return "sun.rise.fill"
        case .weekly: return "calendar.badge.clock"
        case .yearly: return "calendar.badge.plus"
        }
    }

    var label: String {
        switch self {
        case .none:   return "One-time"
        case .daily:  return "Repeats every day"
        case .weekly: return "Repeats every week"
        case .yearly: return "Repeats every year"
        }
    }

    /// Returns the next due date after `date`, or nil for non-recurring.
    func nextDueDate(from date: Date) -> Date? {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        switch self {
        case .none:   return nil
        case .daily:  return cal.date(byAdding: .day,        value: 1, to: start)
        case .weekly: return cal.date(byAdding: .weekOfYear, value: 1, to: start)
        case .yearly: return cal.date(byAdding: .year,       value: 1, to: start)
        }
    }
}

// MARK: - Task Item

struct TaskItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var notes: String
    var difficulty: TaskDifficulty
    var isCompleted: Bool
    var isCancelled: Bool
    var completedDate: Date?
    var createdDate: Date
    /// Points actually awarded when the task was completed (including streak bonus).
    var pointsAwarded: Int
    var recurrence: RecurrenceRule
    /// When set, the task is hidden until this date arrives.
    var dueDate: Date?

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        difficulty: TaskDifficulty = .easy,
        recurrence: RecurrenceRule = .none,
        dueDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.difficulty = difficulty
        self.isCompleted = false
        self.isCancelled = false
        self.completedDate = nil
        self.createdDate = Date()
        self.pointsAwarded = 0
        self.recurrence = recurrence
        self.dueDate = dueDate
    }

    // MARK: - Migration-safe Codable
    // Any new fields added after launch must have a default here so existing
    // saved data (which won't have the key) still decodes correctly.

    enum CodingKeys: String, CodingKey {
        case id, title, notes, difficulty, isCompleted, isCancelled,
             completedDate, createdDate, pointsAwarded, recurrence, dueDate
    }

    init(from decoder: Decoder) throws {
        let c          = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(UUID.self,           forKey: .id)
        title          = try c.decode(String.self,         forKey: .title)
        notes          = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        difficulty     = try c.decodeIfPresent(TaskDifficulty.self, forKey: .difficulty) ?? .easy
        isCompleted    = try c.decodeIfPresent(Bool.self,  forKey: .isCompleted)    ?? false
        isCancelled    = try c.decodeIfPresent(Bool.self,  forKey: .isCancelled)    ?? false   // ← new field default
        completedDate  = try c.decodeIfPresent(Date.self,  forKey: .completedDate)
        createdDate    = try c.decodeIfPresent(Date.self,  forKey: .createdDate)    ?? Date()
        pointsAwarded  = try c.decodeIfPresent(Int.self,   forKey: .pointsAwarded)  ?? 0
        recurrence     = try c.decodeIfPresent(RecurrenceRule.self, forKey: .recurrence) ?? .none
        dueDate        = try c.decodeIfPresent(Date.self,  forKey: .dueDate)
    }

    // MARK: - Helpers

    /// The calendar day (midnight) on which this task was completed, if any.
    var completionDay: Date? {
        guard let date = completedDate else { return nil }
        return Calendar.current.startOfDay(for: date)
    }
}
