import AppKit

struct WindowSample: Equatable {
    var bounds: CGRect
    var layer: Int
    var alpha: Double
    var pid: pid_t
}

struct LedgeScanner {
    static let minWidth: CGFloat = 120
    static let minHeight: CGFloat = 60
    static let minSegment: CGFloat = 48
    static let topClearance: CGFloat = 24
    static let minAlpha = 0.05
    static let maxLedges = 24
    static let normalLayer = Int(CGWindowLevelForKey(.normalWindow))
    static let dockLayer = Int(CGWindowLevelForKey(.dockWindow))
    static let menuLayer = Int(CGWindowLevelForKey(.mainMenuWindow))

    var screen: CGRect
    var visible: CGRect
    var primaryTop: CGFloat
    var ownPID: pid_t
    var dockPID: pid_t?

    init(screen: CGRect, visible: CGRect, primaryTop: CGFloat, ownPID: pid_t, dockPID: pid_t? = nil) {
        self.screen = screen
        self.visible = visible
        self.primaryTop = primaryTop
        self.ownPID = ownPID
        self.dockPID = dockPID
    }

    init(screen: NSScreen) {
        self.init(
            screen: screen.frame,
            visible: screen.visibleFrame,
            primaryTop: NSScreen.screens.first?.frame.maxY ?? screen.frame.maxY,
            ownPID: getpid(),
            dockPID: NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first?.processIdentifier
        )
    }

    static func samples() -> [WindowSample] {
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return [] }
        return list.compactMap { info in
            guard let raw = info[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: raw as CFDictionary) else { return nil }
            let layer = (info[kCGWindowLayer as String] as? NSNumber)?.intValue ?? 0
            let alpha = (info[kCGWindowAlpha as String] as? NSNumber)?.doubleValue ?? 1
            let pid = (info[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value ?? 0
            return WindowSample(bounds: bounds, layer: layer, alpha: alpha, pid: pid)
        }
    }

    func cocoa(_ bounds: CGRect) -> CGRect {
        CGRect(x: bounds.minX, y: primaryTop - bounds.maxY, width: bounds.width, height: bounds.height)
    }

    func world(_ rect: CGRect) -> CGRect {
        rect.offsetBy(dx: -screen.minX, dy: -screen.minY)
    }

    static func worldPoint(_ point: CGPoint, in screen: CGRect) -> CGPoint? {
        guard point.x >= screen.minX, point.x <= screen.maxX, point.y >= screen.minY, point.y <= screen.maxY else { return nil }
        return CGPoint(x: point.x - screen.minX, y: point.y - screen.minY)
    }

    var ceiling: CGFloat {
        min(visible.maxY, screen.maxY - LedgeScanner.topClearance) + 0.5
    }

    func ledges(from samples: [WindowSample]) -> [CGRect] {
        var occluders: [CGRect] = []
        var found: [CGRect] = []
        if let dock = dockShelf(samples) {
            occluders.append(dock)
            found.append(dock)
        }
        for sample in samples {
            guard sample.pid != ownPID, sample.pid != dockPID, sample.alpha > LedgeScanner.minAlpha,
                  sample.layer >= 0, sample.layer < LedgeScanner.menuLayer,
                  sample.bounds.width > 0, sample.bounds.height > 0 else { continue }
            let rect = cocoa(sample.bounds)
            defer { occluders.append(rect) }
            guard sample.layer == LedgeScanner.normalLayer,
                  rect.width >= LedgeScanner.minWidth, rect.height >= LedgeScanner.minHeight else { continue }
            let top = rect.maxY
            guard top > screen.minY + LedgeScanner.minSegment, top <= ceiling else { continue }
            let lo = max(rect.minX, screen.minX)
            let hi = min(rect.maxX, screen.maxX)
            guard hi - lo >= LedgeScanner.minSegment else { continue }
            let covers = occluders.filter { $0.minY < top && $0.maxY >= top }.map { ($0.minX, $0.maxX) }
            let bottom = max(rect.minY, screen.minY)
            for (a, b) in LedgeScanner.subtract(covers, from: (lo, hi)) where b - a >= LedgeScanner.minSegment {
                found.append(CGRect(x: a, y: bottom, width: b - a, height: top - bottom))
            }
        }
        return found
            .sorted { $0.width != $1.width ? $0.width > $1.width : $0.maxY > $1.maxY }
            .prefix(LedgeScanner.maxLedges)
            .map(world)
    }

    func dockShelf(_ samples: [WindowSample]) -> CGRect? {
        guard let dockPID, visible.minY > screen.minY + 1 else { return nil }
        let band = CGRect(x: screen.minX, y: screen.minY, width: screen.width, height: visible.minY - screen.minY)
        var lo = CGFloat.infinity
        var hi = -CGFloat.infinity
        for sample in samples where sample.pid == dockPID && sample.layer == LedgeScanner.dockLayer && sample.alpha > LedgeScanner.minAlpha {
            let rect = cocoa(sample.bounds).intersection(band)
            guard !rect.isNull, rect.width > 0, rect.height > 0 else { continue }
            lo = min(lo, rect.minX)
            hi = max(hi, rect.maxX)
        }
        guard hi - lo >= LedgeScanner.minSegment else { return nil }
        return CGRect(x: lo, y: band.minY, width: hi - lo, height: band.height)
    }

    static func subtract(_ covers: [(CGFloat, CGFloat)], from span: (CGFloat, CGFloat)) -> [(CGFloat, CGFloat)] {
        var pieces = [span]
        for (a, b) in covers where b > a {
            pieces = pieces.flatMap { piece -> [(CGFloat, CGFloat)] in
                guard b > piece.0, a < piece.1 else { return [piece] }
                var out: [(CGFloat, CGFloat)] = []
                if a > piece.0 { out.append((piece.0, a)) }
                if b < piece.1 { out.append((b, piece.1)) }
                return out
            }
            if pieces.isEmpty { break }
        }
        return pieces
    }
}
