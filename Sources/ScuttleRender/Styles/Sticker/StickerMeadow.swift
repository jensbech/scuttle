import Foundation
import CoreGraphics
import ScuttleCore

extension StickerArt {
    static func ladybird(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xf0434a), k.ink), (Tone(0xff8a2a), k.ink), (Tone(0xffd23a), k.ink),
            (Tone(0xff7fb4), Tone(0xfff4f8)), (Tone(0x3fb8ec), k.ink),
        ]
        let (shellTone, spotTone) = f.pick(looks)
        let headTone = Tone(0x2e2645)
        let e = f.energy, t = f.t
        var rot: CGFloat = 0.03 * f.swing * e
        var lift: CGFloat = 0, sy: CGFloat = 1
        var headDy: CGFloat = 0.8 * f.swing2 * e, headRot: CGFloat = 0
        var reach: CGFloat = 2.6 * e
        var antA: CGFloat = 0.25 * f.twitch, antSpread: CGFloat = 1
        var look: CGFloat = 0
        var wings = false
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sy = 0.93
            lift = -2
            headDy = -3
            headRot = -0.14
            antA = -0.55
            reach = 0.4
        case .startled:
            sy = 1.05
            lift = 4
            antSpread = 0.4
        case .fleeing:
            wings = true
            reach = 4.5
            look = 1
            antA = -0.8
            rot = 0.04 * f.swing - 0.03
        case .dizzy:
            rot = 0.12 * sin(t)
        }
        for i in 0..<3 {
            let ph = t + CGFloat(i) * 2.1
            let hx: CGFloat = 26 + 15 * CGFloat(i)
            let hy: CGFloat = 13 + lift
            let fx = hx + 3 + reach * sin(ph)
            let fy: CGFloat = 5 + max(0, cos(ph)) * 2.2 * min(e, 1.3)
            k.stroke(smooth([hx, hy, hx + 4, hy - 3, fx, fy], closed: false), k.ink, k.line * 1.5)
        }
        k.with(about(44, 6, rot: rot, sy: sy).translatedBy(x: 0, y: lift)) {
            if wings {
                let flap: CGFloat = f.frameIndex % 2 == 0 ? 0.22 : -0.12
                let wingT = Tone(0xdcefff), wingS = Tone(0xb4d2f2)
                k.with(about(36, 44, rot: flap)) {
                    k.part(ell(22, 62, 19, 6.5, 0.85), wingT, shadow: wingS, shape: ell(26, 56, 20, 5, 0.85))
                    k.stroke(line(34, 46, 16, 66), wingS.dim(0.85), k.thin * 0.7)
                }
                k.with(about(36, 44, rot: -flap * 0.6)) {
                    k.part(ell(16, 50, 19, 6.5, 0.3), wingT, shadow: wingS, shape: ell(18, 44, 20, 5, 0.3))
                    k.stroke(line(32, 46, 10, 52), wingS.dim(0.85), k.thin * 0.7)
                }
            }
            let shell = ell(40, 31, 28, 22)
            k.fill(shell, shellTone)
            k.clip(shell) {
                for s in ladybirdSpots(f.variant) {
                    if f.variant % 5 == 3 {
                        k.fill(heart(s.x, s.y, s.r * 2.1), spotTone)
                    } else {
                        k.fill(circ(s.x, s.y, s.r), spotTone)
                    }
                }
                k.fill(ell(44, 6, 40, 15), k.shade(shellTone).alpha(0.9))
            }
            k.stroke(smooth([62, 46, 44, 49, 26, 45, 13, 33], closed: false), k.ink, k.line)
            k.stroke(shell, k.ink, k.line)
            k.gloss(26, 44, 3, 5.5, -0.9)
            k.with(about(62, 14, rot: headRot).translatedBy(x: 0, y: headDy)) {
                let antBase: [(CGFloat, CGFloat, CGFloat)] = [(67, 41, -0.4), (78, 41, 0.35)]
                for (bx, by, a0) in antBase {
                    let a = a0 * antSpread + antA
                    let tx = bx + 13 * sin(a), ty = by + 13 * cos(a)
                    k.stroke(smooth([bx, by, bx + 5 * sin(a * 0.5), by + 7, tx, ty], closed: false), k.ink, k.line * 1.1)
                    k.flat(circ(tx, ty, 3.2), headTone)
                }
                let head = circ(72, 26, 18)
                k.part(head, headTone, shadow: Tone(0x1f1a33), shape: ell(88, 16, 14, 22))
                stickerMeadowBlob(k, [circ(68.5, 29, 7.6), circ(81.5, 29, 7.6), ell(75, 21, 10.5, 6.8)], Tone(0xfff4e2), nil, w: k.thin)
                k.face(75 + look * 1.5, 29.5, spread: 6.5, rx: 4.5, ry: 6, look: look)
                ladybirdHat(f, k)
            }
            k.marks(86, 50, 12)
        }
    }

    private static func ladybirdSpots(_ variant: Int) -> [(x: CGFloat, y: CGFloat, r: CGFloat)] {
        if variant % 5 == 4 {
            return [(24, 36, 4.2), (40, 42, 4.6), (54, 33, 4), (34, 22, 4.4), (18, 22, 3.5), (52, 18, 3.6)]
        }
        return [(26, 38, 5), (44, 43, 4.6), (58, 32, 4.4), (36, 22, 5.2), (18, 24, 4), (54, 17, 3.8)]
    }

    private static func ladybirdHat(_ f: FigureFrame, _ k: StickerKit) {
        switch f.variant % 5 {
        case 1:
            stickerMeadowDaisy(k, 62, 41, 9.5, Tone.white)
        case 2:
            stickerMeadowBow(k, 82, 43, 8.5, Tone(0xff5f9e), 0.2)
        case 4:
            stickerMeadowLeaf(k, 72, 46, 14, 0.35, Tone(0x6fd36a))
        default:
            break
        }
    }

    static func bumblebee(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [Tone] = [Tone(0xffcc33), Tone(0xffa62b), Tone(0xfff06a), Tone(0xffb3a7), Tone(0xffd84a)]
        let body = f.pick(looks)
        let stripe = Tone(0x2c2342)
        let wingTone = Tone(0xe9f7ff), wingShadow = Tone(0xbcdcf3)
        let fi = f.frameIndex
        let buzz: [CGFloat] = [0.55, -0.1, 0.25]
        var wingA: CGFloat = buzz[fi % 3]
        var rot: CGFloat = 0, sx: CGFloat = 1, sy: CGFloat = 1
        var antA: CGFloat = 0.25 * f.twitch, look: CGFloat = 0
        var legA: CGFloat = 0.15 * f.swing
        var dy: CGFloat = 1.2 * f.swing2
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            wingA = -0.5 + 0.06 * f.swing
            sy = 0.94
            sx = 1.04
            rot = -0.08
            antA = -0.6
            legA = 0.1
            dy = -2
        case .startled:
            wingA = 0.9 + (fi % 2 == 0 ? 0.18 : 0)
            sy = 1.06
            sx = 0.96
            antA = 0.1
            legA = 0.7
        case .fleeing:
            wingA = (fi % 2 == 0 ? -0.35 : 0.05)
            rot = -0.14
            look = 1
            antA = -0.7
            legA = -0.8
        case .dizzy:
            rot = 0.12 * sin(f.t)
            legA = 0.4 * f.swing
        }
        k.with(about(46, 46, rot: rot, sx: sx, sy: sy).translatedBy(x: 0, y: dy)) {
            for i in 0..<3 {
                let hx: CGFloat = 36 + 11 * CGFloat(i)
                let tip = hx - 2 + legA * 6 + CGFloat(i) * 0.5
                k.stroke(smooth([hx, 26, hx - 1, 20, tip, 15], closed: false), k.ink, k.line * 1.3)
            }
            if f.variant % 5 == 4 {
                bumblebeePot(k, 58 + legA * 5, 12)
            }
            k.fs(poly([19, 50, 7, 45, 19, 40]), stripe, k.ink, k.thin)
            k.with(about(34, 64, rot: wingA * 0.9 + 0.15)) {
                k.part(ell(29, 78, 8, 13.5, 0.25), wingTone.dim(0.92), shadow: wingShadow, shape: ell(38, 72, 8, 16))
            }
            let shellP = ell(46, 46, 30, 24)
            k.fill(shellP, body)
            k.clip(shellP) {
                k.fill(ell(27, 46, 4.6, 30), stripe)
                k.fill(ell(41, 46, 4.6, 30), stripe)
                k.fill(rrect(0, 10, 18, 80, 0), stripe)
                k.fill(ell(50, 18, 42, 13), stickerMeadowShade(k, body))
            }
            k.stroke(shellP, k.ink, k.line)
            k.gloss(52, 63, 2.8, 4.6, -1.0)
            k.with(about(40, 66, rot: wingA)) {
                k.part(ell(37, 80, 9.5, 15, 0.1), wingTone, shadow: wingShadow, shape: ell(47, 74, 8, 18))
            }
            bumblebeeHat(f, k)
            let antBase: [(CGFloat, CGFloat, CGFloat)] = [(61, 67, -0.2), (69, 64, 0.4)]
            for (bx, by, a0) in antBase {
                let a = a0 + antA
                let tx = bx + 12 * sin(a), ty = by + 12 * cos(a)
                k.stroke(smooth([bx, by, bx + 4 * sin(a * 0.5), by + 6, tx, ty], closed: false), k.ink, k.line * 1.1)
                k.flat(circ(tx, ty, 3), stripe)
            }
            k.face(61 + look * 2, 49, spread: 6.5, rx: 4.4, ry: 5.8, look: look)
            k.marks(78, 72, 12)
        }
    }

    private static func bumblebeePot(_ k: StickerKit, _ x: CGFloat, _ y: CGFloat) {
        k.stroke(line(x - 4, y + 6, x - 6, y + 12), k.ink, k.line)
        k.part(smooth([x - 7, y + 6, x + 7, y + 6, x + 8, y - 2, x, y - 7, x - 8, y - 2]), Tone(0xffb52e))
        k.flat(rrect(x - 8, y + 4, 16, 4.5, 2.2), Tone(0xff7f50), w: k.thin)
    }

    private static func bumblebeeHat(_ f: FigureFrame, _ k: StickerKit) {
        switch f.variant % 5 {
        case 1:
            stickerMeadowDaisy(k, 56, 70, 9.5, Tone.white)
        case 2:
            stickerMeadowBow(k, 55, 71, 10, Tone(0xff5f9e), 0.15)
        case 3:
            stickerMeadowCrown(k, 55, 67, 21, 13, 0.12)
        default:
            break
        }
    }

    static func snail(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xe8873a), Tone(0xf6d49c)), (Tone(0xff8fb8), Tone(0xf9dcc4)), (Tone(0x5fa8ff), Tone(0xd4eec4)),
            (Tone(0xa77bff), Tone(0xf6d49c)), (Tone(0x4fcf8f), Tone(0xf3e0b8)),
        ]
        let (shellTone, skin) = f.pick(looks)
        let e = f.energy, t = f.t
        var stretch: CGFloat = 1 + 0.07 * f.swing * e
        var headX: CGFloat = 0, headY: CGFloat = 0.8 * f.sway * e
        var stalkA: CGFloat = 0.18 * f.twitch, stalkLen: CGFloat = 13, stalkSpread: CGFloat = 1
        var shellRot: CGFloat = -0.04 * f.swing * e, shellLift: CGFloat = 0
        var look: CGFloat = 0, rot: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            stretch = 0.9
            headX = -5
            headY = -7
            stalkLen = 7
            stalkA = 0.5
            shellRot = 0.03
        case .startled:
            stretch = 1
            headY = 7
            stalkLen = 17
            stalkSpread = 0.45
            shellLift = 3
        case .fleeing:
            stretch = 1.14 + 0.05 * f.swing
            stalkA = -0.8
            stalkLen = 15
            shellRot = 0.14
            look = 1
        case .dizzy:
            rot = 0.12 * sin(t)
        }
        k.with(about(50, 5, rot: rot)) {
            let front = 6 + 76 * stretch
            let hx = front + headX, hy = 34 + headY
            let footP = rrect(6, 4, front - 6 + 8, 13, 6.5)
            let neck = poly([front - 22, 9, front + 6, 9, hx + 11, hy - 2, hx - 13, hy - 2])
            let bodyParts = [footP, neck, circ(hx, hy, 16)]
            let antBase: [(CGFloat, CGFloat, CGFloat)] = [(hx - 5, hy + 13, -0.35), (hx + 5, hy + 13, 0.3)]
            for (bx, by, a0) in antBase {
                let a = a0 * stalkSpread + stalkA
                let tx = bx + stalkLen * sin(a), ty = by + stalkLen * cos(a)
                let st = smooth([bx, by, bx + 3 * sin(a * 0.5), by + stalkLen * 0.5, tx, ty], closed: false)
                k.stroke(st, k.ink, k.line * 2.6)
                k.stroke(st, skin, k.line * 0.9)
                k.flat(circ(tx, ty, 3.4), skin)
            }
            stickerMeadowBlob(k, bodyParts, skin, (k.shade(skin), ell(50, 0, 60, 10)))
            k.gloss(hx - 7, hy + 7, 2.2, 3.6, -0.7)
            let cx = 6 + 34 * stretch, cy: CGFloat = 33 + shellLift
            k.with(about(cx, 12, rot: shellRot)) {
                let shell = circ(cx, cy, 21)
                k.fill(shell, shellTone)
                k.clip(shell) {
                    if f.variant % 5 == 3 {
                        for (dx, dy) in [(-11, 9), (8, 12), (12, -6), (-6, -12), (-14, -3)] as [(CGFloat, CGFloat)] {
                            k.fill(star(cx + dx, cy + dy, 3.2), Tone(0xfff0a8))
                        }
                    }
                    k.fill(ell(cx + 18, cy - 14, 18, 22), k.shade(shellTone))
                }
                k.stroke(spiral(cx + 1, cy - 1, 15, turns: 2.1, spin: -1, start: 0.6 + (f.mood == .dizzy ? t : 0)), k.ink, k.line)
                k.stroke(shell, k.ink, k.line)
                k.gloss(cx - 11, cy + 11, 3, 5, -0.8)
                if f.variant % 5 == 1 {
                    stickerMeadowDaisy(k, cx + 4, cy + 20, 10, Tone.white)
                }
            }
            k.face(hx + 2 + look * 2, hy + 1, spread: 5.8, rx: 4.1, ry: 5.4, look: look)
            switch f.variant % 5 {
            case 2:
                let a = 0.3 * stalkSpread + stalkA
                stickerMeadowBow(k, hx + 5 + stalkLen * 0.55 * sin(a), hy + 13 + stalkLen * 0.55 * cos(a), 7.5, Tone(0xff5f9e))
            case 4:
                stickerMeadowLeaf(k, hx - 1, hy + 15, 13, 0.3, Tone(0x8fd65a))
            default:
                break
            }
            k.marks(hx + 12, hy + 24, 12)
        }
    }

    static func chick(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [Tone] = [Tone(0xffd84a), Tone(0xffd84a), Tone(0xfff07a), Tone(0xffb347), Tone(0xffe38a)]
        let body = f.pick(looks)
        let orange = Tone(0xff9a2b)
        let v = f.variant % 5
        var sy: CGFloat = 1 - 0.16 * f.squat + 0.1 * f.stretch
        var sx: CGFloat = 1 + 0.1 * f.squat - 0.05 * f.stretch
        var wingA: CGFloat = f.airborne ? 0.5 + 0.6 * sin(f.air * .pi * 2) : 0.15 * f.twitch
        var tuft: CGFloat = 0.15 * f.twitch, tuftS: CGFloat = 1
        var beak: CGFloat = 0, rot: CGFloat = 0, look: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sy *= 0.92
            sx *= 1.05
            wingA = -0.2
            tuft = -0.6
        case .startled:
            sy *= 1.08
            sx *= 0.96
            wingA = 1.3 + 0.1 * f.swing2
            tuftS = 1.35
            beak = 1
        case .fleeing:
            rot = -0.1
            wingA = 0.7 + 0.6 * f.swing2
            tuft = 0.8
            beak = 0.6
            look = 1
        case .dizzy:
            rot = 0.12 * sin(f.t)
            wingA = 0.4 * f.swing
        }
        if v != 4 {
            k.flat(ell(41, 6, 8, 3.6), orange)
            k.flat(ell(61, 6, 8, 3.6), orange)
        }
        k.with(about(50, 4, rot: rot, sx: sx, sy: sy)) {
            k.both { s in
                k.with(about(50 + s * 24, 44, rot: s * wingA)) {
                    k.part(ell(50 + s * 27, 35, 6.5, 11, s * 0.35), body, shadow: stickerMeadowShade(k, body), shape: ell(50 + s * 27, 26, 9, 8))
                }
            }
            if v != 1 {
                k.with(about(50, 62, rot: tuft, sx: tuftS, sy: tuftS)) {
                    k.flat(ell(45, 70, 3.2, 6.5, 0.5), body)
                    k.flat(ell(52, 72, 3.4, 7.5, -0.05), body)
                    k.flat(ell(58, 69, 3, 6, -0.6), body)
                }
            }
            let b = ell(50, 37, 29, 30)
            k.part(b, body, shadow: stickerMeadowShade(k, body), shape: ell(82, 24, 20, 32))
            k.gloss(33, 54, 3.4, 6, -0.6)
            if v == 4 {
                chickShellPants(k)
            }
            k.face(56 + look * 2, 47, spread: 8, rx: 4.8, ry: 6.2, mouth: .none, look: look)
            let bx: CGFloat = 57 + look * 2, by: CGFloat = 37
            let o = beak * 3
            if o > 0 {
                k.fill(poly([bx - 5, by - 1 - o, bx + 5, by - 2 - o, bx - 5, by + 1]), Tone(0xb3302f))
                k.flat(poly([bx - 5, by - 1 - o, bx + 4, by - 2.5 - o * 0.8, bx - 5, by - 4 - o]), orange, w: k.thin)
            }
            k.flat(poly([bx - 5.5, by + 3.5, bx + 6.5, by, bx - 5.5, by - 2.5]), orange, w: k.thin)
            switch v {
            case 1:
                chickEggHat(k)
            case 2:
                stickerMeadowBow(k, 63, 65, 9, Tone(0xff5f9e), -0.2)
            case 3:
                stickerMeadowDaisy(k, 37, 62, 10, Tone.white)
            default:
                break
            }
            k.marks(80, 68, 12)
        }
    }

    private static func chickEggHat(_ k: StickerKit) {
        let p = CGMutablePath()
        p.move(to: pt(31, 60))
        let n = 7
        for i in 1...n {
            let x = 31 + 38 * CGFloat(i) / CGFloat(n)
            p.addLine(to: pt(x, i % 2 == 1 ? 55 : 60))
        }
        p.addCurve(to: pt(31, 60), control1: pt(72, 88), control2: pt(28, 88))
        p.closeSubpath()
        k.part(p, Tone(0xfffaf0), shadow: Tone(0xe8dcc8), shape: ell(70, 58, 14, 18))
        k.gloss(41, 72, 2.4, 4, -0.7)
    }

    private static func chickShellPants(_ k: StickerKit) {
        let p = CGMutablePath()
        p.move(to: pt(20, 26))
        let n = 8
        for i in 1...n {
            let x = 20 + 60 * CGFloat(i) / CGFloat(n)
            p.addLine(to: pt(x, i % 2 == 1 ? 31 : 26))
        }
        p.addCurve(to: pt(20, 26), control1: pt(84, -2), control2: pt(16, -2))
        p.closeSubpath()
        k.part(p, Tone(0xfffaf0), shadow: Tone(0xe8dcc8), shape: ell(78, 8, 22, 18))
    }

    static func butterfly(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone, Tone, Tone, Tone, Tone)] = [
            (Tone(0xffb52e), Tone(0xff6b81), Tone(0xfff3c4), Tone(0xffd3da), Tone(0x6b48c4), Tone(0x8462e6)),
            (Tone(0x4fb3ff), Tone(0xb48cff), Tone(0xdff3ff), Tone(0xefe2ff), Tone(0x3b4fa8), Tone(0x5a74e8)),
            (Tone(0x7fd65a), Tone(0xffe14a), Tone(0xe9ffd0), Tone(0xfff7c4), Tone(0x2f8a5a), Tone(0x45b07a)),
            (Tone(0xff7fb4), Tone(0xffb38a), Tone(0xffe0ef), Tone(0xffe8d8), Tone(0xb0408a), Tone(0xd860a8)),
            (Tone(0xff8a1f), Tone(0xffc23a), Tone(0xfff6e0), Tone(0xfff6e0), Tone(0x3a2f55), Tone(0x5a4a80)),
        ]
        let (up, low, spotUp, spotLow, bodyTone, headTone) = f.pick(looks)
        let v = f.variant % 5
        var open: CGFloat = 0.67 + 0.33 * f.swing
        var rot: CGFloat = 0, sy: CGFloat = 1, look: CGFloat = 0
        var antTip = (x: CGFloat(34) + 2 * f.twitch, y: CGFloat(92))
        var antSweep: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            open = 0.5 + 0.03 * f.swing
            sy = 0.95
            antTip = (38, 83)
        case .startled:
            open = 1.04 + 0.04 * f.swing2
            sy = 1.04
            antTip = (36, 97)
        case .fleeing:
            open = 0.62 + 0.38 * f.swing
            rot = -0.18
            look = 1
            antSweep = -7
        case .dizzy:
            open = 0.6 + 0.3 * f.swing
            rot = 0.12 * sin(f.t)
        }
        k.with(about(50, 40, rot: rot, sy: sy)) {
            k.both { s in
                let tipX = s < 0 ? antTip.x + antSweep : 100 - antTip.x + antSweep
                let a = smooth([50 + s * 3, 74, 50 + s * 7, 86, tipX, antTip.y], closed: false)
                k.stroke(a, k.ink, k.line)
                k.flat(circ(tipX, antTip.y, 3.8), low, w: k.thin)
            }
            let fold = about(50, 50, sx: open)
            k.both { s in
                let m: (CGPath) -> CGPath = { p in xf(s > 0 ? mirror(p) : p, fold) }
                let lw = m(smooth([47, 44, 44, 30, 32, 16, 18, 16, 12, 28, 22, 42]))
                k.fill(lw, low)
                k.clip(lw) { k.fill(m(ell(48, 22, 16, 14)), k.shade(low)) }
                k.stroke(lw, k.ink, k.line)
                butterflySpot(k, m, 26, 27, 4.2, spotLow, heartSpot: v == 3)
                let uw = m(smooth([47, 52, 40, 70, 24, 86, 9, 82, 6, 64, 16, 50, 34, 46]))
                k.fill(uw, up)
                k.clip(uw) { k.fill(m(ell(52, 54, 14, 26)), stickerMeadowShade(k, up)) }
                k.stroke(uw, k.ink, k.line)
                butterflySpot(k, m, 21, 69, 6.5, spotUp, heartSpot: v == 3)
                if v == 4 {
                    k.fill(m(circ(13, 77, 1.8)), Tone.white)
                    k.fill(m(circ(10, 68, 1.6)), Tone.white)
                }
            }
            k.part(rrect(43.5, 18, 13, 40, 6.5), bodyTone, shape: ell(60, 30, 7, 26))
            k.part(circ(50, 64, 14), headTone, shape: ell(68, 56, 10, 15))
            k.gloss(42.5, 72, 2, 3.4, -0.7)
            k.face(50 + look * 2, 66, spread: 5.4, rx: 4.3, ry: 5.7, look: look)
            switch v {
            case 1:
                stickerMeadowBow(k, 61, 75, 7.5, Tone(0xff5f9e), -0.35)
            case 2:
                stickerMeadowDaisy(k, 60, 76, 8.5, Tone.white)
            case 4:
                stickerMeadowCrown(k, 50, 76, 15, 9, 0)
            default:
                break
            }
            k.marks(66, 80, 12)
        }
    }

    private static func butterflySpot(_ k: StickerKit, _ m: (CGPath) -> CGPath, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ tone: Tone, heartSpot: Bool) {
        if heartSpot {
            k.fs(m(heart(x, y + r * 0.25, r * 2.2)), tone, k.ink, k.thin)
        } else {
            k.fs(m(circ(x, y, r)), tone, k.ink, k.thin)
        }
    }

    static func dragonfly(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [Tone] = [Tone(0x3fb6ff), Tone(0x5fd36a), Tone(0xff5a6a), Tone(0xa070ff), Tone(0xffc23a)]
        let body = f.pick(looks)
        let v = f.variant % 5
        let wingTone = Tone(0xeef9ff).mix(body, 0.12), wingShadow = Tone(0xc4e2f5).mix(body, 0.18)
        let fi = f.frameIndex
        let buzz: CGFloat = fi % 2 == 0 ? 0.3 : -0.25
        var wingBase: CGFloat = 1.75 + buzz, wingSpread: CGFloat = 0.55
        var curl: CGFloat = 2.5 * f.twitch
        var rot: CGFloat = 0, sy: CGFloat = 1, look: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            wingBase = 2.75 + 0.03 * f.swing
            wingSpread = 0.2
            curl = -6
            rot = -0.05
        case .startled:
            wingBase = 1.45 + buzz * 0.5
            wingSpread = 0.35
            curl = 10
            sy = 1.04
        case .fleeing:
            wingBase = 2.35 + buzz * 0.7
            wingSpread = 0.3
            curl = 0
            look = 1
        case .dizzy:
            rot = 0.12 * sin(f.t)
            curl = 5 * f.swing
        }
        k.with(about(50, 50, rot: rot, sy: sy)) {
            let roots: [CGFloat] = [56, 62]
            for far in [true, false] {
                if !far {
                    dragonflyBody(f, k, body, curl: curl)
                }
                for (i, rx) in roots.enumerated() {
                    let a = wingBase + (i == 0 ? wingSpread : 0) + (far ? 0.2 : 0)
                    let len: CGFloat = i == 0 ? 22 : 20
                    let cx = rx + cos(a) * len, cy = 56 + sin(a) * len
                    let wp = ell(cx, cy, len, 6.5, a)
                    let tone = far ? wingTone.dim(0.9) : wingTone
                    let sh = far ? wingShadow.dim(0.9) : wingShadow
                    k.part(wp, tone, shadow: sh, shape: ell(cx + sin(a) * 6, cy - cos(a) * 6, len * 1.2, 5, a))
                }
            }
            if v == 3 {
                let wave: CGFloat = 3 * sin(f.t * 2)
                k.part(smooth([66, 47, 52, 45 + wave, 36, 49 + wave * 1.5, 40, 40 + wave, 54, 37, 67, 40]), Tone(0xff5f7e), shape: ell(50, 34, 22, 7))
                k.part(ell(66, 45, 5.5, 10, -0.2), Tone(0xff5f7e), shape: ell(71, 38, 5, 6))
            }
            let head = circ(79, 52, 16)
            k.part(head, body.lift(0.12), shadow: stickerMeadowShade(k, body.lift(0.12)), shape: ell(96, 42, 10, 18))
            k.gloss(70, 61, 2.4, 4, -0.7)
            k.face(82 + look * 2, 50, spread: 6.2, rx: 4.8, ry: 6.4, look: look)
            switch v {
            case 1:
                let band = smooth([64, 60, 79, 66, 94, 60], closed: false)
                k.stroke(band, k.ink, k.line * 2.4)
                k.stroke(band, Tone(0x9a6a44), k.line)
                k.flat(circ(73, 66, 5.4), Tone(0xa8e6ff))
                k.flat(circ(86, 66, 5.4), Tone(0xa8e6ff))
                k.gloss(71.5, 67.5, 1.4, 2.4, -0.7)
                k.gloss(84.5, 67.5, 1.4, 2.4, -0.7)
            case 2:
                stickerMeadowBow(k, 86, 67, 8.5, Tone(0xffd84a), -0.3)
            case 4:
                stickerMeadowCone(k, 80, 66, 14, 17, -0.2, Tone(0x7a5cc8), Tone(0xff7fb0))
            default:
                break
            }
            k.marks(94, 72, 12)
        }
    }

    private static func dragonflyBody(_ f: FigureFrame, _ k: StickerKit, _ body: Tone, curl: CGFloat) {
        let n = 6
        var top: [CGFloat] = [], bot: [CGFloat] = []
        for i in 0...n {
            let u = CGFloat(i) / CGFloat(n)
            let x = 58 - 48 * u
            let half = 6.4 - 2.6 * u
            let y = 49 + curl * u * u
            top += [x, y + half]
            bot = [x, y - half] + bot
        }
        let tipY = 49 + curl
        let pts = top + [6, tipY] + bot
        let tail = smooth(pts, t: 0.8)
        let sh = stickerMeadowShade(k, body)
        k.fill(tail, body)
        k.clip(tail) {
            k.fill(moved(tail, 1, -4.4), sh)
            for i in 1...3 {
                let u = CGFloat(i) / 4
                let x = 58 - 48 * u
                let y = 49 + curl * u * u
                k.stroke(line(x, y - 9, x + 1, y + 9), sh.dim(0.85), k.thin)
            }
        }
        k.stroke(tail, k.ink, k.line)
        for i in 0..<3 {
            let lx: CGFloat = 58 + 5 * CGFloat(i)
            k.stroke(smooth([lx, 44, lx + 1, 38, lx + 3, 35], closed: false), k.ink, k.line * 1.1)
        }
        k.part(ell(62, 49, 10, 9), body, shadow: sh, shape: ell(66, 39, 10, 6))
    }

    static func firefly(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xc6ff3a), Tone(0x4b4f96)), (Tone(0xffc928), Tone(0x5a3f8f)), (Tone(0xff6fc8), Tone(0x3f5a8f)),
            (Tone(0x4fe8ff), Tone(0x4b4f96)), (Tone(0x7dffa8), Tone(0x5a4a7a)),
        ]
        let (lamp, shellTone) = f.pick(looks)
        let headTone = Tone(0xff9a4a)
        let v = f.variant % 5
        let fi = f.frameIndex
        let buzz: [CGFloat] = [0.5, -0.1, 0.25]
        var glow: CGFloat = 0.5 + 0.5 * sin(f.t)
        var rays = 3
        var wingA: CGFloat = buzz[fi % 3]
        var rot: CGFloat = 0, sy: CGFloat = 1, look: CGFloat = 0
        var antA: CGFloat = 0.25 * f.twitch, headDrop: CGFloat = 0
        var dy: CGFloat = 1.2 * f.swing2
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            glow = 0.12 + 0.08 * f.swing
            rays = 0
            wingA = -0.45
            antA = -0.6
            headDrop = -3
            rot = -0.06
            dy = -2
        case .startled:
            glow = 1
            rays = 5
            wingA = 0.85 + (fi % 2 == 0 ? 0.15 : 0)
            antA = 0
            sy = 1.06
        case .fleeing:
            glow = fi % 2 == 0 ? 1 : 0.45
            wingA = fi % 2 == 0 ? -0.35 : 0.05
            rot = -0.14
            look = 1
            antA = -0.7
        case .dizzy:
            rot = 0.12 * sin(f.t)
        }
        let lit = lamp.mix(Tone.white, 0.3 * glow).dim(0.62 + 0.38 * glow)
        k.with(about(46, 46, rot: rot, sy: sy).translatedBy(x: 0, y: dy)) {
            if glow > 0.45 && rays > 0 {
                for i in 0..<rays {
                    let a: CGFloat = 2.3 + CGFloat(i) * (1.8 / CGFloat(max(1, rays - 1)))
                    let r0: CGFloat = 19.5, r1: CGFloat = 20 + 6 * glow
                    let ray = line(22 + cos(a) * r0, 41 + sin(a) * r0, 22 + cos(a) * r1, 41 + sin(a) * r1)
                    k.stroke(ray, k.ink, k.line * 2.5)
                    k.stroke(ray, lit, k.line * 1.0)
                }
            }
            for i in 0..<3 {
                let hx: CGFloat = 38 + 9 * CGFloat(i)
                k.stroke(smooth([hx, 34, hx - 1, 28, hx - 3 - 2 * sin(f.t + CGFloat(i)), 24], closed: false), k.ink, k.line * 1.2)
            }
            k.with(about(40, 60, rot: wingA * 0.9 + 0.2)) {
                k.part(ell(35, 72, 7, 12, 0.3), Tone(0xe9f2ff).dim(0.92), shadow: Tone(0xbccaf0), shape: ell(43, 66, 7, 14))
            }
            let lantern = ell(22, 41, 15.5, 14)
            k.part(lantern, lit, shadow: lit.dim(0.84), shape: ell(28, 27, 14, 9))
            k.gloss(16, 47, 3, 4.6, -0.8)
            let shell = ell(44, 47, 19, 15.5)
            k.part(shell, shellTone, shape: ell(48, 30, 24, 10))
            k.stroke(arc(30, 57, 58, 57, dip: 4), k.ink, k.thin)
            k.with(about(58, 44, rot: wingA)) {
                k.part(ell(46, 72, 8, 13, 0.15), Tone(0xeef5ff), shadow: Tone(0xc4d2f5), shape: ell(55, 66, 7, 15))
            }
            k.with(about(58, 40, rot: headDrop * 0.03).translatedBy(x: 0, y: headDrop)) {
                let antBase: [(CGFloat, CGFloat, CGFloat)] = [(62, 63, -0.3), (71, 63, 0.35)]
                for (bx, by, a0) in antBase {
                    let a = a0 + antA
                    let tx = bx + 12 * sin(a), ty = by + 12 * cos(a)
                    k.stroke(smooth([bx, by, bx + 4 * sin(a * 0.5), by + 6, tx, ty], closed: false), k.ink, k.line * 1.1)
                    k.flat(circ(tx, ty, 2.8), shellTone)
                }
                k.part(circ(67, 49, 15.5), headTone, shape: ell(82, 40, 10, 16))
                k.gloss(59, 57, 2.2, 3.6, -0.7)
                k.face(69 + look * 2, 50, spread: 5.6, rx: 4.3, ry: 5.7, look: look)
                switch v {
                case 1:
                    stickerMeadowBow(k, 75, 64, 8.5, Tone(0xff5f9e), -0.25)
                case 2:
                    stickerMeadowDaisy(k, 59, 63, 9.5, Tone.white)
                case 3:
                    fireflyCap(k)
                case 4:
                    stickerMeadowLeaf(k, 67, 66, 14, 0.3, Tone(0x6fd36a))
                default:
                    break
                }
                k.marks(83, 70, 12)
            }
        }
    }

    private static func fireflyCap(_ k: StickerKit) {
        let cap = smooth([53, 58, 81, 58, 76, 69, 62, 72, 46, 74], t: 0.6)
        k.part(cap, Tone(0x5f7cff), shape: ell(74, 60, 10, 6))
        k.flat(rrect(52, 56, 30, 5, 2.5), Tone(0xf4f1ff), w: k.thin)
        k.flat(circ(45, 74, 3.6), Tone(0xf4f1ff), w: k.thin)
    }

    static func crab(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [Tone] = [Tone(0xff5a4a), Tone(0xff9a3c), Tone(0xff86b0), Tone(0x7a7cff), Tone(0x3fcab8)]
        let shellTone = f.pick(looks)
        let v = f.variant % 5
        let e = f.energy, t = f.t
        var bodyY: CGFloat = 0, sway: CGFloat = 1.6 * f.swing * e
        var clawX: CGFloat = 37, clawY: CGFloat = 44, clawOpen: CGFloat = 0.35 + 0.2 * max(0, f.twitch)
        var stalkH: CGFloat = 14, stalkLean: CGFloat = 0
        var look: CGFloat = 0, rot: CGFloat = 0
        var clawWave: CGFloat = 0
        switch f.mood {
        case .calm:
            clawOpen += 0.15 * sin(2 * t)
        case .sleepy:
            bodyY = -2
            clawX = 33
            clawY = 18
            clawOpen = 0.08
            stalkH = 9
            stalkLean = 4
        case .startled:
            bodyY = 3
            clawX = 40
            clawY = 64
            clawOpen = 0.65
            stalkH = 19
        case .fleeing:
            clawX = 28
            clawY = 66
            clawWave = 4
            clawOpen = 0.3 + 0.3 * sin(4 * t)
            stalkLean = -2
            look = 1
        case .dizzy:
            rot = 0.12 * sin(t)
            stalkLean = 4 * sin(t)
        }
        for i in 0..<3 {
            k.both { s in
                let ph = t + CGFloat(i) * 2.1 + (s > 0 ? .pi : 0)
                let hx = 50 + sway + s * (15 + 4 * CGFloat(i))
                let hy: CGFloat = 20 + bodyY - 3 * CGFloat(i)
                let kx = 50 + sway + s * (30 + 3 * CGFloat(i)) + 1.5 * cos(ph) * e
                let ky = 19 + bodyY - 2 * CGFloat(i) + max(0, sin(ph)) * 2.5 * min(e, 1.3)
                let fx = 50 + sway * 0.5 + s * (34 + 2.5 * CGFloat(i)) + 2 * cos(ph) * e
                let fy: CGFloat = 5 + max(0, sin(ph)) * 3 * min(e, 1.3)
                crabLimb(k, smooth([hx, hy, kx, ky, fx, fy], closed: false), shellTone, 3.6)
            }
        }
        k.with(about(50, 6, rot: rot).translatedBy(x: sway, y: bodyY)) {
            k.both { s in
                let wave = clawWave * sin(2 * t + (s > 0 ? 1.5 : 0))
                let cx = 50 + s * clawX, cy = clawY + wave
                crabLimb(k, smooth([50 + s * 22, 30, 50 + s * (clawX - 4), (30 + cy) / 2 - 2, cx, cy - 6], closed: false), shellTone, 4.2)
                let dir: CGFloat = .pi / 2 - s * 0.45
                let c = pt(cx, cy + 1)
                let wedge = poly([c.x, c.y, c.x + cos(dir - clawOpen) * 16, c.y + sin(dir - clawOpen) * 16, c.x + cos(dir + clawOpen) * 16, c.y + sin(dir + clawOpen) * 16])
                let claw = clawOpen > 0.1 ? minus(ell(cx, cy, 9.5, 10.5, -s * 0.3), wedge) : ell(cx, cy, 9.5, 10.5, -s * 0.3)
                k.part(claw, shellTone, shape: ell(cx + 6, cy - 7, 8, 7))
                if clawOpen <= 0.1 {
                    k.stroke(line(cx, cy + 1, cx + cos(dir) * 10, cy + sin(dir) * 10), k.ink, k.thin)
                }
            }
            let body = smooth([50, 47, 66, 45, 78, 36, 78, 22, 66, 11, 50, 9, 34, 11, 22, 22, 22, 36, 34, 45])
            k.part(body, shellTone, shape: ell(80, 16, 24, 22))
            k.gloss(32, 37, 2.6, 4.6, -0.8)
            k.blush(35, 25, 4, 2.2)
            k.blush(65, 25, 4, 2.2)
            k.mouth(50 + look * 2, 28, 8)
            switch v {
            case 2:
                stickerMeadowDaisy(k, 30, 40, 9.5, Tone.white)
            case 3:
                stickerMeadowBow(k, 50, 17, 8, Tone(0xffd84a))
            case 4:
                k.part(softStar(68, 40, 10, points: 5, inner: 0.5, spin: .pi / 2 + 0.2 * f.twitch, t: 0.5), Tone(0xffa63a))
            default:
                break
            }
            k.both { s in
                let bx = 50 + s * 8, by: CGFloat = 43
                let tx = 50 + s * 12 + stalkLean, ty = 45 + stalkH
                let st = line(bx, by, tx, ty - 5)
                k.stroke(st, k.ink, k.line * 2.4)
                k.stroke(st, shellTone, k.line * 0.9)
                k.fs(circ(tx, ty, 8.4), Tone.white, k.ink, k.line)
                k.eye(tx + look * 1.4, ty, 4.3, 5.6, side: s, look: look)
                if v == 1 && s > 0 {
                    crabSailorHat(k, tx, ty + 7)
                }
            }
            k.marks(74, 64, 12)
        }
    }

    private static func crabLimb(_ k: StickerKit, _ p: CGPath, _ tone: Tone, _ w: CGFloat) {
        k.stroke(p, k.ink, w + k.line * 1.6)
        k.stroke(p, tone, w)
    }

    private static func crabSailorHat(_ k: StickerKit, _ x: CGFloat, _ y: CGFloat) {
        k.with(about(x, y, rot: -0.25)) {
            k.part(smooth([x - 10, y, x + 10, y, x + 7, y + 8, x, y + 9.5, x - 7, y + 8], t: 0.6), Tone.white, shadow: Tone(0xdde4f5), shape: ell(x + 10, y + 3, 5, 8))
            k.flat(rrect(x - 11.5, y - 2.5, 23, 5, 2.5), Tone(0x3f6fe0), w: k.thin)
        }
    }

    static func frog(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [Tone] = [Tone(0x6ccf5a), Tone(0xa8e04a), Tone(0x3fc6b0), Tone(0xff9a4a), Tone(0x5fa8ff)]
        let skin = f.pick(looks)
        let belly = Tone(0xfdf5d8)
        let v = f.variant % 5
        var sy: CGFloat = 1 - 0.16 * f.squat + 0.1 * f.stretch
        var sx: CGFloat = 1 + 0.12 * f.squat - 0.05 * f.stretch
        var ext: CGFloat = f.airborne ? abs(f.stretch) : 0
        var arm: CGFloat = f.airborne ? max(0, -f.stretch) : 0
        var rot: CGFloat = 0, look: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sy *= 0.9
            sx *= 1.06
            ext = 0
            arm = 0
        case .startled:
            sy *= 1.1
            sx *= 0.95
            arm = 1.4
        case .fleeing:
            rot = -0.1
            look = 1
            ext = max(ext, 0.6)
        case .dizzy:
            rot = 0.12 * sin(f.t)
        }
        k.with(about(50, 4, rot: rot, sx: sx, sy: sy)) {
            k.both { s in
                let tx = 50 + s * lerp(26, 30, ext), ty = lerp(15, 5, ext)
                let foot = ell(50 + s * lerp(31, 39, ext), lerp(6, -5, ext), 9, 3.6, s * 0.5 * ext)
                k.flat(foot, skin.dim(0.85))
                let thigh = ell(tx, ty, lerp(12, 7.5, ext), lerp(8, 13, ext), s * lerp(0.35, 0.65, ext))
                k.part(thigh, skin, shape: ell(tx + s * 8, ty - 6, 9, 9))
            }
            let blob = smooth([50, 60, 70, 59, 80, 47, 80, 30, 72, 14, 50, 8, 28, 14, 20, 30, 20, 47, 30, 59])
            stickerMeadowBlob(k, [blob, circ(35, 60, 11.5), circ(65, 60, 11.5)], skin, (k.shade(skin), ell(86, 26, 18, 34))) {
                k.fill(ell(50, 20, 18, 14), belly)
            }
            k.gloss(27, 46, 2.6, 5, -0.5)
            if v == 4 {
                frogRainHat(k)
            }
            k.both { s in
                let hx = 50 + s * (11 + arm * 12), hy: CGFloat = 8 + arm * 22
                k.flat(ell(hx, hy, 5.5, 3.6, s * arm * 0.9), skin)
            }
            k.both { s in
                let ex = 50 + s * 15
                k.fs(circ(ex, 61, 7.6), Tone.white, k.ink, k.thin)
                k.eye(ex + look * 1.5, 61, 3.9, 5.1, side: s, look: look)
            }
            k.blush(29, 40, 4, 2.3)
            k.blush(71, 40, 4, 2.3)
            if f.mood == .calm {
                k.stroke(arc(37 + look * 2, 41, 63 + look * 2, 41, dip: 6), k.ink, k.thin * 1.1)
            } else {
                k.mouth(50 + look * 2, 41, 12)
            }
            switch v {
            case 1:
                stickerMeadowCrown(k, 50, 66, 18, 11, 0)
            case 2:
                stickerMeadowBow(k, 74, 69, 8.5, Tone(0xff5f9e), -0.3)
            case 3:
                stickerMeadowDaisy(k, 69, 71, 9.5, Tone.white)
            default:
                break
            }
            k.marks(80, 72, 12)
        }
    }

    private static func frogRainHat(_ k: StickerKit) {
        let yellow = Tone(0xffd23a)
        k.part(smooth([34, 64, 66, 64, 62, 76, 50, 79, 38, 76], t: 0.7), yellow, shape: ell(66, 66, 8, 12))
        k.flat(ell(50, 64, 24, 4), yellow.dim(0.92), w: k.thin)
    }

    static func sun(_ f: FigureFrame, _ k: StickerKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xffd84a), Tone(0xffa62b)), (Tone(0xffd23a), Tone(0xff8a2a)), (Tone(0xffc29a), Tone(0xff7f9e)),
            (Tone(0xffe15a), Tone(0xffb52e)), (Tone(0xfff07a), Tone(0xffc93c)),
        ]
        let (face, rayTone) = f.pick(looks)
        let v = f.variant % 5
        var outer: CGFloat = 44 + 1.5 * f.swing2
        var inner: CGFloat = 31
        var spin: CGFloat = .pi / 2 + 0.1 * f.swing + 0.09 * f.twitch
        var shift: CGFloat = 0, rot: CGFloat = 0, look: CGFloat = 0
        var pointy: CGFloat = 0.45
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            outer = 39
            inner = 32
            spin = .pi / 2
        case .startled:
            outer = 50
            inner = 30
            pointy = 0.15
        case .fleeing:
            shift = -6
            look = 1
            outer = 46
        case .dizzy:
            spin = .pi / 2 + f.t / 5
            rot = 0.12 * sin(f.t)
        }
        k.with(about(50, 50, rot: rot)) {
            let rays = softStar(50 + shift, 50, outer, points: 10, inner: inner / outer, spin: spin, t: pointy)
            k.part(rays, rayTone, shadow: rayTone.mix(Tone(0xe0402a), 0.25).dim(0.92), shape: ell(96, 30, 30, 40))
            let disc = circ(50, 50, 30)
            k.part(disc, face, shadow: stickerMeadowShade(k, face), shape: ell(88, 40, 21, 36))
            k.gloss(34, 66, 3.6, 6.5, -0.6)
            if v == 3 {
                sunPartyHat(k)
            }
            let shadesOn = v == 1 && f.mood == .calm
            if shadesOn {
                sunShades(k, 53, 0)
                k.blush(32, 44, 4.2, 2.4)
                k.blush(68, 44, 4.2, 2.4)
                k.mouth(51, 42, 9)
            } else {
                k.face(50 + look * 2.5, 54, spread: 9, rx: 5.2, ry: 6.9, look: look)
                if v == 1 {
                    sunShades(k, 72, 0.08)
                }
            }
            switch v {
            case 2:
                stickerMeadowDaisy(k, 71, 72, 10, Tone.white)
            case 4:
                stickerMeadowBow(k, 50, 80, 10, Tone(0xff5f9e))
            default:
                break
            }
            k.marks(80, 80, 13)
        }
    }

    private static func sunShades(_ k: StickerKit, _ y: CGFloat, _ rot: CGFloat) {
        k.with(about(50, y, rot: rot)) {
            let lens = Tone(0x2c2342)
            k.stroke(line(44, y + 1, 56, y + 1), k.ink, k.line)
            k.flat(rrect(30, y - 6, 15, 11, 5), lens)
            k.flat(rrect(55, y - 6, 15, 11, 5), lens)
            k.fill(ell(35, y + 1.5, 3, 1.6, -0.4), Tone.white.alpha(0.85))
            k.fill(ell(60, y + 1.5, 3, 1.6, -0.4), Tone.white.alpha(0.85))
        }
    }

    private static func sunPartyHat(_ k: StickerKit) {
        stickerMeadowCone(k, 50, 76, 24, 25, -0.08, Tone(0x5fd3c4), Tone(0xff7fb0))
    }

    private static func stickerMeadowBow(_ k: StickerKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ tone: Tone, _ rot: CGFloat = 0) {
        k.with(about(x, y, rot: rot)) {
            k.part(smooth([x, y, x - 1.1 * s, y + 0.7 * s, x - 1.2 * s, y - 0.5 * s], t: 0.4), tone, shape: ell(x - 0.6 * s, y - 0.9 * s, 0.9 * s, 0.6 * s))
            k.part(smooth([x, y, x + 1.1 * s, y + 0.7 * s, x + 1.2 * s, y - 0.5 * s], t: 0.4), tone, shape: ell(x + 0.6 * s, y - 0.9 * s, 0.9 * s, 0.6 * s))
            k.flat(circ(x, y, 0.32 * s), tone.dim(0.85), w: k.thin)
        }
    }

    private static func stickerMeadowDaisy(_ k: StickerKit, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ petal: Tone) {
        let petals: [CGPath] = (0..<5).map { i in
            let a = CGFloat(i) * 2 * .pi / 5 + .pi / 2
            return circ(x + cos(a) * r * 0.58, y + sin(a) * r * 0.58, r * 0.44)
        }
        for p in petals { k.stroke(p, k.ink, k.thin * 2) }
        for p in petals { k.fill(p, petal) }
        k.fs(circ(x, y, r * 0.36), Tone(0xffc93c), k.ink, k.thin * 0.8)
    }

    private static func stickerMeadowBlob(_ k: StickerKit, _ parts: [CGPath], _ base: Tone, _ shadow: (Tone, CGPath)?, w: CGFloat? = nil, inner: (() -> Void)? = nil) {
        let lw = w ?? k.line
        for p in parts { k.stroke(p, k.ink, lw * 2) }
        for p in parts { k.fill(p, base) }
        guard shadow != nil || inner != nil else { return }
        for p in parts {
            k.clip(p) {
                inner?()
                if let (tone, shape) = shadow { k.fill(shape, tone) }
            }
        }
    }

    private static func stickerMeadowShade(_ k: StickerKit, _ t: Tone) -> Tone {
        if t.r > 0.85 && t.g > 0.55 && t.b < 0.6 {
            return t.mix(Tone(0xff7a1a), 0.42).dim(0.94)
        }
        return k.shade(t)
    }

    private static func stickerMeadowCone(_ k: StickerKit, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ rot: CGFloat, _ tone: Tone, _ stripe: Tone) {
        k.with(about(x, y, rot: rot)) {
            let cone = poly([x - w / 2, y, x + w / 2, y, x + w * 0.1, y + h])
            k.fill(cone, tone)
            k.clip(cone) {
                for yy in stride(from: y + h * 0.18, to: y + h, by: h * 0.3) { k.fill(rrect(x - w, yy, 2 * w, h * 0.13, 0), stripe) }
            }
            k.stroke(cone, k.ink, k.line)
            k.flat(circ(x + w * 0.1, y + h, w * 0.17), Tone(0xffd54a), w: k.thin)
        }
    }

    private static func stickerMeadowLeaf(_ k: StickerKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ rot: CGFloat, _ tone: Tone) {
        k.with(about(x, y, rot: rot)) {
            let p = CGMutablePath()
            p.move(to: pt(x - s, y))
            p.addQuadCurve(to: pt(x + s, y), control: pt(x, y + s * 0.9))
            p.addQuadCurve(to: pt(x - s, y), control: pt(x, y - s * 0.5))
            k.part(p, tone, shape: ell(x + s * 0.4, y - s * 0.3, s * 0.8, s * 0.35))
            k.stroke(line(x - s * 0.7, y + s * 0.05, x + s * 0.6, y + s * 0.12), tone.dim(0.7), k.thin * 0.7)
        }
    }

    private static func stickerMeadowCrown(_ k: StickerKit, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ rot: CGFloat) {
        k.with(about(x, y, rot: rot)) {
            let hw = w / 2
            let p = poly([x - hw, y, x + hw, y, x + hw, y + h, x + hw * 0.5, y + h * 0.55, x, y + h, x - hw * 0.5, y + h * 0.55, x - hw, y + h])
            k.part(p, Tone(0xffd23a), shape: ell(x + hw, y, hw * 0.6, h))
            k.fill(circ(x, y + h * 0.35, h * 0.16), Tone(0xff5f7e))
        }
    }
}
