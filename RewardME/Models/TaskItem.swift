import Foundation

// MARK: - Recurrence Frequency

enum RecurrenceFrequency: String, Codable, CaseIterable, Identifiable {
    case none    = "None"
    case daily   = "Daily"
    case weekly  = "Weekly"
    case monthly = "Monthly"
    case yearly  = "Yearly"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .none:    return "xmark.circle"
        case .daily:   return "sun.rise.fill"
        case .weekly:  return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .yearly:  return "calendar.badge.plus"
        }
    }
}

// MARK: - Monthly Repeat Style

enum MonthlyRepeatStyle: String, Codable {
    case onDayOfMonth    = "On day"       // e.g. "on the 15th"
    case onWeekdayOfMonth = "On weekday"  // e.g. "on the 2nd Tuesday"
}

// MARK: - Recurrence End

enum RecurrenceEnd: Codable, Equatable {
    case never
    case afterOccurrences(Int)
    case onDate(Date)

    enum CodingKeys: String, CodingKey { case type, count, date }

    init(from decoder: Decoder) throws {
        let c    = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decodeIfPresent(String.self, forKey: .type) ?? "never"
        switch type {
        case "count": self = .afterOccurrences(try c.decodeIfPresent(Int.self, forKey: .count) ?? 1)
        case "date":  self = .onDate(try c.decodeIfPresent(Date.self, forKey: .date) ?? Date())
        default:      self = .never
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .never:
            try c.encode("never", forKey: .type)
        case .afterOccurrences(let n):
            try c.encode("count", forKey: .type)
            try c.encode(n,       forKey: .count)
        case .onDate(let d):
            try c.encode("date",  forKey: .type)
            try c.encode(d,       forKey: .date)
        }
    }

    var label: String {
        switch self {
        case .never:                    return "Never"
        case .afterOccurrences(let n):  return "After \(n) time\(n == 1 ? "" : "s")"
        case .onDate(let d):
            let fmt = DateFormatter()
            fmt.dateStyle = .medium
            return "Until \(fmt.string(from: d))"
        }
    }
}

// MARK: - Recurrence Rule (struct)

struct RecurrenceRule: Codable, Equatable {

    var frequency:        RecurrenceFrequency
    var interval:         Int              // every N units (1 = every, 2 = every other, etc.)
    var weekdays:         [Int]            // 1=Sun…7=Sat; used when frequency == .weekly
    var monthlyStyle:     MonthlyRepeatStyle
    var hasTime:          Bool             // whether a specific time-of-day was set
    var hour:             Int
    var minute:           Int
    var end:              RecurrenceEnd
    /// Running count of how many times this rule has spawned a next task. Used for .afterOccurrences.
    var occurrencesFired: Int

    static let none = RecurrenceRule(frequency: .none)

    init(
        frequency:        RecurrenceFrequency  = .none,
        interval:         Int                  = 1,
        weekdays:         [Int]                = [],
        monthlyStyle:     MonthlyRepeatStyle   = .onDayOfMonth,
        hasTime:          Bool                 = false,
        hour:             Int                  = 9,
        minute:           Int                  = 0,
        end:              RecurrenceEnd        = .never,
        occurrencesFired: Int                  = 0
    ) {
        self.frequency        = frequency
        self.interval         = max(1, interval)
        self.weekdays         = weekdays
        self.monthlyStyle     = monthlyStyle
        self.hasTime          = hasTime
        self.hour             = hour
        self.minute           = minute
        self.end              = end
        self.occurrencesFired = occurrencesFired
    }

    // MARK: - Codable (migration-safe)

    enum CodingKeys: String, CodingKey {
        case frequency, interval, weekdays, monthlyStyle, hasTime, hour, minute, end, occurrencesFired
    }

    init(from decoder: Decoder) throws {
        let c             = try decoder.container(keyedBy: CodingKeys.self)
        frequency         = try c.decodeIfPresent(RecurrenceFrequency.self, forKey: .frequency)     ?? .none
        interval          = try c.decodeIfPresent(Int.self,                 forKey: .interval)      ?? 1
        weekdays          = try c.decodeIfPresent([Int].self,               forKey: .weekdays)      ?? []
        monthlyStyle      = try c.decodeIfPresent(MonthlyRepeatStyle.self,  forKey: .monthlyStyle)  ?? .onDayOfMonth
        hasTime           = try c.decodeIfPresent(Bool.self,                forKey: .hasTime)       ?? false
        hour              = try c.decodeIfPresent(Int.self,                 forKey: .hour)          ?? 9
        minute            = try c.decodeIfPresent(Int.self,                 forKey: .minute)        ?? 0
        end               = try c.decodeIfPresent(RecurrenceEnd.self,       forKey: .end)           ?? .never
        occurrencesFired  = try c.decodeIfPresent(Int.self,                 forKey: .occurrencesFired) ?? 0
    }

    // MARK: - Human-readable summary

    var summary: String {
        guard frequency != .none else { return "Does not repeat" }
        var parts: [String] = []

        // Frequency + interval
        switch frequency {
        case .none:    break
        case .daily:   parts.append(interval == 1 ? "Every day"                : "Every \(interval) days")
        case .weekly:  parts.append(interval == 1 ? "Every week"               : "Every \(interval) weeks")
        case .monthly: parts.append(interval == 1 ? "Every month"              : "Every \(interval) months")
        case .yearly:  parts.append(interval == 1 ? "Every year"               : "Every \(interval) years")
        }

        // Weekly: specific days
        if frequency == .weekly && !weekdays.isEmpty {
            let names = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
            let dayNames = weekdays.sorted().map { names[$0 - 1] }.joined(separator: ", ")
            parts.append("on \(dayNames)")
        }

        // Time
        if hasTime {
            let fmt = DateFormatter()
            fmt.dateFormat = "h:mm a"
            var comps = DateComponents(); comps.hour = hour; comps.minute = minute
            if let d = Calendar.current.date(from: comps) {
                parts.append("at \(fmt.string(from: d))")
            }
        }

        // End
        if end != .never { parts.append("· \(end.label)") }

        return parts.joined(separator: " ")
    }

    // MARK: - Next due date

    /// Returns the next due date after `from`, or nil if the rule has ended.
    func nextDueDate(from date: Date, startDate: Date) -> Date? {
        guard frequency != .none else { return nil }

        // Check end conditions
        switch end {
        case .afterOccurrences(let max) where occurrencesFired >= max:
            return nil
        case .onDate(let endDate) where Calendar.current.startOfDay(for: date) >= Calendar.current.startOfDay(for: endDate):
            return nil
        default:
            break
        }

        let cal   = Calendar.current
        let start = cal.startOfDay(for: date)

        var candidate: Date?

        switch frequency {
        case .none:
            return nil

        case .daily:
            candidate = cal.date(byAdding: .day, value: interval, to: start)

        case .weekly:
            if weekdays.isEmpty {
                candidate = cal.date(byAdding: .weekOfYear, value: interval, to: start)
            } else {
                // Find next matching weekday within the interval-week window
                var next = cal.date(byAdding: .day, value: 1, to: start)!
                for _ in 0 ..< (interval * 7) {
                    let wd = cal.component(.weekday, from: next)
                    if weekdays.contains(wd) { candidate = next; break }
                    next = cal.date(byAdding: .day, value: 1, to: next)!
                }
                if candidate == nil {
                    candidate = cal.date(byAdding: .weekOfYear, value: interval, to: start)
                }
            }

        case .monthly:
            let base = cal.date(byAdding: .month, value: interval, to: start)!
            if monthlyStyle == .onDayOfMonth {
                // Same day-of-month as the original start date
                let originalDay = cal.component(.day, from: startDate)
                var comps       = cal.dateComponents([.year, .month], from: base)
                comps.day       = originalDay
                candidate       = cal.date(from: comps) ?? base
            } else {
                // Same "Nth weekday" as original start date
                let originalWeekday = cal.component(.weekday, from: startDate)
                let originalWeek    = cal.component(.weekdayOrdinal, from: startDate)
                var comps           = cal.dateComponents([.year, .month], from: base)
                comps.weekday        = originalWeekday
                comps.weekdayOrdinal = originalWeek
                candidate            = cal.date(from: comps) ?? base
            }

        case .yearly:
            candidate = cal.date(byAdding: .year, value: interval, to: start)
        }

        guard var result = candidate else { return nil }

        // Apply time-of-day if set
        if hasTime {
            var comps    = cal.dateComponents([.year, .month, .day], from: result)
            comps.hour   = hour
            comps.minute = minute
            comps.second = 0
            result       = cal.date(from: comps) ?? result
        }

        // Final end-date guard
        if case .onDate(let endDate) = end, result > endDate { return nil }

        return result
    }
}

// Legacy alias so old code that referenced RecurrenceRule as an enum still compiles
// (ViewModel and AddTaskView will be updated to use the struct directly)
typealias RecurrenceRuleLegacy = RecurrenceFrequency

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

    enum CodingKeys: String, CodingKey {
        case id, title, notes, difficulty, isCompleted, isCancelled,
             completedDate, createdDate, pointsAwarded, recurrence, dueDate
    }

    init(from decoder: Decoder) throws {
        let c             = try decoder.container(keyedBy: CodingKeys.self)
        id                = try c.decode(UUID.self,            forKey: .id)
        title             = try c.decode(String.self,          forKey: .title)
        notes             = try c.decodeIfPresent(String.self,  forKey: .notes)          ?? ""
        difficulty        = try c.decodeIfPresent(TaskDifficulty.self, forKey: .difficulty) ?? .easy
        isCompleted       = try c.decodeIfPresent(Bool.self,   forKey: .isCompleted)     ?? false
        isCancelled       = try c.decodeIfPresent(Bool.self,   forKey: .isCancelled)     ?? false
        completedDate     = try c.decodeIfPresent(Date.self,   forKey: .completedDate)
        createdDate       = try c.decodeIfPresent(Date.self,   forKey: .createdDate)     ?? Date()
        pointsAwarded     = try c.decodeIfPresent(Int.self,    forKey: .pointsAwarded)   ?? 0
        // Migration: old data stored recurrence as a plain string enum value ("Weekly").
        // Try decoding as the new struct first; fall back to wrapping the old string value.
        if let rule = try? c.decodeIfPresent(RecurrenceRule.self, forKey: .recurrence) {
            recurrence = rule ?? .none
        } else if let legacyFreq = try? c.decodeIfPresent(RecurrenceFrequency.self, forKey: .recurrence) {
            recurrence = RecurrenceRule(frequency: legacyFreq ?? .none)
        } else {
            recurrence = .none
        }
        dueDate           = try c.decodeIfPresent(Date.self,   forKey: .dueDate)
    }

    // MARK: - Helpers

    /// The calendar day (midnight) on which this task was completed, if any.
    var completionDay: Date? {
        guard let date = completedDate else { return nil }
        return Calendar.current.startOfDay(for: date)
    }
}
