import Foundation
import CoreGraphics
import ScuttleCore

extension HoseArt {
    static func ladybird(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t, e = f.energy
        let shell = f.pick([k.red, k.accents[2], k.red, k.accents[4], k.red])
        var rot: CGFloat = 0.035 * sin(t) * min(1.3, e)
        var lift: CGFloat = 0, headDy: CGFloat = 0, faceX: CGFloat = 0
        var reach: CGFloat = 4.5 * e, stepLift: CGFloat = 4 * min(1.3, e)
        var tipL = CGPoint(x: 66 + 2 * f.twitch, y: 59), tipR = CGPoint(x: 84 + 3 * f.twitch, y: 61)
        var hand = (x: CGFloat(95), y: CGFloat(25) + 5 * max(0, f.twitch), a: CGFloat(-1.2) + 0.5 * max(0, f.twitch), open: true)
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            lift = -3
            headDy = -5
            reach = 0
            stepLift = 0
            tipL = CGPoint(x: 80, y: 48)
            tipR = CGPoint(x: 90, y: 45)
            hand = (90, 6, -1.75, true)
        case .startled:
            lift = 6
            headDy = 3
            reach = 2
            tipL = CGPoint(x: 68, y: 66)
            tipR = CGPoint(x: 82, y: 68)
            hand = (92, 50 + 2 * f.swing2, -0.35, true)
        case .fleeing:
            rot = -0.06
            reach = 7.5
            stepLift = 6
            faceX = 2
            tipL = CGPoint(x: 56, y: 52)
            tipR = CGPoint(x: 62, y: 58)
            hand = (96, 30 + 4 * f.swing, -1.5, false)
        case .dizzy:
            rot = 0.12 * sin(t)
            reach = 2
            tipL = CGPoint(x: 64 + 4 * sin(t), y: 58)
            tipR = CGPoint(x: 86 - 4 * sin(t), y: 60)
            hand = (94, 30 + 5 * f.swing, -1.0 + 0.6 * f.swing, true)
        }
        k.with(about(50, 4, rot: rot)) {
            for i in 0..<3 {
                let a = t + CGFloat(i) * 2.1
                let hx: CGFloat = 32 + CGFloat(i) * 14
                let bx = hx + 2 + reach * sin(a)
                let by = 4 + stepLift * max(0, cos(a))
                k.noodle(k.bend(hx, 18 + lift, bx, by + 2, sag: 2), w: k.limb * 0.85)
                meadowBoot(k, bx, by, 0.64, 0, k.red)
            }
            k.with(CGAffineTransform(translationX: 0, y: lift)) {
                k.solid(ell(47, 18, 25, 6))
                let hy = 31 + headDy
                k.noodle([74, hy + 10, 70, hy + 20, tipL.x, tipL.y + headDy], w: k.line)
                k.noodle([79, hy + 11, 80, hy + 21, tipR.x, tipR.y + headDy], w: k.line)
                k.solid(circ(tipL.x, tipL.y + headDy, 2.8))
                k.solid(circ(tipR.x, tipR.y + headDy, 2.8))
                let body = smooth([17, 20, 21, 38, 32, 51, 47, 57, 61, 54, 70, 43, 73, 27, 66, 17, 46, 15, 26, 16])
                k.fill(body, shell)
                k.clip(body) {
                    k.fill(circ(29, 33, 5.2), k.ink)
                    k.fill(circ(45, 46, 5.6), k.ink)
                    k.fill(circ(59, 34, 5.2), k.ink)
                    k.fill(circ(44, 24, 4.4), k.ink)
                }
                k.stroke(smooth([65, 51, 50, 42, 36, 30, 25, 18], closed: false), k.ink, k.line)
                k.stroke(body, k.ink, k.line)
                k.shine(36, 49, 5, 2.4, 0.5)
                k.solid(circ(77, hy, 14))
                k.part(ell(81.5 + faceX * 0.4, hy - 2, 10.5, 11), k.cream)
                k.eye(77.5 + faceX, hy + 3, 2.3, 4.1, look: faceX > 0 ? 1 : 0)
                k.eye(85 + faceX, hy + 3, 2.3, 4.1, look: faceX > 0 ? 1 : 0)
                k.mouth(82 + faceX, hy - 5, 9, 3)
                if f.variant == 2 { meadowTopHat(k, 76, hy + 12, 0.95, 0.22) }
                if f.variant == 3 { meadowBowTie(k, 71, hy + 12, 0.95, k.red, 0.5) }
                k.noodle(k.bend(72, 18 + headDy * 0.5, hand.x, hand.y, sag: f.mood == .startled ? -10 : -3), w: k.limb * 0.85)
                if hand.open { k.glove(hand.x, hand.y, hand.a, 0.68) } else { k.fist(hand.x, hand.y, hand.a, 0.68) }
                if f.variant == 4 { meadowDaisyHeld(k, hand.x, hand.y, hand.a, 0.68) }
                k.marks(f.mood == .fleeing ? 60 : 90, 56 + headDy, 12)
            }
        }
    }

    static func bumblebee(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t
        let coat = f.pick([k.accents[2], k.cream, k.accents[2], k.accents[2], k.accents[2]])
        let buzz: CGFloat = f.frameIndex % 2 == 0 ? 1 : -1
        var rot: CGFloat = 0, sy: CGFloat = 1, faceX: CGFloat = 0
        var wingA: CGFloat = 0.35 * buzz, wingSpread: CGFloat = 0
        var legs = (CGPoint(x: 34 + 2 * f.swing, y: 13), CGPoint(x: 48 + 2 * f.swing, y: 11))
        var hand = (x: CGFloat(86), y: CGFloat(34) + 5 * max(0, f.twitch), a: CGFloat(-1.3) + 0.6 * max(0, f.twitch), open: true)
        var back: (x: CGFloat, y: CGFloat, a: CGFloat)? = nil
        var tipL = CGPoint(x: 58 + 2 * f.twitch, y: 80), tipR = CGPoint(x: 74 + 3 * f.twitch, y: 82)
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            rot = -0.1
            sy = 0.95
            wingA = 0.12 * buzz
            wingSpread = -0.35
            legs = (CGPoint(x: 38, y: 11), CGPoint(x: 50, y: 10))
            hand = (74, 22, -2.6, true)
            tipL = CGPoint(x: 76, y: 74)
            tipR = CGPoint(x: 84, y: 70)
        case .startled:
            sy = 1.07
            wingSpread = 0.3
            legs = (CGPoint(x: 24, y: 14), CGPoint(x: 58, y: 12))
            hand = (86, 76 + 2 * f.swing2, -0.4, true)
            back = (30, 78 - 2 * f.swing2, 0.5)
            tipL = CGPoint(x: 60, y: 86)
            tipR = CGPoint(x: 72, y: 88)
        case .fleeing:
            rot = -0.05
            wingA = 0.5 * buzz
            faceX = 2
            legs = (CGPoint(x: 18 + 3 * f.swing, y: 22), CGPoint(x: 26 - 3 * f.swing, y: 16))
            hand = (88, 40 + 5 * f.swing, -1.6, false)
            tipL = CGPoint(x: 50, y: 74)
            tipR = CGPoint(x: 58, y: 80)
        case .dizzy:
            rot = 0.12 * sin(t)
            legs = (CGPoint(x: 32 + 4 * f.swing, y: 12), CGPoint(x: 50 - 4 * f.swing, y: 12))
            hand = (86, 38 + 5 * f.swing, -1.0 + 0.6 * f.swing, true)
            tipL = CGPoint(x: 56 + 4 * sin(t), y: 80)
            tipR = CGPoint(x: 76 - 4 * sin(t), y: 82)
        }
        k.with(about(50, 46, rot: rot, sx: 1, sy: sy)) {
            meadowWing(k, 46, 60, 1.0 + wingA + wingSpread, 7, 15)
            k.noodle(k.bend(38, 32, legs.0.x, legs.0.y + 2, sag: 2), w: k.limb * 0.8)
            k.noodle(k.bend(48, 31, legs.1.x, legs.1.y + 2, sag: 2), w: k.limb * 0.8)
            meadowBoot(k, legs.0.x, legs.0.y, 0.52, -0.25, k.red)
            meadowBoot(k, legs.1.x, legs.1.y, 0.52, -0.25, k.red)
            if let b = back {
                k.noodle(k.bend(44, 52, b.x, b.y, sag: 3), w: k.limb * 0.85)
                k.glove(b.x, b.y, b.a, 0.66)
            }
            k.solid(poly([22, 50, 12, 45, 22, 41]))
            let body = ell(42, 46, 23, 18)
            k.fill(body, coat)
            k.clip(body) {
                k.fill(xf(rrect(29, 20, 7.5, 60, 0), about(32, 46, rot: -0.15)), k.ink)
                k.fill(xf(rrect(44, 20, 7.5, 60, 0), about(47, 46, rot: -0.15)), k.ink)
                k.fill(rrect(10, 20, 11, 60, 0), k.ink)
            }
            k.stroke(body, k.ink, k.line)
            k.shine(36, 58, 4.5, 2, 0.4)
            let hy: CGFloat = 54
            k.noodle([64, hy + 10, 61, hy + 20, tipL.x, tipL.y], w: k.line)
            k.noodle([70, hy + 11, 71, hy + 21, tipR.x, tipR.y], w: k.line)
            k.solid(circ(tipL.x, tipL.y, 2.8))
            k.solid(circ(tipR.x, tipR.y, 2.8))
            k.solid(circ(68, hy, 14))
            k.part(ell(72.5 + faceX * 0.4, hy - 2, 10.5, 10.5), k.cream)
            k.eye(68.5 + faceX, hy + 2.5, 2.3, 4.1, look: faceX > 0 ? 1 : 0)
            k.eye(76 + faceX, hy + 2.5, 2.3, 4.1, look: faceX > 0 ? 1 : 0)
            k.mouth(73 + faceX, hy - 5.5, 8.5, 3)
            meadowWing(k, 50, 62, 0.35 + wingA + wingSpread * 0.6, 7.5, 16)
            if f.variant == 1 { meadowBowTie(k, 61, 40, 0.9, k.red, 0.4) }
            if f.variant == 2 { meadowTopHat(k, 67, hy + 12, 0.95, 0.18) }
            if f.variant == 4 { meadowBowTie(k, 63, hy + 12, 0.95, k.accents[4], 0.6) }
            k.noodle(k.bend(62, 40, hand.x, hand.y, sag: f.mood == .startled ? -10 : -3), w: k.limb * 0.85)
            if hand.open { k.glove(hand.x, hand.y, hand.a, 0.68) } else { k.fist(hand.x, hand.y, hand.a, 0.68) }
            if f.variant == 3 { meadowDaisyHeld(k, hand.x, hand.y, hand.a, 0.68) }
            k.marks(f.mood == .fleeing ? 50 : 84, 72, 12)
        }
    }

    static func snail(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t, e = f.energy
        let shellTone = f.pick([k.red, k.accents[1], k.accents[2], k.accents[3], k.accents[4]])
        var amp: CGFloat = 3.5 * min(1.4, e)
        var head = CGPoint(x: 78, y: 40)
        var rot: CGFloat = 0, faceX: CGFloat = 0
        var tipL = CGPoint(x: 70 + 2 * f.twitch, y: 66), tipR = CGPoint(x: 86 + 3 * f.twitch, y: 68)
        var hand = (x: CGFloat(96), y: CGFloat(22) + 5 * max(0, f.twitch), a: CGFloat(-1.3) + 0.5 * max(0, f.twitch), open: true)
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            amp = 0.6
            head = CGPoint(x: 70, y: 27)
            tipL = CGPoint(x: 78, y: 40)
            tipR = CGPoint(x: 86, y: 36)
            hand = (82, 6, -1.7, true)
        case .startled:
            amp = 1
            head = CGPoint(x: 80, y: 52)
            tipL = CGPoint(x: 74, y: 80)
            tipR = CGPoint(x: 86, y: 82)
            hand = (94, 58 + 2 * f.swing2, -0.4, true)
        case .fleeing:
            amp = 6
            head = CGPoint(x: 84, y: 37)
            faceX = 2
            tipL = CGPoint(x: 62, y: 56)
            tipR = CGPoint(x: 68, y: 62)
            hand = (98, 24 + 4 * f.swing, -1.5, false)
        case .dizzy:
            rot = 0.12 * sin(t)
            head = CGPoint(x: 78, y: 40)
            tipL = CGPoint(x: 68 + 5 * sin(t), y: 64)
            tipR = CGPoint(x: 88 - 5 * sin(t), y: 66)
            hand = (95, 26 + 5 * f.swing, -1.0 + 0.6 * f.swing, true)
        }
        let hd = amp * sin(t), td = amp * sin(t - 1.5)
        let hx = head.x + hd, hy = head.y
        k.with(about(50, 4, rot: rot)) {
            let foot = smooth([8 + td, 5, 30, 4, 60, 4, 76 + hd, 4, 84 + hd, 9, 80 + hd, 15, 60, 14, 30, 13, 12 + td, 9])
            k.noodle([hx - 3, hy + 9, hx - 7, hy + 19, tipL.x + hd, tipL.y], w: k.line)
            k.noodle([hx + 2, hy + 10, hx + 3, hy + 20, tipR.x + hd, tipR.y], w: k.line)
            k.solid(circ(tipL.x + hd, tipL.y, 2.8))
            k.solid(circ(tipR.x + hd, tipR.y, 2.8))
            let neck = smooth([62 + hd * 0.6, 8, (62 + hx) / 2 + 2, (8 + hy) / 2 - 2, hx, hy], closed: false)
            k.stroke(neck, k.ink, 17)
            k.solid(foot)
            k.solid(circ(hx, hy, 13))
            let sx = 42 + (hd + td) * 0.35
            let shell = circ(sx, 33, 20)
            k.part(shell, shellTone)
            k.stroke(spiral(sx + 1, 32, 14.5, turns: 2.1, spin: 1, start: 2.6), k.ink, k.line)
            k.shine(sx - 9, 45, 4.2, 2.2, 0.6)
            if f.variant == 4 { meadowBowTie(k, sx + 6, 52, 1.0, k.red, -0.3) }
            k.part(ell(hx + 4 + faceX * 0.4, hy - 2, 9.5, 10), k.cream)
            k.eye(hx + 1 + faceX, hy + 2.5, 2.2, 3.9, look: faceX > 0 ? 1 : 0)
            k.eye(hx + 8 + faceX, hy + 2.5, 2.2, 3.9, look: faceX > 0 ? 1 : 0)
            k.mouth(hx + 5 + faceX, hy - 5, 8, 2.8)
            if f.variant == 2 { meadowTopHat(k, hx, hy + 11, 0.9, 0.2) }
            if f.variant == 3 { meadowDaisy(k, sx - 2, 53, 1.3) }
            k.noodle(k.bend(hx + 2, hy - 13, hand.x + hd, hand.y, sag: -3), w: k.limb * 0.8)
            if hand.open { k.glove(hand.x + hd, hand.y, hand.a, 0.62) } else { k.fist(hand.x + hd, hand.y, hand.a, 0.62) }
            k.marks(f.mood == .fleeing ? 62 : hx + 12, hy + 18, 11)
        }
    }

    static func chick(_ f: FigureFrame, _ k: HoseKit) {
        let fluff = f.pick([k.accents[2], k.accents[2], k.accents[2], k.accents[2], k.accents[2]])
        let bootTone = f.pick([k.red, k.red, k.red, k.accents[3], k.red])
        let sq = f.squat, st = f.stretch
        let tuck: CGFloat = f.airborne ? sin(.pi * f.air) : 0
        var sy = 1 - 0.16 * sq + 0.1 * st
        var sx = 1 + 0.1 * sq - 0.05 * st
        var rot: CGFloat = 0, faceX: CGFloat = 0, bodyDy: CGFloat = 0
        let flap = f.airborne ? 10 * sin(f.air * 2 * .pi) : 0
        var back = (x: CGFloat(14), y: CGFloat(56) + 3 * f.swing + flap, a: CGFloat(0.5))
        var front = (x: CGFloat(82), y: CGFloat(28) + 5 * max(0, f.twitch) + flap * 0.6, a: CGFloat(-1.2) + 0.5 * max(0, f.twitch), open: true)
        var feet = (CGPoint(x: 38, y: 4 + 7 * tuck), CGPoint(x: 58, y: 4 + 7 * tuck))
        var curl: CGFloat = 0.25 * f.twitch
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sy *= 0.93
            sx *= 1.04
            bodyDy = -2
            back = (22, 26, 2.6)
            front = (74, 22, -2.6, true)
            curl = -0.5
        case .startled:
            sy *= 1.06
            back = (16, 78 + 2 * f.swing2, 0.35)
            front = (84, 78 - 2 * f.swing2, -0.35, true)
            curl = 0.4
            feet = (CGPoint(x: 34, y: 4 + 7 * tuck), CGPoint(x: 62, y: 4 + 7 * tuck))
        case .fleeing:
            rot = -0.08
            faceX = 2
            back = (10, 44 + 6 * f.swing, 1.9)
            front = (86, 34 - 6 * f.swing, -1.6, false)
            curl = 0.9
            feet = (CGPoint(x: 32, y: 6 + 7 * tuck), CGPoint(x: 62, y: 4 + 9 * tuck))
        case .dizzy:
            rot = 0.12 * sin(f.t)
            back = (14, 50 + 5 * f.swing, 2.2)
            front = (86, 46 - 5 * f.swing, -2.2, true)
            curl = 0.5 * sin(f.t)
        }
        k.with(about(50, 4, rot: rot, sx: sx, sy: sy)) {
            k.noodle(k.bend(44, 22 + bodyDy, feet.0.x, feet.0.y + 3, sag: 3 + 4 * sq))
            k.noodle(k.bend(56, 22 + bodyDy, feet.1.x, feet.1.y + 3, sag: -3 - 4 * sq))
            meadowBoot(k, feet.0.x, feet.0.y, 1, 0.1 * tuck, bootTone)
            meadowBoot(k, feet.1.x, feet.1.y, 1, 0.2 * tuck, bootTone)
            k.with(CGAffineTransform(translationX: 0, y: bodyDy)) {
                k.noodle(k.bend(30, 42, back.x, back.y, sag: 3))
                k.glove(back.x, back.y, back.a, 0.82)
                k.with(about(48, 64, rot: curl)) {
                    k.noodle([47, 64, 44, 72, 38, 75], w: k.limb * 0.9)
                    k.noodle([50, 65, 50, 74, 47, 80], w: k.limb * 0.9)
                    k.noodle([52, 65, 56, 72, 61, 73], w: k.limb * 0.9)
                }
                k.part(smooth([29, 34, 18, 38, 22, 31, 30, 27], t: 0.6), fluff)
                k.part(smooth([50, 68, 66, 63, 73, 46, 70, 28, 58, 18, 42, 18, 30, 28, 27, 46, 34, 63]), fluff)
                k.shine(36, 55, 4.4, 2.2, 0.6)
                if f.variant == 3 { meadowBowTie(k, 42, 66, 1.0, k.accents[3], 0.35) }
                k.part(ell(59 + faceX * 0.4, 47, 12.5, 12), k.cream)
                k.eye(55 + faceX, 51.5, 2.6, 4.4, look: faceX > 0 ? 1 : 0)
                k.eye(63.5 + faceX, 51.5, 2.6, 4.4, look: faceX > 0 ? 1 : 0)
                chickBeak(f, k, 66 + faceX, 42)
                if f.variant == 1 { chickEggCap(k) }
                if f.variant == 2 { meadowBowTie(k, 57, 30, 1.05, k.red) }
                if f.variant == 4 { meadowTopHat(k, 50, 65, 1.1, 0.18) }
                k.noodle(k.bend(66, 32, front.x, front.y, sag: f.mood == .startled ? -12 : -3))
                if front.open { k.glove(front.x, front.y, front.a, 0.8) } else { k.fist(front.x, front.y, front.a, 0.8) }
                k.marks(f.mood == .fleeing ? 26 : 80, 70, 13)
            }
        }
    }

    private static func chickBeak(_ f: FigureFrame, _ k: HoseKit, _ x: CGFloat, _ y: CGFloat) {
        let orange = Tone(0xf2a03a)
        switch f.mood {
        case .startled, .fleeing:
            let gap: CGFloat = f.mood == .startled ? 3.5 : 2.5
            k.part(poly([x, y + 1, x + 11, y + 2.5 + gap * 0.3, x, y + 5]), orange, w: 2.2)
            k.part(poly([x, y - 0.5, x + 9, y - 2 - gap, x, y - 4]), orange, w: 2.2)
            k.fill(poly([x + 0.5, y + 0.8, x + 6, y - 0.5 - gap * 0.4, x + 0.5, y - 0.3]), k.red)
        case .dizzy:
            k.part(poly([x, y + 4, x + 10, y + 1 + 2 * sin(f.t), x, y - 2]), orange, w: 2.2)
        case .sleepy:
            k.part(poly([x, y + 3.5, x + 8, y + 0.5, x, y - 2]), orange, w: 2.2)
        case .calm:
            k.part(smooth([x - 1, y + 5, x + 13, y + 1, x - 1, y - 3], t: 0.3), orange, w: 2.2)
            k.stroke(line(x + 1, y + 1, x + 8, y + 1), k.ink, 1.4)
        }
    }

    private static func chickEggCap(_ k: HoseKit) {
        let cap = smooth([37, 60, 42, 72, 50, 76, 58, 72, 63, 60], closed: false)
        let p = CGMutablePath()
        p.addPath(cap)
        let teeth: [CGFloat] = [63, 60, 59, 64, 55, 59, 51, 64, 47, 59, 43, 64, 37, 60]
        for i in stride(from: 0, to: teeth.count, by: 2) { p.addLine(to: pt(teeth[i], teeth[i + 1])) }
        p.closeSubpath()
        k.with(about(50, 66, rot: 0.18)) {
            k.part(p, k.cream)
        }
    }

    static func butterfly(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t
        let upper = f.pick([k.cream, k.cream, k.accents[2], k.cream, k.cream])
        let spot = f.pick([k.red, k.accents[3], k.red, k.accents[4], k.accents[1]])
        let lower = f.pick([k.red, k.accents[3], k.red, k.accents[4], k.accents[1]])
        var open: CGFloat = 0.38 + 0.62 * (0.5 + 0.5 * f.swing)
        var lift: CGFloat = 0, rot: CGFloat = 0, faceX: CGFloat = 0, raise: CGFloat = 0
        var hand = (x: CGFloat(74), y: CGFloat(70) + 4 * max(0, f.twitch), a: CGFloat(-0.35) - 0.4 * max(0, f.twitch), open: true)
        var curl: CGFloat = 0.15 * f.twitch
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            open = 0.62 + 0.03 * f.swing
            raise = -0.22
            lift = -3
            hand = (60, 30, -2.8, true)
            curl = -0.5
        case .startled:
            open = 1.05
            raise = 0.18
            hand = (76, 86 + 2 * f.swing2, -0.25, true)
            curl = 0.3
        case .fleeing:
            open = 0.3 + 0.75 * (0.5 + 0.5 * sin(2 * t))
            rot = -0.12
            faceX = 2.5
            hand = (78, 56 + 4 * f.swing, -1.2, false)
            curl = -0.6
        case .dizzy:
            rot = 0.12 * sin(t)
            hand = (74, 62 + 6 * f.swing, -0.5 + 0.7 * f.swing, true)
            curl = 0.4 * sin(t)
        }
        k.with(about(50, 48, rot: rot)) {
            k.with(CGAffineTransform(translationX: 0, y: lift)) {
                for s: CGFloat in [-1, 1] {
                    k.with(about(50, 50, rot: -s * raise, sx: open, sy: 1)) {
                        let lw = smooth([48, 46, 42, 32, 33, 21, 22, 22, 18, 32, 28, 43])
                        k.part(s > 0 ? mirror(lw) : lw, lower)
                        let uw = smooth([48, 52, 40, 68, 25, 82, 11, 79, 7, 64, 17, 51, 36, 47])
                        k.part(s > 0 ? mirror(uw) : uw, upper)
                        let sp = circ(24, 66, 6.5)
                        k.part(s > 0 ? mirror(sp) : sp, spot)
                    }
                }
                for s: CGFloat in [-1, 1] {
                    k.with(about(50, 66, rot: s * curl)) {
                        let a = smooth([47, 68, 45, 80, 40, 89, 34, 89, 33, 85], closed: false)
                        k.stroke(s > 0 ? mirror(a) : a, k.ink, k.line)
                        k.solid(s > 0 ? mirror(circ(33.5, 85, 3.2)) : circ(33.5, 85, 3.2))
                    }
                }
                k.solid(ell(50, 40, 6.5, 15))
                k.solid(circ(50, 60, 11.5))
                k.part(ell(51 + faceX * 0.4, 58, 9, 8), k.cream)
                k.eye(47.5 + faceX, 60.5, 2, 3.5, look: faceX > 0 ? 1 : 0)
                k.eye(54.5 + faceX, 60.5, 2, 3.5, look: faceX > 0 ? 1 : 0)
                k.mouth(51 + faceX, 55, 8, 2.7)
                if f.variant == 2 { meadowTopHat(k, 50, 69.5, 0.9, 0.15) }
                if f.variant == 3 { meadowBowTie(k, 42, 70, 0.9, k.red, 0.5) }
                k.noodle(k.bend(55, 47, hand.x, hand.y, sag: 3), w: k.limb * 0.85)
                if hand.open { k.glove(hand.x, hand.y, hand.a, 0.66) } else { k.fist(hand.x, hand.y, hand.a, 0.66) }
                if f.variant == 4 { meadowDaisyHeld(k, hand.x, hand.y, hand.a, 0.66) }
                k.marks(f.mood == .fleeing ? 22 : 80, 82, 12)
            }
        }
    }

    static func dragonfly(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t
        let tailTone = f.pick([k.ink, k.accents[3], k.ink, k.accents[1], k.red])
        let bandTone = f.pick([k.cream, k.ink, k.red, k.ink, k.ink])
        let buzz: CGFloat = f.frameIndex % 2 == 0 ? 1 : -1
        var droop: CGFloat = 0, wiggle: CGFloat = 2, rot: CGFloat = 0, faceX: CGFloat = 0
        var wingA: CGFloat = 0.3 * buzz, spread: CGFloat = 0
        var hand = (x: CGFloat(90), y: CGFloat(38) + 5 * max(0, f.twitch), a: CGFloat(-1.3) + 0.5 * max(0, f.twitch), open: true)
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            droop = -10
            wiggle = 0.5
            wingA = 0.08 * buzz
            spread = 0.5
            rot = -0.06
            hand = (78, 36, -2.7, true)
        case .startled:
            droop = 12
            wiggle = 0.5
            spread = -0.25
            hand = (88, 70 + 2 * f.swing2, -0.35, true)
        case .fleeing:
            wiggle = 3.5
            wingA = 0.45 * buzz
            faceX = 2
            hand = (92, 44 + 4 * f.swing, -1.6, false)
        case .dizzy:
            rot = 0.12 * sin(t)
            droop = 5 * sin(t)
            hand = (90, 42 + 5 * f.swing, -1.0 + 0.6 * f.swing, true)
        }
        k.with(about(50, 50, rot: rot)) {
            dragonflyWing(k, 56, 56, 1.15 + wingA + spread, 0.95)
            dragonflyWing(k, 60, 56, -0.1 + wingA + spread * 0.6, 0.95)
            if f.variant == 2 {
                let wave = 3 * sin(t * 2)
                k.part(smooth([72, 47, 56, 47 + wave, 40, 43 + wave * 1.6, 42, 36 + wave, 56, 40, 72, 41]), k.red)
            }
            var top: [CGPoint] = [], bot: [CGPoint] = []
            for i in 0...6 {
                let u = CGFloat(i) / 6
                let x = 58 - u * 50
                let cy = 50 + droop * u * u + wiggle * sin(t - u * 3) * u
                let w = 4.2 - 1.6 * u
                top.append(pt(x, cy + w))
                bot.append(pt(x, cy - w))
            }
            let tail = smoothP(top + bot.reversed())
            k.fill(tail, tailTone)
            k.clip(tail) {
                for i in 0..<4 {
                    let bx = 46 - CGFloat(i) * 10
                    k.fill(rrect(bx, 20, 3.4, 60, 0), bandTone)
                }
            }
            k.stroke(tail, k.ink, k.line)
            k.solid(ell(66, 50, 11, 8.5))
            k.solid(circ(82, 52, 13.5))
            k.part(ell(85.5 + faceX * 0.4, 50.5, 10.5, 10.5), k.cream)
            k.eye(81.5 + faceX, 55, 2.4, 4.2, look: faceX > 0 ? 1 : 0)
            k.eye(89 + faceX, 55, 2.4, 4.2, look: faceX > 0 ? 1 : 0)
            k.mouth(86 + faceX, 46, 8, 2.8)
            if f.variant == 2 { dragonflyGoggles(k, faceX) }
            if f.variant == 4 { meadowTopHat(k, 81, 64, 0.95, 0.22) }
            if f.variant == 3 { meadowBowTie(k, 73, 41, 0.9, k.red, 0.3) }
            dragonflyWing(k, 58, 57, 0.8 + wingA * 0.8 + spread, 1)
            dragonflyWing(k, 62, 57, -0.4 + wingA * 0.8 + spread * 0.6, 1)
            k.noodle(k.bend(70, 44, hand.x, hand.y, sag: f.mood == .startled ? -9 : -3), w: k.limb * 0.8)
            if hand.open { k.glove(hand.x, hand.y, hand.a, 0.6) } else { k.fist(hand.x, hand.y, hand.a, 0.6) }
            k.marks(f.mood == .fleeing ? 56 : 90, 68, 11)
        }
    }

    private static func dragonflyWing(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, _ a: CGFloat, _ s: CGFloat) {
        k.with(CGAffineTransform(translationX: x, y: y).rotated(by: a).scaledBy(x: s, y: s)) {
            k.part(ell(0, 15, 4.6, 15), k.cream)
        }
    }

    private static func dragonflyGoggles(_ k: HoseKit, _ faceX: CGFloat) {
        k.stroke(arc(69, 60, 95, 60, dip: -5), k.ink, 3)
        for gx: CGFloat in [78, 89] {
            k.part(circ(gx + faceX * 0.3, 65, 5.2), k.accents[2].mix(k.cream, 0.4))
            k.fill(ell(gx - 1.2 + faceX * 0.3, 66.5, 1.6, 1.1, 0.5), Tone.white.alpha(0.8))
        }
    }

    static func firefly(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t
        let glowTone = f.pick([Tone(0xffd84a), Tone(0xa6e35f), Tone(0xffd84a), Tone(0xff9cc4), Tone(0xffd84a)])
        let buzz: CGFloat = f.frameIndex % 2 == 0 ? 1 : -1
        var pulse: CGFloat = 0.6 + 0.4 * sin(2 * t)
        var rot: CGFloat = 0, faceX: CGFloat = 0, wingA: CGFloat = 0.35 * buzz, spread: CGFloat = 0
        var legs = (CGPoint(x: 44 + 2 * f.swing, y: 18), CGPoint(x: 56 + 2 * f.swing, y: 17))
        var hand = (x: CGFloat(88), y: CGFloat(38) + 5 * max(0, f.twitch), a: CGFloat(-1.3) + 0.5 * max(0, f.twitch), open: true)
        var tipL = CGPoint(x: 58 + 2 * f.twitch, y: 86), tipR = CGPoint(x: 80 + 3 * f.twitch, y: 88)
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            pulse = 0.3 + 0.1 * sin(t)
            rot = -0.08
            wingA = 0.1 * buzz
            spread = -0.4
            legs = (CGPoint(x: 46, y: 16), CGPoint(x: 56, y: 15))
            hand = (76, 30, -2.6, true)
            tipL = CGPoint(x: 80, y: 78)
            tipR = CGPoint(x: 90, y: 72)
        case .startled:
            pulse = 1.1
            spread = 0.3
            legs = (CGPoint(x: 36, y: 18), CGPoint(x: 64, y: 16))
            hand = (88, 78 + 2 * f.swing2, -0.35, true)
            tipL = CGPoint(x: 62, y: 92)
            tipR = CGPoint(x: 76, y: 94)
        case .fleeing:
            pulse = 0.8 + 0.2 * sin(4 * t)
            wingA = 0.5 * buzz
            faceX = 2
            legs = (CGPoint(x: 28 + 3 * f.swing, y: 24), CGPoint(x: 36 - 3 * f.swing, y: 19))
            hand = (90, 44 + 5 * f.swing, -1.6, false)
            tipL = CGPoint(x: 48, y: 78)
            tipR = CGPoint(x: 56, y: 84)
        case .dizzy:
            rot = 0.12 * sin(t)
            hand = (88, 42 + 5 * f.swing, -1.0 + 0.6 * f.swing, true)
            tipL = CGPoint(x: 56 + 4 * sin(t), y: 86)
            tipR = CGPoint(x: 82 - 4 * sin(t), y: 88)
        }
        k.with(about(50, 48, rot: rot)) {
            k.glow(25, 40, 17 + 8 * pulse, glowTone, 0.6 * min(1, pulse))
            meadowWing(k, 50, 58, 1.0 + wingA + spread, 6.5, 14)
            k.noodle(k.bend(48, 38, legs.0.x, legs.0.y + 2, sag: 2), w: k.limb * 0.8)
            k.noodle(k.bend(56, 38, legs.1.x, legs.1.y + 2, sag: 2), w: k.limb * 0.8)
            meadowBoot(k, legs.0.x, legs.0.y, 0.5, -0.25, k.cream)
            meadowBoot(k, legs.1.x, legs.1.y, 0.5, -0.25, k.cream)
            let lamp = ell(25, 40, 11.5, 10.5, 0.25)
            k.part(lamp, glowTone.mix(k.cream, 0.15).dim(0.75 + 0.25 * min(1, pulse)))
            k.fill(ell(23, 42, 5.5, 4.5, 0.25), Tone.white.alpha(0.55 * min(1, pulse)))
            k.solid(ell(40, 45, 15, 12, 0.2))
            k.solid(ell(56, 49, 10, 9))
            let hy: CGFloat = 56
            k.noodle([66, hy + 10, 62, hy + 22, tipL.x, tipL.y], w: k.line)
            k.noodle([72, hy + 11, 74, hy + 23, tipR.x, tipR.y], w: k.line)
            k.solid(circ(tipL.x, tipL.y, 2.8))
            k.solid(circ(tipR.x, tipR.y, 2.8))
            k.solid(circ(70, hy, 13.5))
            k.part(ell(74.5 + faceX * 0.4, hy - 2, 10, 10), k.cream)
            k.eye(70.5 + faceX, hy + 2.5, 2.2, 4, look: faceX > 0 ? 1 : 0)
            k.eye(78 + faceX, hy + 2.5, 2.2, 4, look: faceX > 0 ? 1 : 0)
            k.mouth(75 + faceX, hy - 5.5, 8, 2.8)
            meadowWing(k, 54, 60, 0.4 + wingA + spread * 0.6, 7, 15)
            if f.variant == 2 { fireflyNightcap(k, 69, hy + 11) }
            if f.variant == 3 { meadowBowTie(k, 63, hy + 12, 0.95, k.accents[4], 0.6) }
            if f.variant == 4 { meadowTopHat(k, 69, hy + 11.5, 0.95, 0.15) }
            k.noodle(k.bend(62, 44, hand.x, hand.y, sag: f.mood == .startled ? -10 : -3), w: k.limb * 0.85)
            if hand.open { k.glove(hand.x, hand.y, hand.a, 0.66) } else { k.fist(hand.x, hand.y, hand.a, 0.66) }
            k.marks(f.mood == .fleeing ? 50 : 86, 74, 12)
        }
    }

    private static func fireflyNightcap(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat) {
        k.with(about(x, y, rot: 0.25)) {
            let cap = smooth([x - 11, y, x - 6, y + 10, x + 4, y + 14, x + 16, y + 6, x + 11, y + 4, x + 6, y + 0.5], t: 0.7)
            k.part(cap, k.red)
            k.part(rrect(x - 12, y - 2.5, 24, 5, 2.5), k.cream)
            k.part(circ(x + 17, y + 5, 3.2), k.cream)
        }
    }

    static func crab(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t, e = f.energy
        let shellTone = f.pick([k.red, k.red, k.accents[3], k.accents[2], k.red])
        var bob: CGFloat = 1.5 * abs(sin(t)) * min(1.3, e)
        var rot: CGFloat = 0, faceX: CGFloat = 0, legLift: CGFloat = 4 * min(1.4, e)
        var snap: CGFloat = 0.5 + 0.5 * sin(2 * t)
        var clawL = (x: CGFloat(14), y: CGFloat(46) + 2 * f.swing, a: CGFloat(0.3))
        var clawR = (x: CGFloat(86), y: CGFloat(46) - 2 * f.swing + 3 * max(0, f.twitch), a: CGFloat(-0.3))
        var stalk: CGFloat = 0, stalkLen: CGFloat = 14
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            bob = -3
            legLift = 0
            snap = 0
            clawL = (16, 12, 0.9)
            clawR = (84, 12, -0.9)
            stalk = 0.5
            stalkLen = 10
        case .startled:
            bob = 3
            snap = 1
            clawL = (10, 70 + 2 * f.swing2, 0.15)
            clawR = (90, 70 - 2 * f.swing2, -0.15)
            stalkLen = 18
        case .fleeing:
            rot = -0.08
            faceX = 2.5
            legLift = 6
            snap = 0.5 + 0.5 * sin(4 * t)
            clawL = (12, 56 + 5 * f.swing, 0.6)
            clawR = (90, 56 - 5 * f.swing, -0.6)
            stalk = 0.45
        case .dizzy:
            rot = 0.12 * sin(t)
            clawL = (12, 44 + 5 * f.swing, 0.6)
            clawR = (88, 44 - 5 * f.swing, -0.6)
            stalk = 0.35 * sin(t)
        }
        k.with(about(50, 4, rot: rot)) {
            for i in 0..<4 {
                let side: CGFloat = i < 2 ? -1 : 1
                let j = CGFloat(i % 2)
                let a = t + CGFloat(i) * 1.6
                let hx = 50 + side * (14 + 8 * j)
                let fx = 50 + side * (24 + 12 * j) + 1.5 * sin(a)
                let fy = 4 + legLift * max(0, cos(a))
                k.noodle(k.bend(hx, 22 + bob, fx, fy + 2, sag: -side * 4), w: k.limb * 0.8)
                meadowBoot(k, fx, fy, 0.45, 0, k.cream, flip: side < 0)
            }
            let by: CGFloat = 30 + bob
            for s: CGFloat in [-1, 1] {
                let ex = 50 + s * 9
                let lean = (s < 0 ? -0.15 : 0.15) - stalk
                let tip = CGPoint(x: ex + sin(lean) * stalkLen * -1 + s * 2, y: by + 12 + cos(lean) * stalkLen)
                k.noodle([ex, by + 10, ex + s * 1, by + 12 + stalkLen * 0.5, tip.x, tip.y], w: k.limb * 0.8)
                k.part(ell(tip.x + faceX * 0.3, tip.y + 3, 5.2, 6.5), k.cream)
                k.eye(tip.x + 0.6 + faceX * 0.5, tip.y + 3.2, 2.2, 3.8, look: faceX > 0 ? 1 : 0)
            }
            k.noodle(k.bend(30, by + 2, clawL.x, clawL.y, sag: 4), w: k.limb * 0.85)
            k.noodle(k.bend(70, by + 2, clawR.x, clawR.y, sag: -4), w: k.limb * 0.85)
            crabClaw(k, clawL.x, clawL.y, clawL.a, snap, shellTone, mirrored: true)
            crabClaw(k, clawR.x, clawR.y, clawR.a, snap, shellTone, mirrored: false)
            let body = smooth([24, by, 30, by + 12, 50, by + 15, 70, by + 12, 76, by, 70, by - 11, 50, by - 13, 30, by - 11])
            k.part(body, shellTone)
            if f.variant == 1 {
                k.clip(body) {
                    for yy: CGFloat in [-8, 0, 8] { k.fill(rrect(20, by + yy - 1.8, 60, 3.6, 0), k.cream) }
                }
                k.stroke(body, k.ink, k.line)
            }
            k.shine(36, by + 8, 4.5, 2, 0.3)
            k.part(ell(50 + faceX, by - 3, 12.5, 7.5), k.cream)
            k.mouth(50 + faceX, by - 0.5, 12, 3.4)
            if f.variant == 3 { meadowBowTie(k, 50 + faceX, by - 13, 1.0, k.red) }
            if f.variant == 4 { meadowDaisyHeld(k, clawR.x + 1, clawR.y + 8, clawR.a - 0.25, 1.05) }
            k.marks(f.mood == .fleeing ? 20 : 78, by + 32, 12)
        }
    }

    private static func crabClaw(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, _ a: CGFloat, _ open: CGFloat, _ tone: Tone, mirrored: Bool) {
        let m = CGAffineTransform(translationX: x, y: y).rotated(by: a).scaledBy(x: mirrored ? -1 : 1, y: 1)
        k.with(m) {
            let th: CGFloat = 0.2 + 0.32 * open
            let upper = xf(smooth([-7, 10, -8, 19, -4, 27, 1, 26, 0, 18, 1, 11], t: 0.8), about(-1, 12, rot: th))
            let lower = xf(smooth([7, 10, 7.5, 17, 5, 23, 2, 21, 2.5, 15, 1, 10], t: 0.8), about(2, 12, rot: -th))
            meadowBlob(k, [ell(0, 8, 8, 9), upper, lower], tone, 2 * k.line)
        }
    }

    static func frog(_ f: FigureFrame, _ k: HoseKit) {
        let skin = f.pick([k.accents[1], k.accents[1], k.ink, k.accents[1], k.accents[1]])
        let bootTone = f.pick([k.red, k.red, k.red, k.accents[2], k.red])
        let sq = f.squat, st = f.stretch
        let tuck: CGFloat = f.airborne ? sin(.pi * f.air) : 0
        let ext = max(0, st)
        let reachDown = max(0, -st)
        var sy = 1 - 0.16 * sq + 0.08 * st
        var sx = 1 + 0.1 * sq - 0.04 * st
        var rot: CGFloat = 0, faceX: CGFloat = 0
        let trail: CGFloat = f.airborne ? 1 - f.air : 0
        var hand = (x: CGFloat(68) + 10 * tuck + 6 * reachDown, y: CGFloat(13) + 8 * tuck - 2 * reachDown, a: CGFloat.pi - 0.2 + 1.3 * tuck, open: true)
        var foot = CGPoint(x: 30 - 22 * trail * (0.4 + 0.6 * ext), y: 4 + 12 * trail * (0.5 + 0.5 * tuck))
        var wave: (x: CGFloat, y: CGFloat, a: CGFloat)? = nil
        switch f.mood {
        case .calm:
            if f.twitch > 0 { wave = (92, 48, -0.5) }
        case .sleepy:
            sy *= 0.92
            sx *= 1.05
            hand = (64, 12, .pi - 0.5, true)
        case .startled:
            sy *= 1.07
            hand = (86, 66 + 2 * f.swing2, -0.4, true)
            wave = (12, 68 - 2 * f.swing2, 0.4)
        case .fleeing:
            rot = -0.08
            faceX = 2
            hand = (88, 28 + 5 * f.swing, -1.6, false)
            foot = CGPoint(x: 16 + 4 * f.swing, y: 6 + 6 * tuck)
        case .dizzy:
            rot = 0.12 * sin(f.t)
            hand = (88, 22 + 6 * f.swing, -1.4 + 0.6 * f.swing, true)
        }
        k.with(about(50, 4, rot: rot, sx: sx, sy: sy)) {
            if let w = wave, f.mood == .startled {
                k.noodle(k.bend(36, 40, w.x, w.y, sag: 3))
                k.glove(w.x, w.y, w.a, 0.8)
                k.noodle(k.bend(66, 40, hand.x, hand.y, sag: -5))
                k.glove(hand.x, hand.y, hand.a, 0.8)
            }
            k.noodle(k.bend(40, 16, foot.x + 12, foot.y + 3, sag: -3))
            meadowBoot(k, foot.x + 12, foot.y, 1, -0.1 * ext, bootTone)
            meadowBlob(k, [ell(44, 28, 25, 20), ell(62, 42, 22, 15), circ(57, 56, 8.5), circ(71, 57, 8.5)], skin, 2 * k.line)
            let thigh = ell(32 + 6 * ext * 0, 22, 13 - 2 * ext, 10, 0.3 - 0.5 * ext)
            k.part(thigh, skin)
            k.noodle(k.bend(26, 16, foot.x, foot.y + 3, sag: 3))
            meadowBoot(k, foot.x, foot.y, 1, -0.15 * ext, bootTone)
            k.part(ell(55, 24, 13, 12), k.cream)
            if f.variant == 3 { k.with(about(50, 60, rot: 0.45)) { frogBoater(k, 50, 60, 1.05) } }
            if f.variant == 4 { meadowDaisy(k, 48, 60, 1.2) }
            k.part(ell(68 + faceX * 0.4, 40, 15.5, 8.5), k.cream)
            k.part(circ(57 + faceX * 0.3, 57.5, 6), k.cream, w: 2.2)
            k.part(circ(71 + faceX * 0.3, 58.5, 6), k.cream, w: 2.2)
            k.eye(57.5 + faceX * 0.6, 57.5, 2.5, 4, look: faceX > 0 ? 1 : 0)
            k.eye(71.5 + faceX * 0.6, 58.5, 2.5, 4, look: faceX > 0 ? 1 : 0)
            k.mouth(70 + faceX, 43, 17, 4.5)
            k.shine(36, 40, 4.5, 2.2, 0.6)
            if f.variant == 1 { meadowBowTie(k, 63, 30, 0.8, k.red) }
            if f.mood != .startled {
                k.noodle(k.bend(62, 26, hand.x, hand.y, sag: hand.y > 26 ? -4 : 3))
                if hand.open { k.glove(hand.x, hand.y, hand.a, 0.8) } else { k.fist(hand.x, hand.y, hand.a, 0.8) }
            }
            if let w = wave, f.mood == .calm {
                k.noodle(k.bend(66, 28, w.x, w.y, sag: -8))
                k.glove(w.x, w.y, w.a, 0.8)
            }
            k.marks(f.mood == .fleeing ? 30 : 84, 72, 13)
        }
    }

    private static func frogBoater(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        k.with(CGAffineTransform(translationX: x, y: y).rotated(by: -0.12).scaledBy(x: s, y: s)) {
            let straw = k.accents[2].mix(k.cream, 0.35)
            k.part(ell(0, 0, 13.5, 3.2), straw)
            k.part(rrect(-8, 0, 16, 7.5, 1.5), straw)
            k.fill(rrect(-8, 1.2, 16, 3, 0), k.red)
            k.stroke(rrect(-8, 0, 16, 7.5, 1.5), k.ink, k.line)
        }
    }

    static func sun(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t
        let rayA = f.pick([k.accents[2], k.red, k.accents[2], k.accents[2], k.accents[2]])
        let rayB = f.pick([k.accents[2], k.red, k.accents[2], k.red, k.accents[2]])
        var len: CGFloat = 46, pulse: CGFloat = 3, spin: CGFloat = 0.06 * sin(t), stream: CGFloat = 0
        var rot: CGFloat = 0, faceX: CGFloat = 0, droop: CGFloat = 0
        var lh = (x: CGFloat(2), y: CGFloat(66) + 3 * f.swing, a: CGFloat(0.55) + 0.2 * f.swing)
        var rh = (x: CGFloat(98), y: CGFloat(52) + 6 * max(0, f.twitch), a: CGFloat(-0.7) - 0.4 * max(0, f.twitch))
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            len = 38
            pulse = 1
            droop = 4
            lh = (16, 10, 2.7)
            rh = (84, 10, -2.7)
        case .startled:
            len = 52
            pulse = 1.5
            lh = (6, 94 + 2 * f.swing2, 0.4)
            rh = (94, 94 - 2 * f.swing2, -0.4)
        case .fleeing:
            stream = 8
            faceX = 3
            lh = (2, 38 + 6 * f.swing, 2.0)
            rh = (100, 60 - 6 * f.swing, -1.4)
        case .dizzy:
            rot = 0.12 * sin(t)
            spin = 0.3 * sin(t)
            lh = (2, 54 + 6 * f.swing, 1.4)
            rh = (98, 54 - 6 * f.swing, -1.4)
        }
        k.with(about(50, 50, rot: rot)) {
            k.noodle(k.bend(28, 46, lh.x, lh.y, sag: 4))
            k.noodle(k.bend(72, 46, rh.x, rh.y, sag: -4))
            let n = 10
            for i in 0..<n {
                let a = CGFloat(i) / CGFloat(n) * 2 * .pi + spin + .pi / 2
                let even = i % 2 == 0
                let l = (even ? len : len - 8) + pulse * cos(t + (even ? 0 : .pi))
                var tx = 50 + cos(a) * l, ty = 50 + sin(a) * l - droop * max(0, -sin(a) + 0.3)
                tx -= stream * (0.6 + 0.4 * cos(a)) * (cos(a) < 0.5 ? 1 : 0.3)
                let w: CGFloat = 0.27
                let p = poly([50 + cos(a - w) * 24, 50 + sin(a - w) * 24, tx, ty, 50 + cos(a + w) * 24, 50 + sin(a + w) * 24])
                k.part(p, even ? rayA : rayB)
            }
            k.part(circ(50, 50, 27), k.cream)
            k.fill(ell(34.5, 44, 4, 2.6), k.red.alpha(0.45))
            k.fill(ell(65.5 + faceX, 44, 4, 2.6), k.red.alpha(0.45))
            k.eye(43 + faceX, 56, 3.5, 5.9, look: faceX > 0 ? 1 : 0)
            k.eye(57 + faceX, 56, 3.5, 5.9, look: faceX > 0 ? 1 : 0)
            k.mouth(50 + faceX, 45, 17, 5.2)
            if f.variant == 2 { frogBoater(k, 50, 74, 1.4) }
            if f.variant == 3 { meadowBowTie(k, 50, 22, 1.3, k.red) }
            if f.variant == 4 { meadowTopHat(k, 52, 74, 1.3, 0.16) }
            k.glove(lh.x, lh.y, lh.a, 0.85)
            k.glove(rh.x, rh.y, rh.a, 0.85)
            k.marks(f.mood == .fleeing ? 18 : 84, 82, 13)
        }
    }

    private static func meadowWing(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, _ a: CGFloat, _ rx: CGFloat, _ ry: CGFloat) {
        k.with(CGAffineTransform(translationX: x, y: y).rotated(by: a)) {
            k.part(ell(0, ry * 0.9, rx, ry), k.cream)
            k.stroke(arc(0, ry * 0.3, 0, ry * 1.4, dip: rx * 0.3), k.ink.alpha(0.5), 1.2)
        }
    }

    private static func meadowBoot(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ ang: CGFloat, _ tone: Tone, flip: Bool = false) {
        k.with(CGAffineTransform(translationX: x, y: y).scaledBy(x: flip ? -s : s, y: s).rotated(by: ang)) {
            meadowBlob(k, [ell(3.5, 3.4, 7.2, 5.0), ell(-3, 2.6, 5.2, 3.6)], tone, 2 * k.line)
            k.fill(ell(5, 5.2, 2.4, 1.4, 0.3), Tone.white.alpha(0.7))
            k.stroke(poly([-7.6, -0.2, 10, -0.2], closed: false), k.ink, 2.2)
        }
    }

    private static func meadowBlob(_ k: HoseKit, _ parts: [CGPath], _ tone: Tone, _ w: CGFloat) {
        for p in parts { k.stroke(p, k.ink, w) }
        for p in parts { k.fill(p, tone) }
    }

    private static func meadowTopHat(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ rot: CGFloat) {
        k.with(CGAffineTransform(translationX: x, y: y).rotated(by: rot).scaledBy(x: s, y: s)) {
            let crown = rrect(-9, 0, 18, 16, 2)
            k.stroke(crown, k.cream, k.line * 2.6)
            k.stroke(ell(0, 0.5, 14.5, 3.4), k.cream, k.line * 2.6)
            k.solid(crown)
            k.clip(crown) { k.fill(rrect(-10, 1.5, 20, 4.5, 0), k.red) }
            k.solid(ell(0, 0.5, 14.5, 3.4))
            k.shine(-5, 11, 1.4, 3.2, 0)
        }
    }

    private static func meadowBowTie(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ tone: Tone, _ rot: CGFloat = 0) {
        k.with(CGAffineTransform(translationX: x, y: y).rotated(by: rot).scaledBy(x: s, y: s)) {
            k.part(poly([0, 0, -8, 5, -8, -5]), tone, w: 2.4)
            k.part(poly([0, 0, 8, 5, 8, -5]), tone, w: 2.4)
            k.part(circ(0, 0, 2.6), tone, w: 2.4)
        }
    }

    private static func meadowDaisy(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        k.with(CGAffineTransform(translationX: x, y: y).scaledBy(x: s, y: s)) {
            var petals: [CGPath] = []
            for i in 0..<5 {
                let a = CGFloat(i) * 2 * .pi / 5 + .pi / 2
                petals.append(ell(cos(a) * 4.6, sin(a) * 4.6, 3.6, 2.6, a))
            }
            meadowBlob(k, petals, k.cream, 4.4)
            k.part(circ(0, 0, 3), k.accents[2], w: 2.2)
        }
    }

    private static func meadowDaisyHeld(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, _ a: CGFloat, _ s: CGFloat) {
        k.with(CGAffineTransform(translationX: x, y: y).rotated(by: a).scaledBy(x: s, y: s)) {
            k.stroke(line(0, 4, 0, 20), k.accents[1], 2.6)
            meadowDaisy(k, 0, 22, 1.15)
        }
    }
}
