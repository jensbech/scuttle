import Foundation
import CoreGraphics
import ScuttleCore

extension MascotArt {
    private static func mascotWoodlandFace(_ f: FigureFrame, _ k: MascotKit, _ x: CGFloat, _ y: CGFloat, spread: CGFloat, rx: CGFloat, ry: CGFloat, iris: Tone, edge: Tone, lid: Tone, mouthY: CGFloat, mouthW: CGFloat, mouthH: CGFloat, blushX: CGFloat, blushY: CGFloat, mouth: Bool = true) {
        let look: CGFloat = f.mood == .fleeing ? 0.3 : 0.12
        k.eye(x - spread, y, rx, ry, iris: iris, edge: edge, lid: lid, side: -1, look: look)
        k.eye(x + spread, y, rx, ry, iris: iris, edge: edge, lid: lid, side: 1, look: look)
        let by = y + ry + 4.5
        k.brow(x - spread, by, rx * 1.25, side: -1, edge: edge)
        k.brow(x + spread, by, rx * 1.25, side: 1, edge: edge)
        k.blush(x - blushX, blushY)
        k.blush(x + blushX, blushY)
        if mouth { k.mouth(x, mouthY, mouthW, mouthH, edge: edge) }
    }

    private static func mascotWoodlandLimb(_ k: MascotKit, _ x: CGFloat, _ y: CGFloat, _ a: CGFloat, _ len: CGFloat, _ w: CGFloat, _ t: MascotTones) {
        let r = len / 2
        k.cel(ell(x + sin(a) * r, y - cos(a) * r, w, r, a), t, k.line * 0.9)
    }

    private static func mascotWoodlandTwig(_ k: MascotKit, _ p: CGPath, _ fill: Tone, _ edge: Tone, _ w: CGFloat) {
        k.stroke(p, edge, w + k.line * 1.3)
        k.stroke(p, fill, w)
    }

    private static func mascotWoodlandScarf(_ f: FigureFrame, _ k: MascotKit, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ t: MascotTones, stripe: Tone? = nil) {
        let flow: CGFloat = f.mood == .fleeing ? 1 : 0
        let sw = f.swing * (1 + flow)
        let tx0 = x - w * 0.35
        let tail: CGPath
        if flow > 0 {
            tail = smooth([tx0 + 2, y + 1, tx0 - 14, y + 4 + sw * 2, tx0 - 22, y + 1 + sw * 3, tx0 - 20, y - 4 + sw * 3, tx0 - 12, y - 2 + sw, tx0 + 2, y - 3], t: 0.7)
        } else {
            let lx = x + w * 0.35
            tail = smooth([lx - 3, y, lx + 4, y, lx + 5 + sw * 1.5, y - 13, lx - 2 + sw * 1.5, y - 13], t: 0.6)
        }
        k.cel(tail, t, k.line * 0.9, k: 0.15)
        let band = ell(x, y, w, 4.8)
        k.cel(band, t, k.line, k: 0.15)
        if let s = stripe {
            k.clip(band) {
                for i in -2...2 {
                    let sx = x + CGFloat(i) * w * 0.42
                    k.fill(poly([sx - 2, y - 6, sx + 2, y - 6, sx + 5, y + 6, sx + 1, y + 6]), s)
                }
            }
            k.stroke(band, t.line, k.line)
        }
    }

    private static func mascotWoodlandFlower(_ k: MascotKit, _ x: CGFloat, _ y: CGFloat, _ d: CGFloat, _ r: CGFloat, _ spin: CGFloat, _ petal: Tone, _ edge: Tone) {
        let p = CGMutablePath()
        for i in 0..<5 {
            let a = CGFloat(i) * 2 * .pi / 5 + spin
            p.addPath(circ(x + cos(a) * d, y + sin(a) * d, r))
        }
        k.stroke(p, edge, k.line * 1.6)
        k.fill(p, petal)
        k.fs(circ(x, y, r * 0.8), Tone(0xffc93a), edge, k.line * 0.7)
    }

    private static func mascotWoodlandBeanie(_ k: MascotKit, _ cx: CGFloat, _ y: CGFloat, _ w: CGFloat, _ t: MascotTones, cuff: MascotTones, pom: MascotTones) {
        let hw = w / 2
        let dome = smooth([cx - hw, y, cx - hw * 0.9, y + w * 0.32, cx - hw * 0.45, y + w * 0.5, cx, y + w * 0.55, cx + hw * 0.45, y + w * 0.5, cx + hw * 0.9, y + w * 0.32, cx + hw, y], t: 0.9)
        k.cel(dome, t, k.line, k: 0.14)
        k.clip(dome) {
            for i in -2...2 {
                let sx = cx + CGFloat(i) * w * 0.17
                k.stroke(line(sx, y, sx * 0.8 + cx * 0.2, y + w * 0.55), t.shade, k.line * 0.9)
            }
        }
        k.stroke(dome, t.line, k.line)
        k.cel(rrect(cx - hw - 2, y - 4, w + 4, 8, 4), cuff, k.line, k: 0.2)
        k.cel(circ(cx, y + w * 0.58, w * 0.13), pom, k.line, k: 0.2)
    }

    private static let hedgehogFaceShape: CGPath = uni([circ(58, 53, 19), ell(66, 41, 18, 12), circ(70, 58, 13)])
    private static let hedgehogAppleShape: CGPath = uni([circ(23.5, 84, 7), circ(30.5, 84, 7)])
    private static let penguinMaskShape: CGPath = uni([circ(39.5, 56, 15), circ(60.5, 56, 15), ell(50, 40, 22, 15)])
    private static let owlDiscShape: CGPath = uni([circ(37.5, 58, 15), circ(62.5, 58, 15)])
    private static let cloudShapes: [CGPath] = (0..<8).map { j in
        let t = CGFloat(j) * 2 * .pi / 8
        var puffs: [CGPath] = [rrect(13, 22, 74, 26, 13)]
        let centers: [(CGFloat, CGFloat, CGFloat)] = [(27, 44, 16), (48, 58, 22), (70, 52, 18), (85, 38, 11), (15, 34, 11)]
        for (i, c) in centers.enumerated() {
            puffs.append(circ(c.0, c.1, c.2 + 1.1 * sin(t + CGFloat(i) * 1.3)))
        }
        return uni(puffs)
    }

    static func hedgehog(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(Tone, Tone, Tone, Tone, Tone, Tone)] = [
            (Tone(0x8a5232), Tone(0x643820), Tone(0xfad4a4), Tone(0xe4aa76), Tone(0x3f2213), Tone(0x7a3f1a)),
            (Tone(0xc0713a), Tone(0x8e4a22), Tone(0xffe2b8), Tone(0xf0b47e), Tone(0x4a2410), Tone(0x2f7a3a)),
            (Tone(0x86756a), Tone(0x5e4e46), Tone(0xf6dcc0), Tone(0xdcb294), Tone(0x30241e), Tone(0x3a6fd0)),
            (Tone(0x7e4a34), Tone(0x58301e), Tone(0xf8c99a), Tone(0xe0a070), Tone(0x2e160c), Tone(0x7a3f1a)),
            (Tone(0xc89a5a), Tone(0x9c7038), Tone(0xfff0d6), Tone(0xf0cc98), Tone(0x4a3216), Tone(0x8a4a1a)),
        ]
        let v = f.pick(looks)
        let spine = MascotTones(v.0, shade: v.1, line: v.4)
        let back = MascotTones(v.1, shade: v.1.dim(0.78), line: v.4)
        let skin = MascotTones(v.2, shade: v.3, line: v.4)
        let paw = MascotTones(v.1, shade: v.1.dim(0.8), line: v.4)
        let e = min(f.energy, 1.4)
        let b = k.bounce()
        var tilt: CGFloat = 0, len: CGFloat = 1, sweep: CGFloat = 0, squash: CGFloat = 1, look: CGFloat = 0.14
        var armF: CGFloat = 0.9 + 0.4 * f.swing, armB: CGFloat = -0.5 - 0.4 * f.swing
        var armFY: CGFloat = 26
        let stride: CGFloat = 4.5 * e
        let bob: CGFloat = 1.4 * abs(f.swing) * e
        switch f.mood {
        case .calm:
            sweep = 0.05 * f.twitch
        case .sleepy:
            len = 0.8
            squash = 0.9
            armF = 0.15
            armB = -0.1
            tilt = -0.07
        case .startled:
            len = 1.4
            sweep = -0.1
            armF = 2.7 + 0.15 * f.swing2
            armB = -2.5
            armFY = 30
        case .fleeing:
            len = 1.08
            sweep = 0.4 + 0.05 * f.swing
            armF = 0.5 + 1.3 * f.swing
            armB = 0.5 - 1.3 * f.swing
            look = 0.32
        case .dizzy:
            tilt = 0.12 * sin(f.t)
            armF = 1.8 + 0.4 * f.swing
            armB = -1.6
        }
        let xform = about(50, 30, rot: tilt).concatenating(CGAffineTransform(translationX: 3, y: bob)).concatenating(about(50, 0, sx: 1.08 * b.sx, sy: 0.92 * b.sy * squash))
        k.with(xform) {
            let fa = stride * f.sway, fb = -stride * f.sway
            let la = max(0, -f.swing) * 3 * e, lb = max(0, f.swing) * 3 * e
            k.cel(ell(60 + fb, 5 + lb, 6.5, 3.6, 0.1), paw.base.dim(0.85), paw.shade.dim(0.85), paw.line, k.line)
            mascotWoodlandLimb(k, 40, 24, armB, 12, 3.4, MascotTones(v.3, shade: v.3.dim(0.85), line: v.4))
            k.cel(ell(50, 16, 12, 11), skin)
            k.cel(ell(44 + fa, 5 + la, 6.5, 3.6, 0.1), paw)
            hedgehogQuills(k, len: len, sweep: sweep, spine: spine, back: back, wig: f.mood == .startled ? 0.04 * f.swing2 : 0)
            k.cel(circ(48, 52, 29), spine, k.bold, k: 0.12)
            if f.variant % 5 == 3 {
                mascotWoodlandScarf(f, k, 50, 25, 15, MascotTones(Tone(0xe8484a)), stripe: Tone(0xfff4e8))
            }
            k.cel(circ(38, 76, 6), skin)
            k.fill(circ(38, 76, 2.8), Tone(0xff9fb0))
            let face = hedgehogFaceShape
            k.cel(face, skin, k.line, k: 0.1)
            k.cel(ell(76, 43, 12, 8, 0.08), skin, k.line, k: 0.12)
            k.fill(circ(86.5, 45, 4.3), v.4.lift(0.1))
            k.fill(ell(85.3, 46.6, 1.5, 0.9), .white)
            k.eye(57, 57, 7.6, 10.5, iris: v.5, edge: v.4, lid: v.2, side: -1, look: look)
            k.eye(72, 57.5, 6.3, 9.8, iris: v.5, edge: v.4, lid: v.2, side: 1, look: look)
            k.brow(56, 72.5, 9, side: -1, edge: v.4)
            k.brow(72.5, 72, 7.5, side: 1, edge: v.4)
            k.blush(51, 44, 4.2, 2.5)
            k.mouth(72, 35, 12, 7.5, edge: v.4)
            mascotWoodlandLimb(k, 64, armFY, armF, 12, 3.4, skin)
            hedgehogProp(f, k)
            k.marks(84, 80, 13, edge: v.4)
        }
    }

    private static func hedgehogQuills(_ k: MascotKit, len: CGFloat, sweep: CGFloat, spine: MascotTones, back: MascotTones, wig: CGFloat) {
        for layer in 0..<2 {
            var q: [CGPoint] = []
            let n = layer == 0 ? 5 : 6
            let off: CGFloat = layer == 0 ? 0.1 : 0
            for i in 0...(2 * n) {
                let t = CGFloat(i) / CGFloat(2 * n)
                let a: CGFloat = 0.3 * .pi + off + 1.02 * .pi * t
                let tip = i % 2 == 1
                let base: CGFloat = layer == 0 ? 20 : 13
                let l: CGFloat = (base + 9 * sin(t * .pi)) * len
                let r: CGFloat = tip ? 27 + l : 24
                let sw: CGFloat = tip ? 0.3 + sweep * (0.4 + t) + wig * CGFloat(i % 4 == 1 ? 1 : -1) : 0
                q.append(pt(48 + cos(a + sw) * r, 52 + sin(a + sw) * r))
            }
            q.append(pt(52, 44))
            k.cel(polyP(q), layer == 0 ? back : spine, k.line, k: 0.08)
        }
    }

    private static func hedgehogProp(_ f: FigureFrame, _ k: MascotKit) {
        switch f.variant % 5 {
        case 1:
            let apple = MascotTones(Tone(0xf0443a), line: Tone(0x5a1010))
            k.cel(hedgehogAppleShape, apple, k.line, k: 0.18)
            k.stroke(line(27, 90, 28, 96), Tone(0x4a2a14), k.line * 1.2)
            k.cel(ell(33.5, 95, 5, 2.6, 0.4), MascotTones(Tone(0x5fc04a)), k.line * 0.85)
            k.fill(ell(22, 87, 1.8, 2.6, 0.4), Tone.white.alpha(0.7))
        case 2:
            let leaf = MascotTones(Tone(0xf5892e), line: Tone(0x6a2a08))
            k.with(about(26, 84, rot: 0.5 + 0.08 * f.twitch)) {
                k.cel(smooth([26, 72, 35, 82, 26, 100, 17, 82], t: 0.8), leaf, k.line, k: 0.15)
                k.stroke(line(26, 70, 26, 95), leaf.line, k.line * 0.8)
            }
        case 4:
            let cap = MascotTones(Tone(0xec4a48), line: Tone(0x5a1414))
            k.cel(rrect(23, 77, 8, 11, 3.5), MascotTones(Tone(0xfff3de)), k.line * 0.9)
            let c = smooth([13, 87, 18, 96, 27, 99, 36, 96, 41, 87, 27, 84], t: 0.8)
            k.cel(c, cap, k.line, k: 0.15)
            k.fill(circ(21, 91, 2.3), .white)
            k.fill(circ(32, 92, 2.3), .white)
            k.fill(circ(27, 96, 1.7), .white)
        default:
            break
        }
    }

    static func acorn(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0xe2a45e), Tone(0x8a5a32), Tone(0x7a3f1a)),
            (Tone(0xbcd45a), Tone(0x9c7a46), Tone(0x2f8a2a)),
            (Tone(0xd8743e), Tone(0x6e4a2c), Tone(0x8a3a1a)),
            (Tone(0xf4c866), Tone(0x7a5838), Tone(0xb05a10)),
            (Tone(0xc08050), Tone(0xa8784a), Tone(0x4a5ad0)),
        ]
        let v = f.pick(looks)
        let nut = MascotTones(v.0)
        let cap = MascotTones(v.1)
        let b = k.bounce()
        let hopArc: CGFloat = f.airborne ? sin(f.air * .pi) : 0
        var tilt: CGFloat = 0, faceX: CGFloat = 0, capUp: CGFloat = 0, capRot: CGFloat = f.variant % 5 == 4 ? -0.16 : 0
        var arm: CGFloat = 0.45 + 1.4 * hopArc
        var armR: CGFloat = arm
        switch f.mood {
        case .calm:
            armR += 1.2 * max(0, f.twitch)
        case .sleepy:
            arm = 0.12
            armR = 0.12
            capRot -= 0.12
            capUp = -3
        case .startled:
            capUp = 8 + 2 * f.swing2
            capRot += 0.08
            arm = 2.6
            armR = 2.6
        case .fleeing:
            faceX = 3
            capRot += 0.2
            capUp = 1.5
            arm = 1.9 + 0.4 * f.swing
            armR = 1.9 - 0.4 * f.swing
        case .dizzy:
            tilt = 0.12 * sin(f.t)
            capRot += 0.1 * sin(f.t + 1)
            arm = 1.2 + 0.5 * f.swing
            armR = 1.2 - 0.5 * f.swing
        }
        let tuck: CGFloat = 3 * hopArc
        k.with(about(50, 30, rot: tilt).concatenating(about(50, 0, sx: b.sx, sy: b.sy))) {
            let foot = MascotTones(v.1.dim(0.9))
            k.cel(ell(41 - tuck * 0.6, 5 + tuck, 5.8, 3.2, -0.15 * hopArc), foot)
            k.cel(ell(59 + tuck * 0.6, 5 + tuck, 5.8, 3.2, 0.15 * hopArc), foot)
            mascotWoodlandLimb(k, 21, 34, -arm, 11, 3.3, nut)
            mascotWoodlandLimb(k, 79, 34, armR, 11, 3.3, nut)
            let body = smooth([50, 8, 67, 12, 79, 26, 82, 44, 78, 60, 22, 60, 18, 44, 21, 26, 33, 12])
            k.cel(body, nut, k.bold, k: 0.12)
            k.fill(ell(30 + faceX * 0.3, 44, 3, 6, 0.3), Tone.white.alpha(0.55))
            mascotWoodlandFace(f, k, 50 + faceX, 35, spread: 10.5, rx: 8, ry: 10, iris: v.2, edge: nut.line, lid: nut.base, mouthY: 22, mouthW: 13, mouthH: 8, blushX: 23, blushY: 26)
            k.with(CGAffineTransform(translationX: 0, y: capUp).concatenating(about(50, 56, rot: capRot))) {
                acornCap(f, k, cap)
            }
            k.marks(84, 84, 13, edge: nut.line)
        }
    }

    private static func acornCap(_ f: FigureFrame, _ k: MascotKit, _ cap: MascotTones) {
        let stemA: CGFloat = 0.25 * f.twitch + (f.mood == .fleeing ? 0.3 : 0)
        k.with(about(50, 84, rot: -stemA)) {
            let stem = smooth([50, 83, 51, 92, 57, 97], closed: false)
            mascotWoodlandTwig(k, stem, cap.base.dim(0.85), cap.line, 3.6)
            switch f.variant % 5 {
            case 1:
                k.cel(ell(62, 97, 6, 3, 0.3), MascotTones(Tone(0x5fc04a)), k.line * 0.9)
                k.stroke(line(57, 96, 66, 98.5), Tone(0x2c6a1c), k.line * 0.6)
            case 3:
                mascotWoodlandFlower(k, 60, 98, 3.6, 2.7, 0, .white, Tone(0x4a3a6a))
            default:
                break
            }
        }
        let shape = smooth([13, 58, 16, 70, 30, 82, 50, 86, 70, 82, 84, 70, 87, 58, 74, 55, 50, 55, 26, 55], t: 0.9)
        k.cel(shape, cap, k.bold, k: 0.14)
        k.clip(shape) {
            let scales = CGMutablePath()
            for row in 0..<3 {
                let y: CGFloat = 61 + CGFloat(row) * 8
                let off: CGFloat = row % 2 == 0 ? 0 : 4.5
                var x: CGFloat = 10 + off
                while x < 88 {
                    scales.move(to: pt(x, y))
                    scales.addQuadCurve(to: pt(x + 9, y), control: pt(x + 4.5, y - 3))
                    x += 9
                }
            }
            k.stroke(scales, cap.line.alpha(0.5), k.line * 0.7)
        }
        k.stroke(shape, cap.line, k.bold)
        switch f.variant % 5 {
        case 2:
            let bow = MascotTones(Tone(0xff4d6a), line: Tone(0x6a1424))
            k.cel(smooth([70, 76, 62, 82, 62, 70], t: 0.5), bow, k.line * 0.9)
            k.cel(smooth([70, 76, 79, 82, 79, 70], t: 0.5), bow, k.line * 0.9)
            k.cel(circ(70, 76, 2.8), bow, k.line * 0.9)
        case 4:
            k.with(about(30, 74, rot: 0.5 + 0.1 * f.twitch)) {
                k.cel(ell(30, 84, 3.6, 11), MascotTones(Tone(0x4aa8f0)), k.line * 0.9, k: 0.2)
                k.stroke(line(30, 74, 30, 94), Tone(0x1a3a6a), k.line * 0.6)
            }
        default:
            break
        }
    }

    static func toadstool(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0xec4a48), Tone(0xffffff), Tone(0x8a3a1a)),
            (Tone(0xbc7842), Tone(0xf8e6c4), Tone(0x6a3a14)),
            (Tone(0x9a5ae0), Tone(0xffe066), Tone(0x6a3ac0)),
            (Tone(0x3f8ee8), Tone(0xffffff), Tone(0x2a5ac0)),
            (Tone(0xf6b030), Tone(0xe8484a), Tone(0xc05a10)),
        ]
        let v = f.pick(looks)
        let cap = MascotTones(v.0)
        let stem = MascotTones(Tone(0xfff3de), shade: Tone(0xeccfae), line: Tone(0x6a3a2a))
        let e = min(f.energy, 1.4)
        let b = k.bounce()
        var tilt: CGFloat = 0, faceX: CGFloat = 0, capUp: CGFloat = 0
        var capRot: CGFloat = -0.05 * f.swing * e
        var armL: CGFloat = 0.5 - 0.35 * f.swing, armR: CGFloat = 0.5 + 0.35 * f.swing
        let bob: CGFloat = 1.3 * abs(f.swing) * e
        switch f.mood {
        case .calm:
            armR += 1.3 * max(0, f.twitch)
        case .sleepy:
            capRot = -0.12
            capUp = -3
            armL = 0.1
            armR = 0.1
        case .startled:
            capUp = 7 + 1.5 * f.swing2
            armL = 2.6
            armR = 2.6
        case .fleeing:
            capRot = 0.18 + 0.04 * f.swing
            faceX = 3
            armL = 1.6 + 0.6 * f.swing
            armR = 1.6 - 0.6 * f.swing
        case .dizzy:
            tilt = 0.12 * sin(f.t)
            capRot = 0.12 * sin(f.t + 1.2)
            armL = 1.2
            armR = 1.2
        }
        let stride: CGFloat = 4 * e
        k.with(about(50, 30, rot: tilt).concatenating(CGAffineTransform(translationX: 0, y: bob)).concatenating(about(50, 0, sx: b.sx, sy: b.sy))) {
            let feet = MascotTones(Tone(0xe8c8a0), shade: Tone(0xc8a078), line: stem.line)
            k.cel(ell(41 + stride * f.sway, 5 + max(0, -f.swing) * 3 * e, 6.5, 3.4), feet)
            k.cel(ell(59 - stride * f.sway, 5 + max(0, f.swing) * 3 * e, 6.5, 3.4), feet)
            mascotWoodlandLimb(k, 29, 32, -armL, 11, 3.3, stem)
            mascotWoodlandLimb(k, 71, 32, armR, 11, 3.3, stem)
            let body = smooth([31, 58, 26, 38, 29, 17, 38, 10, 50, 9, 62, 10, 71, 17, 74, 38, 69, 58])
            k.cel(body, stem, k.bold, k: 0.12)
            mascotWoodlandFace(f, k, 50 + faceX, 35, spread: 10, rx: 7.6, ry: 9.4, iris: v.2, edge: stem.line, lid: stem.base, mouthY: 21.5, mouthW: 11, mouthH: 6.8, blushX: 17, blushY: 25)
            k.with(CGAffineTransform(translationX: 0, y: capUp).concatenating(about(50, 56, rot: capRot))) {
                k.cel(ell(50, 57.5, 31, 4.2), MascotTones(Tone(0xf4dcc0), shade: Tone(0xd8b894), line: stem.line), k.line, k: 0.1)
                let c = smooth([5, 61, 9, 75, 26, 90, 50, 96, 74, 90, 91, 75, 95, 61, 82, 57, 50, 58, 18, 57], t: 0.9)
                k.cel(c, cap, k.bold, k: 0.13)
                k.clip(c) {
                    let spots: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)] = [(28, 79, 7.5, 5.5, 0.4), (53, 88, 7, 4.6, 0), (75, 78, 6.8, 5.2, -0.35), (13, 64, 4.8, 4, 0.5), (88, 65, 4.8, 4, -0.5), (49, 70, 5, 3.8, 0)]
                    let n = f.variant % 5 == 1 ? 3 : spots.count
                    let sp = CGMutablePath()
                    for s in spots.prefix(n) {
                        sp.addPath(ell(s.0, s.1, s.2, s.3, s.4))
                    }
                    k.fill(sp, v.1)
                }
                k.stroke(c, cap.line, k.bold)
                toadstoolProp(f, k)
            }
            k.marks(86, 86, 13, edge: cap.line)
        }
    }

    private static func toadstoolProp(_ f: FigureFrame, _ k: MascotKit) {
        switch f.variant % 5 {
        case 1:
            let leaf = MascotTones(Tone(0xf6b030), line: Tone(0x6a3a08))
            k.with(about(66, 90, rot: -0.7 + 0.08 * f.twitch)) {
                k.cel(smooth([66, 82, 73, 90, 66, 104, 59, 90], t: 0.8), leaf, k.line, k: 0.15)
                k.stroke(line(66, 80, 66, 100), leaf.line, k.line * 0.8)
            }
        case 3:
            let bow = MascotTones(Tone(0xff5fae), line: Tone(0x7a1a4a))
            k.cel(smooth([62, 92, 52, 99, 52, 86], t: 0.5), bow, k.line * 0.9)
            k.cel(smooth([62, 92, 72, 99, 72, 86], t: 0.5), bow, k.line * 0.9)
            k.cel(circ(62, 92, 3), bow, k.line * 0.9)
        case 4:
            k.stroke(line(70, 90, 72, 99), Tone(0x2c6a1c), k.line)
            mascotWoodlandFlower(k, 72, 101, 3.8, 2.9, 0.3 * f.twitch, .white, Tone(0x4a3a6a))
        default:
            break
        }
    }

    static func leaf(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(Tone, Tone, Int)] = [
            (Tone(0xf5892e), Tone(0x8a3a10), 0),
            (Tone(0xe8443a), Tone(0x8a1a1a), 0),
            (Tone(0xf6c83a), Tone(0x9a5a10), 1),
            (Tone(0x6cc04a), Tone(0x2a7a2a), 2),
            (Tone(0xc8603a), Tone(0x6a2a1a), 0),
        ]
        let v = f.pick(looks)
        let t = MascotTones(v.0)
        var tilt: CGFloat = 0, faceX: CGFloat = 0, faceY: CGFloat = 0
        var sx: CGFloat = 0.93 + 0.07 * cos(f.t), sy: CGFloat = 1
        var stemA: CGFloat = 0.2 * f.twitch + 0.1 * sin(f.t)
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sx *= 0.9
            sy = 0.94
            tilt = -0.12
            faceY = -2
        case .startled:
            sx *= 1.05
            sy = 1.1
        case .fleeing:
            tilt = -0.18
            faceX = 3
            sx *= 0.94
            stemA = 0.5 + 0.15 * sin(f.t)
        case .dizzy:
            tilt = 0.14 * sin(f.t)
        }
        k.with(about(50, 50, rot: tilt).concatenating(about(50, 50, sx: sx, sy: sy))) {
            k.with(about(50, 37, rot: -stemA)) {
                mascotWoodlandTwig(k, smooth([50, 39, 49, 27, 45, 18, 39, 18], closed: false), t.shade.dim(0.9), t.line, 3.4)
            }
            let shape: CGPath
            var tips: [CGFloat] = []
            switch v.2 {
            case 1:
                let p = CGMutablePath()
                p.move(to: pt(50, 95))
                p.addCurve(to: pt(50, 13), control1: pt(90, 74), control2: pt(86, 24))
                p.addCurve(to: pt(50, 95), control1: pt(14, 24), control2: pt(10, 74))
                p.closeSubpath()
                shape = p
                tips = [90, 30, 150, -15, 195]
            case 2:
                var q: [CGPoint] = []
                for i in 0..<14 {
                    let a: CGFloat = -.pi / 2 + CGFloat(i) * 2 * .pi / 14
                    var r: CGFloat = i % 2 == 0 ? 1 : 0.66
                    if i == 0 { r = 0.72 }
                    q.append(pt(50 + cos(a) * 36 * r, 53 + sin(a) * 42 * r))
                }
                shape = smoothP(q, t: 0.85)
                tips = [90, 38, 142, -12, 192]
            default:
                let pts: [(CGFloat, CGFloat)] = [(-90, 14), (-55, 20), (-22, 32), (-14, 37), (-6, 31), (11, 24), (24, 39), (28, 36), (38, 50), (48, 40), (52, 43), (66, 26), (78, 44), (82, 41), (90, 54), (98, 41), (102, 44), (114, 26), (128, 43), (132, 40), (142, 50), (152, 36), (156, 39), (169, 24), (186, 31), (194, 37), (202, 32), (235, 20)]
                shape = smoothP(pts.map { pt(50 + cos($0.0 * .pi / 180) * $0.1, 50 + sin($0.0 * .pi / 180) * $0.1) }, t: 0.35)
                tips = [-14, 38, 90, 142, 194]
            }
            k.cel(shape, t, k.bold, k: 0.12)
            k.clip(shape) {
                for a in tips {
                    let ca = cos(a * .pi / 180), sa = sin(a * .pi / 180)
                    k.stroke(line(50 + ca * 27, 50 + sa * 27, 50 + ca * 52, 50 + sa * 52), t.shade.dim(0.88), k.line * 0.85)
                }
                k.stroke(line(50, 30, 50, 38), t.shade.dim(0.88), k.line * 0.85)
            }
            mascotWoodlandFace(f, k, 50 + faceX, 53 + faceY, spread: 9.5, rx: 7.4, ry: 9.4, iris: v.1, edge: t.line, lid: t.base, mouthY: 40 + faceY, mouthW: 11, mouthH: 7, blushX: 18, blushY: 43 + faceY)
            switch f.variant % 5 {
            case 1:
                let d = drop(70, 76, 4.2, 0.2)
                k.cel(d, MascotTones(Tone(0xb8ecff), shade: Tone(0x7cc8f0), line: Tone(0x1a4a7a)), k.line * 0.85, k: 0.2)
                k.fill(ell(68.6, 75.4, 1.1, 1.8, 0.2), .white)
            case 4:
                leafLadybird(f, k, 28, 74)
            default:
                break
            }
            k.marks(80, 84, 13, edge: t.line)
        }
    }

    private static func leafLadybird(_ f: FigureFrame, _ k: MascotKit, _ x: CGFloat, _ y: CGFloat) {
        let ink = MascotTones(Tone(0x3a3050), line: Tone(0x1a1028))
        k.cel(circ(x + 5.5, y + 1.5, 3), ink, k.line * 0.8)
        let shell = MascotTones(Tone(0xf0443a), line: Tone(0x4a1010))
        k.cel(circ(x, y, 5.6), shell, k.line * 0.9, k: 0.18)
        k.stroke(line(x + 1.5, y + 5, x - 1.5, y - 5), shell.line, k.line * 0.7)
        k.fill(circ(x - 2.6, y + 1.6, 1.4), ink.base)
        k.fill(circ(x + 2.4, y - 1.4, 1.4), ink.base)
    }

    static func penguin(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(Tone, Tone, Tone, Tone)] = [
            (Tone(0x4f86e8), Tone(0x3460c4), Tone(0x14245a), Tone(0x2a6fe0)),
            (Tone(0x2fb3c4), Tone(0x1f8496), Tone(0x0e3a48), Tone(0x168a9e)),
            (Tone(0x8a6ee6), Tone(0x6248c0), Tone(0x281a5c), Tone(0x6a3fd0)),
            (Tone(0x5aaaf2), Tone(0x3a7ed0), Tone(0x163a6a), Tone(0x2a6fe0)),
            (Tone(0x6878d4), Tone(0x4856ac), Tone(0x1c2250), Tone(0xd08a20)),
        ]
        let v = f.pick(looks)
        let body = MascotTones(v.0, shade: v.1, line: v.2)
        let white = MascotTones(Tone(0xfdfbf6), shade: Tone(0xd3d8ea), line: v.2)
        let orange = MascotTones(Tone(0xffa62e), shade: Tone(0xe27a10), line: v.2)
        let e = min(f.energy, 1.4)
        let b = k.bounce()
        var tilt: CGFloat = 0, faceX: CGFloat = 0, faceY: CGFloat = 0, hatUp: CGFloat = 0
        var flL: CGFloat = 0.45 - 0.25 * f.swing, flR: CGFloat = 0.45 + 0.25 * f.swing
        switch f.mood {
        case .calm:
            flR += 1.5 * max(0, f.twitch)
        case .sleepy:
            flL = 0.12
            flR = 0.12
            faceY = -2
        case .startled:
            flL = 1.8 + 0.12 * f.swing2
            flR = 1.8 - 0.12 * f.swing2
            hatUp = 5
        case .fleeing:
            flL = 1.45 + 0.45 * f.swing
            flR = 1.45 - 0.45 * f.swing
            faceX = 3
        case .dizzy:
            tilt = 0.12 * sin(f.t)
            flL = 1.0 + 0.6 * f.swing
            flR = 1.0 - 0.6 * f.swing
        }
        let bob: CGFloat = 1.2 * abs(f.swing) * e
        k.with(about(50, 30, rot: tilt).concatenating(CGAffineTransform(translationX: 0, y: bob)).concatenating(about(50, 0, sx: 0.94 * b.sx, sy: 1.04 * b.sy))) {
            k.cel(ell(42, 4 + max(0, f.swing) * 3 * e, 6.5, 3.2), orange)
            k.cel(ell(58, 4 + max(0, -f.swing) * 3 * e, 6.5, 3.2), orange)
            let up = f.mood == .startled || f.mood == .fleeing
            let fl: CGFloat = up ? 20 : 17, sh: CGFloat = up ? 3 : 0
            mascotWoodlandLimb(k, 37 - sh, 25, -flL, fl, 3.8, body)
            mascotWoodlandLimb(k, 63 + sh, 25, flR, fl, 3.8, body)
            k.cel(ell(50, 15, 13, 12), body)
            k.cel(ell(50, 13, 8.5, 8.5), white, k.line)
            if f.variant % 5 != 2 {
                k.with(about(50, 80, rot: 0.15 * f.twitch)) {
                    k.cel(smooth([45, 80, 48, 92, 52, 84, 57, 90, 56, 80], t: 0.6), body, k.line)
                }
            }
            k.cel(circ(50, 52, 31), body, k.bold, k: 0.12)
            let mx = faceX * 0.7
            k.cel(moved(penguinMaskShape, mx, faceY), white, k.line, k: 0.12)
            if f.variant % 5 == 1 {
                mascotWoodlandScarf(f, k, 50, 23, 17, MascotTones(Tone(0xe8484a)), stripe: Tone(0xfff4e8))
            }
            penguinHat(f, k, hatUp, body)
            let fx = 50 + faceX, fy = faceY
            k.eye(fx - 10, 56 + fy, 8, 10.5, iris: v.3, edge: v.2, lid: white.base, side: -1, look: f.mood == .fleeing ? 0.3 : 0.12)
            k.eye(fx + 10, 56 + fy, 8, 10.5, iris: v.3, edge: v.2, lid: white.base, side: 1, look: f.mood == .fleeing ? 0.3 : 0.12)
            k.brow(fx - 10, 71 + fy, 10, side: -1, edge: v.2)
            k.brow(fx + 10, 71 + fy, 10, side: 1, edge: v.2)
            k.blush(fx - 20.5, 45 + fy, 4.4, 2.5)
            k.blush(fx + 20.5, 45 + fy, 4.4, 2.5)
            k.cel(smooth([fx - 8.5, 42 + fy, fx + 8.5, 42 + fy, fx + 6, 34 + fy, fx, 31.5 + fy, fx - 6, 34 + fy], t: 0.9), orange, k.line * 0.9)
            k.mouth(fx, 41.5 + fy, 10, 6.5, edge: v.2)
            k.cel(smooth([fx - 8, 44.5 + fy, fx + 8, 44.5 + fy, fx, 39 + fy], t: 0.5), orange, k.line * 0.9)
            if f.variant % 5 == 4 {
                let bow = MascotTones(Tone(0xe8384a), line: Tone(0x5a1020))
                k.cel(smooth([50, 23, 40, 28, 40, 18], t: 0.5), bow, k.line * 0.9)
                k.cel(smooth([50, 23, 60, 28, 60, 18], t: 0.5), bow, k.line * 0.9)
                k.cel(circ(50, 23, 2.8), bow, k.line * 0.9)
            }
            k.marks(82, 82, 13, edge: v.2)
        }
    }

    private static func penguinHat(_ f: FigureFrame, _ k: MascotKit, _ up: CGFloat, _ body: MascotTones) {
        switch f.variant % 5 {
        case 2:
            k.with(CGAffineTransform(translationX: 0, y: up).concatenating(about(50, 78, rot: -0.08 + 0.05 * f.twitch))) {
                mascotWoodlandBeanie(k, 50, 78, 50, MascotTones(Tone(0xf6c13a)), cuff: MascotTones(Tone(0xf05a5a)), pom: MascotTones(Tone(0xfdfbf6), shade: Tone(0xd3d8ea)))
            }
        case 3:
            let muff = MascotTones(Tone(0xff8ab8), line: Tone(0x7a1a4a))
            k.with(CGAffineTransform(translationX: 0, y: up * 0.6)) {
                k.stroke(arc(20, 62, 80, 62, dip: -34), muff.line, k.line * 3.2)
                k.stroke(arc(20, 62, 80, 62, dip: -34), Tone(0xb070d8), k.line * 1.7)
                k.cel(circ(19, 58, 7.5), muff, k.line, k: 0.18)
                k.cel(circ(81, 58, 7.5), muff, k.line, k: 0.18)
            }
        default:
            break
        }
    }

    static func snowman(_ f: FigureFrame, _ k: MascotKit) {
        let snow = MascotTones(Tone(0xf7faff), shade: Tone(0xbccdf2), line: Tone(0x34477a))
        let looks: [(Tone, Tone)] = [
            (Tone(0xe8484a), Tone(0x3a6fd8)),
            (Tone(0x3fb86a), Tone(0x2a9a5a)),
            (Tone(0x4a8ae8), Tone(0x8a5ae0)),
            (Tone(0xf6c13a), Tone(0x3a6fd8)),
            (Tone(0x9a5ae0), Tone(0x2a6fe0)),
        ]
        let v = f.pick(looks)
        let scarf = MascotTones(v.0)
        let e = min(f.energy, 1.4)
        let b = k.bounce()
        var tilt: CGFloat = 0, faceX: CGFloat = 0, hatUp: CGFloat = 0, hatRot: CGFloat = 0
        var armL: CGFloat = 0.45 + 0.25 * f.swing, armR: CGFloat = 0.45 - 0.25 * f.swing
        switch f.mood {
        case .calm:
            armR += 0.7 * max(0, f.twitch) + 0.25 * f.twitch
        case .sleepy:
            armL = -0.6
            armR = -0.6
            hatRot = 0.22
            hatUp = -4
        case .startled:
            armL = 1.25 + 0.1 * f.swing2
            armR = 1.25 - 0.1 * f.swing2
            hatUp = 9 + 1.5 * f.swing2
            hatRot = -0.1
        case .fleeing:
            armL = 0.9 + 0.35 * f.swing
            armR = -0.5 - 0.5 * f.swing
            faceX = 3
            hatRot = 0.3
            hatUp = 2
        case .dizzy:
            tilt = 0.12 * sin(f.t)
            hatRot = 0.15 * sin(f.t + 1)
            armL = 0.3 + 0.6 * f.swing
            armR = 0.3 - 0.6 * f.swing
        }
        let bob: CGFloat = 1.5 * abs(f.swing) * e
        let stride: CGFloat = 4 * e
        k.with(about(50, 30, rot: tilt).concatenating(about(50, 0, sx: b.sx, sy: b.sy))) {
            k.cel(ell(41 + stride * f.sway, 4.5 + max(0, -f.swing) * 3 * e, 6.5, 3.6), snow)
            k.cel(ell(59 - stride * f.sway, 4.5 + max(0, f.swing) * 3 * e, 6.5, 3.6), snow)
            k.with(CGAffineTransform(translationX: 0, y: bob)) {
                let twig = Tone(0x8a5a32), twigLine = Tone(0x3a2010)
                k.both { s in
                    let a = s < 0 ? armL : armR
                    let sx: CGFloat = 50 + s * 15, sy: CGFloat = 22
                    let hx = sx + s * cos(a) * 17, hy = sy + sin(a) * 17
                    let p = CGMutablePath()
                    p.move(to: pt(sx, sy))
                    p.addLine(to: pt(hx, hy))
                    let fa: CGFloat = a + 0.6, fb: CGFloat = a - 0.5
                    p.move(to: pt(sx + s * cos(a) * 11, sy + sin(a) * 11))
                    p.addLine(to: pt(sx + s * cos(a) * 11 + s * cos(fa) * 6, sy + sin(a) * 11 + sin(fa) * 6))
                    p.move(to: pt(hx, hy))
                    p.addLine(to: pt(hx + s * cos(fb) * 5, hy + sin(fb) * 5))
                    mascotWoodlandTwig(k, p, twig, twigLine, k.line * 0.9)
                }
                k.cel(ell(50, 18, 19, 15), snow, k.bold, k: 0.12)
                k.fill(circ(50, 13, 2.5), Tone(0x3a3f5c))
                k.fill(circ(50, 21, 2.5), Tone(0x3a3f5c))
                k.cel(circ(50, 55, 26.5), snow, k.bold, k: 0.12)
                mascotWoodlandScarf(f, k, 50, 30, 18, scarf, stripe: f.variant % 5 == 1 ? Tone(0xfdfbf6) : nil)
                snowmanHat(f, k, hatUp, hatRot)
                let fx = 50 + faceX
                mascotWoodlandFace(f, k, fx, 58, spread: 10, rx: 7.6, ry: 9.6, iris: v.1, edge: snow.line, lid: snow.base, mouthY: 42, mouthW: 12, mouthH: 7, blushX: 18, blushY: 46)
                let carrot = MascotTones(Tone(0xff9a2e), shade: Tone(0xe2700e), line: Tone(0x6a2a08))
                let nr: CGFloat = f.mood == .fleeing ? 0.15 : (f.mood == .sleepy ? -0.25 : 0)
                k.with(about(fx, 50, rot: nr)) {
                    k.cel(smooth([fx - 2, 53, fx + 15, 49.5, fx - 2, 46.5], t: 0.55), carrot, k.line * 0.9, k: 0.2)
                }
                k.marks(82, 82, 13, edge: snow.line)
            }
        }
    }

    private static func snowmanHat(_ f: FigureFrame, _ k: MascotKit, _ up: CGFloat, _ rot: CGFloat) {
        let tr = CGAffineTransform(translationX: 0, y: up).concatenating(about(50, 80, rot: rot + 0.04 * f.twitch))
        k.with(tr) {
            switch f.variant % 5 {
            case 0:
                let hat = MascotTones(Tone(0x4a5080), shade: Tone(0x32365c), line: Tone(0x14162e))
                let crown = rrect(37, 80, 26, 21, 3)
                k.cel(crown, hat, k.line, k: 0.15)
                k.clip(crown) { k.fill(rrect(36, 81, 28, 5, 0), Tone(0xe8484a)) }
                k.stroke(crown, hat.line, k.line)
                k.cel(ell(50, 80.5, 20, 4.2), hat, k.line, k: 0.2)
            case 1:
                mascotWoodlandBeanie(k, 50, 77, 44, MascotTones(Tone(0x3fb86a)), cuff: MascotTones(Tone(0xfdfbf6), shade: Tone(0xc8d8ee)), pom: MascotTones(Tone(0xe8484a)))
            case 2:
                let muff = MascotTones(Tone(0xff8ab8), line: Tone(0x7a1a4a))
                k.stroke(arc(24, 62, 76, 62, dip: -28), muff.line, k.line * 3.2)
                k.stroke(arc(24, 62, 76, 62, dip: -28), Tone(0xb070d8), k.line * 1.7)
                k.cel(circ(23.5, 57, 7.5), muff, k.line, k: 0.18)
                k.cel(circ(76.5, 57, 7.5), muff, k.line, k: 0.18)
            case 3:
                let leaf = MascotTones(Tone(0x3fae5a), line: Tone(0x14401e))
                k.cel(smooth([66, 78, 74, 84, 82, 80, 76, 76], t: 0.7), leaf, k.line * 0.9)
                k.cel(smooth([66, 78, 62, 87, 66, 93, 69, 85], t: 0.7), leaf, k.line * 0.9)
                let berry = MascotTones(Tone(0xf0343a), line: Tone(0x5a1010))
                k.cel(circ(64, 77, 3), berry, k.line * 0.8)
                k.cel(circ(69, 75, 3), berry, k.line * 0.8)
            default:
                let pail = MascotTones(Tone(0x9ab4dc), shade: Tone(0x6e88b8), line: Tone(0x22345a))
                k.with(about(50, 80, rot: -0.14)) {
                    k.stroke(arc(36, 88, 64, 88, dip: 9), pail.line, k.line * 1.1)
                    k.cel(poly([34, 79, 66, 79, 61, 98, 39, 98]), pail, k.line, k: 0.15)
                    k.cel(rrect(32, 77, 36, 5, 2.5), pail, k.line * 0.9)
                }
            }
        }
    }

    static func snowflake(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(Tone, Tone, Tone, Int)] = [
            (Tone(0xd2eaff), Tone(0x2c5a9e), Tone(0x2a6fe0), 0),
            (Tone(0xe4d8ff), Tone(0x4a3a9a), Tone(0x7a4fe0), 1),
            (Tone(0xcff7e8), Tone(0x1f6a54), Tone(0x14957a), 2),
            (Tone(0xf6f9ff), Tone(0x3a4a8a), Tone(0x3a8ae0), 0),
            (Tone(0xffdcec), Tone(0x8a2e5e), Tone(0xd0408a), 1),
        ]
        let v = f.pick(looks)
        let t = MascotTones(v.0, line: v.1)
        var tilt: CGFloat = 0, faceX: CGFloat = 0, reach: CGFloat = 44
        var spin: CGFloat = f.phase * .pi / 3
        var sy: CGFloat = 1
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            reach = 40
            sy = 0.95
        case .startled:
            reach = 48
            sy = 1.06
        case .fleeing:
            faceX = 3
            spin = f.phase * 2 * .pi / 3
        case .dizzy:
            tilt = 0.12 * sin(f.t)
            spin = -f.phase * 2 * .pi / 3
        }
        k.with(about(50, 50, rot: tilt).concatenating(about(50, 50, sx: 1 / sy.squareRoot(), sy: sy))) {
            let arms = CGMutablePath()
            var ends: [CGPoint] = []
            for i in 0..<6 {
                let a = spin + CGFloat(i) * .pi / 3 + .pi / 2
                let ca = cos(a), sa = sin(a)
                arms.move(to: pt(50 + ca * 14, 50 + sa * 14))
                arms.addLine(to: pt(50 + ca * reach, 50 + sa * reach))
                ends.append(pt(50 + ca * reach, 50 + sa * reach))
                let br: [(CGFloat, CGFloat)] = v.3 == 2 ? [(31, 8)] : [(30, 9), (39, 5.5)]
                for (r, l) in br {
                    let rr = r * reach / 44
                    let bx = 50 + ca * rr, by = 50 + sa * rr
                    for s in [-1, 1] as [CGFloat] {
                        let ba = a + s * 0.85
                        arms.move(to: pt(bx, by))
                        arms.addLine(to: pt(bx + cos(ba) * l, by + sin(ba) * l))
                    }
                }
            }
            let w: CGFloat = 6.2
            k.stroke(arms, t.line, w + k.line * 2)
            k.stroke(arms, t.shade, w)
            k.with(CGAffineTransform(translationX: -0.9, y: 0.9)) { k.stroke(arms, t.base, w * 0.55) }
            if v.3 != 0 {
                let tipsPath = CGMutablePath()
                for p in ends {
                    if v.3 == 1 {
                        tipsPath.addPath(circ(p.x, p.y, 4.6))
                    } else {
                        tipsPath.addPath(poly([p.x, p.y + 5.5, p.x + 4.5, p.y, p.x, p.y - 5.5, p.x - 4.5, p.y]))
                    }
                }
                k.fill(tipsPath, t.base)
                k.stroke(tipsPath, t.line, k.line * 0.9)
            }
            k.cel(circ(50, 50, 24.5), t, k.bold, k: 0.12)
            k.fill(ell(36, 62, 3, 4.6, 0.6), Tone.white.alpha(0.6))
            mascotWoodlandFace(f, k, 50 + faceX, 52.5, spread: 9.2, rx: 7.4, ry: 9.4, iris: v.2, edge: t.line, lid: t.base, mouthY: 40.5, mouthW: 10, mouthH: 6.2, blushX: 16, blushY: 42.5)
            switch f.variant % 5 {
            case 3:
                k.with(about(50, 70, rot: -0.15 + 0.06 * f.twitch)) {
                    mascotWoodlandBeanie(k, 50, 70, 34, MascotTones(Tone(0xf05a5a)), cuff: MascotTones(Tone(0xfdfbf6), shade: Tone(0xc8d8ee)), pom: MascotTones(Tone(0xfdfbf6), shade: Tone(0xc8d8ee)))
                }
            case 4:
                k.with(about(50, 50, rot: 0)) {
                    let bow = MascotTones(Tone(0xb070e8), line: Tone(0x3a1a6a))
                    k.cel(smooth([64, 68, 56, 75, 57, 63], t: 0.5), bow, k.line * 0.9)
                    k.cel(smooth([64, 68, 72, 75, 72, 62], t: 0.5), bow, k.line * 0.9)
                    k.cel(circ(64, 68, 2.6), bow, k.line * 0.9)
                }
            default:
                break
            }
            if f.mood != .sleepy && (f.frameIndex % 8 == 2 || f.frameIndex % 8 == 3) {
                let p = ends[(f.frameIndex / 8) % 6 + 1]
                let r: CGFloat = f.frameIndex % 8 == 2 ? 5 : 7.5
                k.fill(star(p.x + 3, p.y + 3, r, points: 4, inner: 0.28), t.line)
                k.fill(star(p.x + 3, p.y + 3, r * 0.72, points: 4, inner: 0.28), .white)
            }
            k.marks(80, 82, 13, edge: t.line)
        }
    }

    static func robin(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0x9c6a44), Tone(0xf26a36), Tone(0x6a3a1a)),
            (Tone(0x4f8ae6), Tone(0xf59a46), Tone(0x2a5ac0)),
            (Tone(0xe2443c), Tone(0xf6a07a), Tone(0x8a2a1a)),
            (Tone(0xa8744a), Tone(0xf27040), Tone(0x6a3a1a)),
            (Tone(0x8a86c0), Tone(0xf06a5a), Tone(0x4a3a9a)),
        ]
        let v = f.pick(looks)
        let body = MascotTones(v.0)
        let breast = MascotTones(v.1)
        let beak = MascotTones(Tone(0xffb43a), shade: Tone(0xe8861a), line: body.line)
        let b = k.bounce()
        let hopArc: CGFloat = f.airborne ? sin(f.air * .pi) : 0
        let flap: CGFloat = f.airborne ? sin(f.air * .pi * 4) : 0
        var tilt: CGFloat = 0, look: CGFloat = 0.16, open: CGFloat = 4, puff: CGFloat = 1
        var wing: CGFloat = 0.9 * flap + 0.2 * hopArc, tail: CGFloat = 0.12 * f.twitch
        var legs: CGFloat = 1
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            open = 0
            puff = 1.04
            wing = 0
            legs = 0.5
            tilt = -0.06
        case .startled:
            open = 7
            puff = 1.06
            wing = 1.3 + 0.15 * f.swing2
            tail = 0.4
        case .fleeing:
            look = 0.34
            open = 5
            wing = 0.9 + 0.7 * sin(f.t * 2)
            tail = 0.3
        case .dizzy:
            tilt = 0.12 * sin(f.t)
            open = 1.5
            wing = 0.4 * f.swing
        }
        let tuck: CGFloat = 4 * hopArc
        k.with(about(50, 30, rot: tilt).concatenating(about(50, 0, sx: b.sx * puff, sy: b.sy * puff))) {
            let leg = Tone(0xe8861a), legLine = body.line
            for x in [44, 55] as [CGFloat] {
                let top: CGFloat = 20
                let footY: CGFloat = 4 + (18 - 14 * legs) * 0.5 + tuck
                let p = CGMutablePath()
                p.move(to: pt(x, top))
                p.addLine(to: pt(x - tuck * 0.5, footY))
                p.move(to: pt(x - tuck * 0.5 - 2, footY))
                p.addLine(to: pt(x - tuck * 0.5 + 5, footY))
                p.move(to: pt(x - tuck * 0.5, footY))
                p.addLine(to: pt(x - tuck * 0.5 + 4, footY + 2.5))
                mascotWoodlandTwig(k, p, leg, legLine, k.line * 0.85)
            }
            k.with(about(24, 42, rot: -tail)) {
                k.cel(smooth([26, 44, 10, 52, 2, 62, 8, 64, 15, 60, 26, 52], t: 0.8), body, k.line, k: 0.15)
            }
            let ball = circ(48, 46, 30)
            k.cel(ball, body, k.bold, k: 0.12)
            k.clip(ball) {
                k.cel(ell(68, 31, 23, 21, -0.3), breast, k.line, k: 0.12)
            }
            k.stroke(ball, body.line, k.bold)
            k.with(about(42, 46, rot: wing)) {
                k.cel(smooth([44, 48, 30, 50, 17, 38, 20, 27, 33, 30], t: 0.85), MascotTones(v.0.dim(0.86)), k.line, k: 0.15)
            }
            robinTuft(f, k, body)
            k.eye(57, 55, 7.6, 10.3, iris: v.2, edge: body.line, lid: body.base, side: -1, look: look)
            k.eye(72, 55.5, 6.3, 9.6, iris: v.2, edge: body.line, lid: body.base, side: 1, look: look)
            k.brow(56, 70.5, 9, side: -1, edge: body.line)
            k.brow(72.5, 70, 7.5, side: 1, edge: body.line)
            k.blush(58, 41, 4.2, 2.5)
            let inner = poly([76, 44.5, 89, 44.5, 86, 42 - open, 76, 40 - open * 0.3])
            if open > 0.5 {
                k.fill(inner, k.mouthTone)
                k.fill(ell(81, 41.5 - open * 0.6, 3, 1.6), k.tongue)
            }
            k.cel(smooth([76, 42 - open * 0.25, 87, 41.5 - open, 77, 37.5 - open * 0.45], t: 0.6), beak, k.line * 0.9)
            k.cel(smooth([75, 49.5, 93, 45, 76, 42], t: 0.6), beak, k.line * 0.9)
            robinProp(f, k)
            k.marks(84, 82, 13, edge: body.line)
        }
    }

    private static func robinTuft(_ f: FigureFrame, _ k: MascotKit, _ body: MascotTones) {
        let up: CGFloat = f.mood == .startled ? 0.35 : 0
        k.with(about(48, 74, rot: 0.15 * f.twitch - up)) {
            if f.variant % 5 == 2 {
                k.cel(smooth([38, 72, 34, 92, 46, 84, 58, 74], t: 0.6), body, k.line, k: 0.15)
            } else if f.variant % 5 != 3 {
                k.cel(smooth([44, 74, 42, 84, 50, 80, 54, 74], t: 0.6), body, k.line * 0.9, k: 0.15)
            }
        }
    }

    private static func robinProp(_ f: FigureFrame, _ k: MascotKit) {
        switch f.variant % 5 {
        case 3:
            let up: CGFloat = f.mood == .startled ? 5 : 0
            k.with(CGAffineTransform(translationX: 0, y: up).concatenating(about(46, 72, rot: 0.16 + 0.05 * f.twitch))) {
                mascotWoodlandBeanie(k, 46, 72, 40, MascotTones(Tone(0x3fb86a)), cuff: MascotTones(Tone(0xfdfbf6), shade: Tone(0xc8d8ee)), pom: MascotTones(Tone(0xf6c13a)))
            }
        case 4:
            k.with(about(50, 78, rot: 0.15 * f.twitch)) {
                mascotWoodlandFlower(k, 42, 80, 4.6, 3.6, 0.3, Tone(0xff7ab8), Tone(0x7a1a4a))
            }
        default:
            break
        }
    }

    static func cloud(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(Tone, Tone, Tone, Tone)] = [
            (Tone(0xf8faff), Tone(0xbfcaf0), Tone(0x3a4a8a), Tone(0x3a7ae0)),
            (Tone(0xc6d3ee), Tone(0x8fa2cc), Tone(0x24345e), Tone(0x3a5ac0)),
            (Tone(0xffe0ec), Tone(0xf2a6c6), Tone(0x8a2e5e), Tone(0xd0408a)),
            (Tone(0xf8faff), Tone(0xbfcaf0), Tone(0x3a4a8a), Tone(0x2a9a6a)),
            (Tone(0xe8e2ff), Tone(0xb4a6ec), Tone(0x4a3a9a), Tone(0x7a4fe0)),
        ]
        let v = f.pick(looks)
        let t = MascotTones(v.0, shade: v.1, line: v.2)
        var tilt: CGFloat = 0, faceX: CGFloat = 0, sy: CGFloat = 1, puff: CGFloat = 1
        var armL: CGFloat = 1.9 + 0.2 * sin(f.t), armR: CGFloat = 1.9 - 0.2 * sin(f.t)
        switch f.mood {
        case .calm:
            armR += 0.7 * max(0, f.twitch)
        case .sleepy:
            sy = 0.9
            armL = 0.6
            armR = 0.6
        case .startled:
            sy = 1.08
            puff = 1.07
            armL = 2.6
            armR = 2.6
        case .fleeing:
            faceX = 3
            armL = 2.2 + 0.3 * f.swing
            armR = 1.2 - 0.3 * f.swing
        case .dizzy:
            tilt = 0.12 * sin(f.t)
            armL = 1.4 + 0.5 * f.swing
            armR = 1.4 - 0.5 * f.swing
        }
        k.with(about(50, 40, rot: tilt).concatenating(about(50, 30, sx: 1 / sy.squareRoot(), sy: sy))) {
            if f.variant % 5 == 3 {
                let cols: [Tone] = [Tone(0xff5a5a), Tone(0xffc93a), Tone(0x5ac86a), Tone(0x4a8ae8)]
                let band = CGMutablePath()
                band.addArc(center: pt(50, 36), radius: 50.5, startAngle: 0.25, endAngle: .pi - 0.25, clockwise: false)
                k.stroke(band, t.line, 4 * 5.2 + k.line * 2)
                for (i, c) in cols.enumerated() {
                    let r: CGFloat = 58 - CGFloat(i) * 5
                    let p = CGMutablePath()
                    p.addArc(center: pt(50, 36), radius: r, startAngle: 0.25, endAngle: .pi - 0.25, clockwise: false)
                    k.stroke(p, c, 5.4)
                }
            }
            if f.mood == .fleeing {
                k.cel(circ(4, 38 + 2 * f.swing, 6), t, k.line, k: 0.2)
                k.cel(circ(-8, 42 - 2 * f.swing, 4), t, k.line * 0.9, k: 0.2)
            }
            let base = cloudShapes[(f.frameIndex / 2) % cloudShapes.count]
            let shape = puff == 1 ? base : xf(base, about(50, 40, sx: puff, sy: puff))
            k.cel(shape, t, k.bold, k: 0.1)
            k.fill(ell(40, 70, 6, 3.2, 0.3), Tone.white.alpha(0.7))
            mascotWoodlandLimb(k, 13, 34, -armL, 13, 3.6, t)
            mascotWoodlandLimb(k, 87, 34, armR, 13, 3.6, t)
            mascotWoodlandFace(f, k, 50 + faceX, 45, spread: 10, rx: 7.6, ry: 9.6, iris: v.3, edge: t.line, lid: t.base, mouthY: 32.5, mouthW: 11, mouthH: 7, blushX: 19.5, blushY: 35)
            switch f.variant % 5 {
            case 1:
                for i in 0..<3 {
                    let u = (f.phase * 2 + CGFloat(i) * 0.37).truncatingRemainder(dividingBy: 1)
                    let x: CGFloat = 32 + CGFloat(i) * 17
                    let y: CGFloat = 16 - u * 16
                    k.cel(drop(x, y, 2.8), MascotTones(Tone(0x8fd4ff), shade: Tone(0x5aa8e8), line: Tone(0x1a3a7a)), k.line * 0.8, k: 0.2)
                }
            case 4:
                for i in 0..<3 {
                    let u = (f.phase + CGFloat(i) * 0.37).truncatingRemainder(dividingBy: 1)
                    let x: CGFloat = 32 + CGFloat(i) * 17 + 2 * sin(f.t + CGFloat(i))
                    let y: CGFloat = 16 - u * 16
                    let s = star(x, y, 5.6, points: 6, inner: 0.45, spin: f.t)
                    k.fill(s, t.line)
                    k.fill(star(x, y, 3.9, points: 6, inner: 0.5, spin: f.t), .white)
                }
            case 2:
                k.fill(star(78, 68, 5.5, points: 4, inner: 0.3), t.line)
                k.fill(star(78, 68, 4, points: 4, inner: 0.3), Tone(0xfff2a0))
            default:
                break
            }
            k.marks(84, 72, 13, edge: t.line)
        }
    }

    static func owl(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, Tone, Tone)] = [
            (MascotTones(Tone(0xb07a4c)), Tone(0xfbe3c0), Tone(0xe08a10)),
            (MascotTones(Tone(0xf2f3fb), shade: Tone(0xbcc4e6), line: Tone(0x34407a)), Tone(0xffffff), Tone(0xd8a010)),
            (MascotTones(Tone(0x8f97b8)), Tone(0xe8ecf8), Tone(0xe07a10)),
            (MascotTones(Tone(0xd2763e)), Tone(0xffe4c4), Tone(0xb05a10)),
            (MascotTones(Tone(0x8f6ec8)), Tone(0xeadfff), Tone(0xd89a10)),
        ]
        let v = f.pick(looks)
        let body = v.0
        let disc = MascotTones(v.1, shade: v.1.mix(body.shade, 0.35), line: body.line)
        let orange = MascotTones(Tone(0xffa62e), shade: Tone(0xe27a10), line: body.line)
        let b = k.bounce()
        let hopArc: CGFloat = f.airborne ? sin(f.air * .pi) : 0
        let flap: CGFloat = f.airborne ? sin(f.air * .pi * 3) : 0
        var tilt: CGFloat = 0, faceX: CGFloat = 0, tufts: CGFloat = 0.1 * f.twitch
        var wL: CGFloat = 0.25 + 1.2 * hopArc + 0.5 * flap, wR: CGFloat = 0.25 + 1.2 * hopArc + 0.5 * flap
        var hatUp: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            wL = 0.08
            wR = 0.08
            tufts = -0.25
        case .startled:
            wL = 2.2
            wR = 2.2
            tufts = 0.3
            hatUp = 5
        case .fleeing:
            faceX = 3
            wL = 1.6 + 0.6 * sin(f.t * 2)
            wR = 1.6 - 0.6 * sin(f.t * 2)
            tufts = 0.35
        case .dizzy:
            tilt = 0.12 * sin(f.t)
            wL = 0.8 + 0.5 * f.swing
            wR = 0.8 - 0.5 * f.swing
            tufts = 0.2 * f.swing
        }
        let tuck: CGFloat = 3 * hopArc
        k.with(about(50, 30, rot: tilt).concatenating(about(50, 0, sx: b.sx, sy: b.sy))) {
            for x in [41, 59] as [CGFloat] {
                k.cel(ell(x, 5 + tuck, 6, 3.2), orange, k.line * 0.9)
                let toes = CGMutablePath()
                for d in [-3, 0, 3] as [CGFloat] {
                    toes.addPath(circ(x + d, 3.6 + tuck, 1.3))
                }
                k.fill(toes, body.line)
            }
            mascotWoodlandLimb(k, 22, 52, -wL, 28, 7, MascotTones(body.base.dim(0.88), line: body.line))
            mascotWoodlandLimb(k, 78, 52, wR, 28, 7, MascotTones(body.base.dim(0.88), line: body.line))
            k.both { s in
                k.with(about(50 + s * 22, 82, rot: -s * tufts)) {
                    let tp: [CGFloat] = [24, 80, 16, 99, 38, 86]
                    k.cel(smooth(s < 0 ? tp : mirrorA(tp), t: 0.6), body, k.line, k: 0.15)
                }
            }
            let shape = smooth([50, 90, 74, 86, 85, 64, 83, 36, 71, 12, 50, 6, 29, 12, 17, 36, 15, 64, 26, 86])
            k.cel(shape, body, k.bold, k: 0.12)
            let belly = ell(50, 25, 20, 16)
            k.cel(belly, disc, k.line, k: 0.15)
            for (x, y) in [(43, 28), (57, 28), (50, 20)] as [(CGFloat, CGFloat)] {
                k.stroke(poly([x - 3.5, y + 1.8, x, y - 1.2, x + 3.5, y + 1.8], closed: false), disc.shade.mix(body.line, 0.4), k.line * 0.8)
            }
            let fx = 50 + faceX
            owlHat(f, k, hatUp)
            k.cel(moved(owlDiscShape, faceX, 0), disc, k.line, k: 0.1)
            mascotWoodlandFace(f, k, fx, 58, spread: 12.5, rx: 9.4, ry: 11, iris: v.2, edge: body.line, lid: disc.base, mouthY: 42.5, mouthW: 10, mouthH: 6.5, blushX: 24, blushY: 46)
            k.cel(smooth([fx - 5, 50, fx + 5, 50, fx, 41.5], t: 0.5), orange, k.line * 0.9)
            if f.variant % 5 == 2 {
                let bow = MascotTones(Tone(0xff4d7a), line: Tone(0x6a1430))
                k.with(about(66, 85, rot: -0.25 + 0.1 * f.twitch)) {
                    k.cel(smooth([66, 85, 54, 93, 54, 78], t: 0.5), bow, k.line * 0.9)
                    k.cel(smooth([66, 85, 78, 93, 78, 78], t: 0.5), bow, k.line * 0.9)
                    k.cel(circ(66, 85, 3.4), bow, k.line * 0.9)
                }
            }
            k.marks(84, 86, 13, edge: body.line)
        }
    }

    private static func owlHat(_ f: FigureFrame, _ k: MascotKit, _ up: CGFloat) {
        switch f.variant % 5 {
        case 3:
            let cap = MascotTones(Tone(0x4a5080), shade: Tone(0x32365c), line: Tone(0x14162e))
            k.with(CGAffineTransform(translationX: 0, y: up).concatenating(about(50, 90, rot: -0.1))) {
                k.cel(rrect(38, 82, 24, 9, 2), cap, k.line, k: 0.15)
                k.cel(poly([50, 98, 74, 92, 50, 86, 26, 92]), cap, k.line, k: 0.15)
                let swing: CGFloat = 2 * f.swing + 2 * f.twitch
                k.stroke(smooth([50, 92, 66, 91, 70 + swing * 0.3, 82], closed: false), Tone(0xffc93a), k.line * 1.1)
                k.fill(circ(70 + swing * 0.3, 81, 2.4), Tone(0xffc93a))
            }
        case 4:
            let cap = MascotTones(Tone(0x4a8ae8))
            k.with(CGAffineTransform(translationX: 0, y: up).concatenating(about(50, 86, rot: 0.05 * f.twitch))) {
                k.cel(smooth([27, 85, 36, 97, 56, 103, 76, 99, 88, 84, 74, 91, 62, 90, 72, 84], t: 0.7), cap, k.line, k: 0.15)
                k.cel(circ(89, 81, 4.5), MascotTones(Tone(0xfdfbf6), shade: Tone(0xc8d8ee)), k.line * 0.9)
                k.cel(rrect(26, 81, 48, 7, 3.5), MascotTones(Tone(0xfdfbf6), shade: Tone(0xc8d8ee)), k.line, k: 0.2)
            }
        default:
            break
        }
    }
}
