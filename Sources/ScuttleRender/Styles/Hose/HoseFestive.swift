import Foundation
import CoreGraphics
import ScuttleCore

extension HoseArt {
    static func ghost(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t
        var rot: CGFloat = -0.09, sx: CGFloat = 1, sy: CGFloat = 1 + 0.035 * f.swing2
        var trail: CGFloat = 0, ripple: CGFloat = 2, sag: CGFloat = 3, faceX: CGFloat = 0
        var lh = (x: 13.5 + 1.5 * f.swing, y: CGFloat(69), a: 0.45 + 0.4 * f.swing, open: true)
        var rh = (x: CGFloat(86), y: CGFloat(37.5), a: CGFloat.pi - 0.25, open: true)
        switch f.mood {
        case .calm:
            rh.y += 4 * max(0, f.twitch)
            rh.a -= 0.35 * max(0, f.twitch)
        case .sleepy:
            sx = 1.05
            sy = 0.94
            ripple = 0.7
            lh = (21, 30, .pi + 0.25, true)
            rh = (80, 29, .pi - 0.25, true)
        case .startled:
            sx = 0.95
            sy = 1.08
            ripple = 0.8
            sag = 5
            lh = (10, 86 + 2 * f.swing2, 0.45, true)
            rh = (90, 88 - 2 * f.swing2, -0.45, true)
        case .fleeing:
            rot = -0.02
            trail = 9
            ripple = 3.2
            sag = 6 * f.swing
            faceX = 3
            lh = (7, 50 + 3 * f.swing, 1.9, true)
            rh = (92, 60 - 3 * f.swing, -1.25, false)
        case .dizzy:
            rot = -0.09 + 0.12 * sin(t)
            sag = 8
            lh = (13, 46 + 4 * f.swing, 2.4, true)
            rh = (87, 44 - 4 * f.swing, -2.4, true)
        }
        k.with(about(50, 10, rot: rot, sx: sx, sy: sy)) {
            k.noodle(k.bend(28, 54, lh.x, lh.y, sag: sag))
            if lh.open { k.glove(lh.x, lh.y, lh.a) } else { k.fist(lh.x, lh.y, lh.a) }
            if f.variant % 5 == 4 { hoseGhostCandle(k, lh.x, lh.y, lh.a) }
            k.noodle(k.bend(72, 50, rh.x, rh.y, sag: -sag))
            if rh.open { k.glove(rh.x, rh.y, rh.a, 0.95) } else { k.fist(rh.x, rh.y, rh.a, 0.95) }
            k.part(hoseGhostBody(trail: trail, ripple: ripple, t: t), k.cream)
            hoseGhostDress(f, k)
            k.eye(42 + faceX, 65, 4, 6.4, look: faceX > 0 ? 1 : 0)
            k.eye(57 + faceX, 65, 4, 6.4, look: faceX > 0 ? 1 : 0)
            k.mouth(49.5 + faceX, 51, 19, 6)
            k.marks(f.mood == .fleeing ? 22 : 76, 84, 13)
        }
    }

    private static func hoseGhostBody(trail: CGFloat, ripple: CGFloat, t: CGFloat) -> CGPath {
        var pts = P([50, 90, 66, 86, 75, 72, 76, 54, 74, 36, 72, 22, 66, 12, 60, 19, 53, 11, 46, 18, 39, 10, 32, 18, 27, 14, 26, 32, 25, 52, 28, 72, 36, 86])
        for i in pts.indices {
            if (6...12).contains(i) { pts[i].y += ripple * sin(t + CGFloat(i) * 1.3) }
            let low = max(0, min(1, (44 - pts[i].y) / 34))
            pts[i].x -= trail * low
        }
        return smoothP(pts)
    }

    private static func hoseGhostDress(_ f: FigureFrame, _ k: HoseKit) {
        switch f.variant % 5 {
        case 1:
            k.part(poly([50, 38, 40, 43, 40, 33]), k.red)
            k.part(poly([50, 38, 60, 43, 60, 33]), k.red)
            k.part(circ(50, 38, 2.6), k.red)
        case 2:
            k.with(about(50, 88, rot: 0.14)) {
                let crown = rrect(39, 88, 22, 17, 2)
                k.solid(crown)
                k.clip(crown) { k.fill(rrect(38, 89.5, 24, 4.5, 0), k.red) }
                k.solid(ell(50, 88.5, 17, 3.6))
                k.shine(43, 100, 1.4, 3.2, 0)
            }
        case 3:
            let green = k.accents[1]
            k.part(smooth([35, 41, 65, 41, 51, 27], t: 0.35), green)
            k.part(ell(50, 41, 4, 3), green)
            k.fill(circ(46, 35, 1.2), k.cream)
            k.fill(circ(54, 36, 1.2), k.cream)
        default:
            break
        }
    }

    private static func hoseGhostCandle(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, _ a: CGFloat) {
        k.with(CGAffineTransform(translationX: x, y: y).rotated(by: a)) {
            k.part(rrect(-2.4, 6, 4.8, 13, 1), k.cream)
            k.stroke(line(0, 19, 0, 21), k.ink, 1.2)
            let flame = drop(0, 24, 2.4, 0)
            k.part(flame, k.accents[2], w: k.line * 0.7)
            k.fill(drop(0, 23.2, 1.1, 0), Tone(0xfff4c2))
        }
    }

    private typealias HoseFestiveHand = (x: CGFloat, y: CGFloat, a: CGFloat, open: Bool)

    private static func hoseFestiveArm(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, _ h: HoseFestiveHand, sag: CGFloat, scale: CGFloat = 1) {
        k.noodle(k.bend(x, y, h.x, h.y, sag: sag))
        if h.open { k.glove(h.x, h.y, h.a, scale) } else { k.fist(h.x, h.y, h.a, scale) }
    }

    private static func hoseFestiveBlob(_ k: HoseKit, _ ps: [CGPath], _ tone: Tone, w: CGFloat? = nil) {
        let lw = 2 * (w ?? k.line)
        for p in ps { k.stroke(p, k.ink, lw) }
        for p in ps { k.fill(p, tone) }
    }

    private static func hoseFestiveBoot(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, side: CGFloat, ang: CGFloat = 0, tone: Tone, scale: CGFloat = 1) {
        k.with(CGAffineTransform(translationX: x, y: y).scaledBy(x: side * scale, y: scale)) {
            k.boot(0, 0, ang, color: tone)
        }
    }

    private static func hoseFestiveTopHat(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, rot: CGFloat, s: CGFloat, band: Tone) {
        k.with(CGAffineTransform(translationX: x, y: y).rotated(by: rot).scaledBy(x: s, y: s)) {
            let crown = rrect(-7.5, 0, 15, 13, 1.6)
            k.solid(crown)
            k.clip(crown) { k.fill(rrect(-9, 1.4, 18, 3.6, 0), band) }
            k.solid(ell(0, 0.6, 11.5, 2.7))
            k.shine(-4.2, 8.5, 1.1, 2.6, 0)
        }
    }

    private static func hoseFestiveBow(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, s: CGFloat, tone: Tone, rot: CGFloat = 0) {
        let w = k.line * 0.85 / max(0.3, s)
        k.with(CGAffineTransform(translationX: x, y: y).rotated(by: rot).scaledBy(x: s, y: s)) {
            k.part(smooth([0, 0, -9, 6, -10, -5], t: 0.4), tone, w: w)
            k.part(smooth([0, 0, 9, 6, 10, -5], t: 0.4), tone, w: w)
            k.part(circ(0, 0, 3), tone, w: w)
        }
    }

    private static func hoseFestiveCane(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, ang: CGFloat, s: CGFloat = 1) {
        k.with(CGAffineTransform(translationX: x, y: y).rotated(by: ang).scaledBy(x: s, y: s)) {
            let p = smooth([0, -12, 0, 10, 1.5, 15, 6, 17, 9.5, 13.5], closed: false)
            k.stroke(p, k.ink, 7)
            k.stroke(p, k.cream, 3.6)
            for yy in stride(from: CGFloat(-10), through: 8, by: 5) {
                k.stroke(line(-1.4, yy, 1.4, yy + 2.2), k.red, 1.9)
            }
            k.stroke(line(3.5, 16.4, 5.2, 14.2), k.red, 1.9)
        }
    }

    private static func hoseFestiveGift(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, s: CGFloat, box: Tone, ribbon: Tone) {
        let w = k.line / max(0.3, s)
        k.with(CGAffineTransform(translationX: x, y: y).scaledBy(x: s, y: s)) {
            let b = rrect(-9, -8, 18, 15, 1.5)
            k.fill(b, box)
            k.clip(b) { k.fill(rrect(-2, -9, 4, 18, 0), ribbon) }
            k.stroke(b, k.ink, w)
            k.part(ell(-3.5, 9.5, 3.6, 2.6, 0.5), ribbon, w: w * 0.8)
            k.part(ell(3.5, 9.5, 3.6, 2.6, -0.5), ribbon, w: w * 0.8)
        }
    }

    static func bat(_ f: FigureFrame, _ k: HoseKit) {
        let e = f.energy
        var rot: CGFloat = 0, sx: CGFloat = 1, sy: CGFloat = 1
        var raise: CGFloat = 0.1, flap: CGFloat = 0.55 * f.swing * min(1.3, e), sweep: CGFloat = 0
        var fx: CGFloat = 0, earTw: CGFloat = 0
        var leg = (dx: CGFloat(0), dy: CGFloat(0), spread: CGFloat(4.5))
        switch f.mood {
        case .calm:
            earTw = 0.3 * f.twitch
        case .sleepy:
            raise = -0.75
            flap = 0.06 * f.swing
            sx = 1.04
            sy = 0.95
            leg.spread = 2.5
        case .startled:
            raise = 0.55
            flap = 0.1 * f.swing
            sx = 0.94
            sy = 1.08
            leg = (0, -2, 9)
        case .fleeing:
            sweep = 0.32
            fx = 3
            flap = 0.7 * f.swing
            leg = (-9, 5, 3)
        case .dizzy:
            rot = 0.12 * sin(f.t)
            flap = 0.35 * f.swing
            leg.spread = 7
        }
        let v = f.variant % 5
        let membrane = [k.cream, k.red, k.cream, k.accents[1], k.cream][v]
        let boots = [k.red, k.cream, k.red, k.cream, k.accents[4]][v]
        let look: CGFloat = fx > 0 ? 1 : 0
        k.with(about(50, 46, rot: rot, sx: sx * 1.12, sy: sy * 1.12)) {
            k.both { s in
                let a = raise + flap + s * sweep
                k.with(CGAffineTransform(translationX: 50 + s * 9, y: 52).scaledBy(x: s, y: 1).rotated(by: a)) {
                    hoseBatWing(k, membrane)
                }
            }
            for s: CGFloat in [-1, 1] {
                let footX = 50 + s * leg.spread + leg.dx + 0.8 * f.swing * s
                let footY = 23 + leg.dy - 1.2 * f.sway
                k.noodle(k.bend(50 + s * 5, 34, footX, footY, sag: s * 2), w: k.line)
                hoseFestiveBoot(k, footX, footY - 1, side: s, tone: boots, scale: 0.5)
            }
            let earR = xf(poly([53, 62, 64, 77, 64, 55]), about(60, 60, rot: earTw))
            hoseFestiveBlob(k, [ell(50, 46, 16.5, 17), poly([36, 55, 35, 76, 47, 62]), earR], k.ink)
            k.fill(poly([38.5, 60, 37.8, 70, 43.5, 62.5]), k.red)
            k.fill(xf(poly([56.5, 62, 61.8, 71, 61.5, 59]), about(60, 60, rot: earTw)), k.red)
            if v == 4 { hoseFestiveBow(k, 60, 64, s: 0.75, tone: k.accents[4], rot: 0.3) }
            hoseFestiveBlob(k, [circ(46.5 + fx, 50.5, 6), circ(54.5 + fx, 50.5, 6), ell(50.5 + fx, 43.5, 10, 6.4)], k.cream, w: k.line * 0.8)
            k.eye(46.8 + fx, 51.5, 2.4, 4, look: look)
            k.eye(54.6 + fx, 51.5, 2.4, 4, look: look)
            k.mouth(51 + fx, 44.5, 9, 3)
            if f.mood == .calm {
                k.fill(poly([47.9, 44.4, 50.1, 44.4, 49, 41.8]), k.cream)
                k.fill(poly([51.9, 44.4, 54.1, 44.4, 53, 41.8]), k.cream)
            }
            k.shine(40, 37, 2.6, 1.5, 0.7)
            if v == 2 { hoseFestiveBow(k, 51 + fx, 33.5, s: 0.62, tone: k.red) }
            k.marks(f.mood == .fleeing ? 30 : 70, 68, 11)
        }
    }

    private static func hoseBatWing(_ k: HoseKit, _ membrane: Tone) {
        let w = CGMutablePath()
        w.move(to: pt(-1, 8))
        w.addQuadCurve(to: pt(21, 21), control: pt(7, 20))
        w.addQuadCurve(to: pt(43, 5), control: pt(35, 22))
        w.addQuadCurve(to: pt(28, -7), control: pt(32, 3))
        w.addQuadCurve(to: pt(12, -9), control: pt(19, 1))
        w.addQuadCurve(to: pt(-1, -5), control: pt(5, -1))
        w.closeSubpath()
        k.fill(w, membrane)
        k.clip(w) {
            k.stroke(arc(-2, 9, 21, 21, dip: -4), k.ink, k.limb * 1.3)
            k.stroke(line(21, 21, 43, 5), k.ink, k.line)
            k.stroke(line(21, 21, 28, -7), k.ink, k.line)
            k.stroke(line(21, 21, 12, -9), k.ink, k.line)
        }
        k.stroke(w, k.ink, k.line * 1.1)
        k.fill(ell(21.5, 22.5, 2.6, 3.4, -0.5), k.ink)
    }

    static func pumpkin(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t, sq = f.squat, st = f.stretch
        let tuck: CGFloat = f.airborne ? sin(f.air * .pi) : 0
        var sx: CGFloat = 1 + 0.1 * sq - 0.05 * st, sy: CGFloat = 1 - 0.16 * sq + 0.1 * st
        var rot: CGFloat = 0, fx: CGFloat = 0
        var spread: CGFloat = 10 + 3 * sq
        let footY: CGFloat = 4 + 6 * tuck
        let tw = max(0, f.twitch)
        var lh: HoseFestiveHand = (11, 52 + 3 * f.swing, 0.5, true)
        var rh: HoseFestiveHand = (89, 26 + 9 * tw, .pi - 0.35 - 0.9 * tw, true)
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sx *= 1.05
            sy *= 0.92
            lh = (19, 17, .pi + 0.35, true)
            rh = (81, 17, .pi - 0.35, true)
            spread = 8
        case .startled:
            sx *= 0.95
            sy *= 1.07
            lh = (9, 74 + 2 * f.swing2, 0.4, true)
            rh = (91, 76 - 2 * f.swing2, -0.4, true)
            spread = 14
        case .fleeing:
            rot = -0.07
            fx = 3
            lh = (5, 44 + 5 * f.swing, 1.9, true)
            rh = (93, 50 - 5 * f.swing, -1.3, false)
        case .dizzy:
            rot = 0.12 * sin(t)
            lh = (12, 30 + 4 * f.swing, 2.5, true)
            rh = (88, 30 - 4 * f.swing, -2.5, true)
        }
        let v = f.variant % 5
        let orange = k.red.mix(k.accents[2], 0.45)
        let skin = [orange, orange, k.cream, orange, k.accents[2]][v]
        let hipY = 4 + 14 * sy
        let back: CGFloat = f.mood == .fleeing ? -4 : 0
        for s: CGFloat in [-1, 1] {
            let footX = 50 + s * spread + back
            k.noodle(k.bend(50 + s * 8, hipY, footX, footY + 4, sag: s * (2 + 4 * sq)))
            hoseFestiveBoot(k, footX, footY, side: s, tone: k.red)
        }
        let look: CGFloat = fx > 0 ? 1 : 0
        k.with(about(50, 4, rot: rot, sx: sx, sy: sy)) {
            hoseFestiveArm(k, 26, 40, lh, sag: 4)
            hoseFestiveArm(k, 74, 38, rh, sag: -4, scale: 0.95)
            let lobes = [ell(35, 37, 17, 20), ell(65, 37, 17, 20), ell(50, 38, 17, 23)]
            hoseFestiveBlob(k, lobes, skin)
            let body = CGMutablePath()
            for l in lobes { body.addPath(l) }
            k.clip(body) { k.stroke(ell(50, 38, 16, 26), k.ink, k.line * 0.7) }
            if v != 1 {
                k.part(smooth([46, 57, 53, 57, 55, 66, 52, 71, 48.5, 66], t: 0.7), k.ink)
                k.stroke(spiral(42, 64, 4, turns: 1.2, spin: -1, start: 0), k.ink, k.line * 0.6)
            }
            if v == 0 || v == 4 {
                k.part(smooth([53, 63, 60, 69.5, 67.5, 66, 61, 61.5], t: 0.6), k.accents[1], w: k.line * 0.8)
            }
            k.shine(32, 48, 4, 2.2, 0.7)
            k.eye(50 + fx, 45, 3, 5.2, look: look)
            k.eye(61 + fx, 45, 3, 5.2, look: look)
            k.mouth(56 + fx, 34, 17, 5.4)
            switch v {
            case 1:
                k.with(about(50, 58, rot: 0.1)) {
                    let cone = smooth([37, 60, 63, 60, 57, 72, 50, 84, 35, 93, 43, 80, 42, 69], t: 0.6)
                    k.solid(cone)
                    k.clip(cone) { k.fill(rrect(30, 60.5, 40, 4.4, 0), k.red) }
                    k.solid(ell(50, 59.5, 22, 4.2))
                }
            case 2:
                hoseFestiveBow(k, 55.5 + fx, 20, s: 0.75, tone: k.red)
            case 3:
                hoseFestiveBow(k, 50, 62, s: 0.7, tone: k.red, rot: -0.15)
            case 4:
                hoseFestiveBow(k, 55.5 + fx, 20, s: 0.75, tone: k.accents[1])
            default:
                break
            }
            k.marks(f.mood == .fleeing ? 20 : 80, 66, 13)
        }
    }

    static func spider(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t, e = f.energy
        var cy: CGFloat = 38 + 1.2 * f.swing2 * min(e, 1.3)
        var rot: CGFloat = 0, sx: CGFloat = 1, sy: CGFloat = 1, fx: CGFloat = 0
        var knee: CGFloat = 0, reach: CGFloat = 1, trail: CGFloat = 0, lift: CGFloat = 4 * e
        let tw = max(0, f.twitch)
        var lh: HoseFestiveHand = (16, 64 + 3 * f.swing, 0.55, true)
        var rh: HoseFestiveHand = (85, 66 + 5 * tw, -0.35 - 0.35 * tw, true)
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            cy = 29
            knee = -8
            lift = 0.6
            sx = 1.06
            sy = 0.94
            lh = (40, 19, -1.9, true)
            rh = (61, 19, 1.9, true)
        case .startled:
            cy = 46
            knee = 9
            reach = 1.05
            sx = 0.95
            sy = 1.06
            lift = 1.5
            lh = (22, 88 + 2 * f.swing2, 0.25, true)
            rh = (79, 90 - 2 * f.swing2, -0.25, true)
        case .fleeing:
            trail = 7
            fx = 3
            lift = 6.5
            lh = (6, 50 + 4 * f.swing, 1.8, true)
            rh = (88, 58 - 4 * f.swing, -1.2, false)
        case .dizzy:
            rot = 0.12 * sin(t)
            lift = 2
            lh = (10, 40 + 4 * f.swing, 2.4, true)
            rh = (90, 40 - 4 * f.swing, -2.4, true)
        }
        let v = f.variant % 5
        let shoe = [k.red, k.cream, k.red, k.accents[1], k.accents[4]][v]
        let legW = k.width(3.6, minPt: 1.0)
        let look: CGFloat = fx > 0 ? 1 : 0
        k.with(about(50, 5, rot: rot)) {
            for s: CGFloat in [-1, 1] {
                for i in 0..<3 {
                    let fi = CGFloat(i)
                    let ph = t + fi * 2.1 + (s > 0 ? 0 : 1.05)
                    let up = lift * max(0, sin(ph))
                    let kx = 50 + s * (21 + fi * 8.5) * reach - trail * 0.5
                    let ky = cy + 14 - fi * 4.5 + knee + up * 0.6
                    let footX = 50 + s * (26 + fi * 12.5) * reach - trail
                    let footY = 5 + up
                    k.noodle([50 + s * 10, cy - 4 - fi * 3, kx, ky, footX, footY], w: legW)
                    k.part(ell(footX + s * 1.8, footY + 1.8, 4.4, 3), shoe, w: k.line * 0.75)
                }
            }
            k.noodle(k.bend(36, cy + 8, lh.x, lh.y, sag: 4), w: legW)
            k.noodle(k.bend(64, cy + 8, rh.x, rh.y, sag: -4), w: legW)
            if f.mood != .sleepy {
                if lh.open { k.glove(lh.x, lh.y, lh.a, 0.8) } else { k.fist(lh.x, lh.y, lh.a, 0.8) }
                if rh.open { k.glove(rh.x, rh.y, rh.a, 0.8) } else { k.fist(rh.x, rh.y, rh.a, 0.8) }
            }
            k.with(about(50, cy - 20, sx: sx, sy: sy)) {
                k.solid(circ(50, cy, 20))
                switch v {
                case 0:
                    k.stroke(smooth([49, cy + 18, 50, cy + 25, 55, cy + 27, 57, cy + 23, 53.5, cy + 22.5], closed: false), k.ink, k.line)
                case 1:
                    hoseFestiveBow(k, 50, cy + 20, s: 0.75, tone: k.red)
                case 2:
                    hoseFestiveTopHat(k, 51, cy + 17.5, rot: 0.1, s: 0.85, band: k.red)
                case 3:
                    hoseFestiveBow(k, 50.5 + fx, cy - 13.5, s: 0.62, tone: k.accents[1])
                default:
                    hoseFestiveBow(k, 42, cy + 18, s: 0.7, tone: k.accents[4], rot: 0.35)
                }
                hoseFestiveBlob(k, [circ(45 + fx, cy + 5, 7.2), circ(55.6 + fx, cy + 5, 7.2), ell(50.3 + fx, cy - 3, 11.5, 7.2)], k.cream, w: k.line * 0.8)
                k.eye(45.5 + fx, cy + 6, 3, 5, look: look)
                k.eye(55.6 + fx, cy + 6, 3, 5, look: look)
                k.mouth(50.6 + fx, cy - 2.5, 10.5, 3.5)
                k.shine(36, cy + 9, 2.8, 1.7, 0.7)
                if f.mood == .sleepy {
                    k.glove(lh.x, lh.y, lh.a, 0.75)
                    k.glove(rh.x, rh.y, rh.a, 0.75)
                }
                k.marks(f.mood == .fleeing ? 24 : 78, cy + 26, 12)
            }
        }
    }

    static func gingerbread(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t, e = f.energy
        let dough = Tone(0xbd7a3e)
        var bob: CGFloat = 1.6 * abs(f.sway) * min(e, 1.3)
        var rot: CGFloat = 0, sy: CGFloat = 1, fx: CGFloat = 0
        var reach: CGFloat = 7 * e, lift: CGFloat = 5 * e
        let tw = max(0, f.twitch)
        var lh: HoseFestiveHand = (13, 57 + 3 * f.swing, 0.55, true)
        var rh: HoseFestiveHand = (85, 34 - 3 * f.swing + 9 * tw, .pi - 0.4 - 1.0 * tw, true)
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            bob *= 0.3
            sy = 0.95
            rot = 0.04
            lh = (25, 26, .pi + 0.3, true)
            rh = (76, 26, .pi - 0.3, true)
        case .startled:
            sy = 1.05
            reach = 2
            lift = 2
            lh = (12, 84 + 2 * f.swing2, 0.4, true)
            rh = (88, 86 - 2 * f.swing2, -0.4, true)
        case .fleeing:
            fx = 3
            rot = -0.06
            reach = 10
            lh = (8, 50 - 8 * f.swing, 1.7, true)
            rh = (90, 52 + 8 * f.swing, -1.2, false)
        case .dizzy:
            rot = 0.12 * sin(t)
            lh = (14, 36 + 4 * f.swing, 2.4, true)
            rh = (86, 36 - 4 * f.swing, -2.4, true)
        }
        let v = f.variant % 5
        let drops = [k.red, k.accents[1], k.cream, k.red, k.red][v]
        let boots = [k.red, k.cream, k.red, k.accents[4], k.red][v]
        let look: CGFloat = fx > 0 ? 1 : 0
        k.with(about(50, 4, rot: rot, sx: 1, sy: sy)) {
            for which in [1, 0] {
                let s = k.step(which, reach: reach, lift: lift)
                let hx: CGFloat = which == 0 ? 56 : 44
                let side: CGFloat = which == 0 ? 1 : -1
                hoseGingerLimb(k, k.bend(hx, 30 + bob, hx + s.x + side * 2, 11 + s.y, sag: side * 2), dough)
                hoseFestiveBoot(k, hx + s.x + side * 2, 4 + s.y, side: 1, tone: boots)
            }
            k.with(CGAffineTransform(translationX: 0, y: bob)) {
                hoseGingerLimb(k, k.bend(40, 50, lh.x, lh.y, sag: 4), dough)
                if lh.open { k.glove(lh.x, lh.y - bob, lh.a) } else { k.fist(lh.x, lh.y - bob, lh.a) }
                hoseGingerLimb(k, k.bend(61, 50, rh.x, rh.y, sag: -4), dough)
                if rh.open { k.glove(rh.x, rh.y - bob, rh.a, 0.95) } else { k.fist(rh.x, rh.y - bob, rh.a, 0.95) }
                if v == 4 { hoseFestiveCane(k, rh.x + 1, rh.y + 5, ang: -0.2, s: 1) }
                let torso = smooth([38, 55, 63, 55, 65, 40, 62, 27, 50.5, 24, 39, 27, 36, 40], t: 0.8)
                var head = circ(51, 70, 15)
                if v == 2 {
                    head = minus(head, uni([circ(37.5, 80, 4.2), circ(41.5, 84.5, 4.2), circ(36, 75, 3.6)]))
                }
                hoseFestiveBlob(k, [torso, head, ell(50.5, 55, 9, 4)], dough)
                k.stroke(wavy(42, 79.5, 60, 79.5, waves: 2, amp: 1.3, phase: 0), k.cream, k.line * 0.9)
                k.stroke(zigzag(40, 29.5, 61, 29.5, teeth: 5, amp: 1.4), k.cream, k.line * 0.8)
                k.part(circ(51, 46, 3.2), drops, w: k.line * 0.8)
                k.part(circ(51, 37.5, 3.2), drops, w: k.line * 0.8)
                if v == 1 { hoseFestiveBow(k, 51 + fx * 0.5, 54.5, s: 0.7, tone: k.red) }
                if v == 3 { hoseFestiveBow(k, 42, 82, s: 0.65, tone: k.accents[4], rot: 0.4) }
                k.eye(47 + fx, 72, 2.6, 4.4, look: look)
                k.eye(55.5 + fx, 72, 2.6, 4.4, look: look)
                k.mouth(51.5 + fx, 64.5, 11, 3.6)
                k.marks(f.mood == .fleeing ? 26 : 74, 86, 12)
            }
        }
    }

    private static func hoseGingerLimb(_ k: HoseKit, _ a: [CGFloat], _ dough: Tone) {
        let p = smooth(a, closed: false)
        let w = k.width(8.5, minPt: 2.4)
        k.stroke(p, k.ink, w + 2 * k.line)
        k.stroke(p, dough, w)
        let mx = a[2] + (a[4] - a[2]) * 0.45, my = a[3] + (a[5] - a[3]) * 0.45
        let dx = a[4] - a[2], dy = a[5] - a[3]
        let l = max(0.001, hypot(dx, dy))
        let nx = -dy / l * w * 0.42, ny = dx / l * w * 0.42
        k.stroke(zigzag(mx - nx, my - ny, mx + nx, my + ny, teeth: 2, amp: 1.2), k.cream, k.line * 0.7)
    }

    static func present(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t, sq = f.squat, st = f.stretch
        let tuck: CGFloat = f.airborne ? sin(f.air * .pi) : 0
        var sx: CGFloat = 1 + 0.1 * sq - 0.05 * st, sy: CGFloat = 1 - 0.16 * sq + 0.1 * st
        var rot: CGFloat = 0, fx: CGFloat = 0
        var spread: CGFloat = 10 + 3 * sq
        let footY: CGFloat = 4 + 6 * tuck
        let tw = max(0, f.twitch)
        var lid = (dy: CGFloat(2.5 * tuck), rot: CGFloat(0.05 * tw))
        var lh: HoseFestiveHand = (12, 46 + 3 * f.swing, 0.55, true)
        var rh: HoseFestiveHand = (89, 24 + 8 * tw, .pi - 0.35 - 0.8 * tw, true)
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sx *= 1.04
            sy *= 0.93
            lid = (-1, -0.07)
            lh = (19, 13, .pi + 0.3, true)
            rh = (81, 13, .pi - 0.3, true)
            spread = 8
        case .startled:
            sx *= 0.96
            sy *= 1.05
            lid = (10 + 1.5 * f.swing2, 0.22)
            lh = (10, 66 + 2 * f.swing2, 0.4, true)
            rh = (90, 68 - 2 * f.swing2, -0.4, true)
            spread = 14
        case .fleeing:
            rot = -0.06
            fx = 3
            lid = (2 + 1.5 * abs(f.swing), 0.16)
            lh = (5, 38 + 5 * f.swing, 1.9, true)
            rh = (94, 44 - 5 * f.swing, -1.3, false)
        case .dizzy:
            rot = 0.12 * sin(t)
            lid = (1.5, 0.1 * sin(t + 1))
            lh = (12, 26 + 4 * f.swing, 2.5, true)
            rh = (88, 26 - 4 * f.swing, -2.5, true)
        }
        let v = f.variant % 5
        let box = [k.red, k.accents[1], k.cream, k.ink, k.accents[3]][v]
        let ribbon = [k.cream, k.red, k.red, k.red, k.accents[2]][v]
        let boots = [k.cream, k.red, k.red, k.red, k.cream][v]
        let hipY = 4 + 12 * sy
        let back: CGFloat = f.mood == .fleeing ? -4 : 0
        for s: CGFloat in [-1, 1] {
            let footX = 50 + s * spread + back
            k.noodle(k.bend(50 + s * 9, hipY, footX, footY + 4, sag: s * (2 + 4 * sq)))
            hoseFestiveBoot(k, footX, footY, side: s, tone: boots)
        }
        let look: CGFloat = fx > 0 ? 1 : 0
        k.with(about(50, 4, rot: rot, sx: sx, sy: sy)) {
            hoseFestiveArm(k, 30, 32, lh, sag: 4)
            hoseFestiveArm(k, 70, 32, rh, sag: -4, scale: 0.95)
            let body = rrect(27, 14, 46, 36, 3)
            k.fill(body, box)
            k.clip(body) { k.fill(rrect(33, 13, 8, 38, 0), ribbon) }
            k.stroke(body, k.ink, k.line)
            if v == 3 { k.shine(31, 44, 1.4, 2.6, 0) }
            let patch = ell(60 + fx, 31, 11.5, 10.5)
            k.part(patch, k.cream, w: k.line * 0.85)
            k.eye(56 + fx, 34, 2.6, 4.4, look: look)
            k.eye(64.5 + fx, 34, 2.6, 4.4, look: look)
            k.mouth(60.3 + fx, 27, 11, 3.6)
            k.with(CGAffineTransform(translationX: 0, y: lid.dy).concatenating(about(23, 47, rot: lid.rot))) {
                let top = rrect(23, 47, 54, 12, 3)
                k.fill(top, box)
                k.clip(top) { k.fill(rrect(33, 46, 8, 14, 0), ribbon) }
                k.stroke(top, k.ink, k.line)
                k.part(smooth([37, 60, 27, 69, 24, 62, 30, 59], t: 0.6), ribbon, w: k.line * 0.9)
                k.part(smooth([37, 60, 47, 69, 50, 62, 44, 59], t: 0.6), ribbon, w: k.line * 0.9)
                k.part(circ(37, 60.5, 3.2), ribbon, w: k.line * 0.9)
            }
            k.marks(f.mood == .fleeing ? 18 : 82, 64, 13)
        }
    }

    static func elf(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t, e = f.energy
        var bob: CGFloat = 1.5 * abs(f.sway) * min(e, 1.3)
        var rot: CGFloat = 0, sy: CGFloat = 1, fx: CGFloat = 0
        var reach: CGFloat = 7 * e, lift: CGFloat = 5 * e, tip: CGFloat = 3 * f.swing * e
        let tw = max(0, f.twitch)
        var lh: HoseFestiveHand = (16, 54 + 3 * f.swing, 0.6, true)
        var rh: HoseFestiveHand = (84, 32 - 3 * f.swing + 8 * tw, .pi - 0.4 - tw, true)
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            bob *= 0.3
            sy = 0.95
            tip = -4
            lh = (28, 22, .pi + 0.3, true)
            rh = (74, 22, .pi - 0.3, true)
        case .startled:
            sy = 1.05
            reach = 2
            lift = 2
            tip = 6
            lh = (14, 80 + 2 * f.swing2, 0.4, true)
            rh = (88, 82 - 2 * f.swing2, -0.4, true)
        case .fleeing:
            fx = 2.5
            rot = -0.06
            reach = 10
            tip = -8 + 2 * f.swing
            lh = (10, 46 - 8 * f.swing, 1.7, true)
            rh = (90, 48 + 8 * f.swing, -1.2, false)
        case .dizzy:
            rot = 0.12 * sin(t)
            tip = 4 * sin(t)
            lh = (16, 34 + 4 * f.swing, 2.4, true)
            rh = (86, 34 - 4 * f.swing, -2.4, true)
        }
        let v = f.variant % 5
        let tunic = [k.accents[1], k.red, k.accents[1], k.accents[1], k.accents[3]][v]
        let hat = [k.red, k.accents[1], k.red, k.red, k.red][v]
        let boots = [k.red, k.accents[1], k.red, k.red, k.red][v]
        let look: CGFloat = fx > 0 ? 1 : 0
        k.with(about(50, 4, rot: rot, sx: 1, sy: sy)) {
            for which in [1, 0] {
                let s = k.step(which, reach: reach, lift: lift)
                let hx: CGFloat = which == 0 ? 55 : 45
                let bx = hx + s.x, by = 4 + s.y
                k.noodle(k.bend(hx, 24 + bob, bx, by + 4, sag: which == 0 ? 2.5 : -2.5))
                k.boot(bx, by, 0, color: boots)
                k.stroke(smooth([bx + 9, by + 5, bx + 12.5, by + 8, bx + 11.5, by + 11, bx + 9, by + 10], closed: false), k.ink, k.line)
            }
            k.with(CGAffineTransform(translationX: 0, y: bob)) {
                hoseFestiveArm(k, 43, 42, (lh.x, lh.y - bob, lh.a, lh.open), sag: 4)
                if v == 3 { hoseFestiveGift(k, lh.x - 1, lh.y - bob + 14, s: 0.8, box: k.red, ribbon: k.cream) }
                let coat = poly([41, 47, 61, 47, 67, 21, 62, 25, 57, 20, 51, 25, 46, 20, 41, 25, 35, 21])
                k.fill(coat, tunic)
                k.clip(coat) { k.fill(rrect(30, 28, 42, 5.5, 0), k.ink) }
                k.stroke(coat, k.ink, k.line)
                k.part(rrect(48.5, 27.2, 7, 7, 1), k.accents[2], w: k.line * 0.7)
                hoseFestiveArm(k, 59, 42, (rh.x, rh.y - bob, rh.a, rh.open), sag: -4, scale: 0.95)
                if v == 2 { hoseFestiveCane(k, rh.x + 1, rh.y - bob + 5, ang: -0.2, s: 1) }
                k.part(poly([40, 64, 28, 71, 39, 56]), k.cream)
                k.part(poly([64, 64, 76, 71, 65, 56]), k.cream)
                k.part(circ(52, 60, 14.5), k.cream)
                k.eye(49 + fx, 58, 2.3, 4, look: look)
                k.eye(57 + fx, 58, 2.3, 4, look: look)
                k.mouth(53.5 + fx, 51, 10, 3.4)
                let cone = smooth([37, 68, 67, 70, 61, 82, 50, 92, 34 + tip * 0.4, 99 + tip * 0.3, 26 + tip, 96 + tip * 0.4, 42, 86], t: 0.55)
                k.part(cone, hat)
                k.with(about(52, 69, rot: -0.05)) { k.part(rrect(35, 65.5, 34, 7.5, 3.7), k.cream) }
                if v == 4 {
                    k.part(circ(26 + tip, 95 + tip * 0.4, 4.4), k.accents[2], w: k.line * 0.8)
                    k.stroke(line(23.5 + tip, 94 + tip * 0.4, 28.5 + tip, 94 + tip * 0.4), k.ink, k.line * 0.6)
                } else {
                    k.part(circ(26 + tip, 95.5 + tip * 0.4, 4.6), k.cream, w: k.line * 0.8)
                }
                k.marks(f.mood == .fleeing ? 22 : 76, 80, 12)
            }
        }
    }

    static func reindeer(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t, e = f.energy
        var bob: CGFloat = 1.4 * abs(f.sway) * min(e, 1.3)
        var rot: CGFloat = 0, fx: CGFloat = 0, pivot: CGFloat = 44
        var reach: CGFloat = 6 * e, lift: CGFloat = 4.5 * e
        var hx: CGFloat = 76, hy: CGFloat = 66, bodyY: CGFloat = 40
        var tailA: CGFloat = 0.5 + 0.5 * f.twitch, legLen: CGFloat = 1
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            bob = 0
            bodyY = 26
            hy = 50
            hx = 74
            reach = 0
            lift = 0
            legLen = 0.35
            tailA = -0.2
        case .startled:
            rot = 0.1
            pivot = 28
            hy = 72
            hx = 75
            reach = 2
            lift = 1.5
            tailA = 1.3
        case .fleeing:
            fx = 2
            hx = 82
            hy = 60
            reach = 11
            lift = 7
            tailA = 1.6 + 0.2 * f.swing
        case .dizzy:
            rot = 0.12 * sin(t)
        }
        let v = f.variant % 5
        let coat = v == 4 ? Tone(0x6b4630) : k.ink
        let tan = k.cream.mix(Tone(0xc08850), 0.4)
        let by = bodyY + bob
        let hipY = by - 6
        k.with(about(pivot, 4, rot: rot)) {
            let legs: [(x: CGFloat, w: Int)] = [(60, 1), (30, 0), (65, 0), (35, 1)]
            for (i, lg) in legs.enumerated() {
                let s = k.step(lg.w, reach: reach, lift: lift)
                let fxp = lg.x + s.x + (i % 2 == 0 ? 1 : -1)
                let fy = 4 + s.y + (1 - legLen) * (hipY - 4) * 0.55
                if i == 2 { hoseDeerBody(k, f, coat, by, tailA) }
                k.noodle(k.bend(lg.x, hipY + 2, fxp, fy + 4, sag: (lg.x > 45 ? 2.5 : -2.5) * (2 - legLen)), w: k.limb)
                let hoof = smooth([fxp - 4, fy, fxp + 5, fy, fxp + 4, fy + 5.5, fxp - 3, fy + 5.5], t: 0.5)
                k.part(hoof, k.cream, w: k.line * 0.9)
                k.stroke(line(fxp + 0.8, fy, fxp + 0.8, fy + 3), k.ink, k.line * 0.6)
            }
            let nx0: CGFloat = 60, ny0 = by + 4
            k.stroke(line(nx0, ny0, hx - 3, hy - 4 + bob), coat, k.width(12, minPt: 3))
            let nmx = nx0 + (hx - 3 - nx0) * 0.35, nmy = ny0 + (hy - 4 + bob - ny0) * 0.35
            let nang = atan2(hy - 4 + bob - ny0, hx - 3 - nx0)
            if v == 0 || v == 4 {
                k.part(ell(nmx, nmy, 3.4, 7.6, nang), k.red, w: k.line * 0.8)
                k.part(circ(nmx + 3, nmy - 7, 3.2), k.accents[2], w: k.line * 0.8)
                k.stroke(line(nmx + 1.8, nmy - 8.4, nmx + 4.2, nmy - 8.4), k.ink, k.line * 0.5)
            }
            if v == 2 {
                k.part(ell(nmx, nmy, 5.2, 9.5, nang), k.accents[1], w: k.line * 0.8)
                for (dx, dy) in [(-1.5, 5.5), (2.2, 0.5), (-0.8, -5)] as [(CGFloat, CGFloat)] {
                    k.part(circ(nmx + dx, nmy + dy, 2), k.red, w: k.line * 0.5)
                }
            }
            if v == 3 {
                let wave = 2 * f.swing
                k.part(smooth([nmx - 2, nmy + 3, nmx - 14, nmy + 1 + wave, nmx - 22, nmy - 2 + wave * 1.5, nmx - 20, nmy - 7 + wave, nmx - 12, nmy - 4, nmx - 1, nmy - 4], t: 0.7), k.red, w: k.line * 0.8)
                k.part(ell(nmx, nmy, 3.6, 7.6, nang), k.red, w: k.line * 0.8)
                k.stroke(line(nmx - 1.5, nmy - 5, nmx + 1.5, nmy - 1), k.cream, k.line * 0.8)
                k.stroke(line(nmx - 1.5, nmy + 1, nmx + 1.5, nmy + 5), k.cream, k.line * 0.8)
            }
            hoseDeerHead(k, f, hx + fx * 0, hy + bob, coat, tan, v)
        }
    }

    private static func hoseDeerBody(_ k: HoseKit, _ f: FigureFrame, _ coat: Tone, _ by: CGFloat, _ tailA: CGFloat) {
        k.part(ell(19.5, by + 6, 5.2, 3.6, tailA), k.cream, w: k.line * 0.9)
        let body = ell(44, by, 24, 12.5)
        k.fill(body, coat)
        k.clip(body) { k.fill(ell(46, by - 11, 17, 6), k.cream) }
        k.stroke(body, k.ink, k.line)
        k.shine(32, by + 7, 4, 1.6, 0.15)
    }

    private static func hoseDeerHead(_ k: HoseKit, _ f: FigureFrame, _ hx: CGFloat, _ hy: CGFloat, _ coat: Tone, _ tan: Tone, _ v: Int) {
        let aw = k.width(3.4, minPt: 1.0)
        let antlers: [[CGFloat]] = [
            [hx - 3, hy + 7, hx - 6, hy + 18, hx - 13, hy + 27],
            [hx - 6, hy + 16, hx - 13, hy + 17.5],
            [hx - 8.5, hy + 22, hx - 5, hy + 29],
            [hx + 4, hy + 8, hx + 6, hy + 19, hx + 3, hy + 30],
            [hx + 6, hy + 17, hx + 12.5, hy + 23],
            [hx + 5.5, hy + 13, hx + 11, hy + 13.5],
        ]
        for a in antlers { k.stroke(smooth(a, closed: false), k.ink, aw + 2 * k.line * 0.85) }
        for a in antlers { k.stroke(smooth(a, closed: false), tan, aw) }
        let earA: CGFloat = 0.55 + 0.25 * f.twitch
        k.part(ell(hx - 10, hy + 4, 6.5, 2.8, earA), coat)
        k.fill(ell(hx - 10, hy + 4, 3.8, 1.2, earA), k.red)
        k.part(ell(hx, hy, 10.5, 10), coat)
        hoseFestiveBlob(k, [circ(hx - 0.5, hy + 3, 5), circ(hx + 6.5, hy + 3.5, 5), ell(hx + 9, hy - 4.5, 9.5, 6.5, -0.15)], k.cream, w: k.line * 0.85)
        let look: CGFloat = f.mood == .fleeing ? 1 : 0
        k.eye(hx - 0.2, hy + 4, 2.1, 3.6, look: look)
        k.eye(hx + 6.6, hy + 4.4, 2.1, 3.6, look: look)
        k.mouth(hx + 10.5, hy - 6.5, 8, 2.6)
        let nose = v == 1 ? k.red : k.ink
        k.part(circ(hx + 18, hy - 3, v == 1 ? 4.6 : 3.6), nose, w: k.line * 0.8)
        k.shine(hx + 17, hy - 1.8, 1.2, 0.8, 0.5)
        k.marks(f.mood == .fleeing ? hx - 40 : hx + 14, hy + 20, 12)
    }

    static func blackCat(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t, e = f.energy
        var bob: CGFloat = 1.3 * abs(f.sway) * min(e, 1.3)
        var rot: CGFloat = 0, fx: CGFloat = 0
        var reach: CGFloat = 6 * e, lift: CGFloat = 4.5 * e
        var hx: CGFloat = 73, hy: CGFloat = 56, bodyY: CGFloat = 38, arch: CGFloat = 2, stretchX: CGFloat = 0
        var legLen: CGFloat = 1, earBack: CGFloat = 0
        var tail: [CGFloat] = [26, 42, 15, 48, 12, 62, 17 + 2 * f.twitch, 73, 24 + 3 * f.twitch, 74]
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            bob = 0
            bodyY = 22
            hy = 34
            hx = 72
            reach = 0
            lift = 0
            legLen = 0.2
            tail = [26, 20, 16, 14, 24, 8, 44, 7, 62, 8]
        case .startled:
            bodyY = 44
            hy = 64
            arch = 16
            reach = 1.5
            lift = 1.5
            tail = [26, 50, 22, 62, 22, 76, 23 + 1.5 * f.swing2, 90]
        case .fleeing:
            fx = 2
            hx = 78
            hy = 52
            stretchX = 5
            reach = 12
            lift = 7
            earBack = 0.5
            tail = [24, 42, 14, 44, 4, 46 + 3 * f.swing, -4, 44 - 2 * f.swing]
        case .dizzy:
            rot = 0.12 * sin(t)
        }
        let v = f.variant % 5
        let iris = v == 2 ? Tone(0x6cc04a) : k.accents[2]
        let by = bodyY + bob
        let hipY = by - 6
        k.with(about(48, 4, rot: rot)) {
            let tw = k.width(6, minPt: 1.8)
            if f.mood == .startled {
                k.stroke(smooth(tail, closed: false), k.ink, tw * 1.7)
                let spikes = zigzag(tail[0] - 4, tail[1], tail[6] - 4, tail[7], teeth: 4, amp: 3)
                k.stroke(spikes, k.ink, tw)
            } else {
                k.stroke(smooth(tail, closed: false), k.ink, tw)
            }
            if v == 3 && f.mood != .sleepy {
                let n = tail.count
                hoseFestiveBow(k, tail[n - 4], tail[n - 3], s: 0.85, tone: k.red, rot: 0.4)
            }
            let legs: [(x: CGFloat, w: Int)] = [(58, 1), (30, 0), (63, 0), (35, 1)]
            for (i, lg) in legs.enumerated() {
                if i == 2 { hoseCatBody(k, f, by, arch, stretchX) }
                if legLen < 0.5 {
                    if i >= 2 { k.part(ell(lg.x + 8, 7, 5.5, 3.4), k.cream, w: k.line * 0.9) }
                    continue
                }
                let s = k.step(lg.w, reach: reach, lift: lift)
                let lx = lg.x + (lg.x > 45 ? stretchX : -stretchX)
                let pxp = lx + s.x + (i % 2 == 0 ? 1 : -1)
                let py = 4 + s.y
                k.noodle(k.bend(lx, hipY + 2, pxp, py + 3, sag: lg.x > 45 ? 2.5 : -2.5), w: k.limb)
                k.part(ell(pxp + 1.5, py + 2.8, 5, 3.2), k.cream, w: k.line * 0.9)
            }
            hoseCatHead(k, f, hx + fx, hy + bob, iris, earBack, v)
        }
    }

    private static func hoseCatBody(_ k: HoseKit, _ f: FigureFrame, _ by: CGFloat, _ arch: CGFloat, _ sx: CGFloat) {
        let pts: [CGFloat] = [24 - sx, by - 3, 26 - sx, by + 7, 40, by + 11 + arch, 56, by + 10 + arch * 0.6, 67 + sx, by + 5, 66 + sx, by - 6, 50, by - 9, 34, by - 9]
        let body = smooth(pts, t: 0.9)
        k.solid(body)
        if f.mood == .startled {
            let spikes = spikeRing(46, by + 1, rx: 20, ry: 9 + arch, trx: 23, try_: 12.5 + arch, from: 0.25 * .pi, to: 0.85 * .pi, n: 5)
            k.solid(polyP(spikes + [CGPoint(x: 46, y: by)]))
        }
        k.shine(36, by + 6 + arch * 0.6, 5, 1.6, 0.2)
    }

    private static func hoseCatHead(_ k: HoseKit, _ f: FigureFrame, _ hx: CGFloat, _ hy: CGFloat, _ iris: Tone, _ earBack: CGFloat, _ v: Int) {
        k.with(about(hx, hy - 4, sx: 1.3, sy: 1.3)) {
            hoseCatFace(k, f, hx, hy, iris, earBack, v)
        }
    }

    private static func hoseCatFace(_ k: HoseKit, _ f: FigureFrame, _ hx: CGFloat, _ hy: CGFloat, _ iris: Tone, _ earBack: CGFloat, _ v: Int) {
        let earR = xf(poly([hx + 1, hy + 11, hx + 9, hy + 21, hx + 11.5, hy + 4]), about(hx + 6, hy + 8, rot: 0.25 * f.twitch - earBack))
        let earL = xf(poly([hx - 11, hy + 4, hx - 10, hy + 20, hx - 1, hy + 11]), about(hx - 6, hy + 8, rot: earBack))
        hoseFestiveBlob(k, [circ(hx, hy, 12.5), earR, earL], k.ink)
        k.fill(xf(poly([hx + 3.5, hy + 11.5, hx + 8.5, hy + 17.5, hx + 9.5, hy + 8]), about(hx + 6, hy + 8, rot: 0.25 * f.twitch - earBack)), k.red)
        k.fill(xf(poly([hx - 8.5, hy + 8, hx - 8, hy + 16.5, hx - 3, hy + 11.5]), about(hx - 6, hy + 8, rot: earBack)), k.red)
        if v == 0 || v == 4 {
            let band = v == 4 ? k.accents[4] : k.red
            k.part(smooth([hx - 11, hy - 7, hx - 2, hy - 11.5, hx + 5, hy - 11.5, hx + 5, hy - 15, hx - 2, hy - 15, hx - 11, hy - 10.5], t: 0.7), band, w: k.line * 0.7)
            k.part(circ(hx + 0.5, hy - 16.5, 2.8), k.accents[2], w: k.line * 0.7)
            k.stroke(line(hx - 1, hy - 17.5, hx + 2, hy - 17.5), k.ink, k.line * 0.4)
        }
        if v == 2 { hoseFestiveBow(k, hx - 3, hy - 14, s: 0.85, tone: k.accents[1]) }
        if v == 4 { hoseFestiveBow(k, hx + 6.5, hy + 14, s: 0.55, tone: k.accents[4], rot: -0.3) }
        if v == 1 {
            k.with(about(hx, hy + 11, rot: 0.15)) {
                let cone = smooth([hx - 9, hy + 12, hx + 9, hy + 12, hx + 4, hy + 22, hx - 2, hy + 30, hx - 13, hy + 33, hx - 5, hy + 25, hx - 5, hy + 18], t: 0.6)
                k.solid(cone)
                k.clip(cone) { k.fill(rrect(hx - 14, hy + 12.4, 28, 3.6, 0), k.red) }
                k.solid(ell(hx, hy + 11.5, 15, 3))
            }
        }
        let muzzle = ell(hx + 5.5, hy - 5, 8, 5.6)
        k.part(muzzle, k.cream, w: k.line * 0.85)
        let look: CGFloat = f.mood == .fleeing ? 1 : 0
        let shut = f.eyesShut || f.mood == .dizzy || f.mood == .startled || f.mood == .fleeing
        if !shut {
            k.part(ell(hx - 2, hy + 3.5, 3.6, 5), iris, w: k.line * 0.8)
            k.part(ell(hx + 6.2, hy + 4, 3.4, 5), iris, w: k.line * 0.8)
        }
        if f.eyesShut && f.mood != .dizzy {
            k.stroke(arc(hx - 5, hy + 3.5, hx + 1, hy + 3.5, dip: 2.2), k.cream, k.line)
            k.stroke(arc(hx + 3.5, hy + 4, hx + 9, hy + 4, dip: 2.2), k.cream, k.line)
        } else {
            k.eye(hx - 1.6, hy + 3.3, 2, 3.8, look: look)
            k.eye(hx + 6.5, hy + 3.8, 1.9, 3.8, look: look)
        }
        k.fill(poly([hx + 4.6, hy - 1, hx + 8, hy - 1, hx + 6.3, hy - 3.2]), k.red)
        k.mouth(hx + 6.3, hy - 3.6, 7, 2.3)
        for d: CGFloat in [-1, 1] {
            k.stroke(line(hx + 12.5, hy - 4 + d * 1.2, hx + 20, hy - 3 + d * 3.2), k.ink, k.line * 0.55)
        }
        k.marks(f.mood == .fleeing ? hx - 44 : hx + 13, hy + 20, 12)
    }

    static func santa(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t, e = f.energy
        var bob: CGFloat = 1.4 * abs(f.sway) * min(e, 1.3)
        var rot: CGFloat = 0, sy: CGFloat = 1, fx: CGFloat = 0
        var reach: CGFloat = 6.5 * e, lift: CGFloat = 4.5 * e, tip: CGFloat = 2.5 * f.swing * e
        let tw = max(0, f.twitch)
        var lh: HoseFestiveHand = (12, 66 + 3 * f.swing + 4 * tw, 0.5 - 0.3 * tw, true)
        var rh: HoseFestiveHand = (76, 34, .pi + 0.9, true)
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            bob *= 0.3
            sy = 0.95
            tip = -4
            lh = (22, 22, .pi + 0.3, true)
            rh = (78, 22, .pi - 0.3, true)
        case .startled:
            sy = 1.05
            reach = 2
            lift = 2
            tip = 5
            lh = (11, 84 + 2 * f.swing2, 0.4, true)
            rh = (91, 86 - 2 * f.swing2, -0.4, true)
        case .fleeing:
            fx = 2.5
            rot = -0.06
            reach = 9
            tip = -7 + 2 * f.swing
            lh = (8, 52 - 8 * f.swing, 1.7, true)
            rh = (92, 54 + 8 * f.swing, -1.2, false)
        case .dizzy:
            rot = 0.12 * sin(t)
            tip = 4 * sin(t)
            lh = (12, 40 + 4 * f.swing, 2.4, true)
            rh = (88, 40 - 4 * f.swing, -2.4, true)
        }
        let v = f.variant % 5
        let suit = v == 3 ? k.accents[1] : k.red
        let look: CGFloat = fx > 0 ? 1 : 0
        k.with(about(50, 4, rot: rot, sx: 1, sy: sy)) {
            for which in [1, 0] {
                let s = k.step(which, reach: reach, lift: lift)
                let hx: CGFloat = which == 0 ? 57 : 43
                let bx = hx + s.x, byy = 4 + s.y
                k.noodle(k.bend(hx, 22 + bob, bx, byy + 4, sag: which == 0 ? 2.5 : -2.5))
                k.boot(bx, byy, 0, color: k.ink)
            }
            k.with(CGAffineTransform(translationX: 0, y: bob)) {
                if v == 1 && f.mood != .startled {
                    let sack = smooth([18, 46, 30, 42, 38, 52, 36, 70, 28, 78, 18, 76, 10, 64, 11, 52], t: 0.8)
                    k.part(sack, k.cream.mix(Tone(0xc8a070), 0.35))
                    k.stroke(arc(14, 56, 34, 58, dip: 2), k.ink, k.line * 0.6)
                    k.part(ell(25, 80, 5, 3, 0.3), k.red, w: k.line * 0.8)
                }
                hoseFestiveArm(k, 33, 46, (lh.x, lh.y - bob, lh.a, lh.open), sag: 4)
                if v == 2 {
                    k.with(CGAffineTransform(translationX: lh.x, y: lh.y - bob).rotated(by: lh.a + 0.3 * f.swing2)) {
                        k.stroke(line(0, 8, 0, 15), k.ink, k.line)
                        k.part(smooth([-5, 14, 5, 14, 3.5, 21, 0, 23, -3.5, 21], t: 0.6), k.accents[2], w: k.line * 0.8)
                        k.part(circ(0, 13.4, 1.8), k.ink, w: k.line * 0.5)
                    }
                }
                let body = ell(50, 37, 22, 19.5)
                k.fill(body, suit)
                k.clip(body) {
                    k.fill(rrect(20, 14, 60, 8, 0), k.cream)
                    k.fill(rrect(54, 14, 7, 44, 0), k.cream)
                    k.fill(rrect(20, 30, 60, 7, 0), k.ink)
                }
                k.stroke(body, k.ink, k.line)
                k.stroke(rrect(53, 29.4, 9, 8.2, 1.4), k.accents[2], k.line * 0.9)
                k.shine(36, 46, 3.6, 2, 0.6)
                hoseFestiveArm(k, 67, 46, (rh.x, rh.y - bob, rh.a, rh.open), sag: -4, scale: 0.95)
                if v == 4 { hoseFestiveGift(k, rh.x - 4, rh.y - bob - 2, s: 0.85, box: k.accents[1], ribbon: k.red) }
                k.part(circ(53, 65, 12), k.cream)
                let beard = smooth([38, 64, 68, 64, 70, 55, 66, 48, 62, 43, 58, 38, 53, 40.5, 48, 37.5, 44, 42, 40, 46, 37, 54], t: 0.85)
                k.part(beard, k.cream)
                k.eye(49 + fx, 69, 2.2, 3.8, look: look)
                k.eye(57 + fx, 69, 2.2, 3.8, look: look)
                k.mouth(54 + fx, 56.5, 8, 2.6)
                k.part(ell(49 + fx, 60.5, 5.6, 3.1, 0.25), k.cream, w: k.line * 0.8)
                k.part(ell(59 + fx, 60.5, 5.6, 3.1, -0.25), k.cream, w: k.line * 0.8)
                k.part(circ(54 + fx, 63.5, 2.8), k.red, w: k.line * 0.8)
                let cone = smooth([40, 71, 67, 73, 62, 83, 52, 90, 38 + tip * 0.4, 94 + tip * 0.3, 30 + tip, 89 + tip * 0.4, 43, 82], t: 0.55)
                k.part(cone, suit)
                k.with(about(53, 72, rot: -0.05)) { k.part(rrect(38, 68.5, 31, 7.5, 3.7), k.cream) }
                k.part(circ(30 + tip, 88.5 + tip * 0.4, 4.8), k.cream, w: k.line * 0.8)
                k.marks(f.mood == .fleeing ? 22 : 78, 84, 13)
            }
        }
    }
}
