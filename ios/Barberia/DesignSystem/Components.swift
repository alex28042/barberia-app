import SwiftUI

// MARK: - Surfaces and buttons

/// Navaja's card: a dark surface with a hairline edge that turns red when chosen.
struct Surface: ViewModifier {
    var radius: CGFloat = 26
    var isRaised = false
    var isHighlighted = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background(isHighlighted ? AnyShapeStyle(brandColors.tintSoft) : AnyShapeStyle(isRaised ? brandColors.surfaceRaised : brandColors.surface), in: shape)
            .overlay {
                shape.strokeBorder(isHighlighted ? brandColors.tint : brandColors.hairline, lineWidth: isHighlighted ? 2 : 1)
            }
    }
}

/// The big red call to action.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(brandColors.tint, in: Capsule())
            .overlay(Capsule().strokeBorder(.white.opacity(0.12), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .opacity(isEnabled ? 1 : 0.4)
            .animation(motion.snappy, value: configuration.isPressed)
    }
}

/// Scales down a touch while pressed, so every tap feels physical.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(motion.snappy, value: configuration.isPressed)
    }
}

// MARK: - Entrance animations

/// Lifts a block in from slightly below, a little after the one before it.
struct RiseIn: ViewModifier {
    let index: Int
    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible || reduceMotion ? 0 : 22)
            .blur(radius: isVisible || reduceMotion ? 0 : 6)
            .onAppear {
                withAnimation(motion.gentle.delay(Double(index) * 0.07)) { isVisible = true }
            }
    }
}

/// Pops a small element in, a little after the one before it.
struct StaggeredAppear: ViewModifier {
    let index: Int
    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible || reduceMotion ? 1 : 0.8)
            .onAppear {
                withAnimation(motion.snappy.delay(Double(index) * 0.025)) { isVisible = true }
            }
    }
}

extension View {
    func surface(radius: CGFloat = 26, isRaised: Bool = false, isHighlighted: Bool = false) -> some View {
        modifier(Surface(radius: radius, isRaised: isRaised, isHighlighted: isHighlighted))
    }

    func riseIn(_ index: Int) -> some View {
        modifier(RiseIn(index: index))
    }

    func staggeredAppear(index: Int) -> some View {
        modifier(StaggeredAppear(index: index))
    }
}

// MARK: - Small pieces

struct SectionTitle: View {
    let title: String
    var detail: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(typography.numeral(22))
                .foregroundStyle(brandColors.ink)
            Spacer()
            if let detail {
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(brandColors.inkSecondary)
            }
        }
    }
}

/// A barber's initial on their own colour.
struct Monogram: View {
    let initial: String
    let size: CGFloat
    let tone: Color

    var body: some View {
        Text(initial)
            .font(typography.display(size * 0.46))
            .foregroundStyle(brandColors.ink)
            .frame(width: size, height: size)
            .background(tone, in: Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.1), lineWidth: 1))
    }
}

struct PulsingDot: View {
    let color: Color
    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .background {
                Circle()
                    .fill(color.opacity(0.5))
                    .scaleEffect(isPulsing ? 2.6 : 1)
                    .opacity(isPulsing ? 0 : 1)
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeOut(duration: 1.6).repeatForever(autoreverses: false)) { isPulsing = true }
            }
    }
}

/// The dotted line between a dish and its price on a menu board.
struct DottedLeader: View {
    var body: some View {
        GeometryReader { proxy in
            Path { path in
                path.move(to: CGPoint(x: 0, y: proxy.size.height / 2))
                path.addLine(to: CGPoint(x: proxy.size.width, y: proxy.size.height / 2))
            }
            .stroke(brandColors.inkTertiary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [0.1, 6]))
        }
        .frame(height: 2)
    }
}

/// A slow red glow that breathes behind the top of a screen.
struct AmbientGlow: View {
    @State private var isBreathing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [brandColors.tint.opacity(0.45), brandColors.tint.opacity(0)], center: .center, startRadius: 0, endRadius: 220))
            .frame(width: 440, height: 440)
            .scaleEffect(isBreathing ? 1.12 : 0.92)
            .blur(radius: 30)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) { isBreathing = true }
            }
            .accessibilityHidden(true)
    }
}

/// A ticket: a rounded card with a notch bitten out of each side.
struct TicketShape: Shape {
    /// Where the notches sit, from the top.
    var notchY: CGFloat
    var radius: CGFloat = 26
    var notchRadius: CGFloat = 12

    func path(in rect: CGRect) -> Path {
        var notches = Path()
        notches.addEllipse(in: CGRect(x: rect.minX - notchRadius, y: rect.minY + notchY - notchRadius, width: notchRadius * 2, height: notchRadius * 2))
        notches.addEllipse(in: CGRect(x: rect.maxX - notchRadius, y: rect.minY + notchY - notchRadius, width: notchRadius * 2, height: notchRadius * 2))
        return Path(roundedRect: rect, cornerRadius: radius, style: .continuous).subtracting(notches)
    }
}

struct ToastView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(brandColors.tint, in: Circle())
                .symbolEffect(.wiggle, options: .nonRepeating)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(brandColors.ink)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(brandColors.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .surface(radius: 24, isRaised: true)
        .shadow(color: .black.opacity(0.6), radius: 24, y: 12)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - The barber's pole

/// The shop's mark: a barber's pole whose stripes keep turning.
struct BarberPole: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
            Canvas { canvas, size in
                let stripeWidth = max(size.width * 0.42, 4)
                let colors: [Color] = [brandColors.tint, .white, Color(white: 0.3), .white]
                let period = stripeWidth * CGFloat(colors.count)
                let seconds = reduceMotion ? 0 : context.date.timeIntervalSinceReferenceDate
                let phase = CGFloat(seconds.truncatingRemainder(dividingBy: 3) / 3) * period
                let first = Int(((-size.height - period) / stripeWidth).rounded(.down))
                let last = Int((size.width / stripeWidth).rounded(.up)) + 1
                for index in first...last {
                    let x = CGFloat(index) * stripeWidth + phase
                    var stripe = Path()
                    stripe.move(to: CGPoint(x: x, y: size.height))
                    stripe.addLine(to: CGPoint(x: x + stripeWidth, y: size.height))
                    stripe.addLine(to: CGPoint(x: x + stripeWidth + size.height, y: 0))
                    stripe.addLine(to: CGPoint(x: x + size.height, y: 0))
                    stripe.closeSubpath()
                    canvas.fill(stripe, with: .color(colors[((index % colors.count) + colors.count) % colors.count]))
                }
            }
        }
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }
}

// MARK: - Confetti

/// Barber-pole confetti for the moment a booking is confirmed.
struct ConfettiView: View {
    let startDate: Date
    private let pieces: [ConfettiPiece]
    private let lifetime: TimeInterval = 3.2

    init(startDate: Date, count: Int = 70) {
        self.startDate = startDate
        var random = SeededRandom(seed: UInt64(startDate.timeIntervalSince1970))
        let colors: [Color] = [brandColors.tint, brandColors.ink, Color(white: 0.45), brandColors.tintText]
        pieces = (0..<count).map { _ in
            ConfettiPiece(
                x: Double.random(in: 0...1, using: &random),
                delay: Double.random(in: 0...0.5, using: &random),
                fallSpeed: Double.random(in: 260...460, using: &random),
                sway: Double.random(in: 10...36, using: &random),
                spin: Double.random(in: 2...7, using: &random),
                width: Double.random(in: 6...10, using: &random),
                height: Double.random(in: 12...20, using: &random),
                color: colors.randomElement(using: &random) ?? brandColors.tint
            )
        }
    }

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { canvas, size in
                let elapsed = context.date.timeIntervalSince(startDate)
                guard elapsed < lifetime else { return }
                for piece in pieces {
                    let t = elapsed - piece.delay
                    guard t > 0 else { continue }
                    let y = -30 + piece.fallSpeed * t + 90 * t * t
                    let x = piece.x * size.width + sin(t * 3 + piece.x * 10) * piece.sway
                    let fade = min(1, max(0, (lifetime - elapsed) / 0.8))
                    var transform = canvas
                    transform.translateBy(x: x, y: y)
                    transform.rotate(by: .radians(t * piece.spin))
                    transform.opacity = fade
                    let rect = CGRect(x: -piece.width / 2, y: -piece.height / 2, width: piece.width, height: piece.height * abs(cos(t * piece.spin)))
                    transform.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(piece.color))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct ConfettiPiece {
    let x: Double
    let delay: Double
    let fallSpeed: Double
    let sway: Double
    let spin: Double
    let width: Double
    let height: Double
    let color: Color
}

// MARK: - Tab bar

enum AppTab: Hashable {
    case booking
    case dashboard
}

/// A floating capsule; the chosen tab grows into a red pill with its name.
struct BrandTabBar: View {
    @Binding var selection: AppTab
    @Namespace private var highlight

    var body: some View {
        HStack(spacing: 4) {
            item(.booking, title: "Reservar", systemImage: "scissors")
            item(.dashboard, title: "Panel", systemImage: "chart.bar.fill")
        }
        .padding(5)
        .background(brandColors.surfaceRaised, in: Capsule())
        .overlay(Capsule().strokeBorder(brandColors.hairline))
        .shadow(color: .black.opacity(0.55), radius: 24, y: 10)
        .padding(.bottom, 2)
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func item(_ tab: AppTab, title: String, systemImage: String) -> some View {
        let isSelected = selection == tab
        return Button {
            withAnimation(motion.snappy) { selection = tab }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.body.weight(.semibold))
                    .symbolEffect(.bounce, value: isSelected)
                if isSelected {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .transition(.opacity.combined(with: .scale(scale: 0.6, anchor: .leading)))
                }
            }
            .foregroundStyle(isSelected ? .white : brandColors.inkSecondary)
            .padding(.horizontal, isSelected ? 20 : 18)
            .frame(height: 48)
            .background {
                if isSelected {
                    Capsule()
                        .fill(brandColors.tint)
                        .matchedGeometryEffect(id: "selectedTab", in: highlight)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
