import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var vm: RewardViewModel

    var body: some View {
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

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(RewardViewModel())
}
