import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject private var vm: RewardViewModel
    @Environment(\.dismiss) private var dismiss

    // Edit mode (nil = new task)
    var taskToEdit: TaskItem?

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var difficulty: TaskDifficulty = .easy
    @State private var recurrence: RecurrenceRule = .none

    private var isEditing: Bool { taskToEdit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)

                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("Notes (optional)")
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                    }
                }

                Section("Difficulty") {
                    ForEach(TaskDifficulty.allCases) { diff in
                        Button {
                            difficulty = diff
                        } label: {
                            HStack {
                                Image(systemName: diff.icon)
                                    .foregroundColor(diff.color)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(diff.rawValue)
                                        .foregroundColor(.primary)
                                    Text(diff.label)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if difficulty == diff {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }

                Section("Points Preview") {
                    HStack {
                        Label("You'll earn", systemImage: "star.fill")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("+\(vm.previewPoints(difficulty: difficulty)) pts")
                            .font(.headline)
                            .foregroundColor(.yellow)
                    }
                    if vm.profile.currentStreak > 0 {
                        HStack {
                            Label("Streak bonus active", systemImage: "bolt.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Spacer()
                            Text("🔥 \(vm.profile.currentStreak) days")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }

                Section("Recurrence") {
                    ForEach(RecurrenceRule.allCases) { rule in
                        Button {
                            recurrence = rule
                        } label: {
                            HStack {
                                Image(systemName: rule.icon)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(rule.rawValue)
                                        .foregroundColor(.primary)
                                    Text(rule.label)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if recurrence == rule {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        save()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
        .onAppear {
            if let task = taskToEdit {
                title      = task.title
                notes      = task.notes
                difficulty = task.difficulty
                recurrence = task.recurrence
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if var task = taskToEdit {
            task.title      = trimmed
            task.notes      = notes
            task.difficulty = difficulty
            task.recurrence = recurrence
            vm.updateTask(task)
        } else {
            vm.addTask(title: trimmed, notes: notes, difficulty: difficulty, recurrence: recurrence)
        }
        dismiss()
    }
}

#Preview {
    AddTaskView()
        .environmentObject(RewardViewModel())
}
