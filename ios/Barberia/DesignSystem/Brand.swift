import SwiftUI

/// Navaja's palette: a warm near-black, one barbershop red and a warm white for text.
struct BrandColors {
    let ground = Color(red: 10 / 255, green: 10 / 255, blue: 11 / 255)
    let surface = Color(red: 22 / 255, green: 22 / 255, blue: 24 / 255)
    let surfaceRaised = Color(red: 31 / 255, green: 31 / 255, blue: 34 / 255)
    let hairline = Color.white.opacity(0.08)

    let ink = Color(red: 245 / 255, green: 242 / 255, blue: 236 / 255)
    let inkSecondary = Color(red: 245 / 255, green: 242 / 255, blue: 236 / 255).opacity(0.58)
    let inkTertiary = Color(red: 245 / 255, green: 242 / 255, blue: 236 / 255).opacity(0.3)

    /// Barbershop red, tuned so white text on it and it on black both pass 4.5:1.
    let tint = Color(red: 217 / 255, green: 58 / 255, blue: 38 / 255)
    /// The same red, lighter, for text and icons on dark surfaces.
    let tintText = Color(red: 236 / 255, green: 124 / 255, blue: 108 / 255)
    let tintSoft = Color(red: 217 / 255, green: 58 / 255, blue: 38 / 255).opacity(0.2)

    let open = Color(red: 74 / 255, green: 222 / 255, blue: 128 / 255)
    let warning = Color(red: 255 / 255, green: 176 / 255, blue: 72 / 255)

    /// One quiet colour per barber, so each one is recognisable at a glance.
    let barberTones = [
        Color(red: 0.42, green: 0.15, blue: 0.11),
        Color(red: 0.13, green: 0.27, blue: 0.22),
        Color(red: 0.23, green: 0.19, blue: 0.34),
    ]

    func tone(at index: Int) -> Color {
        barberTones[index % barberTones.count]
    }
}

let brandColors = BrandColors()

/// Bricolage Grotesque for titles and numbers; SF Pro for reading.
struct BrandTypography {
    func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
        .custom("BricolageGrotesque-48ptExtraBold", size: size, relativeTo: style)
    }

    func numeral(_ size: CGFloat, relativeTo style: Font.TextStyle = .title3) -> Font {
        .custom("BricolageGrotesque-24ptBold", size: size, relativeTo: style)
    }
}

let typography = BrandTypography()

struct Motion {
    /// Selections: quick, with a little give.
    let snappy = Animation.spring(response: 0.32, dampingFraction: 0.78)
    /// Things entering or leaving the screen.
    let gentle = Animation.spring(response: 0.5, dampingFraction: 0.86)
    /// The success moment.
    let bouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
    /// Moving between booking steps.
    let page = Animation.spring(response: 0.45, dampingFraction: 0.88)
}

let motion = Motion()
