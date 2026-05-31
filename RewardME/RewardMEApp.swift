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
                    // Only request OS permission when the user has opted in via the in-app toggle.
                    if settings.notificationsEnabled {
                        NotificationManager.shared.requestPermission()
                    }
                }
        }
    }
}
