import Foundation
import CoreGraphics
import ScuttleCore

extension StickerArt {
    static func ghost(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xf6f4ff), Tone(0xc8c0f0)), (Tone(0xffe3ee), Tone(0xf2a9c6)), (Tone(0xdcf7ea), Tone(0x9fd9bf)),
            (Tone(0xdcecff), Tone(0xa9c6f0)), (Tone(0xfff4c8), Tone(0xf0d27a)),
        ]
        let (base, shadow) = f.pick(looks)
        let t = f.t
        var sx: CGFloat = 1, sy: CGFloat = 1 + 0.02 * f.swing2, rot: CGFloat = -0.07
        var trail: CGFloat = 0, ripple: CGFloat = 2.2
        var la = (x: CGFloat(22), y: CGFloat(36), a: CGFloat(0.5) + 0.25 * f.swing)
        var ra = (x: CGFloat(78), y: CGFloat(40), a: CGFloat(-0.6) + 0.25 * f.swing)
        var look: CGFloat = 0
        switch f.mood {
        case .calm:
            ra.a -= 0.5 * max(0, f.twitch)
            ra.y += 3 * max(0, f.twitch)
        case .sleepy:
            sx = 1.05
            sy = 0.93
            ripple = 0.8
            la = (23, 29, -0.45)
            ra = (77, 29, 0.45)
        case .startled:
            sx = 0.95
            sy = 1.07
            ripple = 0.8
            la = (17, 64, 1.1 + 0.1 * f.swing2)
            ra = (83, 66, -1.1 - 0.1 * f.swing2)
        case .fleeing:
            trail = 8
            ripple = 3.4
            rot = -0.02
            la = (19, 44, 0.15 + 0.2 * f.swing)
            ra = (73, 33, 0.9)
            look = 1
        case .dizzy:
            rot = -0.07 + 0.14 * sin(t)
            la = (23, 44, 0.9 * f.swing)
            ra = (77, 34, -0.9 * f.swing)
        }
        k.with(about(50, 40, rot: rot, sx: sx, sy: sy).translatedBy(x: 0, y: 3)) {
            k.flat(ell(la.x, la.y, 8.5, 4.8, la.a), base)
            k.flat(ell(ra.x, ra.y, 8.5, 4.8, ra.a), base)
            let body = stickerGhostBody(trail: trail, ripple: ripple, t: t)
            k.part(body, base, shadow: shadow, shape: ell(86, 36, 21, 48))
            k.gloss(33, 74, 3.2, 6.5, -0.5)
            stickerGhostHat(f, k)
            k.face(50 + look * 2.5, 55, look: look)
            k.marks(75, 86, 13)
        }
    }

    private static func stickerGhostBody(trail: CGFloat, ripple: CGFloat, t: CGFloat) -> CGPath {
        let l: CGFloat = 24, r: CGFloat = 76, top: CGFloat = 90, hem: CGFloat = 20
        let rad = (r - l) / 2, cx = (l + r) / 2
        let p = CGMutablePath()
        p.move(to: pt(l - trail, hem))
        p.addCurve(to: pt(l, top - rad), control1: pt(l - trail * 0.7, hem + 14), control2: pt(l, top - rad - 14))
        p.addArc(center: pt(cx, top - rad), radius: rad, startAngle: .pi, endAngle: 0, clockwise: true)
        p.addCurve(to: pt(r - trail, hem), control1: pt(r, top - rad - 14), control2: pt(r - trail * 0.7, hem + 14))
        let bumps = 4
        let step = (r - l) / CGFloat(bumps)
        for i in 0..<bumps {
            let x0 = r - trail - CGFloat(i) * step
            let x1 = x0 - step
            let depth = 13 + ripple * sin(t + CGFloat(i) * 1.6)
            p.addQuadCurve(to: pt(x1, hem), control: pt((x0 + x1) / 2 - trail * 0.3, hem - depth))
        }
        p.closeSubpath()
        return p
    }

    private static func stickerGhostHat(_ f: FigureFrame, _ k: StickerKit) {
        switch f.variant % 5 {
        case 1:
            let red = Tone(0xff4f6d)
            k.part(smooth([50, 88, 39, 95, 38, 83], t: 0.4), red)
            k.part(smooth([50, 88, 61, 95, 62, 83], t: 0.4), red)
            k.flat(circ(50, 88, 3.2), red.dim(0.85))
        case 2:
            let hat = Tone(0x7a5cc8), band = Tone(0xffc93c)
            let cone = smooth([36, 87, 64, 87, 57, 99, 67, 110, 49, 101], t: 0.5)
            k.part(cone, hat)
            k.clip(cone) { k.fill(rrect(30, 88, 40, 5, 0), band) }
            k.stroke(cone, k.ink, k.line)
            k.part(ell(50, 87, 22, 4.6), hat)
        case 3:
            k.stroke(line(80, 34, 87, 58), k.ink, k.line * 2.2)
            k.stroke(line(80, 34, 87, 58), Tone(0xfff6e8), k.line * 0.9)
            let pop = circ(88, 62, 7)
            k.flat(pop, Tone(0xff6fae))
            k.stroke(spiral(88, 62, 5.5, turns: 1.6), Tone.white, k.thin)
            k.stroke(pop, k.ink, k.line)
        case 4:
            let cone = poly([39, 87, 61, 87, 52, 108])
            k.fill(cone, Tone(0x5fd3c4))
            k.clip(cone) {
                for y in stride(from: CGFloat(91), to: 110, by: 7) { k.fill(rrect(30, y, 40, 3.2, 0), Tone(0xff7fb0)) }
            }
            k.stroke(cone, k.ink, k.line)
            k.flat(circ(52, 109, 3.4), Tone(0xffd54a))
        default:
            break
        }
    }

    private static func stickerFestiveTube(_ k: StickerKit, _ p: CGPath, _ tone: Tone, _ w: CGFloat) {
        k.stroke(p, k.ink, w + k.line * 2)
        k.stroke(p, tone, w)
    }

    private static func stickerFestiveBlob(_ k: StickerKit, _ ps: [CGPath], _ base: Tone, shape: CGPath, inner: (() -> Void)? = nil) {
        for p in ps { k.stroke(p, k.ink, k.line * 2) }
        for p in ps { k.fill(p, base) }
        for p in ps {
            k.clip(p) {
                k.fill(shape, k.shade(base))
                inner?()
            }
        }
    }

    private static func stickerFestiveLimb(_ x: CGFloat, _ y: CGFloat, _ a: CGFloat, _ len: CGFloat, _ w: CGFloat) -> CGPath {
        let t = CGAffineTransform(translationX: x, y: y).rotated(by: a)
        return xf(rrect(-w * 0.5, -w * 0.5, len, w, w * 0.5), t)
    }

    private static func stickerFestiveEnd(_ x: CGFloat, _ y: CGFloat, _ a: CGFloat, _ len: CGFloat, _ w: CGFloat) -> CGPoint {
        let d = len - w * 0.5
        return pt(x + cos(a) * d, y + sin(a) * d)
    }

    private static func stickerFestiveBow(_ k: StickerKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ tone: Tone, _ rot: CGFloat = 0) {
        k.with(about(x, y, rot: rot)) {
            k.flat(smooth([x, y, x - s * 1.3, y + s * 0.85, x - s * 1.4, y - s * 0.75], t: 0.4), tone)
            k.flat(smooth([x, y, x + s * 1.3, y + s * 0.85, x + s * 1.4, y - s * 0.75], t: 0.4), tone)
            k.flat(circ(x, y, s * 0.45), tone.dim(0.85))
        }
    }

    private static func stickerFestiveWitchHat(_ k: StickerKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ hat: Tone, _ band: Tone, _ tilt: CGFloat = 0) {
        k.with(about(x, y, rot: tilt)) {
            let cone = smooth([x - s * 0.62, y, x + s * 0.62, y, x + s * 0.3, y + s * 0.6, x + s * 0.55, y + s * 1.1, x - s * 0.05, y + s * 0.75], t: 0.5)
            k.part(cone, hat)
            k.clip(cone) { k.fill(rrect(x - s, y, s * 2, s * 0.2, 0), band) }
            k.stroke(cone, k.ink, k.line)
            k.part(ell(x, y, s * 0.95, s * 0.2), hat)
        }
    }

    private static func stickerFestiveCane(_ k: StickerKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        let w: CGFloat = 3.8 * s
        let cane = smooth([x, y - 10 * s, x, y + 8 * s, x + 3 * s, y + 13 * s, x + 7.5 * s, y + 9.5 * s], closed: false, t: 0.8)
        k.stroke(cane, k.ink, w + k.line * 2)
        k.stroke(cane, .white, w)
        for j in 0..<4 {
            let y0 = y - 8 * s + CGFloat(j) * 5 * s
            k.fill(xf(rrect(-w * 0.5, 0, w, 2.2 * s, 0), CGAffineTransform(a: 1, b: 0.5, c: 0, d: 1, tx: x, ty: y0)), Tone(0xff3d5a))
        }
    }

    static func bat(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0x7a5cc8), Tone(0x5b3fa6), Tone(0xdcd0ff)),
            (Tone(0xe2629f), Tone(0xb8417c), Tone(0xffd6e8)),
            (Tone(0x4f78d6), Tone(0x3556a8), Tone(0xd3e3ff)),
            (Tone(0x3fae8a), Tone(0x2b8068), Tone(0xd4f6e8)),
            (Tone(0x77738f), Tone(0x55516e), Tone(0xe8e4f6)),
        ]
        let (fur, wing, mask) = f.pick(looks)
        var flap = f.swing * 0.5
        var open: CGFloat = 0.08
        var sx: CGFloat = 1, sy: CGFloat = 1, rot: CGFloat = 0
        var earR: CGFloat = 0.14 * f.twitch, earL: CGFloat = 0
        var look: CGFloat = 0
        let cloak = f.mood == .sleepy
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            flap = 0
            sx = 1.04
            sy = 0.94
            earR = -0.22
            earL = 0.22
        case .startled:
            flap = 0.06 * f.swing2
            open = 0.5
            sx = 0.94
            sy = 1.08
            earR = -0.1
            earL = 0.1
        case .fleeing:
            flap = f.swing * 0.75
            open = 0.3
            rot = -0.08
            look = 1
            earR = 0.45
            earL = 0.45
        case .dizzy:
            rot = 0.12 * sin(f.t)
            flap = f.swing * 0.3
            earR = 0.2 * f.swing
            earL = -0.2 * f.swing
        }
        let lx = look * 2.2
        k.with(about(50, 50, rot: rot, sx: sx, sy: sy)) {
            if !cloak {
                let w = stickerBatWing()
                let ribs = [line(63, 56, 91, 50), line(63, 56, 78, 47)]
                k.with(about(62, 54, rot: open + flap)) {
                    k.part(w, wing)
                    for r in ribs { k.stroke(r, wing.dim(0.7), k.thin) }
                }
                k.with(about(38, 54, rot: -(open + flap))) {
                    k.part(mirror(w), wing)
                    for r in ribs { k.stroke(mirror(r), wing.dim(0.7), k.thin) }
                }
            }
            let ear = poly([54, 62, 68, 63, 67, 84])
            let inner = poly([58, 64, 65, 65, 65, 77])
            k.with(about(61, 64, rot: earR)) {
                k.flat(ear, fur)
                k.fill(inner, mask)
            }
            k.with(about(39, 64, rot: earL)) {
                k.flat(mirror(ear), fur)
                k.fill(mirror(inner), mask)
            }
            k.flat(ell(45, 32, 3.6, 3.2), wing)
            k.flat(ell(55, 32, 3.6, 3.2), wing)
            k.part(ell(50, 50, 20, 19), fur, shape: ell(76, 40, 14, 26))
            k.fill(ell(50 + lx, 41.5, 9, 6), mask)
            k.gloss(37, 62, 2.2, 4, -0.6)
            if cloak {
                let c = smooth([50, 30, 64, 31, 72, 44, 70, 57, 61, 49, 53, 45], t: 0.7)
                k.part(c, wing)
                k.part(mirror(c), wing)
            }
            k.face(50 + lx, 52, spread: 7.4, rx: 4.5, ry: 5.9)
            stickerBatExtra(f, k)
            k.marks(70, 72, 12)
        }
    }

    private static func stickerBatWing() -> CGPath {
        let p = CGMutablePath()
        p.move(to: pt(58, 60))
        p.addQuadCurve(to: pt(98, 70), control: pt(78, 78))
        p.addQuadCurve(to: pt(91, 49), control: pt(90, 61))
        p.addQuadCurve(to: pt(78, 46), control: pt(84, 53))
        p.addQuadCurve(to: pt(60, 44), control: pt(69, 51))
        p.closeSubpath()
        return p
    }

    private static func stickerBatExtra(_ f: FigureFrame, _ k: StickerKit) {
        switch f.variant % 5 {
        case 1:
            stickerFestiveBow(k, 65, 75, 6.8, Tone(0xffd54a), -0.3)
        case 2:
            stickerFestiveWitchHat(k, 50, 68, 16, Tone(0x3b2a6e), Tone(0xffa53a), 0.1)
        case 3:
            let tie = Tone(0xffa53a)
            k.flat(poly([50, 35, 42.5, 39.5, 42.5, 30.5]), tie)
            k.flat(poly([50, 35, 57.5, 39.5, 57.5, 30.5]), tie)
            k.flat(circ(50, 35, 2.4), tie.dim(0.85))
        case 4:
            stickerFestiveBlob(k, [ell(45, 27, 4.5, 5.5), ell(55, 27, 4.5, 5.5), ell(50, 27, 7.5, 6)], Tone(0xff9a2a), shape: ell(60, 22, 5, 8))
            k.flat(rrect(48.6, 32, 2.8, 4, 1), Tone(0x4caf50))
        default:
            break
        }
    }

    static func pumpkin(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xff9a2a), Tone(0x4caf50)), (Tone(0xf7efdc), Tone(0x6cbf6a)), (Tone(0xff6f3c), Tone(0x3f9e5a)),
            (Tone(0xffc53a), Tone(0x58b45c)), (Tone(0x7fc9b6), Tone(0x3f8f5a)),
        ]
        let (skin, leaf) = f.pick(looks)
        var sy: CGFloat = 1 - 0.16 * f.squat + 0.1 * f.stretch
        var sx: CGFloat = 1 + 0.12 * f.squat - 0.05 * f.stretch
        var rot: CGFloat = 0
        var stemTilt: CGFloat = 0.12 * f.twitch
        var stemUp: CGFloat = 0
        var look: CGFloat = 0
        var feet: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sy *= 0.9
            sx *= 1.05
            stemTilt = -0.45
        case .startled:
            sy *= 1.08
            sx *= 0.95
            stemUp = 4
            stemTilt = -0.15
            feet = 5
        case .fleeing:
            rot = -0.08
            look = 1
            stemTilt = 0.5
        case .dizzy:
            rot = 0.12 * sin(f.t)
            stemTilt = 0.3 * f.swing
        }
        let tuck: CGFloat = 3 * f.air * (1 - f.air) * 4
        let lx = look * 2.5
        k.with(about(50, 5, rot: rot, sx: sx, sy: sy)) {
            let shoe = Tone(0x7a4a2e)
            k.flat(ell(38 - feet, 6 + tuck, 7, 4), shoe)
            k.flat(ell(62 + feet, 6 + tuck, 7, 4), shoe)
            k.with(about(51, 64, rot: stemTilt).translatedBy(x: 0, y: stemUp)) {
                k.part(poly([47, 62, 55, 62, 57.5, 79, 51, 80.5]), Tone(0x8a5a3a))
                if f.variant % 5 == 0 || f.variant % 5 == 2 {
                    k.part(smooth([55, 72, 64, 79, 73, 76, 66, 70], t: 0.6), leaf)
                }
            }
            k.part(ell(33, 36, 17, 27), skin)
            k.part(ell(67, 36, 17, 27), skin)
            k.part(ell(50, 38, 21, 31), skin, shape: ell(74, 30, 12, 34))
            k.gloss(37, 54, 2.6, 6, -0.3)
            k.face(52 + lx, 39, spread: 8.5, rx: 4.6, ry: 6.1, look: look)
            stickerPumpkinExtra(f, k, stemTilt)
            k.marks(74, 70, 13)
        }
    }

    private static func stickerPumpkinExtra(_ f: FigureFrame, _ k: StickerKit, _ tilt: CGFloat) {
        switch f.variant % 5 {
        case 1:
            stickerFestiveBow(k, 61, 68, 7, Tone(0xff6fa8), -0.2)
        case 2:
            stickerFestiveWitchHat(k, 50, 66, 24, Tone(0x5b3c9e), Tone(0x8cdc5a), 0.12 + tilt * 0.3)
        case 3:
            k.with(about(50, 66, rot: -0.12 + tilt * 0.3)) {
                k.part(rrect(40, 66, 20, 15, 3), Tone(0x3a3150), shadow: Tone(0x2a2340))
                k.fill(rrect(40, 68, 20, 3.5, 0), Tone(0xff5a6e))
                k.stroke(rrect(40, 66, 20, 15, 3), k.ink, k.line)
                k.part(ell(50, 66, 16, 3.2), Tone(0x3a3150))
            }
        case 4:
            let petal = Tone(0xff8fc8)
            for i in 0..<5 {
                let a = CGFloat(i) * 2 * .pi / 5 + 0.3
                k.flat(circ(61 + cos(a) * 5.2, 71 + sin(a) * 5.2, 4.2), petal)
            }
            k.flat(circ(61, 71, 3.4), Tone(0xffd54a))
        default:
            break
        }
    }

    static func spider(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0x5a4a8e), Tone(0xe6defc)), (Tone(0xe2629f), Tone(0xffe0ee)), (Tone(0x3fa37c), Tone(0xdcf6ea)),
            (Tone(0xff8a3d), Tone(0xffe8d2)), (Tone(0x4a6fd1), Tone(0xdee8ff)),
        ]
        let (body, mask) = f.pick(looks)
        let legTone = body.dim(0.85)
        var by: CGFloat = 28 + 0.8 * f.swing2 * f.energy
        var rot: CGFloat = 0
        var look: CGFloat = 0
        var tuft: CGFloat = 0.18 * f.twitch
        switch f.mood {
        case .calm:
            break
        case .dizzy:
            rot = 0.12 * sin(f.t)
        case .sleepy:
            by = 25
            tuft = -0.4
        case .startled:
            by = 33
        case .fleeing:
            by = 29 + 1.5 * f.bounce
            rot = -0.08
            look = 1
            tuft = 0.55
        }
        let legW: CGFloat = 4.4
        let base: [CGFloat] = [0.8, 0.32, -0.14, -0.58]
        k.with(about(50, 5, rot: rot)) {
            for i in 0..<4 {
                k.both { s in
                    let ph = f.t * (f.mood == .fleeing ? 2 : 1) + CGFloat(i) * .pi / 2 + (s > 0 ? .pi : 0)
                    var a = base[i] + 0.2 * sin(ph) * f.energy
                    var reach: CGFloat = 31
                    var bend: CGFloat = 9
                    switch f.mood {
                    case .sleepy:
                        a = base[i] * 0.55 - 0.35
                        reach = 27
                        bend = 6
                    case .startled:
                        a = base[i] + (i < 2 ? 0.4 : 0.1) + 0.05 * f.swing2
                        reach = 33
                        bend = i < 2 ? 3 : 9
                    case .dizzy:
                        a = base[i] + 0.22 * sin(f.t * 2 + CGFloat(i))
                    default:
                        break
                    }
                    let c = cos(a), sn = sin(a)
                    let hip = pt(50 + s * 17 * c, by + 17 * sn)
                    let knee = pt(50 + s * reach * c, by + reach * sn + 4)
                    let foot = pt(knee.x + s * 5, knee.y - bend)
                    let p = smooth([hip.x, hip.y, knee.x, knee.y, foot.x, foot.y], closed: false, t: 0.55)
                    stickerFestiveTube(k, p, legTone, legW)
                }
            }
            k.with(about(50, by + 19, rot: tuft)) {
                k.flat(poly([44, by + 17, 46.5, by + 28, 50, by + 19, 54, by + 29, 56.5, by + 17]), body)
            }
            k.part(ell(50, by, 23, 21), body, shape: ell(78, by - 8, 15, 26))
            let lx = look * 2.2
            for p in [circ(41.5 + lx, by + 3, 9.5), circ(58.5 + lx, by + 3, 9.5), ell(50 + lx, by - 6, 14, 10)] { k.fill(p, mask) }
            k.gloss(33, by + 10, 2.2, 4.4, -0.5)
            k.face(50 + lx, by + 3, spread: 8.2, rx: 4.8, ry: 6.2, look: look)
            stickerSpiderExtra(f, k, by)
            k.marks(72, by + 26, 12)
        }
    }

    private static func stickerSpiderExtra(_ f: FigureFrame, _ k: StickerKit, _ by: CGFloat) {
        switch f.variant % 5 {
        case 1:
            stickerFestiveBow(k, 64, by + 19, 7, Tone(0xffd54a), -0.4)
        case 2:
            let cone = poly([54, by + 18, 68, by + 15, 66, by + 34])
            k.fill(cone, Tone(0xffd54a))
            k.clip(cone) {
                for y in stride(from: by + 18, to: by + 36, by: 6) { k.fill(rrect(50, y, 22, 2.6, 0), Tone(0xff6fae)) }
            }
            k.stroke(cone, k.ink, k.line)
            k.flat(circ(66, by + 35, 2.8), Tone(0xff6fae))
        case 3:
            let tie = Tone(0x3fc6e0)
            k.flat(poly([50, by - 19, 43, by - 15, 43, by - 23]), tie)
            k.flat(poly([50, by - 19, 57, by - 15, 57, by - 23]), tie)
            k.flat(circ(50, by - 19, 2.2), tie.dim(0.85))
        case 4:
            let petal = Tone(0xffd54a)
            for i in 0..<5 {
                let a = CGFloat(i) * 2 * .pi / 5 + 0.3
                k.flat(circ(64 + cos(a) * 5, by + 19 + sin(a) * 5, 4), petal)
            }
            k.flat(circ(64, by + 19, 3.2), Tone(0xff7a45))
        default:
            break
        }
    }

    static func gingerbread(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xc8834a), Tone(0xffffff)), (Tone(0xd6955a), Tone(0xff9ec8)), (Tone(0xb87440), Tone(0xffffff)),
            (Tone(0xc8834a), Tone(0xffffff)), (Tone(0xe3aa66), Tone(0xffffff)),
        ]
        let (cookie, icing) = f.pick(looks)
        let st = f.sway * f.energy
        var legA: CGFloat = -.pi / 2 + 0.4 * st, legB: CGFloat = -.pi / 2 - 0.4 * st
        var armR: CGFloat = -0.25 - 0.3 * st, armL: CGFloat = .pi + 0.25 - 0.3 * st
        var rot: CGFloat = 0, sy: CGFloat = 1
        var look: CGFloat = 0
        let bob: CGFloat = 1.6 * f.bounce * f.energy
        switch f.mood {
        case .calm:
            if f.twitch > 0 { armR = 0.9 + 0.2 * f.swing2 }
        case .sleepy:
            legA = -.pi / 2 + 0.06
            legB = -.pi / 2 - 0.06
            armR = -1.25
            armL = .pi + 1.25
            sy = 0.95
            rot = 0.06
        case .startled:
            legA = -.pi / 2 + 0.38
            legB = -.pi / 2 - 0.38
            armR = 0.7 + 0.08 * f.swing2
            armL = .pi - 0.7 - 0.08 * f.swing2
            sy = 1.06
        case .fleeing:
            legA = -.pi / 2 + 0.6 * f.sway
            legB = -.pi / 2 - 0.6 * f.sway
            armR = .pi - 0.6 + 0.25 * f.swing
            armL = .pi - 0.2 - 0.25 * f.swing
            rot = -0.1
            look = 1
        case .dizzy:
            rot = 0.12 * sin(f.t)
            armR = 0.3 * sin(f.t)
            armL = .pi - 0.3 * sin(f.t)
        }
        let lx = look * 2.4
        k.with(about(50, 5, rot: rot, sy: sy).translatedBy(x: 0, y: bob)) {
            let limbs: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)] = [
                (42, 25, legA, 27, 14), (58, 25, legB, 27, 14), (35, 51, armL, 26, 13), (65, 51, armR, 26, 13),
            ]
            for (x, y, a, len, w) in limbs {
                k.part(stickerFestiveLimb(x, y, a, len, w), cookie)
                let t = CGAffineTransform(translationX: x, y: y).rotated(by: a)
                let c = len - w * 1.45
                k.stroke(xf(wavy(c, -w * 0.36, c, w * 0.36, waves: 1.5, amp: 1.4), t), icing, k.thin)
            }
            stickerFestiveBlob(k, [circ(52, 71, 18), ell(50, 39, 18, 17)], cookie, shape: ell(76, 36, 14, 40))
            k.gloss(40, 80, 2.4, 4.8, -0.5)
            let drops = [Tone(0xff4f6d), Tone(0x4fc36a), Tone(0xff4f6d)]
            for (i, y) in ([46, 37, 28] as [CGFloat]).enumerated() {
                k.flat(circ(50, y, 3.1), drops[i])
                k.gloss(49, y + 1, 0.9, 1.3)
            }
            k.face(55 + lx, 72.5, spread: 7, rx: 4.3, ry: 5.6, look: look)
            stickerGingerExtra(f, k, armR)
            k.marks(74, 90, 12)
        }
    }

    private static func stickerGingerExtra(_ f: FigureFrame, _ k: StickerKit, _ armR: CGFloat) {
        switch f.variant % 5 {
        case 1:
            stickerFestiveBow(k, 63, 86, 6.5, Tone(0xff6fa8), -0.25)
        case 2:
            let h = stickerFestiveEnd(65, 51, armR, 26, 13)
            stickerFestiveCane(k, h.x, h.y, 1.2)
            k.flat(circ(h.x, h.y, 5.2), f.pick([Tone(0xc8834a), Tone(0xd6955a), Tone(0xb87440)]))
        case 3:
            let scarf = Tone(0x3fb56a)
            k.part(rrect(34, 50, 34, 7.5, 3.75), scarf)
            k.part(poly([39, 52, 46, 52, 44, 38, 37, 39]), scarf)
            k.fill(rrect(37.5, 42, 7.5, 2.2, 0), Tone(0xff4f6d))
        case 4:
            let red = Tone(0xe8473f)
            k.part(smooth([35, 83, 68, 86, 56, 99, 40, 103, 29, 97, 42, 93], t: 0.5), red)
            k.flat(circ(28, 95, 4.4), .white)
            k.flat(rrect(33, 80, 37, 7.5, 3.75), .white)
        default:
            break
        }
    }

    static func present(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xe8473f), Tone(0xffd23f)), (Tone(0x3f8ee8), Tone(0xffffff)), (Tone(0x3fb56a), Tone(0xff4f5a)),
            (Tone(0xa262e0), Tone(0xff9ad0)), (Tone(0xffc93c), Tone(0x3fb56a)),
        ]
        let (box, ribbon) = f.pick(looks)
        var sy: CGFloat = 1 - 0.16 * f.squat + 0.1 * f.stretch
        var sx: CGFloat = 1 + 0.12 * f.squat - 0.05 * f.stretch
        var rot: CGFloat = 0
        var lidUp: CGFloat = 3 * f.air * (1 - f.air) * 4
        var lidTilt: CGFloat = 0.06 * f.twitch
        var look: CGFloat = 0
        var feet: CGFloat = 0
        var tail: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sy *= 0.92
            sx *= 1.04
            lidTilt = -0.1
            lidUp = 0
        case .startled:
            sy *= 1.06
            sx *= 0.96
            lidUp = 9 + 1.5 * f.swing2
            lidTilt = 0.12
            feet = 5
        case .fleeing:
            rot = -0.08
            look = 1
            tail = 1
        case .dizzy:
            rot = 0.12 * sin(f.t)
            lidTilt = 0.16 * sin(f.t + 1)
        }
        let tuck: CGFloat = 3 * f.air * (1 - f.air) * 4
        let lx = look * 2.4
        k.with(about(50, 5, rot: rot, sx: sx, sy: sy)) {
            let shoe = Tone(0x3b3355)
            k.flat(ell(37 - feet, 6 + tuck, 7, 4), shoe)
            k.flat(ell(63 + feet, 6 + tuck, 7, 4), shoe)
            let body = rrect(24, 8, 52, 41, 5)
            k.part(body, box, shape: rrect(66, 0, 20, 60, 0))
            k.clip(body) {
                stickerPresentPattern(f, k, box)
                k.fill(rrect(50, 0, 8, 60, 0), ribbon)
                k.fill(rrect(58, 0, 3, 60, 0), ribbon.dim(0.82))
            }
            k.stroke(body, k.ink, k.line)
            k.with(about(54, 48, rot: lidTilt).translatedBy(x: 0, y: lidUp)) {
                if tail > 0 || f.variant % 5 == 4 {
                    let sway = 2 * f.swing * f.energy
                    k.part(poly([50, 63, 38, 58 + sway, 30, 64 + sway, 34, 56 + sway]), ribbon)
                }
                let lid = rrect(20, 47, 60, 13, 4)
                k.part(lid, box, shape: rrect(70, 40, 20, 30, 0))
                k.clip(lid) {
                    k.fill(rrect(50, 40, 8, 30, 0), ribbon)
                    k.fill(rrect(58, 40, 3, 30, 0), ribbon.dim(0.82))
                }
                k.stroke(lid, k.ink, k.line)
                let droop: CGFloat = f.mood == .sleepy ? -0.35 : 0.1 * f.swing2 * f.energy
                k.with(about(54, 61, rot: droop)) {
                    k.part(smooth([54, 61, 38, 74, 36, 60], t: 0.45), ribbon)
                    k.part(smooth([54, 61, 70, 74, 72, 60], t: 0.45), ribbon)
                    k.flat(circ(54, 61.5, 4.4), ribbon.dim(0.85))
                }
            }
            k.gloss(30, 41, 2, 3.6, -0.3)
            if f.variant % 5 == 4 {
                k.stroke(line(76, 44, 82, 34), k.ink, k.thin)
                k.flat(rrect(78, 24, 10, 12, 2), .white)
                k.fill(circ(83, 32.5, 1.3), k.ink)
            }
            k.face(54 + lx, 31, spread: 11, rx: 4.9, ry: 6.4, look: look)
            k.marks(80, 74, 13)
        }
    }

    private static func stickerPresentPattern(_ f: FigureFrame, _ k: StickerKit, _ box: Tone) {
        switch f.variant % 5 {
        case 1:
            for (x, y) in [(30, 43), (70, 43), (30, 14), (70, 14), (44, 13)] as [(CGFloat, CGFloat)] {
                k.fill(circ(x, y, 2.6), Tone.white.alpha(0.9))
            }
        case 3:
            for i in 0..<6 {
                let x0 = CGFloat(i) * 14 - 10
                k.fill(poly([x0, 0, x0 + 6, 0, x0 + 46, 60, x0 + 40, 60]), box.lift(0.25))
            }
        default:
            break
        }
    }

    static func elf(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone, Tone, Tone)] = [
            (Tone(0x3fae55), Tone(0x3fae55), Tone(0xe8473f), Tone(0xe8473f)),
            (Tone(0xe8473f), Tone(0xe8473f), Tone(0xffffff), Tone(0x3fae55)),
            (Tone(0x3f7ee8), Tone(0x3f7ee8), Tone(0xffffff), Tone(0xffffff)),
            (Tone(0x3fae55), Tone(0xe8473f), Tone(0xffd23f), Tone(0xe8473f)),
            (Tone(0x8a5ad6), Tone(0x8a5ad6), Tone(0xffd23f), Tone(0x3fae55)),
        ]
        let (tunic, hat, trim, legs) = f.pick(looks)
        let skinT = Tone(0xffd2b0)
        let st = f.sway * f.energy
        var legA: CGFloat = -.pi / 2 + 0.42 * st, legB: CGFloat = -.pi / 2 - 0.42 * st
        var armR: CGFloat = -1.0 - 0.35 * st, armL: CGFloat = .pi + 1.0 - 0.35 * st
        var rot: CGFloat = 0, sy: CGFloat = 1
        var look: CGFloat = 0
        var tipX: CGFloat = 21 - 2 * f.swing * f.energy + 2 * f.twitch, tipY: CGFloat = 86
        var earA: CGFloat = 0.12 * f.twitch
        let bob: CGFloat = 1.6 * f.bounce * f.energy
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            legA = -.pi / 2 + 0.05
            legB = -.pi / 2 - 0.05
            armR = -1.4
            armL = .pi + 1.4
            sy = 0.95
            rot = 0.06
            tipX = 34
            tipY = 74
            earA = -0.25
        case .startled:
            legA = -.pi / 2 + 0.35
            legB = -.pi / 2 - 0.35
            armR = 0.45 + 0.08 * f.swing2
            armL = .pi - 0.45 - 0.08 * f.swing2
            sy = 1.06
            tipX = 34
            tipY = 100
            earA = 0.25
        case .fleeing:
            legA = -.pi / 2 + 0.65 * f.sway
            legB = -.pi / 2 - 0.65 * f.sway
            armR = .pi - 0.7 + 0.3 * f.swing
            armL = .pi - 0.3 - 0.3 * f.swing
            rot = -0.1
            look = 1
            tipX = 12
            tipY = 76 + 2 * f.swing2
        case .dizzy:
            rot = 0.12 * sin(f.t)
            armR = -0.3 + 0.4 * sin(f.t)
            armL = .pi + 0.3 + 0.4 * sin(f.t)
            tipX = 22 + 6 * sin(f.t)
        }
        let lx = look * 2.2
        k.with(about(50, 5, rot: rot, sy: sy).translatedBy(x: 0, y: bob)) {
            for (hx, a) in [(45, legA), (56, legB)] as [(CGFloat, CGFloat)] {
                k.flat(stickerFestiveLimb(hx, 21, a, 16, 6), legs)
                let e = stickerFestiveEnd(hx, 21, a, 16, 6)
                let shoe = smooth([e.x - 4.5, e.y - 2.5, e.x + 5, e.y - 2.5, e.x + 9.5, e.y + 4, e.x + 4, e.y + 2.8, e.x - 4.5, e.y + 3], t: 0.6)
                k.flat(shoe, tunic.dim(0.75))
            }
            k.flat(stickerFestiveLimb(41, 41, armL, 14, 6.5), tunic)
            k.flat(circ(stickerFestiveEnd(41, 41, armL, 14, 6.5).x, stickerFestiveEnd(41, 41, armL, 14, 6.5).y, 3.6), skinT)
            let tunicP = poly([40, 44, 62, 44, 68, 19, 62.5, 15.5, 57, 19, 51, 15.5, 45, 19, 39.5, 15.5, 34, 19])
            k.part(tunicP, tunic)
            k.clip(tunicP) {
                k.fill(rrect(30, 26, 40, 5, 0), Tone(0x3b2c3f))
            }
            k.stroke(tunicP, k.ink, k.line)
            k.flat(rrect(47.5, 25, 7, 7, 1.5), Tone(0xffd23f))
            k.flat(stickerFestiveLimb(63, 40, armR, 14, 6.5), tunic)
            let h = stickerFestiveEnd(63, 40, armR, 14, 6.5)
            stickerElfHeld(f, k, h)
            k.flat(circ(h.x, h.y, 3.6), skinT)
            let ear = poly([63, 59, 64, 50, 79, 63])
            k.with(about(65, 56, rot: earA)) { k.flat(ear, skinT) }
            k.with(about(39, 56, rot: -earA)) { k.flat(mirror(ear, 52), skinT) }
            k.part(circ(52, 56, 16), skinT, shape: ell(74, 50, 9, 20))
            let cone = smooth([34, 67, 70, 67, 63, 84, tipX + 10, tipY + 6, tipX, tipY, tipX + 12, tipY - 4, 42, 79], t: 0.5)
            k.part(cone, hat)
            k.part(rrect(33, 63, 38, 8.5, 4.25), trim)
            if f.variant % 5 == 4 {
                k.flat(softStar(tipX, tipY, 7.5), Tone(0xffd23f))
            } else {
                k.flat(circ(tipX, tipY, 4.4), trim)
            }
            k.face(55 + lx, 53, spread: 6.4, rx: 4, ry: 5.2, look: look)
            k.marks(76, 80, 12)
        }
    }

    private static func stickerElfHeld(_ f: FigureFrame, _ k: StickerKit, _ h: CGPoint) {
        switch f.variant % 5 {
        case 2:
            stickerFestiveCane(k, h.x, h.y, 1)
        case 3:
            let b = rrect(h.x - 2, h.y - 7, 12, 10, 2)
            k.flat(b, Tone(0x3f8ee8))
            k.fill(rrect(h.x + 2.8, h.y - 7, 2.4, 10, 0), Tone(0xffd23f))
            k.stroke(b, k.ink, k.line)
        default:
            break
        }
    }

    static func reindeer(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0xa8693e), Tone(0xf4dab4), Tone(0xff3b3b)), (Tone(0x8a5a36), Tone(0xf0d4ae), Tone(0x3b2c3f)),
            (Tone(0xc98d5a), Tone(0xfbe8c8), Tone(0x3b2c3f)), (Tone(0xe6d8c6), Tone(0xffffff), Tone(0xff8fa8)),
            (Tone(0x7a4a2c), Tone(0xe8c8a0), Tone(0x3b2c3f)),
        ]
        let (fur, belly, nose) = f.pick(looks)
        let antler = Tone(0xf1cf94)
        let st = f.sway * f.energy
        var a1: CGFloat = 0.38 * st, a2: CGFloat = -0.38 * st
        var hx: CGFloat = 0, hy: CGFloat = 0, hrot: CGFloat = 0
        var bodyY: CGFloat = 0
        var rot: CGFloat = 0
        var look: CGFloat = 0.5
        var ear: CGFloat = 0.2 * f.twitch
        var lying = false
        let bob: CGFloat = 1.4 * f.bounce * f.energy
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            lying = true
            bodyY = -12
            hy = -16
            hx = 2
            hrot = -0.12
            ear = -0.4
        case .startled:
            a1 = 0.22
            a2 = -0.22
            hy = 5
            hx = -2
            bodyY = 2
            ear = 0.35
        case .fleeing:
            a1 = 0.6 * f.sway
            a2 = -0.6 * f.sway
            hy = -4
            hx = 3
            rot = -0.06
            look = 1
            ear = 0.6
        case .dizzy:
            rot = 0.12 * sin(f.t)
            hrot = 0.1 * sin(f.t + 1)
        }
        let hoof = Tone(0x3b2c3f)
        k.with(about(50, 5, rot: rot).translatedBy(x: 0, y: lying ? 0 : bob)) {
            if lying {
                k.part(ell(36, 9, 11, 5), fur.dim(0.82))
                k.part(ell(64, 9, 11, 5), fur.dim(0.82))
            } else {
                for (x, a) in [(34, a2), (60, a1)] as [(CGFloat, CGFloat)] {
                    k.flat(stickerFestiveLimb(x, 28 + bodyY, -.pi / 2 + a, 26.5 + bodyY, 7), fur.dim(0.8))
                    let e = stickerFestiveEnd(x, 28 + bodyY, -.pi / 2 + a, 26.5 + bodyY, 7)
                    k.flat(rrect(e.x - 4, e.y - 2.6, 8, 5, 2), hoof)
                }
            }
            k.with(CGAffineTransform(translationX: 0, y: bodyY)) {
                k.flat(smooth([22, 46, 13, 52, 19, 41], t: 0.5), belly)
                let neck = poly([55, 44, 67, 46 + hy * 0.6, 74 + hx, 60 + hy, 60, 56])
                stickerFestiveBlob(k, [neck, ell(44, 36, 25, 16)], fur, shape: ell(46, 20, 30, 10)) {
                    k.fill(ell(42, 21, 19, 7), belly)
                }
            }
            if !lying {
                for (x, a) in [(28, a1), (56, a2)] as [(CGFloat, CGFloat)] {
                    k.flat(stickerFestiveLimb(x, 28 + bodyY, -.pi / 2 + a, 26.5 + bodyY, 7), fur)
                    let e = stickerFestiveEnd(x, 28 + bodyY, -.pi / 2 + a, 26.5 + bodyY, 7)
                    k.flat(rrect(e.x - 4, e.y - 2.6, 8, 5, 2), hoof)
                }
            }
            k.with(about(72, 60, rot: hrot).translatedBy(x: hx, y: hy + bodyY * 0.4)) {
                stickerReindeerHead(f, k, fur: fur, belly: belly, nose: nose, antler: antler, ear: ear, look: look)
            }
        }
    }

    private static func stickerReindeerHead(_ f: FigureFrame, _ k: StickerKit, fur: Tone, belly: Tone, nose: Tone, antler: Tone, ear: CGFloat, look: CGFloat) {
        let aw: CGFloat = 4.6
        let left = smooth([64, 74, 59, 87, 52, 95], closed: false, t: 0.8)
        let leftT = line(59, 86, 66, 95)
        let right = smooth([79, 76, 82, 89, 89, 97], closed: false, t: 0.8)
        let rightT = line(82, 88, 76, 95)
        for p in [left, leftT, right, rightT] { k.stroke(p, k.ink, aw + k.line * 2) }
        for p in [left, leftT, right, rightT] { k.stroke(p, antler, aw) }
        if f.variant % 5 == 4 {
            k.flat(ell(83, 92, 6.5, 3.4, 0.5), Tone(0x5fd36a))
            k.flat(ell(91, 89, 6.5, 3.4, -0.4), Tone(0x5fd36a))
            k.flat(circ(87, 88.5, 3), Tone(0xff3d5a))
        }
        k.with(about(60, 70, rot: ear)) { k.flat(ell(53, 72, 8, 3.8, 0.4), fur) }
        k.with(about(84, 72, rot: -ear)) { k.flat(ell(91, 74, 7.5, 3.6, -0.35), fur) }
        stickerFestiveBlob(k, [circ(71, 64, 15.5), ell(85, 57, 11, 9)], fur, shape: ell(88, 44, 20, 10))
        k.fill(ell(87, 55, 9, 6), belly)
        k.gloss(62, 72, 2, 3.6, -0.5)
        k.face(71 + look, 67, spread: 5.8, rx: 3.7, ry: 4.9, mouth: .none, blush: false, look: look)
        k.blush(81.5, 60.5, 3, 1.8)
        k.mouth(88, 53.5, 5.4)
        k.flat(circ(95, 59, 4.8), nose)
        k.gloss(93.8, 60.6, 1.3, 1.8)
        switch f.variant % 5 {
        case 1:
            k.part(rrect(58, 46, 17, 5.5, 2.75), Tone(0xe8473f))
            k.flat(circ(67, 44, 3.8), Tone(0xffd23f))
            k.fill(rrect(65.8, 42, 2.4, 1, 0.4), k.ink)
        case 2, 3:
            let scarf = f.variant % 5 == 2 ? Tone(0x3fae55) : Tone(0x4f9ae8)
            k.part(rrect(56, 45, 20, 7, 3.5), scarf)
            k.part(poly([58, 47, 64, 47, 61, 34, 55, 35]), scarf)
        default:
            break
        }
        k.marks(95, 82, 12)
    }

    static func blackCat(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0x3d3760), Tone(0xd8ee5a)), (Tone(0x3d3760), Tone(0xffc93c)), (Tone(0x3d3760), Tone(0x7fe0c8)),
            (Tone(0x7a7f9c), Tone(0xffd23f)), (Tone(0x3d3760), Tone(0x9be86a)),
        ]
        let (fur, eyeT) = f.pick(looks)
        let shadow = fur.dim(0.68)
        let muzzle = fur.mix(Tone(0xe4def8), 0.7)
        let st = f.sway * f.energy
        var a1: CGFloat = 0.35 * st, a2: CGFloat = -0.35 * st
        var tail: CGFloat = 3 * f.swing * f.energy + 2 * f.twitch
        var tailUp: CGFloat = 0
        var hy: CGFloat = 0, hx: CGFloat = 0
        var rot: CGFloat = 0
        var look: CGFloat = 0.4
        var ear: CGFloat = 0.12 * f.twitch
        var bodyY: CGFloat = 0
        var sit = false
        var arch: CGFloat = 0
        let bob: CGFloat = 1.2 * f.bounce * f.energy
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sit = true
            bodyY = -9
            hy = -14
            hx = -2
            tail = -6
            tailUp = -24
            ear = -0.3
        case .startled:
            arch = 7
            a1 = 0.18
            a2 = -0.18
            tailUp = 6
            tail = 2 * f.swing2
            hy = 3
            ear = 0.3
        case .fleeing:
            a1 = 0.65 * f.sway
            a2 = -0.65 * f.sway
            tail = -10
            tailUp = -12
            hx = 3
            hy = -3
            rot = -0.06
            look = 1
            ear = 0.5
        case .dizzy:
            rot = 0.12 * sin(f.t)
            tail = 6 * sin(f.t * 2)
        }
        let paw = fur.dim(0.85)
        k.with(about(50, 5, rot: rot).translatedBy(x: 0, y: sit ? 0 : bob)) {
            let tp = smooth([26, 34 + bodyY + arch, 14, 42 + bodyY + tailUp * 0.3, 10 + tail * 0.3, 58 + bodyY + tailUp * 0.7, 15 + tail, 70 + bodyY + tailUp, 23 + tail, 70 + bodyY + tailUp], closed: false, t: 0.9)
            stickerFestiveTube(k, tp, fur, 6.5)
            if sit {
                k.part(ell(36, 9, 10, 5), paw)
                k.part(ell(60, 8, 9, 5), paw)
            } else {
                for (x, a) in [(34, a2), (58, a1)] as [(CGFloat, CGFloat)] {
                    k.flat(stickerFestiveLimb(x, 26 + arch, -.pi / 2 + a, 24.5 + arch, 7), paw)
                }
            }
            k.with(CGAffineTransform(translationX: 0, y: bodyY)) {
                let body = smooth([22, 30 + arch * 0.6, 32, 42 + arch, 48, 44 + arch * 1.2, 62, 40 + arch * 0.6, 66, 28, 56, 18, 34, 18, 24, 22], t: 0.8)
                k.part(body, fur, shadow: shadow, shape: ell(44, 12, 26, 9))
                if f.variant % 5 == 4 { k.clip(body) { k.fill(ell(62, 26, 8, 12), Tone(0xf7f4ff)) } ; k.stroke(body, k.ink, k.line) }
            }
            if !sit {
                for (x, a) in [(28, a1), (54, a2)] as [(CGFloat, CGFloat)] {
                    k.flat(stickerFestiveLimb(x, 26 + arch, -.pi / 2 + a, 24.5 + arch, 7), fur)
                }
            }
            k.with(CGAffineTransform(translationX: hx, y: hy + bodyY * 0.3)) {
                stickerCatHead(f, k, fur: fur, shadow: shadow, muzzle: muzzle, eyeT: eyeT, ear: ear, look: look)
            }
        }
    }

    private static func stickerCatHead(_ f: FigureFrame, _ k: StickerKit, fur: Tone, shadow: Tone, muzzle: Tone, eyeT: Tone, ear: CGFloat, look: CGFloat) {
        let pink = Tone(0xff9fbf)
        let earP = poly([55, 58, 56, 80, 69, 66])
        let earI = poly([58, 63, 58.5, 73.5, 65, 66.5])
        k.with(about(61, 63, rot: ear)) {
            k.flat(earP, fur)
            k.fill(earI, pink)
        }
        k.with(about(79, 63, rot: -ear)) {
            k.flat(mirror(earP, 70), fur)
            k.fill(mirror(earI, 70), pink)
        }
        if f.variant % 5 == 2 { stickerFestiveBow(k, 82, 73, 7, Tone(0xff6fa8), -0.4) }
        let head = ell(70, 51, 18, 16)
        k.part(head, fur, shadow: shadow, shape: ell(90, 42, 9, 18))
        let lx = look * 1.8
        k.fill(ell(71 + lx, 42.5, 8, 5.4), muzzle)
        k.gloss(59, 59, 1.8, 3.4, -0.5)
        let open = !(f.eyesShut && f.mood != .dizzy)
        k.both { s in
            k.fs(ell(70 + lx + s * 7, 53, 4.9, 5.9), open ? eyeT : muzzle, k.ink, k.thin)
        }
        k.face(70 + lx, 53, spread: 7, rx: 2.7, ry: 4.5, mouth: .none, blush: false, look: look)
        k.fill(poly([68.6 + lx, 46.5, 73.4 + lx, 46.5, 71 + lx, 43.8]), pink)
        k.mouth(71 + lx, 43.2, 5)

        switch f.variant % 5 {
        case 0:
            k.part(rrect(59, 33, 22, 5.5, 2.75), Tone(0x8a5ad6))
            k.flat(circ(70, 31.5, 3.8), Tone(0xffd23f))
            k.fill(rrect(68.8, 29.3, 2.4, 1, 0.4), k.ink)
        case 1:
            stickerFestiveWitchHat(k, 70, 64, 24, Tone(0x6a45b8), Tone(0xff9a2a), 0.15)
        case 3:
            let scarf = Tone(0xe8473f)
            k.part(rrect(57, 32, 26, 6.5, 3.2), scarf)
            k.part(poly([59, 34, 65, 34, 62, 22, 56, 23]), scarf)
        case 4:
            let tie = Tone(0xe8473f)
            k.flat(poly([70, 33, 63, 37.5, 63, 28.5]), tie)
            k.flat(poly([70, 33, 77, 37.5, 77, 28.5]), tie)
            k.flat(circ(70, 33, 2.3), tie.dim(0.85))
        default:
            break
        }
        k.marks(88, 72, 12)
    }

    static func santa(_ f: FigureFrame, _ k: StickerKit) {
        let suits: [Tone] = [Tone(0xe0383e), Tone(0xe0383e), Tone(0xe0383e), Tone(0xe0383e), Tone(0x3f9e5a)]
        let suit = f.pick(suits)
        let fur = Tone(0xfdf9f2)
        let skinT = Tone(0xffd0ae)
        let dark = Tone(0x2e2638)
        let st = f.sway * f.energy
        var legA: CGFloat = -.pi / 2 + 0.35 * st, legB: CGFloat = -.pi / 2 - 0.35 * st
        var armR: CGFloat = -0.9 - 0.3 * st, armL: CGFloat = .pi + 0.9 - 0.3 * st
        var rot: CGFloat = 0, sy: CGFloat = 1, sx: CGFloat = 1
        var look: CGFloat = 0
        var pom = pt(19 - 2 * f.swing * f.energy, 74 + f.twitch * 2)
        let bob: CGFloat = 1.5 * f.bounce * f.energy
        switch f.mood {
        case .calm:
            if f.twitch > 0 && f.variant % 5 != 2 { armR = 1.0 + 0.2 * f.swing2 }
        case .sleepy:
            legA = -.pi / 2 + 0.05
            legB = -.pi / 2 - 0.05
            armR = -1.35
            armL = .pi + 1.35
            sy = 0.95
            sx = 1.03
            rot = 0.05
            pom = pt(29, 64)
        case .startled:
            legA = -.pi / 2 + 0.3
            legB = -.pi / 2 - 0.3
            armR = 1.0 + 0.08 * f.swing2
            armL = .pi - 1.0 - 0.08 * f.swing2
            sy = 1.05
            pom = pt(24, 98)
        case .fleeing:
            legA = -.pi / 2 + 0.6 * f.sway
            legB = -.pi / 2 - 0.6 * f.sway
            armR = .pi - 0.7 + 0.3 * f.swing
            armL = .pi - 0.3 - 0.3 * f.swing
            rot = -0.09
            look = 1
            pom = pt(9, 82 + 2 * f.swing2)
        case .dizzy:
            rot = 0.12 * sin(f.t)
            armR = -0.4 + 0.4 * sin(f.t)
            armL = .pi + 0.4 + 0.4 * sin(f.t)
            pom = pt(19 + 6 * sin(f.t), 74)
        }
        let lx = look * 2.2
        k.with(about(50, 5, rot: rot, sx: sx, sy: sy).translatedBy(x: 0, y: bob)) {
            if f.variant % 5 == 1 {
                let sack = smooth([30, 36, 44, 44, 40, 64, 30, 76, 16, 70, 12, 52, 18, 38], t: 0.8)
                k.part(sack, Tone(0xb07a4a))
                k.flat(rrect(27, 74, 8, 4, 2), Tone(0xe0383e))
            }
            for (hx, a) in [(43, legA), (57, legB)] as [(CGFloat, CGFloat)] {
                k.flat(stickerFestiveLimb(hx, 18, a, 14, 9), suit)
                let e = stickerFestiveEnd(hx, 18, a, 14, 9)
                k.flat(smooth([e.x - 5, e.y - 3.5, e.x + 7, e.y - 3.5, e.x + 8, e.y + 1.5, e.x + 1, e.y + 4, e.x - 5, e.y + 3], t: 0.6), dark)
            }
            k.flat(stickerFestiveLimb(30, 42, armL, 16, 9), suit)
            let hl = stickerFestiveEnd(30, 42, armL, 16, 9)
            k.flat(circ(hl.x, hl.y, 4.4), dark)
            let belly = ell(50, 33, 23, 21)
            k.part(belly, suit, shape: ell(76, 24, 14, 32))
            k.clip(belly) {
                k.fill(rrect(52, 0, 7, 60, 0), fur)
                k.fill(rrect(20, 8, 60, 6, 0), fur)
                k.fill(rrect(20, 26, 60, 6.5, 0), dark)
            }
            k.stroke(belly, k.ink, k.line)
            k.fs(rrect(50.5, 24.5, 10, 9.5, 2), dark, Tone(0xffcf3c), 2.2)
            k.flat(stickerFestiveLimb(70, 42, armR, 16, 9), suit)
            let hr = stickerFestiveEnd(70, 42, armR, 16, 9)
            if f.variant % 5 == 2 {
                let b = rrect(hr.x - 3, hr.y - 9, 14, 12, 2)
                k.flat(b, Tone(0x3fb56a))
                k.fill(rrect(hr.x + 2.6, hr.y - 9, 2.8, 12, 0), Tone(0xffd23f))
                k.stroke(b, k.ink, k.line)
                stickerFestiveBow(k, hr.x + 4, hr.y + 3.5, 3.2, Tone(0xffd23f))
            }
            k.flat(circ(hr.x, hr.y, 4.4), dark)
            k.part(circ(55, 63, 16), skinT, shape: ell(76, 58, 7, 18))
            let beard = smooth([39, 60, 42, 49, 47, 41, 55, 36, 63, 41, 68, 49, 71, 60, 65, 56, 55, 53.5, 45, 56], t: 0.7)
            k.part(beard, fur, shadow: Tone(0xd8d4ee))
            let hat = smooth([38, 76, 72, 76, 63, 90, pom.x + 12, pom.y + 12, pom.x, pom.y, pom.x + 12, pom.y + 4, 44, 84], t: 0.5)
            k.part(hat, suit)
            k.part(rrect(36, 73, 38, 8, 4), fur, shadow: Tone(0xd8d4ee))
            k.part(circ(pom.x, pom.y, 5), fur, shadow: Tone(0xd8d4ee))
            k.face(57 + lx, 65.5, spread: 6, rx: 3.6, ry: 4.7, mouth: .none, blush: false, look: look)
            k.blush(46 + lx, 60, 2.8, 1.7)
            k.blush(68 + lx, 60, 2.8, 1.7)
            k.mouth(57 + lx, 49, 5.6)
            k.fs(ell(52 + lx, 55.5, 5.5, 2.8, 0.25), fur, k.ink, k.thin * 0.8)
            k.fs(ell(62 + lx, 55.5, 5.5, 2.8, -0.25), fur, k.ink, k.thin * 0.8)
            k.fs(circ(57 + lx, 58.4, 2.6), Tone(0xff9f8a), k.ink, k.thin * 0.8)
            if f.variant % 5 == 3 {
                k.stroke(circ(51 + lx, 65.5, 4.6), Tone(0xffcf3c), k.thin)
                k.stroke(circ(63 + lx, 65.5, 4.6), Tone(0xffcf3c), k.thin)
            }
            k.marks(78, 88, 13)
        }
    }
}
