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
    @State private var recurrenceWeekdays: Set<Int> = []
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Calendar.current.startOfDay(for: .now)

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

                Section("Due Date") {
                    Toggle("Set a due date", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker(
                            "Due",
                            selection: $dueDate,
                            in: Calendar.current.startOfDay(for: .now)...,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                    }
                }

                Section("Recurrence") {
                    ForEach(RecurrenceRule.allCases) { rule in
                        Button {
                            recurrence = rule
                            if rule != .weekly { recurrenceWeekdays = [] }
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

                    if recurrence == .weekly {
                        weekdayPicker
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
                title              = task.title
                notes              = task.notes
                difficulty         = task.difficulty
                recurrence         = task.recurrence
                recurrenceWeekdays = Set(task.recurrenceWeekdays)
                if let due = task.dueDate {
                    hasDueDate = true
                    dueDate    = due
                }
            }
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let due      = hasDueDate ? Calendar.current.startOfDay(for: dueDate) : nil
        let weekdays = recurrence == .weekly ? Array(recurrenceWeekdays).sorted() : []

        if var task = taskToEdit {
            task.title              = trimmed
            task.notes              = notes
            task.difficulty         = difficulty
            task.recurrence         = recurrence
            task.recurrenceWeekdays = weekdays
            task.dueDate            = due
            vm.updateTask(task)
        } else {
            vm.addTask(title: trimmed, notes: notes, difficulty: difficulty,
                       recurrence: recurrence, recurrenceWeekdays: weekdays, dueDate: due)
        }
        dismiss()
    }

    // MARK: - Weekday Picker

    private static let weekdayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    // Calendar weekday ints: 1=Sun, 2=Mon … 7=Sat

    private var weekdayPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Repeat on")
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 6) {
                ForEach(1...7, id: \.self) { wd in
                    let label = Self.weekdayLabels[wd - 1]
                    let selected = recurrenceWeekdays.contains(wd)
                    Button {
                        if selected { recurrenceWeekdays.remove(wd) }
                        else        { recurrenceWeekdays.insert(wd) }
                    } label: {
                        Text(label)
                            .font(.caption2).fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(selected ? Color.accentColor : Color.secondary.opacity(0.15))
                            .foregroundColor(selected ? .white : .primary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            if recurrenceWeekdays.isEmpty {
                Text("No days selected — repeats every 7 days from completion")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 6)
    }
}

#Preview {
    AddTaskView()
        .environmentObject(RewardViewModel())
}
