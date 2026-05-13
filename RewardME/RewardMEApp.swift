import SwiftUI

@main
struct RewardMEApp: App {
    @StateObject private var viewModel = RewardViewModel()
    @StateObject private var settings  = AppSettings.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(settings)
                .onAppear {
                    NotificationManager.shared.requestPermission()
                }
        }
    }
}
