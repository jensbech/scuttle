import AppKit
import ScuttleCore

final class SurroundingsFeed {
    static let scanInterval = 1.0
    static let speedSmoothing = 0.15

    var pointerOverride: CGPoint?
    private(set) var synthetic: [CGRect] = []
    private(set) var scans = 0
    private var scanned: [CGRect] = []
    private var lastScan = -Double.infinity
    private var lastPoint: CGPoint?
    private var lastTime = 0.0
    private var speed = 0.0

    func addLedge(_ rect: CGRect) {
        synthetic.append(rect)
    }

    func clearLedges() {
        synthetic.removeAll()
    }

    func forget() {
        scanned.removeAll()
        lastScan = -Double.infinity
        lastPoint = nil
        speed = 0
    }

    func quiet() -> Surroundings {
        forget()
        return Surroundings(pointer: pointerOverride, pointerSpeed: 0, ledges: Array(synthetic.prefix(LedgeScanner.maxLedges)))
    }

    func sense(now: Double, screen: NSScreen?) -> Surroundings {
        let point = pointerOverride ?? screen.flatMap { LedgeScanner.worldPoint(NSEvent.mouseLocation, in: $0.frame) }
        track(point, now: now)
        if let screen {
            if now - lastScan >= SurroundingsFeed.scanInterval {
                lastScan = now
                scanned = LedgeScanner(screen: screen).ledges(from: LedgeScanner.samples())
                scans += 1
            }
        } else {
            scanned.removeAll()
        }
        return Surroundings(
            pointer: point,
            pointerSpeed: point == nil ? 0 : speed,
            ledges: Array((synthetic + scanned).prefix(LedgeScanner.maxLedges))
        )
    }

    private func track(_ point: CGPoint?, now: Double) {
        guard let point else {
            lastPoint = nil
            speed = 0
            return
        }
        guard let last = lastPoint else {
            lastPoint = point
            lastTime = now
            speed = 0
            return
        }
        let dt = now - lastTime
        guard dt > 0.001 else { return }
        let instant = hypot(point.x - last.x, point.y - last.y) / dt
        let blend = 1 - exp(-dt / SurroundingsFeed.speedSmoothing)
        speed += blend * (Double(instant) - speed)
        lastPoint = point
        lastTime = now
    }
}
