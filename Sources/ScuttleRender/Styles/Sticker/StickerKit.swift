import Foundation
import CoreGraphics
import ScuttleCore

enum StickerArt: FigureShapes {}

enum StickerMouth {
    case smile
    case none
}

final class StickerKit: FigureCanvas {
    static let finish = SpriteFinish(
        border: 4.6, borderMinPt: 1.6, borderTone: .white,
        shadowBlur: 4.5, shadowMinPt: 1.4, shadowDrop: 2.2, shadowTone: Tone(0x000000, 0.5))

    let ink = Tone(0x1d1630)
    let blushTone = Tone(0xff8fa8)
    let iris = Tone(0x4a4590)
    let tongue = Tone(0xff6b81)
    let sweatTone = Tone(0x7fd0ff)

    var line: CGFloat { width(3.2, minPt: 0.95) }
    var thin: CGFloat { width(2.4, minPt: 0.75) }

    func shade(_ base: Tone) -> Tone {
        base.dim(0.8).mix(Tone(0x3c2f86), 0.12)
    }

    func shadowShape(for p: CGPath) -> CGPath {
        let bb = p.boundingBoxOfPath
        return Self.ell(bb.maxX + bb.width * 0.18, bb.minY + bb.height * 0.3, bb.width * 0.4, bb.height * 0.7)
    }

    func part(_ p: CGPath, _ base: Tone, shadow: Tone? = nil, shape: CGPath? = nil, w: CGFloat? = nil) {
        fill(p, base)
        clip(p) { fill(shape ?? shadowShape(for: p), shadow ?? shade(base)) }
        stroke(p, ink, w ?? line)
    }

    func flat(_ p: CGPath, _ base: Tone, w: CGFloat? = nil) {
        fill(p, base)
        stroke(p, ink, w ?? line)
    }

    func gloss(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ rot: CGFloat = 0.6) {
        fill(Self.ell(x, y, rx, ry, rot), Tone.white.alpha(0.92))
    }

    func blush(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat = 4.4, _ ry: CGFloat = 2.6) {
        fill(Self.ell(x, y, rx, ry), blushTone)
    }

    func eye(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, side: CGFloat, look: CGFloat = 0) {
        let m = f.mood
        if m == .dizzy {
            let sc = Self.ell(x, y, rx * 1.1, ry * 1.0)
            fill(sc, .white)
            stroke(Self.spiral(x, y, min(rx, ry) * 0.85, turns: 1.6, spin: side, start: f.t), ink, thin)
            stroke(sc, ink, thin)
            return
        }
        if f.eyesShut {
            stroke(Self.arc(x - rx * 1.1, y + ry * 0.1, x + rx * 1.1, y + ry * 0.1, dip: ry * 0.75), ink, line)
            return
        }
        switch m {
        case .fleeing:
            let p = CGMutablePath()
            p.move(to: Self.pt(x - side * rx * 0.9, y + ry * 0.75))
            p.addLine(to: Self.pt(x + side * rx * 0.8, y))
            p.addLine(to: Self.pt(x - side * rx * 0.9, y - ry * 0.75))
            stroke(p, ink, line * 1.1)
        case .startled:
            let sc = Self.ell(x, y, rx * 1.15, ry * 1.12)
            fill(sc, .white)
            fill(Self.circ(x + look * rx * 0.2, y, rx * 0.42), ink)
            fill(Self.circ(x + look * rx * 0.2 + rx * 0.14, y + rx * 0.16, rx * 0.14), .white)
            stroke(sc, ink, thin)
        default:
            let ox = look * rx * 0.25
            fill(Self.ell(x + ox, y, rx, ry), ink)
            fill(Self.ell(x + ox, y - ry * 0.5, rx * 0.62, ry * 0.26), iris)
            fill(Self.ell(x + ox + rx * 0.25, y + ry * 0.3, rx * 0.46, ry * 0.36), .white)
            fill(Self.circ(x + ox - rx * 0.38, y - ry * 0.12, rx * 0.2), .white)
        }
    }

    func mouth(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat = 8, kind: StickerMouth = .smile) {
        guard kind != .none else { return }
        switch f.mood {
        case .calm:
            stroke(Self.arc(x - w / 2, y, x + w / 2, y, dip: w * 0.44), ink, thin)
        case .sleepy:
            fs(Self.ell(x, y - w * 0.1, w * 0.16, w * 0.2), tongue.dim(0.6), ink, thin * 0.8)
        case .startled:
            let o = Self.ell(x, y - w * 0.2, w * 0.32, w * 0.42)
            fill(o, ink)
            clip(o) { fill(Self.ell(x, y - w * 0.55, w * 0.26, w * 0.2), tongue) }
            stroke(o, ink, thin)
        case .fleeing:
            let r = Self.rrect(x - w * 0.55, y - w * 0.5, w * 1.1, w * 0.55, w * 0.22)
            fill(r, ink)
            clip(r) {
                fill(Self.rrect(x - w * 0.6, y - w * 0.2, w * 1.2, w * 0.3, 0), .white)
                stroke(Self.line(x, y - w * 0.2, x, y + w * 0.1), ink, thin * 0.6)
            }
            stroke(r, ink, thin)
        case .dizzy:
            stroke(Self.wavy(x - w * 0.55, y - w * 0.1, x + w * 0.55, y - w * 0.1, waves: 1.5, amp: w * 0.14, phase: f.t), ink, thin)
        }
    }

    func face(_ cx: CGFloat, _ cy: CGFloat, spread: CGFloat = 9.5, rx: CGFloat = 6.2, ry: CGFloat = 8.2, mouth kind: StickerMouth = .smile, blush showBlush: Bool = true, look: CGFloat = 0) {
        eye(cx - spread, cy, rx, ry, side: -1, look: look)
        eye(cx + spread, cy, rx, ry, side: 1, look: look)
        if showBlush {
            blush(cx - spread - rx * 1.2, cy - ry * 1.2, rx * 0.72, ry * 0.32)
            blush(cx + spread + rx * 1.2, cy - ry * 1.2, rx * 0.72, ry * 0.32)
        }
        mouth(cx + look * 1.5, cy - ry * 1.35, rx * 1.3, kind: kind)
    }

    func marks(_ x: CGFloat, _ y: CGFloat, _ s: CGFloat = 12) {
        switch f.mood {
        case .sleepy:
            let rise = CGFloat(f.frameIndex % 8) / 8
            for (i, k) in ([1.0, 0.7] as [CGFloat]).enumerated() {
                let zx = x + CGFloat(i) * s * 0.8, zy = y + CGFloat(i) * s * 0.75 + rise * s * 0.25
                let h = s * 0.4 * k
                let z = Self.poly([zx - h, zy + h, zx + h, zy + h, zx - h, zy - h, zx + h, zy - h], closed: false)
                stroke(z, ink, thin * 2.4)
                stroke(z, .white, thin)
            }
        case .fleeing:
            let d = Self.drop(x, y, s * 0.3, -0.35)
            fs(d, sweatTone, ink, thin * 0.8)
            gloss(x - s * 0.07, y + s * 0.02, s * 0.06, s * 0.1, -0.35)
        case .startled:
            for a in [0.35, 0.95, 1.55] as [CGFloat] {
                let ca = cos(a + 0.2), sa = sin(a + 0.2)
                stroke(Self.line(x + ca * s * 0.3, y + sa * s * 0.3, x + ca * s * 0.75, y + sa * s * 0.75), ink, thin * 1.2)
            }
        default:
            break
        }
    }

    func placeholder(_ tone: Tone, accent: Tone? = nil) {
        let sq = 1 + 0.04 * f.swing2 * f.energy
        let air = f.species.isAirborne
        let base: CGFloat = air ? 14 : 6
        with(Self.about(50, base, sx: 1 / sq, sy: sq)) {
            if air {
                both { s in
                    part(Self.ell(50 + s * 33, 54 + f.swing * 3, 12, 8, s * (0.5 + f.swing * 0.35)), accent ?? tone.lift(0.3))
                }
            } else {
                let step = f.swing * 4 * f.energy
                flat(Self.ell(38 + step, base + 1, 8, 4.4), shade(tone))
                flat(Self.ell(62 - step, base + 1, 8, 4.4), shade(tone))
            }
            part(Self.ell(50, base + 34, 30, 30), tone)
            face(54, base + 36, spread: 8, rx: 4.4, ry: 5.8)
            marks(78, base + 64, 12)
        }
    }
}
