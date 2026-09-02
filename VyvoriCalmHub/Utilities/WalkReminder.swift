import UserNotifications

enum WalkReminder {
    static let identifier = "walk.daily.reminder"

    static func cancel() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    static func enable(hour: Int, minute: Int, walkedToday: Bool) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    schedule(hour: hour, minute: minute, walkedToday: walkedToday)
                } else {
                    cancel()
                }
            }
        }
    }

    static func reschedule(enabled: Bool, hour: Int, minute: Int, walkedToday: Bool) {
        cancel()
        guard enabled else { return }
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
            schedule(hour: hour, minute: minute, walkedToday: walkedToday)
        }
    }

    private static func schedule(hour: Int, minute: Int, walkedToday: Bool) {
        cancel()
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let calendar = Calendar.current
        var fire = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime) ?? Date()
        if calendar.isDateInToday(fire), walkedToday {
            fire = calendar.date(byAdding: .day, value: 1, to: fire) ?? fire
        }
        if fire <= Date() {
            fire = calendar.date(byAdding: .day, value: 1, to: fire) ?? fire
        }
        let fireComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        let content = UNMutableNotificationContent()
        content.title = "A quiet walk"
        content.body = "When you have a moment, step outside for a few mindful minutes."
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: fireComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
