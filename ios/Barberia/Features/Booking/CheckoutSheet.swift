import PassKit
import SwiftUI

struct CheckoutSheet: View {
    @Bindable var model: BookingFlowModel
    var paysOnAppear = false
    let onDone: () -> Void

    @FocusState private var focusedField: Field?
    @State private var missingNameAttempts = 0
    @Environment(\.dismiss) private var dismiss

    private enum Field {
        case name
        case phone
    }

    var body: some View {
        ZStack {
            if case .confirmed(let appointment) = model.phase {
                ConfirmationView(model: model, appointment: appointment, onDone: onDone)
                    .transition(.opacity)
            } else {
                paymentForm
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(motion.gentle, value: model.phase)
        .presentationDetents([.large])
        .presentationCornerRadius(36)
        .presentationBackground(brandColors.ground)
        .interactiveDismissDisabled(model.phase == .paying)
        .onAppear {
            #if DEBUG
            guard paysOnAppear else { return }
            model.clientName = "Carlos"
            Task { await model.pay() }
            #endif
        }
    }

    private var paymentForm: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.bold))
                            .foregroundStyle(brandColors.ink)
                            .frame(width: 40, height: 40)
                            .background(brandColors.surface, in: Circle())
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityLabel("Cerrar")
                    .disabled(model.phase == .paying)
                    Spacer()
                }

                amountHeader.riseIn(0)
                summaryTicket.riseIn(1)
                contactFields.riseIn(2)

                if case .failed(let message) = model.phase {
                    Label(message, systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(brandColors.warning)
                        .transition(.opacity)
                }

                paymentButtons.riseIn(3)

                Label("Pago seguro con Stripe", systemImage: "lock.fill")
                    .font(.footnote)
                    .foregroundStyle(brandColors.inkSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .sensoryFeedback(.error, trigger: missingNameAttempts)
    }

    private var amountHeader: some View {
        VStack(spacing: 2) {
            Text("Paga ahora la señal")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(brandColors.inkSecondary)
            Text(euros(model.shop.depositCents))
                .font(typography.display(84))
                .tracking(-3)
                .foregroundStyle(brandColors.ink)
            Text("y \(euros(model.remainingCents)) en la barbería")
                .font(.subheadline)
                .foregroundStyle(brandColors.inkSecondary)
        }
    }

    @ViewBuilder
    private var summaryTicket: some View {
        if let barber = model.selectedBarber, let service = model.selectedService, let slot = model.selectedSlot {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Monogram(initial: barber.initial, size: 46, tone: brandColors.tone(at: model.barbers.firstIndex(of: barber) ?? 0))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(service.name)
                            .font(typography.numeral(20))
                            .foregroundStyle(brandColors.ink)
                        Text("con \(barber.name)")
                            .font(.subheadline)
                            .foregroundStyle(brandColors.inkSecondary)
                    }
                    Spacer()
                    Text(euros(service.priceCents))
                        .font(typography.numeral(20))
                        .foregroundStyle(brandColors.ink)
                }
                .padding(18)
                Line()
                    .stroke(brandColors.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                    .frame(height: 1)
                    .padding(.horizontal, 18)
                HStack {
                    Label(longDate(slot.start), systemImage: "calendar")
                    Spacer()
                    Label(clockTime(slot.start), systemImage: "clock")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(brandColors.ink)
                .padding(18)
            }
            .background {
                TicketShape(notchY: 82).fill(brandColors.surface)
            }
        }
    }

    private var contactFields: some View {
        VStack(spacing: 10) {
            BrandTextField(title: "Tu nombre", text: $model.clientName, isFocused: focusedField == .name)
                .textContentType(.name)
                .submitLabel(.next)
                .focused($focusedField, equals: .name)
                .onSubmit { focusedField = .phone }
            BrandTextField(title: "Teléfono (opcional)", text: $model.clientPhone, isFocused: focusedField == .phone)
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)
                .focused($focusedField, equals: .phone)
        }
        .modifier(ShakeEffect(shakes: CGFloat(missingNameAttempts)))
        .animation(.easeInOut(duration: 0.4), value: missingNameAttempts)
    }

    @ViewBuilder
    private var paymentButtons: some View {
        if model.phase == .paying {
            HStack(spacing: 12) {
                ProgressView()
                    .tint(.white)
                Text("Procesando el pago…")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(brandColors.tint, in: Capsule())
            .transition(.opacity.combined(with: .scale(scale: 0.92)))
        } else {
            VStack(spacing: 8) {
                PayWithApplePayButton(.book, action: startPayment)
                    .payWithApplePayButtonStyle(.white)
                    .frame(height: 58)
                    .clipShape(Capsule())
                Button("Pagar con tarjeta", action: startPayment)
                    .font(.headline)
                    .foregroundStyle(brandColors.tintText)
                    .frame(height: 44)
            }
            .transition(.opacity)
        }
    }

    private func startPayment() {
        guard model.hasClientName else {
            focusedField = .name
            missingNameAttempts += 1
            return
        }
        focusedField = nil
        model.clearFailure()
        Task { await model.pay() }
    }
}

/// A text field drawn on a Navaja surface, with a red edge while you type.
private struct BrandTextField: View {
    let title: String
    @Binding var text: String
    let isFocused: Bool

    var body: some View {
        TextField(title, text: $text, prompt: Text(title).foregroundStyle(brandColors.inkTertiary))
            .font(.body.weight(.medium))
            .foregroundStyle(brandColors.ink)
            .padding(.horizontal, 18)
            .frame(height: 56)
            .background(brandColors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isFocused ? brandColors.tint : brandColors.hairline, lineWidth: isFocused ? 2 : 1)
            }
            .animation(motion.snappy, value: isFocused)
    }
}

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
    }
}

/// A short sideways shake, for "this field is missing".
private struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(shakes * .pi * 4), y: 0))
    }
}
