import Foundation
import CoreGraphics
import ScuttleCore

struct CatchPose {
    var raise: CGFloat = 0
    var stretch: CGFloat = 1
    var sx: CGFloat = 1
    var dx: CGFloat = 0
    var angle: CGFloat = 0
}

enum CatchMotion {
    static let rise: CGFloat = 0.09
    static let hang: CGFloat = 0.16
    static let land: CGFloat = 0.27
    static let settled: CGFloat = 0.5

    static func ease(_ x: CGFloat) -> CGFloat {
        let u = max(0, min(1, x))
        return 1 - (1 - u) * (1 - u)
    }

    static func react(age a: CGFloat, size: CGFloat, airborne: Bool, natural: Bool, seed: CGFloat) -> CatchPose {
        var p = CatchPose()
        let top = size * (airborne ? 0.3 : 0.6)
        if a < rise {
            let u = a / rise
            p.raise = top * ease(u)
            p.stretch = 1.24 - 0.08 * u
        } else if a < hang {
            let u = (a - rise) / (hang - rise)
            p.raise = top * (1 + 0.04 * sin(u * .pi))
            p.stretch = 1.16 - 0.08 * u
        } else if a < land {
            let u = (a - hang) / (land - hang)
            p.raise = top * (1 - u * u)
            p.stretch = 1.08 + 0.04 * u
        } else {
            let d = a - land
            p.stretch = 1 - (airborne ? 0.16 : 0.3) * exp(-d * 9) * cos(d * 24)
        }
        if a > land {
            var k = min(1, (a - land) / 0.08)
            if natural && a > 0.55 {
                k *= max(0, 1 - (a - 0.55) / 0.12)
                p.angle = 0.07 * sin((a - 0.55) * 4.2) * min(1, (a - 0.55) / 0.2)
            }
            p.dx = size * (0.03 * sin(a * 78 + seed) + 0.014 * sin(a * 131 + seed * 2)) * k
            p.stretch *= 1 + 0.02 * sin(a * 61 + seed) * k
        }
        return p
    }

    static func windup(_ w: CGFloat, size: CGFloat, airborne: Bool, slip: Bool) -> CatchPose {
        var p = CatchPose()
        let k = GestureMotion.smooth(w / 0.07)
        if airborne {
            p.stretch = 1 - 0.12 * k
            p.sx = 1 + 0.08 * k
            p.dx = size * 0.03 * sin(w * 95) * k
            return p
        }
        p.angle = (slip ? 0.42 : 0.32) * k
        p.stretch = 1 - 0.13 * k
        p.dx = -size * 0.1 * k + size * 0.022 * sin(w * 92) * k
        if slip && w > 0.22 {
            let u = min(1, (w - 0.22) / 0.2)
            p.angle -= 0.75 * sin(u * .pi)
            p.raise = size * 0.12 * sin(u * .pi)
        }
        return p
    }

    static func dash(_ d: CGFloat, size: CGFloat, vertical: Bool, airborne: Bool) -> CatchPose {
        var p = CatchPose()
        let k = 1 - GestureMotion.smooth(d / 0.45)
        if vertical {
            p.stretch = 1 + 0.2 * k
            p.sx = 1 - 0.08 * k
        } else {
            p.sx = 1 + 0.22 * k
            p.stretch = 1 - 0.08 * k
            p.angle = (airborne ? -0.2 : -0.36) * k
        }
        return p
    }
}

struct CatchFx {
    let pen: GesturePen
    let s: CGFloat
    let alpha: CGFloat

    var ctx: CGContext { pen.ctx }

    var accent: Tone {
        switch pen.style {
        case .kawaii: return Tone(0xff6b8b)
        case .sticker: return Tone(0xffd23f)
        case .hose: return GesturePen.hoseCream
        case .mascot: return Tone(0xffb21f)
        case .doodle: return Tone(0xff4a3d)
        }
    }

    var bang: Tone {
        switch pen.style {
        case .kawaii: return Tone(0xff4f73)
        case .sticker: return Tone(0xff3b3b)
        case .hose: return GesturePen.hoseRed
        case .mascot: return Tone(0xff6a1a)
        case .doodle: return Tone(0xff3d30)
        }
    }

    var burst: Tone {
        switch pen.style {
        case .kawaii: return Tone(0xfff0a8)
        case .sticker: return Tone(0xffe14d)
        case .hose: return GesturePen.hoseCream
        case .mascot: return Tone(0xffd84a)
        case .doodle: return Tone(0xffe066)
        }
    }

    var dust: Tone {
        switch pen.style {
        case .kawaii: return Tone(0xf3eefc)
        case .sticker: return .white
        case .hose: return GesturePen.hoseCream
        case .mascot: return Tone(0xeef2ff)
        case .doodle: return Tone(0xe4e0f0)
        }
    }

    var sweatTone: Tone {
        switch pen.style {
        case .kawaii: return Tone(0x9fdcff)
        case .hose: return Tone(0xbfe6ff)
        default: return Tone(0x6cc8ff)
        }
    }

    var keyline: Tone {
        switch pen.style {
        case .kawaii: return Tone(0x4a3366)
        case .hose: return GesturePen.hoseInk
        default: return pen.ink
        }
    }

    func blob(_ pts: [CGPoint], _ tone: Tone, a: CGFloat, w: CGFloat = 1, seed: Int = 0, shine: CGPoint? = nil) {
        if pen.style == .kawaii {
            let p = GestureGeo.smoothP(pts, closed: true)
            pen.stroke(p, .white, pen.unit * 3.2 * w, a * 0.95)
            pen.stroke(p, keyline, pen.unit * 1.1 * w, a * 0.55)
            pen.fill(p, tone, a)
            if let shine {
                let r = pen.unit * 1.1
                pen.fill(CGPath(ellipseIn: CGRect(x: shine.x - r, y: shine.y - r * 0.7, width: 2 * r, height: 1.4 * r), transform: nil), .white, a * 0.85)
            }
        } else {
            pen.shape(pts, tone, alpha: a, smooth: true, w: 1.3 * w, seed: seed, shine: shine)
        }
    }

    func pop(at c: CGPoint, age a: CGFloat) {
        let u = a / 0.34
        guard u > 0, u < 1 else { return }
        let e = CatchMotion.ease(u)
        let r = s * (0.55 + 0.6 * e)
        let fade = pow(1 - u, 1.6) * 0.6
        let path = CGPath(ellipseIn: CGRect(x: c.x - r, y: c.y - r * 0.92, width: 2 * r, height: 1.84 * r), transform: nil)
        if pen.style != .kawaii && pen.style != .doodle {
            pen.stroke(path, keyline, max(1, s * 0.07 * (1 - e) + pen.unit * 1.2), alpha * fade * 0.5)
        }
        pen.stroke(path, accent, max(0.8, s * 0.055 * (1 - e) + 0.6), alpha * fade * 0.8)
    }

    func shock(around c: CGPoint, age a: CGFloat, face: CGFloat) {
        guard a > 0.02, a < 0.5 else { return }
        let grow = CatchMotion.ease((a - 0.02) / 0.1)
        let fade = 1 - GestureMotion.smooth((a - 0.32) / 0.18)
        let angles: [CGFloat] = [0.35, 0.95, 1.57, 2.19, 2.79]
        for (i, ang) in angles.enumerated() {
            let r0 = s * 0.62, r1 = s * (0.62 + 0.26 * grow)
            let dx = cos(ang), dy = sin(ang)
            let p0 = CGPoint(x: c.x + dx * r0, y: c.y + dy * r0 * 0.95)
            let p1 = CGPoint(x: c.x + dx * r1, y: c.y + dy * r1 * 0.95)
            pen.mark([p0, p1], pen.style == .kawaii ? bang.lift(0.1) : bang, alpha: alpha * fade, w: max(1.4, s * 0.075 / pen.unit), smooth: false, seed: i)
        }
    }

    func thump(x: CGFloat, ground: CGFloat, age a: CGFloat) {
        let u = (a - CatchMotion.land) / 0.36
        guard u > 0, u < 1 else { return }
        let e = CatchMotion.ease(u)
        let w = s * (0.62 + 0.75 * e), h = w * 0.24
        let fade = pow(1 - u, 1.3)
        let rect = CGRect(x: x - w / 2, y: ground - h / 2, width: w, height: h)
        ctx.setStrokeColor(red: 0.08, green: 0.05, blue: 0.16, alpha: 0.32 * alpha * fade)
        ctx.setLineWidth(max(1, s * 0.05 * (1 - e) + 0.8))
        ctx.strokeEllipse(in: rect)
    }

    func badge(at head: CGPoint, age a: CGFloat, fade: CGFloat, shake: CGFloat) {
        let t = a - 0.03
        guard t > 0, fade > 0.01 else { return }
        let pop = t < 0.1 ? CatchMotion.ease(t / 0.1) * 1.28 : 1 + 0.28 * exp(-(t - 0.1) * 14) * cos((t - 0.1) * 30)
        let k = max(0, pop)
        let a = alpha * fade
        let x = head.x + shake
        let h = s * 0.4 * k
        guard h > 1 else { return }
        let cy = head.y + s * 0.24 * k
        let burstR = s * 0.33 * k * (t < 0.42 ? 1 : max(0.78, 1 - (t - 0.42) * 0.6))
        let spin = 0.18 * sin(t * 3)
        let star = GesturePen.star(CGPoint(x: x, y: cy), burstR, points: 9, inner: 0.7, spin: spin)
        blob(star, burst, a: a * 0.96, w: 0.9, seed: 3)
        let w = h * 0.36
        let top = cy + h * 0.5, low = cy - h * 0.18
        let wedge = [
            CGPoint(x: x - w * 0.5, y: top - w * 0.12), CGPoint(x: x, y: top + w * 0.12), CGPoint(x: x + w * 0.5, y: top - w * 0.12),
            CGPoint(x: x + w * 0.2, y: low), CGPoint(x: x, y: low - w * 0.12), CGPoint(x: x - w * 0.2, y: low),
        ]
        blob(wedge, bang, a: a, w: 0.8, seed: 1, shine: CGPoint(x: x - w * 0.16, y: top - w * 0.3))
        let dot = CGPoint(x: x, y: cy - h * 0.38)
        blob(GesturePen.ring(dot, w * 0.27, w * 0.27, n: 10), bang, a: a, w: 0.8, seed: 2)
    }

    func drop(at c: CGPoint, r: CGFloat, tilt: CGFloat, a: CGFloat) {
        guard r > 0.6, a > 0.01 else { return }
        var pts: [CGPoint] = []
        for i in 0..<9 {
            let ang = -CGFloat.pi / 2 + CGFloat(i) / 8 * 2 * .pi
            pts.append(CGPoint(x: r * cos(ang), y: r * sin(ang)))
        }
        pts[4] = CGPoint(x: 0, y: r * 2.1)
        let cr = cos(tilt), sr = sin(tilt)
        let placed = pts.map { CGPoint(x: c.x + $0.x * cr - $0.y * sr, y: c.y + $0.x * sr + $0.y * cr) }
        blob(placed, sweatTone, a: a, w: 0.6, seed: 5, shine: CGPoint(x: c.x - r * 0.3, y: c.y + r * 0.2))
    }

    func sweat(head: CGPoint, age a: CGFloat, face: CGFloat, fade: CGFloat) {
        let u = (a - CatchMotion.land) / 0.5
        if u > 0, u < 1 {
            for side in [-1, 1] as [CGFloat] {
                let e = u
                let x = head.x + side * s * (0.28 + 0.55 * e)
                let y = head.y - s * 0.05 + s * (0.7 * e - 1.1 * e * e)
                drop(at: CGPoint(x: x, y: y), r: s * 0.065, tilt: side * (0.5 + 1.4 * e), a: alpha * (1 - GestureMotion.smooth((u - 0.6) / 0.4)))
            }
        }
        let b = a - 0.55
        if b > 0, fade > 0.01 {
            let slide = min(1, b / 0.9)
            let x = head.x + face * s * 0.36
            let y = head.y - s * 0.12 - s * 0.16 * slide
            drop(at: CGPoint(x: x, y: y), r: s * 0.06 * min(1, b / 0.12), tilt: face * 0.15, a: alpha * fade)
        }
    }

    func whistle(mouth: CGPoint, age a: CGFloat, face: CGFloat, fade: CGFloat) {
        let b = a - 0.6
        guard b > 0, fade > 0.01 else { return }
        for k in 0..<2 {
            let t = b - CGFloat(k) * 0.35
            guard t > 0 else { continue }
            let u = GestureMotion.frac(t / 0.7)
            let c = CGPoint(x: mouth.x + face * s * (0.18 + 0.25 * u), y: mouth.y + s * (0.05 + 0.4 * u))
            let r = s * 0.075
            let na = alpha * fade * (1 - GestureMotion.smooth((u - 0.6) / 0.4)) * GestureMotion.smooth(u / 0.15)
            let tone = pen.style == .hose ? GesturePen.hoseInk : Tone(0x7a6bd6)
            pen.shape(GesturePen.ring(c, r * 1.15, r * 0.85, n: 10, rot: 0.4), tone, alpha: na, w: 0.8, seed: k)
            pen.mark([CGPoint(x: c.x + r * 1.0, y: c.y + r * 0.2), CGPoint(x: c.x + r * 1.0, y: c.y + r * 3.2), CGPoint(x: c.x + r * 2.0, y: c.y + r * 2.6)], tone, alpha: na, w: max(1, r * 0.4 / pen.unit), smooth: false, seed: k)
        }
    }

    func puff(_ c: CGPoint, r: CGFloat, a: CGFloat, seed: Int) {
        guard r > 0.5, a > 0.01 else { return }
        let n = 9
        var pts: [CGPoint] = []
        for i in 0..<n {
            let ang = CGFloat(i) / CGFloat(n) * 2 * .pi + CGFloat(seed)
            let bump: CGFloat = i % 2 == 0 ? 1 : 0.8
            pts.append(CGPoint(x: c.x + r * bump * cos(ang), y: c.y + r * bump * 0.82 * sin(ang)))
        }
        if pen.style == .kawaii {
            let p = GestureGeo.smoothP(pts, closed: true)
            pen.stroke(p, keyline, pen.unit * 1.2, a * 0.35)
            pen.fill(p, dust, a * 0.92)
        } else {
            pen.shape(pts, dust, alpha: a, smooth: true, w: 0.9, seed: seed)
        }
    }

    func spin(x: CGFloat, ground: CGFloat, w: CGFloat, dirX: CGFloat) {
        let k = GestureMotion.smooth(w / 0.06)
        guard k > 0.01 else { return }
        let rx = s * 0.3, ry = s * 0.085
        let c = CGPoint(x: x, y: ground + ry * 0.4)
        for i in 0..<3 {
            let phase = w * 26 + CGFloat(i) * 2.1
            var pts: [CGPoint] = []
            for j in 0...6 {
                let ang = phase + CGFloat(j) / 6 * 2.2
                pts.append(CGPoint(x: c.x + rx * cos(ang) * (1 - 0.15 * CGFloat(i)), y: c.y + ry * sin(ang)))
            }
            pen.mark(pts, pen.style == .kawaii ? Tone(0x7a6aa8) : pen.ink.lift(pen.style == .doodle ? 0.3 : 0), alpha: alpha * k * 0.85, w: max(1, s * 0.04 / pen.unit), seed: i)
        }
        for i in 0..<3 {
            let life = GestureMotion.frac(w * 3.2 + CGFloat(i) / 3)
            let back = s * (0.3 + 0.5 * life)
            let p = CGPoint(x: x - dirX * back, y: ground + s * (0.05 + 0.2 * life))
            puff(p, r: s * (0.07 + 0.09 * life), a: alpha * k * (1 - life) * 0.9, seed: i)
        }
    }

    func dashCloud(from p: CGPoint, ground: CGFloat, age d: CGFloat) {
        let u = d / 0.9
        guard u > 0, u < 1 else { return }
        let e = CatchMotion.ease(min(1, u * 1.6))
        let fade = 1 - GestureMotion.smooth((u - 0.3) / 0.7)
        let base = CGPoint(x: p.x, y: ground)
        let spots: [(CGFloat, CGFloat, CGFloat)] = [(-0.34, 0.1, 0.2), (0, 0.2, 0.26), (0.32, 0.09, 0.19), (-0.14, 0.4, 0.17), (0.18, 0.36, 0.16)]
        for (i, sp) in spots.enumerated() {
            let c = CGPoint(x: base.x + sp.0 * s * (1 + 0.5 * e), y: base.y + sp.1 * s + s * 0.22 * u)
            puff(c, r: s * sp.2 * (0.5 + 0.6 * e) * (1 - 0.25 * u), a: alpha * fade, seed: i)
        }
    }

    func speedLines(from c: CGPoint, dirX: CGFloat, dirY: CGFloat, age d: CGFloat, speed: CGFloat) {
        let k = max(0, 1 - d / 0.7) * min(1, speed / (s * 4))
        guard k > 0.02 else { return }
        let nx = -dirY, ny = dirX
        let tone: Tone = pen.style == .hose ? GesturePen.hoseInk : (pen.style == .kawaii ? Tone(0x9c8fd0) : pen.ink.lift(0.15))
        for (i, o) in ([-0.26, 0.02, 0.28] as [CGFloat]).enumerated() {
            let start = s * (0.42 + (i == 1 ? 0 : 0.12))
            let len = s * (0.55 + (i == 1 ? 0.45 : 0.2)) * k
            let a = CGPoint(x: c.x - dirX * start + nx * o * s, y: c.y - dirY * start + ny * o * s)
            let b = CGPoint(x: a.x - dirX * len, y: a.y - dirY * len)
            pen.mark([a, b], tone, alpha: alpha * k * 0.85, w: max(1, s * 0.045 / pen.unit), smooth: false, seed: i)
        }
    }
}
