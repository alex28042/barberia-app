import SwiftUI

/// The payoff: red floods the screen, the tick draws itself and confetti falls.
struct ConfirmationView: View {
    let model: BookingFlowModel
    let appointment: Appointment
    let onDone: () -> Void

    @State private var isFlooded = false
    @State private var showsCheck = false
    @State private var showsDetails = false
    @State private var confettiStart: Date?
    @State private var remindsDayBefore = true
    @State private var isAddingToCalendar = false
    @State private var isInCalendar = false

    var body: some View {
        ZStack(alignment: .top) {
            brandColors.ground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    hero
                    VStack(spacing: 14) {
                        ticket
                        options
                    }
                    .padding(.horizontal, 20)
                    .offset(y: showsDetails ? -36 : 40)
                    .opacity(showsDetails ? 1 : 0)
                }
            }
            .scrollIndicators(.hidden)
            if let confettiStart {
                ConfettiView(startDate: confettiStart)
                    .ignoresSafeArea()
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button("Hecho", action: onDone)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .opacity(showsDetails ? 1 : 0)
        }
        .sensoryFeedback(.success, trigger: showsCheck)
        .onAppear(perform: celebrate)
        .onChange(of: remindsDayBefore) { _, isOn in
            model.setReminder(isOn, for: appointment)
        }
        .sheet(isPresented: $isAddingToCalendar) {
            AddToCalendarView(appointment: appointment, shop: model.shop) { didSave in
                isAddingToCalendar = false
                if didSave {
                    withAnimation(motion.bouncy) { isInCalendar = true }
                }
            }
            .ignoresSafeArea()
        }
    }

    private var hero: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 92, height: 92)
                    .scaleEffect(showsCheck ? 1 : 0.2)
                    .opacity(showsCheck ? 1 : 0)
                if showsCheck {
                    Image(systemName: "checkmark")
                        .font(.system(size: 42, weight: .heavy))
                        .foregroundStyle(brandColors.tint)
                        .transition(.symbolEffect(.drawOn))
                }
            }
            .frame(height: 96)
            VStack(spacing: 6) {
                Text("¡Hecho, \(firstName)!")
                    .font(typography.display(44))
                    .tracking(-1.2)
                    .foregroundStyle(.white)
                Text("Nos vemos \(model.phrase(for: appointment.start)).")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .multilineTextAlignment(.center)
            .opacity(showsCheck ? 1 : 0)
            .offset(y: showsCheck ? 0 : 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 72)
        .padding(.bottom, 76)
        .background {
            brandColors.tint
                .clipShape(Circle().scale(isFlooded ? 3.2 : 0.05))
                .ignoresSafeArea()
        }
    }

    private var ticket: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Monogram(initial: appointment.barber.initial, size: 46, tone: brandColors.tone(at: model.barbers.firstIndex(of: appointment.barber) ?? 0))
                VStack(alignment: .leading, spacing: 2) {
                    Text(appointment.service.name)
                        .font(typography.numeral(20))
                        .foregroundStyle(brandColors.ink)
                    Text("con \(appointment.barber.name)")
                        .font(.subheadline)
                        .foregroundStyle(brandColors.inkSecondary)
                }
                Spacer()
            }
            .padding(18)
            Rectangle()
                .fill(brandColors.hairline)
                .frame(height: 1)
                .padding(.horizontal, 18)
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 14) {
                GridRow {
                    detail("Día", shortDate(appointment.start))
                    detail("Hora", clockTime(appointment.start))
                }
                GridRow {
                    detail("Señal pagada", euros(appointment.depositCents))
                    detail("En la barbería", euros(appointment.service.priceCents - appointment.depositCents))
                }
            }
            .padding(18)
        }
        .background {
            TicketShape(notchY: 82).fill(brandColors.surface)
        }
        .shadow(color: .black.opacity(0.5), radius: 30, y: 16)
    }

    private var options: some View {
        VStack(spacing: 0) {
            Toggle(isOn: $remindsDayBefore) {
                optionLabel("Avisarme el día antes", systemImage: "bell.fill")
            }
            .tint(brandColors.tint)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            Rectangle().fill(brandColors.hairline).frame(height: 1).padding(.leading, 62)
            Button {
                isAddingToCalendar = true
            } label: {
                HStack {
                    optionLabel(isInCalendar ? "Añadida a tu calendario" : "Añadir al calendario", systemImage: "calendar")
                    Spacer()
                    Image(systemName: isInCalendar ? "checkmark.circle.fill" : "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(isInCalendar ? brandColors.open : brandColors.inkTertiary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isInCalendar)
        }
        .surface()
    }

    private var firstName: String {
        appointment.clientName.split(separator: " ").first.map(String.init) ?? appointment.clientName
    }

    private func celebrate() {
        withAnimation(.easeOut(duration: 0.55)) { isFlooded = true }
        withAnimation(motion.bouncy.delay(0.25)) { showsCheck = true }
        withAnimation(motion.gentle.delay(0.5)) { showsDetails = true }
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            confettiStart = .now
        }
    }

    private func detail(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(brandColors.inkSecondary)
            Text(value)
                .font(typography.numeral(18))
                .foregroundStyle(brandColors.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func optionLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(brandColors.tintText)
                .frame(width: 32, height: 32)
                .background(brandColors.tintSoft, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(brandColors.ink)
        }
    }
}
