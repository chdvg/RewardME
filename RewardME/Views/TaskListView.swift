import SwiftUI

struct TaskListView: View {
    @EnvironmentObject private var vm: RewardViewModel

    @State private var showAddTask     = false
    @State private var taskToEdit: TaskItem?
    @State private var statusFilter    : TaskStatusFilter = .pending
    @State private var diffFilter      : DifficultyFilter = .all
    @State private var dueFilter       : DueFilter        = .all
    @State private var sortOption      : SortOption       = .dateCreated
    @State private var sortAscending   : Bool             = false
    @State private var showFilterSheet : Bool             = false

    private var displayedTasks: [TaskItem] {
        vm.filteredAndSorted(
            status: statusFilter,
            difficulty: diffFilter,
            due: dueFilter,
            sort: sortOption,
            ascending: sortAscending
        )
    }

    private var hasActiveFilters: Bool {
        diffFilter != .all || dueFilter != .all || sortOption != .dateCreated
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if vm.tasks.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        Picker("", selection: $statusFilter) {
                            ForEach(TaskStatusFilter.allCases) { s in
                                Text(statusLabel(s)).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                        if hasActiveFilters { filterChips }

                        if displayedTasks.isEmpty {
                            emptyFilterState
                        } else {
                            List {
                                ForEach(displayedTasks) { task in
                                    TaskRowView(task: task) {
                                        withAnimation { vm.toggleCompletion(of: task) }
                                    }
                                    .swipeActions(edge: .leading) {
                                        if statusFilter == .pending {
                                            Button { taskToEdit = task } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }.tint(.blue)
                                        }
                                        if statusFilter == .cancelled {
                                            Button {
                                                withAnimation { vm.uncancelTask(task) }
                                            } label: {
                                                Label("Restore", systemImage: "arrow.uturn.left")
                                            }.tint(.blue)
                                        }
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            withAnimation { vm.deleteTask(task) }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                        if statusFilter == .pending {
                                            Button {
                                                withAnimation { vm.cancelTask(task) }
                                            } label: {
                                                Label("Cancel", systemImage: "xmark.circle")
                                            }.tint(.orange)
                                        }
                                    }
                                }
                            }
                            .listStyle(.insetGrouped)
                            .animation(.default, value: displayedTasks.map(\.id))
                        }
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { streakBadge }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button { showFilterSheet = true } label: {
                            Image(systemName: hasActiveFilters
                                  ? "line.3.horizontal.decrease.circle.fill"
                                  : "line.3.horizontal.decrease.circle")
                                .font(.title3)
                                .foregroundColor(hasActiveFilters ? .accentColor : .primary)
                        }
                        Button { showAddTask = true } label: {
                            Image(systemName: "plus.circle.fill").font(.title2)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddTask) { AddTaskView() }
            .sheet(item: $taskToEdit) { task in AddTaskView(taskToEdit: task) }
            .sheet(isPresented: $showFilterSheet) {
                FilterSortSheet(
                    diffFilter: $diffFilter,
                    dueFilter:  $dueFilter,
                    sortOption: $sortOption,
                    ascending:  $sortAscending
                )
            }
            .overlay(badgeToastOverlay, alignment: .top)
        }
    }

    // MARK: - Helpers

    private func statusLabel(_ s: TaskStatusFilter) -> String {
        switch s {
        case .pending:   return "Pending (\(vm.pendingTasks.count))"
        case .done:      return "Done (\(vm.completedTasks.count))"
        case .cancelled: return "Cancelled (\(vm.cancelledTasks.count))"
        }
    }

    // MARK: - Sub-views

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if diffFilter != .all {
                    chip(label: diffFilter.rawValue, icon: diffFilter.icon, color: diffFilter.color) { diffFilter = .all }
                }
                if dueFilter != .all {
                    chip(label: dueFilter.rawValue, icon: dueFilter.icon, color: dueFilter.color) { dueFilter = .all }
                }
                if sortOption != .dateCreated {
                    chip(label: sortOption.rawValue, icon: sortOption.icon, color: .accentColor) {
                        sortOption = .dateCreated; sortAscending = false
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 6)
        }
    }

    private func chip(label: String, icon: String, color: Color, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text(label).font(.caption).fontWeight(.medium)
            Button(action: onRemove) {
                Image(systemName: "xmark").font(.caption2).fontWeight(.bold)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .clipShape(Capsule())
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor.opacity(0.4))
            Text("No Tasks Yet").font(.title2).bold()
            Text("Tap + to add your first task\nand start earning points!")
                .multilineTextAlignment(.center).foregroundColor(.secondary)
            Button {
                showAddTask = true
            } label: {
                Label("Add Task", systemImage: "plus")
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }.padding()
    }

    private var emptyFilterState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44)).foregroundColor(.secondary.opacity(0.4))
            Text("No tasks match your filters").font(.headline).foregroundColor(.secondary)
            Button("Clear Filters") {
                diffFilter = .all; dueFilter = .all
                sortOption = .dateCreated; sortAscending = false
            }.buttonStyle(.borderedProminent)
            Spacer()
        }.frame(maxWidth: .infinity)
    }

    private var streakBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill").foregroundColor(.orange)
            Text("\(vm.profile.currentStreak)").font(.subheadline).bold()
        }
    }

    @ViewBuilder
    private var badgeToastOverlay: some View {
        if let badge = vm.recentlyEarnedBadges.first {
            BadgeToastView(badge: badge) {
                var remaining = vm.recentlyEarnedBadges
                remaining.removeFirst()
                vm.recentlyEarnedBadges = remaining
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(), value: vm.recentlyEarnedBadges.count)
            .padding(.top, 8)
        }
    }
}

// MARK: - Filter / Sort Sheet

struct FilterSortSheet: View {
    @Binding var diffFilter : DifficultyFilter
    @Binding var dueFilter  : DueFilter
    @Binding var sortOption : SortOption
    @Binding var ascending  : Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Filter by Difficulty") {
                    ForEach(DifficultyFilter.allCases) { d in
                        Button {
                            diffFilter = d
                        } label: {
                            HStack {
                                Image(systemName: d.icon).foregroundColor(d.color).frame(width: 24)
                                Text(d.rawValue).foregroundColor(.primary)
                                Spacer()
                                if diffFilter == d { Image(systemName: "checkmark").foregroundColor(.accentColor) }
                            }
                        }
                    }
                }

                Section("Filter by Due Date") {
                    ForEach(DueFilter.allCases) { d in
                        Button {
                            dueFilter = d
                        } label: {
                            HStack {
                                Image(systemName: d.icon).foregroundColor(d.color).frame(width: 24)
                                Text(d.rawValue).foregroundColor(.primary)
                                Spacer()
                                if dueFilter == d { Image(systemName: "checkmark").foregroundColor(.accentColor) }
                            }
                        }
                    }
                }

                Section("Sort By") {
                    ForEach(SortOption.allCases) { s in
                        Button {
                            if sortOption == s { ascending.toggle() } else { sortOption = s; ascending = false }
                        } label: {
                            HStack {
                                Image(systemName: s.icon).foregroundColor(.accentColor).frame(width: 24)
                                Text(s.rawValue).foregroundColor(.primary)
                                Spacer()
                                if sortOption == s {
                                    Image(systemName: ascending ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.accentColor).font(.caption)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        diffFilter = .all; dueFilter = .all
                        sortOption = .dateCreated; ascending = false
                    } label: {
                        Label("Reset All Filters", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.bold)
                }
            }
        }
    }
}

// MARK: - Badge Toast

struct BadgeToastView: View {
    let badge: BadgeDefinition
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: badge.icon).font(.title2).foregroundColor(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("Badge Unlocked! 🏅").font(.caption).bold().foregroundColor(.secondary)
                Text(badge.name).font(.subheadline).bold()
            }
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { onDismiss() }
        }
    }
}

#Preview {
    TaskListView().environmentObject(RewardViewModel())
}
