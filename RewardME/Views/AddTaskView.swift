import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject private var viewModel: RewardViewModel
    @Environment(\.dismiss) private var dismiss

    var taskToEdit: TaskItem?

    // MARK: - State
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var difficulty: TaskDifficulty = .easy

    // Due date
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Calendar.current.startOfDay(for: .now)

    // Recurrence top-level
    @State private var frequency: RecurrenceFrequency = .none

    // Daily
    @State private var dailyInterval: Int = 1

    // Weekly
    @State private var weeklyInterval: Int = 1
    @State private var weeklyDays: Set<Int> = []          // 1=Sun�7=Sat

    // Monthly
    @State private var monthlyInterval: Int = 1
    @State private var monthlyStyle: MonthlyRepeatStyle = .onDayOfMonth

    // Yearly
    @State private var yearlyInterval: Int = 1

    // Time
    @State private var hasTime: Bool = false
    @State private var recurrenceTime: Date = {
        var c = DateComponents(); c.hour = 9; c.minute = 0
        return Calendar.current.date(from: c) ?? .now
    }()

    // End
    @State private var endType: EndType = .never
    @State private var endCount: Int = 5
    @State private var endDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: .now) ?? .now

    private enum EndType: String, CaseIterable, Identifiable {
        case never = "Never"
        case count = "After"
        case date  = "On date"
        var id: String { rawValue }
    }

    private var isEditing: Bool { taskToEdit != nil }
    private static let weekdayLabels = ["S","M","T","W","T","F","S"]
    private static let weekdayFullLabels = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                difficultySection
                pointsSection
                dueDateSection
                recurrenceSection
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.bold)
                }
            }
        }
        .onAppear { loadFromTask() }
    }

    // MARK: - Sections

    private var detailsSection: some View {
        Section("Task Details") {
            TextField("Title", text: $title)
            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("Notes (optional)").foregroundColor(.secondary).padding(.top, 8).padding(.leading, 4)
                }
                TextEditor(text: $notes).frame(minHeight: 80)
            }
        }
    }

    private var difficultySection: some View {
        Section("Difficulty") {
            ForEach(TaskDifficulty.allCases) { diff in
                Button { difficulty = diff } label: {
                    HStack {
                        Image(systemName: diff.icon).foregroundColor(diff.color).frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(diff.rawValue).foregroundColor(.primary)
                            Text(diff.label).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        if difficulty == diff { Image(systemName: "checkmark").foregroundColor(.accentColor) }
                    }
                }
            }
        }
    }

    private var pointsSection: some View {
        Section("Points Preview") {
            HStack {
                Label("You'll earn", systemImage: "star.fill").foregroundColor(.secondary)
                Spacer()
                Text("+\(viewModel.previewPoints(difficulty: difficulty)) pts").font(.headline).foregroundColor(.yellow)
            }
            if viewModel.profile.currentStreak > 0 {
                HStack {
                    Label("Streak bonus active", systemImage: "bolt.fill").font(.caption).foregroundColor(.orange)
                    Spacer()
                    Text("🔥 \(viewModel.profile.currentStreak) days").font(.caption).foregroundColor(.orange)
                }
            }
        }
    }

    private var dueDateSection: some View {
        Section("Due Date") {
            Toggle("Set a due date", isOn: $hasDueDate)
            if hasDueDate {
                DatePicker("Due", selection: $dueDate,
                           in: Calendar.current.startOfDay(for: .now)...,
                           displayedComponents: .date)
                    .datePickerStyle(.graphical)
            }
        }
    }

    // MARK: - Recurrence Section

    @ViewBuilder
    private var recurrenceSection: some View {
        Section {
            // Frequency picker row
            Picker("Repeat", selection: $frequency) {
                ForEach(RecurrenceFrequency.allCases) { f in
                    Text(f.rawValue).tag(f)
                }
            }
            .onChange(of: frequency) { _, _ in
                // reset weekdays when switching away from weekly
                if frequency != .weekly { weeklyDays = [] }
            }

            if frequency != .none {
                intervalRow
                if frequency == .weekly { weekdayPickerRow }
                if frequency == .monthly { monthlyStyleRow }
                timeRow
                endSection
            }
        } header: {
            Text("Recurrence")
        } footer: {
            if frequency != .none {
                Text(buildRule().summary).foregroundColor(.accentColor)
            }
        }
    }

    private var intervalRow: some View {
        HStack {
            Text("Every")
            Spacer()
            Stepper(value: intervalBinding, in: 1...99) {
                HStack(spacing: 4) {
                    Text("\(currentInterval)")
                        .fontWeight(.semibold)
                        .frame(minWidth: 28, alignment: .trailing)
                    Text(intervalUnit)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var intervalBinding: Binding<Int> {
        switch frequency {
        case .daily:   return $dailyInterval
        case .weekly:  return $weeklyInterval
        case .monthly: return $monthlyInterval
        case .yearly:  return $yearlyInterval
        case .none:    return .constant(1)
        }
    }

    private var currentInterval: Int {
        switch frequency {
        case .daily:   return dailyInterval
        case .weekly:  return weeklyInterval
        case .monthly: return monthlyInterval
        case .yearly:  return yearlyInterval
        case .none:    return 1
        }
    }

    private var intervalUnit: String {
        let n = currentInterval
        switch frequency {
        case .daily:   return n == 1 ? "day"   : "days"
        case .weekly:  return n == 1 ? "week"  : "weeks"
        case .monthly: return n == 1 ? "month" : "months"
        case .yearly:  return n == 1 ? "year"  : "years"
        case .none:    return ""
        }
    }

    private var weekdayPickerRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("On these days")
                .font(.subheadline)
                .foregroundColor(.secondary)
            HStack(spacing: 4) {
                ForEach(1...7, id: \.self) { wd in
                    let selected = weeklyDays.contains(wd)
                    Button {
                        if selected { weeklyDays.remove(wd) }
                        else        { weeklyDays.insert(wd) }
                    } label: {
                        Text(Self.weekdayLabels[wd - 1])
                            .font(.caption).fontWeight(.semibold)
                            .frame(maxWidth: .infinity, minHeight: 34)
                            .background(selected ? Color.accentColor : Color.secondary.opacity(0.15))
                            .foregroundColor(selected ? .white : .primary)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            if weeklyDays.isEmpty {
                Text("No days selected � repeats every \(weeklyInterval == 1 ? "week" : "\(weeklyInterval) weeks") from completion")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var monthlyStyleRow: some View {
        Picker("Repeat by", selection: $monthlyStyle) {
            Text(monthlyOnDayLabel).tag(MonthlyRepeatStyle.onDayOfMonth)
            Text(monthlyOnWeekdayLabel).tag(MonthlyRepeatStyle.onWeekdayOfMonth)
        }
        .pickerStyle(.inline)
        .labelsHidden()
    }

    private var monthlyOnDayLabel: String {
        let day = Calendar.current.component(.day, from: hasDueDate ? dueDate : .now)
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22:     suffix = "nd"
        case 3, 23:     suffix = "rd"
        default:        suffix = "th"
        }
        return "On the \(day)\(suffix) of the month"
    }

    private var monthlyOnWeekdayLabel: String {
        let cal  = Calendar.current
        let date = hasDueDate ? dueDate : .now
        let wd   = cal.component(.weekday,        from: date)
        let ord  = cal.component(.weekdayOrdinal, from: date)
        let names = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
        let ordinals = ["1st","2nd","3rd","4th","5th"]
        let ordStr = ord <= 5 ? ordinals[ord - 1] : "\(ord)th"
        return "On the \(ordStr) \(names[wd - 1])"
    }

    private var timeRow: some View {
        Group {
            Toggle("Set a specific time", isOn: $hasTime)
            if hasTime {
                DatePicker("Time", selection: $recurrenceTime, displayedComponents: .hourAndMinute)
            }
        }
    }

    private var endSection: some View {
        Group {
            Picker("Ends", selection: $endType) {
                ForEach(EndType.allCases) { t in Text(t.rawValue).tag(t) }
            }
            if endType == .count {
                Stepper("After \(endCount) time\(endCount == 1 ? "" : "s")", value: $endCount, in: 1...999)
            }
            if endType == .date {
                DatePicker("End date", selection: $endDate,
                           in: (hasDueDate ? dueDate : .now)...,
                           displayedComponents: .date)
            }
        }
    }

    // MARK: - Build RecurrenceRule

    private func buildRule() -> RecurrenceRule {
        guard frequency != .none else { return .none }
        let timeComps = Calendar.current.dateComponents([.hour, .minute], from: recurrenceTime)
        let end: RecurrenceEnd
        switch endType {
        case .never: end = .never
        case .count: end = .afterOccurrences(endCount)
        case .date:  end = .onDate(Calendar.current.startOfDay(for: endDate))
        }
        return RecurrenceRule(
            frequency:    frequency,
            interval:     currentInterval,
            weekdays:     frequency == .weekly ? Array(weeklyDays).sorted() : [],
            monthlyStyle: monthlyStyle,
            hasTime:      hasTime,
            hour:         timeComps.hour   ?? 9,
            minute:       timeComps.minute ?? 0,
            end:          end
        )
    }

    // MARK: - Load / Save

    private func loadFromTask() {
        guard let task = taskToEdit else { return }
        title    = task.title
        notes    = task.notes
        difficulty = task.difficulty
        if let due = task.dueDate { hasDueDate = true; dueDate = due }

        let rule = task.recurrence
        frequency = rule.frequency
        switch rule.frequency {
        case .daily:   dailyInterval   = rule.interval
        case .weekly:  weeklyInterval  = rule.interval; weeklyDays = Set(rule.weekdays)
        case .monthly: monthlyInterval = rule.interval; monthlyStyle = rule.monthlyStyle
        case .yearly:  yearlyInterval  = rule.interval
        case .none:    break
        }
        hasTime = rule.hasTime
        var tc = DateComponents(); tc.hour = rule.hour; tc.minute = rule.minute
        if let t = Calendar.current.date(from: tc) { recurrenceTime = t }
        switch rule.end {
        case .never:                   endType = .never
        case .afterOccurrences(let n): endType = .count; endCount = n
        case .onDate(let d):           endType = .date;  endDate  = d
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let due  = hasDueDate ? Calendar.current.startOfDay(for: dueDate) : nil
        let rule = buildRule()

        if var task = taskToEdit {
            task.title      = trimmed
            task.notes      = notes
            task.difficulty = difficulty
            task.recurrence = rule
            task.dueDate    = due
            viewModel.updateTask(task)
        } else {
            viewModel.addTask(title: trimmed, notes: notes, difficulty: difficulty,
                       recurrence: rule, dueDate: due)
        }
        dismiss()
    }
}

#Preview {
    AddTaskView()
        .environmentObject(RewardViewModel())
}
