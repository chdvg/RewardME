import SwiftUI

@main
struct RewardMEApp: App {
    @StateObject private var viewModel = RewardViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
