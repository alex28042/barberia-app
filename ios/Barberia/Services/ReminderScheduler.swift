import Foundation
import UserNotifications

enum ReminderTiming: Sendable {
    /// The real behaviour: the day before, at this hour.
    case dayBefore(hour: Int)
    /// For trying it out: a few seconds after booking.
    case afterDelay(seconds: Int)
}

@MainActor
protocol ReminderScheduler {
    /// Asks once, at a calm moment, so the system prompt never interrupts the confirmation.
    func requestPermission() async
    func scheduleReminder(for appointment: Appointment) async
    func cancelReminder(for appointment: Appointment)
}

@MainActor
final class LocalNotificationReminderScheduler: ReminderScheduler {
    private let timing: ReminderTiming
    private let calendar: Calendar

    init(timing: ReminderTiming, calendar: Calendar) {
        self.timing = timing
        self.calendar = calendar
    }

    func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    func scheduleReminder(for appointment: Appointment) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized, let trigger = makeTrigger(for: appointment) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Mañana tienes cita"
        content.body = "\(appointment.service.name) con \(appointment.barber.name) a las \(clockTime(appointment.start)). Si no puedes venir, cancélala desde la app."
        content.sound = .default

        let request = UNNotificationRequest(identifier: appointment.id.uuidString, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancelReminder(for appointment: Appointment) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [appointment.id.uuidString])
    }

    private func makeTrigger(for appointment: Appointment) -> UNNotificationTrigger? {
        switch timing {
        case .afterDelay(let seconds):
            return UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        case .dayBefore(let hour):
            guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: appointment.start),
                  let fireDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: dayBefore),
                  fireDate > .now else { return nil }
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }
    }
}

/// Shows the reminder as a banner even while the app is open.
final class ForegroundNotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
