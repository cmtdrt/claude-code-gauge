// Usage: swift scripts/make-icon.swift <out.iconset>
import AppKit

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write("usage: make-icon.swift <out.iconset>\n".data(using: .utf8)!)
    exit(1)
}
let outDir = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

func render(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(px)
    let inset = s * 0.1
    let tile = NSRect(x: inset, y: inset, width: s - 2 * inset, height: s - 2 * inset)
    NSColor.white.setFill()
    NSBezierPath(roundedRect: tile, xRadius: tile.width * 0.225, yRadius: tile.width * 0.225).fill()

    let barWidth = tile.width * 0.62
    let barHeight = tile.height * 0.12
    let gap = tile.height * 0.09
    let x = tile.midX - barWidth / 2
    let bars: [(y: CGFloat, fill: CGFloat, color: NSColor)] = [
        (tile.midY + gap / 2, 0.45, .black),
        (tile.midY - gap / 2 - barHeight, 0.78, .systemOrange),
    ]
    for bar in bars {
        let r = barHeight / 2
        NSColor.black.withAlphaComponent(0.15).setFill()
        NSBezierPath(roundedRect: NSRect(x: x, y: bar.y, width: barWidth, height: barHeight), xRadius: r, yRadius: r).fill()
        bar.color.setFill()
        NSBezierPath(roundedRect: NSRect(x: x, y: bar.y, width: barWidth * bar.fill, height: barHeight), xRadius: r, yRadius: r).fill()
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for size in [16, 32, 128, 256, 512] {
    try render(size).write(to: outDir.appendingPathComponent("icon_\(size)x\(size).png"))
    try render(size * 2).write(to: outDir.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
