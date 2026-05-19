import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var vm:       RewardViewModel
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        ZStack {
            TabView {
                TaskListView()
                    .tabItem {
                        Label("Tasks", systemImage: "checkmark.circle.fill")
                    }

                BadgesView()
                    .tabItem {
                        Label("Badges", systemImage: "rosette")
                    }
                    .badge(vm.recentlyEarnedBadges.count)

                RewardsView()
                    .tabItem {
                        Label("Rewards", systemImage: "gift.fill")
                    }

                StatsView()
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar.fill")
                    }

                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }

            // Celebration overlay — shown whenever a task is just completed.
            if let task = vm.celebrationTask, settings.celebrationLevel != .off {
                CelebrationView(
                    level:      settings.celebrationLevel,
                    difficulty: task.difficulty
                ) {
                    vm.celebrationTask = nil
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.3), value: vm.celebrationTask?.id)
    }
}

#Preview {
    ContentView()
        .environmentObject(RewardViewModel())
        .environmentObject(AppSettings())
}
