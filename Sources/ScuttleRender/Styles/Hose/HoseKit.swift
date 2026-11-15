import Foundation
import CoreGraphics
import ScuttleCore

enum HoseArt: FigureShapes {}

final class HoseKit: FigureCanvas {
    static let finish = SpriteFinish(border: 2.2, borderMinPt: 0.85, borderTone: Tone(0xf7eedb))

    let ink = Tone(0x17121a)
    let cream = Tone(0xf7eedb)
    let red = Tone(0xd8402b)
    let accents = [Tone(0xd8402b), Tone(0x3a8f5c), Tone(0xe8a92a), Tone(0x2f5fa8), Tone(0xd96a8e)]

    var line: CGFloat { width(2.6, minPt: 0.8) }
    var limb: CGFloat { width(3.8, minPt: 1.1) }

    func part(_ p: CGPath, _ base: Tone, w: CGFloat? = nil) {
        fill(p, base)
        stroke(p, ink, w ?? line)
    }

    func solid(_ p: CGPath) {
        fill(p, ink)
        stroke(p, ink, line)
    }

    func shine(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ rot: CGFloat = 0.4) {
        fill(Self.ell(x, y, rx, ry, rot), Tone.white.alpha(0.75))
    }

    func noodle(_ a: [CGFloat], w: CGFloat? = nil) {
        stroke(Self.smooth(a, closed: false), ink, w ?? limb)
    }

    func bend(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat, sag: CGFloat) -> [CGFloat] {
        let mx = (x0 + x1) / 2, my = (y0 + y1) / 2
        let dx = x1 - x0, dy = y1 - y0
        let l = max(0.001, hypot(dx, dy))
        return [x0, y0, mx - dy / l * sag, my + dx / l * sag, x1, y1]
    }

    func glove(_ x: CGFloat, _ y: CGFloat, _ ang: CGFloat, _ s: CGFloat = 1) {
        with(CGAffineTransform(translationX: x, y: y).rotated(by: ang).scaledBy(x: s, y: s)) {
            let parts = [
                Self.ell(0, 5, 5.2, 4.8),
                Self.ell(-3.3, 9.2, 2.0, 3.3),
                Self.ell(0, 10.3, 2.1, 3.5),
                Self.ell(3.3, 9.2, 2.0, 3.3),
                Self.ell(-5.4, 4.2, 1.9, 3.1, 0.75),
            ]
            let cuff = Self.smooth([-4.6, 1.2, 4.6, 1.2, 3.6, -3.2, -3.6, -3.2])
            let edge = max(3.2, line * 1.25) / max(0.3, s)
            for p in parts + [cuff] { stroke(p, ink, edge) }
            for p in parts { fill(p, cream) }
            fill(cuff, cream)
            stroke(cuff, ink, 1.4)
            stroke(Self.poly([-1.6, 7.6, -1.6, 9.4], closed: false), ink, 1.1)
            stroke(Self.poly([1.6, 7.6, 1.6, 9.4], closed: false), ink, 1.1)
        }
    }

    func fist(_ x: CGFloat, _ y: CGFloat, _ ang: CGFloat, _ s: CGFloat = 1) {
        with(CGAffineTransform(translationX: x, y: y).rotated(by: ang).scaledBy(x: s, y: s)) {
            let ball = Self.uni([Self.ell(0, 5, 5.4, 5.0), Self.ell(-4.6, 4.6, 2.2, 2.8, 0.6)])
            let cuff = Self.smooth([-4.6, 1.2, 4.6, 1.2, 3.6, -3.2, -3.6, -3.2])
            let edge = max(3.2, line * 1.25) / max(0.3, s)
            stroke(ball, ink, edge)
            stroke(cuff, ink, edge)
            fill(ball, cream)
            fill(cuff, cream)
            stroke(cuff, ink, 1.4)
            stroke(Self.arc(-2.5, 6.5, 2.5, 6.5, dip: -1.2), ink, 1.1)
        }
    }

    func boot(_ x: CGFloat, _ y: CGFloat, _ ang: CGFloat = 0, color: Tone? = nil) {
        with(CGAffineTransform(translationX: x, y: y).rotated(by: ang)) {
            let shoe = Self.uni([Self.ell(3.5, 3.4, 7.2, 5.0), Self.ell(-3, 2.6, 5.2, 3.6)])
            stroke(shoe, ink, 2 * line)
            fill(shoe, color ?? cream)
            fill(Self.ell(5, 5.2, 2.4, 1.4, 0.3), Tone.white.alpha(0.7))
            stroke(Self.poly([-7.6, -0.2, 10, -0.2], closed: false), ink, 2.2)
        }
    }

    func step(_ which: Int, reach: CGFloat, lift: CGFloat) -> CGPoint {
        let a = f.t + (which == 0 ? 0 : .pi)
        return CGPoint(x: reach * sin(a), y: lift * max(0, cos(a)))
    }

    func pie(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, dir: CGFloat = 1.15) {
        let e = Self.ell(x, y, rx, ry)
        let ax = x + rx * 0.1, ay = y + ry * 0.05
        let R = ry * 3
        let wedge = Self.poly([ax, ay, ax + cos(dir - 0.42) * R, ay + sin(dir - 0.42) * R, ax + cos(dir + 0.42) * R, ay + sin(dir + 0.42) * R])
        fill(e.subtracting(wedge), ink)
    }

    func eye(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, look: CGFloat = 0) {
        switch f.mood {
        case .dizzy:
            let w = Self.ell(x, y, rx * 1.35, ry * 1.15)
            part(w, cream, w: line * 0.8)
            stroke(Self.spiral(x, y, min(rx * 1.1, ry * 0.9), turns: 1.7, spin: look >= 0 ? 1 : -1, start: f.t), ink, line * 0.75)
        case _ where f.eyesShut:
            stroke(Self.arc(x - rx * 1.2, y + ry * 0.05, x + rx * 1.2, y + ry * 0.05, dip: ry * 0.55), ink, line * 1.25)
            if f.mood == .sleepy {
                stroke(Self.line(x + rx * 1.1, y - ry * 0.05, x + rx * 1.7, y - ry * 0.35), ink, line * 0.7)
            }
        case .startled:
            let w = Self.ell(x, y + ry * 0.15, rx * 1.55, ry * 1.4)
            part(w, cream, w: line * 0.8)
            pie(x + look * rx * 0.2, y + ry * 0.05, rx * 0.55, ry * 0.5)
        case .fleeing:
            let w = Self.ell(x, y, rx * 1.35, ry * 1.2)
            part(w, cream, w: line * 0.8)
            clip(w) { pie(x + rx * 0.55, y - ry * 0.05, rx * 0.8, ry * 0.85, dir: 2.0) }
        default:
            pie(x + look * rx * 0.2, y, rx, ry)
        }
    }

    func mouth(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) {
        switch f.mood {
        case .calm:
            let p = CGMutablePath()
            p.move(to: Self.pt(x - w / 2, y))
            p.addQuadCurve(to: Self.pt(x + w / 2, y), control: Self.pt(x, y - h * 0.35))
            p.addCurve(to: Self.pt(x - w / 2, y), control1: Self.pt(x + w * 0.42, y - h * 1.5), control2: Self.pt(x - w * 0.42, y - h * 1.5))
            p.closeSubpath()
            fill(p, ink)
            clip(p) { fill(Self.ell(x + w * 0.08, y - h * 1.15, w * 0.26, h * 0.5), red) }
            for s: CGFloat in [-1, 1] {
                let c = CGMutablePath()
                c.move(to: Self.pt(x + s * (w / 2 + 1.2), y + 2))
                c.addQuadCurve(to: Self.pt(x + s * (w / 2 + 0.6), y - 1.8), control: Self.pt(x + s * (w / 2 + 2.6), y))
                stroke(c, ink, line * 0.62)
            }
        case .sleepy:
            fill(Self.ell(x, y - h * 0.3, w * 0.12, h * 0.42), ink)
        case .startled:
            let o = Self.ell(x, y - h * 0.5, w * 0.24, h * 1.05)
            fill(o, ink)
            clip(o) { fill(Self.ell(x, y - h * 1.35, w * 0.2, h * 0.45), red) }
        case .fleeing:
            let r = Self.rrect(x - w * 0.42, y - h * 1.1, w * 0.84, h * 1.0, h * 0.45)
            part(r, cream, w: line * 0.9)
            for k in [-0.21, 0.0, 0.21] as [CGFloat] {
                stroke(Self.line(x + w * k, y - h * 1.05, x + w * k, y - h * 0.15), ink, line * 0.5)
            }
            stroke(Self.line(x - w * 0.4, y - h * 0.6, x + w * 0.4, y - h * 0.6), ink, line * 0.5)
        case .dizzy:
            stroke(Self.wavy(x - w * 0.4, y - h * 0.4, x + w * 0.4, y - h * 0.4, waves: 1.5, amp: h * 0.3, phase: f.t), ink, line)
        }
    }

    func marks(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat = 12) {
        switch f.mood {
        case .startled:
            for a in [-0.25, 0.35, 0.95, 1.55, 2.15] as [CGFloat] {
                let ca = cos(a), sa = sin(a)
                stroke(Self.line(x + ca * s * 0.35, y + sa * s * 0.35, x + ca * s * 0.8, y + sa * s * 0.8), ink, line)
            }
        case .sleepy:
            let rise = CGFloat(f.frameIndex % 8) / 8
            for (i, k) in ([1.0, 0.7] as [CGFloat]).enumerated() {
                let zx = x + CGFloat(i) * s * 0.8, zy = y + CGFloat(i) * s * 0.75 + rise * s * 0.25
                let h = s * 0.4 * k
                stroke(Self.poly([zx - h, zy + h, zx + h, zy + h, zx - h, zy - h, zx + h, zy - h], closed: false), ink, line)
            }
        case .fleeing:
            for i in 0..<3 {
                let dx = -CGFloat(i) * s * 0.55, dy = CGFloat(i % 2) * s * 0.3
                part(Self.drop(x + dx, y + dy, s * (0.22 - CGFloat(i) * 0.03), 0.9), cream, w: line * 0.7)
            }
        default:
            break
        }
    }

    func placeholder(_ tone: Tone? = nil) {
        let accent = tone ?? red
        let sq = 1 + 0.05 * f.swing2 * f.energy
        let air = f.species.isAirborne
        let base: CGFloat = air ? 16 : 14
        if !air {
            for which in 0..<2 {
                let s = step(which, reach: 7 * f.energy, lift: 5 * f.energy)
                let hx: CGFloat = which == 0 ? 44 : 56
                noodle(bend(hx, base + 10, hx + s.x, 7 + s.y, sag: 3))
                boot(hx + s.x, 4 + s.y, 0, color: accent)
            }
        }
        with(Self.about(50, base, sx: 1 / sq, sy: sq)) {
            if air {
                both { s in
                    part(Self.ell(50 + s * 30, 58 + f.swing * 4, 12, 8, s * (0.45 + f.swing * 0.35)), cream)
                }
            }
            let b = Self.ell(50, base + 30, 25, 28)
            solid(b)
            let face = Self.ell(57, base + 36, 15, 13)
            part(face, cream)
            eye(52, base + 40, 2.6, 4.4)
            eye(61, base + 40, 2.6, 4.4)
            mouth(57, base + 31, 10, 3.6)
            shine(38, base + 46, 4, 2.2, 0.7)
            marks(76, base + 60, 12)
        }
    }
}
