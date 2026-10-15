import Foundation
import Testing
@testable import Barberia

@MainActor
struct InMemoryBookingRepositoryTests {
    private let calendar = makeSpanishCalendar(timeZone: TimeZone(identifier: "Europe/Madrid")!)
    private let dani = Barber(id: "dani", name: "Dani", specialty: "Degradados")
    private let marcos = Barber(id: "marcos", name: "Marcos", specialty: "Clásico")
    private let haircut = ShopService(id: "corte", name: "Corte", durationMinutes: 30, priceCents: 1500)
    private let shop = DemoCatalog().shop

    private var fiveInTheAfternoon: Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 16, hour: 17))!
    }

    private func makeRepository(appointments: [Appointment] = [], waitlist: [WaitlistEntry] = []) -> InMemoryBookingRepository {
        InMemoryBookingRepository(shop: shop, barbers: [dani, marcos], services: [haircut], appointments: appointments, waitlist: waitlist, calendar: calendar)
    }

    private func request(for barber: Barber) -> BookingRequest {
        BookingRequest(clientName: "Carlos", barber: barber, service: haircut, start: fiveInTheAfternoon, depositCents: 500)
    }

    @Test func it_should_reject_a_booking_that_clashes_with_the_same_barber() throws {
        let repository = makeRepository()
        _ = try repository.book(request(for: dani))

        #expect(throws: BookingError.self) { try repository.book(request(for: dani)) }
    }

    @Test func it_should_accept_the_same_hour_with_another_barber() throws {
        let repository = makeRepository()
        _ = try repository.book(request(for: dani))

        let appointment = try repository.book(request(for: marcos))

        #expect(appointment.barber == marcos)
    }

    @Test func it_should_hand_a_cancelled_hour_to_the_waitlisted_client() throws {
        let waiting = WaitlistEntry(id: UUID(), clientName: "Lucía", barber: dani, start: fiveInTheAfternoon)
        let repository = makeRepository(waitlist: [waiting])
        let appointment = try repository.book(request(for: dani))

        let notified = repository.cancel(appointment)

        #expect(notified == waiting)
    }

    @Test func it_should_take_the_notified_client_off_the_waitlist() throws {
        let waiting = WaitlistEntry(id: UUID(), clientName: "Lucía", barber: dani, start: fiveInTheAfternoon)
        let repository = makeRepository(waitlist: [waiting])
        let appointment = try repository.book(request(for: dani))

        _ = repository.cancel(appointment)

        #expect(repository.waitlist.isEmpty)
    }

    @Test func it_should_free_the_hour_when_an_appointment_is_cancelled() throws {
        let repository = makeRepository()
        let appointment = try repository.book(request(for: dani))

        _ = repository.cancel(appointment)

        #expect(repository.appointments(on: fiveInTheAfternoon, barber: dani).isEmpty)
    }
}
