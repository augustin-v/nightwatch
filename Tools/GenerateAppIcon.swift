import AppKit
import CoreGraphics

// Nightwatch app icon. It has to survive being 40pt on a home screen, so it is
// one idea only: an aurora curtain over a dark ridge. Curtains are what make an
// aurora legible as an aurora — vertical striations rising from a curved base,
// green at the bottom, violet at the tips — so that is the structure, not a
// smooth ribbon.
let size = 1024.0
let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: Int(size), height: Int(size),
                          bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { exit(1) }
func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(colorSpace: cs, components: [r, g, b, a])!
}

let bg = CGGradient(colorsSpace: cs, colors: [
    rgb(0.063, 0.086, 0.157), rgb(0.012, 0.020, 0.047)
] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(bg, start: CGPoint(x: 0, y: size), end: CGPoint(x: 0, y: 0), options: [])

// A few faint stars, small enough to disappear gracefully at icon size.
for (sx, sy, r) in [(0.80, 0.86, 7.0), (0.66, 0.92, 5.0), (0.88, 0.74, 4.0), (0.22, 0.90, 5.0)] {
    ctx.setFillColor(rgb(0.937, 0.953, 0.988, 0.75))
    ctx.fillEllipse(in: CGRect(x: size * sx, y: size * sy, width: r * 2, height: r * 2))
}

// Base curve the curtain hangs from.
func baseY(_ t: Double) -> Double {
    size * (0.13 + 0.05 * sin(t * .pi * 1.15 + 0.35))
}

ctx.setBlendMode(.plusLighter)
let rayCount = 240
for i in 0..<rayCount {
    let t = Double(i) / Double(rayCount - 1)
    let x = -30 + t * (size + 60)
    let y0 = baseY(t)

    // Height varies with two out-of-phase waves so the curtain has structure
    // instead of a flat top edge.
    let heightFactor = 0.55 + 0.45 * abs(sin(t * .pi * 3.1 + 1.2)) * (0.6 + 0.4 * sin(t * .pi * 7.3))
    let h = size * 0.52 * max(0.30, heightFactor)
    let w = size / Double(rayCount) * 2.4
    let alpha = 0.21 * (0.55 + 0.45 * abs(sin(t * .pi * 5.7 + 0.6)))

    let g = CGGradient(colorsSpace: cs, colors: [
        rgb(0.176, 0.749, 0.588, alpha * 1.15),
        rgb(0.365, 0.918, 0.435, alpha),
        rgb(0.686, 0.482, 0.949, alpha * 0.75),
        rgb(0.686, 0.482, 0.949, 0.0)
    ] as CFArray, locations: [0, 0.52, 0.86, 1])!

    ctx.saveGState()
    ctx.clip(to: CGRect(x: x - w / 2, y: y0, width: w, height: h))
    ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: y0),
                           end: CGPoint(x: 0, y: y0 + h), options: [])
    ctx.restoreGState()
}

ctx.setBlendMode(.normal)

// Ridge silhouette: gives the sky a ground and makes the icon read as a place.
let ridge = CGMutablePath()
ridge.move(to: CGPoint(x: 0, y: 0))
ridge.addLine(to: CGPoint(x: 0, y: size * 0.26))
ridge.addLine(to: CGPoint(x: size * 0.20, y: size * 0.31))
ridge.addLine(to: CGPoint(x: size * 0.34, y: size * 0.30))
ridge.addLine(to: CGPoint(x: size * 0.52, y: size * 0.34))
ridge.addLine(to: CGPoint(x: size * 0.70, y: size * 0.22))
ridge.addLine(to: CGPoint(x: size * 0.86, y: size * 0.30))
ridge.addLine(to: CGPoint(x: size, y: size * 0.24))
ridge.addLine(to: CGPoint(x: size, y: 0))
ridge.closeSubpath()
ctx.addPath(ridge)
ctx.setFillColor(rgb(0.004, 0.008, 0.020))
ctx.fillPath()

guard let image = ctx.makeImage() else { exit(1) }
let rep = NSBitmapImageRep(cgImage: image)
guard let data = rep.representation(using: .png, properties: [:]) else { exit(1) }
try! data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
print("wrote \(CommandLine.arguments[1])")
