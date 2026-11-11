#!/usr/bin/env swift
import AppKit

struct Variant {
    let fileName: String
    let pixels: Int
}

let variants: [Variant] = [
    Variant(fileName: "icon_16x16.png", pixels: 16),
    Variant(fileName: "icon_16x16@2x.png", pixels: 32),
    Variant(fileName: "icon_32x32.png", pixels: 32),
    Variant(fileName: "icon_32x32@2x.png", pixels: 64),
    Variant(fileName: "icon_128x128.png", pixels: 128),
    Variant(fileName: "icon_128x128@2x.png", pixels: 256),
    Variant(fileName: "icon_256x256.png", pixels: 256),
    Variant(fileName: "icon_256x256@2x.png", pixels: 512),
    Variant(fileName: "icon_512x512.png", pixels: 512),
    Variant(fileName: "icon_512x512@2x.png", pixels: 1024),
]

func drawIcon(pixelSize: Int) -> NSBitmapImageRep {
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    let size = CGFloat(pixelSize)
    bitmap.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: bitmap)!
    NSGraphicsContext.current = context
    context.shouldAntialias = true
    context.imageInterpolation = .high

    let bounds = NSRect(x: 0, y: 0, width: size, height: size)
    NSColor.clear.setFill()
    bounds.fill()

    let inset = size * 0.055
    let iconRect = bounds.insetBy(dx: inset, dy: inset)
    let cornerRadius = iconRect.width * 0.235
    let squircle = NSBezierPath(
        roundedRect: iconRect,
        xRadius: cornerRadius,
        yRadius: cornerRadius
    )

    let gradient = NSGradient(colors: [
        NSColor(srgbRed: 0.18, green: 0.78, blue: 0.85, alpha: 1),
        NSColor(srgbRed: 0.10, green: 0.40, blue: 0.91, alpha: 1),
    ])!
    gradient.draw(in: squircle, angle: -55)

    NSColor.white.withAlphaComponent(0.18).setStroke()
    squircle.lineWidth = max(1, size * 0.007)
    squircle.stroke()

    func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
        NSPoint(
            x: iconRect.minX + iconRect.width * x,
            y: iconRect.minY + iconRect.height * y
        )
    }

    let wave = NSBezierPath()
    wave.move(to: point(0.17, 0.50))
    wave.line(to: point(0.31, 0.50))
    wave.line(to: point(0.40, 0.68))
    wave.line(to: point(0.52, 0.31))
    wave.line(to: point(0.61, 0.50))
    wave.line(to: point(0.83, 0.50))
    wave.lineWidth = max(1.2, size * 0.052)
    wave.lineCapStyle = .round
    wave.lineJoinStyle = .round
    NSColor.white.withAlphaComponent(0.96).setStroke()
    wave.stroke()

    NSGraphicsContext.restoreGraphicsState()
    return bitmap
}

let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "Resources/AppIcon.iconset"
let outputURL = URL(fileURLWithPath: outputPath)
try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

for variant in variants {
    let bitmap = drawIcon(pixelSize: variant.pixels)
    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write(Data("Failed to encode \(variant.fileName)\n".utf8))
        exit(1)
    }
    try png.write(to: outputURL.appendingPathComponent(variant.fileName))
}
