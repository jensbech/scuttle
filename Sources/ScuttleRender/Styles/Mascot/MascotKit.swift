import Foundation
import CoreGraphics
import ScuttleCore

enum MascotArt: FigureShapes {}

struct MascotTones {
    var base: Tone
    var shade: Tone
    var line: Tone

    init(_ base: Tone, shade: Tone? = nil, line: Tone? = nil) {
        self.base = base
        self.shade = shade ?? base.dim(0.78).mix(Tone(0x3a2a80), 0.14)
        self.line = line ?? base.dim(0.32).mix(Tone(0x1a1030), 0.4)
    }
}

final class MascotKit: FigureCanvas {
    static let finish = SpriteFinish(border: 2.0, borderMinPt: 0.8, borderTone: Tone(0xf2efff, 0.92))

    let blushTone = Tone(0xff7d9c, 0.75)
    let mouthTone = Tone(0x5b1626)
    let tongue = Tone(0xff7a92)
    let pupil = Tone(0x140c1c)
    let sweatTone = Tone(0x8fdcff)

    var line: CGFloat { width(2.6, minPt: 0.85) }
    var bold: CGFloat { width(2.9, minPt: 0.95) }

    func cel(_ p: CGPath, _ base: Tone, _ shade: Tone, _ edge: Tone, _ w: CGFloat? = nil, k: CGFloat = 0.2) {
        let bb = p.boundingBoxOfPath
        let s = k * min(bb.width, bb.height)
        fill(p, shade)
        clip(p) { fill(Self.xf(p, CGAffineTransform(translationX: -s, y: s * 0.9)), base) }
        stroke(p, edge, w ?? line)
    }

    func cel(_ p: CGPath, _ t: MascotTones, _ w: CGFloat? = nil, k: CGFloat = 0.2) {
        cel(p, t.base, t.shade, t.line, w, k: k)
    }

    func blush(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat = 4.6, _ ry: CGFloat = 2.6) {
        fill(Self.ell(x, y, rx, ry), blushTone)
    }

    func eye(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, iris: Tone, edge: Tone, lid: Tone? = nil, side: CGFloat = 1, look: CGFloat = 0.12) {
        let sc = Self.ell(x, y, rx, ry)
        let irisLight = iris.lift(0.45)
        let m = f.mood
        if m == .dizzy {
            fill(sc, .white)
            stroke(Self.spiral(x, y, min(rx, ry) * 0.8, turns: 2, spin: side, start: f.t), iris.dim(0.7), line * 0.9)
            stroke(sc, edge, line * 0.92)
            return
        }
        if f.blink || (m == .sleepy && f.frameIndex % 8 > 5) {
            stroke(Self.arc(x - rx * 0.85, y - ry * 0.15, x + rx * 0.85, y - ry * 0.15, dip: -ry * 0.55), edge, bold)
            stroke(Self.line(x + side * rx * 0.8, y - ry * 0.12, x + side * rx * 1.2, y - ry * 0.3), edge, line * 0.7)
            return
        }
        var ix = x + rx * look, iy = y - ry * 0.08
        var irisR: CGFloat = 0.64, pupilR: CGFloat = 0.32
        switch m {
        case .startled:
            irisR = 0.42
            pupilR = 0.16
            ix = x
            iy = y
        case .fleeing:
            ix = x + rx * 0.3
            iy = y - ry * 0.12
            irisR = 0.56
            pupilR = 0.26
        case .sleepy:
            iy = y - ry * 0.3
        default:
            break
        }
        fill(sc, .white)
        clip(sc) {
            fill(Self.ell(ix, iy, rx * irisR, ry * irisR * 1.03), iris)
            fill(Self.ell(ix, iy - ry * irisR * 0.45, rx * irisR * 0.78, ry * irisR * 0.46), irisLight)
            fill(Self.ell(ix, iy + ry * 0.04, rx * pupilR, ry * pupilR * 1.12), pupil)
            fill(Self.ell(x, y + ry * 0.75, rx * 1.1, ry * 0.32), Tone(0xdde0f0))
            if m == .sleepy {
                let lidTone = lid ?? edge.lift(0.55)
                fill(Self.rrect(x - rx * 1.2, y + ry * 0.05, rx * 2.4, ry * 1.2, 0), lidTone)
                stroke(Self.line(x - rx * 1.2, y + ry * 0.05, x + rx * 1.2, y + ry * 0.05), edge, bold)
            }
        }
        if m != .sleepy {
            fill(Self.ell(ix - rx * irisR * 0.3, iy + ry * irisR * 0.45, rx * irisR * 0.5, ry * irisR * 0.45), .white)
            fill(Self.circ(ix + rx * irisR * 0.55, iy - ry * irisR * 0.45, rx * irisR * 0.22), .white)
        }
        if m == .fleeing {
            fill(Self.drop(x - side * rx * 0.2, y - ry * 1.05, rx * 0.28, 0), sweatTone)
        }
        stroke(sc, edge, line * 0.92)
    }

    func brow(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, side: CGFloat, edge: Tone) {
        var tilt: CGFloat = -side * 0.5
        var lift: CGFloat = 0
        var arch: CGFloat = 3.2
        switch f.mood {
        case .startled:
            lift = 4
            arch = 4.5
            tilt = side * 0.6
        case .fleeing:
            lift = 1.5
            tilt = -side * 2.6
            arch = 1.5
        case .sleepy:
            lift = -2
            tilt = side * 0.3
            arch = 0.6
        case .dizzy:
            lift = side * 2
            tilt = side * 2.2
            arch = 2
        case .calm:
            if f.twitch != 0 && side == f.twitch { lift = 1.6 }
        }
        let p = CGMutablePath()
        p.move(to: Self.pt(x - w / 2, y + lift - tilt))
        p.addQuadCurve(to: Self.pt(x + w / 2, y + lift + tilt), control: Self.pt(x, y + lift + arch))
        stroke(p, edge, max(3.2, line * 1.2))
    }

    func mouth(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, edge: Tone) {
        let lw = line * 0.85
        switch f.mood {
        case .calm:
            let p = CGMutablePath()
            p.move(to: Self.pt(x - w / 2, y))
            p.addQuadCurve(to: Self.pt(x + w / 2, y), control: Self.pt(x, y - h * 0.18))
            p.addCurve(to: Self.pt(x - w / 2, y), control1: Self.pt(x + w * 0.46, y - h * 1.35), control2: Self.pt(x - w * 0.46, y - h * 1.35))
            p.closeSubpath()
            fill(p, mouthTone)
            clip(p) {
                fill(Self.ell(x, y - h * 1.0, w * 0.34, h * 0.45), tongue)
                fill(Self.rrect(x - w * 0.3, y - h * 0.3, w * 0.6, h * 0.3, 1), .white)
            }
            stroke(p, edge, lw)
        case .sleepy:
            let o = Self.ell(x, y - h * 0.35, w * 0.16, h * 0.28)
            fill(o, mouthTone)
            stroke(o, edge, lw)
        case .startled:
            let o = Self.ell(x, y - h * 0.55, w * 0.3, h * 0.75)
            fill(o, mouthTone)
            clip(o) { fill(Self.ell(x, y - h * 1.15, w * 0.24, h * 0.35), tongue) }
            stroke(o, edge, lw)
        case .fleeing:
            let p = CGMutablePath()
            p.move(to: Self.pt(x - w * 0.55, y - h * 0.15))
            p.addQuadCurve(to: Self.pt(x + w * 0.55, y - h * 0.15), control: Self.pt(x, y + h * 0.35))
            p.addCurve(to: Self.pt(x - w * 0.55, y - h * 0.15), control1: Self.pt(x + w * 0.5, y - h * 1.3), control2: Self.pt(x - w * 0.5, y - h * 1.3))
            p.closeSubpath()
            fill(p, mouthTone)
            clip(p) {
                fill(Self.rrect(x - w * 0.6, y - h * 0.32, w * 1.2, h * 0.5, 0), .white)
                fill(Self.ell(x, y - h * 1.05, w * 0.3, h * 0.3), tongue)
            }
            stroke(p, edge, lw)
        case .dizzy:
            stroke(Self.wavy(x - w * 0.45, y - h * 0.4, x + w * 0.45, y - h * 0.4, waves: 1.5, amp: h * 0.22, phase: f.t), edge, lw * 1.2)
        }
    }

    func bounce(_ amount: CGFloat = 1) -> (sx: CGFloat, sy: CGFloat) {
        var sy: CGFloat = 1 + 0.05 * amount * f.swing2 * f.energy
        switch f.mood {
        case .startled: sy *= 1.08
        case .sleepy: sy *= 0.94
        default: break
        }
        if f.locomotion == .hop {
            sy = 1 - 0.16 * f.squat + 0.1 * f.stretch
        }
        return (1 / sy.squareRoot(), sy)
    }

    func marks(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat = 12, edge: Tone) {
        switch f.mood {
        case .sleepy:
            let rise = CGFloat(f.frameIndex % 8) / 8
            for (i, k) in ([1.0, 0.7] as [CGFloat]).enumerated() {
                let zx = x + CGFloat(i) * s * 0.8, zy = y + CGFloat(i) * s * 0.75 + rise * s * 0.25
                let h = s * 0.4 * k
                let z = Self.poly([zx - h, zy + h, zx + h, zy + h, zx - h, zy - h, zx + h, zy - h], closed: false)
                stroke(z, edge, line * 2.2)
                stroke(z, Tone(0xcfc6ff), line)
            }
        case .fleeing:
            let d = Self.drop(x, y, s * 0.34, -0.3)
            cel(d, sweatTone, sweatTone.dim(0.8), edge, line * 0.8)
            fill(Self.ell(x - s * 0.08, y + s * 0.05, s * 0.07, s * 0.12, -0.3), .white)
        case .startled:
            for a in [0.3, 0.9, 1.5] as [CGFloat] {
                let ca = cos(a + 0.2), sa = sin(a + 0.2)
                let seg = Self.line(x + ca * s * 0.35, y + sa * s * 0.35, x + ca * s * 0.85, y + sa * s * 0.85)
                stroke(seg, edge, line * 2)
                stroke(seg, Tone(0xffe066), line * 0.9)
            }
        default:
            break
        }
    }

    func placeholder(_ tone: Tone, iris: Tone = Tone(0x2a6fe0)) {
        let t = MascotTones(tone)
        let b = bounce()
        let air = f.species.isAirborne
        let base: CGFloat = air ? 10 : 4
        with(Self.about(50, base, sx: b.sx, sy: b.sy)) {
            if air {
                both { s in
                    cel(Self.ell(50 + s * 30, 50 + f.swing * 4, 11, 7, s * (0.5 + f.swing * 0.4)), MascotTones(tone.lift(0.35)))
                }
            } else {
                let step = f.swing * 3 * f.energy
                cel(Self.ell(43 + step, base + 2, 6, 3.2), t)
                cel(Self.ell(57 - step, base + 2, 6, 3.2), t)
            }
            cel(Self.ell(50, base + 14, 12, 11), t)
            let head = Self.circ(50, base + 50, 30)
            cel(head, t, bold, k: 0.12)
            eye(42, base + 53, 7.5, 10, iris: iris, edge: t.line, side: -1)
            eye(60, base + 53, 7.5, 10, iris: iris, edge: t.line, side: 1)
            brow(42, base + 68, 9, side: -1, edge: t.line)
            brow(60, base + 68, 9, side: 1, edge: t.line)
            blush(31, base + 43)
            blush(70, base + 43)
            mouth(52, base + 40, 11, 7, edge: t.line)
            marks(80, base + 74, 12, edge: t.line)
        }
    }
}
