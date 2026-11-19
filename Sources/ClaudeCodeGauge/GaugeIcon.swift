import AppKit

/// Menu bar icon: two stacked gauges, session on top and week below.
enum GaugeIcon {
    static func image(for usage: Usage?) -> NSImage {
        let size = NSSize(width: 22, height: 16)
        let barHeight: CGFloat = 5
        let gap: CGFloat = 3
        let image = NSImage(size: size, flipped: true) { rect in
            // Not a template image (it can be orange/red), so pick the menu bar's text color ourselves.
            let dark = NSAppearance.currentDrawing().bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            let base: NSColor = dark ? .white : .black
            let top = (rect.height - 2 * barHeight - gap) / 2
            draw(usage?.session.percent, in: NSRect(x: 0, y: top, width: rect.width, height: barHeight), base: base)
            draw(usage?.week.percent, in: NSRect(x: 0, y: top + barHeight + gap, width: rect.width, height: barHeight), base: base)
            return true
        }
        image.isTemplate = false
        // Redraw on every display so light/dark menu bar changes are picked up.
        image.cacheMode = .never
        return image
    }

    private static func draw(_ percent: Int?, in bar: NSRect, base: NSColor) {
        let radius = bar.height / 2
        let track = NSBezierPath(roundedRect: bar, xRadius: radius, yRadius: radius)
        base.withAlphaComponent(0.3).setFill()
        track.fill()

        if let percent, percent > 0 {
            // Clip to the track instead of enforcing a minimum width, so small values stay proportional.
            NSGraphicsContext.saveGraphicsState()
            track.addClip()
            color(for: Level(percent: percent), base: base).setFill()
            NSRect(x: bar.minX, y: bar.minY, width: bar.width * CGFloat(min(percent, 100)) / 100, height: bar.height).fill()
            NSGraphicsContext.restoreGraphicsState()
        }

        let lineWidth: CGFloat = 0.5
        let outline = NSBezierPath(roundedRect: bar.insetBy(dx: lineWidth / 2, dy: lineWidth / 2),
                                   xRadius: radius - lineWidth / 2, yRadius: radius - lineWidth / 2)
        outline.lineWidth = lineWidth
        base.setStroke()
        outline.stroke()
    }

    private static func color(for level: Level, base: NSColor) -> NSColor {
        switch level {
        case .normal: return base
        case .warning: return .systemOrange
        case .critical: return .systemRed
        }
    }
}
