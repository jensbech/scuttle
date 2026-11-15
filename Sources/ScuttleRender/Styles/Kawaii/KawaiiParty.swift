import Foundation
import CoreGraphics
import ScuttleCore

extension KawaiiArt {
    static func balloon(_ f: FigureFrame, _ k: KawaiiKit) {
        let bases = [Tone(0xffbdd0), Tone(0xbdf0dc), Tone(0xd9ccff), Tone(0xffe6a0), Tone(0xc4e1ff)]
        let base = f.pick(bases)
        let v = f.variant % 5
        let t = f.t
        var sx: CGFloat = 1 - 0.015 * f.swing2
        var sy: CGFloat = 1 + 0.02 * f.swing2
        var tilt: CGFloat = 0
        var sway: CGFloat = 3.5 * f.swing
        var trail: CGFloat = 0
        var faceX: CGFloat = 50, faceY: CGFloat = 52
        switch f.mood {
        case .calm:
            tilt = -0.05 * f.twitch
        case .sleepy:
            sx = 1.06
            sy = 0.86 + 0.01 * f.swing
            tilt = 0.12
            faceY = 50
            sway = 6 * f.swing
        case .startled:
            sx = 1.08
            sy = 1.1
            faceY = 53
            sway = 0.6 * f.swing2
        case .fleeing:
            trail = 15
            tilt = -0.14
            faceX = 53
            sway = 2.5 * sin(2 * t)
        case .dizzy:
            tilt = 0.13 * sin(t)
            sway = 4 * sin(t + 1)
        }
        if v == 2 { faceY += 5 }
        let a = sway
        let sp = smooth([50, 28, 50 - a * 0.6 - trail * 0.3, 20, 50 + a - trail * 0.65, 11, 50 - a * 0.4 - trail, 1], closed: false)
        k.stroke(sp, Tone(0xb9a5e2), k.width(1.4, minPt: 0.85))
        k.with(about(50, 29, rot: tilt, sx: sx, sy: sy)) {
            let knot = poly([46.5, 26.5, 53.5, 26.5, 50, 31.5])
            k.fill(knot, base.dim(0.9))
            k.stroke(knot, base.dim(0.9), 1.6)
            let body = v == 2 ? heart(50, 62, 30) : smooth([50, 90, 68, 85, 76, 68, 73, 50, 62, 37, 50, 31, 38, 37, 27, 50, 24, 68, 32, 85])
            k.body(body, base, depth: 0.32)
            kawaiiBalloonDecor(f, k, body)
            k.shine(37, 77, 6, 3.6)
            k.fill(circ(31, 70, 1.8), Tone.white.alpha(0.8))
            k.face(faceX, faceY, spread: 11, r: 2.7)
        }
        k.marks(76, 84, 13)
    }

    private static func kawaiiBalloonDecor(_ f: FigureFrame, _ k: KawaiiKit, _ body: CGPath) {
        switch f.variant % 5 {
        case 0:
            k.bow(50, 28.5, 4.4, Tone(0xff8fb3))
        case 1:
            k.clip(body) {
                let dot = Tone.white.alpha(0.6)
                k.fill(circ(63, 78, 4), dot)
                k.fill(circ(70, 60, 3.2), dot)
                k.fill(circ(50, 87, 2.6), dot)
                k.fill(circ(29, 56, 3), dot)
                k.fill(circ(59, 38, 2.4), dot)
            }
        case 3:
            kawaiiPartyHat(k, 53, 87, 7.5, -0.18, Tone(0xc9b4ff), Tone(0xfff3c4))
        case 4:
            k.fill(softStar(64, 73, 6.5, inner: 0.5), Tone.white.alpha(0.75))
        default:
            break
        }
    }

    static func star(_ f: FigureFrame, _ k: KawaiiKit) {
        let bases = [Tone(0xffe58c), Tone(0xffc8d9), Tone(0xc2f0d8), Tone(0xdccdff), Tone(0xffd3b4)]
        let base = f.pick(bases)
        let t = f.t
        var big: CGFloat = 36, inner: CGFloat = 0.56
        var armL: CGFloat = 0.06 * f.swing
        var armR: CGFloat = -0.06 * f.swing + 0.3 * max(0, f.twitch)
        var legL: CGFloat = 0.04 * f.sway
        var legR: CGFloat = 0.04 * f.sway
        var sx: CGFloat = 1, sy: CGFloat = 1
        var tilt: CGFloat = 0.05 * f.swing
        var faceX: CGFloat = 50, faceY: CGFloat = 46
        var twinkle: CGFloat = 1
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            armL = -0.22
            armR = -0.22
            legL = -0.05
            legR = -0.05
            sx = 1.05
            sy = 0.92
            tilt = 0.2 + 0.02 * f.swing
            inner = 0.6
            big = 34
            faceY = 45
            twinkle = 0.3
        case .startled:
            armL = 0.32 + 0.05 * f.swing2
            armR = 0.32 - 0.05 * f.swing2
            legL = 0.12
            legR = 0.12
            big = 38
            inner = 0.52
            sy = 1.04
            faceY = 47
            twinkle = 1.4
        case .fleeing:
            armL = -0.3 + 0.1 * f.swing
            armR = 0.35 + 0.1 * f.swing
            legL = 0.16 * sin(2 * t)
            legR = -0.16 * sin(2 * t)
            tilt = -0.14
            faceX = 53
        case .dizzy:
            tilt = 0.13 * sin(t)
            armL = 0.15 * sin(t)
            armR = -0.15 * sin(t)
        }
        let cx: CGFloat = 50, cy: CGFloat = 50
        let h = CGFloat.pi / 2
        let step = 2 * CGFloat.pi / 5
        let tipAngles: [CGFloat] = [h, h + step - armL, h + 2 * step + legL, h + 3 * step - legR, h + 4 * step + armR]
        var pts: [CGPoint] = []
        for i in 0..<5 {
            let a = tipAngles[i]
            pts.append(pt(cx + cos(a) * big, cy + sin(a) * big))
            let b = h + step * (CGFloat(i) + 0.5)
            pts.append(pt(cx + cos(b) * big * inner, cy + sin(b) * big * inner))
        }
        let body = smoothP(pts, t: 0.55)
        k.with(about(50, 40, rot: tilt, sx: sx, sy: sy)) {
            k.body(body, base, depth: 0.22)
            k.shine(40, 66, 4.6, 2.8)
            kawaiiStarDecor(f, k, big)
            k.face(faceX, faceY, spread: 9, r: 2.6)
        }
        let tw1 = max(0, sin(2 * t)) * twinkle
        let tw2 = max(0, sin(2 * t + 2.4)) * twinkle
        kawaiiPartyTwinkle(k, 86, 78, 6 * tw1, Tone(0xfff1b0))
        kawaiiPartyTwinkle(k, 14, 74, 4.5 * tw2, Tone(0xfff1b0))
        k.marks(78, 84, 12)
    }

    private static func kawaiiStarDecor(_ f: FigureFrame, _ k: KawaiiKit, _ big: CGFloat) {
        let top = 50 + big
        switch f.variant % 5 {
        case 1:
            k.bow(50, top - 9, 5, Tone(0xff8fb3))
        case 2:
            kawaiiPartyHat(k, 51, top - 7, 6, -0.12, Tone(0xffb3c9), Tone(0xfff3c4))
        case 3:
            k.flower(72, 60, 4.6, Tone(0xffb8d0))
        case 4:
            let c = Tone(0xffcf6b)
            let y0 = top - 9
            k.fill(poly([42, y0, 58, y0, 60, y0 + 9, 54.5, y0 + 4.5, 50, y0 + 11, 45.5, y0 + 4.5, 40, y0 + 9]), c)
            k.fill(circ(50, y0 + 11, 1.6), Tone(0xff9fbf))
        default:
            break
        }
    }

    static func sparkler(_ f: FigureFrame, _ k: KawaiiKit) {
        let bodies = [Tone(0xe4d8ff), Tone(0xc8f2df), Tone(0xffd0dd), Tone(0xcfe5ff), Tone(0xfff0b4)]
        let sparks = [Tone(0xffd25e), Tone(0xff8fb8), Tone(0xffb35c), Tone(0x8cc8ff), Tone(0xff9a7a)]
        let base = f.pick(bodies)
        let spark = f.pick(sparks)
        let e = f.energy
        let bob = 1.6 * f.bounce * min(1, e)
        var sx: CGFloat = 1, sy: CGFloat = 1, tilt: CGFloat = 0
        var reach: CGFloat = 5 * e
        var burst: CGFloat = 1
        var back: CGFloat = 0
        var armL = (x: CGFloat(34), y: CGFloat(33), r: CGFloat(-0.5))
        var armR = (x: CGFloat(66), y: CGFloat(33), r: CGFloat(0.5))
        var faceX: CGFloat = 52, faceY: CGFloat = 31
        switch f.mood {
        case .calm:
            armR = (67 + 2 * max(0, f.twitch), 35 + 13 * max(0, f.twitch), 0.5 + 1.9 * max(0, f.twitch))
        case .sleepy:
            sx = 1.05
            sy = 0.92
            burst = 0.35
            armL = (36, 26, -0.15)
            armR = (64, 26, 0.15)
            faceY = 29
            reach = 2
        case .startled:
            sx = 0.95
            sy = 1.07
            burst = 1.35
            armL = (31, 50, -2.4)
            armR = (69, 50, 2.4)
            faceY = 33
        case .fleeing:
            back = 1
            armL = (31, 38 + 4 * f.swing, -1.2 - 0.4 * f.swing)
            armR = (68, 36 - 4 * f.swing, 1.0 + 0.4 * f.swing)
            faceX = 55
        case .dizzy:
            tilt = 0.12 * sin(f.t)
            armL = (33, 36 + 3 * f.swing, -0.9)
            armR = (67, 36 - 3 * f.swing, 0.9)
        }
        let s = reach * f.swing
        let liftA = max(0, f.sway) * 2.2 * min(1, e)
        let liftB = max(0, -f.sway) * 2.2 * min(1, e)
        k.with(about(50, 4, rot: tilt)) {
            if f.mood != .sleepy {
                k.nub(42 + s, 6.5 + liftA, 6.5, 4, k.shade(base))
                k.nub(58 - s, 6.5 + liftB, 6.5, 4, k.shade(base))
            } else {
                k.nub(41, 6.5, 6.5, 4, k.shade(base))
                k.nub(59, 6.5, 6.5, 4, k.shade(base))
            }
            k.with(about(50, 6, sx: sx, sy: sy)) {
                k.with(CGAffineTransform(translationX: 0, y: bob)) {
                    k.nub(armL.x, armL.y, 4.5, 7, base, armL.r)
                    k.nub(armR.x, armR.y, 4.5, 7, base, armR.r)
                    let body = rrect(35, 7, 30, 56, 15)
                    k.body(body, base, depth: 0.25)
                    kawaiiSparklerDecor(f, k, body)
                    k.shine(41, 54, 3.6, 2.4)
                    k.face(faceX, faceY, spread: 7.5, r: 2.5)
                    kawaiiSparklerBurst(f, k, 50, 72, burst, back, spark)
                }
            }
        }
        k.marks(74, 82, 12)
    }

    private static func kawaiiSparklerBurst(_ f: FigureFrame, _ k: KawaiiKit, _ cx: CGFloat, _ cy: CGFloat, _ size: CGFloat, _ back: CGFloat, _ spark: Tone) {
        k.glow(cx, cy, 20 * size + 4, spark, 0.55)
        var rng = Noise(f.frameIndex * 97 + f.variant * 13 + 5)
        let n = size < 0.5 ? 4 : (size > 1.2 ? 12 : 9)
        let lw = k.width(1.7, minPt: 0.8)
        for i in 0..<n {
            var a = CGFloat(i) / CGFloat(n) * 2 * .pi + rng.range(-0.25, 0.25)
            var len = (13 + rng.range(-3, 5)) * size
            if back > 0 {
                let dx = cos(a) - 1.1 * back, dy = sin(a)
                a = atan2(dy, dx)
                len *= 1 + 0.4 * max(0, -cos(a))
            }
            let x0 = cx + cos(a) * 5, y0 = cy + sin(a) * 5
            let x1 = cx + cos(a) * len, y1 = cy + sin(a) * len
            k.stroke(line(x0, y0, x1, y1), spark.lift(0.25), lw)
            if i % 2 == 0 {
                kawaiiPartyTwinkle(k, x1, y1, 3.6 * size + 1.2, spark.lift(0.45))
            } else {
                k.fill(circ(x1, y1, 1.6 * size + 0.6), spark.lift(0.35))
            }
        }
        k.fill(circ(cx, cy, 6 * min(1.2, size) + 1), spark.lift(0.5))
        k.fill(circ(cx, cy, 3.6 * min(1.2, size) + 0.6), Tone(0xfffdf2))
    }

    private static func kawaiiSparklerDecor(_ f: FigureFrame, _ k: KawaiiKit, _ body: CGPath) {
        switch f.variant % 5 {
        case 1:
            k.bow(61, 56, 4.4, Tone(0xff9fbf), -0.4)
        case 2:
            k.clip(body) {
                for i in 0..<4 {
                    let y = 40 + CGFloat(i) * 9
                    k.stroke(line(30, y, 70, y + 10), Tone.white.alpha(0.6), 3.6)
                }
            }
        case 3:
            k.fill(softStar(58, 47, 4.8, inner: 0.5), Tone(0xffe08a))
        case 4:
            let scarf = Tone(0xff9fbf)
            k.clip(body) { k.fill(rrect(30, 41, 40, 6.5, 3), scarf) }
            k.nub(39, 37, 2.8, 6, scarf, -0.3)
        default:
            break
        }
    }

    static func rocket(_ f: FigureFrame, _ k: KawaiiKit) {
        let bodies = [Tone(0xf6f2ff), Tone(0xc9f2e0), Tone(0xdfd2ff), Tone(0xffdcc8), Tone(0xcfe6ff)]
        let noses = [Tone(0xffb3c8), Tone(0xcfb8ff), Tone(0xffc59e), Tone(0x9fe3c6), Tone(0xffd98a)]
        let finTones = [Tone(0xb6ead2), Tone(0xffbfd3), Tone(0xa9d6ff), Tone(0xcdb8ff), Tone(0xffb7cc)]
        let base = f.pick(bodies), nose = f.pick(noses), fin = f.pick(finTones)
        let t = f.t
        let flick: CGFloat = f.frameIndex % 2 == 0 ? 1 : -1
        var flame: CGFloat = 18 + 3 * sin(2 * t) + 1.5 * flick
        var flameW: CGFloat = 8
        var sx: CGFloat = 1, sy: CGFloat = 1, tilt: CGFloat = 0.03 * f.swing
        var faceX: CGFloat = 56, faceY: CGFloat = 47
        switch f.mood {
        case .calm:
            tilt += 0.04 * f.twitch
        case .sleepy:
            flame = 6 + 1.5 * sin(t)
            flameW = 5
            tilt = -0.1
            sx = 0.98
            sy = 0.96
        case .startled:
            flame = 24 + 3 * flick
            flameW = 10
            sx = 0.94
            sy = 1.08
            tilt = 0.1
        case .fleeing:
            flame = 34 + 4 * flick + 3 * sin(2 * t)
            flameW = 9
            sx = 1.06
            sy = 0.95
            faceX = 59
        case .dizzy:
            tilt = 0.13 * sin(t)
            flame = 12 + 6 * abs(sin(2 * t))
        }
        k.with(about(50, 50, rot: tilt, sx: sx, sy: sy)) {
            let wig: CGFloat = 1.5 * sin(3 * t)
            let outer = smooth([22, 50 + flameW, 12, 50 + flameW * 0.8, 20 - flame, 50 + wig, 12, 50 - flameW * 0.8, 22, 50 - flameW])
            k.fill(outer, Tone(0xffc48a))
            let inner = smooth([22, 50 + flameW * 0.55, 15, 50 + flameW * 0.45, 22 - flame * 0.62, 50 + wig * 0.6, 15, 50 - flameW * 0.45, 22, 50 - flameW * 0.55])
            k.fill(inner, Tone(0xfff1a8))
            let finPath = smooth([34, 60, 24, 75, 14, 77, 15, 64, 22, 56])
            k.fill(finPath, fin)
            k.with(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 100)) { k.fill(finPath, fin.dim(0.96)) }
            let body = smooth([89, 50, 81, 61, 63, 67, 40, 66, 24, 60, 19, 50, 24, 40, 40, 34, 63, 33, 81, 39])
            k.body(body, base, shade: k.shade(base), depth: 0.3)
            k.clip(body) { k.fill(ell(96, 50, 24, 26), nose) }
            kawaiiRocketDecor(f, k, body, nose, fin)
            k.shine(52, 61, 6, 2.2, 0.1)
            k.face(faceX, faceY, spread: 8, r: 2.5)
        }
        k.marks(74, 72, 12)
    }

    private static func kawaiiRocketDecor(_ f: FigureFrame, _ k: KawaiiKit, _ body: CGPath, _ nose: Tone, _ fin: Tone) {
        switch f.variant % 5 {
        case 1:
            k.clip(body) {
                k.fill(circ(30, 56, 2.6), nose)
                k.fill(circ(36, 44, 2.4), nose)
                k.fill(circ(27, 44, 1.8), nose)
            }
        case 2:
            k.clip(body) { k.fill(rrect(30, 20, 6, 60, 0), nose) }
        case 3:
            k.fill(heart(32, 50, 5.5), nose)
        case 4:
            k.fill(softStar(32, 50, 6.5, inner: 0.5), nose)
        default:
            break
        }
    }

    static func bunny(_ f: FigureFrame, _ k: KawaiiKit) {
        let bodies = [Tone(0xfdfaff), Tone(0xf4dfcb), Tone(0xe6e2f6), Tone(0xffdbe7), Tone(0xfff3da)]
        let base = f.pick(bodies)
        let v = f.variant % 5
        let lop = v == 4
        let innerEar = Tone(0xffbfd2)
        var sy: CGFloat = 1 - 0.16 * f.squat + 0.1 * f.stretch
        var sx: CGFloat = 1 + 0.1 * f.squat - 0.05 * f.stretch
        var tilt: CGFloat = 0
        var earB: CGFloat = 0.28 + 0.3 * f.stretch - 0.12 * f.squat
        var earF: CGFloat = -0.06 + 0.3 * f.stretch - 0.12 * f.squat
        var earLen: CGFloat = 1
        var faceX: CGFloat = 57, faceY: CGFloat = 30
        var paws = false
        switch f.mood {
        case .calm:
            earF -= 0.28 * f.twitch
        case .sleepy:
            sx *= 1.05
            sy *= 0.9
            earB = 1.25
            earF = -1.1
            faceY = 29
        case .startled:
            sx *= 0.95
            sy *= 1.06
            earB = 0.04
            earF = -0.04
            earLen = 1.15
            paws = true
            faceY = 32
        case .fleeing:
            earB = 0.95 + 0.08 * f.swing
            earF = 0.75 + 0.08 * f.swing
            faceX = 60
        case .dizzy:
            tilt = 0.12 * sin(f.t)
            earB = 0.4 + 0.3 * sin(f.t)
            earF = -0.7
        }
        if lop {
            earLen *= 0.82
            if f.mood == .startled {
                earB = 1.5
                earF = -1.5
            } else if f.mood == .fleeing {
                earB = 1.9
                earF = 2.4
            } else {
                earB = 2.5 + 0.15 * f.stretch
                earF = -2.5 - 0.15 * f.stretch + 0.15 * f.twitch
            }
        }
        k.with(about(50, 4, rot: tilt, sx: sx, sy: sy)) {
            let dangle: CGFloat = f.airborne ? 2.5 * sin(f.air * .pi) : 0
            k.nub(38 - dangle, 7 - dangle * 0.4, 8, 4.4, k.shade(base))
            k.nub(23, 24, 7.5, 7.5, base.mix(.white, 0.5))
            if !lop {
                kawaiiBunnyEar(k, 42, 52, earB, earLen, base.dim(0.97), innerEar)
            }
            if paws {
                k.nub(25, 40, 5, 5.5, base)
                k.nub(77, 42, 5, 5.5, base)
            }
            let body = ell(50, 32, 27, 26)
            k.body(body, base, depth: 0.3)
            if !lop {
                kawaiiBunnyEar(k, 58, 54, earF, earLen, base, innerEar)
            } else {
                let lopTone = base.mix(Tone(0xf3c8a8), 0.35)
                kawaiiBunnyEar(k, 39, 55, earB, earLen, lopTone, innerEar)
                kawaiiBunnyEar(k, 61, 56, earF, earLen, lopTone, innerEar)
            }
            k.nub(62 + dangle, 7 - dangle * 0.4, 8, 4.4, k.shade(base))
            k.shine(36, 47, 5, 3)
            kawaiiBunnyDecor(f, k)
            k.face(faceX, faceY, spread: 10, r: 2.7)
            k.fill(ell(faceX, faceY + 0.6, 1.5, 1.1), Tone(0xff9fb8))
        }
        k.marks(76, 76, 13)
    }

    private static func kawaiiBunnyEar(_ k: KawaiiKit, _ px: CGFloat, _ py: CGFloat, _ rot: CGFloat, _ len: CGFloat, _ tone: Tone, _ inner: Tone) {
        k.with(about(px, py, rot: rot)) {
            k.fill(ell(px, py + 15 * len, 7.5, 17 * len), tone)
            k.fill(ell(px, py + 16 * len, 3.8, 12 * len), inner)
        }
    }

    private static func kawaiiBunnyDecor(_ f: FigureFrame, _ k: KawaiiKit) {
        switch f.variant % 5 {
        case 0:
            k.bow(50, 57, 4.6, Tone(0xff9fbf))
        case 1:
            k.flower(67, 53, 4.6, Tone(0xffb8d0))
        case 2:
            let carrot = Tone(0xffb27a)
            k.fill(ell(73, 33, 3, 3.6, 0.6), Tone(0x9fdcae))
            k.fill(ell(69, 35, 2.6, 3.4, -0.3), Tone(0x9fdcae))
            k.fill(poly([66, 31, 75, 28, 66, 12]), carrot)
            k.stroke(poly([66, 31, 75, 28, 66, 12]), carrot, 2.6)
            k.nub(66, 24, 4.4, 3.6, f.pick([Tone(0xfdfaff), Tone(0xf4dfcb), Tone(0xe6e2f6), Tone(0xffdbe7), Tone(0xfff3da)]))
        case 3:
            kawaiiPartyHat(k, 50, 56, 6.5, 0.1, Tone(0xbfe9ff), Tone(0xffd0e0))
        default:
            k.clip(ell(50, 32, 27, 26)) { k.fill(rrect(20, 14, 60, 6, 3), Tone(0xa9e5cc)) }
        }
    }

    static func turtle(_ f: FigureFrame, _ k: KawaiiKit) {
        let shells = [Tone(0xbfe9c9), Tone(0xffd2b8), Tone(0xdacdff), Tone(0xc6e3ff), Tone(0xffe7a8)]
        let shell = f.pick(shells)
        let skin = Tone(0xe6f4d2)
        let e = f.energy
        let t = f.t
        var hx: CGFloat = 85, hy: CGFloat = 30 + 1.2 * f.twitch
        var legOut: CGFloat = 0, legAmp: CGFloat = 3 * e
        var lift: CGFloat = 0, tilt: CGFloat = 0.025 * f.swing
        var tucked = false
        var faceDX: CGFloat = 3
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            hx = 79
            hy = 20
            tucked = true
            legAmp = 0
            lift = -4
        case .startled:
            hx = 89
            hy = 43
            legOut = 5
            lift = 3
            legAmp = 1
        case .fleeing:
            hx = 91
            hy = 29
            legAmp = 6
            faceDX = 5
        case .dizzy:
            tilt = 0.12 * sin(t)
        }
        k.with(about(46, 6, rot: tilt)) {
            k.with(CGAffineTransform(translationX: 0, y: lift)) {
                let legX: [CGFloat] = [18 - legOut, 28 - legOut * 0.5, 52 + legOut * 0.5, 62 + legOut]
                for i in 0..<4 where !tucked {
                    let ph = t * (f.mood == .fleeing ? 2 : 1) + CGFloat(i) * .pi / 2 + (i % 2 == 0 ? 0 : .pi)
                    let dx = legAmp * sin(ph)
                    let dy = max(0, cos(ph)) * 2 * min(1, e)
                    let far = i == 0 || i == 2
                    k.fill(rrect(legX[i] + dx - 6, 3 + dy - lift * 0.6, 12, 14, 6), far ? k.shade(skin) : skin)
                }
                if tucked {
                    k.nub(22, 11, 5, 3, k.shade(skin))
                    k.nub(58, 11, 5, 3, k.shade(skin))
                }
                k.nub(5, 17, 5.5, 3.2, skin, 0.4 + 0.2 * f.swing)
                k.nub((hx + 60) / 2, (hy + 18) / 2, 9, 7.5, skin, 0.4)
                if !tucked {
                    k.body(circ(hx, hy, 16), skin, depth: 0.25)
                }
                let p = CGMutablePath()
                p.move(to: pt(6, 18))
                p.addCurve(to: pt(40, 58), control1: pt(6, 45), control2: pt(20, 58))
                p.addCurve(to: pt(74, 18), control1: pt(60, 58), control2: pt(74, 45))
                p.closeSubpath()
                k.body(p, shell, depth: 0.22)
                kawaiiTurtleSpots(f, k, p, shell)
                k.fill(rrect(3, 13, 74, 8.5, 4.25), shell.mix(.white, 0.5))
                k.shine(24, 46, 5.5, 3)
                if tucked {
                    k.body(ell(hx, hy, 13, 11.5), skin, depth: 0.25)
                }
                let fx = hx + faceDX - 2, fy = hy - 1
                k.face(fx, fy, spread: 5.5, r: 2.5)
                kawaiiTurtleDecor(f, k, hx, hy)
            }
        }
        k.marks(hx + 4, hy + 22, 12)
    }

    private static func kawaiiTurtleSpots(_ f: FigureFrame, _ k: KawaiiKit, _ p: CGPath, _ shell: Tone) {
        let spot = shell.mix(.white, 0.38)
        k.clip(p) {
            if f.variant % 5 == 4 {
                k.fill(heart(40, 35, 7.5), spot)
                k.fill(heart(20, 26, 5), spot)
                k.fill(heart(60, 26, 5), spot)
            } else {
                k.fill(ell(40, 35, 9, 8), spot)
                k.fill(ell(19, 26, 6, 6.5), spot)
                k.fill(ell(61, 26, 6, 6.5), spot)
                k.fill(ell(28, 49, 4.5, 3.5), spot)
                k.fill(ell(52, 49, 4.5, 3.5), spot)
            }
        }
    }

    private static func kawaiiTurtleDecor(_ f: FigureFrame, _ k: KawaiiKit, _ hx: CGFloat, _ hy: CGFloat) {
        switch f.variant % 5 {
        case 1:
            k.flower(40, 57, 5.4, Tone(0xfffaf4), Tone(0xff9fbf))
        case 2:
            k.bow(hx - 3, hy + 12.5, 4.4, Tone(0xff9fbf), 0.2)
        case 3:
            kawaiiPartyHat(k, hx - 1, hy + 12, 6, -0.2, Tone(0xffb3c9), Tone(0xfff3c4))
        default:
            break
        }
    }

    static func fox(_ f: FigureFrame, _ k: KawaiiKit) {
        let furs = [Tone(0xffb487), Tone(0xf3f1fb), Tone(0xffc4cf), Tone(0xffdc9e), Tone(0xf0c9ae)]
        let fur = f.pick(furs)
        let v = f.variant % 5
        let cream = Tone(0xfff7ee)
        let tipTone = v == 1 ? Tone(0xd9d0f5) : cream
        let sock = fur.mix(Tone(0x9d6f8a), 0.28)
        let e = f.energy
        let t = f.t
        var tailRot: CGFloat = 0.06 * f.swing - 0.18 * f.twitch
        var tailScale: CGFloat = 1
        var earL: CGFloat = 0, earR: CGFloat = 0
        var bodySY: CGFloat = 1, headDY: CGFloat = 1.2 * f.bounce, headDX: CGFloat = 0
        var reach: CGFloat = 5 * e
        var legsShown = true
        var tilt: CGFloat = 0
        var faceDX: CGFloat = 0
        switch f.mood {
        case .calm:
            earR = -0.15 * f.twitch
        case .sleepy:
            tailRot = 0.95
            earL = 0.35
            earR = -0.35
            bodySY = 0.8
            headDY = -8
            legsShown = false
        case .startled:
            tailRot = -0.4
            tailScale = 1.12
            headDY = 3
            earL = -0.08
            earR = 0.08
            reach = 1
        case .fleeing:
            tailRot = 1.05 + 0.08 * sin(2 * t)
            earL = 0.45
            earR = 0.45
            headDX = 2
            faceDX = 2
        case .dizzy:
            tilt = 0.12 * sin(t)
            earL = 0.2 * sin(t)
            earR = -0.25
        }
        let s = reach * f.swing
        let la = max(0, f.sway) * 2 * min(1, e)
        let lb = max(0, -f.sway) * 2 * min(1, e)
        k.with(about(50, 4, rot: tilt)) {
            if legsShown {
                k.fill(rrect(31.5 - s, 4 + lb, 9, 15, 4.5), sock.dim(0.94))
                k.fill(rrect(53.5 - s, 4 + lb, 9, 15, 4.5), sock.dim(0.94))
            }
            k.with(about(30, 22 * bodySY, rot: tailRot, sx: tailScale, sy: tailScale)) {
                let tail = ell(20, 42 * bodySY + 4 * (1 - bodySY), 11.5, 21, 0.42)
                k.body(tail, fur, depth: 0.25)
                k.clip(tail) { k.fill(circ(10, 64, 10), tipTone) }
            }
            if legsShown {
                k.fill(rrect(37.5 + s, 4 + la, 9, 15, 4.5), sock)
                k.fill(rrect(59.5 + s, 4 + la, 9, 15, 4.5), sock)
            }
            k.with(about(50, 4, sx: 1, sy: bodySY)) {
                let body = ell(48, 25, 21, 17)
                k.body(body, fur, depth: 0.25)
                k.clip(body) { k.fill(ell(63, 30, 9, 12), cream) }
            }
            let hy: CGFloat = 55 + headDY, hx: CGFloat = 60 + headDX
            kawaiiFoxEar(k, hx - 14, hy + 15, earL, fur, -1)
            kawaiiFoxEar(k, hx + 13, hy + 15, earR, fur, 1)
            let head = ell(hx, hy, 24, 20.5)
            k.body(head, fur, depth: 0.2)
            k.clip(head) {
                k.fill(uni([ell(hx - 9, hy - 12, 14, 10), ell(hx + 11, hy - 12, 14, 10)]), cream)
            }
            k.shine(hx - 13, hy + 10, 4.6, 2.8)
            let fx = hx + 3 + faceDX, fy = hy - 1
            k.face(fx, fy, spread: 9.5, r: 2.7, mouth: .none)
            k.fill(ell(fx, fy - 4.4, 2.5, 1.8), Tone(0x6a4458))
            k.mouth(fx, fy - 7.2, 4.6, kind: .cat)
            kawaiiFoxDecor(f, k, hx, hy)
            k.marks(hx + 22, hy + 22, 13)
        }
    }

    private static func kawaiiFoxEar(_ k: KawaiiKit, _ x: CGFloat, _ y: CGFloat, _ rot: CGFloat, _ fur: Tone, _ side: CGFloat) {
        k.with(about(x, y - 4, rot: rot)) {
            let outer = poly([x - 8, y - 4, x + 8, y - 4, x + side * 2, y + 17])
            k.fill(outer, fur)
            k.stroke(outer, fur, 5)
            let inner = poly([x - 3.6, y - 1, x + 3.6, y - 1, x + side * 1.2, y + 10.5])
            k.fill(inner, Tone(0xffd9df))
            k.stroke(inner, Tone(0xffd9df), 2.2)
        }
    }

    private static func kawaiiFoxDecor(_ f: FigureFrame, _ k: KawaiiKit, _ hx: CGFloat, _ hy: CGFloat) {
        switch f.variant % 5 {
        case 1:
            let scarf = Tone(0x9fe0c8)
            k.fill(rrect(hx - 22, hy - 25, 34, 7, 3.5), scarf)
            k.nub(hx - 18, hy - 30, 3, 6, scarf, 0.4)
        case 2:
            k.flower(hx + 17, hy + 14, 5, Tone(0xffeaf0), Tone(0xffb3c9))
        case 3:
            k.bow(hx - 15, hy + 17, 4.8, Tone(0xc9b4ff), 0.3)
        case 4:
            kawaiiPartyHat(k, hx - 1, hy + 18, 6.5, -0.05, Tone(0xbfe9ff), Tone(0xffd0e0))
        default:
            break
        }
    }

    static func polarBear(_ f: FigureFrame, _ k: KawaiiKit) {
        let furs = [Tone(0xf7f8ff), Tone(0xf5f7ff), Tone(0xfbf8ff), Tone(0xfff2f5), Tone(0xf6f9ff)]
        let fur = f.pick(furs)
        let far = k.shade(fur)
        let e = f.energy
        let t = f.t
        var reach: CGFloat = 5 * e
        var rear: CGFloat = 0
        var lie = false
        var headDY: CGFloat = 1 * f.bounce, headDX: CGFloat = 0
        var earBack: CGFloat = 0
        var tilt: CGFloat = 0
        var faceDX: CGFloat = 0
        switch f.mood {
        case .calm:
            headDY += 1 * f.twitch
        case .sleepy:
            lie = true
            headDY = -14
            headDX = 2
        case .startled:
            rear = 0.2
            headDY = 3
            reach = 1.5
        case .fleeing:
            reach = 8
            earBack = 3
            faceDX = 2
            headDX = 2
        case .dizzy:
            tilt = 0.1 * sin(t)
        }
        let s = reach * f.swing
        let la = max(0, f.sway) * 2.4 * min(1, e)
        let lb = max(0, -f.sway) * 2.4 * min(1, e)
        k.with(about(50, 4, rot: tilt)) {
            k.with(about(24, 5, rot: rear)) {
                if lie {
                    k.nub(28, 8, 7, 4, far)
                    k.nub(70, 8, 7, 4, far)
                } else {
                    k.fill(rrect(22 - s, 4 + lb, 13, 20, 6.5), far)
                    k.fill(rrect(56 + s, 4 + la, 13, 20, 6.5), far)
                }
                k.nub(16, 36 - (lie ? 12 : 0), 4.6, 4.6, fur)
                let body = lie ? ell(46, 20, 33, 16) : ell(46, 31, 31, 21)
                k.body(body, fur, depth: 0.3)
                if lie {
                    k.nub(40, 7, 8, 4, fur)
                    k.nub(80, 8, 8, 4.2, fur)
                } else {
                    k.body(rrect(32 + s, 4 + la, 13, 20, 6.5), fur, depth: 0.3)
                    k.body(rrect(66 - s + rear * 20, 4 + lb + rear * 18, 13, 20, 6.5), fur, depth: 0.3)
                }
                let hx: CGFloat = 74 + headDX, hy: CGFloat = 47 + headDY
                k.nub(hx - 11 - earBack, hy + 14 - earBack * 0.4, 6.5, 6.5, fur)
                k.nub(hx + 7 - earBack, hy + 15.5 - earBack * 0.4, 6.5, 6.5, fur)
                k.fill(circ(hx - 11 - earBack, hy + 14 - earBack * 0.4, 3.2), Tone(0xffd6e0))
                k.fill(circ(hx + 7 - earBack, hy + 15.5 - earBack * 0.4, 3.2), Tone(0xffd6e0))
                let head = circ(hx, hy, 18)
                k.body(head, fur, depth: 0.22)
                k.shine(hx - 9, hy + 8, 4.4, 2.6)
                k.fill(ell(hx + 11, hy - 8, 8.5, 6.5), Tone(0xfff6ea))
                k.face(hx + faceDX, hy, spread: 6.5, r: 2.5, mouth: .none)
                k.fill(ell(hx + 16, hy - 5, 3.2, 2.4), Tone(0x6a4458))
                k.mouth(hx + 14, hy - 10, 4.4, kind: .cat)
                kawaiiPolarBearDecor(f, k, hx, hy)
                k.marks(hx + 14, hy + 24, 13)
            }
        }
    }

    private static func kawaiiPolarBearDecor(_ f: FigureFrame, _ k: KawaiiKit, _ hx: CGFloat, _ hy: CGFloat) {
        switch f.variant % 5 {
        case 0:
            let scarf = Tone(0xff9fbf)
            k.nub(hx - 15, hy - 17 + f.swing, 3.4, 7.5, scarf, 0.3 + 0.12 * f.swing)
            var band: [CGFloat] = []
            for i in 0...6 {
                let a = CGFloat.pi * (1.05 + 0.085 * CGFloat(i))
                band += [hx + cos(a) * 16.5, hy + sin(a) * 16.5]
            }
            k.stroke(smooth(band, closed: false), scarf, 7)
            k.fill(circ(hx - 12, hy - 12, 4.2), scarf.dim(0.95))
        case 1:
            let hat = Tone(0x9fc8ff)
            k.clip(rrect(hx - 30, hy + 9, 60, 30, 0)) { k.fill(ell(hx - 1, hy + 9, 16, 12), hat) }
            k.fill(rrect(hx - 17, hy + 6.5, 32, 6, 3), Tone(0xd2e6ff))
            k.fill(circ(hx - 1, hy + 22, 4.2), Tone(0xd2e6ff))
        case 2:
            let muff = Tone(0x9fe0c8)
            k.stroke(arc(hx - 11, hy + 15, hx + 7, hy + 16.5, dip: -9), muff.dim(0.92), 2.4)
            k.fill(circ(hx - 11, hy + 14, 6.4), muff)
            k.fill(circ(hx + 7, hy + 15.5, 6.4), muff)
        case 3:
            k.bow(hx + 8, hy + 19, 4.6, Tone(0xffa8c4), -0.3)
        default:
            kawaiiPartyHat(k, hx - 2, hy + 16, 6.5, -0.12, Tone(0xffd98a), Tone(0xffb3c9))
        }
    }

    static func comet(_ f: FigureFrame, _ k: KawaiiKit) {
        let heads = [Tone(0xffe58c), Tone(0xffc8d9), Tone(0xc2f0d8), Tone(0xdccdff), Tone(0xfdfbff)]
        let outerTones = [Tone(0xffc2d6), Tone(0xc2f0d8), Tone(0xc4e2ff), Tone(0xffd3b4), Tone(0xd8c8ff)]
        let innerTones = [Tone(0xd8c8ff), Tone(0xfff2b0), Tone(0xd8c8ff), Tone(0xffc2d6), Tone(0xc2f0d8)]
        let head = f.pick(heads), outer = f.pick(outerTones), mid = f.pick(innerTones)
        let t = f.t
        let v = f.variant % 5
        var len: CGFloat = 1, droop: CGFloat = 0, fluff: CGFloat = 1, r: CGFloat = 17
        var tilt: CGFloat = 0, wave: CGFloat = 5
        var faceDX: CGFloat = 3
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            len = 0.62
            droop = -9
            wave = 2
        case .startled:
            fluff = 1.25
            len = 0.85
            r = 18.5
        case .fleeing:
            len = 1.3
            fluff = 0.85
            faceDX = 5
        case .dizzy:
            tilt = 0.12 * sin(t)
            wave = 9
        }
        let hx: CGFloat = 66, hy: CGFloat = 50
        k.with(about(hx, hy, rot: tilt)) {
            k.glow(hx, hy, r + 14, head, 0.45)
            let w1 = sin(t) * wave + droop, w2 = sin(t + 1.3) * wave * 0.8 + droop * 0.8, w3 = sin(t + 2.4) * wave * 0.5 + droop * 0.6
            if v == 4 {
                let bands = [Tone(0xffc2d6), Tone(0xffe3a8), Tone(0xc2f0d8), Tone(0xc4e2ff), Tone(0xd8c8ff)]
                for (i, c) in bands.enumerated() {
                    let off = (CGFloat(i) - 2) * 6.2 * fluff
                    let ll: CGFloat = (62 - abs(CGFloat(i) - 2) * 6) * len
                    let ww = sin(t + CGFloat(i) * 0.5) * wave + droop
                    k.fill(kawaiiCometStreak(hx, hy + off, 4.2 * fluff, ll, ww), c)
                }
            } else {
                k.fill(kawaiiCometStreak(hx, hy, 17 * fluff, 62 * len, w1), outer)
                k.fill(kawaiiCometStreak(hx, hy + 1, 11 * fluff, 48 * len, w2), mid)
                k.fill(kawaiiCometStreak(hx, hy + 1.5, 5.5 * fluff, 32 * len, w3), Tone(0xfffbf0, 0.9))
            }
            for i in 0..<3 {
                let ph = CGFloat((f.frameIndex + i * 5) % 16) / 16
                let tx: CGFloat = hx - 22 - CGFloat(i) * 13 * len
                let ty: CGFloat = hy + (i == 1 ? -9 : 8) + droop * (0.3 + 0.2 * CGFloat(i))
                kawaiiPartyTwinkle(k, tx, ty, 3.8 * sin(ph * .pi) + 0.4, Tone(0xfffbe8))
            }
            let ball = circ(hx, hy, r)
            k.body(ball, head, depth: 0.28)
            k.shine(hx - 7, hy + 8, 4.8, 3)
            kawaiiCometDecor(f, k, hx, hy, r)
            k.face(hx + faceDX, hy - 2, spread: 7, r: 2.6)
        }
        k.marks(hx + 14, hy + 20, 12)
    }

    private static func kawaiiCometStreak(_ hx: CGFloat, _ cy: CGFloat, _ hw: CGFloat, _ len: CGFloat, _ tipY: CGFloat) -> CGPath {
        smooth([hx, cy + hw, hx - len * 0.45, cy + hw * 0.78 + tipY * 0.35, hx - len, cy + tipY, hx - len * 0.45, cy - hw * 0.78 + tipY * 0.35, hx, cy - hw], t: 0.9)
    }

    private static func kawaiiCometDecor(_ f: FigureFrame, _ k: KawaiiKit, _ hx: CGFloat, _ hy: CGFloat, _ r: CGFloat) {
        switch f.variant % 5 {
        case 1:
            k.bow(hx - 2, hy + r - 1.5, 4.6, Tone(0xff8fb3), -0.15)
        case 2:
            k.flower(hx - 9, hy + r - 3, 4.4, Tone(0xffeaf0), Tone(0xffb3c9))
        case 3:
            kawaiiPartyHat(k, hx + 1, hy + r - 3, 6, -0.25, Tone(0xffb3c9), Tone(0xfff3c4))
        default:
            break
        }
    }

    static func ufo(_ f: FigureFrame, _ k: KawaiiKit) {
        let aliens = [Tone(0xc6f2c8), Tone(0xffcadb), Tone(0xdccdff), Tone(0xc4e2ff), Tone(0xffe7a0)]
        let saucers = [Tone(0xdcd6f2), Tone(0xc6eedf), Tone(0xffd6c2), Tone(0xffc9da), Tone(0xcfe4ff)]
        let alien = f.pick(aliens), saucer = f.pick(saucers)
        let ar: CGFloat = 14.5
        let t = f.t
        var tilt: CGFloat = 0.03 * sin(2 * t)
        var ay: CGFloat = 0.8 * f.swing2
        var lit: Int = 1
        var antenna: CGFloat = 1
        var faceDX: CGFloat = 1.5
        var sy: CGFloat = 1
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            tilt = -0.06
            ay = -3
            lit = 0
            antenna = 0.6
            faceDX = 0
        case .startled:
            ay = 4
            lit = 3
            antenna = 1.3
            sy = 1.04
        case .fleeing:
            tilt = -0.15
            faceDX = 4
            lit = 2
        case .dizzy:
            tilt = 0.14 * sin(t)
            lit = 2
        }
        k.with(about(50, 38, rot: tilt, sx: 1, sy: sy)) {
            k.glow(50, 27, 16, Tone(0xfff1b0), lit == 0 ? 0.2 : 0.55)
            k.fill(ell(50, 30, 15, 6.5), k.shade(saucer))
            let ax: CGFloat = 50, aY: CGFloat = 55 + ay
            kawaiiUfoAntenna(f, k, ax, aY, antenna, alien)
            k.body(circ(ax, aY, ar), alien, depth: 0.2)
            k.face(ax + faceDX, aY - 1, spread: 6, r: 2.5)
            kawaiiUfoDecor(f, k, ax, aY)
            let dome = ell(50, 44, 24, 30)
            k.clip(rrect(20, 44, 60, 40, 0)) {
                k.fill(dome, Tone(0xe6f6ff, 0.28))
                k.stroke(arc(36, 54, 44, 67, dip: 3), Tone.white.alpha(0.75), k.width(2, minPt: 0.8))
            }
            let disc = ell(50, 38, 44, 11)
            k.body(disc, saucer, depth: 0.45)
            k.fill(ell(50, 43.5, 23, 3.6), saucer.mix(.white, 0.35))
            let palette = [Tone(0xff9fbf), Tone(0xffd66e), Tone(0x8fe3b8), Tone(0x8cc8ff), Tone(0xc4a8ff)]
            for i in 0..<5 {
                let x: CGFloat = 20 + CGFloat(i) * 15
                let y: CGFloat = 36 - 1.8 * (1 - abs(CGFloat(i) - 2) / 2)
                let on: Bool
                switch lit {
                case 0: on = false
                case 3: on = true
                default: on = (f.frameIndex / (lit == 2 ? 1 : 2) + i) % 3 == 0
                }
                let c = palette[(i + f.variant) % 5]
                if on {
                    k.glow(x, y, 6, c, 0.6)
                    k.fill(circ(x, y, 3), c.lift(0.3))
                } else {
                    k.fill(circ(x, y, 2.6), c.mix(saucer, 0.6))
                }
            }
        }
        k.marks(80, 72, 12)
    }

    private static func kawaiiUfoAntenna(_ f: FigureFrame, _ k: KawaiiKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ alien: Tone) {
        let v = f.variant % 5
        guard v != 3 else { return }
        let stalk = alien.dim(0.86)
        let lw = k.width(1.6, minPt: 0.8)
        let wob = 2 * f.twitch
        if v == 2 {
            k.both { side in
                let tx = x + side * 7 + wob * 0.5, ty = y + 12 + 5 * s
                k.stroke(line(x + side * 5, y + 10, tx, ty), stalk, lw)
                k.fill(circ(tx, ty, 2.3), Tone(0xffb3c9))
            }
        } else {
            let tx = x + wob, ty = y + 13 + 5 * s
            k.stroke(line(x, y + 12, tx, ty), stalk, lw)
            k.fill(circ(tx, ty, 2.6), v == 0 ? Tone(0xffd66e) : stalk)
        }
    }

    private static func kawaiiUfoDecor(_ f: FigureFrame, _ k: KawaiiKit, _ x: CGFloat, _ y: CGFloat) {
        switch f.variant % 5 {
        case 1:
            k.bow(x + 7, y + 10, 3.8, Tone(0xff8fb3), -0.4)
        case 3:
            kawaiiPartyHat(k, x, y + 11, 5, -0.1, Tone(0xffb3c9), Tone(0xfff3c4))
        case 4:
            k.flower(x - 8, y + 9, 3.8, Tone(0xffb8d0))
        default:
            break
        }
    }

    private static func kawaiiPartyHat(_ k: KawaiiKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ rot: CGFloat, _ tone: Tone, _ band: Tone) {
        k.with(about(x, y, rot: rot)) {
            let cone = poly([x - s, y, x + s, y, x, y + s * 2.1])
            k.fill(cone, tone)
            k.stroke(cone, tone, s * 0.35)
            k.clip(cone) { k.fill(rrect(x - s * 2, y + s * 0.65, s * 4, s * 0.5, 0), band) }
            k.fill(circ(x, y + s * 2.2, s * 0.45), band)
        }
    }

    private static func kawaiiPartyTwinkle(_ k: KawaiiKit, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ tone: Tone) {
        guard r > 0.5 else { return }
        k.fill(star(x, y, r, points: 4, inner: 0.34), tone)
    }
}
