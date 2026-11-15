import Foundation
import CoreGraphics
import ScuttleCore

extension HoseArt {
    private typealias HosePartyHand = (x: CGFloat, y: CGFloat, a: CGFloat, open: Bool)

    private static func hosePartyHand(_ k: HoseKit, _ h: HosePartyHand, _ s: CGFloat = 1) {
        if h.open { k.glove(h.x, h.y, h.a, s) } else { k.fist(h.x, h.y, h.a, s) }
    }

    private static func hosePartyBlob(_ k: HoseKit, _ ps: [CGPath], _ tone: Tone) {
        for p in ps { k.stroke(p, k.ink, k.line * 2) }
        for p in ps { k.fill(p, tone) }
    }

    private static func hosePartyBowtie(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ tone: Tone, rot: CGFloat = 0) {
        k.with(about(x, y, rot: rot, sx: s, sy: s)) {
            let w = k.line * 0.8 / s
            let l = poly([x, y, x - 7, y + 4.4, x - 7, y - 4.4])
            k.part(l, tone, w: w)
            k.part(mirror(l, x), tone, w: w)
            k.part(circ(x, y, 2.3), tone, w: w)
        }
    }

    private static func hosePartyTopHat(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, rot: CGFloat, band: Tone) {
        k.with(about(x, y, rot: rot, sx: s, sy: s)) {
            let crown = rrect(x - 8, y, 16, 14, 1.6)
            k.solid(crown)
            k.clip(crown) { k.fill(rrect(x - 9, y + 1.6, 18, 3.8, 0), band) }
            k.solid(ell(x, y + 0.5, 12.5, 2.8))
            k.shine(x - 4.5, y + 10, 1.1, 2.6, 0)
        }
    }

    private static func hosePartyCone(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, rot: CGFloat, tone: Tone) {
        k.with(about(x, y, rot: rot, sx: s, sy: s)) {
            let cone = poly([x - 8.5, y, x + 8.5, y, x, y + 21])
            k.fill(cone, tone)
            k.clip(cone) {
                k.fill(poly([x - 10, y + 5, x + 10, y + 8, x + 10, y + 12, x - 10, y + 9]), k.cream)
            }
            k.stroke(cone, k.ink, k.line / s)
            k.part(circ(x, y + 22, 3.2), k.cream, w: k.line * 0.8 / s)
        }
    }

    private static func hosePartySparkle(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ tone: Tone) {
        guard r > 1 else { return }
        k.part(star(x, y, r, points: 4, inner: 0.34), tone, w: k.line * 0.7)
    }

    static func balloon(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t
        let v = f.variant % 5
        let tone = f.pick([k.red, k.accents[3], k.accents[2], k.ink, k.accents[4]])
        var rot: CGFloat = 0.04 * f.swing
        var sx: CGFloat = 1 + 0.025 * f.swing2
        var sy: CGFloat = 1 - 0.025 * f.swing2
        var faceX: CGFloat = 0, trail: CGFloat = 0, sag: CGFloat = 3
        var lh: HosePartyHand = (13, 74 + 2 * f.swing, 0.5 + 0.3 * f.swing, true)
        var rh: HosePartyHand = (87, 47, .pi - 0.3, true)
        switch f.mood {
        case .calm:
            lh.y += 3 * f.twitch
            lh.a -= 0.35 * f.twitch
        case .sleepy:
            sx = 1.07
            sy = 0.9
            rot = 0.1
            sag = 2
            lh = (25, 38, .pi + 0.2, true)
            rh = (76, 37, .pi - 0.2, true)
        case .startled:
            sx = 0.93
            sy = 1.1
            sag = 5
            lh = (12, 93 + 2 * f.swing2, 0.35, true)
            rh = (88, 95 - 2 * f.swing2, -0.35, true)
        case .fleeing:
            rot = -0.06
            faceX = 3
            trail = 1
            sag = 5 * f.swing
            lh = (6, 54 + 3 * f.swing, 1.9, true)
            rh = (14, 76 - 3 * f.swing, 1.3, false)
        case .dizzy:
            rot = 0.13 * sin(t)
            sag = 8
            lh = (13, 46 + 4 * f.swing, 2.4, true)
            rh = (87, 44 - 4 * f.swing, -2.4, true)
        }
        let s1: CGFloat = 50 + 4 * sin(t) - 5 * trail
        let s2: CGFloat = 50 - 3 * sin(t + 1.2) - 11 * trail
        let s3: CGFloat = 50 + 3 * sin(t + 2.4) - 18 * trail
        k.with(about(50, 30, rot: rot, sx: sx, sy: sy)) {
            k.stroke(smooth([50, 28, s1, 19, s2, 10, s3, 1], closed: false), k.ink, k.line)
            k.noodle(k.bend(28, 64, lh.x, lh.y, sag: sag))
            hosePartyHand(k, lh)
            k.noodle(k.bend(72, 58, rh.x, rh.y, sag: -sag))
            hosePartyHand(k, rh, 0.95)
            let body = smooth([50, 89, 67, 85, 75, 68, 71, 48, 60, 34, 50, 31, 40, 34, 29, 48, 25, 68, 33, 85])
            k.part(poly([45, 26.5, 55, 26.5, 50, 33]), tone)
            k.part(body, tone)
            if v == 3 {
                k.clip(body) {
                    for d in [(31.0, 52.0), (36.0, 79.0), (65.0, 83.0), (71.0, 42.0), (45.0, 38.0)] as [(CGFloat, CGFloat)] {
                        k.fill(circ(d.0, d.1, 3.4), k.cream)
                    }
                }
            }
            k.shine(35, 74, 3.2, 6.5, 0.5)
            let fx = faceX
            hosePartyBlob(k, [circ(49.5 + fx, 65, 7.6), circ(60 + fx, 65, 7.6), ell(55 + fx, 53, 13, 9)], k.cream)
            k.eye(50 + fx, 65.5, 2.8, 4.8, look: fx > 0 ? 1 : 0)
            k.eye(60 + fx, 65.5, 2.8, 4.8, look: fx > 0 ? 1 : 0)
            k.mouth(55 + fx, 55, 12, 4)
            switch v {
            case 1: hosePartyBowtie(k, 50, 29, 0.85, k.red)
            case 2: hosePartyCone(k, 57, 84, 0.8, rot: -0.3, tone: k.red)
            case 4: hosePartyTopHat(k, 54, 86, 0.85, rot: -0.15, band: k.red)
            default: break
            }
            k.marks(f.mood == .fleeing ? 26 : 80, 90, 13)
        }
    }

    static func star(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t
        let v = f.variant % 5
        let tone = f.pick([k.accents[2], k.cream, k.red, k.accents[2], k.accents[3]])
        var aR: CGFloat = 0.1 * f.swing, aL: CGFloat = 0.1 * f.swing
        var lR: CGFloat = 0.06 * f.swing2, lL: CGFloat = -0.06 * f.swing2, top: CGFloat = 0.06 * f.sway
        var rot: CGFloat = 0, sx: CGFloat = 1, sy: CGFloat = 1, faceX: CGFloat = 0, twinkle: CGFloat = 1
        var openR = true, openL = true
        switch f.mood {
        case .calm:
            aR += 0.35 * max(0, f.twitch)
        case .sleepy:
            aR = -0.4
            aL = -0.4
            top = 0.3
            sx = 1.05
            sy = 0.9
            twinkle = 0
        case .startled:
            aR = 0.55
            aL = 0.55
            lR = 0.25
            lL = 0.25
            sx = 0.95
            sy = 1.08
            twinkle = 1.4
        case .fleeing:
            rot = -0.15
            faceX = 3
            aR = 0.35 + 0.2 * f.swing
            aL = -0.5 + 0.25 * f.swing
            lR = -0.15 * f.swing
            lL = 0.15 * f.swing
            openR = false
        case .dizzy:
            rot = 0.14 * sin(t)
            aR = 0.35 * sin(t)
            aL = -0.35 * sin(t)
            top = 0.25 * sin(t)
            twinkle = 0.5
        }
        let outer: [CGFloat] = [.pi / 2 + top, 0.314 + aR, -0.942 + lR, -2.199 - lL, -3.456 - aL]
        let radii: [CGFloat] = [40, 41, 39, 39, 41]
        var pts: [CGPoint] = []
        for i in 0..<5 {
            let a = outer[i]
            pts.append(pt(50 + radii[i] * cos(a), 50 + radii[i] * sin(a)))
            let next = i == 4 ? outer[0] - 2 * .pi : outer[i + 1]
            let m = (a + next) / 2
            pts.append(pt(50 + 18 * cos(m), 50 + 18 * sin(m)))
        }
        let body = smoothP(pts, t: 0.7)
        k.with(about(50, 50, rot: rot, sx: sx, sy: sy)) {
            for i in 0..<2 {
                let a = outer[i == 0 ? 1 : 4]
                let r: CGFloat = 36
                let h: HosePartyHand = (50 + r * cos(a), 50 + r * sin(a), a - .pi / 2, i == 0 ? openR : openL)
                hosePartyHand(k, h, 1.2)
            }
            k.part(body, tone)
            let fx = faceX
            if v != 1 { k.part(circ(52 + fx, 49.5, 14.5), k.cream) }
            k.eye(47.5 + fx, 53, 2.6, 4.4, look: fx > 0 ? 1 : 0)
            k.eye(56.5 + fx, 53, 2.6, 4.4, look: fx > 0 ? 1 : 0)
            k.mouth(52 + fx, 45, 10, 3.4)
            let tip = pt(50 + 30 * cos(outer[0]), 50 + 30 * sin(outer[0]))
            switch v {
            case 1: hosePartyBowtie(k, 51, 33, 0.75, k.red)
            case 2: hosePartyCone(k, tip.x, tip.y, 0.8, rot: top, tone: k.accents[2])
            case 3: hosePartyBowtie(k, 33, 70, 0.75, k.red, rot: 0.7)
            case 4: hosePartyTopHat(k, tip.x, tip.y - 1, 0.8, rot: top, band: k.red)
            default: break
            }
            k.marks(f.mood == .fleeing ? 22 : 80, 82, 13)
        }
        if twinkle > 0 {
            for (i, p) in ([(88.0, 84.0), (12.0, 18.0)] as [(CGFloat, CGFloat)]).enumerated() {
                let r = twinkle * 6 * (0.55 + 0.45 * sin(2 * t + CGFloat(i) * .pi))
                hosePartySparkle(k, p.0, p.1, r, k.cream)
            }
        }
    }

    private static func sparklerBurst(_ f: FigureFrame, _ k: HoseKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ fire: Tone, stream: CGFloat) {
        let n = 10
        let flick: CGFloat = f.frameIndex % 2 == 0 ? 1 : 0.82
        let spin: CGFloat = CGFloat(f.frameIndex % 4) * .pi / CGFloat(2 * n)
        for i in 0..<n {
            let a = CGFloat(i) * 2 * .pi / CGFloat(n) + spin
            let len: CGFloat = (i % 2 == 0 ? 16 : 11) * s * (i % 2 == 0 ? flick : 1.82 - flick)
            let back = stream * max(0, -cos(a) * 0.6 + 0.4) * 10
            let ray = line(x + cos(a) * 5 * s, y + sin(a) * 5 * s, x + cos(a) * len - back, y + sin(a) * len)
            k.stroke(ray, k.ink, k.line * 1.9)
            k.stroke(ray, fire, k.line * 0.8)
        }
        k.part(star(x, y, 9 * s, points: 8, inner: 0.55, spin: spin), fire)
        k.fill(circ(x, y, 3.6 * s), k.cream)
        var rng = Noise(f.frameIndex * 31 + 7)
        for _ in 0..<3 {
            let a = rng.range(0, 2 * .pi)
            let d = rng.range(15, 21) * s
            hosePartySparkle(k, x + cos(a) * d - stream * 8, y + sin(a) * d, 3.6 * s, k.cream)
        }
    }

    static func sparkler(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t
        let v = f.variant % 5
        let body = f.pick([k.ink, k.red, k.ink, k.accents[3], k.cream])
        let fire = f.pick([k.accents[2], k.accents[2], k.red, k.accents[2], k.red])
        let boots = f.pick([k.red, k.ink, k.red, k.red, k.ink])
        var rot: CGFloat = 0, sy: CGFloat = 1, faceX: CGFloat = 0, burst: CGFloat = 1, stream: CGFloat = 0
        var reach: CGFloat = 9, lift: CGFloat = 6, sag: CGFloat = 3
        var splay = false
        var lh: HosePartyHand = (30 - 5 * f.swing, 30 + 1.5 * f.swing, .pi + 0.5 - 0.4 * f.swing, true)
        var rh: HosePartyHand = (70 + 5 * f.swing, 30 - 1.5 * f.swing, .pi - 0.5 - 0.4 * f.swing, true)
        switch f.mood {
        case .calm:
            if f.twitch > 0 { rh = (79, 60, -0.35, true) }
        case .sleepy:
            reach = 3
            lift = 1.5
            sy = 0.94
            rot = 0.05
            burst = 0.55
            lh = (37, 24, .pi + 0.1, true)
            rh = (63, 24, .pi - 0.1, true)
            sag = 1.5
        case .startled:
            splay = true
            sy = 1.06
            burst = 1.35
            lh = (22, 74, 0.5, true)
            rh = (78, 76, -0.5, true)
            sag = 4
        case .fleeing:
            reach = 11
            lift = 8
            faceX = 3
            stream = 1
            sag = 5
            lh = (28 - 9 * f.swing, 46 + 6 * f.swing, 1.2 - 0.6 * f.swing, false)
            rh = (72 + 9 * f.swing, 46 - 6 * f.swing, -1.2 - 0.6 * f.swing, false)
        case .dizzy:
            rot = 0.12 * sin(t)
            burst = 0.9
            sag = 7
            lh = (18, 50 + 4 * f.swing, 2.0, true)
            rh = (82, 48 - 4 * f.swing, -2.0, true)
        }
        let bob: CGFloat = splay ? 0 : 1.5 * f.bounce * f.energy
        k.with(about(50, 4, rot: rot)) {
            for which in 0..<2 {
                let hx: CGFloat = which == 0 ? 45 : 55
                var s = k.step(which, reach: reach * f.energy, lift: lift * f.energy)
                if splay { s = CGPoint(x: which == 0 ? -9 : 9, y: 0) }
                k.noodle(k.bend(hx, 26 + bob, hx + s.x, 8 + s.y, sag: which == 0 ? 3 : -3))
                k.boot(hx + s.x, 4 + s.y, 0, color: boots)
            }
            k.with(about(50, 24 + bob, sy: sy).translatedBy(x: 0, y: bob + 4)) {
                k.noodle(k.bend(40, 48, lh.x, lh.y, sag: sag))
                hosePartyHand(k, lh)
                k.stroke(line(50, 66, 50, 76), k.ink, k.line * 1.2)
                sparklerBurst(f, k, 50 - 2 * stream, 80, burst, fire, stream: stream)
                let rod = rrect(38, 20, 24, 48, 12)
                if body.luma < 0.2 { k.solid(rod) } else { k.part(rod, body) }
                k.clip(rod) {
                    if v == 3 { k.fill(rrect(30, 26, 40, 5, 0), k.cream) }
                    if v == 4 {
                        for i in 0..<5 {
                            let y0 = CGFloat(i) * 12 + 8
                            k.fill(poly([30, y0, 70, y0 + 14, 70, y0 + 19, 30, y0 + 5]), k.red)
                        }
                    }
                }
                if v == 4 { k.stroke(rod, k.ink, k.line) }
                if body.luma < 0.2 { k.shine(42, 38, 1.6, 4, 0.1) }
                if v == 1 {
                    k.part(circ(50, 34, 2.2), k.cream, w: k.line * 0.7)
                    k.part(circ(50, 27, 2.2), k.cream, w: k.line * 0.7)
                }
                let fx = faceX
                hosePartyBlob(k, [circ(48.5 + fx, 56, 6), circ(57.5 + fx, 56, 6), ell(53 + fx, 47, 9.5, 7)], k.cream)
                k.eye(49 + fx, 56.5, 2.3, 4, look: fx > 0 ? 1 : 0)
                k.eye(57.5 + fx, 56.5, 2.3, 4, look: fx > 0 ? 1 : 0)
                k.mouth(53.5 + fx, 48, 9.5, 3.2)
                if v == 2 { hosePartyBowtie(k, 52, 37, 0.75, k.red) }
                k.noodle(k.bend(60, 48, rh.x, rh.y, sag: -sag))
                hosePartyHand(k, rh, 0.95)
                k.marks(f.mood == .fleeing ? 24 : 74, 70, 12)
            }
        }
    }

    private static func rocketFlame(_ x: CGFloat, _ y: CGFloat, _ len: CGFloat, _ hw: CGFloat, _ flick: CGFloat) -> CGPath {
        smooth([x + 2, y + hw, x - len * 0.35, y + hw * 1.05, x - len * 0.75, y + hw * 0.45 + flick, x - len, y + flick * 1.5,
                x - len * 0.7, y - hw * 0.4 + flick, x - len * 0.3, y - hw * 1.05, x + 2, y - hw], t: 0.85)
    }

    static func rocket(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t
        let v = f.variant % 5
        let fi = f.frameIndex
        let hull = f.pick([k.cream, k.cream, k.ink, k.cream, k.red])
        let trim = f.pick([k.red, k.accents[3], k.red, k.accents[1], k.cream])
        var flame: CGFloat = 1, rot: CGFloat = 0, sx: CGFloat = 1, sy: CGFloat = 1, faceX: CGFloat = 0
        var arm: HosePartyHand = (84, 75 + 2 * f.twitch, -1.35 + 0.15 * f.twitch, false)
        var arm2: HosePartyHand? = nil
        var puffs = false
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            flame = 0.45
            rot = -0.05
            arm = (36, 70, 2.2, true)
        case .startled:
            flame = 1.25
            sx = 1.05
            sy = 0.96
            arm = (62, 92, -0.25, true)
            arm2 = (62, 8, .pi + 0.25, true)
        case .fleeing:
            flame = 1.7
            faceX = 2
            arm = (92, 70, -1.5, false)
        case .dizzy:
            rot = 0.12 * sin(t)
            flame = 0.8
            puffs = true
            arm = (70, 86 + 4 * f.swing, -0.6 + 0.5 * f.swing, true)
        }
        let flick: CGFloat = 2.2 * sin(3 * t) + (fi % 2 == 0 ? 1 : -1)
        let len: CGFloat = 24 * flame * (fi % 2 == 0 ? 1 : 0.87)
        k.with(about(50, 50, rot: rot, sx: sx, sy: sy)) {
            if puffs {
                for i in 0..<3 {
                    let u = (CGFloat(fi % 8) / 8 + CGFloat(i) / 3).truncatingRemainder(dividingBy: 1)
                    k.part(circ(8 - 26 * u, 50 + 6 * sin(CGFloat(i) * 2.1 + t), 3 + 4 * u), k.cream, w: k.line * 0.8)
                }
            }
            k.part(rocketFlame(14, 50, len, 9, flick), k.red)
            k.part(rocketFlame(14, 50, len * 0.68, 6, flick * 0.7), k.accents[2], w: k.line * 0.8)
            k.fill(rocketFlame(14, 50, len * 0.36, 3.2, flick * 0.4), k.cream)
            let fin = smooth([23, 58, 37, 62, 28, 75, 15, 78, 16, 66], t: 0.7)
            let flip = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 100)
            let finTone = v == 4 ? k.ink : trim
            k.part(fin, finTone)
            k.part(xf(fin, flip), finTone)
            k.solid(rrect(13, 42, 10, 16, 2.5))
            if let a2 = arm2 {
                k.noodle(k.bend(54, 38, a2.x, a2.y, sag: 4))
                hosePartyHand(k, a2, 0.95)
            }
            k.noodle(k.bend(52, 62, arm.x, arm.y, sag: -4))
            let shell = smooth([93, 50, 86, 58, 74, 63, 42, 63, 26, 61, 21, 50, 26, 39, 42, 37, 74, 37, 86, 42], t: 0.8)
            k.fill(shell, hull)
            k.clip(shell) {
                k.fill(rrect(77, 30, 30, 40, 0), trim)
                k.fill(rrect(15, 30, 12, 40, 0), trim)
                if v == 3 {
                    for i in 0..<4 {
                        for j in 0..<2 {
                            if (i + j) % 2 == 0 { k.fill(rrect(36 + CGFloat(i) * 4, 50 + CGFloat(j - 1) * 13, 4, 13, 0), k.ink) }
                        }
                    }
                }
                if v == 4 { k.fill(rrect(15, 46, 70, 8, 0), k.cream) }
            }
            k.stroke(smooth([77, 63.5, 79.5, 50, 77, 36.5], closed: false), k.ink, k.line)
            k.stroke(smooth([27, 61, 28.5, 50, 27, 39], closed: false), k.ink, k.line)
            k.stroke(shell, k.ink, k.line)
            if hull.luma < 0.5 { k.shine(40, 58, 1.6, 4.5, 1.4) }
            if v == 1 {
                k.part(circ(40, 50, 7.5), trim)
                k.fill(star(40, 50, 5.5), k.cream)
            }
            let fx = faceX
            if v == 2 || v == 4 { k.part(circ(64.5 + fx, 51, 11.5), k.cream) }
            k.eye(60 + fx, 54.5, 2.5, 4.3, look: 1)
            k.eye(68.5 + fx, 54.5, 2.5, 4.3, look: 1)
            k.mouth(64.5 + fx, 46, 10, 3.4)
            hosePartyHand(k, arm, 0.95)
            k.marks(f.mood == .fleeing ? 46 : 80, 72, 12)
        }
    }

    private static func bunnyEar(_ k: HoseKit, _ x: CGFloat, _ y: CGFloat, _ a: CGFloat, _ len: CGFloat, _ inner: Tone) {
        k.with(CGAffineTransform(translationX: x, y: y).rotated(by: a)) {
            let ear = smooth([0, -2, 5.6, len * 0.35, 4.6, len * 0.85, 0, len + 1, -4.6, len * 0.85, -5.6, len * 0.35])
            k.part(ear, k.cream)
            k.fill(ell(0.4, len * 0.55, 2.5, len * 0.32), inner)
        }
    }

    static func bunny(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t
        let v = f.variant % 5
        let boots = f.pick([k.red, k.red, k.red, k.accents[1], k.accents[3]])
        let sq = f.squat, st = f.stretch
        let tuck: CGFloat = f.airborne ? 1 - abs(st) : 0
        let up: CGFloat = f.airborne ? 1 - 0.5 * abs(st) : 0
        var sy: CGFloat = 1 - 0.16 * sq + 0.1 * st
        var sx: CGFloat = 1 + 0.1 * sq - 0.05 * st
        var rot: CGFloat = 0, faceX: CGFloat = 0, earLen: CGFloat = 26, sag: CGFloat = 3
        var footDX: CGFloat = f.airborne ? -7 * st : 0
        var footY: CGFloat = 4 + 9 * tuck
        var earB: CGFloat = 0.32 + 0.25 * max(0, st), earF: CGFloat = -0.06 + 0.2 * max(0, st)
        var lh: HosePartyHand = (34, 34 + 26 * up, lerp(.pi - 0.4, 0.5, up), true)
        var rh: HosePartyHand = (72, 36 + 26 * up, lerp(.pi + 0.4, -0.5, up), v != 3)
        switch f.mood {
        case .calm:
            earF += 0.2 * f.twitch
        case .sleepy:
            sy *= 0.92
            sx *= 1.04
            earB = 1.9
            earF = 1.55
            footDX = 0
            footY = 4 + 3 * tuck
            sag = 1.5
            lh = (40, 25, .pi + 0.15, true)
            rh = (62, 25, .pi - 0.15, v != 3)
        case .startled:
            sy *= 1.06
            earB = 0.08
            earF = -0.08
            earLen = 30
            sag = 4
            lh = (24, 72, 0.5, true)
            rh = (82, 74, -0.5, true)
        case .fleeing:
            faceX = 2.5
            earB = 1.3
            earF = 1.05
            footDX = f.airborne ? -11 * st : 0
            sag = 4
            lh = (28 - 6 * f.swing, 46, 1.6, false)
            rh = (78 + 5 * f.swing, 50, -1.2, false)
        case .dizzy:
            rot = 0.12 * sin(t)
            earB = 0.5 + 0.5 * sin(t)
            earF = -0.3 + 0.5 * sin(t + 1.3)
            sag = 7
            lh = (20, 50 + 4 * f.swing, 2.2, true)
            rh = (84, 48 - 4 * f.swing, -2.2, true)
        }
        let bootRot: CGFloat = f.airborne ? -0.35 * st : 0
        k.with(about(50, 4, rot: rot, sx: sx, sy: sy)) {
            k.noodle(k.bend(44, 22, 39 + footDX, footY + 4, sag: 3))
            k.with(about(39 + footDX, footY, rot: bootRot, sx: 1.08, sy: 1.08)) { k.boot(39 + footDX, footY, 0, color: boots) }
            k.noodle(k.bend(44, 44, lh.x, lh.y, sag: sag))
            hosePartyHand(k, lh, 0.95)
            k.part(circ(31, 30 + 1.5 * f.twitch, 6.5), k.cream)
            k.noodle(k.bend(53, 22, 57 + footDX, footY + 4 + tuck, sag: -3))
            k.with(about(57 + footDX, footY + tuck, rot: bootRot, sx: 1.08, sy: 1.08)) { k.boot(57 + footDX, footY + tuck, 0, color: boots) }
            k.part(ell(47, 33, 15, 17), k.cream)
            bunnyEar(k, 50, 69, earB, earLen, k.red)
            bunnyEar(k, 58, 71, earF, earLen, k.red)
            hosePartyBlob(k, [circ(56, 60, 14), ell(62, 54, 11, 8.5)], k.cream)
            let fx = faceX
            k.eye(54 + fx, 63, 2.5, 4.4, look: fx > 0 ? 1 : 0)
            k.eye(62 + fx, 63, 2.5, 4.4, look: fx > 0 ? 1 : 0)
            k.fill(ell(69.5 + fx, 57.5, 2.6, 2), k.ink)
            k.mouth(63 + fx, 52.5, 11, 3.6)
            if f.mood == .calm || f.mood == .dizzy {
                let teeth = rrect(61 + fx, 47.4, 4.6, 4.4, 1)
                k.part(teeth, k.cream, w: k.line * 0.6)
                k.stroke(line(63.3 + fx, 47.6, 63.3 + fx, 51.4), k.ink, k.line * 0.45)
            }
            switch v {
            case 1: hosePartyBowtie(k, 52, 45, 0.8, k.red)
            case 2: hosePartyTopHat(k, 56, 72.5, 0.85, rot: -0.15, band: k.red)
            case 4:
                k.part(smooth([42, 48, 62, 46.5, 51, 36], t: 0.35), k.accents[3])
                k.fill(circ(49, 43, 1.3), k.cream)
                k.fill(circ(54, 42, 1.3), k.cream)
            default: break
            }
            k.noodle(k.bend(55, 42, rh.x, rh.y, sag: -sag))
            if v == 3 {
                k.with(CGAffineTransform(translationX: rh.x, y: rh.y).rotated(by: rh.a)) {
                    k.part(smooth([-3.2, 2, 3.2, 2, 1.2, 22, -1.2, 22], t: 0.6), Tone(0xe8792a))
                    k.stroke(line(-1, -1, -3, -6), k.accents[1], k.line * 1.1)
                    k.stroke(line(1, -1, 3, -6), k.accents[1], k.line * 1.1)
                }
            }
            hosePartyHand(k, rh, 0.95)
            k.marks(f.mood == .fleeing ? 30 : 76, 82, 13)
        }
    }

    private static func turtlePlate(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> CGPath {
        var a: [CGFloat] = []
        for i in 0..<6 {
            let ang = CGFloat(i) * .pi / 3
            a += [x + r * cos(ang), y + r * 0.92 * sin(ang)]
        }
        return smooth(a, t: 0.35)
    }

    static func turtle(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t
        let v = f.variant % 5
        let shell = f.pick([k.accents[1], k.red, k.accents[2], k.accents[1], k.accents[3]])
        let spot = shell.mix(k.cream, 0.5)
        let rim = f.pick([k.cream, k.cream, k.red, k.red, k.cream])
        var rot: CGFloat = 0.03 * f.swing, lift: CGFloat = 0, reach: CGFloat = 5, step: CGFloat = 4
        var head = (x: CGFloat(83), y: 37 + 1.2 * f.swing2, tilt: 0.12 * f.twitch)
        var tucked = false, splay = false, legLen: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            tucked = true
            head = (79, 27, -0.12)
            reach = 0
            step = 0
            legLen = -4
        case .startled:
            head = (86, 55, 0.1)
            lift = 4
            splay = true
        case .fleeing:
            head = (90, 32 + 1.5 * f.swing2, -0.15)
            reach = 8
            step = 6
        case .dizzy:
            rot = 0.12 * sin(t)
            head = (82, 34 + 3 * sin(t), 0.2 * sin(t + 1))
        }
        let bob: CGFloat = 0.8 * f.bounce * f.energy + lift
        k.with(about(48, 4, rot: rot)) {
            let legs: [(x: CGFloat, which: Int, far: Bool)] = [(38, 1, true), (68, 0, true), (28, 0, false), (59, 1, false)]
            func leg(_ l: (x: CGFloat, which: Int, far: Bool)) {
                var s = k.step(l.which, reach: reach * f.energy, lift: step * f.energy)
                if splay { s = CGPoint(x: l.x < 48 ? -6 : 6, y: 0) }
                k.noodle(k.bend(l.x, 20 + bob, l.x + s.x, 9 + s.y - legLen * 0.5, sag: 2))
                k.with(about(l.x + s.x, 4 + s.y, sx: 0.78, sy: 0.78)) {
                    k.boot(l.x + s.x, 4 + s.y - legLen * 0.4, 0, color: k.red)
                }
            }
            for l in legs where l.far { leg(l) }
            k.part(poly([17, 25 + bob, 17, 17 + bob, 6, 19 + bob + 2 * f.twitch]), k.cream)
            func drawHead() {
                if !tucked {
                    let neck = smooth([64, 24 + bob, (64 + head.x) / 2, (24 + bob + head.y) / 2 - 3, head.x - 3, head.y - 2], closed: false)
                    k.stroke(neck, k.ink, 10 + 2 * k.line)
                    k.stroke(neck, k.cream, 10)
                }
                k.with(about(head.x, head.y, rot: head.tilt)) {
                    let hx = head.x, hy = head.y
                    hosePartyBlob(k, [circ(hx, hy, 11), ell(hx + 5, hy - 3, 8, 6.5)], k.cream)
                    k.eye(hx - 2, hy + 3, 2.3, 4, look: 1)
                    k.eye(hx + 5, hy + 3, 2.3, 4, look: 1)
                    k.mouth(hx + 3.5, hy - 4.5, 9, 3)
                    switch v {
                    case 1: hosePartyBowtie(k, hx - 6, hy - 9, 0.65, k.ink)
                    case 2: hosePartyCone(k, hx + 1, hy + 9, 0.7, rot: -0.2, tone: k.red)
                    case 3: hosePartyTopHat(k, hx + 1, hy + 9, 0.75, rot: -0.15, band: k.red)
                    default: break
                    }
                }
            }
            if tucked { drawHead() }
            let dome = smooth([14, 21, 18, 37, 31, 52, 48, 57, 65, 52, 77, 37, 80, 21, 64, 17, 32, 17], t: 0.8)
            k.with(CGAffineTransform(translationX: 0, y: bob)) {
                k.part(dome, shell)
                k.clip(dome) {
                    for c in [(47.0, 38.0), (31.0, 30.0), (63.0, 30.0), (39.0, 54.0), (55.0, 54.0), (19.0, 46.0), (75.0, 46.0)] as [(CGFloat, CGFloat)] {
                        k.fill(turtlePlate(c.0, c.1, 7.6), spot)
                    }
                }
                k.stroke(dome, k.ink, k.line)
                k.shine(30, 47, 2, 4.5, 0.7)
                k.part(rrect(11, 14.5, 72, 9, 4.5), rim)
                if v == 4 {
                    k.part(smooth([62, 24, 74, 22, 66, 13], t: 0.35), k.red)
                    k.fill(circ(67, 19, 1.2), k.cream)
                }
            }
            for l in legs where !l.far { leg(l) }
            if !tucked { drawHead() }
            k.marks(f.mood == .fleeing ? 70 : head.x + 6, max(60, head.y + 16), 12)
        }
    }

    static func fox(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t
        let v = f.variant % 5
        let fur = f.pick([k.red, k.red, k.accents[2], k.red, k.ink])
        let boots = f.pick([k.ink, k.ink, k.ink, k.ink, k.red])
        var rot: CGFloat = 0, sy: CGFloat = 1, faceX: CGFloat = 0, headRot: CGFloat = 0
        var tailRot: CGFloat = 0.1 * f.swing, earTw: CGFloat = 0.18 * f.twitch
        var reach: CGFloat = 7, lift: CGFloat = 5, sag: CGFloat = 3, splay = false
        var lh: HosePartyHand = (32 - 5 * f.swing, 32 + 1.5 * f.swing, .pi + 0.45 - 0.35 * f.swing, true)
        var rh: HosePartyHand = (68 + 5 * f.swing, 32 - 1.5 * f.swing, .pi - 0.45 - 0.35 * f.swing, true)
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            reach = 3
            lift = 1.5
            sy = 0.95
            headRot = -0.12
            tailRot = 1.0
            earTw = 0.3
            sag = 1.5
            lh = (39, 26, .pi + 0.1, true)
            rh = (62, 26, .pi - 0.1, true)
        case .startled:
            splay = true
            sy = 1.05
            tailRot = -0.35
            earTw = -0.15
            sag = 4
            lh = (24, 78, 0.5, true)
            rh = (80, 80, -0.5, true)
        case .fleeing:
            reach = 11
            lift = 8
            faceX = 2
            tailRot = 0.85 + 0.1 * f.swing
            earTw = 0.35
            sag = 5
            lh = (30 - 9 * f.swing, 50 + 5 * f.swing, 1.2 - 0.6 * f.swing, false)
            rh = (72 + 9 * f.swing, 50 - 5 * f.swing, -1.2 - 0.6 * f.swing, false)
        case .dizzy:
            rot = 0.12 * sin(t)
            tailRot = 0.3 * sin(t)
            sag = 7
            lh = (20, 54 + 4 * f.swing, 2.1, true)
            rh = (82, 52 - 4 * f.swing, -2.1, true)
        }
        let bob: CGFloat = splay ? 0 : 1.5 * f.bounce * f.energy
        k.with(about(50, 4, rot: rot)) {
            k.with(about(40, 30 + bob, rot: tailRot)) {
                let tail = smooth([42, 32 + bob, 30, 25 + bob, 18, 31 + bob, 11, 46 + bob, 12, 62 + bob, 19, 71 + bob, 22, 58 + bob, 27, 45 + bob, 37, 38 + bob], t: 0.9)
                k.fill(tail, fur)
                k.clip(tail) { k.fill(circ(12, 68 + bob, 10), k.cream) }
                k.stroke(tail, k.ink, k.line)
            }
            for which in 0..<2 {
                let hx: CGFloat = which == 0 ? 45 : 54
                var s = k.step(which, reach: reach * f.energy, lift: lift * f.energy)
                if splay { s = CGPoint(x: which == 0 ? -9 : 9, y: 0) }
                k.noodle(k.bend(hx, 25 + bob, hx + s.x, 8 + s.y, sag: which == 0 ? 3 : -3))
                k.boot(hx + s.x, 4 + s.y, 0, color: boots)
            }
            k.with(about(50, 20 + bob, sy: sy).translatedBy(x: 0, y: bob)) {
                k.noodle(k.bend(43, 45, lh.x, lh.y, sag: sag))
                hosePartyHand(k, lh)
                k.part(ell(49, 36, 12.5, 14.5), fur)
                k.part(ell(53, 34, 6.5, 9.5), k.cream, w: k.line * 0.8)
                if v == 3 {
                    let fl: CGFloat = f.mood == .fleeing ? 8 : 0
                    k.part(smooth([46, 50, 36 - fl, 49 + 2 * f.swing, 29 - fl * 1.6, 45 + 3 * f.swing, 37 - fl, 44, 46, 46], t: 0.8), k.accents[1])
                    k.part(rrect(43, 46, 22, 6.5, 3.2), k.accents[1])
                }
                k.with(about(52, 52, rot: headRot)) {
                    k.with(about(46, 73, rot: 0.12 + earTw * 0.5)) {
                        let ear = smooth([39, 72, 42, 93, 52, 75], t: 0.35)
                        k.fill(ear, fur)
                        k.clip(ear) { k.fill(circ(42, 92, 8), k.ink) }
                        k.stroke(ear, k.ink, k.line)
                    }
                    k.with(about(57, 75, rot: -0.08 - earTw)) {
                        let ear = smooth([51, 76, 59, 96, 65, 75], t: 0.35)
                        k.fill(ear, fur)
                        k.clip(ear) { k.fill(circ(59, 95, 8), k.ink) }
                        k.stroke(ear, k.ink, k.line)
                    }
                    let head = smooth([41, 66, 36, 58, 45, 56, 58, 53, 72, 55, 85, 62, 74, 70, 65, 76, 54, 79, 44, 75], t: 0.85)
                    k.part(head, fur)
                    let fx = faceX
                    hosePartyBlob(k, [circ(55.5 + fx, 67, 6.4), circ(63.5 + fx, 67, 6.4), smooth([50, 62, 60, 65.5, 72, 66, 84, 62, 72, 56, 58, 55], t: 0.8)], k.cream)
                    k.fill(circ(84, 62.5, 3.2), k.ink)
                    k.shine(84.5, 63.8, 1, 0.7)
                    k.eye(55.5 + fx, 67.5, 2.4, 4.3, look: fx > 0 ? 1 : 0)
                    k.eye(63.5 + fx, 67.5, 2.4, 4.3, look: fx > 0 ? 1 : 0)
                    k.mouth(67 + fx, 60, 10, 3.2)
                    if v == 2 { hosePartyTopHat(k, 53, 77, 0.85, rot: -0.15, band: k.red) }
                }
                if v == 1 { hosePartyBowtie(k, 56, 50, 0.8, k.ink) }
                if v == 4 { hosePartyBowtie(k, 56, 50, 0.8, k.red) }
                k.noodle(k.bend(55, 45, rh.x, rh.y, sag: -sag))
                hosePartyHand(k, rh, 0.95)
                k.marks(f.mood == .fleeing ? 30 : 80, 88, 13)
            }
        }
    }

    static func polarBear(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t
        let v = f.variant % 5
        let scarf = f.pick([k.red, k.accents[1], k.red, k.accents[3], k.accents[4]])
        var rot: CGFloat = 0, sy: CGFloat = 1, faceX: CGFloat = 0, headRot: CGFloat = 0, flow: CGFloat = 0
        var reach: CGFloat = 6, lift: CGFloat = 4, sag: CGFloat = 3, splay = false
        var lh: HosePartyHand = (24 - 4 * f.swing, 28 + 1.5 * f.swing, .pi + 0.45 - 0.3 * f.swing, true)
        var rh: HosePartyHand = (75 + 4 * f.swing, 28 - 1.5 * f.swing, .pi - 0.45 - 0.3 * f.swing, true)
        switch f.mood {
        case .calm:
            if f.twitch > 0 { rh = (82, 50, -0.6, true) }
        case .sleepy:
            reach = 2.5
            lift = 1.2
            sy = 0.94
            headRot = -0.14
            sag = 1.5
            lh = (30, 22, .pi + 0.1, true)
            rh = (68, 22, .pi - 0.1, true)
        case .startled:
            splay = true
            sy = 1.05
            sag = 4
            lh = (16, 72, 0.55, true)
            rh = (86, 74, -0.55, true)
        case .fleeing:
            reach = 10
            lift = 7
            faceX = 2
            flow = 1
            sag = 5
            lh = (22 - 8 * f.swing, 44 + 5 * f.swing, 1.2 - 0.6 * f.swing, false)
            rh = (80 + 8 * f.swing, 44 - 5 * f.swing, -1.2 - 0.6 * f.swing, false)
        case .dizzy:
            rot = 0.12 * sin(t)
            sag = 7
            lh = (12, 48 + 4 * f.swing, 2.1, true)
            rh = (88, 46 - 4 * f.swing, -2.1, true)
        }
        let bob: CGFloat = splay ? 0 : 1.4 * f.bounce * f.energy
        k.with(about(50, 4, rot: rot)) {
            for which in 0..<2 {
                let hx: CGFloat = which == 0 ? 38 : 60
                var s = k.step(which, reach: reach * f.energy, lift: lift * f.energy)
                if splay { s = CGPoint(x: which == 0 ? -7 : 7, y: 0) }
                k.noodle(k.bend(hx, 20 + bob, hx + s.x, 8 + s.y, sag: which == 0 ? 2.5 : -2.5))
                k.boot(hx + s.x, 4 + s.y, 0, color: k.ink)
            }
            k.with(about(50, 16 + bob, sy: sy).translatedBy(x: 0, y: bob)) {
                k.noodle(k.bend(32, 42, lh.x, lh.y, sag: sag))
                hosePartyHand(k, lh)
                k.part(ell(48, 35, 21, 21), k.cream)
                k.part(ell(53, 30, 11.5, 13), k.cream, w: k.line * 0.7)
                if v != 2 {
                    let w1: CGFloat = 2.5 * f.swing, w2: CGFloat = 3 * sin(t + 1)
                    let fl = flow * 10
                    let tail = smooth([47, 52, 39 - fl, 50 + w1 * 0.5 + fl * 0.3, 34 - fl * 1.8, 40 + w2 + fl * 0.9, 40 - fl * 1.5, 37 + w2 + fl * 0.8, 46, 46], t: 0.8)
                    k.part(tail, scarf)
                }
                k.with(about(54, 50, rot: headRot)) {
                    let tw: CGFloat = 0.8 * f.twitch
                    for e in [(45.0 - tw, 78.0), (62.0 + tw, 81.0)] as [(CGFloat, CGFloat)] {
                        k.part(circ(e.0, e.1, 6), k.cream)
                        k.fill(circ(e.0 + 0.4, e.1 - 0.4, 2.8), k.ink)
                    }
                    hosePartyBlob(k, [circ(56, 65, 15), ell(67, 59, 10.5, 7.5)], k.cream)
                    let fx = faceX
                    k.eye(54 + fx, 68, 2.4, 4.1, look: fx > 0 ? 1 : 0)
                    k.eye(61.5 + fx, 68, 2.4, 4.1, look: fx > 0 ? 1 : 0)
                    k.fill(ell(75.5, 62, 3.6, 2.8), k.ink)
                    k.shine(76, 63.3, 1.1, 0.7)
                    k.mouth(68 + fx, 56.5, 9, 3)
                    switch v {
                    case 1:
                        k.stroke(arc(42, 79, 64, 82, dip: -13), k.ink, k.limb)
                        k.part(circ(44.5, 78, 5), k.red)
                        k.part(circ(62.5, 81, 5), k.red)
                    case 2: hosePartyTopHat(k, 54, 78, 0.95, rot: -0.12, band: k.red)
                    case 3: hosePartyCone(k, 55, 78, 0.9, rot: -0.2, tone: k.accents[2])
                    default: break
                    }
                }
                if v == 2 {
                    hosePartyBowtie(k, 54, 47.5, 0.9, k.red)
                } else {
                    k.part(rrect(37, 44.5, 30, 7, 3.5), scarf)
                    k.stroke(line(44, 45, 44, 51), k.cream, k.line * 0.6)
                    k.stroke(line(58, 45, 58, 51), k.cream, k.line * 0.6)
                }
                k.noodle(k.bend(64, 42, rh.x, rh.y, sag: -sag))
                hosePartyHand(k, rh, 0.95)
                k.marks(f.mood == .fleeing ? 26 : 80, 86, 13)
            }
        }
    }

    private static func cometTail(_ len: CGFloat, _ hw: CGFloat, _ t: CGFloat, _ amp: CGFloat) -> CGPath {
        var pts: [CGPoint] = []
        let n = 6
        for i in 0...n {
            let u = CGFloat(i) / CGFloat(n)
            let lobe: CGFloat = i % 2 == 1 ? 1.22 : 0.85
            pts.append(pt(64 - len * u, 50 + hw * (1 - 0.72 * u) * lobe + amp * u * sin(2 * t + u * 5)))
        }
        pts.append(pt(64 - len * 1.1, 50 + amp * sin(2 * t + 5.4)))
        for i in (0...n).reversed() {
            let u = CGFloat(i) / CGFloat(n)
            let lobe: CGFloat = i % 2 == 0 ? 1.22 : 0.85
            pts.append(pt(64 - len * u, 50 - hw * (1 - 0.72 * u) * lobe + amp * u * sin(2 * t + u * 5 + 0.8)))
        }
        return smoothP(pts, t: 0.8)
    }

    static func comet(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t
        let v = f.variant % 5
        let outer = f.pick([k.red, k.accents[3], k.accents[4], k.accents[1], k.red])
        let inner = f.pick([k.accents[2], k.cream, k.accents[2], k.accents[2], k.accents[2]])
        var len: CGFloat = 52, hw: CGFloat = 16, amp: CGFloat = 3, rot: CGFloat = 0, faceX: CGFloat = 0, sag: CGFloat = 3
        var a1: HosePartyHand = (36, 72 + 2 * f.swing, .pi / 2 + 0.2 + 0.3 * f.twitch, true)
        var a2: HosePartyHand = (36, 28 - 2 * f.swing, .pi / 2 - 0.2, true)
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            len = 32
            hw = 12
            amp = 1.2
            rot = -0.06
            sag = 1.5
            a1 = (42, 60, .pi / 2 + 0.7, true)
            a2 = (42, 34, .pi / 2 + 0.3, true)
        case .startled:
            len = 44
            hw = 19
            amp = 4
            sag = 4
            a1 = (80, 88, -0.5, true)
            a2 = (80, 12, .pi + 0.5, true)
        case .fleeing:
            len = 66
            hw = 15
            amp = 4.5
            faceX = 2
            sag = 2
            a1 = (26, 64, .pi / 2 + 0.1, false)
            a2 = (26, 36, .pi / 2 - 0.1, false)
        case .dizzy:
            len = 46
            amp = 7
            rot = 0.12 * sin(t)
            sag = 7
            a1 = (40, 80 + 4 * f.swing, 0.8, true)
            a2 = (40, 20 - 4 * f.swing, .pi - 0.8, true)
        }
        k.with(about(64, 50, rot: rot)) {
            k.part(cometTail(len, hw, t, amp), outer)
            k.part(cometTail(len * 0.7, hw * 0.62, t + 0.5, amp * 0.8), inner, w: k.line * 0.8)
            if v == 2 {
                for (i, p) in ([(30.0, 57.0), (18.0, 44.0), (42.0, 41.0)] as [(CGFloat, CGFloat)]).enumerated() {
                    hosePartySparkle(k, p.0, p.1, 4.5 * (0.6 + 0.4 * sin(2 * t + CGFloat(i) * 2.1)), k.cream)
                }
            }
            k.noodle(k.bend(54, 62, a1.x, a1.y, sag: sag))
            hosePartyHand(k, a1, 0.95)
            k.noodle(k.bend(54, 38, a2.x, a2.y, sag: -sag))
            hosePartyHand(k, a2, 0.95)
            k.part(circ(64, 50, 17), k.cream)
            let fx = faceX
            k.eye(60.5 + fx, 54, 3, 5.2, look: 1)
            k.eye(69.5 + fx, 54, 3, 5.2, look: 1)
            k.mouth(65.5 + fx, 44, 12, 3.8)
            switch v {
            case 1:
                k.stroke(arc(48, 60, 80, 62, dip: -6), k.ink, k.limb)
                k.part(circ(61, 65, 4.6), k.cream, w: k.line)
                k.part(circ(71, 65.5, 4.6), k.cream, w: k.line)
                k.fill(circ(61, 65, 2.3), k.accents[3].alpha(0.5))
                k.fill(circ(71, 65.5, 2.3), k.accents[3].alpha(0.5))
            case 3: hosePartyBowtie(k, 63, 33, 0.75, k.red)
            case 4: hosePartyCone(k, 60, 64, 0.8, rot: 0.25, tone: k.red)
            default: break
            }
            k.marks(f.mood == .fleeing ? 60 : 80, 74, 12)
        }
    }

    static func ufo(_ f: FigureFrame, _ k: HoseKit) {
        let t = f.t
        let v = f.variant % 5
        let fi = f.frameIndex
        let hull = f.pick([k.ink, k.red, k.ink, k.accents[3], k.cream])
        let band = f.pick([k.cream, k.cream, k.red, k.cream, k.red])
        let bulb = f.pick([k.accents[2], k.accents[2], k.accents[2], k.accents[2], k.accents[2]])
        var rot: CGFloat = 0, hx: CGFloat = 50, hy: CGFloat = 60 + 0.8 * f.swing2, headRot: CGFloat = 0
        var lit = 1, puffs = false, antA: CGFloat = 4, antL: CGFloat = 15
        var lh: HosePartyHand = (31, 46, .pi + 0.25, true)
        var rh: HosePartyHand = (69, 46, .pi - 0.25, true)
        switch f.mood {
        case .calm:
            if f.twitch > 0 { rh = (76, 66, -0.4, true) }
        case .sleepy:
            hy = 53
            headRot = -0.2
            lit = 0
            antA = 12
            antL = 10
        case .startled:
            hy = 70
            lit = 2
            antA = 1
            antL = 18
            lh = (24, 78, 0.5, true)
            rh = (76, 80, -0.5, true)
        case .fleeing:
            hx = 54
            headRot = -0.15
            puffs = true
            antA = 9
            lh = (34, 46, .pi + 0.1, false)
            rh = (71, 46, .pi - 0.1, false)
        case .dizzy:
            rot = 0.12 * sin(t)
            antA = 4 + 5 * sin(t)
            lh = (22, 58 + 4 * f.swing, 2.0, true)
            rh = (78, 56 - 4 * f.swing, -2.0, true)
        }
        k.with(about(50, 30, rot: rot)) {
            if puffs {
                for i in 0..<3 {
                    let u = (CGFloat(fi % 4) / 4 + CGFloat(i) / 3).truncatingRemainder(dividingBy: 1)
                    k.part(circ(6 - 14 * u, 30 + 3 * CGFloat(i % 2), 5 - 2 * u), k.cream, w: k.line * 0.8)
                }
            }
            k.part(ell(50, 23.5, 16, 5.5), hull)
            let disc = ell(50, 33, 44, 11)
            k.fill(disc, hull)
            k.clip(disc) { k.fill(rrect(0, 28.5, 100, 4.6, 0), band) }
            k.stroke(disc, k.ink, k.line)
            for i in 0..<7 {
                let on: Bool
                switch lit {
                case 0: on = i == 3 && fi % 8 < 4
                case 2: on = true
                default: on = (i + fi) % 3 == 0
                }
                let x = 14 + CGFloat(i) * 12
                k.part(circ(x, 30.8, 3.5), on ? bulb : band.mix(k.ink, 0.35), w: k.line * 0.7)
            }
            k.part(ell(50, 41, 23, 7), k.cream)
            let hole = ell(50, 41.5, 19, 5)
            k.solid(hole)
            k.with(about(hx, 40, rot: headRot)) {
                k.solid(rrect(hx - 6, 36, 12, 14, 5))
                for s in [-1.0, 1.0] as [CGFloat] {
                    let bx = hx + s * 5, by = hy + 10
                    let tx = hx + s * (8 + antA), ty = hy + 10 + antL + 1.5 * f.twitch * (s > 0 ? 1 : -1)
                    k.stroke(smooth(k.bend(bx, by, tx, ty, sag: s * 2), closed: false), k.ink, k.line)
                    k.part(circ(tx, ty, 3.4), v == 3 ? k.accents[2] : k.red, w: k.line * 0.8)
                }
                k.solid(circ(hx, hy, 12.5))
                k.shine(hx - 8, hy + 6, 1.3, 2.6, 0.6)
                hosePartyBlob(k, [circ(hx - 4, hy + 1, 6), circ(hx + 4.5, hy + 1, 6), ell(hx + 0.5, hy - 5, 9, 6)], k.cream)
                k.eye(hx - 4, hy + 1.5, 2.4, 4.2)
                k.eye(hx + 4.5, hy + 1.5, 2.4, 4.2)
                k.mouth(hx + 0.5, hy - 4.5, 9, 3)
                switch v {
                case 1: hosePartyBowtie(k, hx, 47, 0.62, k.accents[2])
                case 2:
                    let cap = CGMutablePath()
                    cap.addArc(center: pt(hx, hy + 9.5), radius: 8.5, startAngle: 0, endAngle: .pi, clockwise: false)
                    cap.closeSubpath()
                    k.part(cap, k.red)
                    k.stroke(line(hx, hy + 18.5, hx, hy + 21), k.ink, k.line)
                    let pw: CGFloat = fi % 2 == 0 ? 9 : 3.5
                    k.part(ell(hx, hy + 22, pw, 2), k.accents[2], w: k.line * 0.7)
                case 4: hosePartyTopHat(k, hx + 1, hy + 10.5, 0.8, rot: -0.12, band: k.red)
                default: break
                }
            }
            k.clip(hole) { k.fill(rrect(20, 20, 60, 21.5, 0), k.cream) }
            k.clip(rrect(0, 0, 100, 41.5, 0)) { k.stroke(hole, k.ink, k.line) }
            k.noodle(k.bend(hx - 6, 44, lh.x, lh.y, sag: 3))
            hosePartyHand(k, lh, 0.9)
            k.noodle(k.bend(hx + 6, 44, rh.x, rh.y, sag: -3))
            hosePartyHand(k, rh, 0.9)
            k.marks(f.mood == .fleeing ? 30 : 76, 80, 12)
        }
    }
}
