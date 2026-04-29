import Foundation

struct TaskItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var notes: String
    var difficulty: TaskDifficulty
    var isCompleted: Bool
    var completedDate: Date?
    var createdDate: Date
    /// Points actually awarded when the task was completed (including streak bonus).
    var pointsAwarded: Int

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        difficulty: TaskDifficulty = .easy
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.difficulty = difficulty
        self.isCompleted = false
        self.completedDate = nil
        self.createdDate = Date()
        self.pointsAwarded = 0
    }

    // MARK: - Helpers

    /// The calendar day (midnight) on which this task was completed, if any.
    var completionDay: Date? {
        guard let date = completedDate else { return nil }
        return Calendar.current.startOfDay(for: date)
    }
}
