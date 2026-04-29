import SwiftUI

struct TaskListView: View {
    @EnvironmentObject private var vm: RewardViewModel

    @State private var showAddTask = false
    @State private var taskToEdit: TaskItem?
    @State private var showCompleted = false

    private var displayedTasks: [TaskItem] {
        showCompleted ? vm.completedTasks : vm.pendingTasks
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if vm.tasks.isEmpty {
                    emptyState
                } else {
                    List {
                        // ── Segment control ───────────────────────────────────
                        Picker("", selection: $showCompleted) {
                            Text("Pending (\(vm.pendingTasks.count))").tag(false)
                            Text("Done (\(vm.completedTasks.count))").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))

                        if displayedTasks.isEmpty {
                            noTasksPlaceholder
                        } else {
                            ForEach(displayedTasks) { task in
                                TaskRowView(task: task) {
                                    withAnimation { vm.toggleCompletion(of: task) }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        taskToEdit = task
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            vm.deleteTask(task)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .animation(.default, value: displayedTasks.map(\.id))
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    streakBadge
                }
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskView()
            }
            .sheet(item: $taskToEdit) { task in
                AddTaskView(taskToEdit: task)
            }
            .overlay(badgeToastOverlay, alignment: .top)
        }
    }

    // MARK: - Sub-views

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor.opacity(0.4))
            Text("No Tasks Yet")
                .font(.title2).bold()
            Text("Tap + to add your first task\nand start earning points!")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button {
                showAddTask = true
            } label: {
                Label("Add Task", systemImage: "plus")
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }

    private var noTasksPlaceholder: some View {
        HStack {
            Spacer()
            Text(showCompleted ? "No completed tasks yet." : "All done! 🎉")
                .foregroundColor(.secondary)
                .padding(.vertical, 20)
            Spacer()
        }
        .listRowBackground(Color.clear)
    }

    private var streakBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
            Text("\(vm.profile.currentStreak)")
                .font(.subheadline).bold()
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

// MARK: - Badge Toast

struct BadgeToastView: View {
    let badge: BadgeDefinition
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: badge.icon)
                .font(.title2)
                .foregroundColor(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("Badge Unlocked! 🏅")
                    .font(.caption).bold()
                    .foregroundColor(.secondary)
                Text(badge.name)
                    .font(.subheadline).bold()
            }
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                onDismiss()
            }
        }
    }
}

#Preview {
    TaskListView()
        .environmentObject(RewardViewModel())
}
