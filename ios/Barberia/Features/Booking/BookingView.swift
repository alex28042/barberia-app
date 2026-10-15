import SwiftUI

enum BookingStep: Int, CaseIterable {
    case barber
    case service
    case time

    var title: String {
        switch self {
        case .barber: "¿Con quién?"
        case .service: "¿Qué te hacemos?"
        case .time: "¿Cuándo te viene?"
        }
    }
}

/// Booking in three short steps; choosing something moves on by itself.
struct BookingView: View {
    @Bindable var model: BookingFlowModel
    var presentsCheckoutOnAppear = false
    var paysOnCheckout = false
    let onClose: () -> Void

    @State private var step: BookingStep
    @State private var isMovingForward = true
    @State private var isCheckoutPresented = false
    @State private var waitlistSlot: TimeSlot?
    @State private var waitlistName = ""

    init(model: BookingFlowModel, presentsCheckoutOnAppear: Bool = false, paysOnCheckout: Bool = false, onClose: @escaping () -> Void) {
        self.model = model
        self.presentsCheckoutOnAppear = presentsCheckoutOnAppear
        self.paysOnCheckout = paysOnCheckout
        self.onClose = onClose
        let hasChoices = model.selectedBarber != nil && model.selectedService != nil
        _step = State(initialValue: hasChoices ? .time : .barber)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topBar
            choiceChips
            ZStack(alignment: .top) {
                stepContent
                    .id(step)
                    .transition(stepTransition)
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .clipped()
        }
        .background(brandColors.ground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if step == .time, model.isReadyForCheckout {
                CheckoutBar(model: model) { isCheckoutPresented = true }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(motion.snappy, value: model.isReadyForCheckout)
        .overlay(alignment: .top) { waitlistToast }
        .animation(motion.snappy, value: model.waitlistConfirmation)
        .sensoryFeedback(.success, trigger: model.waitlistConfirmation) { _, entry in entry != nil }
        .sensoryFeedback(.impact(weight: .light), trigger: step)
        .alert("¿Te avisamos si se libera?", isPresented: isWaitlistAlertPresented, presenting: waitlistSlot) { slot in
            TextField("Tu nombre", text: $waitlistName)
                .textContentType(.name)
            Button("Apuntarme") { model.joinWaitlist(at: slot, name: waitlistName) }
            Button("Ahora no", role: .cancel) {}
        } message: { slot in
            Text("Las \(clockTime(slot.start)) están cogidas. Si alguien cancela, te mandamos un aviso.")
        }
        .sheet(isPresented: $isCheckoutPresented, onDismiss: closeIfConfirmed) {
            CheckoutSheet(model: model, paysOnAppear: paysOnCheckout) { isCheckoutPresented = false }
        }
        .onAppear {
            if presentsCheckoutOnAppear, model.isReadyForCheckout { isCheckoutPresented = true }
        }
        .task { await model.prepareReminders() }
    }

    // MARK: Header

    private var topBar: some View {
        HStack(spacing: 16) {
            Button(action: goBackOrClose) {
                Image(systemName: step == .barber ? "xmark" : "chevron.left")
                    .font(.body.weight(.bold))
                    .foregroundStyle(brandColors.ink)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 44, height: 44)
                    .background(brandColors.surface, in: Circle())
                    .overlay(Circle().strokeBorder(brandColors.hairline))
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel(step == .barber ? "Cerrar" : "Atrás")

            HStack(spacing: 6) {
                ForEach(BookingStep.allCases, id: \.self) { candidate in
                    Capsule()
                        .fill(candidate.rawValue <= step.rawValue ? brandColors.tint : brandColors.surfaceRaised)
                        .frame(height: 5)
                }
            }
            .animation(motion.gentle, value: step)

            Text("\(step.rawValue + 1) de 3")
                .font(typography.numeral(15))
                .foregroundStyle(brandColors.inkSecondary)
                .contentTransition(.numericText(value: Double(step.rawValue)))
                .animation(motion.snappy, value: step)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var choiceChips: some View {
        HStack(spacing: 8) {
            if let barber = model.selectedBarber, step.rawValue > BookingStep.barber.rawValue {
                ChoiceChip(text: barber.name, systemImage: "person.fill") { go(to: .barber) }
                    .transition(.scale(scale: 0.6, anchor: .leading).combined(with: .opacity))
            }
            if let service = model.selectedService, step.rawValue > BookingStep.service.rawValue {
                ChoiceChip(text: service.name, systemImage: "scissors") { go(to: .service) }
                    .transition(.scale(scale: 0.6, anchor: .leading).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 52)
        .padding(.horizontal, 20)
        .animation(motion.snappy, value: step)
    }

    // MARK: Steps

    @ViewBuilder
    private var stepContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(step.title)
                    .font(typography.display(40))
                    .tracking(-1)
                    .foregroundStyle(brandColors.ink)
                    .padding(.horizontal, 20)
                switch step {
                case .barber:
                    BarberChoices(model: model) { barber in choose(barber) }
                        .padding(.horizontal, 20)
                case .service:
                    ServiceChoices(services: model.services, selection: model.selectedService) { service in choose(service) }
                        .padding(.horizontal, 20)
                case .time:
                    TimeChooser(model: model) { slot in waitlistSlot = slot }
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
    }

    private var stepTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: isMovingForward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: isMovingForward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    @ViewBuilder
    private var waitlistToast: some View {
        if let entry = model.waitlistConfirmation {
            ToastView(systemImage: "bell.fill", title: "Te hemos apuntado", message: "Si se liberan las \(clockTime(entry.start)), te avisamos")
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
                .task(id: entry.id) {
                    try? await Task.sleep(for: .seconds(3))
                    model.dismissWaitlistConfirmation()
                }
        }
    }

    // MARK: Actions

    private func choose(_ barber: Barber) {
        withAnimation(motion.snappy) { model.selectedBarber = barber }
        advance(to: .service)
    }

    private func choose(_ service: ShopService) {
        withAnimation(motion.snappy) { model.selectedService = service }
        advance(to: .time)
    }

    /// Lets the selection land before the next step slides in.
    private func advance(to next: BookingStep) {
        Task {
            try? await Task.sleep(for: .milliseconds(280))
            go(to: next)
        }
    }

    private func go(to target: BookingStep) {
        guard target != step else { return }
        isMovingForward = target.rawValue > step.rawValue
        withAnimation(motion.page) { step = target }
    }

    private func goBackOrClose() {
        guard let previous = BookingStep(rawValue: step.rawValue - 1) else {
            onClose()
            return
        }
        go(to: previous)
    }

    private func closeIfConfirmed() {
        if case .confirmed = model.phase { onClose() }
    }

    private var isWaitlistAlertPresented: Binding<Bool> {
        Binding(get: { waitlistSlot != nil }, set: { if !$0 { waitlistSlot = nil } })
    }
}

private struct ChoiceChip: View {
    let text: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(brandColors.tintText)
                Text(text)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(brandColors.ink)
            }
            .padding(.horizontal, 12)
            .frame(height: 34)
            .surface(radius: 17)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityHint("Cambiar")
    }
}

private struct CheckoutBar: View {
    let model: BookingFlowModel
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(whenText)
                        .font(.headline)
                        .foregroundStyle(brandColors.ink)
                        .contentTransition(.numericText())
                    Text(whoText)
                        .font(.subheadline)
                        .foregroundStyle(brandColors.inkSecondary)
                }
                .animation(motion.snappy, value: whenText)
                Spacer()
                Text(euros(model.selectedService?.priceCents ?? 0))
                    .font(typography.numeral(26))
                    .foregroundStyle(brandColors.ink)
            }
            Button("Reservar · señal de \(euros(model.shop.depositCents))", action: onContinue)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(18)
        .surface(radius: 32, isRaised: true)
        .shadow(color: .black.opacity(0.6), radius: 30, y: 10)
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }

    private var whenText: String {
        guard let slot = model.selectedSlot else { return "" }
        return "\(shortDate(slot.start)) · \(clockTime(slot.start))"
    }

    private var whoText: String {
        guard let service = model.selectedService, let barber = model.selectedBarber else { return "" }
        return "\(service.name) con \(barber.name)"
    }
}
