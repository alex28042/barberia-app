import Foundation

/// Works out which start times a service fits in on a given day.
struct SlotGenerator: Sendable {
    let calendar: Calendar
    let stepMinutes: Int

    /// Every start time that still lies ahead, marked unavailable when it clashes with a booking.
    func slots(on day: Date, durationMinutes: Int, hours: OpeningHours, booked: [Appointment], now: Date) -> [TimeSlot] {
        let dayStart = calendar.startOfDay(for: day)
        return hours.blocks(on: day, calendar: calendar).flatMap { block in
            stride(from: block.startMinute, through: block.endMinute - durationMinutes, by: stepMinutes).compactMap { minute -> TimeSlot? in
                guard let start = calendar.date(byAdding: .minute, value: minute, to: dayStart), start > now else { return nil }
                let isTaken = booked.contains { $0.overlaps(start: start, durationMinutes: durationMinutes) }
                return TimeSlot(start: start, isAvailable: !isTaken)
            }
        }
    }
}
