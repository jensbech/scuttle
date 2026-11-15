import Foundation
import CoreGraphics
import ScuttleCore

extension StickerArt {
    static func balloon(_ f: FigureFrame, _ k: StickerKit) {
        let tones: [Tone] = [Tone(0xff4f6d), Tone(0x4fa3ff), Tone(0xff7ab8), Tone(0x3fd39a), Tone(0xffa63a)]
        let base = f.pick(tones)
        let v = f.variant % 5
        let t = f.t
        var sx: CGFloat = 1, sy: CGFloat = 1 + 0.025 * f.swing2, rot: CGFloat = 0.04 * f.swing
        var trail: CGFloat = 0, wave: CGFloat = 3, look: CGFloat = 0, sink: CGFloat = 0
        switch f.mood {
        case .calm:
            rot += 0.07 * f.twitch
        case .sleepy:
            sx = 1.05
            sy = 0.9
            rot = -0.16
            wave = 1
            sink = 3
        case .startled:
            sx = 0.93
            sy = 1.1
            wave = 4 * sin(4 * t)
        case .fleeing:
            trail = 18
            wave = 4
            rot = -0.14
            look = 1
        case .dizzy:
            rot = 0.14 * sin(t)
            wave = 5
        }
        let tf = about(50, 50, rot: rot, sx: sx, sy: sy).translatedBy(x: 0, y: -sink)
        let knot = pt(50, 25).applying(tf)
        var pts: [CGFloat] = []
        for i in 0...4 {
            let u = CGFloat(i) / 4
            let x: CGFloat = knot.x - trail * u * u + wave * u * sin(t + u * 4.5)
            let y: CGFloat = knot.y - u * (knot.y - 2) + trail * 0.4 * u * u
            pts += [x, y]
        }
        balloonCord(k, smooth(pts, closed: false), Tone(0xfff4e6), k.thin * 0.9)
        k.with(tf) {
            k.flat(poly([44.5, 23.5, 55.5, 23.5, 50, 31]), base.dim(0.85))
            let body: CGPath = v == 2 ? heart(50, 58, 29) : smooth([50, 90, 69, 86, 78, 68, 74, 47, 60, 32, 50, 29, 40, 32, 26, 47, 22, 68, 31, 86])
            k.part(body, base, shadow: k.shade(base), shape: ell(88, 50, 24, 46))
            if v == 3 {
                k.clip(body) {
                    for d in [(29, 56, 3.6), (66, 79, 3.6), (69, 44, 3.2), (46, 38, 3.0), (40, 82, 2.6)] as [(CGFloat, CGFloat, CGFloat)] {
                        k.fill(circ(d.0, d.1, d.2), Tone.white.alpha(0.9))
                    }
                }
                k.stroke(body, k.ink, k.line)
            }
            k.gloss(34, 74, 3.6, 7.5, -0.45)
            k.gloss(40.5, 84, 1.9, 1.9)
            k.face(50 + look * 2.5, 60, spread: 8.5, rx: 5, ry: 6.6)
            if v == 1 { balloonBow(k, 50, 27, 1.0, Tone(0xffd23f)) }
            if v == 4 { bunnyPartyHat(k, 53, 86, 0.8, -0.14, Tone(0x8a5cff), Tone(0x5fe3d0)) }
            k.marks(77, 86, 13)
        }
    }

    static func star(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xffd23f), Tone(0xf5a524)), (Tone(0xff8cc6), Tone(0xe763a6)), (Tone(0x6cc6ff), Tone(0x4b98e6)),
            (Tone(0xffa040), Tone(0xe9762a)), (Tone(0x8fe6a8), Tone(0x58c487)),
        ]
        let (base, shadow) = f.pick(looks)
        let v = f.variant % 5
        let t = f.t
        var sx: CGFloat = 1, sy: CGFloat = 1, rot: CGFloat = 0.06 * f.swing, inner: CGFloat = 0.54, look: CGFloat = 0
        switch f.mood {
        case .calm:
            rot += 0.08 * f.twitch
        case .sleepy:
            sx = 1.06
            sy = 0.92
            rot = 0.24
            inner = 0.6
        case .startled:
            sx = 0.95
            sy = 1.08
            inner = 0.46
        case .fleeing:
            rot = -0.16
            look = 1
        case .dizzy:
            rot = 0.15 * sin(t)
        }
        if f.mood == .fleeing {
            for i in 0..<3 {
                let u = CGFloat(i)
                let r: CGFloat = 7 - 1.5 * u
                let y: CGFloat = 52 + 4 * sin(t * 2 + u * 1.4)
                k.flat(star(10 - 10 * u, y, r, points: 5, inner: 0.5, spin: t + u), base.lift(0.35), w: k.thin)
            }
        } else if f.mood != .sleepy {
            let spots: [(CGFloat, CGFloat)] = [(9, 84), (91, 86), (93, 14)]
            for (i, s) in spots.enumerated() {
                let g = sin(t + CGFloat(i) * 2.1)
                if g > 0.2 {
                    k.flat(star(s.0, s.1, 7 * g, points: 4, inner: 0.38), Tone(0xfff6c0), w: k.thin)
                }
            }
        }
        k.with(about(50, 48, rot: rot, sx: sx, sy: sy)) {
            let body = softStar(50, 48, 41, points: 5, inner: inner, t: 0.55)
            k.part(body, base, shadow: shadow, shape: ell(98, 34, 32, 52))
            k.gloss(33, 63, 2.6, 5.5, -0.6)
            switch v {
            case 1: balloonBow(k, 27, 66, 0.95, Tone(0xff4f6d), 0.35)
            case 2: bunnyPartyHat(k, 51, 77, 0.85, -0.1, Tone(0xff5c9a), Tone(0xffe14a))
            case 3: starCrown(k, 50, 78, 1.1, 0.05)
            case 4: starFlower(k, 72, 70, 1.3, Tone(0xff7ab8))
            default: break
            }
            k.face(50 + look * 2, 49, spread: 8.5, rx: 5, ry: 6.6)
            k.marks(80, 80, 12)
        }
    }

    static func sparkler(_ f: FigureFrame, _ k: StickerKit) {
        let tones: [Tone] = [Tone(0xff5c9a), Tone(0x4f9dff), Tone(0x4fcf86), Tone(0x9a6cff), Tone(0x2fc4c4)]
        let base = f.pick(tones)
        let v = f.variant % 5
        let t = f.t, e = f.energy
        var burst: CGFloat = 1, sy: CGFloat = 1, rot: CGFloat = 0, look: CGFloat = 0, stream: CGFloat = 0
        var armL: CGFloat = 0.5, armR: CGFloat = -0.5, sparks = 4
        let swingA: CGFloat = 0.45 * f.swing * e
        switch f.mood {
        case .calm:
            armR += 1.1 * max(0, f.twitch)
        case .sleepy:
            burst = 0.55
            sy = 0.94
            sparks = 2
            armL = 1.0
            armR = -1.0
        case .startled:
            burst = 1.3
            sy = 1.06
            armL = -0.9
            armR = 0.9
        case .fleeing:
            stream = 1
            look = 1
            armL = 0.2
            armR = -0.2
        case .dizzy:
            rot = 0.12 * sin(t)
        }
        armL += swingA
        armR += swingA
        let bob: CGFloat = 1.4 * f.bounce * e
        let yellow = f.mood == .sleepy ? Tone(0xffa040) : Tone(0xffe14a)
        let orange = f.mood == .sleepy ? Tone(0xff6a3a) : Tone(0xffa52e)
        k.with(about(50, 5, rot: rot)) {
            for which in [1, 0] {
                let o = CGFloat(which) * .pi
                let dx: CGFloat = 6 * cos(t + o) * e
                let lift: CGFloat = max(0, -sin(t + o)) * 4 * e
                let hx: CGFloat = which == 0 ? 45 : 55
                balloonCord(k, line(hx, 20 + bob, hx + dx, 8 + lift), Tone(0x8f8aa8), k.thin * 1.4)
                k.flat(ell(hx + dx + 2, 6 + lift, 5.6, 3.4), base.dim(0.7))
            }
            k.with(about(50, 16, sx: 1, sy: sy).translatedBy(x: 0, y: bob)) {
                k.flat(rrect(47.5, 60, 5, 12, 2.5), Tone(0x9a97b0))
                let bx: CGFloat = 50 - 2 * stream, by: CGFloat = 80
                var pts: [CGPoint] = []
                var rng = Noise(f.frameIndex * 7 + 3)
                let n = 9
                for i in 0..<(2 * n) {
                    let a: CGFloat = CGFloat(i) * .pi / CGFloat(n) + CGFloat(f.frameIndex) * 0.21
                    let jitter: CGFloat = 4 * rng.next()
                    let r: CGFloat = i % 2 == 0 ? (14 + jitter) * burst : 7.5 * burst
                    let ca = cos(a)
                    let ex: CGFloat = ca < 0 ? 1 + 0.7 * stream : 1
                    pts.append(pt(bx + r * ca * ex, by + r * sin(a)))
                }
                k.part(polyP(pts), yellow, shadow: orange, shape: ell(bx + 11 * burst, by - 9 * burst, 12 * burst, 11 * burst))
                k.fill(circ(bx, by, 5 * burst), Tone(0xfffbe6))
                for i in 0..<sparks {
                    let u: CGFloat = (f.phase * 2 + CGFloat(i) / CGFloat(sparks)).truncatingRemainder(dividingBy: 1)
                    let a: CGFloat = CGFloat(i) * 2.4 + 0.6
                    let d: CGFloat = (18 + 11 * u) * burst
                    let x: CGFloat = bx + cos(a) * d - stream * 20 * u
                    let y: CGFloat = by + sin(a) * d
                    let r: CGFloat = (8 - 3.5 * u) * max(0.8, burst)
                    k.flat(star(x, y, r, points: 4, inner: 0.5, spin: 0.3 * CGFloat(i)), Tone(0xffe14a), w: k.thin * 0.8)
                }
                k.with(about(37, 42, rot: armL)) { k.flat(ell(31, 42, 7, 4.2), base) }
                k.with(about(63, 42, rot: armR)) { k.flat(ell(69, 42, 7, 4.2), base) }
                let body = rrect(36, 16, 28, 48, 13)
                k.part(body, base, shadow: k.shade(base), shape: ell(72, 30, 13, 44))
                if v == 2 {
                    k.clip(body) {
                        for i in 0..<4 {
                            let y0 = 10 + CGFloat(i) * 15
                            k.fill(poly([30, y0, 70, y0 + 16, 70, y0 + 22, 30, y0 + 6]), Tone.white.alpha(0.55))
                        }
                    }
                    k.stroke(body, k.ink, k.line)
                }
                k.gloss(41, 56, 2.2, 4.5, -0.3)
                k.face(51 + look * 2, 45, spread: 6.5, rx: 3.9, ry: 5.2, blush: false)
                k.blush(41.5 + look * 2, 38, 2.8, 1.6)
                k.blush(60.5 + look * 2, 38, 2.8, 1.6)
                switch v {
                case 1:
                    let red = Tone(0xff4f5e)
                    k.flat(poly([50, 28, 42, 32, 42, 24]), red, w: k.thin)
                    k.flat(poly([50, 28, 58, 32, 58, 24]), red, w: k.thin)
                    k.flat(circ(50, 28, 2.2), red.dim(0.85), w: k.thin)
                case 3:
                    k.flat(star(44, 26, 5.5, points: 5, inner: 0.48), Tone(0xffd23f), w: k.thin)
                case 4:
                    let red = Tone(0xff4f5e)
                    k.with(about(40, 28, rot: 0.2 - 0.15 * f.swing * e)) {
                        k.flat(rrect(31, 15, 7, 15, 3), red, w: k.thin)
                    }
                    k.flat(rrect(34, 27, 32, 6.5, 3.2), red, w: k.thin)
                default: break
                }
                k.marks(70, 70, 12)
            }
        }
    }

    static func rocket(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xf4f1ff), Tone(0xff4f5e)), (Tone(0x6cbcff), Tone(0xffcd38)), (Tone(0xff8fc2), Tone(0x8a5cff)),
            (Tone(0x7fe3c0), Tone(0xff8a3c)), (Tone(0xffd84a), Tone(0x4a6cff)),
        ]
        let (hull, trim) = f.pick(looks)
        let v = f.variant % 5
        let t = f.t
        var flame: CGFloat = 25, sx: CGFloat = 1, sy: CGFloat = 1, rot: CGFloat = 0.025 * sin(t), look: CGFloat = 0, wob: CGFloat = 0
        switch f.mood {
        case .calm:
            flame += 3 * f.twitch
        case .sleepy:
            flame = 7
            rot = -0.08
        case .startled:
            flame = 27
            sx = 0.95
            sy = 1.08
        case .fleeing:
            flame = 36
            sx = 1.07
            sy = 0.95
            look = 1
        case .dizzy:
            rot = 0.14 * sin(t)
            wob = 5
        }
        let flick: CGFloat = 1 + 0.14 * sin(t * 4) + 0.06 * sin(t * 7)
        k.with(about(50, 50, rot: rot, sx: sx, sy: sy)) {
            let L = flame * flick
            let w: CGFloat = f.mood == .startled ? 11 : 9
            let tipY: CGFloat = 50 + wob * sin(t * 2)
            if f.mood == .sleepy {
                k.flat(circ(4, 54, 5), Tone(0xeceaf6), w: k.thin)
                k.flat(circ(-5, 60, 3.4), Tone(0xeceaf6), w: k.thin)
            }
            let outer = smooth([18, 50 + w, 18 - L * 0.45, 50 + w * 0.9, 18 - L, tipY, 18 - L * 0.45, 50 - w * 0.9, 18, 50 - w], t: 0.9)
            k.flat(outer, Tone(0xff7a2e))
            let wi = w * 0.55
            let inner = smooth([18, 50 + wi, 18 - L * 0.3, 50 + wi * 0.9, 18 - L * 0.62, (tipY + 50) / 2, 18 - L * 0.3, 50 - wi * 0.9, 18, 50 - wi], t: 0.9)
            k.fill(inner, Tone(0xffe14a))
            k.flat(rrect(11, 41, 10, 18, 3), Tone(0x8a87a6))
            let fin = smooth([22, 60, 42, 62, 30, 82, 15, 84, 12, 76], t: 0.6)
            let finLow = xf(fin, CGAffineTransform(translationX: 0, y: 100).scaledBy(x: 1, y: -1))
            k.part(finLow, trim)
            k.part(fin, trim)
            if v == 2 { k.flat(star(25, 74, 5, points: 5, inner: 0.48), Tone.white, w: k.thin) }
            let body = smooth([90, 50, 80, 62, 60, 68, 34, 68, 20, 63, 17, 50, 20, 37, 34, 32, 60, 32, 80, 38], t: 0.85)
            let shade = ell(50, 22, 58, 16)
            k.fill(body, hull)
            k.clip(body) {
                k.fill(shade, k.shade(hull))
                let nose = ell(101, 50, 27, 40)
                k.clip(nose) {
                    k.fill(nose, trim)
                    k.fill(shade, k.shade(trim))
                }
                k.stroke(nose, k.ink, k.thin)
                if v == 1 {
                    let band = rrect(25, 20, 6, 60, 0)
                    k.fill(band, trim)
                    k.stroke(band, k.ink, k.thin)
                }
                if v == 3 {
                    let bolt = poly([30, 66, 23, 52, 29, 52, 24, 36, 36, 55, 30, 55, 36, 66])
                    k.fill(bolt, Tone(0xffe14a))
                    k.stroke(bolt, k.ink, k.thin)
                }
            }
            k.stroke(body, k.ink, k.line)
            if v == 4 {
                balloonCord(k, line(89, 50, 98, 56), Tone(0x9a97b0), k.thin)
                k.flat(circ(99, 57, 3.2), f.frameIndex % 8 < 4 ? Tone(0xff4f5e) : Tone(0xffe14a), w: k.thin)
            }
            let port = circ(54, 50, 13.5)
            k.flat(port, Tone(0xdcf4ff))
            k.clip(port) { k.fill(ell(62, 40, 12, 10), Tone(0xb4def5)) }
            k.stroke(port, k.ink, k.line)
            k.gloss(45.5, 56, 1.6, 3, -0.6)
            k.face(55 + look * 2, 52, spread: 5.4, rx: 3.6, ry: 4.8, blush: false)
            k.blush(47 + look * 2, 45.5, 2.4, 1.4)
            k.blush(63 + look * 2, 45.5, 2.4, 1.4)
            k.marks(74, 70, 12)
        }
    }

    static func bunny(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xfbf7f2), Tone(0xd8d0ea)), (Tone(0xd29a6a), Tone(0xa8714a)), (Tone(0xb8bed8), Tone(0x8d93b8)),
            (Tone(0xffe2a8), Tone(0xe8b86a)), (Tone(0xdcc8ff), Tone(0xb39ae6)),
        ]
        let (fur, sh) = f.pick(looks)
        let pink = Tone(0xffa6c0)
        let v = f.variant % 5
        let t = f.t
        let st = f.stretch, air = f.air
        var sy: CGFloat = 1 - 0.16 * f.squat + 0.1 * st
        var sx: CGFloat = 1 + 0.08 * f.squat - 0.04 * st
        var rot: CGFloat = 0, look: CGFloat = 0, headDy: CGFloat = 0, earLen: CGFloat = 30
        var earA: CGFloat = 0.1 + 0.35 * st + 0.18 * f.twitch
        var earB: CGFloat = 0.3 + 0.35 * st
        var footDx: CGFloat = -7 * max(0, st), footRot: CGFloat = 0.45 * max(0, st)
        var pawX: CGFloat = 62 + 5 * st, pawY: CGFloat = 8 + 10 * air * (1 - air)
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sy *= 0.9
            sx *= 1.06
            earA = 1.35
            earB = 1.6
            headDy = -4
        case .startled:
            sy *= 1.06
            earA = -0.05
            earB = 0.1
            earLen = 34
            pawX = 71
            pawY = 26
        case .fleeing:
            sx *= 1.06
            earA = 1.0
            earB = 1.18
            look = 1
            footDx = -9
            footRot = 0.5
            pawX = 70
        case .dizzy:
            rot = 0.12 * sin(t)
            earA = 0.2 + 0.5 * sin(t)
            earB = 0.5 - 0.5 * sin(t)
        }
        k.with(about(50, 4, rot: rot, sx: sx, sy: sy)) {
            bunnyEar(k, 57, 58 + headDy, earLen - 2, earB, fur.mix(sh, 0.35), sh, pink)
            k.flat(circ(22, 31, 7.5), fur)
            k.part(ell(44, 28, 23, 19), fur, shadow: sh, shape: ell(56, 10, 30, 14))
            k.part(ell(35, 20, 13, 12), fur, shadow: sh, shape: ell(40, 6, 16, 9))
            k.flat(ell(36 + footDx, 7, 13, 5, footRot), fur)
            if v == 1 {
                let cx = pawX + 4, cy = pawY + 6
                k.flat(ell(cx - 2, cy + 11, 2.4, 4.5, 0.4), Tone(0x4fcf6a), w: k.thin)
                k.flat(ell(cx + 2, cy + 11, 2.4, 4.5, -0.4), Tone(0x4fcf6a), w: k.thin)
                k.flat(smooth([cx - 4.5, cy + 7, cx + 4.5, cy + 7, cx + 1, cy - 11], t: 0.5), Tone(0xff8a2e), w: k.thin)
            }
            k.flat(ell(pawX, pawY, 5.5, 4.2), fur)
            bunnyEar(k, 66, 60 + headDy, earLen, earA, fur, sh, pink)
            let hy = 49 + headDy
            k.part(circ(64, hy, 17), fur, shadow: sh, shape: ell(83, hy - 8, 10, 24))
            k.gloss(55, hy + 9, 2, 3.6, -0.6)
            k.face(69 + look * 2, hy + 1, spread: 6, rx: 3.9, ry: 5.1)
            k.fill(ell(69 + look * 2, hy - 3.6, 2.1, 1.5), Tone(0xff7fa0))
            switch v {
            case 2: balloonBow(k, 63, hy + 15, 0.6, Tone(0xff6fae), 0.3)
            case 3: bunnyPartyHat(k, 60, hy + 14, 0.72, 0.28, Tone(0x4fa3ff), Tone(0xffffff))
            case 4: starFlower(k, 58, hy + 14, 0.8, Tone(0xff8fc0))
            default: break
            }
            k.marks(84, 74 + headDy, 12)
        }
    }

    static func turtle(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0x3fb06a), Tone(0x9ce68a), Tone(0xc4e66a)), (Tone(0x2fa6c0), Tone(0x8fe2ec), Tone(0xa8e07a)),
            (Tone(0xe8893a), Tone(0xffc36e), Tone(0x9ad66a)), (Tone(0x8a63d8), Tone(0xc6a8ff), Tone(0x8fe0b4)),
            (Tone(0xff6f9e), Tone(0xffc0d6), Tone(0xa8e07a)),
        ]
        let (shell, plate, skin) = f.pick(looks)
        let v = f.variant % 5
        let t = f.t, e = f.energy
        var hx: CGFloat = 82, hy: CGFloat = 31 + 1.2 * sin(2 * t) * e
        var amp: CGFloat = 4 * e, tuck: CGFloat = 0, splay: CGFloat = 0, look: CGFloat = 0, sy: CGFloat = 1
        var rot: CGFloat = 0.025 * sin(t) * e
        switch f.mood {
        case .calm:
            hy += 1.5 * f.twitch
        case .sleepy:
            hx = 78
            hy = 21
            amp = 0
            tuck = 4
        case .startled:
            hx = 86
            hy = 45
            splay = 0.35
            sy = 1.04
        case .fleeing:
            hx = 89
            hy = 27
            look = 1
            rot -= 0.04
        case .dizzy:
            rot = 0.1 * sin(t)
            hy += 2 * sin(2 * t)
        }
        let bob: CGFloat = 0.8 * abs(sin(t)) * e
        k.with(about(46, 4, rot: rot, sx: 1, sy: sy).translatedBy(x: 0, y: bob)) {
            let legs: [(CGFloat, CGFloat, Bool, CGFloat)] = [(30, .pi, false, -1), (60, 0, false, 1), (20, 0, true, -1), (70, .pi, true, 1)]
            for leg in legs {
                let dx: CGFloat = amp * cos(t + leg.1)
                let lift: CGFloat = max(0, -sin(t + leg.1)) * 2.5 * e
                let x = leg.0 + dx
                k.with(about(x, 16, rot: -leg.3 * splay)) {
                    k.flat(rrect(x - 5.5, 3 + lift + tuck - bob, 11, 15 - tuck, 5.5), leg.2 ? skin : skin.dim(0.85))
                }
            }
            k.flat(smooth([16, 13, 4, 10, 16, 18], t: 0.6), skin)
            balloonCord(k, line(68, 17, hx - 4, hy - 3), skin, 11)
            let dome = CGMutablePath()
            dome.move(to: pt(12, 15))
            dome.addCurve(to: pt(44, 52), control1: pt(12, 40), control2: pt(26, 52))
            dome.addCurve(to: pt(76, 15), control1: pt(62, 52), control2: pt(76, 40))
            dome.closeSubpath()
            k.part(dome, shell, shadow: k.shade(shell), shape: ell(76, 22, 22, 32))
            k.clip(dome) {
                for p in [ell(44, 33, 10, 8), ell(25, 26, 7, 7.5), ell(63, 26, 7, 7.5), ell(33, 46, 6, 4), ell(55, 46, 6, 4)] {
                    k.fs(p, plate, k.ink, k.thin)
                }
                if v == 4 { k.fs(star(44, 33, 9, points: 5, inner: 0.5), Tone(0xffe14a), k.ink, k.thin) }
            }
            k.stroke(dome, k.ink, k.line)
            k.gloss(22, 38, 2.2, 4.6, -0.7)
            k.part(rrect(8, 11, 72, 8, 4), plate)
            if v == 1 { starFlower(k, 50, 52, 0.85, Tone(0xffffff)) }
            let head = circ(hx, hy, 15)
            k.part(head, skin, shadow: skin.dim(0.82), shape: ell(hx + 13, hy - 9, 8, 17))
            k.gloss(hx - 7, hy + 7, 1.8, 3.2, -0.6)
            let fx = hx + 2 + look * 1.5
            k.clip(head) {
                k.blush(fx - 10, hy - 5, 2.8, 1.6)
                k.blush(fx + 10, hy - 5, 2.8, 1.6)
            }
            k.face(fx, hy + 1, spread: 5.4, rx: 3.8, ry: 5, blush: false)
            if v == 2 { bunnyPartyHat(k, hx - 2, hy + 11, 0.7, 0.2, Tone(0xff5c9a), Tone(0xffe14a)) }
            if v == 3 { balloonBow(k, hx - 5, hy + 12, 0.55, Tone(0xff6fae), 0.4) }
            k.marks(hx + 10, hy + 16, 11)
        }
    }

    static func fox(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0xf47b2a), Tone(0xc95a1c), Tone(0x4a2c36)), (Tone(0xeef1fa), Tone(0xc4cbe4), Tone(0x8d93b3)),
            (Tone(0xe0512e), Tone(0xb03a22), Tone(0x3d2430)), (Tone(0xffa03a), Tone(0xd8761e), Tone(0x5a3626)),
            (Tone(0xa3a8c2), Tone(0x7c81a0), Tone(0x3d3a52)),
        ]
        let (fur, sh, sock) = f.pick(looks)
        let cream = Tone(0xfff8ee)
        let v = f.variant % 5
        let t = f.t, e = f.energy
        var bodyY: CGFloat = 25 + 1.2 * f.bounce * e
        var legA: CGFloat = 0.38 * e
        var tailRot: CGFloat = 0.12 * f.swing + 0.15 * f.twitch, tailScale: CGFloat = 1
        var earRot: CGFloat = 0, headDx: CGFloat = 0, headDy: CGFloat = 0, look: CGFloat = 0, rot: CGFloat = 0, sx: CGFloat = 1
        var lying = false
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            lying = true
            bodyY = 15
            tailRot = 1.1
            earRot = 0.4
            headDy = -8
            headDx = 2
        case .startled:
            bodyY = 28
            legA = 0.08
            tailRot = -0.4
            tailScale = 1.12
            earRot = -0.1
            headDy = 4
        case .fleeing:
            sx = 1.08
            tailRot = 0.75
            earRot = 0.6
            headDx = 3
            look = 1
            legA = 0.75
        case .dizzy:
            rot = 0.12 * sin(t)
            tailRot = 0.35 * sin(t)
        }
        k.with(about(50, 4, rot: rot, sx: sx, sy: 1)) {
            let hipY = bodyY - 2
            if !lying {
                foxLeg(k, 33, hipY, 4 + max(0, sin(t)) * 3 * e, legA * cos(t + .pi), 8.5, sh, sock)
                foxLeg(k, 56, hipY, 4 + max(0, -sin(t)) * 3 * e, legA * cos(t), 8.5, sh, sock)
            }
            k.with(CGAffineTransform(translationX: 29, y: bodyY + 3).rotated(by: tailRot).scaledBy(x: tailScale, y: tailScale)) {
                let tail = smooth([4, 4, -6, -6, -20, -4, -31, 10, -29, 27, -18, 33, -11, 22, -5, 10])
                k.fill(tail, fur)
                k.clip(tail) {
                    k.fill(ell(-12, -8, 18, 8), sh)
                    k.fill(circ(-27, 29, 9.5), cream)
                }
                k.stroke(tail, k.ink, k.line)
            }
            let body = lying ? ell(46, bodyY, 25, 11) : ell(48, bodyY, 22, 13)
            k.part(body, fur, shadow: sh, shape: ell(56, bodyY - 13, 30, 8))
            if lying {
                k.flat(ell(70, 6, 7.5, 3.6), sock)
                k.flat(ell(30, 6, 7, 3.4), sock)
            } else {
                foxLeg(k, 40, hipY, 4 + max(0, -sin(t)) * 3 * e, legA * cos(t), 8.5, fur, sock)
                foxLeg(k, 63, hipY, 4 + max(0, sin(t)) * 3 * e, legA * cos(t + .pi), 8.5, fur, sock)
            }
            let hx: CGFloat = 70 + headDx, hy: CGFloat = bodyY + 20 + headDy
            let earInner = v == 1 ? Tone(0xffb8c8) : sock
            k.with(about(hx - 5, hy + 9, rot: earRot)) {
                k.flat(poly([hx - 13, hy + 8, hx - 1, hy + 13, hx - 10, hy + 28]), sh)
            }
            k.with(about(hx + 5, hy + 10, rot: earRot - 0.2 * f.twitch)) {
                let ear = poly([hx - 1, hy + 13, hx + 12, hy + 8, hx + 8, hy + 29])
                k.fill(ear, fur)
                k.fill(poly([hx + 2.5, hy + 12.5, hx + 9, hy + 10.5, hx + 7.4, hy + 22]), earInner)
                k.stroke(ear, k.ink, k.line)
            }
            let head = smooth([hx - 15, hy + 3, hx - 8, hy + 13, hx + 6, hy + 14, hx + 15, hy + 8, hx + 25, hy - 1, hx + 24, hy - 6, hx + 12, hy - 13, hx - 2, hy - 13, hx - 13, hy - 10, hx - 19, hy - 7], t: 0.85)
            k.fill(head, fur)
            k.clip(head) {
                k.fill(smooth([hx - 20, hy - 7, hx - 6, hy - 4, hx + 4, hy - 1, hx + 14, hy + 1, hx + 28, hy - 1, hx + 26, hy - 18, hx - 14, hy - 18], t: 0.8), cream)
            }
            k.stroke(head, k.ink, k.line)
            k.fill(ell(hx + 24, hy - 3, 2.9, 2.5), k.ink)
            k.fill(circ(hx + 23.2, hy - 2.1, 0.9), Tone.white)
            k.face(hx + 4 + look * 1.5, hy + 4, spread: 5.4, rx: 3.9, ry: 5.1, mouth: .none, blush: false)
            k.blush(hx - 6, hy - 3, 2.8, 1.6)
            k.mouth(hx + 15 + look, hy - 6.5, 4.8)
            switch v {
            case 2:
                polarBearScarf(k, f, hx - 11, hy - 5, Tone(0x3fc47a), Tone(0xfff3a0))
            case 3:
                bunnyPartyHat(k, hx - 1, hy + 11, 0.72, 0.15, Tone(0x8a5cff), Tone(0x5fe3d0))
            case 4:
                let red = Tone(0xff4f5e)
                k.flat(poly([hx - 4, hy - 13, hx - 14, hy - 7, hx - 14, hy - 19]), red, w: k.thin)
                k.flat(poly([hx - 4, hy - 13, hx + 6, hy - 7, hx + 6, hy - 19]), red, w: k.thin)
                k.flat(circ(hx - 4, hy - 13, 2.8), red.dim(0.85), w: k.thin)
            default: break
            }
            k.marks(hx + 14, hy + 20, 12)
        }
    }

    static func polarBear(_ f: FigureFrame, _ k: StickerKit) {
        let fur = Tone(0xf7f9ff), sh = Tone(0xc6d4f0)
        let v = f.variant % 5
        let t = f.t, e = f.energy
        var bodyY: CGFloat = 30 + 1.4 * f.bounce * e
        var legA: CGFloat = 0.28 * e
        var headDx: CGFloat = 0, headDy: CGFloat = 0, look: CGFloat = 0, rot: CGFloat = 0, sx: CGFloat = 1, earDy: CGFloat = 0
        var lying = false, frontUp: CGFloat = 0
        switch f.mood {
        case .calm:
            headDy = 2.2 * f.twitch
        case .sleepy:
            lying = true
            bodyY = 17
            headDy = -10
            headDx = 2
        case .startled:
            rot = 0.16
            frontUp = 0.5
            legA = 0.06
            headDy = 3
            earDy = 1.5
        case .fleeing:
            sx = 1.06
            legA = 0.6
            headDx = 3
            look = 1
            earDy = -3
        case .dizzy:
            rot = 0.11 * sin(t)
        }
        k.with(about(30, 4, rot: rot, sx: sx, sy: 1)) {
            let hipY = bodyY - 6
            if !lying {
                foxLeg(k, 26, hipY, 4 + max(0, sin(t)) * 3 * e, legA * cos(t + .pi), 12, sh, sh)
                foxLeg(k, 58, hipY, 4 + max(0, -sin(t)) * 3 * e, legA * cos(t) + frontUp, 12, sh, sh)
            }
            k.flat(circ(17, bodyY + 7, 4.5), fur)
            let body = lying ? ell(46, bodyY, 32, 13) : ell(46, bodyY, 30, 19)
            k.part(body, fur, shadow: sh, shape: ell(56, bodyY - 20, 40, 12))
            if lying {
                k.flat(ell(74, 6, 9, 4), fur)
                k.flat(ell(24, 6, 8, 3.6), fur)
            } else {
                foxLeg(k, 34, hipY, 4 + max(0, -sin(t)) * 3 * e, legA * cos(t), 12, fur, fur)
                foxLeg(k, 66, hipY, 4 + max(0, sin(t)) * 3 * e, legA * cos(t + .pi) + frontUp, 12, fur, fur)
            }
            let hx: CGFloat = 78 + headDx, hy: CGFloat = bodyY + 13 + headDy
            for ex in [hx - 9, hx + 3] {
                k.flat(circ(ex, hy + 13.5 + earDy, 5.6), fur)
                k.fill(circ(ex, hy + 13.5 + earDy, 2.6), sh)
            }
            let head = uni([circ(hx, hy, 16.5), ell(hx + 13, hy - 5, 10, 7.5)])
            k.part(head, fur, shadow: sh, shape: ell(hx + 8, hy - 20, 24, 8))
            k.fill(ell(hx + 22, hy - 3, 3.5, 2.7), k.ink)
            k.fill(circ(hx + 21.2, hy - 2.1, 1), Tone.white)
            k.face(hx + 4 + look * 1.5, hy + 3.5, spread: 5.4, rx: 3.9, ry: 5.1, mouth: .none, blush: false)
            k.blush(hx - 5, hy - 3, 3, 1.7)
            k.mouth(hx + 16 + look, hy - 9.5, 5)
            switch v {
            case 1:
                polarBearScarf(k, f, hx - 11, hy - 8, Tone(0xff4f5e), Tone(0xffffff))
            case 2:
                let cap = CGMutablePath()
                cap.move(to: pt(hx - 14, hy + 11))
                cap.addCurve(to: pt(hx + 11, hy + 12), control1: pt(hx - 14, hy + 29), control2: pt(hx + 11, hy + 29))
                cap.closeSubpath()
                k.part(cap, Tone(0x4f86ff))
                k.flat(rrect(hx - 16, hy + 9, 29, 6.5, 3.2), Tone(0xffffff))
                k.flat(circ(hx - 2 - 3 * f.swing * e, hy + 28, 4.8), Tone(0xffffff))
            case 3:
                bunnyPartyHat(k, hx - 2, hy + 13, 0.8, 0.12, Tone(0xff5c9a), Tone(0xffe14a))
            case 4:
                k.stroke(arc(hx - 11, hy + 9, hx + 6, hy + 11, dip: -11), k.ink, k.line * 2.2)
                k.stroke(arc(hx - 11, hy + 9, hx + 6, hy + 11, dip: -11), Tone(0xb36cff), k.line)
                k.flat(circ(hx - 11, hy + 9, 5.8), Tone(0xff8fc8))
                k.flat(circ(hx + 6, hy + 11, 5.8), Tone(0xff8fc8))
            default: break
            }
            k.marks(hx + 14, hy + 20, 12)
        }
    }

    static func comet(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0xffd84a), Tone(0xff7a3a), Tone(0xffd06a)), (Tone(0xc8eeff), Tone(0x4f9cff), Tone(0x9fd6ff)),
            (Tone(0xffb6dc), Tone(0xc75cff), Tone(0xff8fd8)), (Tone(0xc6ffe0), Tone(0x2fc98a), Tone(0x9af0c4)),
            (Tone(0xfff6d8), Tone(0xff5c7a), Tone(0xffc94a)),
        ]
        let (head, outer, inner) = f.pick(looks)
        let v = f.variant % 5
        let t = f.t
        var len: CGFloat = 1, flare: CGFloat = 0, amp: CGFloat = 2.5, rot: CGFloat = 0.03 * sin(t), look: CGFloat = 0
        var sx: CGFloat = 1, sy: CGFloat = 1
        switch f.mood {
        case .calm:
            amp += 1.5 * f.twitch
        case .sleepy:
            len = 0.62
            amp = 1
            rot = -0.08
        case .startled:
            flare = 1
            sx = 0.96
            sy = 1.06
        case .fleeing:
            len = 1.3
            amp = 3.5
            look = 1
        case .dizzy:
            rot = 0.14 * sin(t)
            amp = 9
        }
        k.with(about(66, 50, rot: rot, sx: sx, sy: sy)) {
            let tail = cometTail(len: len, amp: amp, flare: flare, t: t)
            k.fill(tail, outer)
            k.clip(tail) {
                if v == 4 {
                    let bands: [Tone] = [Tone(0x6c8cff), Tone(0x4fd08a), Tone(0xffd23f), Tone(0xff9a3c), Tone(0xff5c7a)]
                    for (i, b) in bands.enumerated() {
                        k.fill(rrect(-30, 22 + CGFloat(i) * 11.2, 100, 11.4, 0), b)
                    }
                } else {
                    k.fill(xf(tail, about(66, 50, sx: 0.78, sy: 0.55)), inner)
                    k.fill(ell(30, 22, 50, 10), k.shade(outer))
                }
            }
            k.stroke(tail, k.ink, k.line)
            if f.mood != .sleepy {
                let spots: [(CGFloat, CGFloat)] = [(18, 76), (2, 30), (40, 22)]
                for (i, s) in spots.enumerated() {
                    let g = sin(2 * t + CGFloat(i) * 2.2)
                    if g > 0.15 {
                        k.flat(star(s.0 + (1 - len) * 30, s.1, 6.5 * g, points: 4, inner: 0.38), Tone(0xfff6c0), w: k.thin)
                    }
                }
            }
            let ball = circ(66, 50, 18.5)
            k.part(ball, head, shadow: k.shade(head), shape: ell(80, 38, 15, 24, 0.4))
            k.gloss(57, 61, 2.6, 5, -0.6)
            k.face(68 + look * 1.5, 51, spread: 6.2, rx: 4.1, ry: 5.4)
            if v == 2 { balloonBow(k, 62, 67, 0.62, Tone(0xff4fa0), 0.25) }
            if v == 3 { bunnyPartyHat(k, 66, 66, 0.75, -0.05, Tone(0x8a5cff), Tone(0xffe14a)) }
            if v == 1 { k.flat(star(78, 64, 5, points: 4, inner: 0.4), Tone.white, w: k.thin) }
            k.marks(84, 70, 11)
        }
    }

    static func ufo(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xc9c4ec), Tone(0x86e25a)), (Tone(0xff7fb6), Tone(0x4fdcc8)), (Tone(0xffa23c), Tone(0xa87cff)),
            (Tone(0x6fe0b8), Tone(0xff9ad0)), (Tone(0x5b9dff), Tone(0xffd84a)),
        ]
        let (disc, alien) = f.pick(looks)
        let v = f.variant % 5
        let t = f.t
        var rot: CGFloat = 0, ay: CGFloat = 62 + 1.2 * sin(t), look: CGFloat = 0, lean: CGFloat = 0
        var handsUp = false, puffs = false, antA: CGFloat = 0.15 * f.twitch
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            ay = 58
            rot = 0.06
            antA = 0.5
        case .startled:
            ay = 65
            handsUp = true
            antA = -0.15
        case .fleeing:
            lean = 3
            look = 1
            puffs = true
            antA = 0.45
        case .dizzy:
            rot = 0.13 * sin(t)
            antA = 0.4 * sin(2 * t)
        }
        let buzz: CGFloat = f.frameIndex % 2 == 0 ? 0 : 0.6
        k.with(about(50, 40, rot: rot).translatedBy(x: 0, y: buzz)) {
            if puffs {
                k.flat(circ(4, 38, 5), Tone(0xeceaf6), w: k.thin)
                k.flat(circ(-6, 44, 3.4), Tone(0xeceaf6), w: k.thin)
            }
            k.part(ell(50, 31, 21, 8), disc.dim(0.78))
            k.flat(ell(50, 24.5, 7, 3), Tone(0xfff3a0), w: k.thin)
            let dome = minus(ell(50, 50, 25, 31), rrect(0, -10, 100, 50, 0))
            k.fill(dome, Tone(0xd6f5ff))
            k.clip(dome) {
                let ax = 50 + lean
                if handsUp {
                    k.flat(ell(33 + lean, ay + 4, 3.8, 6, 0.4), alien, w: k.thin)
                    k.flat(ell(67 + lean, ay + 4, 3.8, 6, -0.4), alien, w: k.thin)
                }
                if v == 3 {
                    k.with(about(ax, ay + 10, rot: antA)) {
                        k.stroke(line(ax, ay + 10, ax, ay + 16), k.ink, k.thin)
                        k.flat(star(ax, ay + 18, 4.6, points: 5, inner: 0.5), Tone(0xffe14a), w: k.thin)
                    }
                } else {
                    k.both { s in
                        k.with(about(ax + s * 5, ay + 9, rot: -s * 0.35 + antA)) {
                            k.stroke(line(ax + s * 5, ay + 9, ax + s * 5, ay + 16), k.ink, k.thin)
                            k.flat(circ(ax + s * 5, ay + 16.5, 2.8), alien, w: k.thin)
                        }
                    }
                }
                k.part(rrect(ax - 10, ay - 22, 20, 16, 7), alien)
                let headP = ell(ax, ay, 14.5, 12.5)
                k.part(headP, alien, shadow: alien.dim(0.82), shape: ell(ax + 14, ay - 7, 8, 15))
                if v == 2 {
                    k.eye(ax + look * 1.2, ay + 2, 6, 7.6, side: 1, look: look)
                    k.mouth(ax + look * 1.5, ay - 6.8, 6)
                    k.blush(ax - 9, ay - 3.5, 2.8, 1.6)
                    k.blush(ax + 9, ay - 3.5, 2.8, 1.6)
                } else {
                    k.face(ax + look * 1.5, ay + 1.5, spread: 5.6, rx: 4.1, ry: 5.4)
                }
            }
            k.stroke(dome, k.ink, k.line)
            k.gloss(35, 66, 2.6, 6, -0.5)
            if v == 4 {
                balloonCord(k, line(50, 80, 50, 88), Tone(0x9a97b0), k.thin)
                k.flat(circ(50, 90, 3.6), f.frameIndex % 8 < 4 ? Tone(0xff4f5e) : Tone(0xffe14a), w: k.thin)
            }
            k.part(ell(50, 40, 45, 10), disc, shadow: k.shade(disc), shape: ell(50, 29, 52, 7))
            k.fill(ell(50, 43.5, 30, 3), Tone.white.alpha(0.35))
            let lit = (f.frameIndex / 4) % 4
            for (i, x) in ([24, 41, 59, 76] as [CGFloat]).enumerated() {
                var tone: Tone
                switch f.mood {
                case .sleepy: tone = disc.dim(0.7)
                case .startled: tone = f.frameIndex % 4 < 2 ? Tone(0xff4f5e) : Tone(0xffb0b8)
                case .fleeing: tone = Tone(0xfff36a)
                default: tone = i == lit ? Tone(0xfff36a) : disc.lift(0.55)
                }
                k.flat(circ(x, 37.5, 3.5), tone, w: k.thin)
            }
            k.marks(78, 78, 12)
        }
    }

    private static func cometTail(len: CGFloat, amp: CGFloat, flare: CGFloat, t: CGFloat) -> CGPath {
        let x0: CGFloat = 66
        let upTip: CGFloat = 64 + 6 * flare + amp * sin(2 * t + 1)
        let midTip: CGFloat = 50 + amp * sin(2 * t + 2.4)
        let lowTip: CGFloat = 36 - 6 * flare + amp * sin(2 * t + 3.8)
        let a: [CGFloat] = [
            x0, 68.5,
            x0 - 26 * len, 70 + 2 * flare,
            x0 - 54 * len, upTip,
            x0 - 40 * len, 56.5,
            x0 - 72 * len, midTip,
            x0 - 40 * len, 43.5,
            x0 - 54 * len, lowTip,
            x0 - 26 * len, 30 - 2 * flare,
            x0, 31.5,
        ]
        return smooth(a, t: flare > 0 ? 0.55 : 0.85)
    }

    private static func foxLeg(_ k: StickerKit, _ x: CGFloat, _ hip: CGFloat, _ foot: CGFloat, _ a: CGFloat, _ w: CGFloat, _ fur: Tone, _ sock: Tone) {
        k.with(about(x, hip, rot: a)) {
            let len = hip - foot
            let leg = rrect(x - w / 2, foot, w, len + w * 0.5, w / 2)
            k.fill(leg, fur)
            if sock != fur {
                k.clip(leg) { k.fill(rrect(x - w, foot - 1, w * 2, len * 0.42 + 1, 0), sock) }
            }
            k.stroke(leg, k.ink, k.line)
        }
    }

    private static func polarBearScarf(_ k: StickerKit, _ f: FigureFrame, _ x: CGFloat, _ y: CGFloat, _ tone: Tone, _ stripe: Tone) {
        let flap: CGFloat = f.mood == .fleeing ? 1.2 : 0.35 + 0.15 * f.swing * f.energy
        k.with(about(x - 1, y - 7, rot: flap)) {
            let tail = rrect(x - 5, y - 22, 8, 17, 3)
            k.fill(tail, tone)
            k.clip(tail) { k.fill(rrect(x - 6, y - 17, 10, 3, 0), stripe) }
            k.stroke(tail, k.ink, k.thin)
        }
        let band = ell(x, y, 6, 13.5, -0.45)
        k.fill(band, tone)
        k.clip(band) { k.fill(xf(rrect(x - 10, y - 1.6, 20, 3.2, 0), about(x, y, rot: -0.45)), stripe) }
        k.stroke(band, k.ink, k.thin)
    }

    private static func bunnyEar(_ k: StickerKit, _ x: CGFloat, _ y: CGFloat, _ len: CGFloat, _ rot: CGFloat, _ fur: Tone, _ sh: Tone, _ inner: Tone) {
        k.with(about(x, y, rot: rot)) {
            let ear = ell(x, y + len * 0.5, 6.8, len * 0.5)
            k.part(ear, fur, shadow: sh, shape: ell(x + 7.5, y + len * 0.4, 4, len * 0.55))
            k.fill(ell(x - 0.6, y + len * 0.56, 3, len * 0.34), inner)
        }
    }

    private static func balloonCord(_ k: StickerKit, _ p: CGPath, _ tone: Tone, _ w: CGFloat) {
        k.stroke(p, k.ink, w + k.line * 0.9)
        k.stroke(p, tone, w)
    }

    private static func balloonBow(_ k: StickerKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ tone: Tone, _ rot: CGFloat = 0) {
        k.with(about(x, y, rot: rot)) {
            k.part(smooth([x, y, x - 11 * s, y + 7 * s, x - 12 * s, y - 5 * s], t: 0.4), tone)
            k.part(smooth([x, y, x + 11 * s, y + 7 * s, x + 12 * s, y - 5 * s], t: 0.4), tone)
            k.flat(circ(x, y, 3.2 * s), tone.dim(0.85))
        }
    }

    private static func bunnyPartyHat(_ k: StickerKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ rot: CGFloat, _ cone: Tone, _ stripe: Tone) {
        k.with(about(x, y, rot: rot)) {
            let h: CGFloat = 21 * s, w: CGFloat = 10 * s
            let c = poly([x - w, y, x + w, y, x, y + h])
            k.fill(c, cone)
            k.clip(c) {
                for i in 0..<3 {
                    let yy: CGFloat = y + (3 + 6.5 * CGFloat(i)) * s
                    k.fill(rrect(x - w - 2, yy, 2 * w + 4, 3 * s, 0), stripe)
                }
            }
            k.stroke(c, k.ink, k.line)
            k.flat(circ(x, y + h, 3.4 * s), Tone(0xffd54a))
        }
    }

    private static func starCrown(_ k: StickerKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ rot: CGFloat) {
        k.with(about(x, y, rot: rot)) {
            let c = poly([x - 9 * s, y, x + 9 * s, y, x + 11 * s, y + 12 * s, x + 5 * s, y + 6 * s, x, y + 14 * s, x - 5 * s, y + 6 * s, x - 11 * s, y + 12 * s])
            k.part(c, Tone(0xffd23f), shadow: Tone(0xf0a020), shape: rrect(x - 12 * s, y - 2, 24 * s, 4 * s, 0))
            k.fill(circ(x, y + 5 * s, 2 * s), Tone(0xff4f8a))
        }
    }

    private static func starFlower(_ k: StickerKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ petal: Tone) {
        var ps: [CGPath] = []
        for i in 0..<5 {
            let a = CGFloat(i) * 2 * .pi / 5 + .pi / 2
            ps.append(circ(x + cos(a) * 4.6 * s, y + sin(a) * 4.6 * s, 3.6 * s))
        }
        k.flat(uni(ps), petal, w: k.thin)
        k.flat(circ(x, y, 2.8 * s), Tone(0xffd23f), w: k.thin)
    }
}
