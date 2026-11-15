import Foundation
import CoreGraphics
import ScuttleCore

extension KawaiiArt {
    static func hedgehog(_ f: FigureFrame, _ k: KawaiiKit) {
        let quill = f.pick([Tone(0xcca089), Tone(0xb9aaa8), Tone(0xdfaaa6), Tone(0xb8937e), Tone(0xe9d0b4)])
        let cream = f.pick([Tone(0xfff1de), Tone(0xfff6ee), Tone(0xffefe9), Tone(0xffeedb), Tone(0xfffaf1)])
        let toe = Tone(0xf5c8b4)
        let e = f.energy
        var sx: CGFloat = 1, sy: CGFloat = 1, tilt: CGFloat = 0
        var len: CGFloat = 13, lean: CGFloat = 0.3, count = 9
        var fx: CGFloat = 0, fy: CGFloat = 0, stride: CGFloat = 5 * e, sniff: CGFloat = f.twitch
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sx = 1.06; sy = 0.86; len = 10; lean = 0.55; fy = -2.5; stride = 1.2; sniff = 0
        case .startled:
            sx = 0.95; sy = 1.08; len = 19; lean = -0.05; count = 11; fy = 1.5
        case .fleeing:
            len = 14; lean = 0.9; fx = 2.5; stride = 7.5
        case .dizzy:
            tilt = 0.12 * sin(f.t)
        }
        let step = f.sway * stride
        let upA = max(0, -f.swing) * 2.6 * min(e, 1.4)
        let upB = max(0, f.swing) * 2.6 * min(e, 1.4)
        let by: CGFloat = 35 + 1.1 * f.bounce * min(e, 1.3)
        let wob: CGFloat = f.mood == .fleeing ? 1.5 * sin(f.t * 2) : 0.6 * sin(f.t)
        k.with(about(50, 5, rot: tilt, sx: sx, sy: sy)) {
            let far = k.shade(toe)
            k.nub(28 - step, 7 + upB, 6.5, 4, far)
            k.nub(58 + step, 7 + upA, 6.5, 4, far)
            k.nub(36 + step, 6 + upA, 7, 4.2, toe)
            k.nub(68 - step, 6 + upB, 7, 4.2, toe)
            k.fill(kawaiiHedgehogQuills(44, by + 3, 30, 25, len: len, lean: lean, n: count, a0: 1.2, a1: 3.8, ripple: wob), quill)
            k.body(ell(47, by, 33, 27), quill)
            k.shine(30, by + 17, 4.6, 2.6)
            kawaiiHedgehogPack(f, k, by)
            let snout = ell(81, by - 8 + sniff * 0.6, 12, 8, -0.18)
            k.body(kawaiiWoodJoin([ell(66, by - 4, 20, 20), snout]), cream, depth: 0.32)
            k.nub(58, by + 19, 5.5, 6, cream)
            k.nub(58, by + 18.5, 2.8, 3.2, Tone(0xffc3cf))
            k.blush(60 + fx, by - 4 + fy, 3.6, 2.1)
            k.blush(79 + fx, by - 2 + fy, 2.6, 1.6)
            k.eye(64 + fx, by + 2 + fy, 2.5, side: -1)
            k.eye(75 + fx, by + 3 + fy, 2.5, side: 1)
            k.fill(ell(92 + fx * 0.4, by - 7 + sniff, 3.3, 2.8), Tone(0x7d5866))
            k.mouth(84 + fx * 0.6, by - 12 + fy * 0.5, 4.4, kind: .cat)
            k.marks(82, by + 32, 12)
        }
    }

    private static func kawaiiHedgehogQuills(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, len: CGFloat, lean: CGFloat, n: Int, a0: CGFloat, a1: CGFloat, ripple: CGFloat) -> CGPath {
        var pts: [CGPoint] = [pt(cx, cy)]
        let step = (a1 - a0) / CGFloat(n)
        for i in 0...n {
            let a = a0 + CGFloat(i) * step
            pts.append(pt(cx + cos(a) * rx, cy + sin(a) * ry))
            if i < n {
                let at = a + step * (0.5 + lean)
                let u = CGFloat(i) / CGFloat(max(1, n - 1))
                let l = len * (0.72 + 0.28 * sin(u * .pi)) + ripple * sin(CGFloat(i) * 1.9)
                pts.append(pt(cx + cos(at) * (rx + l), cy + sin(at) * (ry + l)))
            }
        }
        return smoothP(pts, t: 0.55)
    }

    private static func kawaiiHedgehogPack(_ f: FigureFrame, _ k: KawaiiKit, _ by: CGFloat) {
        switch f.variant % 5 {
        case 0:
            k.fill(circ(37, by + 29, 7.5), Tone(0xff9ea2))
            k.stroke(line(37, by + 35, 38.5, by + 40.5), Tone(0xb08a76), k.width(2, minPt: 0.7))
            k.nub(43, by + 39.5, 4.6, 2.3, Tone(0xa8dca0), 0.4)
            k.shine(34, by + 32, 2.1, 1.3)
        case 1:
            k.fill(rrect(33, by + 22, 6, 10, 3), Tone(0xfff3e4))
            let cap = moved(smooth([25, 31, 47, 31, 43, 38.5, 36, 41, 29, 38.5], t: 0.7), 0, by)
            k.fill(cap, Tone(0xff9f9f))
            k.fill(circ(32, by + 35.5, 1.9), .white)
            k.fill(circ(40, by + 35, 1.6), .white)
        case 2:
            k.bow(41, by + 32, 6.5, Tone(0xb9d4ff), 0.25)
        case 3:
            k.with(about(37, by + 30, rot: 0.5)) {
                k.fill(moved(smooth([37, 20, 44.5, 30, 37, 42, 29.5, 30], t: 0.7), 0, by), Tone(0xffb27a))
                k.stroke(line(37, by + 21, 37, by + 38), Tone(0xffd3a8), k.width(1.4, minPt: 0.5))
            }
        default:
            k.flower(38, by + 31, 6.5, Tone(0xffb8d0))
        }
    }

    static func acorn(_ f: FigureFrame, _ k: KawaiiKit) {
        let nut = f.pick([Tone(0xf7d0a0), Tone(0xfde2bf), Tone(0xf3c6a8), Tone(0xffe2a6), Tone(0xeac6a6)])
        let cap = f.pick([Tone(0xc49c7f), Tone(0xf4b4c6), Tone(0xaacb9c), Tone(0xd2a27e), Tone(0xb4a0d8)])
        let air: CGFloat = f.airborne ? sin(f.air * .pi) : 0
        var sx: CGFloat = 1 + 0.12 * f.squat - 0.05 * f.stretch
        var sy: CGFloat = 1 - 0.16 * f.squat + 0.1 * f.stretch
        var tilt: CGFloat = 0, capRot: CGFloat = 0.06 * f.twitch
        var capY: CGFloat = f.airborne ? 2.5 * max(0, -f.stretch) - 1.5 * max(0, f.stretch) : -1.5 * f.squat
        var al: CGFloat = 26 + 7 * air, ar: CGFloat = 26 + 7 * air + 3 * max(0, f.twitch), out: CGFloat = 0
        var fx: CGFloat = 0, fy: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sx *= 1.06; sy *= 0.9; capY = -4.5; capRot = 0.1; al = 19; ar = 19; fy = -1
        case .startled:
            sx *= 0.95; sy *= 1.07; capY = 8; capRot = -0.18; al = 42; ar = 42; out = 3
        case .fleeing:
            capRot = 0.32; capY = 2.5; al = 34 + 4 * f.swing2; ar = 24 - 4 * f.swing2; fx = 3
        case .dizzy:
            tilt = 0.12 * sin(f.t); capRot = 0.22 * sin(f.t + 1.2)
        }
        let feetUp = 3 * air
        k.with(about(50, 5, rot: tilt, sx: sx, sy: sy)) {
            k.nub(39, 6 + feetUp, 5.5, 3.6, k.shade(nut))
            k.nub(61, 6 + feetUp, 5.5, 3.6, k.shade(nut))
            k.nub(23 - out, al, 4.3, 5.4, nut, 0.3)
            k.nub(77 + out, ar, 4.3, 5.4, nut, -0.3)
            let shell = smooth([50, 5, 57, 8, 66, 15, 73, 26, 75, 38, 72, 50, 50, 54, 28, 50, 25, 38, 27, 26, 34, 15, 43, 8], t: 0.85)
            k.body(shell, nut)
            k.face(50 + fx, 28 + fy, spread: 10, r: 2.7)
            k.with(about(50, 48, rot: capRot)) {
                kawaiiAcornCap(f, k, cap, capY)
            }
            k.marks(80, 74, 12)
        }
    }

    private static func kawaiiAcornCap(_ f: FigureFrame, _ k: KawaiiKit, _ tone: Tone, _ dy: CGFloat) {
        let v = f.variant % 5
        if v == 3 {
            let leaf = Tone(0x9fdcae)
            k.stroke(arc(50, 70 + dy, 51, 79 + dy, dip: -1.5), leaf.dim(0.9), k.width(2.2, minPt: 0.7))
            k.nub(44.5, 80 + dy + f.twitch, 6, 3.2, leaf, 0.45)
            k.nub(56.5, 81 + dy - f.twitch, 6, 3.2, leaf, -0.45)
        } else {
            k.with(about(50, 71 + dy, rot: 0.25 * f.twitch)) {
                k.fill(rrect(47.5, 69 + dy, 5, 11, 2.5), tone.dim(0.84))
            }
        }
        let capP = moved(smooth([20, 48, 35, 45, 50, 44.5, 65, 45, 80, 48, 81, 57, 72, 69, 50, 73, 28, 69, 19, 57], t: 0.85), 0, dy)
        k.body(capP, tone, depth: 0.32)
        let hatch = tone.lift(0.22)
        let hw = k.width(1.5, minPt: 0.5)
        k.clip(capP) {
            for i in 0..<7 {
                let x0 = 6 + CGFloat(i) * 9
                k.stroke(line(x0, 44 + dy, x0 + 30, 74 + dy), hatch, hw)
                k.stroke(line(x0 + 30, 44 + dy, x0, 74 + dy), hatch, hw)
            }
        }
        k.fill(moved(smooth([19, 50, 50, 46, 81, 50, 81, 53, 50, 49.5, 19, 53], t: 0.6), 0, dy), tone.dim(0.93))
        k.shine(34, 63 + dy, 4.5, 2.5)
        switch v {
        case 0:
            k.nub(57.5, 77 + dy, 5.5, 2.6, Tone(0x9fd8a0), 0.5)
        case 1:
            k.bow(68, 62 + dy, 4.6, Tone(0xa8c8ff), -0.3)
        case 2:
            k.flower(66, 64 + dy, 4.6, Tone(0xffb8d0))
        case 4:
            k.fill(softStar(66, 63 + dy, 5.5, inner: 0.5, spin: .pi / 2 - 0.2), Tone(0xffe08a))
        default:
            break
        }
    }

    static func toadstool(_ f: FigureFrame, _ k: KawaiiKit) {
        let capT = f.pick([Tone(0xff9f9f), Tone(0xcbb6f3), Tone(0xffd98c), Tone(0xa9dcc2), Tone(0xffb796)])
        let dot = f.pick([Tone(0xfff7ef), Tone(0xffffff), Tone(0xfffaf0), Tone(0xffffff), Tone(0xfff3f0)])
        let stem = Tone(0xfff2e2)
        let e = f.energy
        var sx: CGFloat = 1, sy: CGFloat = 1, tilt: CGFloat = 0
        var capRot: CGFloat = -0.05 * f.swing * min(e, 1.3), capY: CGFloat = 0
        var al: CGFloat = 26 + 1.5 * f.swing, ar: CGFloat = 26 - 1.5 * f.swing + 4 * max(0, f.twitch)
        var fx: CGFloat = 0, fy: CGFloat = 0, stride: CGFloat = 4.5 * e
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sy = 0.92; sx = 1.04; capY = -3; capRot = -0.12; al = 20; ar = 20; stride = 1; fy = -1
        case .startled:
            sy = 1.06; sx = 0.96; capY = 7; al = 40; ar = 40
        case .fleeing:
            capRot = 0.22; al = 34 + 3 * f.swing2; ar = 22 - 3 * f.swing2; fx = 3; stride = 7
        case .dizzy:
            tilt = 0.12 * sin(f.t); capRot = 0.15 * sin(f.t + 1)
        }
        let step = f.sway * stride
        let upA = max(0, -f.swing) * 2.5 * min(e, 1.4)
        let upB = max(0, f.swing) * 2.5 * min(e, 1.4)
        let bob: CGFloat = 1.2 * f.bounce * min(e, 1.3)
        k.with(about(50, 5, rot: tilt, sx: sx, sy: sy)) {
            let foot = k.shade(stem)
            k.nub(41 + step, 6 + upA, 6, 3.6, foot)
            k.nub(59 - step, 6 + upB, 6, 3.6, foot)
            k.nub(30, al + bob, 4, 5.8, stem, 0.5)
            k.nub(70, ar + bob, 4, 5.8, stem, -0.5)
            let stalk = smooth([33, 10, 50, 8, 67, 10, 70, 28, 65, 48, 50, 50, 35, 48, 30, 28], t: 0.8)
            k.body(moved(stalk, 0, bob), stem, depth: 0.28)
            k.face(50 + fx, 27 + bob + fy, spread: 9.5, r: 2.7)
            k.with(about(50, 46 + bob, rot: capRot)) {
                kawaiiToadstoolCap(f, k, capT, dot, capY + bob)
            }
            k.marks(84, 86, 12)
        }
    }

    private static func kawaiiToadstoolCap(_ f: FigureFrame, _ k: KawaiiKit, _ tone: Tone, _ dot: Tone, _ dy: CGFloat) {
        let v = f.variant % 5
        k.fill(ell(50, 45 + dy, 31, 5), Tone(0xf3d9cf).mix(tone, 0.2))
        let cap = moved(smooth([11, 47, 30, 44, 50, 43, 70, 44, 89, 47, 86, 62, 70, 78, 50, 83, 30, 78, 14, 62], t: 0.85), 0, dy)
        k.body(cap, tone, depth: 0.22)
        k.clip(cap) {
            if v == 4 {
                k.fill(heart(36, 64 + dy, 6), dot)
                k.fill(heart(64, 66 + dy, 5), dot)
                k.fill(heart(50, 52 + dy, 3.5), dot)
            } else {
                k.fill(circ(36, 66 + dy, 6), dot)
                k.fill(circ(60, 73 + dy, 5), dot)
                k.fill(circ(72, 57 + dy, 4.5), dot)
                k.fill(circ(21, 54 + dy, 3.4), dot)
                k.fill(circ(50, 55 + dy, 3.2), dot)
            }
        }
        switch v {
        case 1:
            k.bow(80, 54 + dy, 5, Tone(0xfff0a8), -0.4)
        case 2:
            let leaf = Tone(0x9fdcae)
            k.stroke(arc(50, 81 + dy, 51, 90 + dy, dip: -1.5), leaf.dim(0.9), k.width(2.2, minPt: 0.7))
            k.nub(44.5, 91 + dy + f.twitch, 6, 3.2, leaf, 0.45)
            k.nub(56.5, 92 + dy - f.twitch, 6, 3.2, leaf, -0.45)
        case 3:
            k.flower(68, 76 + dy, 5.2, Tone(0xffb8d0))
        default:
            break
        }
    }

    static func leaf(_ f: FigureFrame, _ k: KawaiiKit) {
        let tone = f.pick([Tone(0xffb47e), Tone(0xff9f9a), Tone(0xffd97e), Tone(0xb9dca0), Tone(0xf3b98f)])
        let kind = f.pick([0, 1, 0, 2, 1])
        var sx: CGFloat = 1 - 0.1 * (0.5 - 0.5 * cos(f.t))
        var sy: CGFloat = 1, tilt: CGFloat = 0, shear: CGFloat = 0.05 * f.swing
        var al: CGFloat = 46 + 3 * f.swing, ar: CGFloat = 46 - 3 * f.swing + 5 * max(0, f.twitch)
        var fx: CGFloat = 0, fy: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sy = 0.93; sx = 1; al = 38; ar = 38; fy = -1; tilt = 0.1
        case .startled:
            sy = 1.07; sx = 0.96; al = 62; ar = 62
        case .fleeing:
            shear = -0.22; al = 54 + 4 * f.swing2; ar = 40 - 4 * f.swing2; fx = 3
        case .dizzy:
            tilt = 0.15 * sin(f.t); shear = 0.08 * f.swing2
        }
        k.with(kawaiiWoodWarp(50, 50, rot: tilt, sx: sx, sy: sy, shear: shear)) {
            let ax: CGFloat = kind == 1 ? 13 : 24
            k.nub(ax, al, 4.6, 4.2, tone)
            k.nub(100 - ax, ar, 4.6, 4.2, tone)
            k.stroke(smooth([50, 24, 49, 14, 45, 8, 41, 9], closed: false), tone.dim(0.82), k.width(3, minPt: 0.9))
            let blade = kawaiiLeafBlade(kind)
            k.body(blade, tone, depth: 0.3)
            let vein = tone.lift(0.45), vw = k.width(2, minPt: 0.6)
            k.stroke(line(50, 66, 50, 84), vein, vw)
            if kind == 1 {
                k.stroke(line(64, 60, 78, 74), vein, vw)
                k.stroke(line(36, 60, 22, 74), vein, vw)
                k.stroke(line(73, 45, 84, 45), vein, vw)
                k.stroke(line(27, 45, 16, 45), vein, vw)
            }
            k.shine(36, 66, 4.4, 2.5)
            k.face(50 + fx, 48 + fy, spread: 9.5, r: 2.7)
            switch f.variant % 5 {
            case 2:
                k.fill(circ(66, 72, 4.6), Tone(0xff8f8f))
                k.fill(circ(69.5, 74.5, 2.2), Tone(0x6e5a6e))
                k.stroke(line(64, 69, 68, 75), Tone(0x6e5a6e).alpha(0.7), k.width(0.9, minPt: 0.4))
            case 4:
                k.bow(48, 16, 4.2, Tone(0xc8b4f4), 0.3)
            default:
                break
            }
            k.marks(76, 82, 12)
        }
    }

    private static func kawaiiLeafBlade(_ kind: Int) -> CGPath {
        switch kind {
        case 1:
            let right: [CGFloat] = [50, 93, 56, 84, 60, 85, 61, 73, 70, 78, 83, 82, 78, 70, 82, 66, 73, 57, 83, 54, 89, 43, 78, 41, 70, 38, 60, 34, 54, 27]
            var pts: [CGFloat] = right + [50, 24]
            var i = right.count - 2
            while i >= 2 {
                pts.append(100 - right[i])
                pts.append(right[i + 1])
                i -= 2
            }
            return smooth(pts, t: 0.5)
        case 2:
            return smooth([50, 90, 60, 83, 64, 75, 73, 70, 74, 59, 67, 53, 75, 43, 67, 32, 57, 30, 50, 22, 43, 30, 33, 32, 25, 43, 33, 53, 26, 59, 27, 70, 36, 75, 40, 83], t: 0.7)
        default:
            return smooth([50, 91, 64, 80, 75, 60, 70, 38, 50, 22, 30, 38, 25, 60, 36, 80], t: 0.9)
        }
    }

    static func penguin(_ f: FigureFrame, _ k: KawaiiKit) {
        let coat = f.pick([Tone(0xa9bde8), Tone(0xc4b6ee), Tone(0x9fd0d8), Tone(0xb3bcd8), Tone(0xf2bccd)])
        let cream = Tone(0xfff7ee), peach = Tone(0xffc58f)
        let e = f.energy
        var sx: CGFloat = 1, sy: CGFloat = 1
        var tilt: CGFloat = 0.05 * f.swing * min(e, 1.2)
        var fl: CGFloat = 0.12 * f.swing * e, fr: CGFloat = -0.12 * f.swing * e
        var fx: CGFloat = 0, fy: CGFloat = 0, stride: CGFloat = 3 * e
        var open = false
        switch f.mood {
        case .calm:
            fr += 0.5 * max(0, f.twitch)
        case .sleepy:
            sx = 1.06; sy = 0.9; fl = 0.15; fr = -0.15; fy = -2; stride = 0.8; tilt = 0.06
        case .startled:
            sx = 0.95; sy = 1.08; fl = -1.5 + 0.1 * f.swing2; fr = 1.5 - 0.1 * f.swing2; fy = 2; open = true
        case .fleeing:
            fl = -1.1 + 0.35 * f.swing; fr = 0.7 - 0.5 * f.swing; fx = 3; stride = 4.5
        case .dizzy:
            tilt = 0.12 * sin(f.t); fl = -0.4 + 0.3 * sin(f.t); fr = 0.4 + 0.3 * sin(f.t)
        }
        let upL = max(0, f.swing) * 3 * min(e, 1.4)
        let upR = max(0, -f.swing) * 3 * min(e, 1.4)
        k.with(about(50, 5, rot: tilt, sx: sx, sy: sy)) {
            k.nub(40.5 - stride * f.swing * 0.4, 6.5 + upL, 6.5, 3.8, peach)
            k.nub(59.5 + stride * f.swing * 0.4, 6.5 + upR, 6.5, 3.8, peach)
            k.with(about(23, 46, rot: fl)) { k.nub(17, 34, 6.5, 12, coat, -0.5) }
            k.with(about(77, 46, rot: fr)) { k.nub(83, 34, 6.5, 12, coat, 0.5) }
            let body = ell(50, 41, 35, 34)
            k.body(body, coat, depth: 0.28)
            let bx = 50 + fx * 0.5
            let belly = kawaiiWoodJoin([circ(bx - 11, 45, 17), circ(bx + 11, 45, 17), ell(bx, 31, 25, 21)])
            k.clip(body) { k.body(belly, cream, depth: 0.3) }
            k.fill(ell(50, 74.5, 7, 2.6), coat.lift(0.35))
            k.shine(29, 62, 4.5, 2.6)
            let cx = 50 + fx, cy = 33.5 + fy
            if open {
                k.fill(ell(cx, cy - 2.6, 2.6, 2.2), k.mouthTone)
                k.fill(poly([cx - 3.8, cy + 0.6, cx + 3.8, cy + 0.6, cx, cy - 2.2]), peach)
                k.fill(poly([cx - 2.6, cy - 4, cx + 2.6, cy - 4, cx, cy - 6.4]), peach)
            } else {
                let beak = poly([cx - 3.6, cy, cx + 3.6, cy, cx, cy - 3.9])
                k.fill(beak, peach)
                k.stroke(beak, peach, 1.8)
            }
            k.face(cx, 36 + fy, spread: 13, r: 2.7, mouth: .none)
            kawaiiPenguinWear(f, k)
            k.marks(82, 76, 12)
        }
    }

    private static func kawaiiPenguinWear(_ f: FigureFrame, _ k: KawaiiKit) {
        switch f.variant % 5 {
        case 1:
            kawaiiWoodlandBeanie(k, 50, 66, 22, Tone(0xffb3c9), f.twitch)
        case 2:
            k.bow(50, 21, 4.6, Tone(0xffa0b4))
        case 3:
            kawaiiWoodlandMuffs(k, 50, 55, 32, Tone(0xffd0dc), Tone(0xb9a8ec))
        case 4:
            k.flower(70, 66, 5.2, Tone(0xfff6c8), Tone(0xffb36b))
        default:
            break
        }
    }

    static func snowman(_ f: FigureFrame, _ k: KawaiiKit) {
        let snow = f.pick([Tone(0xf7f9ff), Tone(0xfaf7ff), Tone(0xf5fbff), Tone(0xfff9f8), Tone(0xf6fbf8)])
        let scarf = f.pick([Tone(0xff9fb2), Tone(0x9fdfc4), Tone(0xffbf96), Tone(0xa3c9f5), Tone(0xc9b2f1)])
        let twig = Tone(0xbb9c88), carrot = Tone(0xffad78)
        let e = f.energy
        var sx: CGFloat = 1, sy: CGFloat = 1, tilt: CGFloat = 0
        var hx: CGFloat = 1.2 * f.swing * min(e, 1.3), hy: CGFloat = 0, hatY: CGFloat = 0, hatRot: CGFloat = 0, headRot: CGFloat = 0
        var la: CGFloat = 0.35 + 0.12 * f.swing, ra: CGFloat = 0.35 - 0.12 * f.swing + 0.5 * max(0, f.twitch)
        var tail: CGFloat = 0.1 * f.swing
        var fx: CGFloat = 0, fy: CGFloat = 0, stride: CGFloat = 3 * e
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sx = 1.04; sy = 0.93; hx = 2; hy = -3; headRot = -0.12; la = -0.5; ra = -0.5; tail = 0; fy = -1; stride = 0.8
        case .startled:
            sy = 1.06; hy = 4; hatY = 7; hatRot = 0.2; la = 1.1 + 0.1 * f.swing2; ra = 1.1 - 0.1 * f.swing2
        case .fleeing:
            hatY = 4; hatRot = 0.35; la = 0.9 + 0.4 * f.swing; ra = 0.2 - 0.5 * f.swing; tail = -1.2 + 0.15 * f.swing2; fx = 3; stride = 5
        case .dizzy:
            tilt = 0.12 * sin(f.t); headRot = 0.1 * sin(f.t + 1); la = 0.5 + 0.4 * sin(f.t); ra = 0.5 - 0.4 * sin(f.t)
        }
        let upL = max(0, f.swing) * 2.4 * min(e, 1.4)
        let upR = max(0, -f.swing) * 2.4 * min(e, 1.4)
        k.with(about(50, 5, rot: tilt, sx: sx, sy: sy)) {
            let foot = k.shade(snow)
            k.nub(40 - stride * f.swing * 0.4, 6 + upL, 6.5, 3.8, foot)
            k.nub(60 + stride * f.swing * 0.4, 6 + upR, 6.5, 3.8, foot)
            kawaiiSnowmanTwig(k, 28, 32, la, 19, -1, twig)
            kawaiiSnowmanTwig(k, 72, 32, ra, 19, 1, twig)
            k.body(ell(50, 27, 27, 21), snow)
            k.fill(circ(50 + fx * 0.3, 31, 2.4), Tone(0xb7aed6))
            k.fill(circ(50 + fx * 0.3, 20, 2.4), Tone(0xb7aed6))
            k.with(about(50 + hx, 46 + hy, rot: headRot)) {
                let cx = 50 + hx, cy = 62 + hy
                k.body(circ(cx, cy, 18), snow, depth: 0.25)
                k.shine(cx - 9, cy + 9, 3.6, 2.2)
                k.face(cx + fx, cy - 3 + fy, spread: 7.5, r: 2.5, mouth: .none)
                k.mouth(cx + fx, cy - 10 + fy, 4.6, kind: .smile)
                let nx = cx + fx, ny = cy - 6.5 + fy
                let nose = poly([nx - 1, ny + 1.8, nx - 1, ny - 1.8, nx + 9, ny - 0.4])
                k.fill(nose, carrot)
                k.stroke(nose, carrot, 1.4)
                kawaiiSnowmanHat(f, k, cx, cy + 18, hatY, hatRot)
            }
            k.fill(ell(50 + hx * 0.5, 46, 18.5, 4.4), scarf)
            k.with(about(38, 45, rot: tail)) {
                k.fill(rrect(33.5, 30, 8, 16, 4), scarf.dim(0.95))
                k.fill(rrect(33.5, 30, 8, 2.5, 1.2), scarf.lift(0.35))
            }
            k.marks(80, 84, 12)
        }
    }

    private static func kawaiiSnowmanTwig(_ k: KawaiiKit, _ x0: CGFloat, _ y0: CGFloat, _ ang: CGFloat, _ len: CGFloat, _ side: CGFloat, _ tone: Tone) {
        let w = k.width(2.6, minPt: 0.9)
        let ca = cos(ang) * side, sa = sin(ang)
        k.stroke(line(x0, y0, x0 + ca * len, y0 + sa * len), tone, w)
        let mx = x0 + ca * len * 0.62, my = y0 + sa * len * 0.62
        let fa = ang + 0.75
        k.stroke(line(mx, my, mx + cos(fa) * side * len * 0.36, my + sin(fa) * len * 0.36), tone, w * 0.85)
    }

    private static func kawaiiSnowmanHat(_ f: FigureFrame, _ k: KawaiiKit, _ x: CGFloat, _ top: CGFloat, _ lift: CGFloat, _ rot: CGFloat) {
        let y = top + lift
        k.with(about(x, y, rot: rot)) {
            switch f.variant % 5 {
            case 0:
                let hat = Tone(0xa59fd0)
                k.fill(rrect(x - 10, y - 2, 20, 17, 3.5), hat)
                k.fill(rrect(x - 10, y + 0.8, 20, 4, 0), Tone(0xffa8bc))
                k.fill(ell(x, y - 1.5, 16, 3.4), hat.dim(0.95))
                k.shine(x - 5.5, y + 10, 1.6, 2.6, 0)
            case 1:
                kawaiiWoodlandBeanie(k, x, y - 5, 16.5, Tone(0xffb3c9), f.twitch)
            case 2:
                kawaiiWoodlandMuffs(k, x, y - 17, 17, Tone(0xffe0b8), Tone(0xffb894))
            case 3:
                kawaiiWoodlandHolly(k, x + 8, y - 3, 7)
            default:
                k.bow(x - 8, y - 3, 5, Tone(0xc9b2f1), 0.3)
            }
        }
    }

    static func snowflake(_ f: FigureFrame, _ k: KawaiiKit) {
        let ice = f.pick([Tone(0xcfe5ff), Tone(0xdcd3ff), Tone(0xc6eee2), Tone(0xffd5e6), Tone(0xe2ecff)])
        let core = ice.lift(0.6)
        let tipKind = f.pick([0, 1, 2, 0, 3])
        let e = f.energy
        var spin: CGFloat = 0.1 * sin(f.t), reach: CGFloat = 38, sx: CGFloat = 1, sy: CGFloat = 1, shear: CGFloat = 0
        var fx: CGFloat = 0, fy: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            reach = 33; sy = 0.95; spin = 0.03 * sin(f.t); fy = -1
        case .startled:
            reach = 43; sx = 1.03; sy = 1.05
        case .fleeing:
            shear = -0.25; fx = 3; spin = 0.12 * f.swing2
        case .dizzy:
            spin = f.t / 3
        }
        let w = k.width(8.5, minPt: 1.7)
        let bw = k.width(5, minPt: 1.1)
        let tipTone = ice.mix(.white, 0.25)
        k.with(kawaiiWoodWarp(50, 50, rot: 0, sx: sx, sy: sy, shear: shear)) {
            let arms = CGMutablePath(), twigs = CGMutablePath()
            for i in 0..<6 {
                let a = spin + CGFloat(i) * .pi / 3 + .pi / 2
                let ca = cos(a), sa = sin(a)
                arms.move(to: pt(50, 50))
                arms.addLine(to: pt(50 + ca * reach, 50 + sa * reach))
                let bx = 50 + ca * reach * 0.6, by = 50 + sa * reach * 0.6
                for s in [-1, 1] as [CGFloat] {
                    let b = a + s * 0.8
                    twigs.move(to: pt(bx, by))
                    twigs.addLine(to: pt(bx + cos(b) * 10, by + sin(b) * 10))
                }
            }
            k.stroke(arms, ice, w)
            k.stroke(twigs, ice, bw)
            for i in 0..<6 {
                let a = spin + CGFloat(i) * .pi / 3 + .pi / 2
                let pulse = 1 + 0.14 * sin(2 * f.t + CGFloat(i) * 2.1) * min(e, 1.3)
                let ex = 50 + cos(a) * reach, ey = 50 + sin(a) * reach
                let r: CGFloat = 5.8 * pulse
                switch tipKind {
                case 1:
                    k.with(about(ex, ey, rot: a + 1.5 * .pi)) { k.fill(heart(ex, ey, r * 1.1), Tone(0xffc2dc)) }
                case 2:
                    k.fill(softStar(ex, ey, r * 1.35, inner: 0.5, spin: a), Tone(0xfff1a8))
                case 3:
                    k.with(about(ex, ey, rot: a)) { k.fill(smooth([ex + r * 1.7, ey, ex, ey + r * 0.85, ex - r * 0.8, ey, ex, ey - r * 0.85], t: 0.3), tipTone) }
                default:
                    k.fill(circ(ex, ey, r), tipTone)
                }
            }
            k.body(circ(50, 50, 20), core, shade: ice.lift(0.25), depth: 0.32)
            k.shine(41, 60, 3.6, 2.2)
            k.face(50 + fx, 47 + fy, spread: 7.5, r: 3.0)
            if f.variant % 5 == 3 {
                k.bow(62, 67, 5.2, Tone(0xa8c4ff), -0.4)
            }
            if f.mood == .calm && f.frameIndex % 8 < 3 {
                let a = spin + CGFloat((f.frameIndex / 8) * 2 + 1) * .pi / 3 + .pi / 2
                let gx = 50 + cos(a) * (reach + 9), gy = 50 + sin(a) * (reach + 9)
                k.fill(star(gx, gy, 4.2, points: 4, inner: 0.3, spin: 0), Tone.white.alpha(0.9))
            }
            k.marks(78, 82, 12)
        }
    }

    static func robin(_ f: FigureFrame, _ k: KawaiiKit) {
        let back = f.pick([Tone(0xd2b09a), Tone(0xbcc3d9), Tone(0xe4c9a8), Tone(0xc8b8d0), Tone(0xc2a494)])
        let breast = f.pick([Tone(0xffa98c), Tone(0xffb2c0), Tone(0xffc29a), Tone(0xffa192), Tone(0xff9c88)])
        let beakT = Tone(0xffd685), legT = Tone(0xe8a68c)
        let air: CGFloat = f.airborne ? sin(f.air * .pi) : 0
        var sx: CGFloat = 1 + 0.12 * f.squat - 0.05 * f.stretch
        var sy: CGFloat = 1 - 0.16 * f.squat + 0.1 * f.stretch
        var tilt: CGFloat = 0, wing: CGFloat = f.airborne ? 0.75 * abs(sin(f.air * .pi * 2)) : 0
        var tail: CGFloat = 0.15 * f.twitch + 0.2 * f.squat, tuft: CGFloat = 0.2 * f.twitch
        var fx: CGFloat = 0, fy: CGFloat = 0
        var open = false
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sx *= 1.08; sy *= 0.9; wing = 0; tail = -0.25; fy = -2.5; tuft = -0.2
        case .startled:
            sx *= 0.95; sy *= 1.07; wing = 1.0 + 0.15 * f.swing2; tuft = 0.35; tail = 0.4; open = true
        case .fleeing:
            wing = 0.55 + 0.45 * f.swing2; tail = -0.35; fx = 2.5
        case .dizzy:
            tilt = 0.12 * sin(f.t)
        }
        let v = f.variant % 5
        k.with(about(50, 4, rot: tilt, sx: sx, sy: sy)) {
            let leg = 6.5 - 3.5 * air
            let lw = k.width(1.7, minPt: 0.7)
            for lx in [43, 55] as [CGFloat] {
                k.stroke(line(lx, 11, lx - 0.5, 11 - leg), legT, lw)
                k.stroke(line(lx - 0.5, 11 - leg, lx + 3, 11 - leg), legT, lw)
            }
            k.with(about(26, 40, rot: tail)) {
                k.fill(smooth([28, 45, 9, 59, 4, 53, 6, 46, 26, 36], t: 0.6), back.dim(0.93))
            }
            if v != 1 {
                k.with(about(46, 62, rot: tuft)) {
                    k.nub(44, 66, 3, 5.2, back, 0.4)
                    k.nub(49.5, 66.5, 2.6, 4.4, back, -0.25)
                }
            }
            let body = ell(48, 36, 29, 28)
            k.body(body, back)
            k.clip(body) { k.body(ell(66, 27, 20, 21), breast, depth: 0.28) }
            k.with(about(44, 42, rot: -wing)) {
                k.nub(37, 35, 12.5, 9, back.dim(0.9), -0.35)
            }
            k.shine(35, 53, 4.5, 2.6)
            k.blush(61 + fx, 36 + fy, 3.4, 2)
            k.blush(77 + fx, 37 + fy, 2.4, 1.6)
            k.eye(64 + fx, 41 + fy, 2.5, side: -1)
            k.eye(74 + fx, 42 + fy, 2.5, side: 1)
            let bx = 76.5 + fx * 0.4, by = 37.5 + fy * 0.5
            if open {
                k.fill(poly([bx, by + 4.5, bx + 9, by + 3, bx, by + 0.8]), beakT)
                k.fill(poly([bx, by - 0.8, bx + 7, by - 2.4, bx, by - 4]), beakT)
            } else {
                let beak = poly([bx, by + 3, bx + 9.5, by + 0.5, bx, by - 3])
                k.fill(beak, beakT)
                k.stroke(beak, beakT, 1.3)
                if v == 2 {
                    k.fill(circ(bx + 10, by - 2, 3.6), Tone(0xff8f9f))
                    k.nub(bx + 12, by + 2, 2.8, 1.4, Tone(0x9fd8a8), 0.6)
                    k.shine(bx + 9, by - 1, 1.1, 0.8)
                }
            }
            switch v {
            case 1:
                kawaiiWoodlandBeanie(k, 47, 57, 15, Tone(0xffb3c9), f.twitch, -0.12)
            case 3:
                kawaiiWoodlandHolly(k, 40, 62, 6.5)
            case 4:
                k.bow(55, 62, 4.6, Tone(0xbfe0ff), -0.25)
            default:
                break
            }
            k.marks(82, 70, 12)
        }
    }

    static func cloud(_ f: FigureFrame, _ k: KawaiiKit) {
        let base = f.pick([Tone(0xf5f2ff), Tone(0xd9e0f2), Tone(0xffe2ec), Tone(0xeef5ff), Tone(0xffe8d6)])
        let e = f.energy, t = f.t
        var sx: CGFloat = 1, sy: CGFloat = 1, tilt: CGFloat = 0, puff: CGFloat = 1.3 * min(e, 1.3), trail: CGFloat = 0
        var al: CGFloat = 32 + 2 * f.swing, ar: CGFloat = 32 - 2 * f.swing + 5 * max(0, f.twitch)
        var fx: CGFloat = 0, fy: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sx = 1.05; sy = 0.88; puff = 0.5; al = 26; ar = 26; fy = -1
        case .startled:
            sx = 1.04; sy = 1.08; puff = 2; al = 46; ar = 46
        case .fleeing:
            trail = 7; al = 40 + 3 * f.swing2; ar = 28 - 3 * f.swing2; fx = 3
        case .dizzy:
            tilt = 0.12 * sin(f.t)
        }
        let v = f.variant % 5
        k.with(about(50, 40, rot: tilt, sx: sx, sy: sy)) {
            if v == 2 {
                let bands: [Tone] = [Tone(0xffb3c6), Tone(0xffe39a), Tone(0xa9e3c0), Tone(0xaed2fa)]
                let bw = k.width(4.6, minPt: 1)
                for (i, c) in bands.enumerated() {
                    let r = 30 - CGFloat(i) * 4.4
                    let p = CGMutablePath()
                    p.addArc(center: pt(62, 50), radius: r, startAngle: 0, endAngle: .pi, clockwise: false)
                    k.stroke(p, c, bw)
                }
            }
            if v == 4 {
                let sun = Tone(0xffe08a)
                for i in 0..<8 {
                    let a = CGFloat(i) * .pi / 4 + t / 8
                    k.stroke(line(76 + cos(a) * 15, 66 + sin(a) * 15, 76 + cos(a) * 19, 66 + sin(a) * 19), sun, k.width(3, minPt: 0.9))
                }
                k.fill(circ(76, 66, 12), sun)
            }
            k.nub(13 - trail * 0.6, al, 5, 4.5, base)
            k.nub(88, ar, 5, 4.5, base)
            let puffs: [(CGFloat, CGFloat, CGFloat)] = [(25, 39, 13.5), (42, 52, 17), (62, 56, 18), (79, 44, 13), (17, 31, 9.5)]
            var shapes: [CGPath] = [ell(50, 32, 37, 11)]
            for (i, p) in puffs.enumerated() {
                let r = p.2 + puff * sin(t + CGFloat(i) * 1.4)
                let x = p.0 - trail * (1 - p.0 / 100)
                shapes.append(circ(x, p.1, r))
            }
            if trail > 0 {
                shapes.append(circ(2 + 1.5 * f.swing, 36, 6 + 0.8 * f.swing2))
                shapes.append(circ(-8 + 2 * f.swing, 39, 3.8))
            }
            let body = kawaiiWoodJoin(shapes)
            k.body(body, base, depth: 0.32)
            k.shine(37, 60, 4.8, 2.7)
            k.face(52 + fx, 35 + fy, spread: 10, r: 2.8)
            switch v {
            case 1:
                for i in 0..<3 {
                    let u = (f.phase + CGFloat(i) * 0.37).truncatingRemainder(dividingBy: 1)
                    k.fill(drop(34 + CGFloat(i) * 16, 16 - u * 16, 3.6), Tone(0x8fc8ff).alpha(1 - u * 0.6))
                }
            case 3:
                for i in 0..<3 {
                    let u = (f.phase + CGFloat(i) * 0.41).truncatingRemainder(dividingBy: 1)
                    let x = 34 + CGFloat(i) * 16 + 2 * sin(f.t * 2 + CGFloat(i))
                    k.fill(softStar(x, 16 - u * 15, 4, points: 6, inner: 0.55, spin: f.t), Tone(0xffffff).alpha(1 - u * 0.5))
                    k.fill(circ(x, 16 - u * 15, 1.3), Tone(0xc9d8ff).alpha(1 - u * 0.5))
                }
            default:
                break
            }
            k.marks(84, 68, 12)
        }
    }

    static func owl(_ f: FigureFrame, _ k: KawaiiKit) {
        let plume = f.pick([Tone(0xcaa78c), Tone(0xeceaf4), Tone(0xbeb3de), Tone(0xf5b9c7), Tone(0xa8d3c3)])
        let disc = f.pick([Tone(0xfff1de), Tone(0xffffff), Tone(0xf6f1ff), Tone(0xfff1f4), Tone(0xf0fff9)])
        let peach = Tone(0xffc58f)
        let air: CGFloat = f.airborne ? sin(f.air * .pi) : 0
        var sx: CGFloat = 1 + 0.12 * f.squat - 0.05 * f.stretch
        var sy: CGFloat = 1 - 0.16 * f.squat + 0.1 * f.stretch
        var tilt: CGFloat = 0, wing: CGFloat = f.airborne ? 0.9 * abs(sin(f.air * .pi * 2)) : 0
        var tuftRot: CGFloat = 0.12 * f.twitch, tuftLen: CGFloat = 1, head: CGFloat = 0
        var fx: CGFloat = 0, fy: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sx *= 1.06; sy *= 0.9; tuftRot = 0.35; head = -0.08; wing = 0; fy = -1
        case .startled:
            sx *= 0.95; sy *= 1.08; tuftLen = 1.3; tuftRot = -0.1; wing = 1.1 + 0.1 * f.swing2; fy = 1
        case .fleeing:
            wing = 0.6 + 0.4 * f.swing2; tuftRot = 0.3; fx = 2.5
        case .dizzy:
            tilt = 0.12 * sin(f.t); head = 0.1 * sin(f.t + 1)
        }
        let v = f.variant % 5
        k.with(about(50, 5, rot: tilt, sx: sx, sy: sy)) {
            k.nub(41, 6 + 3 * air, 5.5, 3.4, peach)
            k.nub(59, 6 + 3 * air, 5.5, 3.4, peach)
            let wt = k.shade(plume)
            k.with(about(24, 50, rot: -wing)) { k.nub(19, 35, 8, 15, wt, 0.15) }
            k.with(about(76, 50, rot: wing)) { k.nub(81, 35, 8, 15, wt, -0.15) }
            k.with(about(50, 50, rot: head)) {
                let th = 14 * tuftLen
                k.with(about(31, 64, rot: tuftRot)) {
                    k.fill(smooth([23, 60, 25, 66 + th, 41, 67], t: 0.5), plume)
                }
                k.with(about(69, 64, rot: -tuftRot)) {
                    k.fill(smooth([77, 60, 75, 66 + th, 59, 67], t: 0.5), plume)
                }
            }
            k.body(ell(50, 40, 31, 34), plume)
            let belly = disc.mix(plume, 0.3)
            k.fill(ell(50, 20, 18, 13), belly)
            k.shine(29, 56, 3.8, 2.2)
            k.with(about(50, 50, rot: head)) {
                k.fill(kawaiiWoodJoin([circ(39, 47, 12.5), circ(61, 47, 12.5)]), disc)
                k.blush(29 + fx * 0.5, 38 + fy, 3.8, 2.2)
                k.blush(71 + fx * 0.5, 38 + fy, 3.8, 2.2)
                k.eye(39 + fx, 47 + fy, 3.2, side: -1)
                k.eye(61 + fx, 47 + fy, 3.2, side: 1)
                let bx = 50 + fx * 0.6, by = 40.5 + fy
                k.fill(smooth([bx, by + 4, bx + 3.4, by, bx, by - 4.2, bx - 3.4, by], t: 0.4), peach)
                kawaiiOwlHat(v, k, f.twitch)
            }
            k.marks(82, 84, 12)
        }
    }

    private static func kawaiiOwlHat(_ v: Int, _ k: KawaiiKit, _ twitch: CGFloat) {
        switch v {
        case 2:
            let cap = Tone(0xa9b8f0)
            k.fill(smooth([30, 69, 70, 69, 70, 78, 84, 84 + twitch, 60, 85, 38, 80], t: 0.6), cap)
            k.fill(ell(50, 69.5, 21, 4.2), Tone(0xfff6fb))
            k.fill(circ(85, 83 + twitch, 4.2), Tone(0xfff6fb))
        case 3:
            k.bow(67, 75, 4.8, Tone(0xb8a4f0), -0.35)
        case 4:
            let ink = Tone(0x8d93c4)
            k.fill(ell(50, 73, 14, 4.5), ink.dim(0.92))
            k.fill(poly([27, 79, 50, 85.5, 73, 79, 50, 72.5]), ink)
            let tw = k.width(1.6, minPt: 0.6)
            k.stroke(poly([50, 79, 66, 79.5, 67 + twitch, 71], closed: false), Tone(0xffe08a), tw)
            k.fill(circ(67 + twitch, 70, 2.2), Tone(0xffe08a))
        default:
            break
        }
    }

    private static func kawaiiWoodJoin(_ ps: [CGPath]) -> CGPath {
        let m = CGMutablePath()
        for p in ps { m.addPath(p) }
        return m
    }

    private static func kawaiiWoodWarp(_ x: CGFloat, _ y: CGFloat, rot: CGFloat, sx: CGFloat, sy: CGFloat, shear: CGFloat) -> CGAffineTransform {
        let m = CGAffineTransform(a: sx, b: 0, c: shear, d: sy, tx: 0, ty: 0)
        let base = CGAffineTransform(translationX: x, y: y).rotated(by: rot)
        return CGAffineTransform(translationX: -x, y: -y).concatenating(m).concatenating(base)
    }

    private static func kawaiiWoodlandBeanie(_ k: KawaiiKit, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ tone: Tone, _ bob: CGFloat, _ rot: CGFloat = 0) {
        k.with(about(x, y, rot: rot)) {
            let h = w * 0.8
            k.clip(rrect(x - w - 2, y, 2 * w + 4, h + 2, 0)) { k.fill(ell(x, y, w, h), tone) }
            k.fill(rrect(x - w - 1.5, y - w * 0.2, 2 * w + 3, w * 0.42, w * 0.21), tone.lift(0.3))
            k.fill(circ(x + bob * 0.8, y + h + w * 0.2, w * 0.3), Tone(0xfffaf6))
        }
    }

    private static func kawaiiWoodlandMuffs(_ k: KawaiiKit, _ x: CGFloat, _ y: CGFloat, _ half: CGFloat, _ fluff: Tone, _ band: Tone) {
        k.stroke(arc(x - half, y + 2, x + half, y + 2, dip: -half * 0.95), band, k.width(3.2, minPt: 0.9))
        k.fill(circ(x - half, y, 6.5), fluff)
        k.fill(circ(x + half, y, 6.5), fluff)
    }

    private static func kawaiiWoodlandHolly(_ k: KawaiiKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        let green = Tone(0x9fd8a8)
        k.nub(x - s * 0.55, y + s * 0.1, s * 0.7, s * 0.32, green, 0.45)
        k.nub(x + s * 0.55, y + s * 0.1, s * 0.7, s * 0.32, green, -0.45)
        k.fill(circ(x - s * 0.2, y - s * 0.15, s * 0.3), Tone(0xff8f9f))
        k.fill(circ(x + s * 0.22, y - s * 0.08, s * 0.3), Tone(0xff8f9f))
    }
}
