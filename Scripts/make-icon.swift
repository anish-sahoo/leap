#!/usr/bin/env swift
import AppKit

// Generates Resources/AppIcon.icns — the ⌥ glyph on a cobalt→magenta rounded
// square (matches the menu-bar icon). Run via `mise run icon`.

let root = FileManager.default.currentDirectoryPath
let resources = "\(root)/Resources"
try? FileManager.default.createDirectory(atPath: resources, withIntermediateDirectories: true)

// Cobalt → magenta, with each color held near its corner so the blend is
// concentrated in the middle.
func gradient() -> NSGradient {
    let cobalt = NSColor(srgbRed: 0.09, green: 0.27, blue: 0.80, alpha: 1)
    let magenta = NSColor(srgbRed: 0.90, green: 0.15, blue: 0.75, alpha: 1)
    let locations: [CGFloat] = [0.0, 0.34, 0.66, 1.0]
    return NSGradient(
        colors: [cobalt, cobalt, magenta, magenta],
        atLocations: locations,
        colorSpace: .sRGB
    )!
}

func drawIcon(_ px: Int) -> NSBitmapImageRep {
    let size = CGFloat(px)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let inset = size * 0.06
    let square = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let path = NSBezierPath(roundedRect: square, xRadius: square.width * 0.2237, yRadius: square.width * 0.2237)
    gradient().draw(in: path, angle: -45)

    let style = NSMutableParagraphStyle()
    style.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: square.width * 0.52, weight: .semibold),
        .foregroundColor: NSColor.white,
        .paragraphStyle: style,
    ]
    let glyph = "⌥" as NSString
    let textSize = glyph.size(withAttributes: attrs)
    glyph.draw(
        in: NSRect(x: square.minX, y: square.midY - textSize.height / 2, width: square.width, height: textSize.height),
        withAttributes: attrs
    )

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

// Build the .iconset, then convert with iconutil.
let iconset = "\(NSTemporaryDirectory())/Leap.iconset"
try? FileManager.default.removeItem(atPath: iconset)
try! FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)

let variants: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
for (name, px) in variants {
    let data = drawIcon(px).representation(using: .png, properties: [:])!
    try data.write(to: URL(fileURLWithPath: "\(iconset)/\(name).png"))
}

let convert = Process()
convert.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
convert.arguments = ["-c", "icns", "-o", "\(resources)/AppIcon.icns", iconset]
try convert.run()
convert.waitUntilExit()
print("wrote \(resources)/AppIcon.icns")

// Layered 1024² source for Icon Composer (full Liquid Glass icon).
// Import background.png + glyph.png as separate layers.
func layer(_ px: Int, _ draw: (CGFloat) -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw(CGFloat(px))
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let srcDir = "\(resources)/icon-src"
try? FileManager.default.createDirectory(atPath: srcDir, withIntermediateDirectories: true)

let background = layer(1024) { size in
    gradient().draw(in: NSRect(x: 0, y: 0, width: size, height: size), angle: -45)
}
let glyph = layer(1024) { size in
    let style = NSMutableParagraphStyle()
    style.alignment = .center
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size * 0.5, weight: .semibold),
        .foregroundColor: NSColor.white,
        .paragraphStyle: style,
    ]
    let text = "⌥" as NSString
    let textSize = text.size(withAttributes: attrs)
    text.draw(
        in: NSRect(x: 0, y: size / 2 - textSize.height / 2, width: size, height: textSize.height),
        withAttributes: attrs
    )
}
try background.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: "\(srcDir)/background.png"))
try glyph.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: "\(srcDir)/glyph.png"))
print("wrote \(srcDir)/{background,glyph}.png  (import into Icon Composer)")
