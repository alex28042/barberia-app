import Foundation

struct Barber: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let specialty: String

    var initial: String { String(name.prefix(1)) }
}

struct ShopService: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let durationMinutes: Int
    let priceCents: Int
}

struct Appointment: Identifiable, Hashable, Sendable {
    let id: UUID
    let clientName: String
    let barber: Barber
    let service: ShopService
    let start: Date
    let depositCents: Int

    var end: Date { start.addingTimeInterval(TimeInterval(service.durationMinutes * 60)) }

    func overlaps(start otherStart: Date, durationMinutes: Int) -> Bool {
        let otherEnd = otherStart.addingTimeInterval(TimeInterval(durationMinutes * 60))
        return start < otherEnd && otherStart < end
    }
}

/// A client who asked to be told if a taken hour frees up.
struct WaitlistEntry: Identifiable, Hashable, Sendable {
    let id: UUID
    let clientName: String
    let barber: Barber
    let start: Date
}

struct BookingRequest: Sendable {
    let clientName: String
    let barber: Barber
    let service: ShopService
    let start: Date
    let depositCents: Int
}

enum BookingError: Error {
    case slotTaken
}

/// A stretch of the day the shop is open, in minutes after midnight.
struct OpeningBlock: Hashable, Sendable {
    let startMinute: Int
    let endMinute: Int
}

struct OpeningHours: Sendable {
    let weekdays: [OpeningBlock]
    let saturday: [OpeningBlock]

    func blocks(on day: Date, calendar: Calendar) -> [OpeningBlock] {
        switch calendar.component(.weekday, from: day) {
        case 1: []
        case 7: saturday
        default: weekdays
        }
    }
}

struct Shop: Sendable {
    let name: String
    let address: String
    let depositCents: Int
    let hours: OpeningHours
}

struct TimeSlot: Identifiable, Hashable, Sendable {
    let start: Date
    let isAvailable: Bool

    var id: Date { start }
}
