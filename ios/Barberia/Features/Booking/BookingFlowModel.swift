import Foundation
import Observation

@Observable
@MainActor
final class BookingFlowModel {
    enum Phase: Equatable {
        case choosing
        case paying
        case confirmed(Appointment)
        case failed(String)
    }

    var selectedBarber: Barber? {
        didSet { if oldValue != selectedBarber { selectedSlot = nil } }
    }
    var selectedService: ShopService? {
        didSet { if oldValue != selectedService { selectedSlot = nil } }
    }
    var selectedDay: Date {
        didSet { if oldValue != selectedDay { selectedSlot = nil } }
    }
    var selectedSlot: TimeSlot?
    var clientName = ""
    var clientPhone = ""
    private(set) var phase: Phase = .choosing
    private(set) var upcomingAppointment: Appointment?
    private(set) var waitlistConfirmation: WaitlistEntry?

    private let repository: any BookingRepository
    private let payments: any PaymentGateway
    private let reminders: any ReminderScheduler
    private let slotGenerator: SlotGenerator
    private let calendar: Calendar
    private let now: () -> Date

    init(repository: any BookingRepository, payments: any PaymentGateway, reminders: any ReminderScheduler, slotGenerator: SlotGenerator, calendar: Calendar, now: @escaping () -> Date) {
        self.repository = repository
        self.payments = payments
        self.reminders = reminders
        self.slotGenerator = slotGenerator
        self.calendar = calendar
        self.now = now
        self.selectedDay = calendar.startOfDay(for: now())
        self.selectedDay = bookableDays.first ?? selectedDay
    }

    var shop: Shop { repository.shop }
    var barbers: [Barber] { repository.barbers }
    var services: [ShopService] { repository.services }

    /// The next two weeks of open days, skipping today once it has no time left.
    var bookableDays: [Date] {
        let today = calendar.startOfDay(for: now())
        let days = (0..<21).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
        return Array(days.filter(hasTimeLeft).prefix(12))
    }

    var slots: [TimeSlot] {
        guard let selectedBarber, let selectedService else { return [] }
        return slotGenerator.slots(
            on: selectedDay,
            durationMinutes: selectedService.durationMinutes,
            hours: shop.hours,
            booked: repository.appointments(on: selectedDay, barber: selectedBarber),
            now: now()
        )
    }

    var openStatus: OpenStatus { shop.hours.status(at: now(), calendar: calendar) }

    func phrase(for date: Date) -> String {
        relativeTimePhrase(date, now: now(), calendar: calendar)
    }

    /// The first start time a 30-minute service could take with this barber.
    func nextFreeStart(with barber: Barber) -> Date? {
        for day in bookableDays.prefix(4) {
            let free = slotGenerator.slots(
                on: day,
                durationMinutes: 30,
                hours: shop.hours,
                booked: repository.appointments(on: day, barber: barber),
                now: now()
            ).first { $0.isAvailable }
            if let free { return free.start }
        }
        return nil
    }

    var isReadyForCheckout: Bool {
        selectedBarber != nil && selectedService != nil && selectedSlot != nil
    }

    var hasClientName: Bool {
        !clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var remainingCents: Int {
        max((selectedService?.priceCents ?? 0) - shop.depositCents, 0)
    }

    func pay() async {
        guard hasClientName, phase != .paying,
              let selectedBarber, let selectedService, let selectedSlot else { return }
        phase = .paying
        do {
            _ = try await payments.chargeDeposit(amountCents: shop.depositCents, description: "\(selectedService.name) con \(selectedBarber.name)")
            let appointment = try repository.book(BookingRequest(
                clientName: clientName.trimmingCharacters(in: .whitespacesAndNewlines),
                barber: selectedBarber,
                service: selectedService,
                start: selectedSlot.start,
                depositCents: shop.depositCents
            ))
            upcomingAppointment = appointment
            phase = .confirmed(appointment)
            await reminders.scheduleReminder(for: appointment)
        } catch BookingError.slotTaken {
            phase = .failed("Alguien acaba de reservar esa hora. Elige otra.")
        } catch {
            phase = .failed("No se ha podido completar el pago. Inténtalo otra vez.")
        }
    }

    func prepareReminders() async {
        await reminders.requestPermission()
    }

    func setReminder(_ isOn: Bool, for appointment: Appointment) {
        if isOn {
            Task { await reminders.scheduleReminder(for: appointment) }
        } else {
            reminders.cancelReminder(for: appointment)
        }
    }

    func joinWaitlist(at slot: TimeSlot, name: String) {
        guard let selectedBarber else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = WaitlistEntry(id: UUID(), clientName: trimmed.isEmpty ? "Cliente" : trimmed, barber: selectedBarber, start: slot.start)
        repository.joinWaitlist(entry)
        waitlistConfirmation = entry
    }

    func dismissWaitlistConfirmation() {
        waitlistConfirmation = nil
    }

    func clearFailure() {
        if case .failed = phase { phase = .choosing }
    }

    /// Back to a blank booking, keeping the appointment just made on the home screen.
    func startOver() {
        phase = .choosing
        selectedBarber = nil
        selectedService = nil
        selectedSlot = nil
        selectedDay = bookableDays.first ?? calendar.startOfDay(for: now())
    }

    #if DEBUG
    /// Picks the first barber, a service and the first free hour, for checking the screens.
    func prefillForDemo() {
        selectedBarber = barbers.first
        selectedService = services.dropFirst().first
        selectedSlot = slots.first { $0.isAvailable }
    }
    #endif

    private func hasTimeLeft(on day: Date) -> Bool {
        guard let lastBlock = shop.hours.blocks(on: day, calendar: calendar).last,
              let closing = calendar.date(byAdding: .minute, value: lastBlock.endMinute - 30, to: calendar.startOfDay(for: day)) else { return false }
        return closing > now()
    }
}
