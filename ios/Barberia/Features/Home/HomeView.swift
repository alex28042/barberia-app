import SwiftUI

struct HomeView: View {
    @Bindable var booking: BookingFlowModel
    let launchOptions: DemoLaunchOptions
    @State private var isBooking = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 34) {
                hero.riseIn(0)
                if let upcoming = booking.upcomingAppointment {
                    UpcomingTicket(appointment: upcoming, tone: tone(for: upcoming.barber), phrase: booking.phrase(for: upcoming.start))
                        .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95)))
                }
                menu.riseIn(1)
                team.riseIn(2)
                hours.riseIn(3)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(alignment: .top) {
            ZStack(alignment: .topLeading) {
                brandColors.ground
                AmbientGlow().offset(x: -140, y: -200)
            }
            .ignoresSafeArea()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                isBooking = true
            } label: {
                HStack(spacing: 10) {
                    Text("Reservar cita")
                    Image(systemName: "arrow.right")
                        .font(.headline.weight(.bold))
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 12)
            .background {
                LinearGradient(colors: [brandColors.ground.opacity(0), brandColors.ground], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.5))
                    .ignoresSafeArea()
            }
        }
        .animation(motion.gentle, value: booking.upcomingAppointment)
        .sensoryFeedback(.impact(weight: .light), trigger: isBooking) { _, isOpen in isOpen }
        .fullScreenCover(isPresented: $isBooking, onDismiss: booking.startOver) {
            BookingView(model: booking, presentsCheckoutOnAppear: launchOptions.opensCheckout, paysOnCheckout: launchOptions.paysOnCheckout) {
                isBooking = false
            }
        }
        .onAppear(perform: openBookingForDemo)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                BarberPole()
                    .frame(width: 15, height: 56)
                Text(booking.shop.name)
                    .font(typography.display(64))
                    .tracking(-1.6)
                    .foregroundStyle(brandColors.ink)
            }
            Text("Cortes clásicos y degradados en \(booking.shop.address). Reserva en treinta segundos.")
                .font(.body)
                .foregroundStyle(brandColors.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
            OpenStatusPill(status: booking.openStatus, phrase: booking.phrase(for:))
        }
    }

    private var menu: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionTitle(title: "La carta", detail: "Señal de \(euros(booking.shop.depositCents)) al reservar")
            VStack(spacing: 18) {
                ForEach(booking.services) { service in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(service.name)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(brandColors.ink)
                            DottedLeader()
                            Text(euros(service.priceCents))
                                .font(typography.numeral(19))
                                .foregroundStyle(brandColors.ink)
                        }
                        Text("\(service.durationMinutes) minutos")
                            .font(.footnote)
                            .foregroundStyle(brandColors.inkSecondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(20)
            .surface()
        }
    }

    private var team: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(title: "El equipo")
            HStack(spacing: 10) {
                ForEach(Array(booking.barbers.enumerated()), id: \.element.id) { index, barber in
                    VStack(spacing: 10) {
                        Monogram(initial: barber.initial, size: 58, tone: brandColors.tone(at: index))
                        VStack(spacing: 2) {
                            Text(barber.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(brandColors.ink)
                            Text(barber.specialty)
                                .font(.caption)
                                .foregroundStyle(brandColors.inkSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .surface(radius: 24)
                }
            }
        }
    }

    private var hours: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(title: "Horario")
            VStack(spacing: 12) {
                hoursRow("Lunes a viernes", hoursText(booking.shop.hours.weekdays))
                hoursRow("Sábado", hoursText(booking.shop.hours.saturday))
                hoursRow("Domingo", "Cerrado")
            }
            .padding(20)
            .surface()
        }
    }

    private func hoursRow(_ days: String, _ hours: String) -> some View {
        HStack {
            Text(days).foregroundStyle(brandColors.ink)
            Spacer()
            Text(hours)
                .monospacedDigit()
                .foregroundStyle(brandColors.inkSecondary)
        }
        .font(.subheadline)
    }

    private func tone(for barber: Barber) -> Color {
        brandColors.tone(at: booking.barbers.firstIndex(of: barber) ?? 0)
    }

    private func openBookingForDemo() {
        #if DEBUG
        guard launchOptions.opensBooking, booking.selectedBarber == nil else { return }
        if !launchOptions.opensEmptyBooking { booking.prefillForDemo() }
        isBooking = true
        #endif
    }
}

private struct OpenStatusPill: View {
    let status: OpenStatus
    let phrase: (Date) -> String

    var body: some View {
        HStack(spacing: 10) {
            switch status {
            case .open(let closesAt):
                PulsingDot(color: brandColors.open)
                Text("Abierto · cierra a las \(clockTime(closesAt))")
            case .closed(let opensAt):
                Circle().fill(brandColors.inkTertiary).frame(width: 8, height: 8)
                Text(opensAt.map { "Cerrado · abre \(phrase($0))" } ?? "Cerrado")
            }
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(brandColors.ink)
        .padding(.horizontal, 14)
        .frame(height: 36)
        .surface(radius: 18)
    }
}

/// The booking just made, drawn as a ticket.
private struct UpcomingTicket: View {
    let appointment: Appointment
    let tone: Color
    let phrase: String

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                Text(weekdayShort(appointment.start).uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1)
                Text(dayNumber(appointment.start))
                    .font(typography.display(38))
            }
            .foregroundStyle(.white)
            .frame(width: 92)
            .frame(maxHeight: .infinity)
            .background(brandColors.tint)

            VStack(alignment: .leading, spacing: 4) {
                Text("TU PRÓXIMA CITA")
                    .font(.caption.weight(.bold))
                    .tracking(1)
                    .foregroundStyle(brandColors.tintText)
                Text(appointment.service.name)
                    .font(typography.numeral(22))
                    .foregroundStyle(brandColors.ink)
                Text("\(capitalizedFirst(phrase)) con \(appointment.barber.name)")
                    .font(.subheadline)
                    .foregroundStyle(brandColors.inkSecondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            Spacer(minLength: 0)
            Monogram(initial: appointment.barber.initial, size: 40, tone: tone)
                .padding(.trailing, 18)
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(brandColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(brandColors.hairline)
        }
        .accessibilityElement(children: .combine)
    }
}

private func hoursText(_ blocks: [OpeningBlock]) -> String {
    blocks.map { "\(clockTime(minutes: $0.startMinute))–\(clockTime(minutes: $0.endMinute))" }.joined(separator: "  ·  ")
}
