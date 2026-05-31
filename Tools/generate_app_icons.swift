import AppKit
import Foundation

private let iconSizes = [16, 32, 64, 128, 256, 512, 1024]

private func color(_ hex: UInt32, alpha: CGFloat = 1) -> NSColor {
    let r = CGFloat((hex >> 16) & 0xff) / 255
    let g = CGFloat((hex >> 8) & 0xff) / 255
    let b = CGFloat(hex & 0xff) / 255
    return NSColor(srgbRed: r, green: g, blue: b, alpha: alpha)
}

private func path(_ build: (NSBezierPath) -> Void) -> NSBezierPath {
    let p = NSBezierPath()
    build(p)
    return p
}

private func fill(_ p: NSBezierPath, _ c: NSColor) {
    c.setFill()
    p.fill()
}

private func stroke(_ p: NSBezierPath, _ c: NSColor, width: CGFloat) {
    c.setStroke()
    p.lineWidth = width
    p.lineCapStyle = .round
    p.lineJoinStyle = .round
    p.stroke()
}

private func drawIcon(size: Int, output: URL) throws {
    let scale = CGFloat(size) / 1024
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "IconGenerator", code: 1)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    guard let context = NSGraphicsContext.current?.cgContext else {
        throw NSError(domain: "IconGenerator", code: 2)
    }
    context.scaleBy(x: scale, y: scale)

    fill(NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1024, height: 1024)), color(0xf4f8fb))

    let background = NSBezierPath(roundedRect: NSRect(x: 86, y: 86, width: 852, height: 852), xRadius: 188, yRadius: 188)
    NSGradient(colors: [
        color(0xffffff),
        color(0xf2f8fb)
    ])?.draw(in: background, angle: -34)

    let blue = color(0x336cf6)
    let deepBlue = color(0x203bc7)
    let cyan = color(0x66d7e8)

    context.setShadow(offset: CGSize(width: 0, height: -24), blur: 42, color: color(0x123864, alpha: 0.16).cgColor)
    let page = NSBezierPath(roundedRect: NSRect(x: 318, y: 250, width: 388, height: 466), xRadius: 62, yRadius: 62)
    NSGradient(colors: [
        color(0xebfbff),
        cyan
    ])?.draw(in: page, angle: -90)
    context.setShadow(offset: .zero, blur: 0, color: nil)

    let sideTab = NSBezierPath(roundedRect: NSRect(x: 686, y: 376, width: 70, height: 188), xRadius: 28, yRadius: 28)
    NSGradient(colors: [blue, deepBlue])?.draw(in: sideTab, angle: -90)

    let capTop = path { p in
        p.move(to: NSPoint(x: 512, y: 798))
        p.line(to: NSPoint(x: 292, y: 712))
        p.curve(to: NSPoint(x: 292, y: 674), controlPoint1: NSPoint(x: 270, y: 704), controlPoint2: NSPoint(x: 270, y: 682))
        p.line(to: NSPoint(x: 512, y: 588))
        p.line(to: NSPoint(x: 732, y: 674))
        p.curve(to: NSPoint(x: 732, y: 712), controlPoint1: NSPoint(x: 754, y: 682), controlPoint2: NSPoint(x: 754, y: 704))
        p.close()
    }
    NSGradient(colors: [color(0x4d92ff), deepBlue])?.draw(in: capTop, angle: -90)

    let capBase = NSBezierPath(roundedRect: NSRect(x: 398, y: 552, width: 228, height: 108), xRadius: 54, yRadius: 54)
    NSGradient(colors: [color(0x376df4), deepBlue])?.draw(in: capBase, angle: -90)

    let tassel = path { p in
        p.move(to: NSPoint(x: 698, y: 674))
        p.line(to: NSPoint(x: 698, y: 584))
    }
    stroke(tassel, deepBlue, width: 28)
    fill(NSBezierPath(ovalIn: NSRect(x: 668, y: 542, width: 60, height: 60)), deepBlue)

    if size <= 32 {
        fill(NSBezierPath(rect: NSRect(x: 260, y: 380, width: 504, height: 10)), color(0xffffff, alpha: 0.01))
    }

    NSGraphicsContext.restoreGraphicsState()

    guard let png = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGenerator", code: 3)
    }
    try png.write(to: output)
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let appIconDir = root.appendingPathComponent("Scholar/Assets.xcassets/AppIcon.appiconset")

for size in iconSizes {
    try drawIcon(size: size, output: appIconDir.appendingPathComponent("appicon-\(size).png"))
}
