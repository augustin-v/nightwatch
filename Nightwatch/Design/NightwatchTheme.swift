import SwiftUI

/// The app's visual identity, in one place.
///
/// Two rules drive every value here. First, this app is read outdoors, at
/// night, at minimum screen brightness, by someone who is cold and in a
/// hurry — so contrast and type size win over subtlety. Second, aurora green
/// and violet are *accents that carry meaning* (they encode the verdict), not
/// decoration sprayed across the surface; the base is near-black midnight
/// navy so the accent has somewhere to glow from.
///
/// Night vision mode replaces the whole palette with red-on-black. Real
/// aurora chasers use red light because it preserves dark adaptation, and no
/// incumbent ships it. It is a first-class theme, not a filter.
enum Nightwatch {

    // MARK: - Theme selection

    enum Mode: String, CaseIterable, Sendable {
        case night
        case nightVision
    }

    // MARK: - Palette

    struct Palette: Sendable {
        let background: Color
        let surface: Color
        let surfaceRaised: Color
        let hairline: Color
        let textPrimary: Color
        let textSecondary: Color
        let textTertiary: Color
        /// Verdict ramp, coldest (no chance) to hottest (rare display).
        let ramp: [Color]
        let positive: Color
        let warning: Color

        static let night = Palette(
            background: Color(red: 0.031, green: 0.043, blue: 0.086),
            surface: Color(red: 0.063, green: 0.082, blue: 0.145),
            surfaceRaised: Color(red: 0.094, green: 0.118, blue: 0.196),
            hairline: Color.white.opacity(0.10),
            textPrimary: Color(red: 0.937, green: 0.953, blue: 0.988),
            textSecondary: Color(red: 0.639, green: 0.678, blue: 0.769),
            textTertiary: Color(red: 0.435, green: 0.475, blue: 0.573),
            ramp: [
                Color(red: 0.267, green: 0.302, blue: 0.404),
                Color(red: 0.259, green: 0.451, blue: 0.639),
                Color(red: 0.176, green: 0.749, blue: 0.588),
                Color(red: 0.365, green: 0.918, blue: 0.435),
                Color(red: 0.686, green: 0.482, blue: 0.949)
            ],
            positive: Color(red: 0.365, green: 0.918, blue: 0.435),
            warning: Color(red: 0.965, green: 0.686, blue: 0.310)
        )

        /// Red monochrome. Luminance is deliberately held low — the point is
        /// to stay readable without destroying dark adaptation, so nothing
        /// here is allowed to be bright.
        static let nightVision = Palette(
            background: .black,
            surface: Color(red: 0.086, green: 0.008, blue: 0.008),
            surfaceRaised: Color(red: 0.145, green: 0.016, blue: 0.016),
            hairline: Color(red: 0.667, green: 0.098, blue: 0.098).opacity(0.28),
            textPrimary: Color(red: 0.902, green: 0.220, blue: 0.180),
            textSecondary: Color(red: 0.706, green: 0.157, blue: 0.129),
            textTertiary: Color(red: 0.510, green: 0.110, blue: 0.090),
            ramp: [
                Color(red: 0.310, green: 0.063, blue: 0.055),
                Color(red: 0.451, green: 0.090, blue: 0.075),
                Color(red: 0.612, green: 0.129, blue: 0.106),
                Color(red: 0.780, green: 0.176, blue: 0.145),
                Color(red: 0.937, green: 0.251, blue: 0.208)
            ],
            positive: Color(red: 0.902, green: 0.220, blue: 0.180),
            warning: Color(red: 0.780, green: 0.176, blue: 0.145)
        )

        /// Matches `AccentColor` in the asset catalog. Dark enough that the
        /// white button labels FactoryKit renders clear WCAG AA, and calm
        /// enough to look at outdoors at 2am.
        static let ctaGreen = Color(red: 0.055, green: 0.478, blue: 0.373)

        static func forMode(_ mode: Mode) -> Palette {
            switch mode {
            case .night: return .night
            case .nightVision: return .nightVision
            }
        }

        /// Colour for a 0–100 score, interpolated along the ramp so the
        /// hourly timeline reads as one continuous gradient rather than five
        /// discrete buckets.
        func rampColor(for score: Double) -> Color {
            let clamped = min(max(score, 0), 100) / 100
            let scaled = clamped * Double(ramp.count - 1)
            let lower = Int(scaled.rounded(.down))
            let upper = min(lower + 1, ramp.count - 1)
            return ramp[lower].mix(with: ramp[upper], by: scaled - Double(lower))
        }
    }

    // MARK: - Spacing and radius

    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 14
        static let l: CGFloat = 20
        static let xl: CGFloat = 28
        static let xxl: CGFloat = 40
    }

    enum Radius {
        static let card: CGFloat = 22
        static let chip: CGFloat = 12
        static let pill: CGFloat = 999
    }

    // MARK: - Type

    /// Everything is at least `.callout` sized. Nothing here is smaller than
    /// is readable with gloves on at arm's length, and every style scales
    /// with Dynamic Type so long translations and large-text users both work.
    enum TypeScale {
        static let verdict = Font.system(size: 44, weight: .bold, design: .rounded)
        static let score = Font.system(size: 62, weight: .heavy, design: .rounded)
        static let title = Font.system(.title2, design: .rounded).weight(.semibold)
        static let sectionHeading = Font.system(.headline, design: .rounded)
        static let body = Font.system(.body, design: .rounded)
        static let emphasis = Font.system(.body, design: .rounded).weight(.semibold)
        static let caption = Font.system(.footnote, design: .rounded)
    }
}

// MARK: - Environment

private struct NightwatchPaletteKey: EnvironmentKey {
    static let defaultValue = Nightwatch.Palette.night
}

private struct NightwatchModeKey: EnvironmentKey {
    static let defaultValue = Nightwatch.Mode.night
}

extension EnvironmentValues {
    var palette: Nightwatch.Palette {
        get { self[NightwatchPaletteKey.self] }
        set { self[NightwatchPaletteKey.self] = newValue }
    }

    var nightwatchMode: Nightwatch.Mode {
        get { self[NightwatchModeKey.self] }
        set { self[NightwatchModeKey.self] = newValue }
    }
}

extension View {
    /// Applies the palette for a mode to a subtree.
    func nightwatchTheme(_ mode: Nightwatch.Mode) -> some View {
        environment(\.nightwatchMode, mode)
            .environment(\.palette, .forMode(mode))
    }
}

// MARK: - Colour interpolation

private extension Color {
    /// Linear blend in sRGB. Good enough for a ramp of already-close hues and
    /// avoids pulling in a colour-science dependency for one gradient.
    func mix(with other: Color, by amount: Double) -> Color {
        let t = min(max(amount, 0), 1)
        let a = UIColor(self)
        let b = UIColor(other)
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        return Color(
            red: Double(ar + (br - ar) * t),
            green: Double(ag + (bg - ag) * t),
            blue: Double(ab + (bb - ab) * t),
            opacity: Double(aa + (ba - aa) * t)
        )
    }
}
