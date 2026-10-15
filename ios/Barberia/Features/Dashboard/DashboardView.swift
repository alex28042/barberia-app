import SwiftUI

struct DashboardView: View {
    @Bindable var model: DashboardModel
    @State private var chartProgress = 0.0
    @State private var appointmentToCancel: Appointment?
    @Namespace private var filterHighlight

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header.riseIn(0)
                filters.riseIn(1)
                RevenueCard(
                    days: model.weekRevenue,
                    totalCents: model.weekTotalCents,
                    changePercent: model.weekChangePercent,
                    today: model.today,
                    progress: chartProgress
                )
                .riseIn(2)
                HStack(spacing: 12) {
                    StatTile(value: model.agenda.count, label: "citas hoy", systemImage: "scissors")
                    StatTile(value: model.waitlistCount, label: "en lista de espera", systemImage: "bell.fill")
                }
                .riseIn(3)
                agenda.riseIn(4)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background(brandColors.ground.ignoresSafeArea())
        .overlay(alignment: .bottom) { noticeToast }
        .animation(motion.snappy, value: model.notice)
        .animation(motion.gentle, value: model.barberFilter)
        .sensoryFeedback(.success, trigger: model.notice) { _, notice in notice != nil }
        .sensoryFeedback(.selection, trigger: model.barberFilter)
        .onAppear(perform: growChart)
        .onChange(of: model.barberFilter) { growChart() }
        .confirmationDialog(
            appointmentToCancel.map { "¿Cancelar la cita de \($0.clientName)?" } ?? "",
            isPresented: isCancelDialogPresented,
            titleVisibility: .visible,
            presenting: appointmentToCancel
        ) { appointment in
            Button("Cancelar cita", role: .destructive) {
                withAnimation(motion.gentle) { model.cancel(appointment) }
            }
            Button("Mantener", role: .cancel) {}
        } message: { appointment in
            Text("\(appointment.service.name) a las \(clockTime(appointment.start)) con \(appointment.barber.name). Si hay alguien en lista de espera, le avisamos.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(longDate(model.today))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(brandColors.inkSecondary)
            Text("Hoy")
                .font(typography.display(56))
                .tracking(-1.4)
                .foregroundStyle(brandColors.ink)
        }
    }

    private var filters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                filterChip("Todos", barber: nil)
                ForEach(model.barbers) { barber in
                    filterChip(barber.name, barber: barber)
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }

    private func filterChip(_ title: String, barber: Barber?) -> some View {
        let isSelected = model.barberFilter == barber
        return Button {
            withAnimation(motion.snappy) { model.barberFilter = barber }
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : brandColors.ink)
                .padding(.horizontal, 18)
                .frame(height: 40)
                .background {
                    Capsule().fill(brandColors.surface).overlay(Capsule().strokeBorder(brandColors.hairline))
                    if isSelected {
                        Capsule()
                            .fill(brandColors.tint)
                            .matchedGeometryEffect(id: "selectedFilter", in: filterHighlight)
                    }
                }
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var agenda: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(title: "Agenda", detail: model.agenda.isEmpty ? nil : "Toca una cita para cancelarla")
            if !model.isOpenToday {
                emptyAgenda("Hoy no se abre", systemImage: "moon.zzz.fill")
            } else if model.agenda.isEmpty {
                emptyAgenda("No hay citas para hoy", systemImage: "calendar")
            } else {
                VStack(spacing: 0) {
                    ForEach(model.agenda) { appointment in
                        let status = model.status(of: appointment)
                        AgendaRow(appointment: appointment, status: status, tone: tone(for: appointment.barber)) {
                            appointmentToCancel = appointment
                        }
                        .disabled(status != .upcoming)
                        .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var noticeToast: some View {
        if let notice = model.notice {
            ToastView(systemImage: "bell.fill", title: notice.title, message: notice.message)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .task(id: notice.id) {
                    try? await Task.sleep(for: .seconds(4))
                    model.dismissNotice()
                }
        }
    }

    private func emptyAgenda(_ text: String, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(brandColors.inkSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .surface()
    }

    private func tone(for barber: Barber) -> Color {
        brandColors.tone(at: model.barbers.firstIndex(of: barber) ?? 0)
    }

    private var isCancelDialogPresented: Binding<Bool> {
        Binding(get: { appointmentToCancel != nil }, set: { if !$0 { appointmentToCancel = nil } })
    }

    private func growChart() {
        chartProgress = 0
        withAnimation(.spring(response: 1.1, dampingFraction: 0.9).delay(0.15)) {
            chartProgress = 1
        }
    }
}

private struct RevenueCard: View {
    let days: [DailyRevenue]
    let totalCents: Int
    let changePercent: Int?
    let today: Date
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Facturado en 7 días")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(brandColors.inkSecondary)
                    CountingEuros(cents: Double(totalCents) * progress)
                        .font(typography.display(44))
                        .tracking(-1.2)
                        .foregroundStyle(brandColors.ink)
                }
                Spacer()
                if let changePercent {
                    let color = changePercent >= 0 ? brandColors.open : brandColors.warning
                    Label("\(changePercent >= 0 ? "+" : "")\(changePercent) %", systemImage: changePercent >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(color)
                        .padding(.horizontal, 10)
                        .frame(height: 30)
                        .background(color.opacity(0.14), in: Capsule())
                }
            }
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                    let isToday = Calendar.current.isDate(day.day, inSameDayAs: today)
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isToday ? AnyShapeStyle(LinearGradient(colors: [brandColors.tintText, brandColors.tint], startPoint: .top, endPoint: .bottom)) : AnyShapeStyle(brandColors.tintSoft))
                            .frame(height: max(6, 120 * ratio(of: day) * progress))
                            .animation(.spring(response: 0.8, dampingFraction: 0.78).delay(Double(index) * 0.06), value: progress)
                        Text(weekdayInitial(day.day))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(isToday ? brandColors.ink : brandColors.inkTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(longDate(day.day)): \(euros(day.cents))")
                }
            }
            .frame(height: 146, alignment: .bottom)
        }
        .padding(20)
        .surface(radius: 30)
    }

    private func ratio(of day: DailyRevenue) -> Double {
        let highest = days.map(\.cents).max() ?? 0
        return highest > 0 ? Double(day.cents) / Double(highest) : 0
    }
}

/// Euros that count up as the value animates.
private struct CountingEuros: View, Animatable {
    var cents: Double

    nonisolated var animatableData: Double {
        get { cents }
        set { cents = newValue }
    }

    var body: some View {
        Text(euros(Int(cents / 100) * 100))
            .monospacedDigit()
    }
}

private struct StatTile: View {
    let value: Int
    let label: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(brandColors.tintText)
                .frame(width: 34, height: 34)
                .background(brandColors.tintSoft, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 0) {
                Text("\(value)")
                    .font(typography.display(34, relativeTo: .title))
                    .foregroundStyle(brandColors.ink)
                    .contentTransition(.numericText(value: Double(value)))
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(brandColors.inkSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .surface(radius: 24)
        .animation(motion.snappy, value: value)
    }
}

private struct AgendaRow: View {
    let appointment: Appointment
    let status: AgendaStatus
    let tone: Color
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(clockTime(appointment.start))
                .font(typography.numeral(17))
                .monospacedDigit()
                .foregroundStyle(status == .inProgress ? brandColors.tintText : brandColors.ink)
                .frame(width: 50, alignment: .leading)
                .padding(.top, 19)

            VStack(spacing: 0) {
                marker
                    .padding(.top, 23)
                Rectangle()
                    .fill(brandColors.hairline)
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 12)

            Button(action: onTap) {
                HStack(spacing: 12) {
                    Monogram(initial: appointment.barber.initial, size: 34, tone: tone)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(appointment.clientName)
                                .font(.headline)
                                .foregroundStyle(brandColors.ink)
                            if status == .inProgress {
                                Text("AHORA")
                                    .font(.caption2.weight(.heavy))
                                    .tracking(0.6)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 7)
                                    .frame(height: 18)
                                    .background(brandColors.tint, in: Capsule())
                            }
                        }
                        Text(appointment.service.name)
                            .font(.subheadline)
                            .foregroundStyle(brandColors.inkSecondary)
                    }
                    Spacer(minLength: 4)
                    Text(euros(appointment.service.priceCents))
                        .font(typography.numeral(17))
                        .foregroundStyle(brandColors.ink)
                }
                .padding(14)
                .surface(radius: 22, isHighlighted: status == .inProgress)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.bottom, 10)
        }
        .opacity(status == .past ? 0.38 : 1)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var marker: some View {
        switch status {
        case .past:
            Circle().fill(brandColors.inkTertiary).frame(width: 10, height: 10)
        case .inProgress:
            PulsingDot(color: brandColors.tint)
        case .upcoming:
            Circle().strokeBorder(brandColors.ink.opacity(0.6), lineWidth: 2).frame(width: 10, height: 10)
        }
    }
}
