import Foundation

/// Where appointments and the waitlist live. The demo keeps them in memory;
/// a backend-backed implementation can replace it without touching the screens.
@MainActor
protocol BookingRepository: AnyObject {
    var shop: Shop { get }
    var barbers: [Barber] { get }
    var services: [ShopService] { get }
    var waitlist: [WaitlistEntry] { get }

    /// Appointments on `day`, earliest first. A nil `barber` means every barber.
    func appointments(on day: Date, barber: Barber?) -> [Appointment]
    func book(_ request: BookingRequest) throws -> Appointment
    /// Removes the appointment and returns the waitlisted client who gets its place, if any.
    func cancel(_ appointment: Appointment) -> WaitlistEntry?
    func joinWaitlist(_ entry: WaitlistEntry)
}
