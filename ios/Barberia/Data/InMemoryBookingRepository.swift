import Foundation
import Observation

@Observable
@MainActor
final class InMemoryBookingRepository: BookingRepository {
    let shop: Shop
    let barbers: [Barber]
    let services: [ShopService]
    private(set) var waitlist: [WaitlistEntry]
    private var storedAppointments: [Appointment]
    private let calendar: Calendar

    init(shop: Shop, barbers: [Barber], services: [ShopService], appointments: [Appointment], waitlist: [WaitlistEntry], calendar: Calendar) {
        self.shop = shop
        self.barbers = barbers
        self.services = services
        self.storedAppointments = appointments
        self.waitlist = waitlist
        self.calendar = calendar
    }

    func appointments(on day: Date, barber: Barber?) -> [Appointment] {
        storedAppointments
            .filter { calendar.isDate($0.start, inSameDayAs: day) && (barber == nil || $0.barber == barber) }
            .sorted { $0.start < $1.start }
    }

    func book(_ request: BookingRequest) throws -> Appointment {
        let clashes = storedAppointments.contains {
            $0.barber == request.barber && $0.overlaps(start: request.start, durationMinutes: request.service.durationMinutes)
        }
        guard !clashes else { throw BookingError.slotTaken }

        let appointment = Appointment(
            id: UUID(),
            clientName: request.clientName,
            barber: request.barber,
            service: request.service,
            start: request.start,
            depositCents: request.depositCents
        )
        storedAppointments.append(appointment)
        return appointment
    }

    func cancel(_ appointment: Appointment) -> WaitlistEntry? {
        storedAppointments.removeAll { $0.id == appointment.id }
        let waitingIndex = waitlist.firstIndex {
            $0.barber == appointment.barber && appointment.overlaps(start: $0.start, durationMinutes: 1)
        }
        guard let waitingIndex else { return nil }
        return waitlist.remove(at: waitingIndex)
    }

    func joinWaitlist(_ entry: WaitlistEntry) {
        waitlist.append(entry)
    }
}
