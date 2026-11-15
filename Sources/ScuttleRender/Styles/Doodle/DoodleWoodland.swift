import Foundation
import CoreGraphics
import ScuttleCore

extension DoodleArt {
    private static func woodlandBold(_ k: DoodleKit) -> CGFloat { k.width(3.4, minPt: 1.25) }

    private static func woodlandFine(_ k: DoodleKit) -> CGFloat { k.width(2.4, minPt: 0.95) }

    private static func woodlandHatch(_ k: DoodleKit, _ region: CGPath, _ tone: Tone, seed: Int, cross: Bool) {
        let bb = region.boundingBoxOfPath
        guard bb.width > 2, bb.height > 2 else { return }
        var r = Noise(seed &+ 77)
        let gap = max(4.4, 1.5 * k.pt)
        let lw = max(1.3, 0.5 * k.pt)
        let diag = hypot(bb.width, bb.height) + 6
        let hatch = CGMutablePath()
        let passes = cross ? 2 : 1
        for pass in 0..<passes {
            let ang: CGFloat = pass == 0 ? r.range(0.95, 1.2) : r.range(2.0, 2.25)
            let dx = cos(ang), dy = sin(ang)
            var off: CGFloat = -diag / 2 + r.range(0, gap)
            while off < diag / 2 {
                let cx = bb.midX + dy * off, cy = bb.midY - dx * off
                let a = CGPoint(x: cx - dx * diag / 2, y: cy - dy * diag / 2)
                let b = CGPoint(x: cx + dx * diag / 2, y: cy + dy * diag / 2)
                hatch.move(to: a)
                hatch.addQuadCurve(to: b, control: CGPoint(x: (a.x + b.x) / 2 + r.range(-1.2, 1.2), y: (a.y + b.y) / 2 + r.range(-1.2, 1.2)))
                off += gap * r.range(0.85, 1.2)
            }
        }
        k.clip(region) { k.stroke(hatch, tone, lw) }
    }

    private static func woodlandBlob(_ k: DoodleKit, _ shape: CGPath, _ fill: Tone, _ ink: Tone?, seed: Int, w: CGFloat? = nil, hatch: Tone? = nil, cross: Bool = false) {
        let sd = k.seed(seed)
        var r = Noise(sd &+ 313)
        let bb = shape.boundingBoxOfPath
        let miss = min(1.3, max(bb.width, bb.height) * 0.06)
        let ox = r.range(-miss, miss), oy = r.range(-miss, miss)
        let region = CGMutablePath()
        for (i, sub) in DoodleKit.flatten(shape, step: 2).enumerated() where sub.1 {
            let pts = sub.0.map { CGPoint(x: $0.x + ox, y: $0.y + oy) }
            region.addPath(DoodleKit.curve(DoodleKit.wobble(pts, closed: true, seed: sd &+ 11 &+ i, amp: 0.9), closed: true))
        }
        k.fill(region, fill)
        if max(bb.width, bb.height) > 16 {
            woodlandHatch(k, region, hatch ?? fill.dim(0.78).alpha(0.55), seed: sd, cross: cross)
        }
        if let ink { k.marker(shape, ink, w ?? woodlandBold(k), seed: seed) }
    }

    private static func woodlandFlower(_ k: DoodleKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ petal: Tone, seed: Int) {
        for i in 0..<5 {
            let a = CGFloat(i) / 5 * 2 * .pi + 0.3
            k.dot(x + cos(a) * s, y + sin(a) * s, s * 0.78, s * 0.78, petal, seed: seed + i)
        }
        k.dot(x, y, s * 0.62, s * 0.62, Tone(0xffc21a), seed: seed + 5)
    }

    private static func woodlandBow(_ k: DoodleKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ tone: Tone, _ ink: Tone, seed: Int) {
        let l = poly([x, y, x - s, y + s * 0.65, x - s, y - s * 0.65])
        let r = poly([x, y, x + s, y + s * 0.65, x + s, y - s * 0.65])
        woodlandBlob(k, uni([l, r]), tone, ink, seed: seed, w: woodlandFine(k))
        k.dot(x, y, s * 0.3, s * 0.3, ink, seed: seed + 1)
    }

    private static func woodlandStep(_ f: FigureFrame, _ s: CGFloat, reach: CGFloat) -> (CGFloat, CGFloat) {
        let fwd = s * f.sway * reach
        let up = max(0, -s * f.swing) * min(3.4, 0.5 * reach + 1)
        return (fwd, up)
    }

    static func hedgehog(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0xa8643a), Tone(0xff7a1a), Tone(0xf8cf98)),
            (Tone(0x9a5a34), Tone(0xff8a2a), Tone(0xf8cf98)),
            (Tone(0x6e4230), Tone(0xff5f9a), Tone(0xffd9b4)),
            (Tone(0x84849c), Tone(0x9a6aff), Tone(0xf4e2d2)),
            (Tone(0xd0923a), Tone(0xff5a2a), Tone(0xfff0c8)),
        ]
        let (body, ink, snout) = f.pick(looks)
        let e = f.energy
        var rot: CGFloat = 0, sx: CGFloat = 1, sy: CGFloat = 1
        var dy: CGFloat = f.bounce * 1.4 * e
        var spike: CGFloat = 1.4, sweep: CGFloat = 0, fx: CGFloat = 0
        var reach: CGFloat = 5 * e
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sx = 1.06
            sy = 0.86
            spike = 1.22
            dy = -5
            reach = 0.6
        case .startled:
            sx = 0.96
            sy = 1.06
            spike = 1.66
            dy = 3
            reach = 1.5
        case .fleeing:
            sweep = 0.42
            fx = 2
            reach = 8
        case .dizzy:
            rot = 0.12 * sin(f.t)
        }
        let bold = woodlandBold(k)
        k.with(about(50, 4, rot: rot, sx: sx, sy: sy)) {
            for (i, hx) in ([27, 37, 55, 65] as [CGFloat]).enumerated() {
                let (fwd, up) = woodlandStep(f, i % 2 == 0 ? 1 : -1, reach: reach)
                k.stick([hx, 17 + dy, hx + fwd, 4 + up], ink, seed: 1 + i, w: bold)
            }
            k.with(CGAffineTransform(translationX: 0, y: dy)) {
                woodlandBlob(k, hedgehogBody(spike: spike, sweep: sweep), body, ink, seed: 10)
                woodlandBlob(k, moved(smooth([60, 16, 76, 15, 90, 22, 98, 27, 92, 33, 79, 43, 65, 41, 57, 29]), fx, 0), snout, ink, seed: 11)
                k.dot(97.5 + fx, 27.5 + 0.9 * f.twitch, 3.4, 3.1, k.felt, seed: 12)
                k.eye(77 + fx, 31, 3.3, 4.1, side: 1, seed: 13)
                k.crayon(circ(85 + fx, 23, 3.4), k.cheek, seed: 15, dense: true)
                k.mouth(88.5 + fx, 20.5, 7, seed: 16)
                hedgehogExtra(f, k, fx)
            }
            k.marks(f.mood == .fleeing ? 20 : 84, 56, 12, ink: ink, seed: 40)
        }
    }

    private static func hedgehogBody(spike: CGFloat, sweep: CGFloat) -> CGPath {
        var pts: [CGPoint] = []
        let n = 7
        let a0: CGFloat = 1.06 * .pi, a1: CGFloat = 0.12 * .pi
        for i in 0...(2 * n) {
            let t = CGFloat(i) / CGFloat(2 * n)
            let tip = i % 2 == 1
            let a = a0 + (a1 - a0) * t + (tip ? sweep : 0)
            let rr: CGFloat = tip ? spike : 1
            pts.append(pt(44 + cos(a) * 28 * rr, 31 + sin(a) * 19 * rr))
        }
        pts += P([70, 20, 58, 14, 32, 14, 17, 22])
        return polyP(pts)
    }

    private static func hedgehogExtra(_ f: FigureFrame, _ k: DoodleKit, _ fx: CGFloat) {
        switch f.variant % 5 {
        case 1:
            woodlandBlob(k, circ(40, 53, 7), Tone(0xff3434), Tone(0xff2d6a), seed: 20)
            k.stick([40, 59, 41, 64], Tone(0x9a5a2a), seed: 21, w: woodlandFine(k))
            woodlandBlob(k, ell(46, 63, 4.5, 2.4, 0.4), Tone(0x5fd04a), Tone(0x169a4a), seed: 22, w: woodlandFine(k))
        case 2:
            woodlandFlower(k, 66 + fx, 46, 4.4, Tone(0xff8fc0), seed: 20)
        case 3:
            woodlandBlob(k, ell(32, 50, 9, 4.6, 0.5), Tone(0xff8a1a), Tone(0xe8341f), seed: 20, w: woodlandFine(k))
            k.marker(line(25, 45, 39, 55), Tone(0xe8341f), woodlandFine(k), seed: 21)
        case 4:
            let lean: CGFloat = f.mood == .fleeing ? 0.35 : 0
            k.with(about(72 + fx, 42, rot: lean)) {
                woodlandBlob(k, circ(71 + fx + f.twitch, 57, 4.4), .white, Tone(0x1f5fe0), seed: 21, w: woodlandFine(k), hatch: Tone(0xbcd8ff, 0.6))
                woodlandBlob(k, smooth([61 + fx, 40, 72 + fx, 43, 83 + fx, 39, 80 + fx, 49, 71 + fx, 54, 63 + fx, 49]), Tone(0x3f8cff), Tone(0x1f5fe0), seed: 20, w: woodlandFine(k))
            }
        default:
            break
        }
    }

    static func acorn(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone, Tone, Tone)] = [
            (Tone(0xf0a646), Tone(0xe0602a), Tone(0x96603a), Tone(0xff8a2a)),
            (Tone(0x9ad850), Tone(0x22a04a), Tone(0x7a8a3a), Tone(0x22a04a)),
            (Tone(0xd27a3c), Tone(0xff5a2a), Tone(0x6a4632), Tone(0xffa03a)),
            (Tone(0xf6c060), Tone(0xff7a1a), Tone(0x96603a), Tone(0xff4f8b)),
            (Tone(0xf0a646), Tone(0xe0602a), Tone(0x8a62e0), Tone(0x6a3fe8)),
        ]
        let (nut, nutInk, cap, capInk) = f.pick(looks)
        let v = f.variant % 5
        let sq = f.squat, st = f.stretch
        let tuck: CGFloat = f.airborne ? sin(f.air * .pi) : 0
        var sy: CGFloat = 1 - 0.16 * sq + 0.1 * st
        var sx: CGFloat = 1 + 0.1 * sq - 0.05 * st
        var rot: CGFloat = 0, fx: CGFloat = 0
        var capDy: CGFloat = 0, capDx: CGFloat = 0, capRot: CGFloat = 0
        let armUp: CGFloat = f.airborne ? 0.3 + 0.7 * tuck : -0.4 * sq
        var lh = pt(14, 38 + 16 * armUp), rh = pt(86, 38 + 16 * armUp)
        switch f.mood {
        case .calm:
            rh.y += 14 * max(0, f.twitch)
        case .sleepy:
            sy *= 0.92
            sx *= 1.05
            capDy = -6
            capRot = -0.14
            lh = pt(22, 20)
            rh = pt(78, 20)
        case .startled:
            sy *= 1.06
            sx *= 0.96
            capDy = 8
            lh = pt(14, 66)
            rh = pt(86, 66)
        case .fleeing:
            capRot = 0.38
            capDx = -4
            capDy = 2
            fx = 3
            lh = pt(8, 44 + 5 * f.swing)
            rh = pt(20, 58 - 5 * f.swing)
        case .dizzy:
            rot = 0.12 * sin(f.t)
            capRot = -0.2 * sin(f.t)
        }
        let bold = woodlandBold(k)
        k.with(about(50, 5, rot: rot, sx: sx, sy: sy)) {
            for (i, hx) in ([43, 57] as [CGFloat]).enumerated() {
                let kick: CGFloat = f.mood == .fleeing ? 4 * f.swing * (i == 0 ? 1 : -1) : 0
                let fy = 5 + tuck * 6
                k.stick([hx, 16, hx - 1 + kick, fy, hx + 4 + kick, fy], nutInk, seed: 1 + i, w: bold)
            }
            k.stick([31, 38, (31 + lh.x) / 2, (38 + lh.y) / 2 - 2, lh.x, lh.y], nutInk, seed: 3, w: bold)
            k.stick([69, 38, (69 + rh.x) / 2, (38 + rh.y) / 2 - 2, rh.x, rh.y], nutInk, seed: 4, w: bold)
            woodlandBlob(k, smooth([50, 11, 62, 15, 71, 28, 73, 44, 68, 56, 50, 60, 32, 56, 27, 44, 29, 28, 38, 15]), nut, nutInk, seed: 10)
            k.face(51 + fx, 35, spread: 8.5, rx: 3.6, ry: 4.5, seed: 30)
            if v == 2 {
                let band = smooth([28, 54, 50, 50, 72, 54, 72, 46, 50, 43, 28, 46])
                woodlandBlob(k, band, Tone(0x3f8cff), Tone(0x1f5fe0), seed: 20, w: woodlandFine(k))
                let tail = smooth([34, 48, 28 - 2 * f.swing, 36, 34 - 2 * f.swing, 34, 39, 46], t: 0.6)
                woodlandBlob(k, tail, Tone(0x3f8cff), Tone(0x1f5fe0), seed: 21, w: woodlandFine(k))
            }
            let ct = about(50, 56, rot: capRot).concatenating(CGAffineTransform(translationX: capDx, y: capDy))
            k.with(ct) {
                if v == 4 {
                    woodlandBlob(k, circ(50 + 2 * f.twitch, 85, 6), Tone(0xff7ab0), Tone(0xff3d8b), seed: 22)
                } else {
                    k.stick([50, 80, 51, 87, 55 + 2.5 * f.twitch, 91], capInk, seed: 12, w: bold)
                }
                woodlandBlob(k, smooth([21, 58, 50, 53, 79, 58, 81, 66, 72, 77, 50, 82, 28, 77, 19, 66]), cap, capInk, seed: 11, cross: v != 4)
                if v == 1 {
                    woodlandBlob(k, ell(61, 90, 8, 4, 0.45), Tone(0x5fd04a), Tone(0x169a4a), seed: 23, w: woodlandFine(k))
                }
                if v == 3 {
                    woodlandFlower(k, 67, 74, 3.6, Tone(0xff8fc0), seed: 24)
                }
            }
            k.marks(f.mood == .fleeing ? 18 : 84, 76, 12, ink: nutInk, seed: 40)
        }
    }

    static func toadstool(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0xf03434), Tone(0xff3d8b), .white),
            (Tone(0x2f7fff), Tone(0x6ab4ff), .white),
            (Tone(0xff8a1a), Tone(0xff3d3d), Tone(0xfff2c8)),
            (Tone(0x8a4ae0), Tone(0xd060ff), Tone(0xffe04a)),
            (Tone(0x2fb84a), Tone(0x0f9a6a), .white),
        ]
        let (cap, capInk, spot) = f.pick(looks)
        let stem = Tone(0xfff0d8), stemInk = Tone(0xff8a4a)
        let v = f.variant % 5
        let e = f.energy
        var dy: CGFloat = f.bounce * 1.6 * e
        var rot: CGFloat = 0, sx: CGFloat = 1, sy: CGFloat = 1, fx: CGFloat = 0
        var capDy: CGFloat = 0, capRot: CGFloat = -0.05 * f.swing * e
        var reach: CGFloat = 5 * e
        var lh = pt(20, 24 + 3 * f.swing), rh = pt(80, 24 - 3 * f.swing)
        switch f.mood {
        case .calm:
            rh = pt(82 - 2 * max(0, f.twitch), 24 - 3 * f.swing + 16 * max(0, f.twitch))
        case .sleepy:
            sy = 0.94
            sx = 1.03
            capDy = -6
            capRot = 0.1
            reach = 0.6
            dy = 0
            lh = pt(30, 14)
            rh = pt(70, 14)
        case .startled:
            sy = 1.06
            capDy = 8
            reach = 1.5
            lh = pt(16, 52)
            rh = pt(84, 52)
        case .fleeing:
            capRot = 0.3
            capDy = 1
            fx = 3
            reach = 8
            lh = pt(12, 36 + 4 * f.swing)
            rh = pt(24, 20 - 4 * f.swing)
        case .dizzy:
            rot = 0.12 * sin(f.t)
            capRot = -0.16 * sin(f.t)
        }
        let bold = woodlandBold(k)
        k.with(about(50, 4, rot: rot, sx: sx, sy: sy)) {
            for (i, hx) in ([44, 56] as [CGFloat]).enumerated() {
                let (fwd, up) = woodlandStep(f, i == 0 ? 1 : -1, reach: reach)
                k.stick([hx, 16 + dy, hx + fwd, 4 + up, hx + fwd + 4, 4 + up], stemInk, seed: 1 + i, w: bold)
            }
            k.stick([37, 30 + dy, lh.x, lh.y + dy], stemInk, seed: 3, w: bold)
            k.stick([63, 30 + dy, rh.x, rh.y + dy], stemInk, seed: 4, w: bold)
            if v == 4 {
                k.stick([rh.x, rh.y + dy, rh.x + 1, rh.y + dy + 10], Tone(0x169a4a), seed: 5, w: woodlandFine(k))
                woodlandFlower(k, rh.x + 1, rh.y + dy + 13, 3.2, Tone(0xffe04a), seed: 24)
            }
            k.with(CGAffineTransform(translationX: 0, y: dy)) {
                woodlandBlob(k, smooth([38, 14, 62, 14, 66, 30, 63, 46, 50, 49, 37, 46, 34, 30]), stem, stemInk, seed: 10, hatch: Tone(0xffc890, 0.5))
                k.face(51 + fx, 31, spread: 7.5, rx: 3.3, ry: 4.3, seed: 30)
                let ct = about(50, 46, rot: capRot).concatenating(CGAffineTransform(translationX: 0, y: capDy))
                k.with(ct) {
                    woodlandBlob(k, smooth([11, 50, 25, 72, 50, 83, 75, 72, 89, 50, 72, 45, 50, 43, 28, 45]), cap, capInk, seed: 11)
                    k.dot(34, 63, 6, 5, spot, seed: 12)
                    k.dot(57, 73, 5.5, 4.4, spot, seed: 13)
                    k.dot(73, 57, 4.6, 4.2, spot, seed: 14)
                    k.dot(50, 54, 3.6, 3.2, spot, seed: 15)
                    if v == 2 {
                        woodlandBlob(k, ell(62, 85, 8, 4, 0.5), Tone(0x5fd04a), Tone(0x169a4a), seed: 20, w: woodlandFine(k))
                    }
                    if v == 3 {
                        woodlandBow(k, 40, 81, 6.5, Tone(0xff7ab0), Tone(0xff3d8b), seed: 21)
                    }
                }
            }
            k.marks(f.mood == .fleeing ? 14 : 88, 74, 12, ink: capInk, seed: 40)
        }
    }

    static func leaf(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xff8a1a), Tone(0xe8341f)),
            (Tone(0xf0383a), Tone(0xff4f8b)),
            (Tone(0xffc82a), Tone(0xff7a1a)),
            (Tone(0x5fd04a), Tone(0x169a4a)),
            (Tone(0xc8803a), Tone(0xff5a2a)),
        ]
        let (fill, ink) = f.pick(looks)
        let v = f.variant % 5
        let maple = v == 1 || v == 4
        let e = f.energy
        var rot: CGFloat = 0.07 * f.swing * e, sx: CGFloat = 1 + 0.03 * f.swing2 * e, sy: CGFloat = 1
        var shear: CGFloat = 0, fx: CGFloat = 0
        var lh = pt(11, 58 + 5 * sin(f.t)), rh = pt(89, 58 - 5 * sin(f.t))
        switch f.mood {
        case .calm:
            rh.y += 12 * max(0, f.twitch)
        case .sleepy:
            sy = 0.9
            rot = -0.12
            lh = pt(18, 36)
            rh = pt(82, 36)
        case .startled:
            sy = 1.07
            sx = 0.95
            lh = pt(12, 80)
            rh = pt(88, 80)
        case .fleeing:
            shear = -0.3
            fx = 3
            lh = pt(6, 50 + 4 * f.swing2)
            rh = pt(14, 64 - 4 * f.swing2)
        case .dizzy:
            rot = 0.14 * sin(f.t)
        }
        let sh = CGAffineTransform(a: 1, b: 0, c: shear, d: 1, tx: -shear * 16, ty: 0)
        let tr = sh.concatenating(about(50, 16, rot: rot, sx: sx, sy: sy))
        let bold = woodlandBold(k)
        k.with(tr) {
            k.stick([50, 18, 49 + 2 * f.sway, 9, 45 + 4 * f.sway, 4], ink, seed: 1, w: bold)
            k.stick([28, 52, (28 + lh.x) / 2, (52 + lh.y) / 2 + 2, lh.x, lh.y], ink, seed: 2, w: bold)
            k.stick([72, 52, (72 + rh.x) / 2, (52 + rh.y) / 2 + 2, rh.x, rh.y], ink, seed: 3, w: bold)
            var body = maple ? leafMaple() : leafOval()
            if v == 3 { body = minus(body, circ(79, 66, 9)) }
            woodlandBlob(k, body, fill, ink, seed: 10)
            let veins = CGMutablePath()
            veins.addPath(line(50, 20, 50, 40))
            veins.addPath(line(50, 27, 41, 35))
            veins.addPath(line(50, 30, 59, 38))
            veins.addPath(line(50, 74, 50, 86))
            k.marker(veins, ink, woodlandFine(k), seed: 11)
            k.face(50 + fx, 55, spread: 8, rx: 3.5, ry: 4.4, seed: 30)
            if v == 2 {
                woodlandBlob(k, circ(62, 77, 6.5), Tone(0xff3030), Tone(0xc8183a), seed: 20, w: woodlandFine(k))
                k.dot(67.5, 79, 2.8, 2.8, k.felt, seed: 21)
                k.dot(60, 79, 1.6, 1.6, k.felt, seed: 22)
                k.dot(62, 74, 1.6, 1.6, k.felt, seed: 23)
            }
            if v == 4 {
                woodlandBlob(k, drop(76, 84, 5, -0.3), Tone(0x6ac8ff), Tone(0x2f7fff), seed: 20, w: woodlandFine(k))
            }
            k.marks(f.mood == .fleeing ? 18 : 80, 84, 12, ink: ink, seed: 40)
        }
    }

    private static func leafOval() -> CGPath {
        let p = CGMutablePath()
        p.move(to: pt(50, 15))
        p.addCurve(to: pt(50, 94), control1: pt(16, 24), control2: pt(14, 72))
        p.addCurve(to: pt(50, 15), control1: pt(86, 72), control2: pt(84, 24))
        p.closeSubpath()
        return p
    }

    private static func leafMaple() -> CGPath {
        smooth([50, 96, 57, 79, 69, 87, 67, 69, 87, 71, 77, 57, 89, 45, 68, 43, 62, 29, 54, 33, 50, 19,
                46, 33, 38, 29, 32, 43, 11, 45, 23, 57, 13, 71, 33, 69, 31, 87, 43, 79], t: 0.35)
    }

    static func penguin(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0x3a4a8f), Tone(0x5fa8ff)), (Tone(0x3a4a8f), Tone(0x5fa8ff)), (Tone(0x3a4a8f), Tone(0x5fa8ff)),
            (Tone(0x5a3f9a), Tone(0xa880ff)), (Tone(0x22667a), Tone(0x3fd6e0)),
        ]
        let (body, ink) = f.pick(looks)
        let orange = Tone(0xff9a2a), oInk = Tone(0xff6a1a)
        let v = f.variant % 5
        let e = f.energy
        var dy: CGFloat = f.bounce * 1.5 * e
        var rot: CGFloat = 0.05 * f.swing * e, sx: CGFloat = 1, sy: CGFloat = 1, fx: CGFloat = 0
        var la: CGFloat = 0.15 + 0.14 * f.swing * e, ra: CGFloat = 0.15 - 0.14 * f.swing * e
        var reach: CGFloat = 1
        switch f.mood {
        case .calm:
            ra += 1.1 * max(0, f.twitch)
        case .sleepy:
            sy = 0.92
            sx = 1.04
            la = -0.05
            ra = -0.05
            dy = 0
            reach = 0.3
        case .startled:
            sy = 1.06
            sx = 0.96
            la = 1.7 + 0.1 * f.swing2
            ra = 1.7 - 0.1 * f.swing2
        case .fleeing:
            la = 1.0 + 0.6 * f.swing2
            ra = la
            fx = 3
            reach = 1.6
        case .dizzy:
            rot = 0.12 * sin(f.t)
            la = 0.5 + 0.4 * sin(f.t)
            ra = 0.5 - 0.4 * sin(f.t)
        }
        k.with(about(50, 4, rot: rot, sx: sx, sy: sy)) {
            for (i, x) in ([39, 61] as [CGFloat]).enumerated() {
                let s: CGFloat = i == 0 ? 1 : -1
                let up = max(0, -s * f.swing) * 3.2 * e * reach
                woodlandBlob(k, ell(x + s * f.sway * 1.5 * reach, 6.5 + up, 8, 3.8), orange, oInk, seed: 1 + i, w: woodlandFine(k))
            }
            k.with(CGAffineTransform(translationX: 0, y: dy)) {
                let flip = smooth([29, 60, 16, 44, 14, 30, 28, 42])
                k.with(about(29, 58, rot: -la)) { woodlandBlob(k, flip, body, ink, seed: 3) }
                k.with(about(71, 58, rot: ra)) { woodlandBlob(k, mirror(flip), body, ink, seed: 4) }
                woodlandBlob(k, smooth([50, 88, 66, 82, 74, 61, 74, 34, 66, 14, 50, 10, 34, 14, 26, 34, 26, 61, 34, 82]), body, ink, seed: 10, hatch: ink.alpha(0.3))
                woodlandBlob(k, smooth([50, 64, 62, 59, 66, 40, 62, 22, 50, 16, 38, 22, 34, 40, 38, 59]), Tone(0xfbfbff), nil, seed: 11, hatch: Tone(0xbcd8ff, 0.6))
                for (i, x) in ([42, 58] as [CGFloat]).enumerated() {
                    k.dot(x + fx, 71, 6, 6, .white, seed: 12 + i)
                    k.eye(x + fx + 1, 70.5, 2.6, 3.0, side: i == 0 ? -1 : 1, seed: 14 + 2 * i)
                }
                k.cheeks(37 + fx, 63 + fx, 60, 3.2, seed: 18)
                penguinBeak(f, k, fx, orange, oInk)
                penguinExtra(f, k, v)
            }
            k.marks(f.mood == .fleeing ? 18 : 80, 90, 12, ink: ink, seed: 40)
        }
    }

    private static func penguinBeak(_ f: FigureFrame, _ k: DoodleKit, _ fx: CGFloat, _ orange: Tone, _ oInk: Tone) {
        let w = woodlandFine(k)
        switch f.mood {
        case .startled, .fleeing:
            k.dot(50 + fx, 58.5, 4.2, 3.2, Tone(0xc0303a), seed: 20)
            woodlandBlob(k, poly([44 + fx, 64, 56 + fx, 64, 50 + fx, 60]), orange, oInk, seed: 21, w: w)
            woodlandBlob(k, poly([45.5 + fx, 56.5, 54.5 + fx, 56.5, 50 + fx, 52]), orange, oInk, seed: 22, w: w)
        case .sleepy:
            woodlandBlob(k, poly([46 + fx, 62, 54 + fx, 62, 50 + fx, 57]), orange, oInk, seed: 21, w: w)
        case .dizzy:
            woodlandBlob(k, poly([44.5 + fx, 63, 55.5 + fx, 63, 50 + fx, 56]), orange, oInk, seed: 21, w: w)
            k.mouth(50 + fx, 53, 9, seed: 23)
        case .calm:
            woodlandBlob(k, poly([44.5 + fx, 63, 55.5 + fx, 63, 50 + fx, 55]), orange, oInk, seed: 21, w: w)
        }
    }

    private static func penguinExtra(_ f: FigureFrame, _ k: DoodleKit, _ v: Int) {
        let w = woodlandFine(k)
        switch v {
        case 1:
            let red = Tone(0xff3b3b), rInk = Tone(0xff2d6a)
            let trail: CGFloat = f.mood == .fleeing ? -14 : 0
            woodlandBlob(k, smooth([60, 51, 66 + trail, 34 + 2 * f.swing - trail * 0.6, 72 + trail, 36 + 2 * f.swing - trail * 0.6, 68, 51], t: 0.6), red, rInk, seed: 30, w: w)
            woodlandBlob(k, smooth([26, 54, 50, 50, 74, 54, 74, 46, 50, 42, 26, 46]), red, rInk, seed: 31, w: w)
        case 2:
            woodlandBlob(k, smooth([30, 80, 50, 84, 70, 80, 67, 92, 50, 98, 33, 92]), Tone(0xff5f9a), Tone(0xe02a7a), seed: 30, w: w)
            woodlandBlob(k, circ(50 + 1.5 * f.twitch, 100, 5), .white, Tone(0xe02a7a), seed: 31, w: w, hatch: Tone(0xffc0dc, 0.6))
        case 3:
            woodlandBow(k, 50, 49, 8, Tone(0xffc21a), Tone(0xff7a1a), seed: 30)
        case 4:
            let pink = Tone(0xff5f9a), pInk = Tone(0xe02a7a)
            k.marker(smooth([27, 74, 32, 90, 50, 96, 68, 90, 73, 74], closed: false), pInk, woodlandBold(k) * 1.2, seed: 30)
            woodlandBlob(k, circ(26, 72, 7), pink, pInk, seed: 31, w: w)
            woodlandBlob(k, circ(74, 72, 7), pink, pInk, seed: 32, w: w)
        default:
            break
        }
    }

    static func snowman(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xff3b3b), Tone(0xff2d6a)), (Tone(0x3fc04a), Tone(0x14904a)), (Tone(0x3f8cff), Tone(0x1f5fe0)),
            (Tone(0xff5f9a), Tone(0xe02a7a)), (Tone(0xffc21a), Tone(0xff7a1a)),
        ]
        let (scarf, sInk) = f.pick(looks)
        let snow = Tone.white, ink = Tone(0x3f8cff), shade = Tone(0x9cc8ff, 0.55)
        let twig = Tone(0xc8722a)
        let e = f.energy
        var dy: CGFloat = f.bounce * 2 * e
        var rot: CGFloat = 0.06 * f.swing * e, sy: CGFloat = 1
        var hdx: CGFloat = 0, hdy: CGFloat = 0, hrot: CGFloat = 0, hatDy: CGFloat = 0, hatRot: CGFloat = 0, fx: CGFloat = 0
        var lh = pt(12, 50 + 3 * f.swing), rh = pt(88, 50 - 3 * f.swing)
        var tail = pt(38 + 2 * f.swing, 28)
        var reach: CGFloat = 4 * e
        switch f.mood {
        case .calm:
            rh = pt(86, 50 - 3 * f.swing + 16 * max(0, f.twitch))
        case .sleepy:
            sy = 0.95
            hrot = 0.18
            hdx = -2
            hdy = -3
            hatRot = 0.12
            dy = 0
            reach = 0.5
            lh = pt(16, 24)
            rh = pt(84, 24)
        case .startled:
            sy = 1.04
            hdy = 4
            hatDy = 8
            lh = pt(14, 72)
            rh = pt(86, 72)
            reach = 1.5
        case .fleeing:
            fx = 2
            hatRot = 0.3
            lh = pt(6, 44 + 5 * f.swing)
            rh = pt(20, 60 - 5 * f.swing)
            tail = pt(12, 46 + 4 * f.swing2)
            reach = 7
        case .dizzy:
            rot = 0.12 * sin(f.t)
            hrot = -0.16 * sin(f.t)
            hatRot = 0.2 * sin(f.t)
        }
        let bold = woodlandBold(k)
        k.with(about(50, 4, rot: rot, sx: 1, sy: sy)) {
            for (i, x) in ([40, 60] as [CGFloat]).enumerated() {
                let (fwd, up) = woodlandStep(f, i == 0 ? 1 : -1, reach: reach)
                woodlandBlob(k, ell(x + fwd, 6.5 + up, 7, 3.8), scarf, sInk, seed: 1 + i, w: woodlandFine(k))
            }
            k.with(CGAffineTransform(translationX: 0, y: dy)) {
                k.stick([30, 38, (30 + lh.x) / 2, (38 + lh.y) / 2 + 1, lh.x, lh.y], twig, seed: 3, w: bold)
                k.stick([70, 38, (70 + rh.x) / 2, (38 + rh.y) / 2 + 1, rh.x, rh.y], twig, seed: 4, w: bold)
                let mlx = (30 + lh.x) / 2, mly = (38 + lh.y) / 2 + 1
                let mrx = (70 + rh.x) / 2, mry = (38 + rh.y) / 2 + 1
                k.stick([mlx, mly, mlx - 3, mly + 6], twig, seed: 5, w: woodlandFine(k))
                k.stick([mrx, mry, mrx + 3, mry + 6], twig, seed: 6, w: woodlandFine(k))
                woodlandBlob(k, ell(50, 28, 23, 20), snow, ink, seed: 10, hatch: shade)
                k.dot(51, 34, 2.6, 2.6, k.felt, seed: 11)
                k.dot(51, 23, 2.6, 2.6, k.felt, seed: 12)
                let ht = about(50, 48, rot: hrot).concatenating(CGAffineTransform(translationX: hdx, y: hdy))
                k.with(ht) {
                    woodlandBlob(k, circ(50, 62, 15.5), snow, ink, seed: 13, hatch: shade)
                    k.eye(45 + fx, 66, 2.8, 3.3, side: -1, seed: 14)
                    k.eye(56 + fx, 66, 2.8, 3.3, side: 1, seed: 15)
                    k.cheeks(40 + fx, 62 + fx, 59, 2.8, seed: 16)
                    woodlandBlob(k, poly([56 + fx, 62, 73 + fx, 59, 56 + fx, 57.5]), Tone(0xff8a1a), Tone(0xff5a1a), seed: 18, w: woodlandFine(k))
                    k.mouth(51 + fx, 54.5, 8, seed: 19)
                    let hat = about(50, 76, rot: hatRot).concatenating(CGAffineTransform(translationX: 0, y: hatDy))
                    k.with(hat) { snowmanHat(f, k, scarf, sInk) }
                }
                let band = smooth([34, 50, 50, 46, 66, 50, 66, 44, 50, 40, 34, 44])
                let tl = smooth([41, 46, tail.x - 3, tail.y + 1, tail.x + 4, tail.y - 1, 47, 43], t: 0.6)
                woodlandBlob(k, tl, scarf, sInk, seed: 20, w: woodlandFine(k))
                woodlandBlob(k, band, scarf, sInk, seed: 21, w: woodlandFine(k))
            }
            k.marks(f.mood == .fleeing ? 18 : 80, 88, 12, ink: ink, seed: 40)
        }
    }

    private static func snowmanHat(_ f: FigureFrame, _ k: DoodleKit, _ scarf: Tone, _ sInk: Tone) {
        let dark = Tone(0x2e2a40), dInk = Tone(0x9a7bff)
        let w = woodlandFine(k)
        switch f.variant % 5 {
        case 1:
            woodlandBlob(k, circ(50, 90, 5), .white, sInk, seed: 31, w: w, hatch: Tone(0xbfe8c8, 0.6))
            woodlandBlob(k, smooth([33, 73, 50, 76, 67, 73, 64, 85, 50, 90, 36, 85]), scarf, sInk, seed: 30, w: w)
        case 2:
            k.marker(smooth([35, 64, 38, 76, 50, 80, 62, 76, 65, 64], closed: false), sInk, woodlandBold(k), seed: 30)
            woodlandBlob(k, circ(35, 63, 4.8), scarf, sInk, seed: 31, w: w)
            woodlandBlob(k, circ(65, 63, 4.8), scarf, sInk, seed: 32, w: w)
        case 4:
            woodlandBlob(k, poly([37, 75, 63, 75, 59, 88, 41, 88]), scarf, sInk, seed: 30, w: w)
            woodlandBlob(k, ell(50, 75, 18, 3.6), scarf, sInk, seed: 31, w: w)
        default:
            woodlandBlob(k, rrect(39, 75, 22, 16, 2), dark, dInk, seed: 30, hatch: dInk.alpha(0.3))
            woodlandBlob(k, ell(50, 75.5, 16, 3.4), dark, dInk, seed: 31, w: w, hatch: dInk.alpha(0.3))
            if f.variant % 5 == 3 {
                woodlandFlower(k, 58, 81, 3.2, Tone(0xff8fc0), seed: 32)
            } else {
                k.marker(line(40, 79, 60, 79), scarf, woodlandBold(k), seed: 32)
            }
        }
    }

    static func snowflake(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0x3f8cff), Tone(0xeef7ff)), (Tone(0x9a6aff), Tone(0xf4efff)), (Tone(0x0fb4c8), Tone(0xe8fffb)),
            (Tone(0xff4f8b), Tone(0xfff0f6)), (Tone(0x2f6fff), Tone(0xeef4ff)),
        ]
        let (ink, centre) = f.pick(looks)
        let v = f.variant % 5
        var spin: CGFloat = f.t / 6, len: CGFloat = 40, r0: CGFloat = 15
        var rot: CGFloat = 0, sx: CGFloat = 1, sy: CGFloat = 1, fx: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            spin = 0
            len = 34
            sy = 0.94
        case .startled:
            spin = 0
            len = 45 + 1.5 * f.swing2
            r0 = 16
        case .fleeing:
            spin = f.t / 3
            fx = 3
            sx = 1.08
        case .dizzy:
            spin = f.t / 2
            rot = 0.12 * sin(f.t)
        }
        let cx: CGFloat = 50, cy: CGFloat = 52
        k.with(about(cx, cy, rot: rot, sx: sx, sy: sy)) {
            let arms = CGMutablePath()
            var tips: [CGPoint] = []
            for i in 0..<6 {
                let a = spin + CGFloat(i) * .pi / 3 + .pi / 2
                let ca = cos(a), sa = sin(a)
                let droop: CGFloat = f.mood == .sleepy ? -3 * abs(ca) : 0
                func p(_ r: CGFloat, _ da: CGFloat) -> CGPoint {
                    CGPoint(x: cx + cos(a + da) * r, y: cy + sin(a + da) * r + droop * r / len)
                }
                let tip = p(len, 0)
                tips.append(tip)
                arms.move(to: p(r0 - 2, 0))
                arms.addLine(to: tip)
                let b = CGPoint(x: cx + ca * len * 0.6, y: cy + sa * len * 0.6 + droop * 0.6)
                let bl = a - 0.8, br = a + 0.8
                arms.move(to: CGPoint(x: b.x + cos(bl) * len * 0.3, y: b.y + sin(bl) * len * 0.3))
                arms.addLine(to: b)
                arms.addLine(to: CGPoint(x: b.x + cos(br) * len * 0.3, y: b.y + sin(br) * len * 0.3))
            }
            k.marker(arms, ink, woodlandBold(k) * 1.25, seed: 1)
            if v == 2 {
                for (i, t) in tips.enumerated() { k.dot(t.x, t.y, 3.6, 3.6, Tone(0xffc21a), seed: 3 + i) }
            }
            woodlandBlob(k, circ(cx, cy, r0), centre, ink, seed: 10, hatch: ink.alpha(0.18))
            k.face(cx + fx, cy + 1, spread: 5.8, rx: 2.8, ry: 3.6, seed: 30)
            switch v {
            case 1:
                woodlandBow(k, 39, 64, 6, Tone(0xff7ab0), Tone(0xff3d8b), seed: 20)
            case 3:
                woodlandBlob(k, poly([41, 64, 59, 64, 62, 75, 55, 69, 50, 77, 45, 69, 38, 75]), Tone(0xffd23a), Tone(0xff8a1a), seed: 20, w: woodlandFine(k))
            case 4:
                woodlandBlob(k, circ(50 + 1.5 * f.twitch, 78, 4.5), .white, Tone(0xd8203a), seed: 21, w: woodlandFine(k), hatch: Tone(0xffc0c8, 0.6))
                woodlandBlob(k, smooth([36, 63, 50, 66, 64, 63, 61, 72, 50, 76, 39, 72]), Tone(0xff3b3b), Tone(0xd8203a), seed: 20, w: woodlandFine(k))
            default:
                break
            }
            if f.twitch != 0, f.mood == .calm, let t = tips.first {
                woodlandBlob(k, softStar(t.x + 4, t.y + 4, 5, points: 4, inner: 0.35), Tone(0xffd23a), Tone(0xff8a1a), seed: 26, w: woodlandFine(k))
            }
        }
        k.marks(f.mood == .fleeing ? 16 : 84, 86, 12, ink: ink, seed: 40)
    }

    static func robin(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0x9a6440), Tone(0xff8a2a), Tone(0xff5226)),
            (Tone(0x9a6440), Tone(0xff8a2a), Tone(0xff5226)),
            (Tone(0x9a6440), Tone(0xff8a2a), Tone(0xff5226)),
            (Tone(0x3f7fe0), Tone(0x6ab8ff), Tone(0xffa060)),
            (Tone(0x8a5a3a), Tone(0xffa03a), Tone(0xff5226)),
        ]
        let (body, ink, breast) = f.pick(looks)
        let v = f.variant % 5
        let sq = f.squat, st = f.stretch
        let tuck: CGFloat = f.airborne ? sin(f.air * .pi) : 0
        var sy: CGFloat = 1 - 0.16 * sq + 0.1 * st
        var sx: CGFloat = 1 + 0.1 * sq - 0.05 * st
        var rot: CGFloat = 0
        var wing: CGFloat = f.airborne ? sin(f.air * .pi) * (1.2 + 0.8 * sin(f.air * .pi * 4)) : -0.1 * sq
        var tail: CGFloat = 0.12 * f.twitch - 0.15 * sq
        var open = false
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sy *= 0.9
            sx *= 1.08
            wing = 0
            tail = -0.1
        case .startled:
            sy *= 1.08
            sx *= 0.95
            wing = 1.9 + 0.1 * f.swing2
            tail = 0.45
            open = true
        case .fleeing:
            wing = 1.2 + 0.9 * f.swing2
            tail = -0.4
            open = true
        case .dizzy:
            rot = 0.12 * sin(f.t)
        }
        let bold = woodlandBold(k)
        let w = woodlandFine(k)
        k.with(about(50, 5, rot: rot, sx: sx, sy: sy)) {
            for (i, hx) in ([45, 54] as [CGFloat]).enumerated() {
                let fy = 5 + tuck * 6
                k.stick([hx, 18, hx - 1, fy, hx + 5, fy], ink, seed: 1 + i, w: bold)
            }
            k.with(about(28, 44, rot: tail)) {
                woodlandBlob(k, poly([30, 40, 8, 52, 11, 59, 32, 49]), body, ink, seed: 3)
            }
            let shape = smooth([22, 40, 30, 22, 50, 15, 68, 20, 77, 36, 76, 54, 66, 66, 50, 68, 34, 62])
            woodlandBlob(k, shape, body, ink, seed: 10)
            woodlandBlob(k, smooth([60, 60, 71, 55, 74, 42, 69, 28, 58, 23, 54, 38, 55, 52]), breast, nil, seed: 11)
            if v == 1 {
                woodlandBlob(k, circ(57, 83, 4.5), .white, Tone(0xd8203a), seed: 22, w: w, hatch: Tone(0xffc0c8, 0.6))
                woodlandBlob(k, smooth([50, 62, 63, 68, 76, 61, 70, 74, 58, 82, 52, 74]), Tone(0xff3b3b), Tone(0xd8203a), seed: 21, w: w)
            }
            k.eye(65, 55, 3.4, 4.1, side: 1, seed: 12)
            k.crayon(circ(70, 47, 3.2), k.cheek, seed: 17, dense: true)
            if open {
                woodlandBlob(k, poly([75, 55, 87, 53, 75, 49.5]), Tone(0xffc21a), Tone(0xff7a1a), seed: 13, w: w)
                woodlandBlob(k, poly([75, 47, 85, 43.5, 75, 44]), Tone(0xffc21a), Tone(0xff7a1a), seed: 14, w: w)
            } else {
                woodlandBlob(k, poly([75, 53.5, 88, 49.5, 75, 45.5]), Tone(0xffc21a), Tone(0xff7a1a), seed: 13, w: w)
            }
            if f.mood == .dizzy { k.mouth(70, 42, 7, seed: 15) }
            k.with(about(52, 50, rot: -wing)) {
                woodlandBlob(k, smooth([28, 50, 54, 52, 57, 38, 44, 27, 24, 34]), body.lift(0.18), ink, seed: 16, w: w)
            }
            if v == 2 {
                k.marker(wavy(85, 49, 83, 34, waves: 1.5, amp: 2.2, phase: f.t), Tone(0xff6aa0), bold * 1.1, seed: 20)
            }
            if v == 4 {
                let band = smooth([58, 47, 70, 43, 78, 45, 77, 38, 68, 36, 56, 40])
                let trail: CGFloat = f.mood == .fleeing ? -8 : 0
                woodlandBlob(k, smooth([60, 42, 54 + trail, 30 - trail * 0.5 + 2 * f.swing, 59 + trail, 29 - trail * 0.5 + 2 * f.swing, 63, 40], t: 0.6), Tone(0x3fc04a), Tone(0x14904a), seed: 23, w: w)
                woodlandBlob(k, band, Tone(0x3fc04a), Tone(0x14904a), seed: 24, w: w)
            }
            k.marks(f.mood == .fleeing ? 16 : 82, 72, 11, ink: ink, seed: 40)
        }
    }

    static func cloud(_ f: FigureFrame, _ k: DoodleKit) {
        k.with(about(50, 48, sx: 1.16, sy: 1.16)) { cloudDraw(f, k) }
    }

    private static func cloudDraw(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (.white, Tone(0x3f8cff), Tone(0xa8d0ff, 0.55)),
            (Tone(0xdde6f4), Tone(0x4f74d0), Tone(0x9fb4e0, 0.6)),
            (.white, Tone(0x3f8cff), Tone(0xa8d0ff, 0.55)),
            (Tone(0xffe4ef), Tone(0xff4f8b), Tone(0xffa8c8, 0.55)),
            (Tone(0xefeaff), Tone(0x8a6aff), Tone(0xc8b8ff, 0.6)),
        ]
        let (fill, ink, hatch) = f.pick(looks)
        let v = f.variant % 5
        let e = f.energy
        var rot: CGFloat = 0, sx: CGFloat = 1, sy: CGFloat = 1, fx: CGFloat = 0, puff: CGFloat = 1
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sy = 0.86
            sx = 1.06
        case .startled:
            puff = 1.12
            sy = 1.04
        case .fleeing:
            sx = 1.1
            fx = 3
        case .dizzy:
            rot = 0.1 * sin(f.t)
        }
        let w = woodlandFine(k)
        if v == 2 {
            k.marker(cloudRays(f.t), Tone(0xff8a1a), woodlandBold(k), seed: 21)
            woodlandBlob(k, circ(72, 64, 13), Tone(0xffd23a), Tone(0xff8a1a), seed: 20)
        }
        if v == 3 {
            let cols: [Tone] = [Tone(0xff3b3b), Tone(0xffb21a), Tone(0x2fc04a), Tone(0x3f8cff)]
            for (i, c) in cols.enumerated() {
                let y0 = 46 - CGFloat(i) * 4.2
                let flee: CGFloat = f.mood == .fleeing ? 8 : 0
                k.marker(wavy(24, y0, -6 - flee, y0 - 4, waves: 1, amp: 2, phase: f.t), c, woodlandBold(k), seed: 22 + i)
            }
        }
        if f.mood == .startled {
            woodlandBlob(k, poly([60, 30, 52, 17, 58, 17, 50, 2, 67, 21, 60, 21, 65, 30]), Tone(0xffd23a), Tone(0xff8a1a), seed: 30, w: w)
        }
        if f.mood == .fleeing {
            woodlandBlob(k, circ(9, 42 + 2 * f.swing, 5.5), fill, ink, seed: 31, w: w, hatch: hatch)
            woodlandBlob(k, circ(-2, 46 - 2 * f.swing, 3.6), fill, ink, seed: 32, w: w, hatch: hatch)
        }
        k.with(about(50, 30, rot: rot, sx: sx, sy: sy)) {
            let rip: CGFloat = 0.9 * e
            let bumps: [(CGFloat, CGFloat, CGFloat)] = [(27, 44, 11), (44, 57, 16), (64, 55, 14), (79, 43, 10)]
            var ps: [CGPath] = [rrect(15, 29, 70, 18, 9)]
            for (i, b) in bumps.enumerated() {
                var r = b.2 * puff + rip * sin(f.t + CGFloat(i) * 1.4)
                if i == 3, f.mood == .calm { r += 1.6 * max(0, f.twitch) }
                ps.append(circ(b.0, b.1, r))
            }
            woodlandBlob(k, uni(ps), fill, ink, seed: 10, hatch: hatch)
            k.face(52 + fx, 45, spread: 8.5, rx: 3.5, ry: 4.4, seed: 33)
            if v == 1 {
                for i in 0..<3 {
                    let u = (f.phase + CGFloat(i) * 0.37).truncatingRemainder(dividingBy: 1)
                    let x: CGFloat = 32 + CGFloat(i) * 17
                    woodlandBlob(k, drop(x, 22 - u * 18, 3.6), Tone(0x6ac8ff), Tone(0x2f7fff), seed: 24 + i, w: w)
                }
            }
            if v == 4 {
                for i in 0..<3 {
                    let u = (f.phase + CGFloat(i) * 0.41).truncatingRemainder(dividingBy: 1)
                    let x: CGFloat = 30 + CGFloat(i) * 19 + 2 * sin(f.t + CGFloat(i))
                    let y: CGFloat = 22 - u * 18
                    let flake = CGMutablePath()
                    for j in 0..<3 {
                        let a = CGFloat(j) * .pi / 3 + f.t
                        flake.addPath(line(x - cos(a) * 3.6, y - sin(a) * 3.6, x + cos(a) * 3.6, y + sin(a) * 3.6))
                    }
                    k.marker(flake, ink, w, seed: 24 + i)
                }
            }
        }
        k.marks(f.mood == .fleeing ? 16 : 86, 74, 12, ink: ink, seed: 40)
    }

    private static func cloudRays(_ t: CGFloat) -> CGPath {
        let p = CGMutablePath()
        for i in 0..<5 {
            let a = -0.2 + CGFloat(i) * 0.42 + 0.05 * sin(t)
            p.addPath(line(72 + cos(a) * 17, 64 + sin(a) * 17, 72 + cos(a) * 24, 64 + sin(a) * 24))
        }
        return p
    }

    static func owl(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone, Tone, Tone)] = [
            (Tone(0x8a5a3a), Tone(0xffa03a), Tone(0xf6d4a4), Tone(0xfff4dc)),
            (Tone(0xf4f6ff), Tone(0x3f8cff), Tone(0xffffff), Tone(0xfff3b0)),
            (Tone(0x6a4aa8), Tone(0xc07aff), Tone(0xe8d8ff), Tone(0xfff4ff)),
            (Tone(0x7a7a92), Tone(0x3fd6c0), Tone(0xe0e4ee), Tone(0xffffff)),
            (Tone(0xd4702a), Tone(0xff4f6a), Tone(0xffd8a8), Tone(0xfff4dc)),
        ]
        let (body, ink, belly, disc) = f.pick(looks)
        let v = f.variant % 5
        let sq = f.squat, st = f.stretch
        let tuck: CGFloat = f.airborne ? sin(f.air * .pi) : 0
        var sy: CGFloat = 1 - 0.16 * sq + 0.1 * st
        var sx: CGFloat = 1 + 0.1 * sq - 0.05 * st
        var rot: CGFloat = 0, fx: CGFloat = 0, dr: CGFloat = 10
        var wing: CGFloat = f.airborne ? 0.05 + sin(f.air * .pi) * (0.55 + 0.45 * sin(f.air * .pi * 4)) : 0.05 - 0.1 * sq
        var tl = pt(27, 97), tr = pt(73, 97)
        switch f.mood {
        case .calm:
            tr = pt(73 + 2 * f.twitch, 97 + 3 * f.twitch)
        case .sleepy:
            sy *= 0.92
            sx *= 1.05
            tl = pt(20, 86)
            tr = pt(80, 86)
            wing = 0
        case .startled:
            sy *= 1.06
            sx *= 0.95
            tl = pt(25, 106)
            tr = pt(75, 106)
            wing = 1.3 + 0.1 * f.swing2
            dr = 11.5
        case .fleeing:
            tl = pt(17, 94)
            tr = pt(62, 100)
            wing = 0.6 + 0.6 * f.swing2
            fx = 3
        case .dizzy:
            rot = 0.12 * sin(f.t)
        }
        let w = woodlandFine(k)
        k.with(about(50, 5, rot: rot, sx: sx, sy: sy)) {
            for (i, x) in ([41, 59] as [CGFloat]).enumerated() {
                woodlandBlob(k, ell(x, 7 + tuck * 4, 6.5, 3.4), Tone(0xff9a2a), Tone(0xff6a1a), seed: 1 + i, w: w)
            }
            let wingP = smooth([27, 62, 13, 46, 15, 27, 28, 40])
            k.with(about(27, 60, rot: -wing)) { woodlandBlob(k, wingP, body.dim(0.85), ink, seed: 3) }
            k.with(about(73, 60, rot: wing)) { woodlandBlob(k, mirror(wingP), body.dim(0.85), ink, seed: 4) }
            let shape = smoothP([pt(50, 83), pt(62, 84), tr, pt(74, 77), pt(78, 58), pt(74, 30), pt(62, 12), pt(50, 9),
                                 pt(38, 12), pt(26, 30), pt(22, 58), pt(26, 77), tl, pt(38, 84)], t: 0.6)
            woodlandBlob(k, shape, body, ink, seed: 10)
            woodlandBlob(k, ell(50, 29, 15, 16), belly, nil, seed: 11)
            let vs = CGMutablePath()
            for (x, y) in [(41, 35), (50, 36), (59, 35), (45.5, 26), (54.5, 26)] as [(CGFloat, CGFloat)] {
                vs.addPath(arc(x - 3, y, x + 3, y, dip: 2.4))
            }
            k.marker(vs, ink, w, seed: 12)
            for (i, x) in ([39, 61] as [CGFloat]).enumerated() {
                woodlandBlob(k, circ(x + fx, 62, dr), disc, ink, seed: 13 + i, w: w, hatch: ink.alpha(0.15))
                k.eye(x + fx, 62, 3.7, 4.3, side: i == 0 ? -1 : 1, seed: 15 + 2 * i)
            }
            k.cheeks(29 + fx, 71 + fx, 49, 3.2, seed: 19)
            woodlandBlob(k, poly([45.5 + fx, 56, 54.5 + fx, 56, 50 + fx, 46]), Tone(0xff9a2a), Tone(0xff6a1a), seed: 21, w: w)
            switch v {
            case 1:
                k.dot(36, 26, 1.8, 1.8, Tone(0x6a7a9a), seed: 22)
                k.dot(66, 38, 1.8, 1.8, Tone(0x6a7a9a), seed: 23)
                k.dot(32, 40, 1.8, 1.8, Tone(0x6a7a9a), seed: 24)
            case 2:
                woodlandBlob(k, poly([28, 88, 50, 95, 72, 88, 50, 81]), Tone(0x2e2a44), ink, seed: 22, w: w, hatch: ink.alpha(0.3))
                k.stick([50, 88, 66, 85, 67 + f.twitch, 76], Tone(0xffc21a), seed: 23, w: w)
                k.dot(67 + f.twitch, 75, 2.6, 2.6, Tone(0xffc21a), seed: 24)
            case 3:
                woodlandBow(k, 50, 42, 7, Tone(0xff3b3b), Tone(0xd8203a), seed: 22)
            case 4:
                woodlandBlob(k, smooth([33, 81, 67, 81, 72, 90, 86, 86, 62, 98, 40, 92], t: 0.7), Tone(0x3f6fe0), Tone(0x6aa8ff), seed: 22, w: w)
                woodlandBlob(k, circ(86, 85, 4.6), .white, Tone(0x6aa8ff), seed: 23, w: w, hatch: Tone(0xc0d8ff, 0.6))
            default:
                break
            }
            k.marks(f.mood == .fleeing ? 16 : 84, 92, 12, ink: ink, seed: 40)
        }
    }
}
