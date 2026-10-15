import Foundation
import Observation

struct DailyRevenue: Identifiable, Equatable {
    let day: Date
    let cents: Int

    var id: Date { day }
}

struct DashboardNotice: Identifiable, Equatable {
    let id: UUID
    let title: String
    let message: String
}

enum AgendaStatus {
    case past
    case inProgress
    case upcoming
}

@Observable
@MainActor
final class DashboardModel {
    /// Nil shows every barber.
    var barberFilter: Barber?
    private(set) var notice: DashboardNotice?

    private let repository: any BookingRepository
    private let calendar: Calendar
    private let now: () -> Date

    init(repository: any BookingRepository, calendar: Calendar, now: @escaping () -> Date) {
        self.repository = repository
        self.calendar = calendar
        self.now = now
    }

    var barbers: [Barber] { repository.barbers }
    var today: Date { calendar.startOfDay(for: now()) }
    var isOpenToday: Bool { !repository.shop.hours.blocks(on: today, calendar: calendar).isEmpty }
    var agenda: [Appointment] { repository.appointments(on: today, barber: barberFilter) }

    var weekRevenue: [DailyRevenue] {
        (0..<7).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return DailyRevenue(day: day, cents: revenue(on: day, upTo: now()))
        }
    }

    var weekTotalCents: Int { weekRevenue.reduce(0) { $0 + $1.cents } }

    /// Compared with the same stretch a week earlier; nil when there is nothing to compare with.
    var weekChangePercent: Int? {
        guard let sameMomentLastWeek = calendar.date(byAdding: .day, value: -7, to: now()) else { return nil }
        let previous = (7..<14).reduce(0) { total, offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return total }
            return total + revenue(on: day, upTo: sameMomentLastWeek)
        }
        guard previous > 0 else { return nil }
        return Int((Double(weekTotalCents - previous) / Double(previous) * 100).rounded())
    }

    var waitlistCount: Int {
        repository.waitlist.filter { $0.start > now() && (barberFilter == nil || $0.barber == barberFilter) }.count
    }

    func status(of appointment: Appointment) -> AgendaStatus {
        let current = now()
        if appointment.end <= current { return .past }
        if appointment.start <= current { return .inProgress }
        return .upcoming
    }

    func cancel(_ appointment: Appointment) {
        let time = clockTime(appointment.start)
        if let notified = repository.cancel(appointment) {
            notice = DashboardNotice(id: UUID(), title: "Se ha liberado las \(time)", message: "Hemos avisado a \(notified.clientName), de la lista de espera")
        } else {
            notice = DashboardNotice(id: UUID(), title: "Cita cancelada", message: "El hueco de las \(time) vuelve a estar libre")
        }
    }

    func dismissNotice() {
        notice = nil
    }

    /// Only what has already been served counts as billed.
    private func revenue(on day: Date, upTo cutoff: Date) -> Int {
        repository.appointments(on: day, barber: barberFilter)
            .filter { $0.start <= cutoff }
            .reduce(0) { $0 + $1.service.priceCents }
    }
}
