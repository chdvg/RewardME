import UserNotifications
import Foundation

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    /// Requests notification authorization and posts a notification if the user denies.
    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if let error {
                    print("❌ Notification permission error: \(error.localizedDescription)")
                }
                if !granted {
                    print("⚠️ Notification permission denied by user.")
                    NotificationCenter.default.post(name: .notificationPermissionDenied, object: nil)
                }
                completion?(granted)
            }
        }
    }

    /// Checks current authorization status without requesting.
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    func schedule(task: TaskItem, hour: Int, minute: Int) {
        guard let dueDate = task.dueDate else { return }
        cancel(taskID: task.id)

        var components        = Calendar.current.dateComponents([.year, .month, .day], from: dueDate)
        components.hour       = hour
        components.minute     = minute

        // Only schedule if the fire date is in the future.
        let fireDate = Calendar.current.date(from: components) ?? .distantPast
        guard fireDate > Date() else { return }

        let content       = UNMutableNotificationContent()
        content.title     = "Task Due Today"
        content.body      = task.title
        content.sound     = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content:    content,
            trigger:    trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("❌ Failed to schedule notification for task '\(task.title)': \(error.localizedDescription)")
            }
        }
    }

    func cancel(taskID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [taskID.uuidString]
        )
    }

    func disableAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func rescheduleAll(tasks: [TaskItem], hour: Int, minute: Int) {
        disableAll()
        for task in tasks where !task.isCompleted && !task.isCancelled {
            schedule(task: task, hour: hour, minute: minute)
        }
    }
}

// MARK: - Notification name

extension Notification.Name {
    static let notificationPermissionDenied = Notification.Name("NotificationPermissionDenied")
}
