import Foundation

/// Fills the agenda around today with believable bookings, the same ones on every launch.
struct DemoScheduleSeeder {
    let catalog: DemoCatalog
    let calendar: Calendar
    let stepMinutes: Int

    func appointments(around now: Date) -> [Appointment] {
        var random = SeededRandom(seed: 1987)
        let today = calendar.startOfDay(for: now)
        var result: [Appointment] = []
        for offset in -14...13 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            for barber in catalog.barbers {
                result += appointments(for: barber, on: day, occupancy: occupancy(forDayOffset: offset), random: &random)
            }
        }
        return result
    }

    /// Puts the waitlisted clients on the next bookings, so cancelling one of them shows the notice.
    func waitlist(for appointments: [Appointment], now: Date) -> [WaitlistEntry] {
        let upcoming = appointments.filter { $0.start > now }.sorted { $0.start < $1.start }
        return zip(catalog.waitlistNames, upcoming).map { name, appointment in
            WaitlistEntry(id: UUID(), clientName: name, barber: appointment.barber, start: appointment.start)
        }
    }

    private func occupancy(forDayOffset offset: Int) -> Double {
        switch offset {
        case ..<0: 0.75
        case 0: 0.35
        case 1...2: 0.3
        default: 0.2
        }
    }

    private func appointments(for barber: Barber, on day: Date, occupancy: Double, random: inout SeededRandom) -> [Appointment] {
        let dayStart = calendar.startOfDay(for: day)
        var result: [Appointment] = []
        for block in catalog.shop.hours.blocks(on: day, calendar: calendar) {
            var minute = block.startMinute
            while minute + stepMinutes <= block.endMinute {
                guard let service = catalog.services.randomElement(using: &random),
                      let client = catalog.clientNames.randomElement(using: &random) else { break }
                let fits = minute + service.durationMinutes <= block.endMinute
                let isBooked = Double.random(in: 0..<1, using: &random) < occupancy
                if fits, isBooked, let start = calendar.date(byAdding: .minute, value: minute, to: dayStart) {
                    result.append(Appointment(id: UUID(), clientName: client, barber: barber, service: service, start: start, depositCents: catalog.shop.depositCents))
                    minute += roundedUpToStep(service.durationMinutes)
                } else {
                    minute += stepMinutes
                }
            }
        }
        return result
    }

    private func roundedUpToStep(_ minutes: Int) -> Int {
        ((minutes + stepMinutes - 1) / stepMinutes) * stepMinutes
    }
}

/// SplitMix64: a tiny deterministic generator, so the sample agenda is the same on every launch.
struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
