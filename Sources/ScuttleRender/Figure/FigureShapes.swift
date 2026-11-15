import Foundation
import CoreGraphics

protocol FigureShapes {}

extension FigureShapes {
    static func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    static func P(_ a: [CGFloat]) -> [CGPoint] {
        stride(from: 0, to: a.count - 1, by: 2).map { CGPoint(x: a[$0], y: a[$0 + 1]) }
    }

    static func ell(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ rot: CGFloat = 0) -> CGPath {
        var t = CGAffineTransform(translationX: cx, y: cy).rotated(by: rot)
        return CGPath(ellipseIn: CGRect(x: -abs(rx), y: -abs(ry), width: 2 * abs(rx), height: 2 * abs(ry)), transform: &t)
    }

    static func circ(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> CGPath { ell(cx, cy, r, r) }

    static func rrect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> CGPath {
        let rr = max(0, min(r, min(abs(w), abs(h)) / 2))
        return CGPath(roundedRect: CGRect(x: x, y: y, width: w, height: h).standardized, cornerWidth: rr, cornerHeight: rr, transform: nil)
    }

    static func line(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.move(to: pt(x0, y0))
        p.addLine(to: pt(x1, y1))
        return p
    }

    static func arc(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat, dip: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.move(to: pt(x0, y0))
        p.addQuadCurve(to: pt(x1, y1), control: pt((x0 + x1) / 2, (y0 + y1) / 2 - dip))
        return p
    }

    static func poly(_ a: [CGFloat], closed: Bool = true) -> CGPath {
        polyP(P(a), closed: closed)
    }

    static func polyP(_ pts: [CGPoint], closed: Bool = true) -> CGPath {
        let p = CGMutablePath()
        guard !pts.isEmpty else { return p }
        p.addLines(between: pts)
        if closed { p.closeSubpath() }
        return p
    }

    static func smoothP(_ p: [CGPoint], closed: Bool = true, t: CGFloat = 1) -> CGPath {
        let path = CGMutablePath()
        let n = p.count
        guard n > 1 else { return path }
        path.move(to: p[0])
        if n == 2 {
            path.addLine(to: p[1])
            return path
        }
        let count = closed ? n : n - 1
        for i in 0..<count {
            let p0 = p[closed ? (i - 1 + n) % n : max(i - 1, 0)]
            let p1 = p[i]
            let p2 = p[(i + 1) % n]
            let p3 = p[closed ? (i + 2) % n : min(i + 2, n - 1)]
            let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6 * t, y: p1.y + (p2.y - p0.y) / 6 * t)
            let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6 * t, y: p2.y - (p3.y - p1.y) / 6 * t)
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        if closed { path.closeSubpath() }
        return path
    }

    static func smooth(_ a: [CGFloat], closed: Bool = true, t: CGFloat = 1) -> CGPath {
        smoothP(P(a), closed: closed, t: t)
    }

    static func xf(_ p: CGPath, _ t: CGAffineTransform) -> CGPath {
        var tt = t
        return p.copy(using: &tt) ?? p
    }

    static func moved(_ p: CGPath, _ dx: CGFloat, _ dy: CGFloat) -> CGPath {
        xf(p, CGAffineTransform(translationX: dx, y: dy))
    }

    static func mirror(_ p: CGPath, _ x: CGFloat = 50) -> CGPath {
        xf(p, CGAffineTransform(translationX: 2 * x, y: 0).scaledBy(x: -1, y: 1))
    }

    static func mirrorA(_ a: [CGFloat], _ x: CGFloat = 50) -> [CGFloat] {
        var b = a
        for i in stride(from: 0, to: b.count, by: 2) { b[i] = 2 * x - b[i] }
        return b
    }

    static func about(_ x: CGFloat, _ y: CGFloat, rot: CGFloat = 0, sx: CGFloat = 1, sy: CGFloat = 1) -> CGAffineTransform {
        CGAffineTransform(translationX: x, y: y).rotated(by: rot).scaledBy(x: sx, y: sy).translatedBy(x: -x, y: -y)
    }

    static func uni(_ ps: [CGPath]) -> CGPath {
        guard var r = ps.first else { return CGMutablePath() }
        for p in ps.dropFirst() { r = r.union(p) }
        return r
    }

    static func minus(_ a: CGPath, _ b: CGPath) -> CGPath {
        a.subtracting(b)
    }

    static func spikeRing(_ cx: CGFloat, _ cy: CGFloat, rx: CGFloat, ry: CGFloat, trx: CGFloat, try_: CGFloat, from a0: CGFloat, to a1: CGFloat, n: Int) -> [CGPoint] {
        var out: [CGPoint] = []
        for i in 0...(2 * max(1, n)) {
            let t = CGFloat(i) / CGFloat(2 * max(1, n))
            let a = a0 + (a1 - a0) * t
            let tip = i % 2 == 1
            out.append(CGPoint(x: cx + cos(a) * (tip ? trx : rx), y: cy + sin(a) * (tip ? try_ : ry)))
        }
        return out
    }

    static func star(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, points: Int = 5, inner: CGFloat = 0.45, spin: CGFloat = .pi / 2) -> CGPath {
        var pts: [CGPoint] = []
        for i in 0..<(max(2, points) * 2) {
            let rad = i % 2 == 0 ? r : r * inner
            let a = spin + CGFloat(i) * .pi / CGFloat(max(2, points))
            pts.append(CGPoint(x: cx + rad * cos(a), y: cy + rad * sin(a)))
        }
        return polyP(pts)
    }

    static func softStar(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, points: Int = 5, inner: CGFloat = 0.5, spin: CGFloat = .pi / 2, t: CGFloat = 0.6) -> CGPath {
        var pts: [CGPoint] = []
        for i in 0..<(max(2, points) * 2) {
            let rad = i % 2 == 0 ? r : r * inner
            let a = spin + CGFloat(i) * .pi / CGFloat(max(2, points))
            pts.append(CGPoint(x: cx + rad * cos(a), y: cy + rad * sin(a)))
        }
        return smoothP(pts, t: t)
    }

    static func heart(_ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.move(to: pt(cx, cy - s))
        p.addCurve(to: pt(cx - s, cy + 0.35 * s), control1: pt(cx - 0.3 * s, cy - 0.55 * s), control2: pt(cx - s, cy - 0.25 * s))
        p.addCurve(to: pt(cx, cy + 0.5 * s), control1: pt(cx - s, cy + s), control2: pt(cx - 0.2 * s, cy + s))
        p.addCurve(to: pt(cx + s, cy + 0.35 * s), control1: pt(cx + 0.2 * s, cy + s), control2: pt(cx + s, cy + s))
        p.addCurve(to: pt(cx, cy - s), control1: pt(cx + s, cy - 0.25 * s), control2: pt(cx + 0.3 * s, cy - 0.55 * s))
        p.closeSubpath()
        return p
    }

    static func drop(_ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat, _ rot: CGFloat = 0) -> CGPath {
        let p = CGMutablePath()
        p.move(to: pt(0, s * 1.5))
        p.addCurve(to: pt(0, -s), control1: pt(s * 0.35, s * 0.8), control2: pt(s * 1.25, -s))
        p.addCurve(to: pt(0, s * 1.5), control1: pt(-s * 1.25, -s), control2: pt(-s * 0.35, s * 0.8))
        p.closeSubpath()
        return xf(p, CGAffineTransform(translationX: cx, y: cy).rotated(by: rot))
    }

    static func spiral(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, turns: CGFloat = 1.75, spin: CGFloat = 1, start: CGFloat = 0) -> CGPath {
        var pts: [CGPoint] = []
        let steps = 22
        for i in 0...steps {
            let u = CGFloat(i) / CGFloat(steps)
            let a = start + spin * u * turns * 2 * .pi
            pts.append(CGPoint(x: cx + r * u * cos(a), y: cy + r * u * sin(a)))
        }
        return smoothP(pts, closed: false)
    }

    static func zigzag(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat, teeth: Int, amp: CGFloat) -> CGPath {
        var pts: [CGPoint] = []
        let n = max(2, teeth * 2)
        let dx = x1 - x0, dy = y1 - y0
        let l = max(0.0001, hypot(dx, dy))
        let nx = -dy / l, ny = dx / l
        for i in 0...n {
            let u = CGFloat(i) / CGFloat(n)
            let o: CGFloat = i == 0 || i == n ? 0 : (i % 2 == 0 ? -amp : amp)
            pts.append(CGPoint(x: x0 + dx * u + nx * o, y: y0 + dy * u + ny * o))
        }
        return polyP(pts, closed: false)
    }

    static func wavy(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat, waves: CGFloat, amp: CGFloat, phase: CGFloat = 0) -> CGPath {
        var pts: [CGPoint] = []
        let n = max(6, Int(waves * 8))
        let dx = x1 - x0, dy = y1 - y0
        let l = max(0.0001, hypot(dx, dy))
        let nx = -dy / l, ny = dx / l
        for i in 0...n {
            let u = CGFloat(i) / CGFloat(n)
            let o = amp * sin(u * waves * 2 * .pi + phase)
            pts.append(CGPoint(x: x0 + dx * u + nx * o, y: y0 + dy * u + ny * o))
        }
        return smoothP(pts, closed: false)
    }

    static func hem(left: CGFloat, right: CGFloat, y: CGFloat, bumps: Int, depth: CGFloat, phase: CGFloat = 0, ripple: CGFloat = 0) -> [CGPoint] {
        var pts: [CGPoint] = []
        let n = max(1, bumps)
        let step = (right - left) / CGFloat(n)
        for i in 0...n {
            let x = right - CGFloat(i) * step
            let lift = ripple * sin(phase + CGFloat(i) * 1.7)
            pts.append(CGPoint(x: x, y: y + lift))
            if i < n {
                let mid = x - step / 2
                pts.append(CGPoint(x: mid, y: y - depth + lift * 0.6))
            }
        }
        return pts
    }

    static func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

    static func clamp(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat { max(lo, min(hi, v)) }
}

struct Noise {
    var s: UInt64

    init(_ seed: Int) {
        s = UInt64(truncatingIfNeeded: seed &* 2654435761 &+ 1013904223) | 1
    }

    mutating func next() -> CGFloat {
        s ^= s << 13
        s ^= s >> 7
        s ^= s << 17
        return CGFloat(s % 1_000_000) / 1_000_000
    }

    mutating func range(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * next() }

    mutating func sign() -> CGFloat { next() > 0.5 ? 1 : -1 }
}
