import Foundation
import CoreGraphics
import ScuttleCore

enum DoodleArt: FigureShapes {}

final class DoodleKit: FigureCanvas {
    static let finish = SpriteFinish(shadowBlur: 2.2, shadowMinPt: 0.9, shadowDrop: 0, shadowTone: Tone(0x1a1020, 0.35))

    let felt = Tone(0x231b26)
    let cheek = Tone(0xff7aa0)
    let sweatTone = Tone(0x3fb6ff)
    var boil = true

    var line: CGFloat { width(2.7, minPt: 0.95) }
    var thin: CGFloat { width(1.9, minPt: 0.7) }

    func seed(_ n: Int) -> Int {
        boil ? n &+ (f.frameIndex / 4) &* 7919 : n
    }

    static func flatten(_ path: CGPath, step: CGFloat = 1.2) -> [([CGPoint], Bool)] {
        var out: [([CGPoint], Bool)] = []
        var cur: [CGPoint] = []
        var last = CGPoint.zero
        var start = CGPoint.zero
        func lineTo(_ p: CGPoint) {
            let n = max(1, Int(hypot(p.x - last.x, p.y - last.y) / step))
            for i in 1...n {
                let t = CGFloat(i) / CGFloat(n)
                cur.append(CGPoint(x: last.x + (p.x - last.x) * t, y: last.y + (p.y - last.y) * t))
            }
            last = p
        }
        path.applyWithBlock { e in
            let el = e.pointee
            switch el.type {
            case .moveToPoint:
                if cur.count > 1 { out.append((cur, false)) }
                cur = [el.points[0]]
                last = el.points[0]
                start = last
            case .addLineToPoint:
                lineTo(el.points[0])
            case .addQuadCurveToPoint:
                let c = el.points[0], p = el.points[1], p0 = last
                for i in 1...10 {
                    let t = CGFloat(i) / 10, u = 1 - t
                    lineTo(CGPoint(x: u * u * p0.x + 2 * u * t * c.x + t * t * p.x, y: u * u * p0.y + 2 * u * t * c.y + t * t * p.y))
                }
            case .addCurveToPoint:
                let c1 = el.points[0], c2 = el.points[1], p = el.points[2], p0 = last
                for i in 1...12 {
                    let t = CGFloat(i) / 12, u = 1 - t
                    let a = u * u * u, b = 3 * u * u * t, c = 3 * u * t * t, d = t * t * t
                    lineTo(CGPoint(x: a * p0.x + b * c1.x + c * c2.x + d * p.x, y: a * p0.y + b * c1.y + c * c2.y + d * p.y))
                }
            case .closeSubpath:
                if hypot(last.x - start.x, last.y - start.y) > 0.01 { lineTo(start) }
                if cur.count > 2 {
                    cur.removeLast()
                    out.append((cur, true))
                }
                cur = []
            @unknown default:
                break
            }
        }
        if cur.count > 1 { out.append((cur, false)) }
        return out
    }

    static func wobble(_ pts: [CGPoint], closed: Bool, seed: Int, amp: CGFloat) -> [CGPoint] {
        var r = Noise(seed)
        let ph = [r.range(0, 6.28), r.range(0, 6.28), r.range(0, 6.28)]
        var out: [CGPoint] = []
        out.reserveCapacity(pts.count)
        var s: CGFloat = 0
        let n = pts.count
        for i in 0..<n {
            if i > 0 { s += hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y) }
            let a = pts[closed ? (i - 1 + n) % n : max(0, i - 1)]
            let b = pts[closed ? (i + 1) % n : min(n - 1, i + 1)]
            var tx = b.x - a.x, ty = b.y - a.y
            let l = max(0.0001, hypot(tx, ty))
            tx /= l
            ty /= l
            let o = amp * (sin(s * 0.17 + ph[0]) * 0.55 + sin(s * 0.41 + ph[1]) * 0.3 + sin(s * 1.1 + ph[2]) * 0.15)
            out.append(CGPoint(x: pts[i].x - ty * o, y: pts[i].y + tx * o))
        }
        return out
    }

    static func curve(_ pts: [CGPoint], closed: Bool = false) -> CGPath {
        let p = CGMutablePath()
        guard pts.count > 2 else {
            if pts.count > 1 { p.addLines(between: pts) }
            return p
        }
        p.move(to: pts[0])
        for i in 1..<(pts.count - 1) {
            let m = CGPoint(x: (pts[i].x + pts[i + 1].x) / 2, y: (pts[i].y + pts[i + 1].y) / 2)
            p.addQuadCurve(to: m, control: pts[i])
        }
        p.addLine(to: pts[pts.count - 1])
        if closed { p.closeSubpath() }
        return p
    }

    func marker(_ shape: CGPath, _ color: Tone, _ w: CGFloat? = nil, seed raw: Int) {
        let sd = seed(raw)
        let lw = w ?? line
        var r = Noise(sd &+ 991)
        for (k, sub) in Self.flatten(shape).enumerated() {
            let (pts, closed) = sub
            if closed {
                let n = pts.count
                let st = Int(r.range(0, CGFloat(n))) % n
                let rot = Array(pts[st...] + pts[..<st])
                let wob = Self.wobble(rot, closed: true, seed: sd &+ k &* 31, amp: 1.1)
                let extra = max(3, Int(CGFloat(n) * 0.09))
                var tail: [CGPoint] = []
                let drift = r.range(1.2, 2.4) * r.sign()
                for i in 0...extra {
                    let p = wob[i % n]
                    let q = wob[(i + 1) % n]
                    var tx = q.x - p.x, ty = q.y - p.y
                    let l = max(0.0001, hypot(tx, ty))
                    tx /= l
                    ty /= l
                    let t = CGFloat(i) / CGFloat(extra)
                    tail.append(CGPoint(x: p.x - ty * drift * t + tx * t * 1.5, y: p.y + tx * drift * t + ty * t * 1.5))
                }
                stroke(Self.curve(wob + [wob[0]]), color, lw)
                stroke(Self.curve(tail), color.alpha(color.a * 0.85), lw * 0.95)
            } else {
                var line = pts
                if line.count >= 2 {
                    let a = line[0], b = line[1]
                    let l = max(0.0001, hypot(a.x - b.x, a.y - b.y))
                    let over = r.range(0.6, 1.8)
                    line.insert(CGPoint(x: a.x + (a.x - b.x) / l * over, y: a.y + (a.y - b.y) / l * over), at: 0)
                    let c = line[line.count - 1], e = line[line.count - 2]
                    let l2 = max(0.0001, hypot(c.x - e.x, c.y - e.y))
                    let over2 = r.range(0.8, 2.2)
                    line.append(CGPoint(x: c.x + (c.x - e.x) / l2 * over2, y: c.y + (c.y - e.y) / l2 * over2))
                }
                stroke(Self.curve(Self.wobble(line, closed: false, seed: sd &+ k &* 17, amp: 0.7)), color, lw)
            }
        }
    }

    func crayon(_ shape: CGPath, _ color: Tone, seed raw: Int, dense: Bool = false) {
        let sd = seed(raw)
        var r = Noise(sd &+ 4242)
        let bb = shape.boundingBoxOfPath
        guard bb.width > 0.5, bb.height > 0.5 else { return }
        let s = max(0.8, 1 - 3.2 / max(bb.width, bb.height))
        let ox = r.range(-1.4, 1.4), oy = r.range(-1.4, 1.4)
        let t = CGAffineTransform(translationX: bb.midX + ox, y: bb.midY + oy).scaledBy(x: s, y: s).translatedBy(x: -bb.midX, y: -bb.midY)
        let sh = Self.xf(shape, t)
        let region = CGMutablePath()
        for (k, sub) in Self.flatten(sh, step: 2).enumerated() where sub.1 {
            region.addPath(Self.curve(Self.wobble(sub.0, closed: true, seed: sd &+ 7 &+ k, amp: 1.6), closed: true))
        }
        let gap = max(1.3, 0.75 * pt)
        let stroke0 = max(1.1, 0.5 * pt)
        clip(region) {
            fill(CGPath(rect: bb.insetBy(dx: -4, dy: -4), transform: nil), color.alpha(color.a * (dense ? 0.72 : 0.42)))
            let ang = r.range(0.95, 1.2)
            let dx = cos(ang), dy = sin(ang)
            let diag = hypot(bb.width, bb.height) + 10
            var off: CGFloat = -diag / 2
            let hatch = CGMutablePath()
            while off < diag / 2 {
                let cx = bb.midX + dy * off, cy = bb.midY - dx * off
                let half = diag / 2
                let a = CGPoint(x: cx - dx * half + r.range(-2, 2), y: cy - dy * half)
                let b = CGPoint(x: cx + dx * half + r.range(-2, 2), y: cy + dy * half)
                hatch.move(to: a)
                hatch.addQuadCurve(to: b, control: CGPoint(x: (a.x + b.x) / 2 + r.range(-1.5, 1.5), y: (a.y + b.y) / 2 + r.range(-1.5, 1.5)))
                off += gap * r.range(0.85, 1.3)
            }
            stroke(hatch, color.alpha(color.a * 0.8), stroke0 * 1.3)
        }
    }

    func part(_ shape: CGPath, fill tone: Tone?, line ink: Tone, seed: Int, w: CGFloat? = nil, dense: Bool = true) {
        if let tone { crayon(shape, tone, seed: seed, dense: dense) }
        marker(shape, ink, w, seed: seed)
    }

    func dot(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ color: Tone, seed raw: Int) {
        guard let pts = Self.flatten(Self.ell(x, y, rx, ry), step: 0.6).first?.0 else { return }
        fill(Self.curve(Self.wobble(pts, closed: true, seed: seed(raw), amp: min(0.35, rx * 0.15)), closed: true), color)
    }

    func stick(_ a: [CGFloat], _ color: Tone, seed: Int, w: CGFloat? = nil) {
        marker(Self.smooth(a, closed: false), color, w, seed: seed)
    }

    func cheeks(_ x0: CGFloat, _ x1: CGFloat, _ y: CGFloat, _ r: CGFloat = 3.6, seed: Int) {
        crayon(Self.circ(x0, y, r), cheek, seed: seed, dense: true)
        crayon(Self.circ(x1, y, r), cheek, seed: seed + 1, dense: true)
    }

    func eye(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, side: CGFloat, ink: Tone? = nil, seed: Int) {
        let pen = ink ?? felt
        switch f.mood {
        case .dizzy:
            marker(Self.spiral(x, y, max(rx, ry) * 1.2, turns: 1.6, spin: side, start: f.t), pen, thin, seed: seed)
        case _ where f.eyesShut:
            marker(Self.arc(x - rx * 1.2, y + ry * 0.1, x + rx * 1.2, y + ry * 0.1, dip: ry * 0.8), pen, thin * 1.1, seed: seed)
        case .startled:
            dot(x, y, rx * 1.45, ry * 1.3, .white, seed: seed)
            marker(Self.ell(x, y, rx * 1.45, ry * 1.3), pen, thin * 0.85, seed: seed + 1)
            dot(x, y, rx * 0.45, rx * 0.45, pen, seed: seed + 2)
        case .fleeing:
            let p = CGMutablePath()
            p.move(to: Self.pt(x - side * rx * 1.1, y + ry * 0.9))
            p.addLine(to: Self.pt(x + side * rx, y))
            p.addLine(to: Self.pt(x - side * rx * 1.1, y - ry * 0.9))
            marker(p, pen, thin * 1.1, seed: seed)
        default:
            dot(x, y, rx, ry, pen, seed: seed)
            fill(Self.circ(x + rx * 0.3, y + ry * 0.4, min(rx, ry) * 0.32), .white)
        }
    }

    func mouth(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, ink: Tone? = nil, seed: Int) {
        let pen = ink ?? felt
        switch f.mood {
        case .calm:
            marker(Self.smooth([x - w / 2, y + w * 0.12, x, y - w * 0.3, x + w / 2, y + w * 0.12], closed: false), pen, thin, seed: seed)
        case .sleepy:
            marker(Self.ell(x, y - w * 0.05, w * 0.13, w * 0.16), pen, thin * 0.8, seed: seed)
        case .startled:
            dot(x, y - w * 0.12, w * 0.24, w * 0.32, pen, seed: seed)
        case .fleeing:
            marker(Self.zigzag(x - w * 0.55, y, x + w * 0.55, y, teeth: 3, amp: w * 0.13), pen, thin, seed: seed)
        case .dizzy:
            marker(Self.wavy(x - w * 0.5, y, x + w * 0.5, y, waves: 1.5, amp: w * 0.14, phase: f.t), pen, thin, seed: seed)
        }
    }

    func face(_ cx: CGFloat, _ cy: CGFloat, spread: CGFloat = 9.5, rx: CGFloat = 3.4, ry: CGFloat = 4.8, mouth showMouth: Bool = true, cheeks showCheeks: Bool = true, ink: Tone? = nil, seed: Int) {
        eye(cx - spread, cy, rx, ry, side: -1, ink: ink, seed: seed)
        eye(cx + spread, cy, rx, ry, side: 1, ink: ink, seed: seed + 1)
        if showCheeks { cheeks(cx - spread - rx * 2.3, cx + spread + rx * 2.3, cy - ry * 2.2, rx * 1.05, seed: seed + 2) }
        if showMouth { mouth(cx, cy - ry * 2.4, spread * 1.25, ink: ink, seed: seed + 4) }
    }

    func marks(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat = 12, ink: Tone, seed: Int) {
        switch f.mood {
        case .sleepy:
            let rise = CGFloat(f.frameIndex % 8) / 8
            for (i, k) in ([1.0, 0.7] as [CGFloat]).enumerated() {
                let zx = x + CGFloat(i) * s * 0.8, zy = y + CGFloat(i) * s * 0.75 + rise * s * 0.25
                let h = s * 0.4 * k
                marker(Self.poly([zx - h, zy + h, zx + h, zy + h, zx - h, zy - h, zx + h, zy - h], closed: false), ink, thin, seed: seed + i)
            }
        case .fleeing:
            for i in 0..<2 {
                let dx = -CGFloat(i) * s * 0.6
                marker(Self.drop(x + dx, y + CGFloat(i) * s * 0.3, s * 0.24, 0.5), sweatTone, thin * 0.9, seed: seed + i)
            }
        case .startled:
            for (i, a) in ([0.35, 0.95, 1.55] as [CGFloat]).enumerated() {
                let ca = cos(a + 0.2), sa = sin(a + 0.2)
                marker(Self.line(x + ca * s * 0.3, y + sa * s * 0.3, x + ca * s * 0.8, y + sa * s * 0.8), ink, thin, seed: seed + i)
            }
        default:
            break
        }
    }

    func placeholder(_ tone: Tone, ink: Tone? = nil) {
        let pen = ink ?? (tone.luma > 0.75 ? Tone(0x7a6cff) : tone.saturate(1.5).dim(0.9))
        let air = f.species.isAirborne
        let base: CGFloat = air ? 14 : 8
        let sq = 1 + 0.04 * f.swing2 * f.energy
        with(Self.about(50, base, sx: 1 / sq, sy: sq)) {
            if air {
                both { s in
                    part(Self.ell(50 + s * 32, 54 + f.swing * 3, 12, 8, s * (0.5 + f.swing * 0.35)), fill: tone.lift(0.3), line: pen, seed: s > 0 ? 3 : 4, dense: false)
                }
            } else {
                let step = f.swing * 4 * f.energy
                stick([40, base + 12, 38 + step, base - 3], pen, seed: 5)
                stick([60, base + 12, 62 - step, base - 3], pen, seed: 6)
            }
            part(Self.ell(50, base + 34, 30, 29), fill: tone, line: pen, seed: 7)
            face(54, base + 36, spread: 8, rx: 2.8, ry: 3.8, seed: 10)
            marks(78, base + 64, 12, ink: pen, seed: 20)
        }
    }
}
