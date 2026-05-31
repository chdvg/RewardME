import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: RewardViewModel
    @EnvironmentObject private var settings:  AppSettings

    @State private var showSettings = false

    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
            } else {
                TabView {
                    TaskListView()
                        .tabItem {
                            Label("Tasks", systemImage: "checkmark.circle.fill")
                        }

                    BadgesView()
                        .tabItem {
                            Label("Badges", systemImage: "rosette")
                        }
                        .badge(viewModel.recentlyEarnedBadges.count)

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
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                }
            }

            // Celebration overlay — shown whenever a task is just completed.
            if let task = viewModel.celebrationTask, settings.celebrationLevel != .off {
                CelebrationView(
                    level:      settings.celebrationLevel,
                    difficulty: task.difficulty
                ) {
                    viewModel.celebrationTask = nil
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.3), value: viewModel.celebrationTask?.id)
    }
}

#Preview {
    ContentView()
        .environmentObject(RewardViewModel())
        .environmentObject(AppSettings())
}
