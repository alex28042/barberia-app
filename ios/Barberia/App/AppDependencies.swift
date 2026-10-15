import Foundation
import UserNotifications

/// Builds every collaborator once and hands the screens their models.
@MainActor
final class AppDependencies {
    private let repository: InMemoryBookingRepository
    private let payments: any PaymentGateway
    private let reminders: any ReminderScheduler
    private let slotGenerator: SlotGenerator
    private let calendar: Calendar
    private let notificationPresenter = ForegroundNotificationPresenter()

    init(launchArguments: [String], now: Date = .now) {
        let calendar = makeSpanishCalendar()
        let catalog = DemoCatalog()
        let seeder = DemoScheduleSeeder(catalog: catalog, calendar: calendar, stepMinutes: 30)
        let appointments = seeder.appointments(around: now)
        let timing: ReminderTiming = launchArguments.contains("-demoReminder") ? .afterDelay(seconds: 6) : .dayBefore(hour: 10)

        self.calendar = calendar
        self.slotGenerator = SlotGenerator(calendar: calendar, stepMinutes: 30)
        self.repository = InMemoryBookingRepository(
            shop: catalog.shop,
            barbers: catalog.barbers,
            services: catalog.services,
            appointments: appointments,
            waitlist: seeder.waitlist(for: appointments, now: now),
            calendar: calendar
        )
        self.payments = SimulatedPaymentGateway(latency: .milliseconds(1400))
        self.reminders = LocalNotificationReminderScheduler(timing: timing, calendar: calendar)
        UNUserNotificationCenter.current().delegate = notificationPresenter
    }

    func makeBookingFlowModel() -> BookingFlowModel {
        BookingFlowModel(repository: repository, payments: payments, reminders: reminders, slotGenerator: slotGenerator, calendar: calendar, now: { .now })
    }

    func makeDashboardModel() -> DashboardModel {
        DashboardModel(repository: repository, calendar: calendar, now: { .now })
    }
}
