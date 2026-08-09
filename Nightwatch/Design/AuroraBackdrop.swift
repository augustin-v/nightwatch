import SwiftUI

/// The aurora, drawn rather than photographed.
///
/// A stock photo would be a licensing liability and would look like every
/// other app in the category; baked-in text over an image would also break
/// STANDARDS §11. So the backdrop is generated: three soft vertical curtains
/// over a midnight gradient, drifting slowly enough to feel alive without
/// competing with the copy the user is trying to read.
///
/// `intensity` lets a screen dial it down to near-nothing, so this stays a
/// hierarchy tool rather than decoration applied uniformly everywhere.
struct AuroraBackdrop: View {
    var intensity: Double = 1.0
    var animated: Bool = true

    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: !animated || reduceMotion)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate

                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(
                        Gradient(colors: [palette.surface, palette.background]),
                        startPoint: .zero,
                        endPoint: CGPoint(x: 0, y: size.height)
                    )
                )

                for (index, curtain) in Self.curtains.enumerated() {
                    let drift = reduceMotion ? 0 : sin(t * curtain.speed + Double(index)) * 40
                    let centerX = size.width * curtain.center + drift
                    let width = size.width * curtain.width

                    var path = Path()
                    path.move(to: CGPoint(x: centerX - width / 2, y: -20))
                    path.addQuadCurve(
                        to: CGPoint(x: centerX + width / 2, y: -20),
                        control: CGPoint(x: centerX, y: -40)
                    )
                    path.addLine(to: CGPoint(x: centerX + width / 2 + 30, y: size.height * curtain.reach))
                    path.addQuadCurve(
                        to: CGPoint(x: centerX - width / 2 - 30, y: size.height * curtain.reach),
                        control: CGPoint(x: centerX, y: size.height * curtain.reach + 60)
                    )
                    path.closeSubpath()

                    context.fill(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [
                                curtain.color(palette).opacity(0.30 * intensity),
                                curtain.color(palette).opacity(0.0)
                            ]),
                            startPoint: .zero,
                            endPoint: CGPoint(x: 0, y: size.height * curtain.reach)
                        )
                    )
                }
            }
            .blur(radius: 32)
            .drawingGroup()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private struct Curtain {
        let center: Double
        let width: Double
        let reach: Double
        let speed: Double
        let rampIndex: Int

        func color(_ palette: Nightwatch.Palette) -> Color {
            palette.ramp[min(rampIndex, palette.ramp.count - 1)]
        }
    }

    private static let curtains: [Curtain] = [
        Curtain(center: 0.28, width: 0.42, reach: 0.62, speed: 0.11, rampIndex: 2),
        Curtain(center: 0.62, width: 0.34, reach: 0.48, speed: 0.08, rampIndex: 3),
        Curtain(center: 0.80, width: 0.28, reach: 0.38, speed: 0.14, rampIndex: 4)
    ]
}

/// Applies the app's night identity to a screen that renders inside one of
/// FactoryKit's shared shells. The shells own their own layout and chrome, so
/// this reaches them the only ways it can without forking the package: a dark
/// colour scheme (which retints their `.secondary` text and system chrome) and
/// a tint (which recolours their `Color.accentColor` buttons).
struct NightSurface<Content: View>: View {
    var intensity: Double = 1.0
    @ViewBuilder var content: Content

    private let palette = Nightwatch.Palette.night

    var body: some View {
        ZStack {
            palette.background.ignoresSafeArea()
            AuroraBackdrop(intensity: intensity)
            content
        }
        .nightwatchTheme(.night)
        .tint(palette.ramp[3])
        .preferredColorScheme(.dark)
    }
}
