import Foundation
import CoreGraphics
import ScuttleCore

extension KawaiiArt {
    static func ladybird(_ f: FigureFrame, _ k: KawaiiKit) {
        let v = f.variant % 5
        let shell = f.pick([Tone(0xff9e9e), Tone(0xffb8d3), Tone(0xffdf8c), Tone(0xb4e9cf), Tone(0xcdbaf6)])
        let spot = Tone(0x7a5876)
        let head = Tone(0xfff3ea)
        let t = f.t
        let e = f.energy
        var lift: CGFloat = 0
        var sy: CGFloat = 1
        var tilt: CGFloat = 0.03 * f.swing * e
        var hx: CGFloat = 72, hy: CGFloat = 22, fdx: CGFloat = 0
        let tw = 2.5 * f.twitch
        var ant: [CGFloat] = [-10 + tw, 25, 12 + tw, 23]
        var wings = false
        var legs = true
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sy = 0.9
            hy = 17
            hx = 70
            legs = false
            tilt = 0
            ant = [-15, 13, 16, 11]
        case .startled:
            lift = 5
            sy = 1.05
            hy = 25
            ant = [-6, 30, 8, 30]
        case .fleeing:
            wings = true
            fdx = 2.5
            hx = 73
            ant = [-18, 18, -8, 23]
        case .dizzy:
            tilt = 0.12 * sin(t)
            ant = [-11 + 3 * sin(t), 24, 12 - 3 * sin(t), 22]
        }
        k.with(about(45, 4, rot: tilt, sy: sy)) {
            if legs { ladybirdLegs(f, k, lift) }
            k.with(CGAffineTransform(translationX: 0, y: lift)) {
                if wings { ladybirdWings(f, k) }
                let body = ell(44, 33, 28, 24)
                k.body(body, shell)
                k.clip(body) {
                    k.stroke(arc(47, 58, 41, 8, dip: -3), k.shade(shell).dim(0.95), k.width(2, minPt: 0.7))
                    ladybirdSpots(k, v, spot)
                }
                k.shine(30, 47, 6, 3.4)
                let antTone = Tone(0x8f6f8c)
                for i in 0..<2 {
                    let bx: CGFloat = hx + (i == 0 ? -4 : 5)
                    let tx = hx + ant[i * 2], ty = hy + ant[i * 2 + 1]
                    k.stroke(arc(bx, hy + 10, tx, ty, dip: i == 0 ? 2 : -2), antTone, k.width(2.2, minPt: 0.75))
                    k.fill(circ(tx, ty, 3), antTone)
                }
                k.body(circ(hx, hy, 16), head, depth: 0.26)
                k.face(hx + 3 + fdx, hy - 1.5, spread: 6.6, r: 2.5)
                ladybirdHat(f, k, hx, hy)
                k.marks(hx + 13, hy + 24, 11)
            }
        }
    }

    private static func ladybirdLegs(_ f: FigureFrame, _ k: KawaiiKit, _ lift: CGFloat) {
        let leg = Tone(0xa58aa6)
        for i in 0..<3 {
            let x: CGFloat = 28 + CGFloat(i) * 15
            let ph = f.t + CGFloat(i) * 2.1
            let dx = 2.6 * sin(ph) * f.energy
            let dy = max(0, cos(ph)) * 1.8 * min(f.energy, 1.2)
            k.stroke(line(x, 12 + lift, x + dx, 6.5 + dy), leg, 4.4)
            k.nub(x + dx + 1, 5.6 + dy, 3.6, 2.4, leg)
        }
    }

    private static func ladybirdWings(_ f: FigureFrame, _ k: KawaiiKit) {
        let a: CGFloat = f.frameIndex % 2 == 0 ? 0.35 : 0.8
        let wing = Tone(0xf2f8ff, 0.8)
        k.fill(ell(28, 58, 17, 8, a), wing)
        k.fill(ell(36, 62, 15, 7, a + 0.25), Tone(0xffffff, 0.85))
    }

    private static func ladybirdSpots(_ k: KawaiiKit, _ v: Int, _ spot: Tone) {
        let spots: [CGFloat] = [29, 38, 6, 56, 44, 5, 31, 20, 5, 56, 22, 4.8, 44, 50, 3.6]
        for i in 0..<5 {
            let x = spots[i * 3], y = spots[i * 3 + 1], r = spots[i * 3 + 2]
            switch v {
            case 1:
                k.fill(heart(x, y, r * 1.05), Tone(0xe86a92))
            case 4:
                k.fill(softStar(x, y, r * 1.3, inner: 0.5), Tone(0x8e6fd0))
            default:
                k.fill(circ(x, y, r), spot)
            }
        }
    }

    private static func ladybirdHat(_ f: FigureFrame, _ k: KawaiiKit, _ hx: CGFloat, _ hy: CGFloat) {
        switch f.variant % 5 {
        case 1:
            k.bow(hx - 8, hy + 12, 5.2, Tone(0xb79cf0), 0.35)
        case 2:
            k.flower(hx - 34, hy + 34, 5.6, Tone(0xffffff), Tone(0xffb35c))
        case 3:
            let leaf = Tone(0x86cf98)
            k.stroke(arc(hx + 1, hy + 13, hx + 2, hy + 19, dip: -1), leaf.dim(0.85), 2)
            k.nub(hx - 3, hy + 20 + 0.6 * f.twitch, 5.2, 2.6, leaf, 0.5)
            k.nub(hx + 7, hy + 20 - 0.6 * f.twitch, 5.2, 2.6, leaf, -0.5)
        default:
            break
        }
    }

    static func bumblebee(_ f: FigureFrame, _ k: KawaiiKit) {
        let v = f.variant % 5
        let base = f.pick([Tone(0xffe28a), Tone(0xffd2ae), Tone(0xfff0a6), Tone(0xffc8da), Tone(0xffe28a)])
        let stripe = Tone(0x9e8579)
        let t = f.t
        var sx: CGFloat = 1, sy: CGFloat = 1, tilt: CGFloat = 0, fdx: CGFloat = 0
        let tw = 2.5 * f.twitch
        var ant: [CGFloat] = [-4 + tw, 14, 8 + tw, 12]
        var wingMode = f.frameIndex % 2
        var legSwing: CGFloat = 2 * sin(t * 2)
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sx = 1.05
            sy = 0.92
            wingMode = 2
            legSwing = 0
            ant = [4, 9, 14, 6]
        case .startled:
            sx = 0.95
            sy = 1.07
            ant = [-2, 17, 6, 17]
            legSwing = 3
        case .fleeing:
            fdx = 2.5
            wingMode = f.frameIndex % 3
            tilt = -0.08
            ant = [-12, 10, -4, 13]
            legSwing = -4
        case .dizzy:
            tilt = 0.12 * sin(t)
            ant = [-4 + 3 * sin(t), 13, 8 - 3 * sin(t), 12]
        }
        k.with(about(50, 46, rot: tilt, sx: sx, sy: sy)) {
            bumblebeeWings(k, wingMode, back: true)
            bumblebeeWings(k, wingMode, back: false)
            let leg = stripe.mix(.white, 0.25)
            k.stroke(line(42, 26, 40 + legSwing * 0.5, 17), leg, 3.6)
            k.stroke(line(54, 25, 53 + legSwing, 16), leg, 3.6)
            k.fill(smooth([23, 51, 23, 39, 12, 44.5], t: 0.4), stripe)
            let body = ell(49, 45, 29, 25)
            k.body(body, base, shade: kawaiiMeadowWarmShade(base))
            k.clip(body) {
                k.fill(ell(29, 45, 4.4, 30, 0.12), stripe)
                k.fill(ell(41.5, 45, 4.4, 30, 0.06), stripe)
            }
            let antTone = stripe
            for i in 0..<2 {
                let bx: CGFloat = i == 0 ? 60 : 68
                let by: CGFloat = i == 0 ? 67 : 65
                let tx = bx + ant[i * 2], ty = by + ant[i * 2 + 1]
                k.stroke(arc(bx, by, tx, ty, dip: -2), antTone, k.width(2.2, minPt: 0.75))
                k.fill(circ(tx, ty, 3), antTone)
            }
            k.shine(52, 62, 4.6, 2.6)
            k.face(64 + fdx, 42, spread: 7, r: 2.4)
            bumblebeeHat(f, k, v)
            k.marks(78, 72, 11)
        }
    }

    private static func bumblebeeWings(_ k: KawaiiKit, _ mode: Int, back: Bool) {
        let wing = back ? Tone(0xdcebff, 0.9) : Tone(0xf6fbff, 0.95)
        let x: CGFloat = back ? 38 : 50
        k.with(about(x, 64, rot: [0.35, 0.8, 1.25][min(mode, 2)] * (back ? 1.1 : 0.8))) {
            k.fill(ell(x, 78, 9.5, 14), wing)
        }
    }

    private static func kawaiiMeadowWarmShade(_ base: Tone) -> Tone {
        base.dim(0.95).mix(Tone(0xf2a2b8), 0.3)
    }

    private static func bumblebeeHat(_ f: FigureFrame, _ k: KawaiiKit, _ v: Int) {
        switch v {
        case 1:
            k.flower(58, 71, 5.4, Tone(0xffa9c8))
        case 2:
            k.bow(52, 70, 5, Tone(0x9fe0c4), -0.2)
        case 3:
            let swing = 1.5 * f.swing
            k.stroke(line(74, 28, 76 + swing, 22), Tone(0xc9a27a), 1.6)
            k.fill(drop(76 + swing, 17, 5.4, .pi), Tone(0xffc14d))
            k.fill(ell(74.6 + swing, 17, 1.2, 1.8, 0.4), Tone.white.alpha(0.8))
        case 4:
            let gold = Tone(0xffc95c)
            k.fill(poly([45, 68, 47, 79, 51.5, 72, 56, 81, 60.5, 72, 65, 79, 67, 68]), gold)
            k.fill(rrect(45, 66.5, 22, 4.5, 2), gold.dim(0.95))
            k.fill(circ(56, 81, 1.8), Tone(0xff9db8))
        default:
            break
        }
    }

    static func snail(_ f: FigureFrame, _ k: KawaiiKit) {
        let v = f.variant % 5
        let shell = f.pick([Tone(0xffc2d6), Tone(0xd5c6f7), Tone(0xbdeed6), Tone(0xffd3b0), Tone(0xbfdcff)])
        let skin = Tone(0xfff0dc)
        let t = f.t
        let e = f.energy
        let wave = sin(t)
        var reach: CGFloat = 5 * wave * min(e, 1.2)
        var hx: CGFloat = 72, hy: CGFloat = 26, hr: CGFloat = 13.5
        var stalk: [CGFloat] = [-8 + 2 * f.twitch, 24, 8 + 2 * f.twitch, 23]
        var tilt: CGFloat = 0, shellLift: CGFloat = 0, fdx: CGFloat = 0, sy: CGFloat = 1
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            hx = 64
            hy = 17
            hr = 11.5
            reach = 0
            stalk = [-6, 14, 6, 13]
            sy = 0.95
        case .startled:
            hy = 33
            reach = 2
            stalk = [-6, 29, 8, 29]
            shellLift = 3
        case .fleeing:
            hx = 78
            reach = 3 * wave
            stalk = [-18, 17, -8, 21]
            fdx = 2
        case .dizzy:
            tilt = 0.11 * sin(t)
            stalk = [-8 + 4 * sin(t), 23, 8 - 4 * sin(t), 23]
        }
        hx += reach
        let shellX: CGFloat = (f.mood == .fleeing ? 36 : 40) + reach * 0.35
        k.with(about(48, 4, rot: tilt, sx: 1.1, sy: 1.1 * sy)) {
            let tail: CGFloat = 12 - reach * 0.3 - (f.mood == .fleeing ? 4 : 0)
            let foot = smooth([tail, 7, (tail + hx) / 2, 4.4, hx + 8, 4.6, hx + 11, 10, hx + 2, 18, (tail + hx) / 2, 17, tail + 5, 12.5], t: 0.85)
            for i in 0..<2 {
                let bx: CGFloat = hx + (i == 0 ? -4 : 4)
                let tx = hx + stalk[i * 2], ty = hy + stalk[i * 2 + 1]
                k.stroke(arc(bx, hy + hr * 0.5, tx, ty, dip: i == 0 ? 1.5 : -1.5), skin.dim(0.96), k.width(3.4, minPt: 1))
                k.fill(circ(tx, ty, 3.8), skin)
            }
            k.body(foot, skin, shade: k.shade(skin).dim(0.98), depth: 0.4)
            let neckY: CGFloat = max(12, hy - 7)
            k.body(uni([ell(hx - 1, neckY, 9.5, max(4, neckY - 5)), circ(hx, hy, hr)]), skin, depth: 0.16)
            k.shine(hx - 6, hy + 7, 3.4, 2)
            let sc = CGPoint(x: shellX, y: 32 + shellLift)
            let sr: CGFloat = 21
            k.body(circ(sc.x, sc.y, sr), shell, depth: 0.32)
            k.stroke(spiral(sc.x + 1.5, sc.y - 0.5, 14.5, turns: 1.55, spin: 1, start: 0.4), k.shade(shell).dim(0.9), k.width(3, minPt: 1))
            k.shine(sc.x - 9, sc.y + 11, 4.6, 2.6)
            k.face(hx + 2.5 + fdx, hy - 2, spread: 5.4, r: 2.2)
            snailHat(f, k, v, sc, hx, hy, stalk)
            k.marks(hx + 12, hy + 20, 10)
        }
    }

    private static func snailHat(_ f: FigureFrame, _ k: KawaiiKit, _ v: Int, _ sc: CGPoint, _ hx: CGFloat, _ hy: CGFloat, _ stalk: [CGFloat]) {
        switch v {
        case 1:
            k.flower(sc.x - 3, sc.y + 20, 5.6, Tone(0xffb3cc))
        case 2:
            k.bow(hx - 8, hy + 10, 4.6, Tone(0xff9fc0), 0.4)
        case 3:
            let leaf = Tone(0x8ccf86)
            k.stroke(line(sc.x + 2, sc.y + 20, sc.x + 3, sc.y + 30), leaf.dim(0.8), 1.8)
            k.fill(smooth([sc.x + 3, sc.y + 26, sc.x - 10, sc.y + 30, sc.x + 3, sc.y + 38, sc.x + 16, sc.y + 30], t: 0.9), leaf)
        case 4:
            k.fill(softStar(sc.x + 10, sc.y + 16, 7, inner: 0.5, spin: .pi / 2 + 0.2 * f.swing), Tone(0xffd36b))
            k.fill(softStar(sc.x - 14, sc.y - 7, 3.8, inner: 0.5), Tone(0xffffff))
        default:
            break
        }
    }

    static func chick(_ f: FigureFrame, _ k: KawaiiKit) {
        let v = f.variant % 5
        let base = f.pick([Tone(0xfff0a0), Tone(0xfff0a0), Tone(0xfffaf0), Tone(0xffdcc0), Tone(0xfff3b4)])
        let peach = Tone(0xffbd80)
        let t = f.t
        var sy: CGFloat = 1 - 0.16 * f.squat + 0.1 * f.stretch
        var tilt: CGFloat = 0, fdx: CGFloat = 0, faceY: CGFloat = 34
        var wingA: CGFloat = 0.25 + (f.airborne ? 0.9 * abs(sin(f.air * .pi * 3)) : 0)
        var feetIn: CGFloat = f.airborne ? 3 : 0
        var tuftLean: CGFloat = 0.12 * f.twitch
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sy = 0.9
            wingA = 0.05
            faceY = 31
            tuftLean = 0.45
        case .startled:
            sy = max(sy, 1.07)
            wingA = 1.35
            faceY = 37
            tuftLean = 0
        case .fleeing:
            fdx = 2.5
            wingA = 0.6 + 0.8 * abs(sin(t * 2))
            tuftLean = -0.5
            feetIn = 0
        case .dizzy:
            tilt = 0.12 * sin(t)
            wingA = 0.5 + 0.3 * sin(t)
        }
        let sx: CGFloat = 1 / max(0.8, sy) * 0.98 + 0.02
        let step: CGFloat = f.mood == .fleeing ? 4 * sin(t * 2) : 0
        let shade = kawaiiMeadowWarmShade(base)
        k.with(about(50, 4, rot: tilt, sx: sx, sy: sy)) {
            if v != 4 {
                k.nub(41 + feetIn + step, 6 - (f.airborne ? 1 : 0), 6.5, 3.6, peach)
                k.nub(59 - feetIn - step, 6 - (f.airborne ? 1 : 0), 6.5, 3.6, peach)
            }
            k.both { s in
                let wx: CGFloat = 50 + s * 25
                k.with(about(wx, 38, rot: -s * wingA)) {
                    k.nub(wx + s * 4.5, 31, 6.5, 10, base.mix(shade, 0.5))
                }
            }
            if v == 0 || v == 3 {
                chickTuft(k, base, tuftLean)
            }
            k.body(ell(50, 36, 29, 29), base, shade: shade, depth: 0.26)
            k.shine(36, 53, 5.5, 3.2)
            k.face(52 + fdx, faceY, spread: 11, r: 2.6, mouth: .none)
            chickBeak(f, k, 52 + fdx, faceY - 2.5, peach)
            chickHat(f, k, v)
            k.marks(77, 66, 12)
        }
    }

    private static func chickTuft(_ k: KawaiiKit, _ base: Tone, _ lean: CGFloat) {
        k.with(about(50, 62, rot: -lean)) {
            k.nub(46, 69, 3, 6.5, base, 0.35)
            k.nub(51, 71, 3, 7.5, base, 0)
            k.nub(56, 69, 3, 6, base, -0.4)
        }
    }

    private static func chickBeak(_ f: FigureFrame, _ k: KawaiiKit, _ x: CGFloat, _ y: CGFloat, _ peach: Tone) {
        switch f.mood {
        case .startled:
            k.fill(poly([x - 3.6, y + 1, x + 3.6, y + 1, x, y + 4]), peach)
            k.fill(poly([x - 3, y - 0.5, x + 3, y - 0.5, x, y - 3.6]), peach)
            k.stroke(poly([x - 3.4, y + 0.8, x + 3.4, y + 0.8, x, y + 3.6]), peach, 1.4)
        default:
            let beak = poly([x - 3.6, y + 1.6, x + 3.6, y + 1.6, x, y - 2.4])
            k.fill(beak, peach)
            k.stroke(beak, peach, 1.6)
        }
    }

    private static func chickHat(_ f: FigureFrame, _ k: KawaiiKit, _ v: Int) {
        switch v {
        case 1:
            let shell = Tone(0xfffcf6)
            let cap = poly([28, 57, 32, 64, 36, 59, 41, 66, 46, 60, 51, 67, 56, 60, 61, 66, 66, 59, 70, 64, 73, 57, 70, 70, 62, 78, 50, 81, 38, 78, 30, 70])
            k.with(about(50, 60, rot: -0.12 + 0.06 * f.twitch)) {
                k.fill(cap, shell)
                k.fill(ell(40, 72, 4, 2.4, 0.5), Tone(0xe9e2f6))
            }
        case 2:
            k.bow(66, 62, 5.6, Tone(0xffa9c8), -0.3)
        case 3:
            k.flower(67, 60, 5.4, Tone(0xffffff), Tone(0xffc96b))
        case 4:
            let shell = Tone(0xfffcf6)
            let cup = minus(ell(50, 16, 30, 17), poly([16, 26, 24, 31, 30, 24, 37, 31, 44, 24, 50, 31, 56, 24, 63, 31, 70, 24, 76, 31, 84, 26, 84, 60, 16, 60]))
            k.body(cup, shell, depth: 0.45)
            k.fill(ell(37, 15, 3, 2, 0.3), Tone(0xc8b8ee, 0.7))
            k.fill(ell(63, 12, 2.4, 1.6, 0.3), Tone(0xc8b8ee, 0.7))
        default:
            break
        }
    }

    static func butterfly(_ f: FigureFrame, _ k: KawaiiKit) {
        let v = f.variant % 5
        let up = f.pick([Tone(0xffc6de), Tone(0xffd6b6), Tone(0xbfe0ff), Tone(0xdcc8f8), Tone(0xbdeed8)])
        let low = f.pick([Tone(0xbfeedd), Tone(0xd9c9f7), Tone(0xfff1a6), Tone(0xffc6de), Tone(0xffd6b6)])
        let ant = Tone(0xcbb3f2)
        let bodyTone = Tone(0xd6c4f6)
        let head = Tone(0xfff2f7)
        let t = f.t
        var open: CGFloat = 0.72 + 0.28 * f.swing
        var tilt: CGFloat = 0, fdx: CGFloat = 0, droop: CGFloat = 0, sy: CGFloat = 1
        let tw = 2 * f.twitch
        var antTip: [CGFloat] = [33 + tw, 88]
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            open = 0.42 + 0.04 * f.swing
            droop = 0.18
            sy = 0.95
            antTip = [37, 80]
        case .startled:
            open = 1.02 + 0.04 * f.swing
            sy = 1.04
            antTip = [37, 94]
        case .fleeing:
            open = 0.6 + 0.4 * f.swing
            tilt = -0.12
            fdx = 2.5
            antTip = [26, 84]
        case .dizzy:
            tilt = 0.12 * sin(t)
            antTip = [33 + 3 * sin(t), 87]
        }
        k.with(about(50, 40, rot: tilt, sy: sy)) {
            k.both { s in
                let tip = CGPoint(x: 50 + s * (50 - antTip[0]), y: antTip[1])
                k.stroke(smooth([50 + s * 4, 64, 50 + s * 9, 80, tip.x, tip.y], closed: false), ant, k.width(2.6, minPt: 0.8))
                k.fill(circ(tip.x, tip.y, 4), ant)
            }
            k.both { s in
                k.with(about(50, 44, rot: s * droop, sx: open, sy: 1)) {
                    let ux: CGFloat = 50 + s * 23
                    let lx: CGFloat = 50 + s * 19
                    k.fill(ell(ux, 62, 21, 19, -s * 0.35), up)
                    k.fill(ell(lx, 31, 15, 14), low)
                    butterflySpots(k, v, s)
                }
            }
            k.body(ell(50, 28, 9, 14), bodyTone)
            k.body(circ(50, 51, 17), head, depth: 0.12)
            k.face(50 + fdx, 47, spread: 7.5, r: 2.2)
            butterflyHat(f, k, v)
            k.marks(70, 72, 11)
        }
    }

    private static func butterflySpots(_ k: KawaiiKit, _ v: Int, _ s: CGFloat) {
        let w = Tone(0xffffff, 0.6)
        switch v {
        case 3:
            k.fill(heart(50 + s * 29, 66, 5.2), Tone(0xffffff, 0.75))
            k.fill(heart(50 + s * 23, 28, 3.8), Tone(0xffffff, 0.75))
        case 4:
            k.fill(softStar(50 + s * 29, 66, 6.2, inner: 0.5), Tone(0xffffff, 0.75))
            k.fill(softStar(50 + s * 23, 28, 4.4, inner: 0.5), Tone(0xffffff, 0.75))
        default:
            k.fill(circ(50 + s * 29, 67, 6), w)
            k.fill(circ(50 + s * 23, 27, 4), w)
        }
    }

    private static func butterflyHat(_ f: FigureFrame, _ k: KawaiiKit, _ v: Int) {
        switch v {
        case 1:
            k.bow(50, 68, 5, Tone(0xff9fc2))
        case 2:
            k.flower(62, 64, 5, Tone(0xffffff), Tone(0xffc96b))
        default:
            break
        }
    }

    static func dragonfly(_ f: FigureFrame, _ k: KawaiiKit) {
        let v = f.variant % 5
        let base = f.pick([Tone(0xa9dcf5), Tone(0xb6ecd0), Tone(0xd6c6f7), Tone(0xffc6dc), Tone(0xffd8b2)])
        let t = f.t
        var tailLift: CGFloat = 0, wave: CGFloat = 1.6, tilt: CGFloat = 0, fdx: CGFloat = 0, sy: CGFloat = 1
        var wingMode = f.frameIndex % 2
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            tailLift = -5
            wave = 0.5
            wingMode = 2
            sy = 0.96
        case .startled:
            tailLift = 6
            wave = 0.8
            wingMode = 3
        case .fleeing:
            tailLift = 0
            wave = 0.6
            fdx = 2
            wingMode = f.frameIndex % 2
        case .dizzy:
            tilt = 0.12 * sin(t)
            wave = 2.4
        }
        k.with(about(50, 50, rot: tilt, sy: sy)) {
            dragonflyWings(k, wingMode, back: true)
            let xs: [CGFloat] = [41, 32, 24, 17, 10]
            let rs: [CGFloat] = [8.2, 7.3, 6.5, 5.8, 5.2]
            var tipX: CGFloat = 10, tipY: CGFloat = 48
            for i in (0..<5).reversed() {
                let u = CGFloat(i + 1) / 5
                let y = 48 + tailLift * u + wave * sin(t - CGFloat(i) * 0.7)
                let x = xs[i] - (f.mood == .fleeing ? CGFloat(i) * 1.5 : 0)
                k.body(circ(x, y, rs[i]), i % 2 == 0 ? base : base.mix(.white, 0.35), depth: 0.3)
                if i == 4 {
                    tipX = x
                    tipY = y
                }
            }
            k.body(ell(55, 50, 12, 10.5), base)
            dragonflyWings(k, wingMode, back: false)
            let headTone = base.mix(.white, 0.25)
            k.body(circ(74, 53, 15), headTone, depth: 0.26)
            k.shine(68, 62, 3.8, 2.2)
            k.face(77 + fdx, 50, spread: 6, r: 2.3)
            dragonflyHat(f, k, v, tipX, tipY)
            k.marks(87, 70, 10)
        }
    }

    private static func dragonflyWings(_ k: KawaiiKit, _ mode: Int, back: Bool) {
        let wing = back ? Tone(0xe2f0ff, 0.78) : Tone(0xffffff, 0.84)
        let a: [CGFloat]
        switch mode {
        case 0:
            a = back ? [0.55, -0.35] : [0.85, -0.05]
        case 1:
            a = back ? [1.1, 0.25] : [1.35, 0.5]
        case 2:
            a = back ? [1.5, 1.35] : [1.62, 1.45]
        default:
            a = back ? [0.25, -0.65] : [0.5, -0.4]
        }
        let len: CGFloat = back ? 20 : 18
        k.with(about(53, 57, rot: a[0])) {
            k.fill(ell(53, 57 + len, 5.6, len), wing)
        }
        k.with(about(57, 57, rot: a[1])) {
            k.fill(ell(57, 57 + len * 0.9, 5.2, len * 0.9), wing)
        }
    }

    private static func dragonflyHat(_ f: FigureFrame, _ k: KawaiiKit, _ v: Int, _ tx: CGFloat, _ ty: CGFloat) {
        switch v {
        case 1:
            k.bow(tx - 4, ty, 5.4, Tone(0xff9fc2), 1.3)
        case 2:
            k.flower(69, 67, 4.8, Tone(0xffffff), Tone(0xffc96b))
        case 3:
            let leaf = Tone(0x8ccf86)
            k.stroke(line(74, 67, 74, 72), leaf.dim(0.8), 1.8)
            k.nub(70, 72 + 0.6 * f.twitch, 5, 2.5, leaf, 0.45)
            k.nub(79, 72 - 0.6 * f.twitch, 5, 2.5, leaf, -0.45)
        case 4:
            k.fill(softStar(tx - 4, ty, 5.6, inner: 0.5, spin: .pi / 2 + 0.3), Tone(0xffe07a))
        default:
            break
        }
    }

    static func firefly(_ f: FigureFrame, _ k: KawaiiKit) {
        let v = f.variant % 5
        let body = f.pick([Tone(0xd3c8ef), Tone(0xc6d6f2), Tone(0xdcccf0), Tone(0xcfdcea), Tone(0xd8c8ec)])
        let light = f.pick([Tone(0xfff39a), Tone(0xc6ffc9), Tone(0xffd3e8), Tone(0xfff39a), Tone(0xffe2b4)])
        let t = f.t
        var pulse: CGFloat = 0.5 + 0.5 * sin(t)
        var sx: CGFloat = 1, sy: CGFloat = 1, tilt: CGFloat = 0, fdx: CGFloat = 0
        var wingMode = f.frameIndex % 2
        let tw = 2.5 * f.twitch
        var ant: [CGFloat] = [-3 + tw, 14, 9 + tw, 11]
        var bulbX: CGFloat = 31
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            pulse = 0.12 + 0.12 * sin(t)
            sx = 1.04
            sy = 0.92
            wingMode = 2
            ant = [5, 8, 14, 5]
        case .startled:
            pulse = 1.25
            sy = 1.07
            sx = 0.95
            ant = [-1, 17, 6, 17]
        case .fleeing:
            pulse = 0.8 + 0.2 * sin(t * 2)
            fdx = 2.5
            tilt = -0.08
            ant = [-12, 9, -4, 12]
            bulbX = 28
        case .dizzy:
            tilt = 0.12 * sin(t)
            ant = [-3 + 3 * sin(t), 13, 9 - 3 * sin(t), 11]
        }
        k.with(about(50, 48, rot: tilt, sx: sx, sy: sy)) {
            k.glow(bulbX, 42, 26 + 8 * pulse, light, 0.22 + 0.32 * min(pulse, 1.1))
            if f.mood == .fleeing {
                for i in 0..<3 {
                    let d = CGFloat(i + 1)
                    k.fill(circ(bulbX - 6 - d * 7, 42 + 2 * sin(t + d), 3.4 - d * 0.7), light.alpha(0.75 - d * 0.18))
                }
            }
            fireflyWings(k, wingMode, back: true)
            fireflyWings(k, wingMode, back: false)
            let bright = light.mix(.white, 0.35 * min(pulse, 1))
            k.body(ell(bulbX, 42, 15, 14), bright, shade: light.dim(0.97), depth: 0.25)
            k.fill(ell(bulbX - 4, 47, 4.5, 3, 0.6), Tone.white.alpha(0.5 + 0.4 * min(pulse, 1)))
            k.body(ell(57, 47, 23, 22), body)
            let antTone = Tone(0x9a88c4)
            for i in 0..<2 {
                let bx: CGFloat = i == 0 ? 60 : 68
                let by: CGFloat = i == 0 ? 68 : 66
                let tx = bx + ant[i * 2], ty = by + ant[i * 2 + 1]
                k.stroke(arc(bx, by, tx, ty, dip: -2), antTone, k.width(2.2, minPt: 0.75))
                if v == 4 {
                    k.fill(softStar(tx, ty, 5.4, inner: 0.5), Tone(0xffd36b))
                } else {
                    k.fill(circ(tx, ty, 3), antTone)
                }
            }
            k.shine(50, 62, 4.6, 2.6)
            k.face(62 + fdx, 43, spread: 7, r: 2.4)
            fireflyHat(f, k, v)
            k.marks(80, 70, 11)
        }
    }

    private static func fireflyWings(_ k: KawaiiKit, _ mode: Int, back: Bool) {
        let wing = back ? Tone(0xdcebff, 0.9) : Tone(0xf6fbff, 0.95)
        let x: CGFloat = back ? 46 : 56
        k.with(about(x, 64, rot: [0.35, 0.8, 1.25][min(mode, 2)] * (back ? 1.1 : 0.8))) {
            k.fill(ell(x, 77, 9, 13.5), wing)
        }
    }

    private static func fireflyHat(_ f: FigureFrame, _ k: KawaiiKit, _ v: Int) {
        switch v {
        case 1:
            let cap = Tone(0xa9c4f0)
            let tipX: CGFloat = 44 + 2 * f.twitch
            k.fill(smooth([46, 64, 70, 66, 58, 74, tipX, 76], t: 0.6), cap)
            k.fill(circ(tipX - 1, 75, 3.2), Tone(0xffffff))
            k.fill(ell(58, 65, 13, 3.2, 0.05), Tone(0xffffff))
        case 2:
            k.bow(57, 68, 4.8, Tone(0xffa9c8), -0.15)
        case 3:
            k.flower(52, 68, 5, Tone(0xffc2dc))
        default:
            break
        }
    }

    static func crab(_ f: FigureFrame, _ k: KawaiiKit) {
        let v = f.variant % 5
        let base = f.pick([Tone(0xffad9c), Tone(0xffc6a6), Tone(0xffbcd2), Tone(0xd4c2f3), Tone(0xb8e8d4)])
        let t = f.t
        let e = f.energy
        let shuffle: CGFloat = 1.6 * sin(t) * min(e, 1.3)
        var lift: CGFloat = 0, sy: CGFloat = 1, tilt: CGFloat = 0, fdx: CGFloat = 0
        var clawY: CGFloat = 50, clawX: CGFloat = 19, pinch: CGFloat = 0.5 + 0.5 * sin(t * 2)
        var wave: CGFloat = 0
        switch f.mood {
        case .calm:
            wave = 2 * f.twitch
        case .sleepy:
            sy = 0.9
            clawY = 16
            clawX = 17
            pinch = 0
        case .startled:
            lift = 4
            sy = 1.04
            clawY = 66
            clawX = 16
            pinch = 1
        case .fleeing:
            fdx = 2.5
            clawY = 62 + 3 * sin(t * 2)
            clawX = 18
            pinch = 0.5 + 0.5 * sin(t * 4)
            wave = 3 * sin(t * 2)
        case .dizzy:
            tilt = 0.12 * sin(t)
        }
        k.with(about(50, 4, rot: tilt, sy: sy)) {
            k.with(CGAffineTransform(translationX: shuffle, y: 0)) {
                if f.mood != .sleepy { crabLegs(f, k, base, lift) }
                k.with(CGAffineTransform(translationX: 0, y: lift)) {
                    for i in 0..<2 {
                        let s: CGFloat = i == 0 ? -1 : 1
                        let cx = 50 + s * (50 - clawX)
                        let cy = clawY + (s > 0 ? wave : -wave * 0.5)
                        k.stroke(line(50 + s * 22, 30, cx, cy - 6), k.shade(base), 5)
                        crabClaw(k, cx, cy, s, pinch, base)
                    }
                    k.both { s in
                        k.stroke(line(50 + s * 8, 44, 50 + s * 10 + (s > 0 ? f.twitch : 0), 54), base, 3.2)
                        k.fill(circ(50 + s * 10 + (s > 0 ? f.twitch : 0), 55, 3.6), base)
                    }
                    k.body(ell(50, 30, 28, 20), base)
                    k.shine(36, 41, 5, 2.8)
                    k.face(50 + fdx, 28, spread: 10, r: 2.6)
                    crabHat(f, k, v)
                    k.marks(76, 54, 11)
                }
            }
        }
    }

    private static func crabLegs(_ f: FigureFrame, _ k: KawaiiKit, _ base: Tone, _ lift: CGFloat) {
        let leg = k.shade(base)
        for i in 0..<2 {
            let ph = f.t * 2 + CGFloat(i) * 3.1
            let amp: CGFloat = 2.6 * min(f.energy, 1.3)
            k.both { s in
                let x0: CGFloat = 50 + s * (15 + CGFloat(i) * 8)
                let x1: CGFloat = 50 + s * (20 + CGFloat(i) * 9)
                let y1 = 6 + (s > 0 ? max(0, sin(ph)) : max(0, -sin(ph))) * amp
                k.stroke(line(x0, 15 + lift, x1, y1), leg, 5.6)
                k.nub(x1 + s * 0.8, y1 - 0.4, 3.4, 2.6, leg)
            }
        }
    }

    private static func crabClaw(_ k: KawaiiKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ pinch: CGFloat, _ base: Tone) {
        let open: CGFloat = 0.15 + 0.4 * pinch
        let r: CGFloat = 9.5
        let ax = x + s * 1, ay = y + 2
        let a0: CGFloat = s > 0 ? .pi / 2 - 0.35 : .pi / 2 + 0.35
        let w = CGMutablePath()
        w.move(to: pt(ax, ay))
        w.addLine(to: pt(ax + cos(a0 - open) * r * 2, ay + sin(a0 - open) * r * 2))
        w.addLine(to: pt(ax + cos(a0 + open) * r * 2, ay + sin(a0 + open) * r * 2))
        w.closeSubpath()
        k.body(minus(ell(x, y, r * 0.95, r), w), base, depth: 0.3)
        k.fill(ell(x - s * 3, y + 4, 2.4, 1.5, 0.6), Tone.white.alpha(0.7))
    }

    private static func crabHat(_ f: FigureFrame, _ k: KawaiiKit, _ v: Int) {
        switch v {
        case 1:
            k.bow(66, 46, 4.8, Tone(0xff9fc2), -0.3)
        case 2:
            k.flower(33, 46, 5, Tone(0xffffff), Tone(0xffc96b))
        case 3:
            let shell = Tone(0xfff0f4)
            let fan = smooth([39, 47, 41, 56, 50, 62, 59, 56, 61, 47, 50, 45], t: 0.8)
            k.fill(fan, shell)
            for x in [44, 50, 56] as [CGFloat] {
                k.stroke(line(50, 46, x + (x - 50) * 0.3, 58), Tone(0xf5bccb), 1.4)
            }
            k.fill(ell(50, 46, 4, 2.4), Tone(0xf5bccb))
        case 4:
            k.fill(softStar(76, 24, 6.6, inner: 0.5, spin: .pi / 2 + 0.2 * f.swing), Tone(0xffd36b))
            k.fill(circ(76, 24, 1.4), Tone(0xffb35c))
        default:
            break
        }
    }

    static func frog(_ f: FigureFrame, _ k: KawaiiKit) {
        let v = f.variant % 5
        let base = f.pick([Tone(0xb8e6a2), Tone(0xa9e4d4), Tone(0xdcf0a2), Tone(0xffc6d6), Tone(0xbcd8ff)])
        let belly = Tone(0xfffbea)
        let t = f.t
        var sy: CGFloat = 1 - 0.18 * f.squat + 0.12 * f.stretch
        var tilt: CGFloat = 0, fdx: CGFloat = 0, eyeY: CGFloat = 48
        var legOut: CGFloat = f.airborne ? max(0, f.stretch) : 0
        var tuck: CGFloat = f.airborne ? max(0, -f.stretch) : 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sy = 0.88
            eyeY = 45
            legOut = 0
            tuck = 0
        case .startled:
            sy = max(sy, 1.08)
            eyeY = 51
        case .fleeing:
            fdx = 2.5
            legOut = max(legOut, 0.6 + 0.4 * sin(t))
        case .dizzy:
            tilt = 0.12 * sin(t)
        }
        let sx: CGFloat = 1 / max(0.82, sy) * 0.97 + 0.03
        k.with(about(50, 4, rot: tilt, sx: sx, sy: sy)) {
            let thigh = k.shade(base)
            k.both { s in
                let kx: CGFloat = 50 + s * 25
                let footX: CGFloat = kx + s * (3 + 4 * legOut) - s * 3 * tuck
                let footY: CGFloat = 6 - 6 * legOut
                if legOut > 0.05 {
                    k.stroke(line(kx, 12, footX + s * 1, footY + 1.5), thigh, 6.5)
                }
                k.nub(kx, 13 + 2 * tuck, 10, 8.5, thigh)
                k.nub(footX + s * 3, footY, 7.5, 3.6, thigh, s * 0.2 * legOut)
            }
            let eyeTone = base
            k.body(circ(36, eyeY, 10.5), eyeTone, depth: 0.2)
            k.body(circ(64 + fdx * 0.5, eyeY, 10.5), eyeTone, depth: 0.2)
            k.body(ell(50, 27, 32, 23), base, depth: 0.26)
            k.fill(ell(50, 20, 19, 12), belly)
            k.nub(42 - (f.mood == .startled ? 4 : 0), 7 + 2 * tuck, 5.4, 3.4, base.mix(.white, 0.25))
            k.nub(58 + (f.mood == .startled ? 4 : 0), 7 + 2 * tuck, 5.4, 3.4, base.mix(.white, 0.25))
            if f.mood == .startled {
                k.nub(24, 32, 4.5, 7, base, -0.6)
                k.nub(76, 32, 4.5, 7, base, 0.6)
            } else if f.mood == .calm && f.twitch != 0 {
                k.nub(79, 29 + 3 * f.twitch, 4.2, 6.5, base, 0.5 + 0.25 * f.twitch)
            }
            k.shine(35, 55, 3.6, 2.2)
            k.eye(37 + fdx, eyeY - 1, 2.8, side: -1)
            k.eye(63 + fdx, eyeY - 1, 2.8, side: 1)
            k.blush(30 + fdx, 34, 4.8, 2.8)
            k.blush(70 + fdx, 34, 4.8, 2.8)
            frogMouth(f, k, 50 + fdx, 35)
            frogHat(f, k, v, eyeY)
            k.marks(78, 62, 12)
        }
    }

    private static func frogMouth(_ f: FigureFrame, _ k: KawaiiKit, _ x: CGFloat, _ y: CGFloat) {
        switch f.mood {
        case .calm:
            let p = CGMutablePath()
            p.move(to: pt(x - 9, y + 1.5))
            p.addQuadCurve(to: pt(x, y), control: pt(x - 4.5, y - 4))
            p.addQuadCurve(to: pt(x + 9, y + 1.5), control: pt(x + 4.5, y - 4))
            k.stroke(p, k.eyeTone, k.width(1.7, minPt: 0.6))
        default:
            k.mouth(x, y, 7.5, kind: .smile)
        }
    }

    private static func frogHat(_ f: FigureFrame, _ k: KawaiiKit, _ v: Int, _ eyeY: CGFloat) {
        switch v {
        case 1:
            let gold = Tone(0xffd36b)
            k.fill(poly([40, 55, 41, 66, 46, 60, 50, 68, 54, 60, 59, 66, 60, 55]), gold)
            k.fill(rrect(40, 53, 20, 4.4, 2), gold.dim(0.95))
            k.fill(circ(50, 68, 1.8), Tone(0xff9db8))
        case 2:
            k.flower(64, eyeY + 10, 5, Tone(0xffb3cc))
        case 3:
            let leaf = Tone(0x7cc48a)
            k.stroke(line(50, 50, 51 + f.twitch, 58), leaf.dim(0.8), 1.8)
            k.fill(smooth([28, 58, 50, 70, 72, 58, 50, 61], t: 0.8), leaf)
            k.stroke(line(31, 59, 69, 59), leaf.dim(0.85), 1)
        case 4:
            k.bow(36, eyeY + 9, 4.6, Tone(0xff9fc2), 0.3)
        default:
            break
        }
    }

    static func sun(_ f: FigureFrame, _ k: KawaiiKit) {
        let v = f.variant % 5
        let base = f.pick([Tone(0xffe27a), Tone(0xffd1a0), Tone(0xffd4dc), Tone(0xfff0a0), Tone(0xffdc8a)])
        let ray = base.mix(Tone(0xffb347), 0.22)
        let t = f.t
        var sx: CGFloat = 1, sy: CGFloat = 1 + 0.02 * f.swing2, tilt: CGFloat = 0, fdx: CGFloat = 0
        var rayR: CGFloat = 33, rayLen: CGFloat = 5.5, spin: CGFloat = f.phase * 2 * .pi / 10, stream: CGFloat = 0
        var glowA: CGFloat = 0.32 + 0.06 * f.swing
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sx = 1.04
            sy = 0.95
            rayR = 30
            rayLen = 3.5
            spin = 0
            glowA = 0.18
        case .startled:
            sx = 0.97
            sy = 1.05
            rayR = 36
            rayLen = 7
            glowA = 0.5
        case .fleeing:
            fdx = 3
            stream = 1
            rayLen = 7.5
        case .dizzy:
            tilt = 0.12 * sin(t)
            spin = f.phase * 2 * .pi / 5
        }
        k.with(about(50, 50, rot: tilt, sx: sx, sy: sy)) {
            k.glow(50, 50, 48, base, glowA)
            let n = 10
            var pts: [CGPoint] = []
            for i in 0..<n {
                let a = CGFloat(i) / CGFloat(n) * 2 * .pi + spin
                let back = max(0, -cos(a)) * stream
                let r: CGFloat = rayR + rayLen + back * 6
                let dx: CGFloat = -back * 4
                let va = a + .pi / CGFloat(n)
                for d in [-0.1, 0.1] as [CGFloat] {
                    pts.append(pt(50 + cos(a + d) * r + dx, 50 + sin(a + d) * r))
                }
                pts.append(pt(50 + cos(va) * 26, 50 + sin(va) * 26))
            }
            k.fill(smoothP(pts, t: 1), ray)
            let disc = circ(50, 50, 28)
            k.body(disc, base, shade: kawaiiMeadowWarmShade(base), depth: 0.26)
            k.shine(36, 66, 6, 3.4)
            k.face(50 + fdx, 45, spread: 10, r: 2.7)
            sunHat(f, k, v)
            k.marks(77, 77, 12)
        }
    }

    private static func sunHat(_ f: FigureFrame, _ k: KawaiiKit, _ v: Int) {
        switch v {
        case 1:
            let frame = Tone(0x9a7fc8)
            let lens = Tone(0xb59de0)
            k.fill(rrect(35, 58, 12, 8, 4), lens)
            k.fill(rrect(53, 58, 12, 8, 4), lens)
            k.stroke(line(46, 63, 54, 63), frame, 2)
            k.fill(ell(39, 63.5, 2, 1.2, 0.5), Tone.white.alpha(0.8))
            k.fill(ell(57, 63.5, 2, 1.2, 0.5), Tone.white.alpha(0.8))
        case 2:
            k.flower(68, 68, 6, Tone(0xffffff), Tone(0xffb35c))
        case 3:
            k.bow(50, 76, 5.6, Tone(0xffa9c8))
        case 4:
            let cloud = Tone(0xffffff)
            let bob = 1.2 * f.swing
            k.body(uni([circ(70, 26 + bob, 8), circ(80, 28 + bob, 9.5), circ(90, 25 + bob, 7), rrect(66, 18 + bob, 28, 9, 4.5)]), cloud, shade: Tone(0xe6e2f6), depth: 0.3)
        default:
            break
        }
    }
}
