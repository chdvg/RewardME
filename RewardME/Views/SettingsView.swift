import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: RewardViewModel
    @EnvironmentObject private var settings: AppSettings

    @State private var notificationPermissionDenied = false

    // Mirror the hour/minute as a single Date for the DatePicker.
    @State private var notificationTime: Date = {
        var comps        = DateComponents()
        comps.hour       = AppSettings.shared.notificationHour
        comps.minute     = AppSettings.shared.notificationMinute
        return Calendar.current.date(from: comps) ?? .now
    }()

    var body: some View {
        NavigationStack {
            Form {
                // ── Celebrations ──────────────────────────────────────
                Section {
                    ForEach(CelebrationLevel.allCases) { level in
                        Button {
                            settings.celebrationLevel = level
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: level.icon)
                                    .foregroundColor(iconColor(for: level))
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(level.rawValue)
                                        .foregroundColor(.primary)
                                    Text(level.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if settings.celebrationLevel == level {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Celebration Level")
                } footer: {
                    Text("Controls the animation when you complete a task. Epic tasks always get an extra boost.")
                }

                // ── Redemption history ────────────────────────────────
                Section {
                    ForEach(HistoryRetention.allCases) { window in
                        Button {
                            settings.historyRetention = window
                            viewModel.pruneRedemptions()
                        } label: {
                            HStack {
                                Text(window.rawValue)
                                    .foregroundColor(.primary)
                                Spacer()
                                if settings.historyRetention == window {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Redemption History")
                } footer: {
                    Text("How long to keep your reward redemption history. \(settings.historyRetention.storageNote).")
                }

                // ── Notifications ─────────────────────────────────────
                Section {
                    Toggle("Enable Reminders", isOn: $settings.notificationsEnabled)
                        .onChange(of: settings.notificationsEnabled) { _, enabled in
                            if enabled {
                                NotificationManager.shared.requestPermission { granted in
                                    notificationPermissionDenied = !granted
                                    if granted {
                                        NotificationManager.shared.rescheduleAll(
                                            tasks:  viewModel.tasks,
                                            hour:   settings.notificationHour,
                                            minute: settings.notificationMinute
                                        )
                                    } else {
                                        // Revert toggle — permission denied
                                        settings.notificationsEnabled = false
                                    }
                                }
                            } else {
                                NotificationManager.shared.disableAll()
                            }
                        }

                    if notificationPermissionDenied {
                        Label("Notifications are blocked. Go to Settings > RewardME to enable them.", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }

                    if settings.notificationsEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: $notificationTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: notificationTime) { _, newTime in
                            let comps              = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                            settings.notificationHour   = comps.hour   ?? 9
                            settings.notificationMinute = comps.minute ?? 0
                            NotificationManager.shared.rescheduleAll(
                                tasks:  viewModel.tasks,
                                hour:   settings.notificationHour,
                                minute: settings.notificationMinute
                            )
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("A reminder fires on each task's due date at the time you choose.")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                // Keep picker in sync if settings changed elsewhere.
                var comps  = DateComponents()
                comps.hour   = settings.notificationHour
                comps.minute = settings.notificationMinute
                if let t = Calendar.current.date(from: comps) { notificationTime = t }

                // Check current permission status so we can show warning if denied
                NotificationManager.shared.checkAuthorizationStatus { status in
                    notificationPermissionDenied = (status == .denied)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .notificationPermissionDenied)) { _ in
                notificationPermissionDenied = true
            }
        }
    }

    private func iconColor(for level: CelebrationLevel) -> Color {
        switch level {
        case .off:                return .secondary
        case .mild:               return .blue
        case .medium:             return .green
        case .wild:               return .orange
        case .absolutelyUnhinged: return .red
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(RewardViewModel())
        .environmentObject(AppSettings())
}
