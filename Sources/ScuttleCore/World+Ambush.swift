import Foundation

extension World {
    public func settleInDark(seconds: Double = 14) {
        primeDark()
        let dt = 1.0 / 30
        var t = 0.0
        while t < seconds {
            step(dt: dt, lidAngle: 0)
            t += dt
        }
        for e in drainEvents() {
            if case .rareVisitor = e { pushEvent(e) }
        }
    }
}
