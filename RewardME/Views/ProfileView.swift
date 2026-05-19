import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var vm: RewardViewModel
    @EnvironmentObject private var settings: AppSettings
    @State private var showResetAlert   = false
    @State private var showEditProfile  = false

    var body: some View {
        NavigationStack {
            List {
                // ── Points & Streak hero ─────────────────────────────────
                Section {
                    heroSection
                }
                .listRowBackground(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.7), Color.purple.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .listRowInsets(EdgeInsets())

                // ── Streak details ───────────────────────────────────────
                Section("Streak") {
                    statRow(label: "Current Streak",  value: "\(vm.profile.currentStreak) days",  icon: "flame.fill",   color: .orange)
                    statRow(label: "Longest Streak",  value: "\(vm.profile.longestStreak) days",  icon: "crown.fill",   color: .yellow)
                    if let last = vm.profile.lastCompletionDay {
                        statRow(label: "Last Active", value: RelativeDateTimeFormatter().localizedString(for: last, relativeTo: Date()), icon: "calendar", color: .blue)
                    }
                }

                // ── Task stats ───────────────────────────────────────────
                Section("Tasks") {
                    statRow(label: "Total Completed",  value: "\(vm.profile.totalTasksCompleted)",  icon: "checkmark.circle.fill", color: .green)
                    statRow(label: "Hard Tasks",       value: "\(vm.profile.hardTasksCompleted)",   icon: "flame.fill",            color: .orange)
                    statRow(label: "Epic Tasks",       value: "\(vm.profile.epicTasksCompleted)",   icon: "star.fill",             color: .purple)
                    statRow(label: "Pending",          value: "\(vm.pendingTasks.count)",           icon: "circle",                color: .secondary)
                }

                // ── Points breakdown ─────────────────────────────────────
                Section("Points") {
                    statRow(label: "Task Points",   value: "\(vm.profile.totalPoints - vm.profile.badgeBonusPoints)", icon: "star.fill",   color: .yellow)
                    statRow(label: "Badge Bonuses", value: "+\(vm.profile.badgeBonusPoints)",                         icon: "rosette",     color: .orange)
                    statRow(label: "Total Points",  value: "\(vm.profile.totalPoints)",                               icon: "dollarsign.circle.fill", color: .green)
                }

                // ── Points per difficulty guide ──────────────────────────
                Section("Points Guide") {
                    ForEach(TaskDifficulty.allCases) { diff in
                        HStack {
                            Label(diff.rawValue, systemImage: diff.icon)
                                .foregroundColor(diff.color)
                            Spacer()
                            Text("\(diff.basePoints) base pts")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack {
                        Label("Streak Bonus", systemImage: "bolt.fill")
                            .foregroundColor(.orange)
                        Spacer()
                        Text("+10% per 5-day tier (max 100%)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // ── Brag About It ────────────────────────────────────────
                Section {
                    ShareLink(
                        item: vm.braggingText,
                        preview: SharePreview("My RewardME Stats", image: Image(systemName: "trophy.fill"))
                    ) {
                        Label("Brag About It!", systemImage: "megaphone.fill")
                            .foregroundColor(.accentColor)
                    }
                } footer: {
                    Text("Share your progress via text, social media, or anywhere else.")
                }

                // ── Danger zone ──────────────────────────────────────────
                Section {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("Reset All Data", systemImage: "trash")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showEditProfile = true
                    } label: {
                        Label("Edit Profile", systemImage: "person.crop.circle.badge.pencil")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    ShareLink(
                        item: vm.braggingText,
                        preview: SharePreview("My RewardME Stats", image: Image(systemName: "trophy.fill"))
                    ) {
                        Label("Brag", systemImage: "megaphone.fill")
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) {
                    DataStore.shared.reset()
                    vm.tasks   = []
                    vm.profile = UserProfile()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all your tasks, badges, and points. This action cannot be undone.")
            }
        }
    }

    // MARK: - Hero section

    private var heroSection: some View {
        VStack(spacing: 14) {
            // Avatar with optional crown
            let streak = vm.profile.currentStreak
            let crown: String? = streak >= 7 ? "👑" : streak >= 3 ? "⭐️" : nil
            AvatarView(imageData: settings.avatarImageData, size: 80, crown: crown)

            // Greeting
            if !settings.userName.isEmpty {
                Text("Great job, \(settings.userName)!")
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }

            // Points circle
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 88, height: 88)
                VStack(spacing: 2) {
                    Text("\(vm.profile.totalPoints)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Points")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            // Stats row
            HStack(spacing: 24) {
                VStack {
                    Text("\(vm.profile.earnedBadges.count)")
                        .font(.title3).bold().foregroundColor(.white)
                    Text("Badges")
                        .font(.caption).foregroundColor(.white.opacity(0.8))
                }
                VStack {
                    Text("\(vm.profile.currentStreak)🔥")
                        .font(.title3).bold().foregroundColor(.white)
                    Text("Streak")
                        .font(.caption).foregroundColor(.white.opacity(0.8))
                }
                VStack {
                    Text("\(vm.profile.totalTasksCompleted)")
                        .font(.title3).bold().foregroundColor(.white)
                    Text("Done")
                        .font(.caption).foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Helpers

    private func statRow(label: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundColor(color)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
                .font(.subheadline)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(RewardViewModel())
        .environmentObject(AppSettings.shared)
}
