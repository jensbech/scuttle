import Foundation
import CoreGraphics
import ScuttleCore

extension HoseArt {
    private typealias HoseHand = (x: CGFloat, y: CGFloat, open: Bool)

    private static func hoseWoodArm(_ k: HoseKit, _ sx: CGFloat, _ sy: CGFloat, _ h: HoseHand, sag: CGFloat, s: CGFloat = 1, twist: CGFloat = 0) {
        let b = k.bend(sx, sy, h.x, h.y, sag: sag)
        k.noodle(b)
        let a = atan2(-(h.x - b[2]), h.y - b[3]) + twist
        if h.open { k.glove(h.x, h.y, a, s) } else { k.fist(h.x, h.y, a, s) }
    }

    private static func hoseWoodWalk(_ f: FigureFrame, _ k: HoseKit, hips: [CGFloat], hipY: CGFloat, body: CGAffineTransform, color: Tone, reach: CGFloat, lift: CGFloat, sag: CGFloat = 3, splay: CGFloat = 0, rise: CGFloat = 0) {
        for which in 0..<2 {
            let s = k.step(which, reach: reach, lift: lift)
            let h = CGPoint(x: hips[which], y: hipY).applying(body)
            let side: CGFloat = which == 0 ? -1 : 1
            let fx = hips[which] + s.x + side * splay
            let fy = 4 + s.y + rise
            k.noodle(k.bend(h.x, h.y, fx, fy + 5, sag: sag))
            k.boot(fx, fy, s.x * 0.03 + (rise > 0 ? side * 0.25 : 0), color: color)
        }
    }

    private static func hoseWoodHop(_ f: FigureFrame, _ k: HoseKit, hips: [CGFloat], hipY: CGFloat, color: Tone, splay: CGFloat = 2) {
        let tuck = sin(f.air * .pi) * 5 * min(1.2, f.energy)
        for (i, hx) in hips.enumerated() {
            let side: CGFloat = i == 0 ? -1 : 1
            let fx = hx + side * splay - tuck * 0.5
            let fy = 4 + tuck
            k.noodle(k.bend(hx, hipY, fx, fy + 5, sag: 2.5))
            k.boot(fx, fy, -0.12 * f.stretch + side * 0.06, color: color)
        }
    }

    private static func hoseWoodBlob(_ k: HoseKit, _ parts: [CGPath], _ tone: Tone) {
        for p in parts { k.stroke(p, k.ink, k.line) }
        for p in parts { k.fill(p, tone) }
    }

    private static func hoseWoodBowtie(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ tone: Tone) {
        k.part(poly([x, y, x - 7 * s, y + 4.5 * s, x - 7 * s, y - 4.5 * s]), tone)
        k.part(poly([x, y, x + 7 * s, y + 4.5 * s, x + 7 * s, y - 4.5 * s]), tone)
        k.part(circ(x, y, 2.4 * s), tone)
    }

    private static func hoseWoodTopHat(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, rot: CGFloat, band: Tone) {
        k.with(about(x, y, rot: rot, sx: s, sy: s)) {
            let crown = rrect(x - 9, y, 18, 15, 2)
            k.solid(crown)
            k.clip(crown) { k.fill(rrect(x - 10, y + 1.5, 20, 4.5, 0), band) }
            k.solid(ell(x, y + 0.5, 14, 3.2))
            k.shine(x - 5, y + 10, 1.3, 3, 0)
        }
    }

    static func hedgehog(_ f: FigureFrame, _ k: HoseKit) {
        let v = f.variant % 5
        let boot = f.pick([k.red, k.accents[1], k.accents[2], k.accents[3], k.accents[4]])
        var rot: CGFloat = 0, sx: CGFloat = 1, sy: CGFloat = 1
        var spikeBack: CGFloat = 0, spikeLen: CGFloat = 0, faceX: CGFloat = 0
        var reach = 9 * f.energy, lift = 5 * f.energy, splay: CGFloat = 0, rise: CGFloat = 0
        var near: HoseHand = (74 + 6 * f.swing, 17, true)
        var far: HoseHand = (68 - 6 * f.swing, 21, true)
        var twist: CGFloat = 0
        switch f.mood {
        case .calm:
            if f.twitch != 0 {
                near = (84, 44, true)
                twist = 0.35 * f.twitch
            }
        case .sleepy:
            sx = 1.05
            sy = 0.9
            near = (68, 13, true)
            far = (62, 14, true)
        case .startled:
            sy = 1.06
            spikeLen = 5
            reach = 2
            rise = 3
            splay = 3
            near = (96, 28, true)
            far = (50, 92, true)
        case .fleeing:
            spikeBack = 7
            faceX = 2.5
            reach = 13
            lift = 8
            near = (90, 22 + 5 * f.swing, false)
            far = (40, 90 - 3 * f.swing, true)
        case .dizzy:
            rot = 0.12 * sin(f.t)
            reach = 3
            splay = -2
            near = (88, 24 + 4 * f.swing, true)
            far = (60, 10 - 3 * f.swing, true)
        }
        let bob = 1.6 * (1 - f.bounce) * min(1.2, f.energy)
        let T = about(50, 20, rot: rot, sx: sx, sy: sy).concatenating(CGAffineTransform(translationX: 0, y: bob))
        hoseWoodWalk(f, k, hips: [42, 56], hipY: 24, body: T, color: boot, reach: reach, lift: lift, splay: splay, rise: rise)
        k.with(T) {
            hoseWoodArm(k, 54, 36, far, sag: -3, s: 0.9)
            var pts = spikeRing(44, 42, rx: 22, ry: 20, trx: 33 + spikeLen, try_: 31 + spikeLen, from: 0.4 * .pi, to: 1.33 * .pi, n: 6)
            for i in pts.indices where i % 2 == 1 {
                pts[i].x -= spikeBack
                pts[i].y += spikeBack * 0.15
            }
            pts.append(contentsOf: P([42, 21, 58, 21]))
            k.solid(polyP(pts))
            k.shine(34, 52, 1.2, 2.8, 0.6)
            if v == 1 {
                k.part(circ(31, 63, 7.5), k.red)
                k.stroke(line(32, 70, 34, 75), k.ink, k.line)
                k.part(ell(38, 74, 4.2, 2.2, 0.5), k.accents[1])
                k.shine(28.5, 65, 1.6, 2.4, 0.5)
            } else if v == 4 {
                hoseWoodFlower(k, 32, 64, 1, k.accents[4])
            }
            k.part(ell(55, 30, 10.5, 11), k.cream)
            let head = smooth([48, 44, 51, 58, 61, 66, 73, 64, 83, 55, 93, 47, 88, 39, 74, 36, 58, 36])
            k.part(head, k.cream)
            k.solid(circ(92 + faceX * 0.5, 46, 4.6))
            k.shine(93.5, 47.5, 1.5, 1.1)
            k.eye(65 + faceX, 53, 3.3, 5.8, look: faceX > 0 ? 1 : 0)
            k.eye(74 + faceX, 53.5, 3.2, 5.6, look: faceX > 0 ? 1 : 0)
            k.mouth(78 + faceX, 44, 10, 3.4)
            if v == 2 {
                hoseWoodTopHat(k, 66, 61, 0.85, rot: -0.2 - 0.05 * f.swing, band: k.accents[2])
            } else if v == 3 {
                hoseWoodBowtie(k, 58, 38, 1.1, k.red)
            }
            hoseWoodArm(k, 61, 30, near, sag: 3, twist: twist)
            k.marks(f.mood == .fleeing ? 60 : 82, 72, 12)
        }
    }

    private static func hoseWoodFlower(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ tone: Tone) {
        for i in 0..<5 {
            let a = CGFloat(i) * 2 * .pi / 5 + 0.3
            k.part(ell(x + cos(a) * 4.6 * s, y + sin(a) * 4.6 * s, 3.4 * s, 3.4 * s), tone)
        }
        k.part(circ(x, y, 2.8 * s), k.cream)
    }

    static func acorn(_ f: FigureFrame, _ k: HoseKit) {
        let v = f.variant % 5
        let nut = k.cream
        let cap = v == 2 ? k.red : k.ink
        var rot: CGFloat = 0.04 * f.stretch, capUp: CGFloat = 2 * sin(f.air * .pi), capRot: CGFloat = -0.12
        var faceX: CGFloat = 0
        let armUp = sin(f.air * .pi)
        var lh: HoseHand = (22, 30 + 14 * armUp - 4 * f.squat, true)
        var rh: HoseHand = (80, 30 + 14 * armUp - 4 * f.squat, true)
        switch f.mood {
        case .calm:
            rh.y += 5 * max(0, f.twitch)
        case .sleepy:
            capUp = -4
            capRot = -0.25
            lh = (26, 18, true)
            rh = (74, 18, true)
        case .startled:
            capUp = 12
            capRot = -0.35
            lh = (16, 62, true)
            rh = (86, 62, true)
        case .fleeing:
            faceX = 2.5
            capRot = 0.2
            lh = (10, 46 + 5 * f.swing, true)
            rh = (88, 40 - 5 * f.swing, false)
        case .dizzy:
            rot = 0.12 * sin(f.t)
            capRot = -0.12 + 0.25 * sin(f.t + 1)
            lh = (18, 22 + 4 * f.swing, true)
            rh = (84, 22 - 4 * f.swing, true)
        }
        let sq = 1 - 0.16 * f.squat + 0.1 * f.stretch
        k.with(about(50, 4, rot: rot, sx: 1 / sqrt(sq), sy: sq)) {
            hoseWoodHop(f, k, hips: [43, 57], hipY: 16, color: v == 3 ? k.accents[3] : (v == 4 ? k.accents[4] : k.red), splay: 2)
            hoseWoodArm(k, 34, 32, lh, sag: -3, s: 0.95)
            hoseWoodArm(k, 66, 32, rh, sag: 3, s: 0.95)
            let body = smooth([50, 9, 58, 13, 67, 24, 70, 38, 66, 50, 34, 50, 30, 38, 33, 24, 42, 13], t: 0.9)
            k.part(body, nut)
            k.eye(49 + faceX, 37, 2.8, 4.7, look: faceX > 0 ? 1 : 0)
            k.eye(58 + faceX, 37, 2.8, 4.7, look: faceX > 0 ? 1 : 0)
            k.mouth(54 + faceX, 29, 10, 3.2)
            if v == 3 {
                hoseWoodBowtie(k, 52 + faceX, 19, 0.85, k.accents[3])
            }
            k.with(about(50, 50 + capUp, rot: capRot)) {
                let y0 = 50 + capUp
                let capShape = hoseWoodAcornCap(y0)
                k.stroke(smooth([50, y0 + 16, 50, y0 + 22, 55, y0 + 25], closed: false), k.ink, k.limb * 1.3)
                if cap == k.ink { k.solid(capShape) } else { k.part(capShape, cap) }
                let tex = cap == k.ink ? k.cream.alpha(0.9) : k.ink
                for (x, y) in [(40.0, 8.0), (50.0, 9.5), (60.0, 8.0), (45.0, 13.5), (55.0, 13.5)] as [(CGFloat, CGFloat)] {
                    k.stroke(arc(x - 2.6, y0 + y, x + 2.6, y0 + y, dip: 1.8), tex, k.line * 0.6)
                }
                if v == 1 {
                    k.part(smooth([54, y0 + 24, 62, y0 + 30, 72, y0 + 27, 63, y0 + 21], t: 0.7), k.accents[1])
                } else if v == 4 {
                    let pink = k.accents[4]
                    k.part(poly([55, y0 + 23, 47, y0 + 29, 48, y0 + 18]), pink)
                    k.part(poly([55, y0 + 23, 63, y0 + 29, 62, y0 + 18]), pink)
                    k.part(circ(55, y0 + 23, 2.6), pink)
                }
            }
            k.marks(f.mood == .fleeing ? 30 : 76, 66, 12)
        }
    }

    private static func hoseWoodAcornCap(_ y0: CGFloat) -> CGPath {
        var a: [CGFloat] = [72, y0 + 4, 70, y0 + 12, 60, y0 + 17, 50, y0 + 18, 40, y0 + 17, 30, y0 + 12, 28, y0 + 4]
        for i in 0..<5 {
            let x0 = 28 + CGFloat(i) * 8.8
            a.append(contentsOf: [x0 + 4.4, y0 - 2.6, x0 + 8.8, y0 + 0.6])
        }
        a.removeLast(2)
        return smooth(a, t: 0.75)
    }

    static func toadstool(_ f: FigureFrame, _ k: HoseKit) {
        let v = f.variant % 5
        let capTone = f.pick([k.red, k.accents[2], k.ink, k.accents[1], k.accents[3]])
        let spot = v == 2 ? k.cream : k.cream
        var rot: CGFloat = 0, sy: CGFloat = 1, capRot: CGFloat = -0.06 * f.swing * f.energy, capUp: CGFloat = 0
        var faceX: CGFloat = 0
        var reach = 6 * f.energy, lift = 4 * f.energy, splay: CGFloat = 0, rise: CGFloat = 0
        var lh: HoseHand = (22 - 4 * f.swing, 22, true)
        var rh: HoseHand = (78 + 4 * f.swing, 22, true)
        var twist: CGFloat = 0
        switch f.mood {
        case .calm:
            if f.twitch != 0 {
                rh = (82, 46, true)
                twist = 0.35 * f.twitch
            }
        case .sleepy:
            sy = 0.93
            capUp = -5
            capRot = 0.08
            lh = (30, 14, true)
            rh = (70, 14, true)
        case .startled:
            sy = 1.06
            capUp = 9
            capRot = 0.1
            reach = 2
            rise = 3
            splay = 3
            lh = (14, 54, true)
            rh = (88, 56, true)
        case .fleeing:
            faceX = 2.5
            capRot = 0.22
            reach = 10
            lift = 7
            lh = (24, 70, true)
            rh = (90, 34 + 5 * f.swing, false)
        case .dizzy:
            rot = 0.12 * sin(f.t)
            capRot = 0.18 * sin(f.t + 0.8)
            reach = 3
            splay = -2
            lh = (16, 28 + 4 * f.swing, true)
            rh = (86, 28 - 4 * f.swing, true)
        }
        let bob = 1.6 * (1 - f.bounce) * min(1.2, f.energy)
        let T = about(50, 14, rot: rot, sx: 1 / sy, sy: sy).concatenating(CGAffineTransform(translationX: 0, y: bob))
        hoseWoodWalk(f, k, hips: [44, 56], hipY: 16, body: T, color: v == 2 ? k.red : k.ink, reach: reach, lift: lift, splay: splay, rise: rise)
        k.with(T) {
            if f.mood == .fleeing {
                hoseWoodArm(k, 38, 32, lh, sag: -6, s: 0.9)
            } else {
                hoseWoodArm(k, 37, 30, lh, sag: -3, s: 0.9)
            }
            hoseWoodArm(k, 63, 30, rh, sag: 3, twist: twist)
            let stem = smooth([39, 14, 61, 14, 65, 28, 62, 46, 38, 46, 35, 28])
            k.part(stem, k.cream)
            k.eye(52 + faceX, 36, 2.8, 4.8, look: faceX > 0 ? 1 : 0)
            k.eye(60 + faceX, 36, 2.8, 4.8, look: faceX > 0 ? 1 : 0)
            k.mouth(57 + faceX, 27.5, 10, 3.2)
            if v == 1 { hoseWoodBowtie(k, 52 + faceX, 19.5, 0.85, k.red) }
            k.with(about(50, 46 + capUp, rot: capRot)) {
                let y0 = 46 + capUp
                let capShape = smooth([16, y0, 50, y0 - 3, 84, y0, 82, y0 + 11, 68, y0 + 27, 50, y0 + 31, 32, y0 + 27, 18, y0 + 11])
                if capTone == k.ink { k.solid(capShape) } else { k.part(capShape, capTone) }
                k.clip(capShape) {
                    k.part(circ(50, y0 + 20, 6), spot)
                    k.part(circ(30, y0 + 10, 4.5), spot)
                    k.part(circ(70, y0 + 11, 5), spot)
                    k.part(circ(81, y0 + 3, 3), spot)
                }
                k.stroke(capShape, k.ink, k.line)
                if v == 3 { hoseWoodFlower(k, 64, y0 + 25, 1, k.red) }
                if v == 4 { hoseWoodTopHat(k, 50, y0 + 28, 0.8, rot: 0.15, band: k.red) }
            }
            k.marks(f.mood == .fleeing ? 30 : 82, 76, 12)
        }
    }

    static func leaf(_ f: FigureFrame, _ k: HoseKit) {
        let v = f.variant % 5
        let tone = f.pick([k.red, k.accents[2], k.accents[1], k.ink, k.accents[2]])
        var rot: CGFloat = 0, sx: CGFloat = 1, sy: CGFloat = 1, curl: CGFloat = 0.25 * f.swing
        var faceX: CGFloat = 0, trail: CGFloat = 0
        var lh: HoseHand = (14, 60 + 4 * f.swing, true)
        var rh: HoseHand = (88, 52 - 4 * f.swing, true)
        var twist: CGFloat = 0.25 * f.swing
        switch f.mood {
        case .calm:
            twist += 0.3 * f.twitch
        case .sleepy:
            sx = 1.04
            sy = 0.9
            curl = 0.5
            lh = (22, 34, true)
            rh = (80, 30, true)
        case .startled:
            sx = 0.95
            sy = 1.08
            lh = (12, 82, true)
            rh = (90, 82, true)
        case .fleeing:
            faceX = 2.5
            trail = 6
            curl = -0.4 + 0.2 * f.swing
            lh = (6, 66 + 5 * f.swing, true)
            rh = (92, 62 - 5 * f.swing, false)
        case .dizzy:
            rot = 0.12 * sin(f.t)
            lh = (12, 36 + 5 * f.swing, true)
            rh = (90, 34 - 5 * f.swing, true)
        }
        k.with(about(50, 48, rot: rot, sx: sx, sy: sy)) {
            hoseWoodArm(k, 34, 50, lh, sag: -4, s: 0.95, twist: -twist)
            hoseWoodArm(k, 66, 50, rh, sag: 4, s: 0.95, twist: twist)
            k.with(about(50, 26, rot: curl)) {
                k.noodle([50, 28, 50 - trail * 0.5, 19, 54 - trail, 15, 57 - trail, 18], w: k.limb * 1.2)
            }
            let shape = smooth([50, 25, 57, 29, 72, 22, 68, 36, 88, 45, 79, 52, 87, 67, 70, 64, 67, 77, 58, 72, 50, 92, 42, 72, 33, 77, 30, 64, 13, 67, 21, 52, 12, 45, 32, 36, 28, 22, 43, 29], t: 0.32)
            k.part(shape, tone)
            let vein = tone == k.ink ? k.cream.alpha(0.85) : k.ink
            for (x0, y0, x1, y1) in [(50.0, 64.0, 50.0, 84.0), (61.0, 57.0, 80.0, 63.0), (39.0, 57.0, 20.0, 63.0), (59.0, 43.0, 68.0, 30.0), (41.0, 43.0, 32.0, 30.0)] as [(CGFloat, CGFloat, CGFloat, CGFloat)] {
                k.stroke(line(x0, y0, x1, y1), vein, k.line * 0.7)
            }
            k.part(ell(51 + faceX * 0.4, 52, 14, 12.5), k.cream)
            k.eye(47.5 + faceX, 55, 2.8, 4.6, look: faceX > 0 ? 1 : 0)
            k.eye(55.5 + faceX, 55, 2.8, 4.6, look: faceX > 0 ? 1 : 0)
            k.mouth(52 + faceX, 47, 10, 3.2)
            switch v {
            case 2:
                k.part(ell(30, 69, 6, 5), k.red)
                k.solid(ell(25, 70, 2.6, 2.6))
                k.stroke(line(30, 64, 30, 74), k.ink, k.line * 0.6)
            case 3:
                hoseWoodBowtie(k, 51, 38, 0.7, k.red)
            case 4:
                k.with(about(50, 80, rot: -0.2)) {
                    let beret = smooth([37, 80, 63, 80, 60, 88, 50, 91, 40, 88])
                    k.part(beret, k.red)
                    k.stroke(line(50, 91, 51, 95), k.ink, k.limb)
                }
            default:
                break
            }
            k.marks(f.mood == .fleeing ? 26 : 82, 84, 12)
        }
    }

    static func penguin(_ f: FigureFrame, _ k: HoseKit) {
        let v = f.variant % 5
        let beak = k.accents[2]
        var rot: CGFloat = 0, sx: CGFloat = 1, sy: CGFloat = 1, faceX: CGFloat = 1.5
        var reach = 4.5 * f.energy, lift = 3.5 * f.energy, splay: CGFloat = 0, rise: CGFloat = 0
        var lh: HoseHand = (16, 58 + 3 * f.swing, true)
        var rh: HoseHand = (82, 30 - 3 * f.swing, true)
        var twist: CGFloat = 0
        switch f.mood {
        case .calm:
            lh.y += 5 * max(0, f.twitch)
            twist = 0.35 * f.twitch
        case .sleepy:
            sx = 1.04
            sy = 0.93
            lh = (22, 24, true)
            rh = (78, 24, true)
        case .startled:
            sy = 1.07
            reach = 1.5
            rise = 3
            splay = 3
            lh = (12, 86, true)
            rh = (88, 88, true)
        case .fleeing:
            faceX = 4
            reach = 8
            lift = 6
            lh = (8, 56 - 6 * f.swing, true)
            rh = (92, 52 + 6 * f.swing, false)
        case .dizzy:
            rot = 0.12 * sin(f.t)
            splay = -2
            reach = 2.5
            lh = (10, 40 + 4 * f.swing, true)
            rh = (90, 40 - 4 * f.swing, true)
        }
        let bob = 1.4 * (1 - f.bounce) * min(1.2, f.energy)
        let T = about(50, 14, rot: rot, sx: sx, sy: sy).concatenating(CGAffineTransform(translationX: 0, y: bob))
        hoseWoodWalk(f, k, hips: [43, 57], hipY: 18, body: T, color: v == 4 ? k.red : k.cream, reach: reach, lift: lift, sag: 2, splay: splay, rise: rise)
        k.with(T) {
            hoseWoodArm(k, 31, 50, lh, sag: -3, s: 0.95, twist: twist)
            hoseWoodArm(k, 69, 46, rh, sag: 3, s: 0.95)
            let body = smooth([50, 84, 66, 79, 73, 60, 72, 36, 64, 19, 50, 14, 36, 19, 28, 36, 27, 60, 34, 79])
            k.solid(body)
            k.shine(36, 70, 2, 4.5, 0.4)
            let fx = faceX
            let mask = [circ(44 + fx, 63, 9.2), circ(57 + fx, 63, 9.2), ell(51 + fx * 0.6, 37, 14, 19)]
            hoseWoodBlob(k, mask, k.cream)
            k.eye(45 + fx, 64, 3.4, 5.8, look: fx > 2 ? 1 : 0)
            k.eye(56.5 + fx, 64, 3.4, 5.8, look: fx > 2 ? 1 : 0)
            k.part(smooth([45 + fx, 56.5, 58 + fx, 56.5, 53 + fx, 49.5], t: 0.4), beak)
            hoseWoodPenguinMouth(f, k, 51.5 + fx, 48.5)
            switch v {
            case 1:
                let scarf = k.accents[1]
                k.clip(body) { k.part(rrect(20, 44, 60, 7, 3), scarf) }
                k.part(smooth([62, 48, 68, 47, 70 - (f.mood == .fleeing ? 20 : 0), 34, 64 - (f.mood == .fleeing ? 20 : 0), 34], t: 0.6), scarf)
            case 2:
                hoseWoodTopHat(k, 52, 81, 0.9, rot: -0.15, band: k.red)
                hoseWoodBowtie(k, 51 + fx * 0.6, 43, 1.05, k.red)
            case 3:
                let muff = k.accents[3]
                k.stroke(arc(27, 70, 73, 70, dip: -15), k.ink, k.limb * 1.6)
                k.part(circ(28, 68, 6), muff)
                k.part(circ(72, 68, 6), muff)
                hoseWoodBowtie(k, 51 + fx * 0.6, 43, 1.05, k.red)
            case 4:
                let bow = k.accents[4]
                k.with(about(62, 82, rot: 0.3, sx: 1.5, sy: 1.5)) {
                    k.part(poly([62, 82, 55, 88, 56, 78]), bow)
                    k.part(poly([62, 82, 69, 88, 68, 78]), bow)
                    k.part(circ(62, 82, 2.4), bow)
                }
            default:
                hoseWoodBowtie(k, 51 + fx * 0.6, 43, 1.05, k.red)
            }
            k.marks(f.mood == .fleeing ? 22 : 80, 82, 12)
        }
    }

    private static func hoseWoodPenguinMouth(_ f: FigureFrame, _ k: HoseKit, _ x: CGFloat, _ y: CGFloat) {
        switch f.mood {
        case .startled:
            k.fill(ell(x, y - 1.5, 2.2, 2.6), k.ink)
        case .dizzy:
            k.stroke(wavy(x - 4, y - 1, x + 4, y - 1, waves: 1.5, amp: 0.9, phase: f.t), k.ink, k.line * 0.7)
        default:
            break
        }
    }

    static func snowman(_ f: FigureFrame, _ k: HoseKit) {
        let v = f.variant % 5
        let scarf = f.pick([k.red, k.accents[1], k.accents[2], k.accents[3], k.accents[4]])
        var rot: CGFloat = 0, headRot: CGFloat = 0.04 * f.swing, headUp: CGFloat = 0, hatUp: CGFloat = 0, hatRot: CGFloat = -0.14
        var faceX: CGFloat = 0, tail: CGFloat = 0
        var reach = 6 * f.energy, lift = 4 * f.energy, splay: CGFloat = 0, rise: CGFloat = 0
        var lh: HoseHand = (14 - 3 * f.swing, 36, true)
        var rh: HoseHand = (86 + 3 * f.swing, 34, true)
        var twist: CGFloat = 0
        switch f.mood {
        case .calm:
            if f.twitch != 0 {
                rh = (88, 58, true)
                twist = 0.35 * f.twitch
            }
        case .sleepy:
            headRot = -0.16
            headUp = -1.5
            hatRot = -0.3
            lh = (22, 20, true)
            rh = (78, 20, true)
        case .startled:
            headUp = 6
            hatUp = 9
            hatRot = 0.1
            reach = 2
            rise = 3
            splay = 3
            lh = (12, 62, true)
            rh = (88, 64, true)
        case .fleeing:
            faceX = 3
            tail = 16
            hatRot = 0.3
            reach = 10
            lift = 7
            lh = (8, 52 + 5 * f.swing, true)
            rh = (92, 40 - 5 * f.swing, false)
        case .dizzy:
            rot = 0.1 * sin(f.t)
            headRot = 0.16 * sin(f.t + 1)
            reach = 3
            splay = -2
            lh = (12, 24 + 4 * f.swing, true)
            rh = (88, 24 - 4 * f.swing, true)
        }
        let bob = 1.6 * (1 - f.bounce) * min(1.2, f.energy)
        let T = about(50, 14, rot: rot).concatenating(CGAffineTransform(translationX: 0, y: bob))
        hoseWoodWalk(f, k, hips: [42, 58], hipY: 16, body: T, color: v == 3 ? k.accents[3] : k.red, reach: reach, lift: lift, splay: splay, rise: rise)
        k.with(T) {
            hoseWoodArm(k, 31, 36, lh, sag: -4, s: 0.95)
            if v == 4 { hoseWoodSnowmanBroom(k, rh) }
            hoseWoodArm(k, 69, 37, rh, sag: 4, s: 0.95, twist: twist)
            k.part(ell(50, 30, 22, 18.5), k.cream)
            k.solid(circ(57, 34, 2.4))
            k.solid(circ(58, 24, 2.4))
            k.with(about(52, 48, rot: headRot).concatenating(CGAffineTransform(translationX: 0, y: headUp))) {
                k.part(circ(52, 63, 15.5), k.cream)
                k.eye(49 + faceX, 68, 2.7, 4.6, look: faceX > 0 ? 1 : 0)
                k.eye(58 + faceX, 68, 2.7, 4.6, look: faceX > 0 ? 1 : 0)
                k.part(poly([57 + faceX, 63.5, 57 + faceX, 58.5, 73 + faceX, 60]), k.accents[2], w: k.line * 0.9)
                k.mouth(53 + faceX, 56, 9, 3)
                k.with(CGAffineTransform(translationX: 0, y: hatUp)) {
                    hoseWoodSnowmanHat(k, v, scarf, hatRot)
                }
            }
            k.part(smooth([40, 47, 36, 40 - tail * 0.2, 30 - tail, 34, 34 - tail, 30, 42, 40], t: 0.7), scarf)
            k.part(rrect(35, 43, 34, 7, 3.5), scarf)
            k.marks(f.mood == .fleeing ? 28 : 80, 86, 12)
        }
    }

    private static func hoseWoodSnowmanHat(_ k: HoseKit, _ v: Int, _ tone: Tone, _ rot: CGFloat) {
        switch v {
        case 1:
            k.with(about(52, 76, rot: rot)) {
                let cap = smooth([37, 74, 67, 74, 64, 85, 52, 90, 40, 85], t: 0.8)
                k.part(cap, k.red)
                k.part(rrect(36, 72, 32, 5, 2.5), k.cream)
                k.part(circ(52, 91, 4), k.cream)
            }
        case 2:
            k.with(about(52, 76, rot: rot)) {
                k.solid(smooth([41, 76, 63, 76, 61, 86, 52, 89, 43, 86], t: 0.8))
                k.solid(ell(52, 76, 15, 2.6))
                k.fill(rrect(41.5, 77, 21, 2.6, 1), k.red)
            }
        case 3:
            k.stroke(arc(36, 65, 68, 65, dip: -17), k.ink, k.limb * 1.5)
            k.part(circ(37, 63, 5.5), tone)
            k.part(circ(67, 63, 5.5), tone)
        default:
            hoseWoodTopHat(k, 52, 76, 1, rot: rot, band: k.red)
        }
    }

    private static func hoseWoodSnowmanBroom(_ k: HoseKit, _ h: HoseHand) {
        k.stroke(line(h.x - 4, h.y - 24, h.x + 4, h.y + 26), k.ink, k.limb * 1.5)
        let b = smooth([h.x - 9, h.y - 34, h.x + 1, h.y - 34, h.x - 1, h.y - 22, h.x - 5, h.y - 22], t: 0.5)
        k.part(b, k.accents[2])
        k.stroke(line(h.x - 6, h.y - 33, h.x - 4.5, h.y - 24), k.ink, k.line * 0.5)
        k.stroke(line(h.x - 2, h.y - 33, h.x - 2.5, h.y - 24), k.ink, k.line * 0.5)
    }

    static func snowflake(_ f: FigureFrame, _ k: HoseKit) {
        let v = f.variant % 5
        var spin: CGFloat = 0.2 * sin(f.t), len: CGFloat = 35, sy: CGFloat = 1, faceX: CGFloat = 0
        switch f.mood {
        case .calm:
            spin += 0.08 * f.twitch
        case .sleepy:
            len = 31
            sy = 0.94
            spin = 0.05 * sin(f.t)
        case .startled:
            len = 41
            sy = 1.04
        case .fleeing:
            spin = -f.t / 3
            faceX = 2
        case .dizzy:
            spin = f.t / 3
        }
        let tip = v == 3 ? k.accents[3] : k.cream
        let cx: CGFloat = 50, cy: CGFloat = 50
        let w: CGFloat = 5.5
        let edge = w + 2 * k.line
        var arms: [CGPath] = []
        var tips: [CGPoint] = []
        var gloves: [(CGPoint, CGFloat)] = []
        for i in 0..<6 {
            let a = spin + CGFloat(i) * .pi / 3 + .pi / 6
            let ca = cos(a), sa = sin(a)
            let ex = cx + ca * len, ey = cy + sa * len
            let p = CGMutablePath()
            p.move(to: pt(cx, cy))
            p.addLine(to: pt(ex, ey))
            let bx = cx + ca * len * 0.64, by = cy + sa * len * 0.64
            for s: CGFloat in [-1, 1] {
                let ba = a + s * 0.8
                p.move(to: pt(bx, by))
                p.addLine(to: pt(bx + cos(ba) * len * 0.22, by + sin(ba) * len * 0.22))
            }
            arms.append(p)
            if i == 0 || i == 2 {
                gloves.append((pt(ex, ey), a - .pi / 2))
            } else {
                tips.append(pt(ex, ey))
            }
        }
        k.with(about(cx, cy, sx: 1 / sy, sy: sy)) {
            for p in arms { k.stroke(p, k.ink, edge) }
            for p in arms { k.stroke(p, k.cream, w) }
            for g in gloves { k.glove(g.0.x, g.0.y, g.1, 1) }
            if v == 3 {
                for t in tips { k.part(circ(t.x, t.y, 4.2), tip) }
            }
            k.part(circ(cx, cy, 16.5), k.cream)
            k.eye(46 + faceX, 53, 2.6, 4.4, look: faceX > 0 ? 1 : 0)
            k.eye(54 + faceX, 53, 2.6, 4.4, look: faceX > 0 ? 1 : 0)
            k.mouth(50 + faceX, 45, 9, 3)
            switch v {
            case 1:
                hoseWoodBowtie(k, 50, 35, 0.95, k.red)
            case 2:
                hoseWoodTopHat(k, 52, 63, 0.75, rot: -0.2, band: k.red)
            case 4:
                let bow = k.accents[4]
                k.with(about(58, 65, rot: 0.25, sx: 1.4, sy: 1.4)) {
                    k.part(poly([58, 65, 51, 71, 52, 61]), bow)
                    k.part(poly([58, 65, 65, 71, 64, 61]), bow)
                    k.part(circ(58, 65, 2.3), bow)
                }
            default:
                break
            }
            k.marks(74, 74, 11)
        }
    }

    static func robin(_ f: FigureFrame, _ k: HoseKit) {
        let v = f.variant % 5
        var rot: CGFloat = 0.05 * f.stretch, faceX: CGFloat = 0, tailUp: CGFloat = 0.15 * f.stretch
        let flap = sin(f.air * .pi)
        var wing: HoseHand = (22, 64 + 14 * flap - 8 * f.squat, true)
        var twist: CGFloat = 0
        var tuftRot: CGFloat = 0.25 * f.twitch
        switch f.mood {
        case .calm:
            twist = 0.3 * f.twitch
        case .sleepy:
            wing = (30, 26, true)
            tailUp = -0.25
            tuftRot = -0.5
        case .startled:
            wing = (28, 86, true)
            tailUp = 0.4
            tuftRot = 0.4
        case .fleeing:
            faceX = 2.5
            wing = (8, 60 + 10 * f.swing, true)
            tailUp = -0.2
            tuftRot = 0.7
        case .dizzy:
            rot = 0.12 * sin(f.t)
            wing = (18, 30 + 6 * f.swing, true)
        }
        let sq = 1 - 0.16 * f.squat + 0.1 * f.stretch
        k.with(about(50, 4, rot: rot, sx: 1 / sqrt(sq), sy: sq)) {
            hoseWoodHop(f, k, hips: [44, 56], hipY: 22, color: v == 2 ? k.accents[3] : k.cream, splay: 1.5)
            k.with(about(30, 42, rot: tailUp)) {
                k.solid(smooth([34, 46, 18, 56, 8, 60, 12, 50, 8, 42, 18, 40, 32, 36], t: 0.8))
            }
            let body = ell(52, 42, 24, 22)
            k.solid(body)
            k.clip(body) { k.part(ell(66, 30, 16, 15), k.red) }
            k.stroke(body, k.ink, k.line)
            k.part(ell(64 + faceX * 0.4, 52, 13, 11), k.cream)
            k.with(about(54, 63, rot: tuftRot)) {
                k.stroke(smooth([54, 62, 52, 70, 57, 74, 60, 70], closed: false), k.ink, k.limb)
            }
            k.eye(60 + faceX, 55, 2.7, 4.5, look: faceX > 0 ? 1 : 0)
            k.eye(68 + faceX, 55, 2.7, 4.5, look: faceX > 0 ? 1 : 0)
            k.part(poly([73 + faceX, 51, 73 + faceX, 46, 84 + faceX, 48]), k.accents[2], w: k.line * 0.9)
            hoseWoodPenguinMouth(f, k, 70 + faceX, 46)
            hoseWoodArm(k, 44, 44, wing, sag: -4, s: 0.85, twist: twist)
            switch v {
            case 1:
                k.with(about(56, 62, rot: -0.2)) {
                    let cap = smooth([45, 61, 71, 61, 68, 72, 58, 76, 48, 72], t: 0.8)
                    k.part(cap, k.accents[1])
                    k.part(rrect(44, 59, 28, 5, 2.5), k.cream)
                    k.part(circ(58, 78, 4), k.cream)
                }
            case 3:
                k.part(ell(52, 67, 7, 3.6, 0.5), k.accents[1])
                k.part(ell(63, 67, 7, 3.6, -0.5), k.accents[1])
                k.part(circ(55.5, 64, 3), k.red)
                k.part(circ(60.5, 64.5, 3), k.red)
            case 4:
                let pink = k.accents[4]
                k.with(about(56, 66, rot: 0.25, sx: 1.4, sy: 1.4)) {
                    k.part(poly([56, 66, 49, 72, 50, 62]), pink)
                    k.part(poly([56, 66, 63, 72, 62, 62]), pink)
                    k.part(circ(56, 66, 2.3), pink)
                }
            default:
                break
            }
            k.marks(f.mood == .fleeing ? 30 : 80, 72, 12)
        }
    }

    static func cloud(_ f: FigureFrame, _ k: HoseKit) {
        let v = f.variant % 5
        let storm = v == 1
        var rot: CGFloat = 0, sx: CGFloat = 1, sy: CGFloat = 1, puff: CGFloat = 1.2 * f.swing, trail: CGFloat = 0
        var faceX: CGFloat = 0
        var lh: HoseHand = (10, 40 + 4 * f.swing, true)
        var rh: HoseHand = (90, 38 - 4 * f.swing, true)
        var twist: CGFloat = 0
        switch f.mood {
        case .calm:
            rh.y += 6 * max(0, f.twitch)
            twist = 0.3 * f.twitch
        case .sleepy:
            sx = 1.06
            sy = 0.88
            puff *= 0.4
            lh = (18, 26, true)
            rh = (82, 26, true)
        case .startled:
            sx = 1.05
            sy = 1.1
            lh = (8, 74, true)
            rh = (92, 74, true)
        case .fleeing:
            faceX = 3
            trail = 8
            lh = (6, 58 + 5 * f.swing, true)
            rh = (94, 48 - 5 * f.swing, false)
        case .dizzy:
            rot = 0.1 * sin(f.t)
            lh = (8, 30 + 5 * f.swing, true)
            rh = (92, 30 - 5 * f.swing, true)
        }
        k.with(about(50, 40, rot: rot, sx: sx, sy: sy)) {
            if v == 4 {
                k.with(about(70, 70, rot: f.t / 10)) {
                    k.part(star(70, 70, 20, points: 10, inner: 0.68), k.accents[2])
                }
                k.part(circ(70, 70, 12), k.accents[2])
            }
            if v == 3 { hoseWoodCloudUmbrella(f, k, rh) }
            hoseWoodArm(k, 22, 36, lh, sag: -4, s: 0.95)
            hoseWoodArm(k, 78, 36, rh, sag: 4, s: 0.95, twist: twist)
            if v == 2 {
                for i in 0..<3 {
                    let dx = CGFloat(i) * 14 + 36
                    let fall = CGFloat((f.frameIndex * 2 + i * 5) % 16) / 16
                    k.part(drop(dx, 22 - fall * 14, 2.6), k.accents[3], w: k.line * 0.7)
                }
            }
            if storm {
                let flash = f.frameIndex % 8 < 5 || f.mood == .startled
                if flash {
                    k.part(poly([52, 26, 44, 12, 50, 12, 44, -2, 60, 16, 53, 16, 58, 26]), k.accents[2], w: k.line * 0.8)
                }
            }
            let body = [
                circ(30 - trail, 44, 14 + puff),
                circ(50, 55, 19 - puff * 0.6),
                circ(70, 47, 15 + puff * 0.5),
                rrect(14 - trail, 28, 72 + trail, 22, 11),
            ]
            if trail > 0 {
                let bob = 2 * f.swing
                k.part(circ(4 - trail, 38 + bob, 6), storm ? k.ink : k.cream)
                k.part(circ(-8 - trail, 44 - bob, 3.6), storm ? k.ink : k.cream)
            }
            hoseWoodBlob(k, body, storm ? k.ink : k.cream)
            if storm {
                k.part(ell(54 + faceX * 0.4, 44, 16, 13), k.cream)
            }
            k.eye(49 + faceX, 48, 3, 5, look: faceX > 0 ? 1 : 0)
            k.eye(58 + faceX, 48, 3, 5, look: faceX > 0 ? 1 : 0)
            k.mouth(54 + faceX, 39.5, 11, 3.5)
            k.marks(f.mood == .fleeing ? 26 : 82, 72, 13)
        }
    }

    private static func hoseWoodCloudUmbrella(_ f: FigureFrame, _ k: HoseKit, _ h: HoseHand) {
        let top = CGPoint(x: h.x - 22, y: h.y + 40)
        k.stroke(line(h.x + 1, h.y + 6, top.x, top.y), k.ink, k.limb * 1.2)
        let c = CGMutablePath()
        c.move(to: pt(top.x - 24, top.y - 2))
        c.addCurve(to: pt(top.x + 24, top.y - 2), control1: pt(top.x - 22, top.y + 20), control2: pt(top.x + 22, top.y + 20))
        for i in 0..<4 {
            let x1 = top.x + 24 - CGFloat(i + 1) * 12
            c.addQuadCurve(to: pt(x1, top.y - 2), control: pt(x1 + 6, top.y + 3))
        }
        c.closeSubpath()
        k.part(c, k.red)
        k.stroke(line(top.x, top.y + 13, top.x, top.y + 17), k.ink, k.line)
    }

    static func owl(_ f: FigureFrame, _ k: HoseKit) {
        let v = f.variant % 5
        var rot: CGFloat = 0, faceX: CGFloat = 0, tuft: CGFloat = 0.12 * f.twitch
        let flap = sin(f.air * .pi)
        var lh: HoseHand = (14, 34 + 22 * flap - 4 * f.squat, true)
        var rh: HoseHand = (86, 34 + 22 * flap - 4 * f.squat, true)
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            tuft = -0.3
            lh = (24, 20, true)
            rh = (76, 20, true)
        case .startled:
            tuft = 0.3
            lh = (12, 84, true)
            rh = (88, 84, true)
        case .fleeing:
            faceX = 3
            tuft = -0.35
            lh = (6, 58 + 8 * f.swing, true)
            rh = (94, 50 - 8 * f.swing, false)
        case .dizzy:
            rot = 0.12 * sin(f.t)
            lh = (10, 28 + 5 * f.swing, true)
            rh = (90, 28 - 5 * f.swing, true)
        }
        let sq = 1 - 0.16 * f.squat + 0.1 * f.stretch
        k.with(about(50, 4, rot: rot, sx: 1 / sqrt(sq), sy: sq)) {
            hoseWoodHop(f, k, hips: [42, 58], hipY: 18, color: v == 4 ? k.red : k.accents[2], splay: 2)
            hoseWoodArm(k, 28, 46, lh, sag: -4, s: 0.95)
            hoseWoodArm(k, 72, 46, rh, sag: 4, s: 0.95)
            let lt = CGPoint(x: 28, y: 84).applying(about(36, 74, rot: tuft))
            let rt = CGPoint(x: 72, y: 84).applying(about(64, 74, rot: -tuft))
            let body = smoothP([pt(50, 13), pt(68, 17), pt(76, 36), pt(74, 60), pt(70, 72), rt, pt(60, 75), pt(50, 74), pt(40, 75), lt, pt(30, 72), pt(26, 60), pt(24, 36), pt(32, 17)], t: 0.85)
            k.solid(body)
            k.shine(33, 34, 1.3, 4, 0.2)
            let disc = [circ(40.5 + faceX, 58, 11.5), circ(59.5 + faceX, 58, 11.5)]
            hoseWoodBlob(k, disc, k.cream)
            k.eye(41 + faceX, 59, 3.6, 6, look: faceX > 0 ? 1 : 0)
            k.eye(59 + faceX, 59, 3.6, 6, look: faceX > 0 ? 1 : 0)
            k.part(smooth([44.5 + faceX, 51, 55.5 + faceX, 51, 50 + faceX, 40], t: 0.5), k.accents[2], w: k.line * 0.9)
            hoseWoodPenguinMouth(f, k, 50 + faceX, 37.5)
            switch v {
            case 1:
                hoseWoodBowtie(k, 50, 31, 1.35, k.red)
            case 2:
                k.with(about(50, 74, rot: -0.12)) {
                    k.part(rrect(40, 70, 20, 9, 2), k.red)
                    k.part(poly([50, 74, 74, 80, 50, 87, 26, 80]), k.red)
                    k.stroke(smooth([50, 80, 62, 80, 66, 72], closed: false), k.accents[2], k.line)
                    k.part(circ(66, 70, 2.4), k.accents[2], w: k.line * 0.6)
                }
            case 3:
                k.with(about(50, 72, rot: -0.2)) {
                    let cap = smooth([33, 72, 67, 72, 58, 86, 76, 92, 50, 84], t: 0.7)
                    k.part(cap, k.accents[3])
                    k.part(rrect(32, 69, 36, 5, 2.5), k.cream)
                    k.part(circ(76, 91, 4), k.cream)
                }
            case 4:
                k.part(rrect(30, 40, 40, 6, 3), k.red)
                k.part(smooth([64, 43, 70, 42, 72, 28, 66, 28], t: 0.6), k.red)
            default:
                break
            }
            k.marks(f.mood == .fleeing ? 24 : 82, 84, 12)
        }
    }
}
