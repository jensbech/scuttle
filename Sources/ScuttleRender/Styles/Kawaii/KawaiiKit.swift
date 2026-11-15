import Foundation
import CoreGraphics
import ScuttleCore

enum KawaiiArt: FigureShapes {}

enum KawaiiMouth {
    case cat
    case smile
    case none
}

final class KawaiiKit: FigureCanvas {
    static let finish = SpriteFinish(border: 1.1, borderMinPt: 0.7, borderTone: Tone(0x6a4a86, 0.5), shadowBlur: 3, shadowMinPt: 1.2, shadowDrop: 0.9, shadowTone: Tone(0x3a2456, 0.75))

    let eyeTone = Tone(0x3d2c40)
    let blushTone = Tone(0xff9db8, 0.85)
    let mouthTone = Tone(0x8a4a5e)
    let markTone = Tone(0x9a86d8)
    let sweatTone = Tone(0x8fd3ff)

    var line: CGFloat { width(1.5, minPt: 0.6) }

    func shade(_ base: Tone) -> Tone {
        base.dim(0.93).mix(Tone(0x9d86d6), 0.17)
    }

    func body(_ p: CGPath, _ base: Tone, shade s: Tone? = nil, depth: CGFloat = 0.3) {
        fill(p, base)
        let bb = p.boundingBoxOfPath
        clip(p) {
            fill(Self.ell(bb.midX + bb.width * 0.2, bb.minY + bb.height * 0.03, bb.width * 0.8, bb.height * depth), s ?? shade(base))
        }
    }

    func shine(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ rot: CGFloat = 0.7) {
        fill(Self.ell(x, y, rx, ry, rot), Tone.white.alpha(0.88))
    }

    func nub(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ tone: Tone, _ rot: CGFloat = 0) {
        fill(Self.ell(x, y, rx, ry, rot), tone)
    }

    func blush(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat = 4.6, _ ry: CGFloat = 2.7) {
        fill(Self.ell(x, y, rx, ry), blushTone)
    }

    func eye(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, side: CGFloat) {
        let m = f.mood
        if m == .dizzy {
            stroke(Self.spiral(x, y, r * 1.45, turns: 1.6, spin: side, start: f.t), eyeTone, max(r * 0.42, line * 0.8))
            return
        }
        if f.eyesShut {
            stroke(Self.arc(x - r * 1.15, y + r * 0.25, x + r * 1.15, y + r * 0.25, dip: r * 1.5), eyeTone, max(r * 0.55, line))
            return
        }
        switch m {
        case .fleeing:
            let p = CGMutablePath()
            p.move(to: Self.pt(x - side * r * 1.0, y + r * 1.05))
            p.addLine(to: Self.pt(x + side * r * 0.9, y))
            p.addLine(to: Self.pt(x - side * r * 1.0, y - r * 1.05))
            stroke(p, eyeTone, max(r * 0.6, line))
        case .startled:
            let rr = r * 1.35
            fill(Self.circ(x, y, rr), eyeTone)
            fill(Self.circ(x + rr * 0.32, y + rr * 0.34, rr * 0.4), .white)
            fill(Self.circ(x - rr * 0.38, y - rr * 0.36, rr * 0.17), .white)
        default:
            fill(Self.circ(x, y, r), eyeTone)
            fill(Self.circ(x + r * 0.35, y + r * 0.35, r * 0.32), .white)
        }
    }

    func mouth(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat = 5.6, kind: KawaiiMouth = .cat) {
        guard kind != .none else { return }
        let lw = max(line, w * 0.24)
        switch f.mood {
        case .startled:
            fill(Self.ell(x, y - w * 0.12, w * 0.3, w * 0.4), mouthTone)
            fill(Self.ell(x, y - w * 0.3, w * 0.18, w * 0.14), Tone(0xff9db8))
        case .sleepy:
            fill(Self.ell(x, y - w * 0.05, w * 0.17, w * 0.2), mouthTone)
        case .fleeing:
            stroke(Self.wavy(x - w * 0.55, y - w * 0.1, x + w * 0.55, y - w * 0.1, waves: 1.5, amp: w * 0.12), eyeTone, lw)
        case .dizzy:
            stroke(Self.wavy(x - w * 0.5, y - w * 0.1, x + w * 0.5, y - w * 0.1, waves: 1, amp: w * 0.16, phase: f.t), eyeTone, lw)
        case .calm:
            if kind == .cat {
                let h = w / 2
                let p = CGMutablePath()
                p.move(to: Self.pt(x - h, y + h * 0.15))
                p.addQuadCurve(to: Self.pt(x, y + h * 0.05), control: Self.pt(x - h * 0.5, y - h * 0.8))
                p.addQuadCurve(to: Self.pt(x + h, y + h * 0.15), control: Self.pt(x + h * 0.5, y - h * 0.8))
                stroke(p, eyeTone, lw)
            } else {
                stroke(Self.arc(x - w * 0.4, y, x + w * 0.4, y, dip: w * 0.38), eyeTone, lw)
            }
        }
    }

    func face(_ cx: CGFloat, _ cy: CGFloat, spread: CGFloat = 12, r: CGFloat = 2.7, mouth kind: KawaiiMouth = .cat, blush showBlush: Bool = true) {
        if showBlush {
            let bx = spread + r * 1.9
            blush(cx - bx, cy - r * 1.5, r * 1.75, r * 1.0)
            blush(cx + bx, cy - r * 1.5, r * 1.75, r * 1.0)
        }
        eye(cx - spread, cy, r, side: -1)
        eye(cx + spread, cy, r, side: 1)
        mouth(cx, cy - r * 0.5, r * 2.1, kind: kind)
    }

    func marks(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat = 10) {
        switch f.mood {
        case .sleepy:
            let lw = max(s * 0.13, line)
            let rise = CGFloat(f.frameIndex % 8) / 8
            for (i, k) in ([1.0, 0.68] as [CGFloat]).enumerated() {
                let zx = x + CGFloat(i) * s * 0.75, zy = y + CGFloat(i) * s * 0.7 + rise * s * 0.25
                let h = s * 0.42 * k
                stroke(Self.poly([zx - h, zy + h, zx + h, zy + h, zx - h, zy - h, zx + h, zy - h], closed: false), markTone, lw)
            }
        case .fleeing:
            let d = Self.drop(x, y, s * 0.32, -0.35)
            fill(d, sweatTone)
            fill(Self.ell(x - s * 0.08, y + s * 0.02, s * 0.07, s * 0.12, -0.35), Tone.white.alpha(0.9))
        case .startled:
            let lw = max(s * 0.12, line)
            for a in [0.35, 0.95, 1.55] as [CGFloat] {
                let ca = cos(a + 0.2), sa = sin(a + 0.2)
                stroke(Self.line(x + ca * s * 0.35, y + sa * s * 0.35, x + ca * s * 0.75, y + sa * s * 0.75), Tone(0xff8fab), lw)
            }
        default:
            break
        }
    }

    func bow(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ tone: Tone, _ rot: CGFloat = 0) {
        with(Self.about(x, y, rot: rot)) {
            fill(Self.smooth([x, y, x - s * 1.2, y + s * 0.7, x - s * 1.25, y - s * 0.7], t: 0.5), tone)
            fill(Self.smooth([x, y, x + s * 1.2, y + s * 0.7, x + s * 1.25, y - s * 0.7], t: 0.5), tone)
            fill(Self.circ(x, y, s * 0.42), tone.dim(0.92).mix(Tone(0xff6f9a), 0.25))
        }
    }

    func flower(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ petal: Tone, _ center: Tone = Tone(0xffd36b)) {
        for i in 0..<5 {
            let a = CGFloat(i) / 5 * 2 * .pi + 0.3
            fill(Self.circ(x + cos(a) * s * 0.62, y + sin(a) * s * 0.62, s * 0.5), petal)
        }
        fill(Self.circ(x, y, s * 0.42), center)
    }

    func placeholder(_ raw: Tone, accent: Tone? = nil) {
        let tone = raw.lift(0.4)
        let sq = 1 + 0.04 * f.swing2 * f.energy
        let air = f.species.isAirborne
        let base: CGFloat = air ? 14 : 6
        with(Self.about(50, base, sx: 1 / sq, sy: sq)) {
            if air {
                both { s in
                    let flap = f.swing * 0.35
                    nub(50 + s * 34, 52 + f.swing * 3, 12, 8, accent ?? tone.lift(0.4), s * (0.5 + flap))
                }
            } else {
                let step = f.swing * 4 * f.energy
                nub(38 + step, base + 1, 7, 4, shade(tone))
                nub(62 - step, base + 1, 7, 4, shade(tone))
            }
            let b = Self.ell(50, base + 34, 32, 31)
            body(b, tone)
            shine(34, base + 52, 5, 3.2)
            face(54, base + 32, spread: 11, r: 2.6)
            marks(78, base + 64, 12)
        }
    }
}
