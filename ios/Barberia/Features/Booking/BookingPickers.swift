import SwiftUI

struct BarberChoices: View {
    let model: BookingFlowModel
    let onChoose: (Barber) -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(model.barbers.enumerated()), id: \.element.id) { index, barber in
                let isSelected = barber == model.selectedBarber
                Button {
                    onChoose(barber)
                } label: {
                    HStack(spacing: 16) {
                        Monogram(initial: barber.initial, size: 62, tone: brandColors.tone(at: index))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(barber.name)
                                .font(typography.numeral(24))
                                .foregroundStyle(brandColors.ink)
                            Text(barber.specialty)
                                .font(.subheadline)
                                .foregroundStyle(brandColors.inkSecondary)
                            if let free = model.nextFreeStart(with: barber) {
                                Label("Libre \(model.phrase(for: free))", systemImage: "clock")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(brandColors.open)
                                    .padding(.top, 2)
                            }
                        }
                        Spacer()
                        SelectionMark(isSelected: isSelected)
                    }
                    .padding(16)
                    .surface(isHighlighted: isSelected)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .riseIn(index)
            }
        }
        .sensoryFeedback(.selection, trigger: model.selectedBarber)
    }
}

struct ServiceChoices: View {
    let services: [ShopService]
    let selection: ShopService?
    let onChoose: (ShopService) -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach(Array(services.enumerated()), id: \.element.id) { index, service in
                let isSelected = service == selection
                Button {
                    onChoose(service)
                } label: {
                    HStack(alignment: .center, spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(service.name)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(brandColors.ink)
                            Label("\(service.durationMinutes) min", systemImage: "clock")
                                .font(.subheadline)
                                .foregroundStyle(brandColors.inkSecondary)
                        }
                        Spacer()
                        Text(euros(service.priceCents))
                            .font(typography.display(30))
                            .foregroundStyle(isSelected ? brandColors.tintText : brandColors.ink)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                    .surface(isHighlighted: isSelected)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableButtonStyle())
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .riseIn(index)
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

private struct SelectionMark: View {
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(brandColors.inkTertiary, lineWidth: 1.5)
            if isSelected {
                Circle().fill(brandColors.tint)
                    .transition(.scale)
                Image(systemName: "checkmark")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 28, height: 28)
        .animation(motion.bouncy, value: isSelected)
    }
}

struct TimeChooser: View {
    @Bindable var model: BookingFlowModel
    let onTakenSlot: (TimeSlot) -> Void
    @Namespace private var highlight

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            dayStrip
            VStack(alignment: .leading, spacing: 22) {
                if model.slots.isEmpty {
                    Text("Este día ya no quedan horas. Prueba con otro.")
                        .font(.subheadline)
                        .foregroundStyle(brandColors.inkSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .surface()
                } else {
                    period("Mañana", systemImage: "sun.max.fill", slots: morningSlots, offset: 0)
                    period("Tarde", systemImage: "sunset.fill", slots: afternoonSlots, offset: morningSlots.count)
                    Label("¿Tu hora está cogida? Tócala y te avisamos si se libera.", systemImage: "bell")
                        .font(.footnote)
                        .foregroundStyle(brandColors.inkSecondary)
                }
            }
            .id(slotIdentity)
            .padding(.horizontal, 20)
        }
        .sensoryFeedback(.selection, trigger: model.selectedSlot)
        .sensoryFeedback(.selection, trigger: model.selectedDay)
    }

    private var dayStrip: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Array(model.bookableDays.enumerated()), id: \.element) { index, day in
                    let isSelected = day == model.selectedDay
                    Button {
                        withAnimation(motion.snappy) { model.selectedDay = day }
                    } label: {
                        VStack(spacing: 4) {
                            Text(weekdayShort(day).uppercased())
                                .font(.caption2.weight(.bold))
                                .tracking(0.8)
                                .foregroundStyle(isSelected ? .white.opacity(0.85) : brandColors.inkSecondary)
                            Text(dayNumber(day))
                                .font(typography.display(26))
                                .foregroundStyle(isSelected ? .white : brandColors.ink)
                        }
                        .frame(width: 60, height: 78)
                        .background {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(brandColors.surface)
                                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(brandColors.hairline))
                            if isSelected {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(brandColors.tint)
                                    .matchedGeometryEffect(id: "selectedDay", in: highlight)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityLabel(longDate(day))
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                    .staggeredAppear(index: index)
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }

    private func period(_ title: String, systemImage: String, slots: [TimeSlot], offset: Int) -> some View {
        Group {
            if !slots.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label(title, systemImage: systemImage)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(brandColors.inkSecondary)
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(Array(slots.enumerated()), id: \.element.id) { index, slot in
                            slotButton(slot)
                                .staggeredAppear(index: offset + index)
                        }
                    }
                }
            }
        }
    }

    private func slotButton(_ slot: TimeSlot) -> some View {
        let isSelected = slot == model.selectedSlot
        return Button {
            if slot.isAvailable {
                withAnimation(motion.snappy) { model.selectedSlot = slot }
            } else {
                onTakenSlot(slot)
            }
        } label: {
            Text(clockTime(slot.start))
                .font(.body.weight(isSelected ? .bold : .semibold))
                .monospacedDigit()
                .strikethrough(!slot.isAvailable, color: brandColors.inkTertiary)
                .foregroundStyle(isSelected ? .white : slot.isAvailable ? brandColors.ink : brandColors.inkTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(brandColors.tint)
                            .matchedGeometryEffect(id: "selectedSlot", in: highlight)
                    } else if slot.isAvailable {
                        Capsule()
                            .fill(brandColors.surface)
                            .overlay(Capsule().strokeBorder(brandColors.hairline))
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(slot.isAvailable ? clockTime(slot.start) : "\(clockTime(slot.start)), cogida")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var morningSlots: [TimeSlot] { model.slots.filter { hour(of: $0) < 15 } }
    private var afternoonSlots: [TimeSlot] { model.slots.filter { hour(of: $0) >= 15 } }

    private func hour(of slot: TimeSlot) -> Int {
        Calendar.current.component(.hour, from: slot.start)
    }

    /// Changes whenever the day, barber or service does, so the hours animate in again.
    private var slotIdentity: String {
        "\(model.selectedDay.timeIntervalSince1970)-\(model.selectedBarber?.id ?? "")-\(model.selectedService?.id ?? "")"
    }
}
