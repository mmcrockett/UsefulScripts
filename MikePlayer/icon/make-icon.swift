// Draws the app icon (an owl wearing headphones) and writes it as a PNG.
// Usage: swift make-icon.swift <out.png>
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: space,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

func color(_ r: Int, _ g: Int, _ b: Int) -> CGColor {
    CGColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
}

func fillEllipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ c: CGColor) {
    ctx.setFillColor(c)
    ctx.fillEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
}

func fillPolygon(_ points: [(CGFloat, CGFloat)], _ c: CGColor) {
    ctx.setFillColor(c)
    ctx.move(to: CGPoint(x: points[0].0, y: points[0].1))
    for p in points.dropFirst() { ctx.addLine(to: CGPoint(x: p.0, y: p.1)) }
    ctx.closePath()
    ctx.fillPath()
}

func fillRoundedRect(_ rect: CGRect, _ radius: CGFloat, _ c: CGColor) {
    ctx.setFillColor(c)
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    ctx.fillPath()
}

// Background: console-black rounded square with a faint vertical gradient.
let background = CGPath(
    roundedRect: CGRect(x: 100, y: 100, width: 824, height: 824), cornerWidth: 185, cornerHeight: 185, transform: nil)
ctx.saveGState()
ctx.addPath(background)
ctx.clip()
let gradient = CGGradient(
    colorsSpace: space, colors: [color(34, 38, 56), color(8, 9, 14)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(
    gradient, start: CGPoint(x: 512, y: 924), end: CGPoint(x: 512, y: 100), options: [])

let brown = color(150, 98, 58)
let darkBrown = color(104, 66, 38)
let belly = color(232, 200, 150)
let cyan = color(64, 214, 232)
let cyanDark = color(20, 120, 140)

// Ear tufts, then body and head.
fillPolygon([(270, 640), (300, 840), (430, 730)], darkBrown)
fillPolygon([(754, 640), (724, 840), (594, 730)], darkBrown)
fillEllipse(512, 430, 300, 330, brown)

// Belly with feather scallops.
fillEllipse(512, 300, 190, 215, belly)
for (i, row) in [(1, 340), (2, 270), (3, 200)] {
    for dx in stride(from: CGFloat(-90), through: 90, by: 90) {
        let offset: CGFloat = i % 2 == 0 ? 45 : 0
        ctx.setStrokeColor(color(190, 150, 100))
        ctx.setLineWidth(10)
        ctx.addArc(
            center: CGPoint(x: 512 + dx + offset - (i % 2 == 0 ? 45 : 0), y: CGFloat(row)), radius: 38,
            startAngle: .pi, endAngle: 2 * .pi, clockwise: false)
        ctx.strokePath()
    }
}

// Wings.
fillEllipse(262, 330, 70, 170, darkBrown)
fillEllipse(762, 330, 70, 170, darkBrown)

// Facial discs and eyes.
fillEllipse(400, 560, 125, 125, belly)
fillEllipse(624, 560, 125, 125, belly)
fillEllipse(400, 560, 92, 92, color(255, 255, 255))
fillEllipse(624, 560, 92, 92, color(255, 255, 255))
fillEllipse(408, 556, 52, 52, color(24, 20, 20))
fillEllipse(616, 556, 52, 52, color(24, 20, 20))
fillEllipse(426, 576, 17, 17, color(255, 255, 255))
fillEllipse(634, 576, 17, 17, color(255, 255, 255))

// Beak and feet.
fillPolygon([(480, 500), (544, 500), (512, 420)], color(244, 164, 48))
fillEllipse(440, 130, 46, 26, color(244, 164, 48))
fillEllipse(584, 130, 46, 26, color(244, 164, 48))

// Headphones: band over the head, cups on the sides.
ctx.setStrokeColor(cyan)
ctx.setLineWidth(46)
ctx.setLineCap(.round)
ctx.addArc(center: CGPoint(x: 512, y: 540), radius: 330, startAngle: 0, endAngle: .pi, clockwise: false)
ctx.strokePath()
for x in [CGFloat(182), 842] {
    fillRoundedRect(CGRect(x: x - 58, y: 410, width: 116, height: 260), 52, cyan)
    fillRoundedRect(CGRect(x: x - 30, y: 450, width: 60, height: 180), 28, cyanDark)
}
ctx.restoreGState()

let out = URL(fileURLWithPath: CommandLine.arguments[1])
let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
CGImageDestinationFinalize(dest)
