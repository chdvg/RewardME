import SwiftUI

// MARK: - Task Row

struct TaskRowView: View {
    let task: TaskItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Completion button
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .green : .secondary)
                    .animation(.spring(response: 0.3), value: task.isCompleted)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted, color: .secondary)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .lineLimit(2)

                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    // Difficulty badge
                    Label(task.difficulty.rawValue, systemImage: task.difficulty.icon)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(task.difficulty.color.opacity(0.15))
                        .foregroundColor(task.difficulty.color)
                        .clipShape(Capsule())

                    if task.isCompleted {
                        Label("\(task.pointsAwarded) pts", systemImage: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    } else {
                        Text("+\(task.difficulty.basePoints) pts")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if task.isCompleted, let date = task.completedDate {
                Text(date, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
