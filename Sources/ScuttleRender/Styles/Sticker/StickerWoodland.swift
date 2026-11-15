import Foundation
import CoreGraphics
import ScuttleCore

extension StickerArt {
    static func hedgehog(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0x9a6240), Tone(0xf7cf9d)), (Tone(0x7a4a34), Tone(0xf3c08a)), (Tone(0xb57c48), Tone(0xffe2b8)),
            (Tone(0x6e5a56), Tone(0xf2d4b4)), (Tone(0xa0603a), Tone(0xfad4a8)),
        ]
        let (back, face) = f.pick(looks)
        let foot = back.dim(0.62)
        let e = min(f.energy, 1.3)
        var sx: CGFloat = 1, sy: CGFloat = 1, rot: CGFloat = 0
        var trx: CGFloat = 43, tr: CGFloat = 35, sweep: CGFloat = 0
        var headRot: CGFloat = 0, headLift: CGFloat = 0, headX: CGFloat = 0, look: CGFloat = 0
        var reach: CGFloat = 5
        switch f.mood {
        case .calm:
            headLift = 0.8 * max(0, f.twitch)
            headRot = 0.05 * max(0, f.twitch)
        case .sleepy:
            sx = 1.04
            sy = 0.88
            trx = 39
            tr = 29
            sweep = 0.14
            headRot = -0.14
            headLift = -2
            reach = 1.5
        case .startled:
            sx = 0.97
            sy = 1.05
            trx = 49
            tr = 42
            headRot = 0.1
            headLift = 2.5
        case .fleeing:
            trx = 46
            tr = 33
            sweep = 0.34
            look = 1
            headX = 2.5
            headRot = -0.05
            reach = 6.5
        case .dizzy:
            rot = 0.12 * sin(f.t)
        }
        let st = f.swing * reach * e
        let la = max(0, f.sway) * 3 * e
        let lb = max(0, -f.sway) * 3 * e
        let bob = f.bounce * 1.2 * e
        k.with(about(50, 4, rot: rot)) {
            k.flat(ell(58 - st, 7 + lb, 8, 5), foot)
            k.flat(ell(34 + st, 8 + la, 8, 5), foot)
            k.with(about(50, 6, sx: sx, sy: sy).translatedBy(x: 0, y: bob)) {
                let body = hedgehogBack(trx: trx, tr: tr, sweep: sweep)
                k.part(body, back, shadow: back.dim(0.74), shape: ell(36, 8, 38, 14))
                hedgehogBackProp(f, k)
                k.with(about(56, 24, rot: headRot).translatedBy(x: headX, y: headLift)) {
                    if f.variant % 5 != 3 {
                        k.flat(circ(61 - 1.2 * max(0, f.twitch), 50 + 1.2 * max(0, f.twitch), 6.5), face)
                        k.fill(circ(61, 51, 3), Tone(0xff9fb0))
                    }
                    let snout = smooth([54, 12, 68, 10, 82, 13, 92, 20, 96, 27, 91, 33, 80, 42, 66, 48, 54, 44, 48, 30])
                    k.part(snout, face, shadow: face.dim(0.86), shape: ell(72, 6, 30, 9))
                    let ny: CGFloat = 27.5 + 0.9 * f.twitch
                    k.fill(circ(95, ny, 4.8), k.ink)
                    k.gloss(96.4, ny + 1.6, 1.6, 1.1, 0.3)
                    k.eye(73.5, 33, 5.6, 7.4, side: 1, look: look)
                    k.blush(82, 21.5, 4.4, 2.6)
                    k.mouth(86.5, 18.5, 7)
                    if f.variant % 5 == 3 { hedgehogHat(k) }
                }
                k.marks(84, 56, 13)
            }
        }
    }

    private static func hedgehogBack(trx: CGFloat, tr: CGFloat, sweep: CGFloat) -> CGPath {
        var pts: [CGPoint] = []
        let n = 9
        let a0: CGFloat = 0.28 * .pi, a1: CGFloat = 1.18 * .pi
        for i in 0...(2 * n) {
            let u = CGFloat(i) / CGFloat(2 * n)
            let tip = i % 2 == 1
            let a = a0 + (a1 - a0) * u + (tip ? sweep : 0)
            pts.append(pt(45 + cos(a) * (tip ? trx : 31), 30 + sin(a) * (tip ? tr : 23)))
        }
        pts.append(pt(28, 10))
        pts.append(pt(56, 9))
        return polyP(pts)
    }

    private static func hedgehogBackProp(_ f: FigureFrame, _ k: StickerKit) {
        switch f.variant % 5 {
        case 1:
            k.stroke(arc(40, 64, 43, 70, dip: -1), k.ink, k.line * 1.6)
            k.flat(ell(47, 69, 5, 2.6, 0.5), Tone(0x6cc04a))
            cloudMerge(k, [circ(36.5, 58, 7.2), circ(43.5, 58, 7.2)], Tone(0xf0443a), shadow: Tone(0xc8302a), shape: ell(50, 52, 7, 9))
            k.gloss(35, 61, 1.6, 2.6, -0.4)
        case 2:
            let leaf = smooth([22, 50, 30, 62, 42, 66, 38, 56], t: 0.6)
            k.part(leaf, Tone(0xff8a2a))
            k.stroke(line(24, 52, 38, 62), Tone(0xc85a14), k.thin * 0.8)
        case 4:
            acornFlower(k, 40, 62, 8.5)
        default:
            break
        }
    }

    private static func hedgehogHat(_ k: StickerKit) {
        let red = Tone(0xe84a4a)
        k.with(about(64, 46, rot: -0.35)) {
            let dome = CGMutablePath()
            dome.addArc(center: pt(64, 46), radius: 10.5, startAngle: 0, endAngle: .pi, clockwise: false)
            dome.closeSubpath()
            k.part(dome, red)
            k.flat(rrect(52, 42.5, 24, 6.5, 3.2), Tone(0xfdf6ee))
            k.flat(circ(64, 58.5, 4), Tone(0xfdf6ee))
        }
    }

    static func acorn(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xe0a060), Tone(0x8a5a34)), (Tone(0xeeb850), Tone(0x9a6a3a)), (Tone(0xd08850), Tone(0x7a4a2c)),
            (Tone(0xc06a3c), Tone(0x6a4430)), (Tone(0xe8b070), Tone(0x8a5a34)),
        ]
        let (nut, cap) = f.pick(looks)
        let foot = cap.dim(0.85)
        let sq = f.squat, stp = f.stretch
        var sx: CGFloat = 1 + 0.1 * sq - 0.05 * stp
        var sy: CGFloat = 1 - 0.16 * sq + 0.1 * stp
        var rot: CGFloat = 0, capDy: CGFloat = 0, capRot: CGFloat = 0, look: CGFloat = 0
        var armL: CGFloat = 0.3, armR: CGFloat = -0.3
        let tuck: CGFloat = f.airborne ? 2.5 * sin(f.air * .pi) : 0
        let flap = f.airborne ? 0.5 * sin(f.air * .pi) : 0
        armL += flap
        armR -= flap
        switch f.mood {
        case .calm:
            capRot = -0.06 * f.twitch
        case .sleepy:
            sx *= 1.05
            sy *= 0.9
            capDy = -4
            capRot = -0.1
            armL = -0.2
            armR = 0.2
        case .startled:
            sy *= 1.05
            capDy = 6 + 1.5 * f.swing2
            capRot = 0.12
            armL = 2.2
            armR = -2.2
        case .fleeing:
            capRot = 0.2
            look = 1
            armL = 1.2 + 0.4 * f.swing2
            armR = 1.6 + 0.4 * f.swing2
        case .dizzy:
            rot = 0.12 * sin(f.t)
            capRot = 0.18 * sin(f.t + 1)
        }
        k.with(about(50, 4, rot: rot)) {
            k.flat(ell(41, 7 + tuck, 6.5, 3.8), foot)
            k.flat(ell(59, 7 + tuck, 6.5, 3.8), foot)
            k.with(about(50, 4, sx: sx, sy: sy)) {
                k.with(about(27, 32, rot: armL)) { k.flat(ell(21, 30, 6.5, 4), nut) }
                k.with(about(73, 32, rot: armR)) { k.flat(ell(79, 30, 6.5, 4), nut) }
                let body = smooth([50, 9, 64, 13, 74, 26, 76, 44, 66, 54, 34, 54, 24, 44, 26, 26, 36, 13])
                k.part(body, nut, shadow: nut.dim(0.8), shape: ell(84, 26, 20, 34))
                k.gloss(32, 40, 2.4, 4.5, -0.3)
                k.face(53 + look * 2.5, 32, spread: 7.5, rx: 4.3, ry: 5.7, look: look)
                k.with(about(50, 50, rot: capRot).translatedBy(x: 0, y: capDy)) {
                    acornCap(f, k, cap)
                }
                k.marks(80, 68, 12)
            }
        }
    }

    private static func acornCap(_ f: FigureFrame, _ k: StickerKit, _ cap: Tone) {
        let v = f.variant % 5
        let stem = smooth([48, 72, 51, 72, 53, 84, 49, 84], t: 0.6)
        k.flat(stem, cap.dim(0.8))
        if v == 1 || v == 3 {
            let tone = v == 1 ? Tone(0x6cc04a) : Tone(0xff8a2a)
            let leaf = smooth([52, 82, 60, 90, 72, 90, 64, 82], t: 0.6)
            k.part(leaf, tone)
            k.stroke(line(53, 83, 68, 88), tone.dim(0.7), k.thin * 0.8)
        }
        let p = CGMutablePath()
        p.move(to: pt(20, 52))
        p.addCurve(to: pt(50, 78), control1: pt(20, 66), control2: pt(34, 78))
        p.addCurve(to: pt(80, 52), control1: pt(66, 78), control2: pt(80, 66))
        let n = 5
        for i in 0..<n {
            let x0 = 80 - CGFloat(i) * 12
            p.addQuadCurve(to: pt(x0 - 12, 52), control: pt(x0 - 6, 45))
        }
        p.closeSubpath()
        k.part(p, cap, shadow: cap.dim(0.78), shape: ell(86, 52, 18, 30))
        k.clip(p) {
            for x in stride(from: CGFloat(30), through: 70, by: 10) {
                k.stroke(arc(x - 5, 62, x + 5, 62, dip: 3), cap.lift(0.18), k.thin * 0.8)
            }
        }
        switch v {
        case 2:
            acornFlower(k, 36, 71, 8.5)
        case 4:
            let blue = Tone(0x4aa0f0)
            k.part(smooth([62, 72, 51, 79, 51, 65], t: 0.4), blue)
            k.part(smooth([62, 72, 73, 79, 73, 65], t: 0.4), blue)
            k.flat(circ(62, 72, 3), blue.dim(0.85))
        default:
            break
        }
    }

    private static func acornFlower(_ k: StickerKit, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat) {
        var petals: [CGPath] = []
        for i in 0..<5 {
            let a = 0.3 + CGFloat(i) * 2 * .pi / 5
            petals.append(circ(x + cos(a) * r * 0.52, y + sin(a) * r * 0.52, r * 0.5))
        }
        cloudMerge(k, petals, Tone(0xff8fbc), shadow: Tone(0xf06aa0), shape: ell(x + r * 1.1, y - r * 0.5, r * 0.6, r))
        k.flat(circ(x, y, r * 0.36), Tone(0xffd54a), w: k.thin)
    }

    static func toadstool(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xf0443a), Tone(0xffffff)), (Tone(0x9a5ad8), Tone(0xffe066)), (Tone(0xb0703c), Tone(0xf3d9a8)),
            (Tone(0x3f8ee8), Tone(0xffffff)), (Tone(0xff8a2a), Tone(0xfff3c4)),
        ]
        let (capTone, spot) = f.pick(looks)
        let stemTone = Tone(0xfbeedb)
        let e = min(f.energy, 1.3)
        var sx: CGFloat = 1, sy: CGFloat = 1, rot: CGFloat = 0
        var capDy: CGFloat = 0, capRot: CGFloat = -0.04 * f.swing, look: CGFloat = 0
        var armL: CGFloat = 0.2 * f.swing, armR: CGFloat = -0.2 * f.swing
        var reach: CGFloat = 4.5
        switch f.mood {
        case .calm:
            capRot += -0.07 * f.twitch
        case .sleepy:
            sy = 0.92
            sx = 1.04
            capDy = -5
            capRot = -0.14
            armL = -0.3
            armR = 0.3
            reach = 1.5
        case .startled:
            sy = 1.06
            capDy = 6 + 1.2 * f.swing2
            capRot = 0.08
            armL = 2.3
            armR = -2.3
        case .fleeing:
            capRot = 0.2
            look = 1
            armL = 1.3 + 0.4 * f.swing
            armR = 1.7 - 0.4 * f.swing
            reach = 6
        case .dizzy:
            rot = 0.12 * sin(f.t)
            capRot = 0.15 * sin(f.t + 1.2)
        }
        let st = f.swing * reach * e
        let la = max(0, f.sway) * 3 * e
        let lb = max(0, -f.sway) * 3 * e
        let bob = f.bounce * 1.5 * e
        k.with(about(50, 4, rot: rot)) {
            k.flat(ell(59 - st, 7 + lb, 7.5, 4.2), stemTone.dim(0.78))
            k.flat(ell(41 + st, 7 + la, 7.5, 4.2), stemTone.dim(0.78))
            k.with(about(50, 6, sx: sx, sy: sy).translatedBy(x: 0, y: bob)) {
                k.with(about(33, 32, rot: armL)) { k.flat(ell(27, 28, 4, 7.5, -0.3), stemTone) }
                k.with(about(67, 32, rot: armR)) { k.flat(ell(73, 28, 4, 7.5, 0.3), stemTone) }
                let stem = smooth([36, 9, 64, 9, 68, 28, 63, 50, 37, 50, 32, 28])
                k.part(stem, stemTone, shadow: Tone(0xe6cfae), shape: ell(76, 26, 14, 30))
                if f.variant % 5 == 3 {
                    let red = Tone(0xff4f6d)
                    k.part(smooth([50, 16, 42, 20, 42, 12], t: 0.4), red)
                    k.part(smooth([50, 16, 58, 20, 58, 12], t: 0.4), red)
                    k.flat(circ(50, 16, 2.4), red.dim(0.85))
                }
                k.face(52 + look * 2.5, 33, spread: 7, rx: 4, ry: 5.4, look: look)
                k.with(about(50, 46, rot: capRot).translatedBy(x: 0, y: capDy)) {
                    toadstoolCap(f, k, capTone, spot)
                }
                k.marks(80, 74, 12)
            }
        }
    }

    private static func toadstoolCap(_ f: FigureFrame, _ k: StickerKit, _ tone: Tone, _ spot: Tone) {
        let v = f.variant % 5
        let cap = smooth([12, 50, 20, 74, 50, 90, 80, 74, 88, 50, 72, 43, 50, 41, 28, 43])
        k.part(cap, tone, shadow: tone.dim(0.8), shape: ell(84, 42, 22, 22))
        if v != 2 {
            k.clip(cap) {
                for s in [(32.0, 70.0, 6.5), (55.0, 80.0, 5.0), (70.0, 62.0, 6.5), (46.0, 58.0, 4.2), (20.0, 54.0, 3.6)] as [(CGFloat, CGFloat, CGFloat)] {
                    k.fs(circ(s.0, s.1, s.2), spot, k.ink, k.thin)
                }
            }
            k.stroke(cap, k.ink, k.line)
        }
        k.gloss(30, 78, 2.2, 4, -0.8)
        switch v {
        case 2:
            let leaf = smooth([54, 88, 62, 98, 74, 100, 66, 90], t: 0.6)
            k.part(leaf, Tone(0x6cc04a))
            k.stroke(line(56, 89, 70, 97), Tone(0x3f8a2e), k.thin * 0.8)
        case 4:
            k.stroke(line(50, 89, 52, 96), k.ink, k.line * 1.4)
            acornFlower(k, 53, 99, 8)
        default:
            break
        }
    }

    static func leaf(_ f: FigureFrame, _ k: StickerKit) {
        let v = f.variant % 5
        let tones: [Tone] = [Tone(0xff8a2a), Tone(0xf0443a), Tone(0xffc93c), Tone(0x6cc04a), Tone(0xc0783a)]
        let base = tones[v]
        var sx: CGFloat = 1 - 0.1 * (0.5 - 0.5 * cos(2 * f.t))
        var sy: CGFloat = 1, rot: CGFloat = 0.06 * f.swing, shear: CGFloat = 0, look: CGFloat = 0
        var stemWag: CGFloat = 2 * f.twitch + 1.5 * f.swing
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sy = 0.9
            sx *= 1.03
            rot = -0.22 + 0.03 * f.swing
            stemWag = 0
        case .startled:
            sx *= 1.07
            sy = 1.08
            rot = 0.04 * f.swing2
        case .fleeing:
            shear = -0.28
            sx *= 0.94
            look = 1
            stemWag = -5
        case .dizzy:
            rot = 0.14 * sin(f.t)
        }
        var t = about(50, 50, rot: rot, sx: sx, sy: sy)
        if shear != 0 {
            t = CGAffineTransform(a: 1, b: 0, c: shear, d: 1, tx: -shear * 50, ty: 0).concatenating(t)
        }
        k.with(t) {
            let stem = smooth([50, 34, 50, 24, 53 + stemWag * 0.5, 16, 60 + stemWag, 12], closed: false)
            k.stroke(stem, k.ink, k.line * 2 + 3)
            k.stroke(stem, base.dim(0.62), 3)
            let shape: CGPath
            switch v {
            case 2: shape = smooth([50, 93, 66, 80, 73, 60, 66, 38, 50, 26, 34, 38, 27, 60, 34, 80], t: 0.9)
            case 4: shape = smooth([50, 93, 60, 86, 72, 82, 68, 71, 79, 63, 70, 54, 77, 43, 64, 39, 61, 29, 50, 25, 39, 29, 36, 39, 23, 43, 30, 54, 21, 63, 32, 71, 28, 82, 40, 86], t: 0.9)
            default: shape = smooth([50, 97, 57, 86, 64, 89, 62, 77, 73, 81, 82, 85, 80, 72, 93, 64, 83, 58, 86, 49, 73, 50, 75, 40, 61, 44, 53, 31, 47, 31, 39, 44, 25, 40, 27, 50, 14, 49, 17, 58, 7, 64, 20, 72, 18, 85, 27, 81, 38, 77, 36, 89, 43, 86], t: 0.55)
            }
            k.part(shape, base, shadow: base.dim(0.8), shape: ell(86, 34, 30, 42))
            let veins = CGMutablePath()
            veins.move(to: pt(50, 32))
            veins.addLine(to: pt(50, 42))
            veins.move(to: pt(50, 36))
            veins.addLine(to: pt(38, 44))
            veins.move(to: pt(50, 36))
            veins.addLine(to: pt(62, 44))
            k.stroke(veins, base.dim(0.66), k.thin)
            k.gloss(34, 70, 2.4, 4.4, -0.6)
            k.face(51 + look * 2.5, 60, spread: 8, rx: 5, ry: 6.4, look: look)
            switch v {
            case 1:
                let bug = circ(73, 67, 5.2)
                k.flat(circ(77.5, 70, 2.8), k.ink)
                k.flat(bug, Tone(0xf0443a).lift(0.15))
                k.stroke(line(73, 62, 73, 72), k.ink, k.thin * 0.8)
                k.fill(circ(70.5, 66, 1.3), k.ink)
                k.fill(circ(75.5, 65, 1.3), k.ink)
            case 3:
                k.flat(drop(72, 64, 4), Tone(0xaee4ff))
                k.gloss(70.8, 64.6, 1.1, 1.8, -0.2)
            default:
                break
            }
            k.marks(80, 88, 12)
        }
    }

    static func penguin(_ f: FigureFrame, _ k: StickerKit) {
        let v = f.variant % 5
        let bodies: [Tone] = [Tone(0x3d4a6e), Tone(0x33526e), Tone(0x4a3f74), Tone(0x3d4a6e), Tone(0x2f5a62)]
        let body = bodies[v]
        let belly = Tone(0xfcf7ee), orange = Tone(0xffa22b)
        let e = min(f.energy, 1.3)
        var sx: CGFloat = 1, sy: CGFloat = 1, rot: CGFloat = 0, look: CGFloat = 0
        var aL: CGFloat = -0.35 - 0.12 * f.swing, aR: CGFloat = 0.35 - 0.12 * f.swing
        var beak: CGFloat = 0, trail: CGFloat = -0.1 + 0.1 * f.swing
        switch f.mood {
        case .calm:
            aR += 0.9 * max(0, f.twitch)
        case .sleepy:
            sy = 0.93
            sx = 1.04
            aL = -0.12
            aR = 0.12
        case .startled:
            sy = 1.06
            sx = 0.97
            aL = -2.3 - 0.1 * f.swing2
            aR = 2.3 + 0.1 * f.swing2
            beak = 3.5
        case .fleeing:
            aL = -1.5 + 0.35 * f.swing2
            aR = 1.0 + 0.4 * f.swing2
            look = 1
            beak = 2
            trail = -1.3 + 0.15 * f.swing2
        case .dizzy:
            rot = 0.12 * sin(f.t)
            aL = -0.6 + 0.5 * f.swing
            aR = 0.6 + 0.5 * f.swing
        }
        let la = max(0, f.swing) * 3 * e
        let lb = max(0, -f.swing) * 3 * e
        let bob = f.bounce * 1.2 * e
        let shift = 1.2 * f.swing * e
        k.with(about(50, 4, rot: rot)) {
            k.flat(ell(40 - shift * 0.5, 8 + la, 9, 4.6), orange)
            k.flat(ell(60 - shift * 0.5, 8 + lb, 9, 4.6), orange)
            k.with(about(50, 8, sx: sx, sy: sy).translatedBy(x: shift, y: bob)) {
                if v == 1 { penguinScarfTail(k, trail) }
                k.with(about(29, 53, rot: aL)) { k.flat(ell(26, 39, 6.5, 15), body) }
                k.with(about(71, 53, rot: aR)) { k.flat(ell(74, 39, 6.5, 15), body) }
                let b = smooth([50, 86, 66, 81, 76, 63, 78, 38, 72, 16, 50, 9, 28, 16, 22, 38, 24, 63, 34, 81])
                k.part(b, body, shadow: body.dim(0.72), shape: ell(88, 40, 20, 50))
                k.gloss(34, 74, 2.2, 4.2, -0.6)
                let fx = look * 2.5
                cloudMerge(k, [circ(41.5 + fx, 60, 11.2), circ(58.5 + fx, 60, 11.2), ell(50 + fx * 0.4, 33, 18.6, 21.6)], belly, shadow: Tone(0xe2dcef), shape: ell(76, 22, 16, 24))
                if v == 1 { penguinScarf(k) }
                if v == 4 { penguinBowTie(k, fx) }
                k.eye(43 + fx, 60.5, 4.7, 6.3, side: -1, look: look)
                k.eye(57 + fx, 60.5, 4.7, 6.3, side: 1, look: look)
                k.blush(35.5 + fx, 51, 3.6, 2.2)
                k.blush(64.5 + fx, 51, 3.6, 2.2)
                if beak > 0 {
                    k.flat(poly([44 + fx, 51 - beak * 0.3, 56 + fx, 51 - beak * 0.3, 50 + fx, 45 - beak]), orange.dim(0.85))
                    k.flat(poly([44 + fx, 54, 56 + fx, 54, 50 + fx, 50]), orange)
                } else if f.mood == .dizzy {
                    k.flat(poly([44 + fx, 53, 56 + fx, 53, 50 + fx + 1.5 * f.swing, 46.5]), orange)
                } else {
                    k.flat(poly([44 + fx, 53, 56 + fx, 53, 50 + fx, 46]), orange)
                }
                if v == 2 { penguinHat(k) }
                if v == 3 { penguinMuffs(k) }
                k.marks(74, 86, 13)
            }
        }
    }

    private static func penguinScarfTail(_ k: StickerKit, _ trail: CGFloat) {
        k.with(about(32, 44, rot: trail)) {
            k.part(rrect(27, 22, 9, 22, 3.5), Tone(0xe84a4a))
            k.stroke(line(28, 25, 35, 25), Tone(0xfdf6ee), k.thin)
        }
    }

    private static func penguinScarf(_ k: StickerKit) {
        let band = smooth([21, 46, 50, 42.5, 79, 46, 79, 38.5, 50, 35, 21, 38.5], t: 0.5)
        k.part(band, Tone(0xe84a4a), shadow: Tone(0xb83434), shape: ell(80, 36, 14, 6))
    }

    private static func penguinBowTie(_ k: StickerKit, _ fx: CGFloat) {
        let y: CGFloat = 40
        let c = Tone(0xffc93c)
        k.flat(poly([50 + fx, y, 41 + fx, y + 5, 41 + fx, y - 5]), c)
        k.flat(poly([50 + fx, y, 59 + fx, y + 5, 59 + fx, y - 5]), c)
        k.flat(circ(50 + fx, y, 2.4), c.dim(0.85))
    }

    private static func penguinHat(_ k: StickerKit) {
        let blue = Tone(0x4aa0f0)
        let dome = CGMutablePath()
        dome.addArc(center: pt(50, 77), radius: 17, startAngle: 0, endAngle: .pi, clockwise: false)
        dome.closeSubpath()
        k.part(dome, blue)
        k.clip(dome) { k.fill(rrect(30, 84, 40, 3.5, 0), Tone(0xfdf6ee)) }
        k.stroke(dome, k.ink, k.line)
        k.flat(rrect(31, 73, 38, 8, 4), Tone(0xfdf6ee))
        k.flat(circ(50, 96, 5), Tone(0xfdf6ee))
    }

    private static func penguinMuffs(_ k: StickerKit) {
        let band = arc(26, 66, 74, 66, dip: -30)
        k.stroke(band, k.ink, k.line * 2.6)
        k.stroke(band, Tone(0xff7fb0), k.line * 0.9)
        k.flat(circ(25, 64, 7), Tone(0xff7fb0))
        k.flat(circ(75, 64, 7), Tone(0xff7fb0))
        k.gloss(23, 66.5, 1.4, 2.4, -0.5)
    }

    static func snowman(_ f: FigureFrame, _ k: StickerKit) {
        let v = f.variant % 5
        let scarves: [Tone] = [Tone(0xe84a4a), Tone(0x4cb860), Tone(0xff7fb0), Tone(0x4a8ae8), Tone(0xffb02e)]
        let scarf = scarves[v]
        let snow = Tone(0xf8fbff), shade = Tone(0xc4d4f0), coal = Tone(0x3a3448)
        let e = min(f.energy, 1.3)
        var sx: CGFloat = 1, sy: CGFloat = 1, rot: CGFloat = 0, look: CGFloat = 0
        var headDy: CGFloat = 0, hatDy: CGFloat = 0, hatRot: CGFloat = 0.04 * f.swing
        var aL: CGFloat = .pi - 0.45 + 0.1 * f.swing, aR: CGFloat = 0.45 + 0.1 * f.swing
        var trail: CGFloat = -0.08 + 0.1 * f.swing
        switch f.mood {
        case .calm:
            aR += 0.6 * max(0, f.twitch)
        case .sleepy:
            sy = 0.95
            sx = 1.03
            headDy = -2.5
            hatRot = -0.16
            aL = .pi + 0.6
            aR = -0.6
        case .startled:
            sy = 1.03
            headDy = 3
            hatDy = 6 + 1.2 * f.swing2
            hatRot = 0.12
            aL = .pi - 1.15
            aR = 1.15
        case .fleeing:
            look = 1
            aL = .pi - 0.1 + 0.25 * f.swing2
            aR = 1.0 + 0.3 * f.swing2
            trail = -1.35 + 0.12 * f.swing2
            hatRot = 0.14
        case .dizzy:
            rot = 0.12 * sin(f.t)
            headDy = 0
            hatRot = 0.2 * sin(f.t + 1)
            aL = .pi - 0.4 + 0.5 * f.swing
            aR = 0.4 - 0.5 * f.swing
        }
        let la = max(0, f.swing) * 3 * e
        let lb = max(0, -f.swing) * 3 * e
        let bob = f.bounce * 1.4 * e
        k.with(about(50, 4, rot: rot)) {
            k.flat(ell(40, 7 + la, 7.5, 4.2), coal)
            k.flat(ell(60, 7 + lb, 7.5, 4.2), coal)
            k.with(about(50, 6, sx: sx, sy: sy).translatedBy(x: 0, y: bob)) {
                snowmanArm(k, 33, 30, aL, scarf)
                snowmanArm(k, 67, 30, aR, scarf)
                k.with(about(37, 44, rot: trail)) {
                    k.part(rrect(32, 24, 9, 21, 3.5), scarf)
                    k.stroke(line(33, 27, 40, 27), Tone(0xfdf6ee), k.thin)
                }
                k.part(circ(50, 25, 20), snow, shadow: shade, shape: ell(75, 14, 21, 30))
                k.gloss(37, 33, 2.4, 4.4, -0.6)
                k.flat(circ(50, 28, 2.6), coal)
                k.flat(circ(50, 18, 2.6), coal)
                let hy: CGFloat = 61 + headDy
                k.part(circ(50, hy, 19), snow, shadow: shade, shape: ell(75, hy - 9, 18, 26))
                k.gloss(38, hy + 8, 2, 3.6, -0.6)
                k.part(rrect(30, 40 + headDy * 0.4, 40, 9, 4.5), scarf, shadow: scarf.dim(0.78), shape: ell(78, 41, 12, 8))
                let fx = look * 2.5
                k.eye(44 + fx, hy + 3.5, 4, 5.2, side: -1, look: look)
                k.eye(56.5 + fx, hy + 3.5, 4, 5.2, side: 1, look: look)
                k.blush(38 + fx, hy - 5, 3.4, 2)
                k.mouth(46 + fx, hy - 10, 6.5)
                let nose = smooth([53 + fx, hy - 1.5, 76 + fx, hy - 4.5, 53 + fx, hy - 7], t: 0.3)
                k.flat(nose, Tone(0xff8a2a))
                k.with(about(50, hy + 15, rot: hatRot).translatedBy(x: 0, y: hatDy)) {
                    snowmanHat(f, k, hy + 15)
                }
                k.marks(78, hy + 22, 12)
            }
        }
    }

    private static func snowmanArm(_ k: StickerKit, _ x: CGFloat, _ y: CGFloat, _ a: CGFloat, _ mitt: Tone) {
        let len: CGFloat = 18
        let c = cos(a), s = sin(a)
        let ex = x + c * len, ey = y + s * len
        let bx = x + c * len * 0.6, by = y + s * len * 0.6
        let side: CGFloat = c >= 0 ? 1 : -1
        let p = CGMutablePath()
        p.move(to: pt(x, y))
        p.addLine(to: pt(ex, ey))
        p.move(to: pt(bx, by))
        p.addLine(to: pt(bx + cos(a + 0.7 * side) * 6, by + sin(a + 0.7 * side) * 6))
        let twig = Tone(0x8a5a3a)
        k.stroke(p, k.ink, k.line * 2.4)
        k.stroke(p, twig, k.line * 0.95)
        k.flat(circ(ex, ey, 3.8), mitt)
    }

    private static func snowmanHat(_ f: FigureFrame, _ k: StickerKit, _ y: CGFloat) {
        switch f.variant % 5 {
        case 1:
            let green = Tone(0x4cb860)
            let dome = CGMutablePath()
            dome.addArc(center: pt(50, y - 1), radius: 15.5, startAngle: 0, endAngle: .pi, clockwise: false)
            dome.closeSubpath()
            k.part(dome, green)
            k.clip(dome) { k.fill(rrect(30, y + 6, 40, 3.5, 0), Tone(0xfdf6ee)) }
            k.stroke(dome, k.ink, k.line)
            k.flat(rrect(33, y - 4.5, 34, 8, 4), Tone(0xfdf6ee))
            k.flat(circ(50, y + 16.5, 4.8), Tone(0xfdf6ee))
        case 2:
            let band = arc(32, y - 8, 68, y - 8, dip: -24)
            k.stroke(band, k.ink, k.line * 2.6)
            k.stroke(band, Tone(0xff7fb0), k.line * 0.9)
            k.flat(circ(31, y - 12, 6.5), Tone(0xff7fb0))
            k.flat(circ(69, y - 12, 6.5), Tone(0xff7fb0))
            k.gloss(29.5, y - 10, 1.4, 2.4, -0.5)
        case 3:
            let g = Tone(0x3fa04a)
            k.part(ell(43, y + 1, 7, 3.6, 0.4), g)
            k.part(ell(57, y + 1, 7, 3.6, -0.4), g)
            k.flat(circ(48, y + 3, 2.6), Tone(0xe84a4a))
            k.flat(circ(53, y + 4, 2.6), Tone(0xe84a4a))
            k.flat(circ(50, y - 0.5, 2.6), Tone(0xe84a4a))
        case 4:
            let red = Tone(0xe84a4a)
            let cone = smooth([35, y - 1, 65, y - 1, 64, y + 12, 77, y + 16, 54, y + 19], t: 0.5)
            k.part(cone, red)
            k.flat(rrect(32, y - 4.5, 36, 8, 4), Tone(0xfdf6ee))
            k.flat(circ(78, y + 15, 4.5), Tone(0xfdf6ee))
        default:
            let black = Tone(0x2e2a3e)
            let crown = rrect(38, y - 1, 24, 19, 3)
            k.part(crown, black, shadow: Tone(0x1f1c2c), shape: ell(66, y + 6, 6, 14))
            k.clip(crown) { k.fill(rrect(38, y + 1, 24, 4.5, 0), Tone(0xe84a4a)) }
            k.stroke(crown, k.ink, k.line)
            k.flat(rrect(31, y - 3.5, 38, 6, 3), black)
        }
    }

    static func snowflake(_ f: FigureFrame, _ k: StickerKit) {
        let v = f.variant % 5
        let looks: [(Tone, Tone)] = [
            (Tone(0xcfe8ff), Tone(0x8db6ea)), (Tone(0xe4d8ff), Tone(0xa894e6)), (Tone(0xd2f5ee), Tone(0x86cfbe)),
            (Tone(0xf6fbff), Tone(0xb4c8ea)), (Tone(0xbfe0ff), Tone(0x76a8e6)),
        ]
        let (base, shade) = f.pick(looks)
        let third: CGFloat = .pi / 3
        var R: CGFloat = 37, w: CGFloat = 7, spin: CGFloat = f.phase * third
        var sx: CGFloat = 1 + 0.03 * f.swing2, sy: CGFloat = 1 + 0.03 * f.swing2
        var rot: CGFloat = 0, faceRot: CGFloat = 0.1 * f.twitch, look: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            R = 33
            spin = 0.04 * f.swing
            sy = 0.92
            sx = 1.03
            faceRot = -0.12
        case .startled:
            R = 41
            w = 6.2
            sx = 1.06
            sy = 1.06
        case .fleeing:
            spin = -f.phase * 2 * third
            sx = 0.93
            look = 1
            faceRot = -0.1
        case .dizzy:
            spin = f.phase * 2 * third
            rot = 0.12 * sin(f.t)
        }
        k.with(about(50, 50, rot: rot, sx: sx, sy: sy)) {
            let arms = snowflakeArms(R: R, spin: spin)
            k.stroke(arms, k.ink, w + 2 * k.line)
            k.stroke(arms, shade, w)
            k.stroke(moved(arms, -1.1, 1.1), base, w * 0.64)
            if v == 1 {
                for i in 0..<6 {
                    let a = spin + CGFloat(i) * third + .pi / 2
                    k.flat(circ(50 + cos(a) * R, 50 + sin(a) * R, 4.2), Tone(0xff7fb0))
                }
            }
            k.with(about(50, 50, rot: faceRot)) {
                k.part(circ(50, 50, 17), base.lift(0.35), shadow: shade.lift(0.25), shape: ell(70, 36, 14, 22))
                k.gloss(41, 59, 1.8, 3.2, -0.6)
                k.face(50 + look * 2.5, 50, spread: 6, rx: 3.5, ry: 4.6, look: look)
                switch v {
                case 2:
                    let red = Tone(0xe84a4a)
                    let dome = CGMutablePath()
                    dome.addArc(center: pt(50, 63), radius: 10, startAngle: 0, endAngle: .pi, clockwise: false)
                    dome.closeSubpath()
                    k.part(dome, red)
                    k.flat(rrect(39, 60.5, 22, 5.5, 2.7), Tone(0xfdf6ee))
                    k.flat(circ(50, 74.5, 3.6), Tone(0xfdf6ee))
                case 3:
                    let pink = Tone(0xff4f8a)
                    k.part(smooth([50, 66, 41, 71, 41, 61], t: 0.4), pink)
                    k.part(smooth([50, 66, 59, 71, 59, 61], t: 0.4), pink)
                    k.flat(circ(50, 66, 2.6), pink.dim(0.85))
                default:
                    break
                }
            }
            if v == 4 {
                let tw = 0.6 + 0.4 * abs(sin(f.t * 2))
                k.flat(star(86, 82, 7 * tw, points: 4, inner: 0.4), Tone(0xffd54a))
                k.flat(star(14, 20, 5 * (1.6 - tw), points: 4, inner: 0.4), Tone(0xffd54a))
            }
            k.marks(74, 78, 12)
        }
    }

    private static func snowflakeArms(R: CGFloat, spin: CGFloat) -> CGPath {
        let p = CGMutablePath()
        for i in 0..<6 {
            let a = spin + CGFloat(i) * .pi / 3 + .pi / 2
            let c = cos(a), s = sin(a)
            p.move(to: pt(50 + c * 12, 50 + s * 12))
            p.addLine(to: pt(50 + c * R, 50 + s * R))
            let bx = 50 + c * R * 0.62, by = 50 + s * R * 0.62
            for side in [-1, 1] as [CGFloat] {
                let b = a + side * 0.8
                p.move(to: pt(bx, by))
                p.addLine(to: pt(bx + cos(b) * R * 0.3, by + sin(b) * R * 0.3))
            }
        }
        return p
    }

    static func robin(_ f: FigureFrame, _ k: StickerKit) {
        let v = f.variant % 5
        let browns: [Tone] = [Tone(0x8a5a3a), Tone(0x7a5238), Tone(0x96643e), Tone(0x8a5a3a), Tone(0xa0704a)]
        let brown = browns[v]
        let breast = Tone(0xff6a3a), beakTone = Tone(0xffb02e)
        let sq = f.squat, stp = f.stretch
        var sx: CGFloat = 1 + 0.1 * sq - 0.05 * stp
        var sy: CGFloat = 1 - 0.16 * sq + 0.1 * stp
        var rot: CGFloat = 0, look: CGFloat = 0, faceDy: CGFloat = 0
        var wing: CGFloat = f.airborne ? -0.7 * abs(sin(f.air * 3 * .pi)) : 0.05 * f.swing
        var tail: CGFloat = 0.25 * f.twitch, beakOpen: CGFloat = 0, crest = false
        let legLen: CGFloat = f.airborne ? 5 : 9
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sx *= 1.08
            sy *= 0.9
            faceDy = -2
            wing = 0.1
            tail = -0.15
        case .startled:
            sy *= 1.05
            sx *= 0.97
            wing = -1.0
            beakOpen = 3
            crest = true
            tail = 0.3
        case .fleeing:
            wing = -0.3 - 0.8 * abs(f.swing2)
            look = 1
            beakOpen = 2
            tail = -0.3
        case .dizzy:
            rot = 0.12 * sin(f.t)
            wing = -0.3 * abs(f.swing)
        }
        k.with(about(50, 4, rot: rot)) {
            robinLegs(k, legLen)
            k.with(about(50, 4, sx: sx, sy: sy)) {
                k.with(about(26, 36, rot: tail)) {
                    k.part(smooth([28, 30, 6, 40, 4, 50, 30, 42], t: 0.5), brown.dim(0.85))
                }
                if crest {
                    k.flat(poly([52, 56, 50, 70, 57, 60, 60, 72, 62, 58]), brown)
                }
                let body = ell(48, 36, 27, 25)
                k.fill(body, brown)
                k.clip(body) {
                    k.fill(ell(32, 12, 26, 14), brown.dim(0.76))
                    let br = ell(66, 26, 19, 20)
                    k.fill(br, breast)
                    k.clip(br) { k.fill(ell(70, 9, 22, 12), breast.dim(0.82)) }
                    k.fill(ell(50, 8, 14, 6), Tone(0xfbeedb))
                }
                k.stroke(body, k.ink, k.line)
                k.gloss(34, 52, 2.4, 4.2, -0.6)
                k.with(about(50, 44, rot: wing)) {
                    k.part(ell(36, 36, 15, 9.5, -0.35), brown.dim(0.9), shadow: brown.dim(0.72), shape: ell(36, 26, 18, 6))
                }
                if v == 2 { robinScarf(k) }
                let fx = look * 2, fy = faceDy
                k.eye(55 + fx, 46 + fy, 3.8, 5, side: -1, look: look)
                k.eye(65.5 + fx, 46 + fy, 3.8, 5, side: 1, look: look)
                k.blush(50 + fx, 39 + fy, 3, 1.8)
                if beakOpen > 0 {
                    k.flat(poly([71, 40 + fy, 85, 38 + fy + beakOpen * 0.5, 71, 35.5 + fy]), beakTone)
                    k.flat(poly([71, 35 + fy, 82, 34 - beakOpen + fy, 71, 31 + fy]), beakTone.dim(0.85))
                } else {
                    k.flat(poly([71, 40 + fy, 85, 36 + fy, 71, 32 + fy]), beakTone)
                }
                if v == 4 && beakOpen == 0 {
                    let worm = wavy(84, 35 + fy, 86, 22 + fy, waves: 1.5, amp: 1.8, phase: f.t)
                    k.stroke(worm, k.ink, k.line * 2.3)
                    k.stroke(worm, Tone(0xff9fb0), k.line * 0.9)
                }
                if v == 1 { robinHat(k, fy) }
                if v == 3 { robinHolly(k, fy) }
                k.marks(76, 64, 12)
            }
        }
    }

    private static func robinLegs(_ k: StickerKit, _ len: CGFloat) {
        let p = CGMutablePath()
        for x in [44, 55] as [CGFloat] {
            let top: CGFloat = 4 + len + 2
            p.move(to: pt(x, top))
            p.addLine(to: pt(x - 1, top - len))
            p.move(to: pt(x - 4.5, top - len))
            p.addLine(to: pt(x + 3.5, top - len))
        }
        k.stroke(p, k.ink, k.line * 1.1)
        k.stroke(p, Tone(0xffb02e), k.line * 0.35)
    }

    private static func robinScarf(_ k: StickerKit) {
        let green = Tone(0x4cb860)
        let band = smooth([28, 36, 50, 31, 74, 34, 74, 27, 50, 24, 27, 29], t: 0.6)
        k.part(rrect(30, 14, 8, 17, 3.5), green)
        k.part(band, green, shadow: green.dim(0.78), shape: ell(76, 26, 10, 6))
    }

    private static func robinHat(_ k: StickerKit, _ fy: CGFloat) {
        let red = Tone(0xe84a4a)
        k.with(about(56, 58 + fy, rot: -0.28)) {
            let dome = CGMutablePath()
            dome.addArc(center: pt(56, 58 + fy), radius: 11, startAngle: 0, endAngle: .pi, clockwise: false)
            dome.closeSubpath()
            k.part(dome, red)
            k.flat(rrect(43.5, 54.5 + fy, 25, 6.5, 3.2), Tone(0xfdf6ee))
            k.flat(circ(56, 71 + fy, 4), Tone(0xfdf6ee))
        }
    }

    private static func robinHolly(_ k: StickerKit, _ fy: CGFloat) {
        let g = Tone(0x3fa04a)
        k.part(ell(46, 62 + fy, 7, 3.4, 0.5), g)
        k.part(ell(58, 63 + fy, 7, 3.4, -0.3), g)
        k.flat(circ(51, 63 + fy, 2.6), Tone(0xe84a4a))
        k.flat(circ(54, 66 + fy, 2.6), Tone(0xe84a4a))
    }

    static func cloud(_ f: FigureFrame, _ k: StickerKit) {
        let v = f.variant % 5
        let looks: [(Tone, Tone)] = [
            (Tone(0xffffff), Tone(0xc9d6ee)), (Tone(0xc8d3e6), Tone(0x95a3bf)), (Tone(0xffdfe9), Tone(0xf0a8c0)),
            (Tone(0xe8e0ff), Tone(0xb8a8e8)), (Tone(0x9ea6bd), Tone(0x737b96)),
        ]
        let (base, shade) = f.pick(looks)
        let t = f.t
        var sx: CGFloat = 1, sy: CGFloat = 1, rot: CGFloat = 0, look: CGFloat = 0
        var puff: CGFloat = 0, trail: CGFloat = 0, breath: CGFloat = 0.9
        switch f.mood {
        case .calm:
            puff = 1.4 * f.twitch
        case .sleepy:
            sy = 0.86
            sx = 1.06
            breath = 0.4
        case .startled:
            sy = 1.08
            sx = 0.97
            puff = 2
        case .fleeing:
            sx = 1.05
            sy = 0.95
            trail = 1
            look = 1
            breath = 1.4
        case .dizzy:
            rot = 0.12 * sin(t)
        }
        k.with(about(50, 40, rot: rot, sx: sx, sy: sy)) {
            if v == 2 {
                let sun = Tone(0xffc93c)
                k.part(softStar(74, 60, 17, points: 8, inner: 0.72, spin: f.phase * .pi / 4), sun, shadow: Tone(0xf5a623), shape: ell(92, 50, 10, 16))
            }
            if v == 1 || v == 3 { cloudFall(f, k, snow: v == 3) }
            if v == 4 {
                let bolt = poly([52, 30, 44, 16, 50, 16, 44, 2, 60, 20, 53, 20, 58, 30])
                k.flat(bolt, f.frameIndex % 8 < 5 ? Tone(0xffd54a) : Tone(0xfff3a0))
            }
            if trail > 0 {
                let d = 2 * sin(t)
                k.part(circ(4 + d, 34, 5), base, shadow: shade)
                k.part(circ(13 + d * 0.5, 38, 7.5), base, shadow: shade)
            }
            let b0 = breath * sin(t), b1 = breath * sin(t + 2.1), b2 = breath * sin(t + 4.2)
            let body: [CGPath] = [
                rrect(16 + trail * 2, 24, 70, 22, 11),
                circ(30, 44, 13 + b0),
                circ(49, 55 + puff * 0.6, 17 + b1 + puff * 0.5),
                circ(68, 50, 14 + b2),
                circ(82, 38, 9.5 + b0 * 0.6),
            ]
            cloudMerge(k, body, base, shadow: shade, shape: ell(56, 16, 52, 16))
            k.gloss(36, 54, 2.6, 4.6, -0.6)
            k.face(53 + look * 2.5, 42, spread: 8, rx: 4.6, ry: 6, look: look)
            k.marks(80, 66, 13)
        }
    }

    private static func cloudMerge(_ k: StickerKit, _ parts: [CGPath], _ base: Tone, shadow: Tone, shape: CGPath) {
        let p = CGMutablePath()
        for q in parts { p.addPath(q) }
        k.stroke(p, k.ink, k.line * 2)
        k.fill(p, base)
        k.clip(p) { k.fill(shape, shadow) }
    }

    private static func cloudFall(_ f: FigureFrame, _ k: StickerKit, snow: Bool) {
        for i in 0..<3 {
            let u = (f.phase * 2 + CGFloat(i) * 0.37).truncatingRemainder(dividingBy: 1)
            let x: CGFloat = 32 + CGFloat(i) * 17
            let y: CGFloat = 24 - u * 18
            if snow {
                k.flat(circ(x, y, 4.2), Tone(0xffffff))
            } else {
                k.flat(drop(x, y, 4.4), Tone(0x6ec3ff))
            }
        }
    }

    static func owl(_ f: FigureFrame, _ k: StickerKit) {
        let v = f.variant % 5
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0xa8754a), Tone(0xf3dcb8), Tone(0xfff0d8)), (Tone(0xeef0f6), Tone(0xffffff), Tone(0xffffff)),
            (Tone(0x8a8eaa), Tone(0xdfe2ee), Tone(0xf4f5fa)), (Tone(0x8a6ac8), Tone(0xe6dcff), Tone(0xf5f0ff)),
            (Tone(0xd88a3a), Tone(0xffe2b0), Tone(0xfff2da)),
        ]
        let (body, belly, mask) = f.pick(looks)
        let orange = Tone(0xffa22b)
        let sq = f.squat, stp = f.stretch
        var sx: CGFloat = 1 + 0.1 * sq - 0.05 * stp
        var sy: CGFloat = 1 - 0.16 * sq + 0.1 * stp
        var rot: CGFloat = 0, look: CGFloat = 0
        let open: CGFloat = f.airborne ? sin(f.air * .pi) : 0
        var aL: CGFloat = -0.1 - 0.9 * open, aR: CGFloat = 0.1 + 0.9 * open
        var tL: CGFloat = 0, tR: CGFloat = 0.2 * f.twitch, beak: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sx *= 1.05
            sy *= 0.92
            tL = 0.35
            tR = -0.35
            aL = 0.05
            aR = -0.05
        case .startled:
            sy *= 1.06
            sx *= 0.97
            tL = -0.15
            tR = 0.15
            aL = -1.9
            aR = 1.9
            beak = 3
        case .fleeing:
            aL = -1.3 + 0.4 * f.swing2
            aR = 1.0 + 0.4 * f.swing2
            look = 1
            tL = 0.25
            tR = 0.25
            beak = 2
        case .dizzy:
            rot = 0.12 * sin(f.t)
        }
        k.with(about(50, 4, rot: rot)) {
            k.flat(ell(41, 7, 6.5, 3.6), orange)
            k.flat(ell(59, 7, 6.5, 3.6), orange)
            k.with(about(50, 4, sx: sx, sy: sy)) {
                k.with(about(33, 74, rot: tL)) { k.flat(smooth([29, 72, 19, 88, 33, 84, 43, 78], t: 0.5), body) }
                k.with(about(67, 74, rot: tR)) { k.flat(smooth([71, 72, 81, 88, 67, 84, 57, 78], t: 0.5), body) }
                k.with(about(25, 54, rot: aL)) { k.part(ell(22, 38, 8, 17), body.dim(0.88)) }
                k.with(about(75, 54, rot: aR)) { k.part(ell(78, 38, 8, 17), body.dim(0.88)) }
                let b = ell(50, 44, 29, 36)
                k.part(b, body, shadow: body.dim(0.78), shape: ell(86, 30, 22, 50))
                k.part(ell(50, 28, 17, 18), belly, shadow: belly.dim(0.9), shape: ell(70, 16, 12, 18))
                let chev = CGMutablePath()
                for (x, y) in [(44.0, 32.0), (56.0, 32.0), (50.0, 24.0)] as [(CGFloat, CGFloat)] {
                    chev.move(to: pt(x - 3.2, y + 1.6))
                    chev.addLine(to: pt(x, y - 1.2))
                    chev.addLine(to: pt(x + 3.2, y + 1.6))
                }
                k.stroke(chev, belly.dim(0.72), k.thin)
                if v == 1 {
                    for (x, y) in [(30.0, 46.0), (70.0, 44.0), (34.0, 30.0), (66.0, 26.0)] as [(CGFloat, CGFloat)] {
                        k.fill(ell(x, y, 2.2, 1.5), Tone(0x6a6a80))
                    }
                }
                if v == 4 { owlScarf(k) }
                let fx = look * 2.5
                cloudMerge(k, [circ(39.5 + fx, 56, 12.2), circ(60.5 + fx, 56, 12.2)], mask, shadow: mask.dim(0.92), shape: ell(76, 46, 10, 10))
                k.eye(40 + fx, 56.5, 5.2, 6.6, side: -1, look: look)
                k.eye(60 + fx, 56.5, 5.2, 6.6, side: 1, look: look)
                if v == 2 {
                    let g = CGMutablePath()
                    g.addPath(circ(40 + fx, 56.5, 9))
                    g.addPath(circ(60 + fx, 56.5, 9))
                    g.move(to: pt(49 + fx, 57))
                    g.addLine(to: pt(51 + fx, 57))
                    k.stroke(g, k.ink, k.line * 0.9)
                }
                k.blush(30 + fx, 47, 3.2, 1.9)
                k.blush(70 + fx, 47, 3.2, 1.9)
                if beak > 0 {
                    k.flat(poly([45.5 + fx, 49, 54.5 + fx, 49, 50 + fx, 44 - beak]), Tone(0x8a3a3a))
                    k.flat(poly([45.5 + fx, 50, 54.5 + fx, 50, 50 + fx, 46]), orange)
                } else {
                    k.flat(poly([45.5 + fx, 50, 54.5 + fx, 50, 50 + fx, 43]), orange)
                }
                if v == 3 { owlCap(k, f) }
                k.marks(76, 84, 13)
            }
        }
    }

    private static func owlScarf(_ k: StickerKit) {
        let red = Tone(0xe84a4a)
        k.part(rrect(28, 22, 9, 20, 3.5), red)
        let band = smooth([21, 44, 50, 40, 79, 44, 79, 36, 50, 32, 21, 36], t: 0.5)
        k.part(band, red, shadow: red.dim(0.78), shape: ell(80, 34, 10, 6))
    }

    private static func owlCap(_ k: StickerKit, _ f: FigureFrame) {
        let dark = Tone(0x2e2a3e)
        k.flat(rrect(38, 72, 24, 9, 3), dark)
        k.flat(poly([26, 82, 50, 90, 74, 82, 50, 75]), dark)
        let sw = 1.5 * f.swing
        let tassel = smooth([50, 83, 66, 82, 68 + sw, 72], closed: false)
        k.stroke(tassel, k.ink, k.line * 1.9)
        k.stroke(tassel, Tone(0xffc93c), k.line * 0.7)
        k.flat(rrect(65 + sw, 66, 6, 7, 2), Tone(0xffc93c))
    }
}
