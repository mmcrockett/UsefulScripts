// Draws the app icon (an owl face wearing headphones) and writes it as a PNG.
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
let cream = color(232, 200, 150)
let white = color(255, 255, 255)
let ink = color(24, 20, 20)
let orange = color(244, 164, 48)
let cyan = color(64, 214, 232)
let cyanDark = color(20, 120, 140)

let centerY: CGFloat = 480

// Ear tufts, then the head.
fillPolygon([(270, centerY + 130), (310, centerY + 360), (450, centerY + 230)], darkBrown)
fillPolygon([(754, centerY + 130), (714, centerY + 360), (574, centerY + 230)], darkBrown)
fillEllipse(512, centerY, 295, 300, brown)

// Forehead feather ticks.
ctx.setStrokeColor(darkBrown)
ctx.setLineWidth(14)
ctx.setLineCap(.round)
for dx in [CGFloat(-60), 0, 60] {
    ctx.move(to: CGPoint(x: 512 + dx - 18, y: centerY + 215))
    ctx.addLine(to: CGPoint(x: 512 + dx, y: centerY + 185))
    ctx.addLine(to: CGPoint(x: 512 + dx + 18, y: centerY + 215))
    ctx.strokePath()
}

// Facial discs and eyes.
fillEllipse(392, centerY + 20, 140, 140, cream)
fillEllipse(632, centerY + 20, 140, 140, cream)
fillEllipse(392, centerY + 20, 108, 108, white)
fillEllipse(632, centerY + 20, 108, 108, white)
fillEllipse(402, centerY + 14, 62, 62, ink)
fillEllipse(622, centerY + 14, 62, 62, ink)
fillEllipse(424, centerY + 40, 20, 20, white)
fillEllipse(644, centerY + 40, 20, 20, white)

// Beak.
fillPolygon([(474, centerY - 30), (550, centerY - 30), (512, centerY - 130)], orange)

// Headphones: band over the head, cups on the sides.
ctx.setStrokeColor(cyan)
ctx.setLineWidth(46)
ctx.addArc(center: CGPoint(x: 512, y: centerY), radius: 322, startAngle: 0, endAngle: .pi, clockwise: false)
ctx.strokePath()
for x in [CGFloat(190), 834] {
    fillRoundedRect(CGRect(x: x - 58, y: centerY - 130, width: 116, height: 260), 52, cyan)
    fillRoundedRect(CGRect(x: x - 30, y: centerY - 90, width: 60, height: 180), 28, cyanDark)
}
ctx.restoreGState()

let out = URL(fileURLWithPath: CommandLine.arguments[1])
let dest = CGImageDestinationCreateWithURL(out as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
CGImageDestinationFinalize(dest)
