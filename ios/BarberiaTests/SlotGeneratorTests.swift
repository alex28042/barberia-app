import Foundation
import Testing
@testable import Barberia

struct SlotGeneratorTests {
    private let calendar = makeSpanishCalendar(timeZone: TimeZone(identifier: "Europe/Madrid")!)
    private let hours = OpeningHours(
        weekdays: [OpeningBlock(startMinute: 600, endMinute: 720)],
        saturday: []
    )
    private let barber = Barber(id: "dani", name: "Dani", specialty: "Degradados")
    private let haircut = ShopService(id: "corte", name: "Corte", durationMinutes: 30, priceCents: 1500)

    private var generator: SlotGenerator { SlotGenerator(calendar: calendar, stepMinutes: 30) }

    /// Thursday 16 October 2026.
    private var thursday: Date { calendar.date(from: DateComponents(year: 2026, month: 10, day: 16))! }
    private var sunday: Date { calendar.date(from: DateComponents(year: 2026, month: 10, day: 18))! }
    private var dayBefore: Date { calendar.date(byAdding: .day, value: -1, to: thursday)! }

    private func at(_ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: thursday)!
    }

    @Test func it_should_offer_every_start_time_that_fits_before_closing() {
        let slots = generator.slots(on: thursday, durationMinutes: 30, hours: hours, booked: [], now: dayBefore)

        #expect(slots.map(\.start) == [at(10), at(10, 30), at(11), at(11, 30)])
    }

    @Test func it_should_not_offer_a_start_time_whose_service_runs_past_closing() {
        let slots = generator.slots(on: thursday, durationMinutes: 45, hours: hours, booked: [], now: dayBefore)

        #expect(slots.last?.start == at(11))
    }

    @Test func it_should_mark_a_slot_taken_when_it_overlaps_a_booking() {
        let booking = Appointment(id: UUID(), clientName: "Hugo", barber: barber, service: haircut, start: at(10, 30), depositCents: 500)

        let slots = generator.slots(on: thursday, durationMinutes: 30, hours: hours, booked: [booking], now: dayBefore)

        #expect(slots.first { $0.start == at(10, 30) }?.isAvailable == false)
    }

    @Test func it_should_hide_start_times_that_have_already_passed() {
        let slots = generator.slots(on: thursday, durationMinutes: 30, hours: hours, booked: [], now: at(11, 10))

        #expect(slots.map(\.start) == [at(11, 30)])
    }

    @Test func it_should_offer_nothing_on_a_closed_day() {
        let slots = generator.slots(on: sunday, durationMinutes: 30, hours: hours, booked: [], now: dayBefore)

        #expect(slots.isEmpty)
    }
}
