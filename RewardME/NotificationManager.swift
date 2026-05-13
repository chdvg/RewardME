import UserNotifications
import Foundation

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
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
        UNUserNotificationCenter.current().add(request)
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
