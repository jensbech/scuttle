import Foundation
import CoreGraphics
import ScuttleCore

extension MascotArt {
    private static func meadowFace(_ f: FigureFrame, _ k: MascotKit, _ x: CGFloat, _ y: CGFloat, spread: CGFloat, rx: CGFloat, ry: CGFloat, iris: Tone, tones: MascotTones, mouthY: CGFloat, mouthW: CGFloat, mouthH: CGFloat, far: CGFloat = 1, blush: Bool = true) {
        let fx: CGFloat = f.mood == .fleeing ? 2.5 : 0
        let look: CGFloat = f.mood == .fleeing ? 0.3 : 0.12
        let lx = x - spread / 2 + fx
        let rx2 = x + spread / 2 + fx
        let frx = rx * far, fry = ry * far
        k.eye(lx, y, rx, ry, iris: iris, edge: tones.line, lid: tones.base, side: -1, look: look)
        k.eye(rx2, y, frx, fry, iris: iris, edge: tones.line, lid: tones.base, side: 1, look: look)
        k.brow(lx, y + ry + 4.5, rx * 1.25, side: -1, edge: tones.line)
        k.brow(rx2, y + fry + 4.5, frx * 1.25, side: 1, edge: tones.line)
        if blush {
            k.blush(lx - rx * 0.6, y - ry - 1, 4, 2.4)
            k.blush(rx2 + frx * 0.6, y - fry - 1, 4, 2.4)
        }
        k.mouth(x + fx, mouthY, mouthW, mouthH, edge: tones.line)
    }

    private static func meadowAntenna(_ k: MascotKit, _ bx: CGFloat, _ by: CGFloat, len: CGFloat, ang: CGFloat, bend: CGFloat, line: Tone, tip: MascotTones, r: CGFloat = 3.2) {
        let tx = bx - sin(ang) * len, ty = by + cos(ang) * len
        let mx = (bx + tx) / 2 + cos(ang) * bend, my = (by + ty) / 2 + sin(ang) * bend
        let p = CGMutablePath()
        p.move(to: pt(bx, by))
        p.addQuadCurve(to: pt(tx, ty), control: pt(mx, my))
        k.stroke(p, line, k.line * 1.1)
        if r > 0 { k.fs(circ(tx, ty, r), tip.base, tip.line, k.line * 0.9) }
    }

    private static func meadowDaisy(_ k: MascotKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, petal: Tone, center: Tone, line: Tone) {
        let petals = CGMutablePath()
        for i in 0..<6 {
            let a = CGFloat(i) * .pi / 3 + 0.3
            petals.addPath(circ(x + cos(a) * s * 0.95, y + sin(a) * s * 0.95, s * 0.62))
        }
        k.stroke(petals, line, k.line * 1.6)
        k.fill(petals, petal)
        k.cel(circ(x, y, s * 0.55), MascotTones(center, line: line), k.line * 0.8)
    }

    private static func meadowBow(_ k: MascotKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ tones: MascotTones, rot: CGFloat = 0) {
        k.with(about(x, y, rot: rot)) {
            k.cel(smooth([x, y, x - s * 1.2, y + s * 0.75, x - s * 1.25, y - s * 0.75], t: 0.45), tones, k.line * 0.9)
            k.cel(smooth([x, y, x + s * 1.2, y + s * 0.75, x + s * 1.25, y - s * 0.75], t: 0.45), tones, k.line * 0.9)
            k.cel(circ(x, y, s * 0.4), tones, k.line * 0.9)
        }
    }

    private static func meadowWing(_ k: MascotKit, _ hx: CGFloat, _ hy: CGFloat, len: CGFloat, wide: CGFloat, ang: CGFloat, _ tones: MascotTones, w: CGFloat) {
        k.with(about(hx, hy, rot: ang)) {
            if tones.base.a < 0.5 {
                k.fill(ell(hx, hy + len, wide, len), tones.shade)
            } else {
                k.cel(ell(hx, hy + len, wide, len), tones, w, k: 0.12)
            }
        }
    }

    static func ladybird(_ f: FigureFrame, _ k: MascotKit) {
        let shells: [Tone] = [Tone(0xf0433a), Tone(0xff8a26), Tone(0xffc93a), Tone(0xff6aa8), Tone(0x3fb4e6)]
        let spots: [Tone] = [Tone(0x2a1c3c), Tone(0x2a1c3c), Tone(0x2a1c3c), Tone(0x7a1848), Tone(0xffffff)]
        let shell = MascotTones(f.pick(shells))
        let spot = f.pick(spots)
        let head = MascotTones(Tone(0x4a4270), shade: Tone(0x2e2850), line: Tone(0x1a1430))
        let face = MascotTones(Tone(0xfff2e2), shade: Tone(0xf2c9b0), line: head.line)
        let wingT = MascotTones(Tone(0xeaf6ff, 0.85), shade: Tone(0xb8d8f5, 0.85), line: Tone(0x3a4f8a))
        let e = f.energy
        let t = f.t
        let b = k.bounce()
        var tilt: CGFloat = 0, hx: CGFloat = 68, hy: CGFloat = 43, open: CGFloat = 0
        var antA: CGFloat = 0, antL: CGFloat = 15, stepK: CGFloat = 1
        switch f.mood {
        case .calm:
            antA = 0.3 * f.twitch
        case .sleepy:
            hy = 37
            hx = 66
            antA = -0.9
            antL = 12
            stepK = 0
        case .startled:
            hy = 49
            open = 1
            antL = 18
        case .fleeing:
            hx = 71
            open = 0.7
            antA = 0.7
        case .dizzy:
            tilt = 0.12 * sin(t)
            antA = 0.4 * sin(2 * t)
        }
        k.with(about(50, 30, rot: tilt).concatenating(about(50, 4, sx: b.sx, sy: b.sy))) {
            for i in 0..<3 {
                let a = t + CGFloat(i) * 2.1 + .pi
                let hip = 30 + CGFloat(i) * 15
                let dx = 4 * sin(a) * e * stepK
                let up = max(0, cos(a)) * 3 * e * stepK
                k.stroke(line(hip, 16, hip + dx + 3, 6 + up), head.line, k.bold)
            }
            if open > 0 {
                let bz: CGFloat = f.mood == .fleeing ? (f.frameIndex % 2 == 0 ? 0.25 : -0.15) : 0.05 * f.swing2
                meadowWing(k, 58, 48, len: 15, wide: 7, ang: 0.95 + bz, wingT, w: k.line * 0.9)
                meadowWing(k, 58, 48, len: 16, wide: 7.5, ang: 0.55 + bz, wingT, w: k.line * 0.9)
            }
            let rock = 0.03 * sin(t) * e - 0.22 * open
            k.with(about(62, 46, rot: rock)) {
                let dome = smooth([8, 18, 12, 40, 26, 55, 42, 61, 58, 55, 68, 36, 66, 17, 38, 12], t: 0.9)
                k.cel(dome, shell, k.bold, k: 0.12)
                k.clip(dome) {
                    let pts: [(CGFloat, CGFloat, CGFloat)] = [(24, 37, 6.4), (43, 50, 6), (41, 27, 5.4), (57, 37, 4.8), (12, 25, 4.4), (27, 54, 3.8)]
                    for (x, y, r) in pts {
                        if f.variant == 3 {
                            k.fill(heart(x, y, r * 1.05), spot)
                        } else {
                            k.fill(circ(x, y, r), spot)
                        }
                    }
                }
                k.stroke(smooth([63, 53, 44, 58, 24, 50, 11, 30], closed: false), shell.line, k.line)
                k.stroke(dome, shell.line, k.bold)
                k.fill(ell(40, 52, 7, 3, 0.25), Tone(0xffffff, 0.55))
            }
            for i in 0..<3 {
                let a = t + CGFloat(i) * 2.1
                let hip = 24 + CGFloat(i) * 16
                let dx = 4 * sin(a) * e * stepK
                let up = max(0, cos(a)) * 3 * e * stepK
                let fy: CGFloat = f.mood == .sleepy ? 9 : 5 + up
                k.stroke(line(hip, 15, hip + dx + 2, fy), head.line, k.bold)
                k.fs(ell(hip + dx + 3.5, fy, 3.2, 2.2), head.base, head.line, k.line * 0.8)
            }
            meadowAntenna(k, hx - 10, hy + 22, len: antL, ang: 0.35 + antA, bend: 3, line: head.line, tip: shell)
            meadowAntenna(k, hx + 5, hy + 24, len: antL + 1, ang: -0.2 + antA, bend: -3, line: head.line, tip: shell)
            k.cel(circ(hx, hy, 27), head, k.bold, k: 0.12)
            k.cel(ell(hx + 4, hy - 1, 21.5, 23.5), face, k.line, k: 0.08)
            meadowFace(f, k, hx + 4, hy + 1, spread: 19, rx: 8, ry: 10.5, iris: Tone(0x2f6fe0), tones: face, mouthY: hy - 11.5, mouthW: 11, mouthH: 7)
            switch f.variant {
            case 1:
                meadowDaisy(k, hx - 15, hy + 20, 5.5, petal: .white, center: Tone(0xffc83a), line: Tone(0x6a5a3a))
            case 2:
                meadowBow(k, hx - 16, hy + 19, 6.5, MascotTones(Tone(0x8a6cf0), line: Tone(0x2c1a6a)), rot: 0.3)
            case 4:
                let leaf = MascotTones(Tone(0x6ad05a), line: Tone(0x1f5a1a))
                k.with(about(hx - 4, hy + 25, rot: 0.35)) {
                    let hy = hy + 4
                    k.cel(smooth([hx - 18, hy + 21, hx - 4, hy + 29, hx + 10, hy + 21, hx - 4, hy + 17], t: 0.7), leaf, k.line)
                    k.stroke(line(hx - 16, hy + 21, hx + 8, hy + 21.5), leaf.line, k.line * 0.7)
                }
            default:
                break
            }
            k.marks(hx + 22, hy + 33, 12, edge: head.line)
        }
    }

    static func bumblebee(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, MascotTones, Tone)] = [
            (MascotTones(Tone(0xffd23a), shade: Tone(0xf0a020), line: Tone(0x5a3412)), MascotTones(Tone(0x5a3a2a), shade: Tone(0x3e2618), line: Tone(0x2a160c)), Tone(0x2f78e8)),
            (MascotTones(Tone(0xffa840), shade: Tone(0xe8781a), line: Tone(0x5e2a0e)), MascotTones(Tone(0x5a3220), shade: Tone(0x3e2014), line: Tone(0x2a120a)), Tone(0x2f6fe0)),
            (MascotTones(Tone(0xfff07a), shade: Tone(0xe8c440), line: Tone(0x4a3a7a)), MascotTones(Tone(0x7a5ac8), shade: Tone(0x5a3ea0), line: Tone(0x2a1a5a)), Tone(0x7a4ad8)),
            (MascotTones(Tone(0xffd23a), shade: Tone(0xf0a020), line: Tone(0x5a3412)), MascotTones(Tone(0x5a3a2a), shade: Tone(0x3e2618), line: Tone(0x2a160c)), Tone(0x22a06c)),
            (MascotTones(Tone(0xffbcd8), shade: Tone(0xf088b0), line: Tone(0x7a2a52)), MascotTones(Tone(0x8a3a6a), shade: Tone(0x6a2650), line: Tone(0x3a1028)), Tone(0xd0408a)),
        ]
        let (fur, stripe, iris) = f.pick(looks)
        let wingT = MascotTones(Tone(0xeef8ff, 0.88), shade: Tone(0xbcdcf8, 0.88), line: Tone(0x3a4f8a))
        let blurT = MascotTones(Tone(0xeef8ff, 0.3), shade: Tone(0xbcdcf8, 0.3), line: Tone(0x3a4f8a, 0.3))
        let t = f.t
        let b = k.bounce()
        var tilt: CGFloat = 0, ab: CGFloat = 0.25, abx: CGFloat = 32, aby: CGFloat = 40
        var antA: CGFloat = 0, antL: CGFloat = 14, legA: CGFloat = 0, legL: CGFloat = 8
        var buzzSlow = false
        switch f.mood {
        case .calm:
            antA = 0.3 * f.twitch
        case .sleepy:
            ab = 0.5
            aby = 37
            antA = -0.8
            antL = 11
            buzzSlow = true
            tilt = -0.06
        case .startled:
            antL = 17
            legA = 0.7
            legL = 9
        case .fleeing:
            ab = 0.05
            abx = 29
            antA = 0.8
            legA = -1.0
            tilt = -0.08
        case .dizzy:
            tilt = 0.12 * sin(t)
            antA = 0.4 * sin(2 * t)
        }
        let fi = buzzSlow ? f.frameIndex / 4 : f.frameIndex
        let bz: CGFloat = fi % 2 == 0 ? 0.3 : -0.25
        k.with(about(50, 45, rot: tilt).concatenating(about(50, 30, sx: b.sx, sy: b.sy))) {
            meadowWing(k, 44, 64, len: 14, wide: 8, ang: 0.75 - bz, blurT, w: k.line * 0.6)
            meadowWing(k, 47, 66, len: 15, wide: 8.5, ang: 0.2 - bz, blurT, w: k.line * 0.6)
            meadowWing(k, 44, 64, len: 14, wide: 8, ang: 0.75 + bz, wingT, w: k.line * 0.9)
            for i in 0..<3 {
                let lx = 38 + CGFloat(i) * 9
                let a = legA + 0.25 * sin(t * 2 + CGFloat(i)) * f.energy * 0.4
                let p = line(lx, 32, lx - sin(a) * legL, 32 - cos(a) * legL)
                k.stroke(p, stripe.line, k.bold)
            }
            let body = ell(abx, aby, 20, 17, ab)
            k.cel(body, fur, k.bold, k: 0.12)
            k.clip(body) {
                for sx in [CGFloat(20), 33] {
                    let cx = abx + (sx - 32) * cos(ab), cy = aby + (sx - 32) * sin(ab)
                    k.fill(ell(cx, cy, 4.2, 22, ab), stripe.base)
                    k.fill(ell(cx - 1.5, cy - 2, 2.5, 22, ab), stripe.shade)
                }
            }
            k.stroke(body, fur.line, k.bold)
            let tx = abx - 20 * cos(ab), ty = aby - 20 * sin(ab)
            k.cel(poly([tx + 1, ty + 3, tx - 7 * cos(ab), ty - 7 * sin(ab) - 0.5, tx + 1, ty - 3]), stripe, k.line * 0.8)
            meadowWing(k, 47, 66, len: 15, wide: 8.5, ang: 0.2 + bz, wingT, w: k.line * 0.9)
            let tipT = MascotTones(stripe.base, line: stripe.line)
            meadowAntenna(k, 52, 70, len: antL, ang: 0.35 + antA, bend: 3, line: stripe.line, tip: tipT, r: f.variant == 4 ? 0 : 3.2)
            meadowAntenna(k, 66, 72, len: antL + 1, ang: -0.25 + antA, bend: -3, line: stripe.line, tip: tipT, r: f.variant == 4 ? 0 : 3.2)
            if f.variant == 4 {
                for (bx, by, a) in [(52 as CGFloat, 70 as CGFloat, 0.35 + antA), (66, 72, -0.25 + antA)] {
                    let l = antL + (bx > 60 ? 1 : 0)
                    let hxp = bx - sin(a) * l, hyp = by + cos(a) * l
                    k.cel(heart(hxp, hyp + 1, 4.2), MascotTones(Tone(0xff4d8a), line: Tone(0x6a1438)), k.line * 0.8)
                }
            }
            k.cel(circ(60, 50, 25), fur, k.bold, k: 0.12)
            k.fill(ell(52, 66, 6, 3, 0.3), Tone(0xffffff, 0.5))
            meadowFace(f, k, 63, 52, spread: 18, rx: 7.5, ry: 10, iris: iris, tones: fur, mouthY: 36.5, mouthW: 11, mouthH: 7)
            switch f.variant {
            case 1:
                meadowDaisy(k, 76, 70, 5, petal: Tone(0xff8ac0), center: Tone(0xffe04a), line: Tone(0x7a2a52))
            case 2:
                meadowBow(k, 46, 70, 6, MascotTones(Tone(0x4aa0ff), line: Tone(0x1a3a7a)), rot: 0.4)
            case 3:
                let knit = MascotTones(Tone(0xff5a5a), shade: Tone(0xd83a4a), line: Tone(0x6a1420))
                let bob: CGFloat = 1.5 * f.twitch
                k.with(about(60, 72, rot: -0.12)) {
                    k.cel(smooth([38, 66, 41, 82, 60, 89, 79, 82, 82, 66, 60, 70], t: 0.8), knit, k.line, k: 0.15)
                    k.cel(rrect(37, 63, 46, 8, 4), MascotTones(Tone(0xfdf6ee), shade: Tone(0xe0d6cc), line: knit.line), k.line)
                    k.cel(circ(60 + bob, 91, 5), MascotTones(Tone(0xfdf6ee), shade: Tone(0xe0d6cc), line: knit.line), k.line)
                }
            default:
                break
            }
            k.marks(80, 78, 12, edge: fur.line)
        }
    }

    static func snail(_ f: FigureFrame, _ k: MascotKit) {
        let shells: [Tone] = [Tone(0xe2844a), Tone(0xb48aea), Tone(0x5fcf9e), Tone(0xff8cb8), Tone(0x6aa8f0)]
        let irises: [Tone] = [Tone(0x7a3f1a), Tone(0x6a3ad0), Tone(0x1f8a5a), Tone(0xc02f86), Tone(0x2a5fd0)]
        let shell = MascotTones(f.pick(shells))
        let iris = f.pick(irises)
        let skin = MascotTones(Tone(0xf6cc94), shade: Tone(0xe0a466), line: Tone(0x5e3416))
        let t = f.t
        let e = f.energy
        let b = k.bounce(0.6)
        let s = sin(t) * e
        let s2 = sin(t - 1.3) * e
        var tilt: CGFloat = 0, hx: CGFloat = 72 + 3 * s, hy: CGFloat = 45, stalk: CGFloat = 13, stalkA: CGFloat = 0
        var spin: CGFloat = 0, sx0: CGFloat = 36 + 1.2 * s2
        switch f.mood {
        case .calm:
            stalkA = 0.3 * f.twitch
        case .sleepy:
            hx = 67
            hy = 37
            stalk = 6
            stalkA = -0.5
            sx0 = 37
        case .startled:
            hy = 51
            stalk = 17
        case .fleeing:
            hx = 78 + 2 * s
            stalkA = 0.7
            stalk = 14
        case .dizzy:
            tilt = 0.12 * sin(t)
            spin = t
            stalkA = 0.4 * sin(2 * t)
        }
        let tail: CGFloat = 8 + 3 * s2 - (f.mood == .fleeing ? 4 : 0)
        k.with(about(50, 30, rot: tilt).concatenating(about(50, 4, sx: b.sx, sy: b.sy))) {
            let foot = smooth([tail, 6, tail + 4, 10, 30, 15, 58, 16, hx - 10, 18, hx + 10, 14, hx + 14, 7, hx + 6, 4, 40, 4], t: 0.8)
            k.cel(foot, skin, k.bold, k: 0.1)
            let sy0: CGFloat = 38 + 0.8 * s2
            let sh = circ(sx0, sy0, 25)
            k.cel(sh, shell, k.bold, k: 0.12)
            k.clip(sh) {
                k.fill(ell(sx0 - 4, sy0 - 22, 30, 8), shell.shade.dim(0.92))
            }
            k.stroke(spiral(sx0 + 1, sy0 + 1, 21, turns: 2.1, spin: -1, start: 0.6 - spin), shell.line, k.line * 1.05)
            k.stroke(sh, shell.line, k.bold)
            k.fill(ell(sx0 - 10, sy0 + 14, 6, 3.4, 0.5), Tone(0xffffff, 0.5))
            switch f.variant {
            case 1:
                meadowDaisy(k, sx0 - 6, sy0 + 25, 5.5, petal: .white, center: Tone(0xffc83a), line: Tone(0x5a3a6a))
            case 2:
                let leaf = MascotTones(Tone(0x7ad85a), line: Tone(0x1f5a1a))
                k.stroke(line(sx0 - 2, sy0 + 24, sx0 - 2, sy0 + 30), leaf.line, k.line)
                k.cel(ell(sx0 - 8, sy0 + 32, 6.5, 3.4, 0.4), leaf, k.line * 0.9)
                k.cel(ell(sx0 + 4, sy0 + 32, 6.5, 3.4, -0.4), leaf, k.line * 0.9)
            default:
                break
            }
            let tip = MascotTones(skin.base, shade: skin.shade, line: skin.line)
            meadowAntenna(k, hx - 7, hy + 19, len: stalk, ang: 0.3 + stalkA, bend: 2, line: skin.line, tip: tip, r: 3.4)
            meadowAntenna(k, hx + 8, hy + 20, len: stalk + 1, ang: -0.25 + stalkA, bend: -2, line: skin.line, tip: tip, r: 3.4)
            if f.variant == 3 {
                let a = -0.25 + stalkA
                let l = stalk + 1
                meadowBow(k, hx + 8 - sin(a) * l * 0.55, hy + 20 + cos(a) * l * 0.55, 4.2, MascotTones(Tone(0xff5fae), line: Tone(0x8a2e5e)))
            }
            let neck = smooth([hx - 14, 14, hx - 16, hy - 4, hx, hy, hx + 14, hy - 6, hx + 12, 12], t: 0.8)
            k.cel(neck, skin, k.bold, k: 0.1)
            k.cel(circ(hx, hy, 23), skin, k.bold, k: 0.12)
            meadowFace(f, k, hx + 3, hy + 2, spread: 18.5, rx: 7.8, ry: 10.3, iris: iris, tones: skin, mouthY: hy - 10.5, mouthW: 11, mouthH: 7)
            if f.variant == 4 {
                let cap = MascotTones(Tone(0xff4d4d), line: Tone(0x6a1414))
                k.with(about(hx, hy + 17, rot: -0.15)) {
                    k.cel(smooth([hx + 6, hy + 18, hx + 24, hy + 19, hx + 23, hy + 15, hx + 6, hy + 14], t: 0.5), cap, k.line)
                    k.cel(smooth([hx - 14, hy + 14, hx - 11, hy + 26, hx, hy + 30, hx + 11, hy + 26, hx + 14, hy + 14, hx, hy + 12], t: 0.8), cap, k.line, k: 0.15)
                }
            }
            k.marks(hx + 21, hy + 31, 12, edge: skin.line)
        }
    }

    static func chick(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, Tone)] = [
            (MascotTones(Tone(0xffe04a), shade: Tone(0xf5b42a), line: Tone(0x6a3a10)), Tone(0xa05a1e)),
            (MascotTones(Tone(0xffe04a), shade: Tone(0xf5b42a), line: Tone(0x6a3a10)), Tone(0x2f6fe0)),
            (MascotTones(Tone(0xfff08a), shade: Tone(0xf0c850), line: Tone(0x5e4210)), Tone(0x22a06c)),
            (MascotTones(Tone(0xffc8dc), shade: Tone(0xf094b8), line: Tone(0x7a2a52)), Tone(0xc02f86)),
            (MascotTones(Tone(0xffc85a), shade: Tone(0xf0962a), line: Tone(0x6a3010)), Tone(0x7a4ad8)),
        ]
        let (fluff, iris) = f.pick(looks)
        let beak = MascotTones(Tone(0xff9a2e), shade: Tone(0xe2700e), line: Tone(0x6a2a08))
        let shellT = MascotTones(Tone(0xfffaf0), shade: Tone(0xe2dccf), line: Tone(0x6a5a48))
        let t = f.t
        let b = k.bounce()
        let air = f.airborne
        var tilt: CGFloat = 0, wingA: CGFloat = 0.3, tuft: CGFloat = 0
        var footY: CGFloat = 0
        if air { wingA = 0.3 + 0.9 * (1 - abs(f.stretch)) }
        footY = air ? -2 * max(0, f.stretch) : 0
        switch f.mood {
        case .calm:
            tuft = 0.25 * f.twitch
        case .sleepy:
            wingA = -0.2
            tuft = -0.5
        case .startled:
            wingA = 1.15
            tuft = 0.4 * f.swing2
        case .fleeing:
            wingA = 0.75 + 0.5 * f.swing
            tuft = 0.6
        case .dizzy:
            tilt = 0.12 * sin(t)
            tuft = 0.4 * sin(2 * t)
        }
        k.with(about(50, 30, rot: tilt).concatenating(about(50, 4, sx: b.sx, sy: b.sy))) {
            k.both { side in
                let fx = 50 + side * 7
                k.stroke(line(fx, 12, fx, 6 + footY), beak.line, k.bold)
                k.cel(smooth([fx - 6, 4 + footY, fx + 6, 4 + footY, fx + 4, 8 + footY, fx - 4, 8 + footY], t: 0.7), beak, k.line * 0.9)
            }
            k.cel(ell(50, 19, 14, 12), fluff, k.bold, k: 0.12)
            k.both { side in
                let a = side * (wingA + 0.35)
                k.with(about(50 + side * 11, 25, rot: a)) {
                    k.cel(ell(50 + side * 11, 17, 4.6, 8.5), fluff, k.line)
                }
            }
            if f.variant == 1 {
                let egg = smooth([29, 27, 30, 12, 39, 4, 61, 4, 70, 12, 71, 27, 65, 22, 60, 28, 55, 22, 50, 28, 45, 22, 40, 28, 35, 22], t: 0.25)
                k.cel(egg, shellT, k.line, k: 0.12)
            }
            for (i, a) in [(-1, 0.45), (0, 0.0), (1, -0.45)] as [(Int, CGFloat)] {
                let ang = a + tuft
                let bx = 50 + CGFloat(i) * 3
                k.with(about(bx, 82, rot: ang)) {
                    k.cel(drop(bx, 90, 3.4, .pi), fluff, k.line * 0.9)
                }
            }
            k.cel(circ(50, 55, 28), fluff, k.bold, k: 0.12)
            k.fill(ell(37, 72, 6, 3.2, 0.5), Tone(0xffffff, 0.5))
            let fx: CGFloat = f.mood == .fleeing ? 2.5 : 0
            meadowFace(f, k, 50, 58, spread: 20, rx: 8.5, ry: 11, iris: iris, tones: fluff, mouthY: 42, mouthW: 12, mouthH: 7.5)
            k.cel(smooth([43.5 + fx, 44, 56.5 + fx, 44, 50 + fx, 39.5], t: 0.6), beak, k.line * 0.9)
            switch f.variant {
            case 2:
                let cap = smooth([26, 70, 30, 86, 50, 92, 70, 86, 74, 70, 68, 75, 62, 70, 56, 75, 50, 70, 44, 75, 38, 70, 32, 75], t: 0.3)
                k.cel(cap, shellT, k.line, k: 0.12)
            case 3:
                meadowBow(k, 66, 80, 6.5, MascotTones(Tone(0xff5fae), line: Tone(0x8a2e5e)), rot: -0.3)
            case 4:
                meadowDaisy(k, 64, 81, 5.5, petal: .white, center: Tone(0xff8a3a), line: Tone(0x6a3010))
            default:
                break
            }
            k.marks(78, 82, 12, edge: fluff.line)
        }
    }

    static func butterfly(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, MascotTones, MascotTones, Tone, Tone, Tone)] = [
            (MascotTones(Tone(0xff8c42), shade: Tone(0xdc5f22)), MascotTones(Tone(0xffd24a), shade: Tone(0xe9a823)), MascotTones(Tone(0xb08cf0), shade: Tone(0x8463d0), line: Tone(0x35215f)), Tone(0x7a52c7), Tone(0xc02f86), Tone(0xffe3c8)),
            (MascotTones(Tone(0x4aa8ff), shade: Tone(0x2a78e0)), MascotTones(Tone(0x7ae8d8), shade: Tone(0x3cc0b0)), MascotTones(Tone(0xffa6cc), shade: Tone(0xe874a4), line: Tone(0x5e1a40)), Tone(0xe0609a), Tone(0x2a6fe0), Tone(0xe8f6ff)),
            (MascotTones(Tone(0xff6fae), shade: Tone(0xe04a8a)), MascotTones(Tone(0xc49cff), shade: Tone(0x9a70e8)), MascotTones(Tone(0x9ad8ff), shade: Tone(0x62acec), line: Tone(0x1f3a7a)), Tone(0x4a7ae0), Tone(0xd0408a), Tone(0xfff0f8)),
            (MascotTones(Tone(0x6ad46a), shade: Tone(0x3aa84a)), MascotTones(Tone(0xd8f06a), shade: Tone(0xb0d040)), MascotTones(Tone(0xffbe5a), shade: Tone(0xf0902a), line: Tone(0x5e2a0e)), Tone(0xe07a2a), Tone(0x22a06c), Tone(0xf6ffe0)),
            (MascotTones(Tone(0xff8a1e), shade: Tone(0xd8600e)), MascotTones(Tone(0xffaa3a), shade: Tone(0xe07e1a)), MascotTones(Tone(0x8f7ae8), shade: Tone(0x6a54c8), line: Tone(0x22164a)), Tone(0x4a3a8a), Tone(0xe07a1a), Tone(0xffffff)),
        ]
        let (up0, low0, hd, bodyTone, iris, spot) = f.pick(looks)
        let up = MascotTones(up0.base, shade: up0.shade, line: hd.line)
        let low = MascotTones(low0.base, shade: low0.shade, line: hd.line)
        let bodyT = MascotTones(bodyTone, line: hd.line)
        let t = f.t
        let e = f.energy
        var w: CGFloat = 0.7 + 0.3 * f.swing
        var tilt: CGFloat = 0, wingDX: CGFloat = 0, antA: CGFloat = 0, raise: CGFloat = 0, hy: CGFloat = 52
        switch f.mood {
        case .calm:
            antA = 0.25 * f.twitch
        case .sleepy:
            w = 0.34 + 0.06 * f.swing
            antA = -0.5
            hy = 49
            raise = 4
        case .startled:
            w = 1.04 + 0.04 * f.swing2
            raise = 6
            hy = 55
            antA = 0
        case .fleeing:
            w = 0.62 + 0.36 * f.swing
            wingDX = -3
            antA = 0.6
        case .dizzy:
            tilt = 0.12 * sin(t)
            w = 0.68 + 0.28 * f.swing
            antA = 0.4 * sin(2 * t)
        }
        raise += 5 * max(0, 0.75 - w) * e
        let b = k.bounce(0.5)
        k.with(about(50, 45, rot: tilt).concatenating(about(50, 45, sx: 1.06 * b.sx, sy: 0.95 * b.sy))) {
            k.with(CGAffineTransform(translationX: wingDX, y: raise).concatenating(about(50 + wingDX, 50 + raise, sx: w, sy: 1))) {
                for s in [false, true] {
                    let m: (CGPath) -> CGPath = { s ? mirror($0) : $0 }
                    let lw = m(smooth([46, 44, 40, 28, 28, 14, 14, 16, 10, 30, 22, 42]))
                    k.cel(lw, low, k.bold, k: 0.15)
                    let uw = m(smooth([46, 56, 36, 74, 20, 88, 6, 82, 4, 62, 16, 50, 36, 48]))
                    if f.variant == 4 {
                        k.cel(uw, up, k.bold, k: 0.15)
                        k.clip(uw) { k.stroke(uw, hd.line.mix(Tone(0x2a1408), 0.5), 9) }
                        k.clip(lw) { k.stroke(lw, hd.line.mix(Tone(0x2a1408), 0.5), 8) }
                        k.stroke(uw, hd.line, k.bold)
                        k.stroke(lw, hd.line, k.bold)
                        for (x, y) in [(8, 70), (11, 79), (17, 85), (25, 87), (9, 62)] as [(CGFloat, CGFloat)] {
                            k.fill(m(circ(x, y, 1.9)), spot)
                        }
                        for (x, y) in [(13, 21), (18, 16), (12, 28)] as [(CGFloat, CGFloat)] {
                            k.fill(m(circ(x, y, 1.7)), spot)
                        }
                    } else {
                        k.cel(uw, up, k.bold, k: 0.15)
                        if f.variant == 2 {
                            k.fill(m(heart(17, 70, 5.8)), spot)
                            k.fill(m(heart(23, 26, 4.2)), spot)
                        } else {
                            k.fill(m(ell(17, 71, 5.4, 4.6)), spot)
                            k.fill(m(circ(26, 82, 2.4)), spot)
                            k.fill(m(ell(23, 27, 4, 3.4)), spot)
                        }
                    }
                }
            }
            meadowAntenna(k, 46, hy + 18, len: 18, ang: 0.45 + antA, bend: 4, line: hd.line, tip: MascotTones(Tone(0xff6fb8), shade: Tone(0xd8408c), line: hd.line), r: 4)
            meadowAntenna(k, 54, hy + 18, len: 18, ang: -0.45 + antA * 0.6, bend: -4, line: hd.line, tip: MascotTones(Tone(0xff6fb8), shade: Tone(0xd8408c), line: hd.line), r: 4)
            let kick: CGFloat = 0.2 * sin(t * 2)
            k.cel(ell(43, 20, 3, 5, -0.8 - kick), hd, k.line * 0.9)
            k.cel(ell(57, 22, 3, 5, 0.9 + kick), hd, k.line * 0.9)
            k.cel(ell(50, 19, 7, 11), bodyT, k.line)
            k.cel(circ(50, hy, 23), hd, k.bold, k: 0.12)
            meadowFace(f, k, 50, hy + 2, spread: 16, rx: 6.8, ry: 9.2, iris: iris, tones: hd, mouthY: hy - 9.5, mouthW: 11, mouthH: 7.5)
            if f.variant == 1 {
                meadowBow(k, 64, hy + 19, 6.5, MascotTones(Tone(0xff5fae), line: Tone(0x8a2e5e)), rot: -0.35)
            }
            if f.variant == 3 {
                meadowDaisy(k, 36, hy + 18, 4.6, petal: .white, center: Tone(0xffd23a), line: Tone(0x5e2a0e))
                meadowDaisy(k, 46, hy + 22, 4.6, petal: Tone(0xff9ac8), center: Tone(0xffd23a), line: Tone(0x5e2a0e))
            }
            k.marks(72, hy + 24, 12, edge: hd.line)
        }
    }

    static func dragonfly(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0x2fb0d8), Tone(0x64d4ee), Tone(0x2a5fd0)),
            (Tone(0xf0503c), Tone(0xff8a6a), Tone(0x1f8a5a)),
            (Tone(0x52c046), Tone(0x96e27a), Tone(0x8a4ad0)),
            (Tone(0x9a5ae8), Tone(0xbc96ff), Tone(0xd0408a)),
            (Tone(0xf0a020), Tone(0xffd25a), Tone(0x2a6fe0)),
        ]
        let (bodyC, headC, iris) = f.pick(looks)
        let bodyT = MascotTones(bodyC)
        let head = MascotTones(headC, line: bodyT.line)
        let wingT = MascotTones(Tone(0xeef8ff, 0.82), shade: Tone(0xb6dcf8, 0.82), line: Tone(0x3a5590))
        let blurT = MascotTones(Tone(0xeef8ff, 0.28), shade: Tone(0xb6dcf8, 0.28), line: Tone(0x3a5590, 0.28))
        let t = f.t
        let e = f.energy
        var tilt: CGFloat = 0, fold: CGFloat = 0, spread: CGFloat = 0, gap: CGFloat = 5.4
        var buzzOn = true
        switch f.mood {
        case .sleepy:
            fold = 1
            buzzOn = false
        case .startled:
            spread = 1
        case .fleeing:
            fold = -0.3
            gap = 6.2
        case .dizzy:
            tilt = 0.12 * sin(t)
        default:
            break
        }
        let bz: CGFloat = buzzOn ? (f.frameIndex % 2 == 0 ? 0.22 : -0.16) : 0
        let b = k.bounce(0.4)
        k.with(about(50, 50, rot: tilt).concatenating(about(50, 50, sx: b.sx, sy: b.sy))) {
            let a1: CGFloat = 0.6 + 0.95 * fold - 0.35 * spread
            let a2: CGFloat = -0.35 + 0.35 * spread + (fold > 0 ? 1.75 : 0)
            if buzzOn {
                meadowWing(k, 46, 57, len: 19, wide: 5.6, ang: a1 + 0.25 - bz, blurT, w: k.line * 0.6)
                meadowWing(k, 46, 57, len: 18, wide: 5.6, ang: a2 - 0.25 - bz, blurT, w: k.line * 0.6)
            }
            meadowWing(k, 45, 57, len: 18, wide: 5.4, ang: a1 + 0.3 + bz, wingT, w: k.line * 0.85)
            meadowWing(k, 47, 57, len: 17, wide: 5.4, ang: a2 - 0.3 + bz, wingT, w: k.line * 0.85)
            var segs: [(CGFloat, CGFloat)] = []
            for i in 0..<7 {
                let u = CGFloat(i) / 6
                var y: CGFloat = 50 + 2 * sin(t - u * 3) * e * u
                switch f.mood {
                case .sleepy: y = 50 - 9 * u * u
                case .startled: y = 50 + 15 * u * u
                case .fleeing: y = 50 + 1.5 * u + 1.5 * sin(t * 2 - u * 4) * u
                case .dizzy: y = 50 + 5 * sin(2 * t - u * 5) * u
                case .calm: y += 3 * f.twitch * u * u
                }
                segs.append((38 - CGFloat(i) * gap, y))
            }
            let tailP = CGMutablePath()
            for i in stride(from: 6, through: 0, by: -1) {
                let (x, y) = segs[i]
                let nx = i > 0 ? segs[i - 1] : (46, 50)
                let ang = atan2(nx.1 - y, nx.0 - x)
                let r: CGFloat = 4.8 - CGFloat(i) * 0.33
                tailP.addPath(ell(x, y, gap * 0.62, r, ang))
            }
            k.cel(tailP, bodyT, k.line, k: 0.15)
            k.stroke(line(44, 44, 42, 38), bodyT.line, k.bold)
            k.stroke(line(50, 44, 51, 38), bodyT.line, k.bold)
            k.cel(ell(47, 51, 9.5, 8.5), bodyT, k.bold, k: 0.12)
            k.cel(circ(68, 54, 21), head, k.bold, k: 0.12)
            if f.variant == 1 {
                let wv = 3 * sin(t * 2) * e
                let sc = MascotTones(Tone(0xffd23a), shade: Tone(0xf0a020), line: Tone(0x6a3a08))
                k.cel(smooth([54, 38, 40, 42 + wv, 26, 40 + wv * 1.5, 30, 47 + wv, 42, 48, 54, 45], t: 0.7), sc, k.line)
                k.cel(smooth([47, 42, 56, 32, 68, 33, 60, 43], t: 0.8), sc, k.line, k: 0.15)
                k.cel(circ(53, 40, 4), sc, k.line)
            }
            meadowFace(f, k, 71, 56, spread: 18, rx: 8, ry: 10.5, iris: iris, tones: head, mouthY: 40.5, mouthW: 11, mouthH: 7)
            switch f.variant {
            case 2:
                let gl = MascotTones(Tone(0x8a5a3a), line: Tone(0x2e1a0e))
                k.with(about(68, 74, rot: -0.1)) {
                    k.stroke(arc(49, 70, 87, 70, dip: -6), gl.line, k.bold * 1.6)
                    k.stroke(arc(49, 70, 87, 70, dip: -6), gl.base, k.line)
                    for gx in [CGFloat(61), 75] {
                        k.cel(circ(gx, 76, 5.4), gl, k.line)
                        k.fill(circ(gx, 76, 3.4), Tone(0x9ae0ff))
                        k.fill(circ(gx - 1.2, 77.2, 1.2), .white)
                    }
                }
            case 3:
                meadowDaisy(k, 56, 72, 5, petal: Tone(0xffb0d8), center: Tone(0xffd23a), line: bodyT.line)
            default:
                break
            }
            k.marks(86, 76, 12, edge: head.line)
        }
    }

    static func firefly(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(Tone, MascotTones, Tone)] = [
            (Tone(0xe4ff5a), MascotTones(Tone(0x8e9cf4), shade: Tone(0x6474d8), line: Tone(0x1e2460)), Tone(0x2a8a3a)),
            (Tone(0xffd84a), MascotTones(Tone(0xb49af0), shade: Tone(0x8c70d8), line: Tone(0x2a1a5e)), Tone(0xd08a10)),
            (Tone(0xff8ad8), MascotTones(Tone(0x9ab4f8), shade: Tone(0x6a88e0), line: Tone(0x1e2a64)), Tone(0xc02f86)),
            (Tone(0x7af0ff), MascotTones(Tone(0xa0a8f4), shade: Tone(0x7478d8), line: Tone(0x1e1e60)), Tone(0x1a8ab0)),
            (Tone(0xffaa4a), MascotTones(Tone(0x96a4f2), shade: Tone(0x6a78d8), line: Tone(0x1e2460)), Tone(0xd0601a)),
        ]
        let (glowC, head, iris) = f.pick(looks)
        let shellT = MascotTones(Tone(0x5a4a8a), shade: Tone(0x3a2e64), line: head.line)
        let wingT = MascotTones(Tone(0xeef8ff, 0.85), shade: Tone(0xbcdcf8, 0.85), line: Tone(0x3a4f8a))
        let blurT = MascotTones(Tone(0xeef8ff, 0.3), shade: Tone(0xbcdcf8, 0.3), line: Tone(0x3a4f8a, 0.3))
        let t = f.t
        var tilt: CGFloat = 0, antA: CGFloat = 0, antL: CGFloat = 16, glow: CGFloat = 0.55 + 0.3 * sin(t)
        var slow = false, legA: CGFloat = 0
        switch f.mood {
        case .calm:
            antA = 0.3 * f.twitch
        case .sleepy:
            glow = 0.28 + 0.08 * sin(t)
            antA = -0.8
            antL = 12
            slow = true
            tilt = -0.06
        case .startled:
            glow = 1
            antL = 19
            legA = 0.7
        case .fleeing:
            glow = f.frameIndex % 2 == 0 ? 1 : 0.55
            antA = 0.8
            legA = -1
            tilt = -0.08
        case .dizzy:
            tilt = 0.12 * sin(t)
            glow = 0.5 + 0.4 * sin(3 * t)
            antA = 0.4 * sin(2 * t)
        }
        let fi = slow ? f.frameIndex / 4 : f.frameIndex
        let bz: CGFloat = fi % 2 == 0 ? 0.3 : -0.25
        let lamp = MascotTones(glowC.mix(.white, 0.15 + 0.35 * glow), shade: glowC.mix(Tone(0x9ab020), 0.25 * (1 - glow)), line: head.line)
        let b = k.bounce(0.6)
        k.with(about(50, 45, rot: tilt).concatenating(about(50, 30, sx: b.sx, sy: b.sy))) {
            if glow > 0.4 {
                let gr: CGFloat = 14 + 12 * glow
                k.fill(softStar(26, 37, gr, points: 8, inner: 0.72, spin: f.t / 4, t: 0.9), glowC.mix(.white, 0.55).alpha(0.9))
            }
            meadowWing(k, 44, 62, len: 14, wide: 8, ang: 0.8 - bz, blurT, w: k.line * 0.6)
            meadowWing(k, 44, 62, len: 14, wide: 8, ang: 0.8 + bz, wingT, w: k.line * 0.9)
            for i in 0..<3 {
                let lx = 40 + CGFloat(i) * 8
                let a = legA + 0.2 * sin(t * 2 + CGFloat(i))
                k.stroke(line(lx, 34, lx - sin(a) * 8, 34 - cos(a) * 8), head.line, k.bold)
            }
            let lantern = ell(28, 38, 16, 14, 0.3)
            k.cel(lantern, lamp, k.bold, k: 0.12)
            k.fill(ell(22, 42, 5, 3, 0.4), Tone(0xffffff, 0.35 + 0.4 * glow))
            k.cel(ell(42, 46, 11, 11), shellT, k.bold, k: 0.12)
            k.cel(ell(40, 56, 15, 8, 0.45), shellT, k.bold, k: 0.12)
            meadowWing(k, 47, 64, len: 15, wide: 8.5, ang: 0.25 + bz, wingT, w: k.line * 0.9)
            let tipT = MascotTones(glowC, line: head.line)
            meadowAntenna(k, 53, 70, len: antL, ang: 0.15 + antA, bend: -5, line: head.line, tip: tipT, r: f.variant == 4 ? 0 : 3)
            meadowAntenna(k, 66, 72, len: antL, ang: -0.45 + antA, bend: -5, line: head.line, tip: tipT, r: f.variant == 4 ? 0 : 3)
            if f.variant == 4 {
                let a: CGFloat = -0.45 + antA
                k.cel(star(66 - sin(a) * antL, 72 + cos(a) * antL, 5.5, inner: 0.5), MascotTones(Tone(0xffd84a), line: head.line), k.line * 0.8)
            }
            k.cel(circ(60, 52, 22), head, k.bold, k: 0.12)
            meadowFace(f, k, 63, 54, spread: 17, rx: 7.5, ry: 10, iris: iris, tones: head, mouthY: 38.5, mouthW: 10.5, mouthH: 7)
            switch f.variant {
            case 1:
                let cap = MascotTones(Tone(0x5a8af0), line: Tone(0x1a2a6a))
                k.cel(smooth([42, 66, 52, 78, 64, 80, 76, 72, 80, 64, 60, 70], t: 0.8), cap, k.line, k: 0.15)
                k.cel(smooth([42, 66, 30, 74, 22, 64], closed: false, t: 0.8), cap, k.line)
                k.cel(circ(22, 63, 3.6), MascotTones(.white, line: cap.line), k.line * 0.9)
                k.cel(rrect(40, 62, 42, 7, 3.5), MascotTones(.white, line: cap.line), k.line * 0.9)
            case 2:
                meadowBow(k, 46, 70, 6, MascotTones(Tone(0xff5fae), line: Tone(0x8a2e5e)), rot: 0.4)
            case 3:
                meadowBow(k, 59, 29.5, 5, MascotTones(Tone(0xff8a3a), line: Tone(0x6a2a08)))
            default:
                break
            }
            k.marks(80, 78, 12, edge: head.line)
        }
    }

    static func crab(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xff6447), Tone(0x2a6fe0)),
            (Tone(0xff9a3a), Tone(0x22a06c)),
            (Tone(0x5a9af0), Tone(0xe07a1a)),
            (Tone(0xff7fb0), Tone(0x7a4ad8)),
            (Tone(0xffbe3a), Tone(0xc02f86)),
        ]
        let (shellC, iris) = f.pick(looks)
        let shellT = MascotTones(shellC)
        let t = f.t
        let e = f.energy
        let b = k.bounce(0.6)
        var tilt: CGFloat = 0, clawUp: CGFloat = 0.5, stalk: CGFloat = 13, stalkA: CGFloat = 0, pinch: CGFloat = 0.35 + 0.25 * sin(2 * t)
        var wave: CGFloat = 0, sx0: CGFloat = 0
        switch f.mood {
        case .calm:
            wave = max(0, f.twitch) * 0.7
        case .sleepy:
            clawUp = -0.5
            stalk = 9
            stalkA = 0.5
            pinch = 0.05
        case .startled:
            clawUp = 1.5
            stalk = 16
            pinch = 0.7
        case .fleeing:
            clawUp = 1.1 + 0.4 * f.swing
            sx0 = 2
            pinch = 0.6 + 0.2 * sin(4 * t)
        case .dizzy:
            tilt = 0.12 * sin(t)
            stalkA = 0.35 * sin(2 * t)
        }
        let cy: CGFloat = f.mood == .sleepy ? 26 : 30
        let roll: CGFloat = 0.045 * sin(t) * e
        k.with(about(50, 30, rot: tilt + roll).concatenating(about(50, 4, sx: b.sx, sy: b.sy))) {
            k.both { side in
                for i in 0..<3 {
                    let ph = t + CGFloat(i) * 2.1 + (side > 0 ? .pi : 0)
                    let up = max(0, sin(ph)) * 3.5 * e * (f.mood == .sleepy ? 0 : 1)
                    let hx = 50 + side * (20 + CGFloat(i) * 4)
                    let kx = 50 + side * (32 + CGFloat(i) * 5)
                    let ky: CGFloat = 20 + up
                    let fx = 50 + side * (34 + CGFloat(i) * 6)
                    let p = CGMutablePath()
                    p.move(to: pt(hx, cy - 6))
                    p.addLine(to: pt(kx, ky))
                    p.addLine(to: pt(fx, 5 + up))
                    k.stroke(p, shellT.line, k.bold * 1.9)
                    k.stroke(p, shellT.shade, k.bold * 0.8)
                }
            }
            k.both { side in
                var lift = clawUp
                if side > 0 { lift += wave + 0.2 * f.twitch }
                if f.mood == .fleeing { lift = clawUp + 0.35 * side * f.swing }
                let ax = 50 + side * 28, ay = cy + 2
                let elbowX = ax + side * 10, elbowY = ay + 4 + 6 * lift
                let cx = elbowX + side * 3, cyc = elbowY + 8 + 6 * lift
                k.stroke(line(ax, ay, elbowX, elbowY), shellT.line, k.bold * 2.4)
                k.stroke(line(ax, ay, elbowX, elbowY), shellT.base, k.bold * 1.1)
                k.stroke(line(elbowX, elbowY, cx, cyc - 4), shellT.line, k.bold * 2.4)
                k.stroke(line(elbowX, elbowY, cx, cyc - 4), shellT.base, k.bold * 1.1)
                let open = pinch
                let ca: CGFloat = side * 0.3
                k.with(about(cx, cyc, rot: ca)) {
                    let fing = smooth([cx - side * 2, cyc + 2, cx + side * 3, cyc + 12 + 4 * open, cx + side * 9, cyc + 14 + 3 * open, cx + side * 7, cyc + 5], t: 0.8)
                    k.cel(fing, shellT, k.line)
                    let claw = meadowNotched(cx, cyc, 10.5, 9.5, up: atan2(5 + 9 * open, 15), low: atan2(-2 - 2 * open, 15), side: side, notch: 1)
                    k.cel(claw, shellT, k.bold, k: 0.15)
                }
            }
            let saL = crabStalk(-1, stalkA, f.mood == .dizzy)
            let saR = crabStalk(1, stalkA, f.mood == .dizzy)
            let lx = 41 - sin(saL) * stalk + sx0, rxp = 59 - sin(saR) * stalk + sx0
            let ly = cy + 18 + cos(saL) * stalk, ry = cy + 18 + cos(saR) * stalk
            k.stroke(line(41, cy + 14, lx, ly), shellT.line, k.bold * 2.2)
            k.stroke(line(41, cy + 14, lx, ly), shellT.base, k.bold * 0.9)
            k.stroke(line(59, cy + 14, rxp, ry), shellT.line, k.bold * 2.2)
            k.stroke(line(59, cy + 14, rxp, ry), shellT.base, k.bold * 0.9)
            let body = smooth([18, cy + 2, 22, cy + 16, 36, cy + 24, 64, cy + 24, 78, cy + 16, 82, cy + 2, 70, cy - 12, 30, cy - 12], t: 0.85)
            k.cel(body, shellT, k.bold, k: 0.12)
            k.fill(ell(34, cy + 16, 6, 3, 0.3), Tone(0xffffff, 0.45))
            let ex: CGFloat = 50 + sx0
            let ey = max(ly, ry) + 2
            let look: CGFloat = f.mood == .fleeing ? 0.3 : 0.12
            k.eye(lx, ly + 2, 8.5, 10.5, iris: iris, edge: shellT.line, lid: shellT.base, side: -1, look: look)
            k.eye(rxp, ry + 2, 8.5, 10.5, iris: iris, edge: shellT.line, lid: shellT.base, side: 1, look: look)
            k.brow(lx, ly + 17, 10, side: -1, edge: shellT.line)
            k.brow(rxp, ry + 17, 10, side: 1, edge: shellT.line)
            k.blush(31 + sx0, cy + 4, 4.6, 2.6)
            k.blush(69 + sx0, cy + 4, 4.6, 2.6)
            k.mouth(ex, cy + 8, 14, 9, edge: shellT.line)
            switch f.variant {
            case 1:
                let hat = MascotTones(.white, shade: Tone(0xd8dcef), line: Tone(0x1f2a5a))
                k.cel(smooth([36, cy + 21, 38, cy + 30, 50, cy + 33, 62, cy + 30, 64, cy + 21, 50, cy + 19], t: 0.8), hat, k.line, k: 0.12)
                k.fill(rrect(36.5, cy + 21, 27, 3.6, 1.5), Tone(0x3a6ae0))
                k.stroke(smooth([36, cy + 21, 38, cy + 30, 50, cy + 33, 62, cy + 30, 64, cy + 21, 50, cy + 19], t: 0.8), hat.line, k.line)
            case 3:
                meadowDaisy(k, 26, cy + 18, 5, petal: .white, center: Tone(0xffd23a), line: shellT.line)
            case 4:
                k.cel(softStar(73, cy + 19, 9, inner: 0.5, spin: .pi / 2 + 0.2), MascotTones(Tone(0xff7a9a), line: Tone(0x6a1a34)), k.line)
            default:
                break
            }
            k.marks(80, ey + 10, 12, edge: shellT.line)
        }
    }

    private static func meadowNotched(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat, up: CGFloat, low: CGFloat, side: CGFloat, notch: CGFloat) -> CGPath {
        var pts: [CGPoint] = [pt(cx + side * notch, cy + notch)]
        let span = 2 * .pi + low - up
        for i in 0...18 {
            let a = up + span * CGFloat(i) / 18
            pts.append(pt(cx + side * cos(a) * rx, cy + sin(a) * ry))
        }
        return polyP(pts)
    }

    private static func crabStalk(_ side: CGFloat, _ a: CGFloat, _ dizzy: Bool) -> CGFloat {
        side * -0.15 + a * side + (dizzy ? a : 0)
    }

    static func frog(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, Tone, Tone)] = [
            (MascotTones(Tone(0x7cd06a), shade: Tone(0x4ea84a), line: Tone(0x1e4a1a)), Tone(0xe0a020), Tone(0xeaf8c8)),
            (MascotTones(Tone(0x9ade5a), shade: Tone(0x68b43a), line: Tone(0x2a4a12)), Tone(0x8a4a10), Tone(0xf2fcd0)),
            (MascotTones(Tone(0x4aa8f0), shade: Tone(0x2a78d0), line: Tone(0x102a5a)), Tone(0xf0b020), Tone(0xd8f0ff)),
            (MascotTones(Tone(0xff9ac0), shade: Tone(0xec6a9c), line: Tone(0x6a1a40)), Tone(0x22a06c), Tone(0xfff0f6)),
            (MascotTones(Tone(0xffc84a), shade: Tone(0xf0962a), line: Tone(0x5e2e08)), Tone(0x2a6fe0), Tone(0xfff6d8)),
        ]
        let (skin, iris, belly) = f.pick(looks)
        let bellyT = MascotTones(belly, shade: belly.mix(skin.shade, 0.35), line: skin.line)
        let t = f.t
        let b = k.bounce()
        let air = f.airborne
        let st = f.stretch
        var tilt: CGFloat = 0, sac: CGFloat = 0, armUp: CGFloat = 0
        switch f.mood {
        case .calm:
            sac = max(0, f.twitch)
        case .sleepy:
            armUp = -0.3
        case .startled:
            armUp = 2.25
        case .fleeing:
            armUp = 0.8 + 0.4 * f.swing
        case .dizzy:
            tilt = 0.12 * sin(t)
        }
        k.with(about(50, 30, rot: tilt).concatenating(about(50, 4, sx: b.sx, sy: b.sy))) {
            k.both { side in
                if air && st > 0 {
                    let ext = st
                    k.cel(ell(50 + side * 14, 12 - 4 * ext, 5.5, 11 + 3 * ext, side * 0.35), skin, k.line, k: 0.12)
                    k.cel(ell(50 + side * 19, 2 - 6 * ext, 6.5, 3, side * 0.2), skin, k.line)
                } else {
                    k.cel(ell(50 + side * 22, 12, 11, 8, side * -0.3), skin, k.bold, k: 0.12)
                    k.cel(smooth([50 + side * 14, 4, 50 + side * 30, 3, 50 + side * 33, 7, 50 + side * 27, 8, 50 + side * 22, 6], t: 0.7), skin, k.line)
                }
            }
            k.cel(ell(50, 16, 16, 13), skin, k.bold, k: 0.12)
            k.cel(ell(50, 14, 10, 9), bellyT, k.line, k: 0.1)
            let frogArms = {
                k.both { side in
                    let a = side * armUp
                    k.with(about(50 + side * 11, 22, rot: a)) {
                        k.cel(ell(50 + side * 11, 13, 3.6, 7.5, side * 0.15), skin, k.line)
                        k.cel(ell(50 + side * 12, 6, 4.6, 2.6), skin, k.line * 0.9)
                    }
                }
            }
            if f.mood != .startled { frogArms() }
            let headY: CGFloat = f.mood == .sleepy ? 42 : 45
            let bump: CGFloat = f.mood == .sleepy ? 61 : (f.mood == .startled ? 68 : 65)
            let b0 = bump
            let headP = smooth([16, headY, 20, headY - 13, 33, headY - 20.5, 50, headY - 22, 67, headY - 20.5, 80, headY - 13, 84, headY, 81, headY + 10, 78, b0 + 3, 74, b0 + 10, 66, b0 + 12.5, 58, b0 + 9.5, 54.5, b0 + 2, 50, b0 - 1.5, 45.5, b0 + 2, 42, b0 + 9.5, 34, b0 + 12.5, 26, b0 + 10, 22, b0 + 3, 19, headY + 10], t: 0.9)
            k.cel(headP, skin, k.bold, k: 0.1)
            k.fill(ell(26, bump + 6, 4.5, 2.6, 0.5), Tone(0xffffff, 0.45))
            if f.variant == 2 {
                for (x, y, r) in [(22, 42, 3.2), (78, 44, 2.8), (30, 52, 2.2), (72, 54, 2.4)] as [(CGFloat, CGFloat, CGFloat)] {
                    k.fill(circ(x, y, r), skin.line.mix(skin.shade, 0.3))
                }
            }
            if sac > 0 {
                k.cel(ell(52, headY - 18, 10, 6), bellyT, k.line)
            }
            let fx: CGFloat = f.mood == .fleeing ? 2.5 : 0
            let look: CGFloat = f.mood == .fleeing ? 0.3 : 0.12
            k.eye(34 + fx, bump + 1, 8, 10, iris: iris, edge: skin.line, lid: skin.base, side: -1, look: look)
            k.eye(66 + fx, bump + 1, 8, 10, iris: iris, edge: skin.line, lid: skin.base, side: 1, look: look)
            k.brow(34 + fx, bump + 15, 10, side: -1, edge: skin.line)
            k.brow(66 + fx, bump + 15, 10, side: 1, edge: skin.line)
            k.blush(22 + fx, headY - 2, 4.6, 2.6)
            k.blush(78 + fx, headY - 2, 4.6, 2.6)
            k.mouth(50 + fx, headY - 2, 22, 10, edge: skin.line)
            k.fill(circ(46, headY + 6, 1.2), skin.line)
            k.fill(circ(54, headY + 6, 1.2), skin.line)
            if f.mood == .startled { frogArms() }
            switch f.variant {
            case 1:
                let gold = MascotTones(Tone(0xffd23a), shade: Tone(0xf0a020), line: Tone(0x6a3a08))
                let crown = poly([39, bump + 8, 39, bump + 20, 44, bump + 14, 50, bump + 22, 56, bump + 14, 61, bump + 20, 61, bump + 8])
                k.cel(crown, gold, k.line, k: 0.15)
                k.fill(circ(50, bump + 12, 1.8), Tone(0xff4d6a))
            case 3:
                meadowDaisy(k, 74, bump + 11, 5.5, petal: .white, center: Tone(0xffd23a), line: skin.line)
            case 4:
                let pad = MascotTones(Tone(0x5ac86a), shade: Tone(0x38a04a), line: Tone(0x14401a))
                k.cel(meadowNotched(50, bump + 11, 13, 5, up: 0.75, low: 0.15, side: 1, notch: 0), pad, k.line, k: 0.15)
            default:
                break
            }
            k.marks(82, bump + 16, 12, edge: skin.line)
        }
    }

    static func sun(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, MascotTones, Tone)] = [
            (MascotTones(Tone(0xffd84a), shade: Tone(0xf5a623), line: Tone(0x8a4210)), MascotTones(Tone(0xffb52e), shade: Tone(0xf08a1a), line: Tone(0x8a4210)), Tone(0xd06a10)),
            (MascotTones(Tone(0xffbc3a), shade: Tone(0xf08420), line: Tone(0x7a2e10)), MascotTones(Tone(0xff8a2a), shade: Tone(0xe0601a), line: Tone(0x7a2e10)), Tone(0x8a3a10)),
            (MascotTones(Tone(0xfff07a), shade: Tone(0xf0c840), line: Tone(0x7a5410)), MascotTones(Tone(0xffd84a), shade: Tone(0xf0b030), line: Tone(0x7a5410)), Tone(0x22a06c)),
            (MascotTones(Tone(0xffb894), shade: Tone(0xf08080), line: Tone(0x8a2a3a)), MascotTones(Tone(0xff8a8a), shade: Tone(0xe86070), line: Tone(0x8a2a3a)), Tone(0xc02f86)),
            (MascotTones(Tone(0xffe066), shade: Tone(0xf5b030), line: Tone(0x7a4010)), MascotTones(Tone(0xffc040), shade: Tone(0xf09a20), line: Tone(0x7a4010)), Tone(0x2a6fe0)),
        ]
        let (face, rayT, iris) = f.pick(looks)
        let t = f.t
        let e = f.energy
        var tilt: CGFloat = 0
        var spin: CGFloat = f.phase * 2 * .pi / 6
        var longR: CGFloat = 45, shortR: CGFloat = 40, half: CGFloat = 0.25, sag: CGFloat = 0, stream: CGFloat = 0, wob: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            longR = 38
            shortR = 34
            sag = 3
            spin = 0
            half = 0.24
        case .startled:
            longR = 48
            shortR = 42
            half = 0.16
        case .fleeing:
            stream = 1
        case .dizzy:
            tilt = 0.12 * sin(t)
            wob = 3
        }
        let b = k.bounce(0.4)
        k.with(about(50, 50, rot: tilt).concatenating(about(50, 50, sx: b.sx, sy: b.sy))) {
            let rays = CGMutablePath()
            for i in 0..<12 {
                let a = spin + CGFloat(i) * .pi / 6
                var r = (i % 2 == 0 ? longR : shortR) + 1.6 * sin(t + CGFloat(i) * 1.3) * e
                r += wob * sin(3 * a + 2 * t)
                var tx = 50 + cos(a) * r, ty = 50 + sin(a) * r - sag
                let back = max(0, 0.3 - cos(a))
                tx -= stream * (8 + 3 * sin(2 * t + CGFloat(i))) * back
                ty -= stream * sin(a) * 2 * back
                let rm: CGFloat = 26 + (r - 26) * 0.5
                let dxm = (tx - 50 - cos(a) * r) * 0.5, dym = (ty - 50 - sin(a) * r) * 0.5
                let p = smoothP([pt(50 + cos(a) * 18, 50 + sin(a) * 18),
                                 pt(50 + cos(a - half) * 27, 50 + sin(a - half) * 27),
                                 pt(50 + cos(a - half * 0.6) * rm + dxm, 50 + sin(a - half * 0.6) * rm + dym - sag * 0.5),
                                 pt(tx, ty),
                                 pt(50 + cos(a + half * 0.6) * rm + dxm, 50 + sin(a + half * 0.6) * rm + dym - sag * 0.5),
                                 pt(50 + cos(a + half) * 27, 50 + sin(a + half) * 27)], t: 0.75)
                rays.addPath(p)
            }
            k.cel(rays, rayT, k.line, k: 0.025)
            k.cel(circ(50, 50, 29), face, k.bold, k: 0.12)
            k.fill(ell(36, 66, 6.5, 3.6, 0.6), Tone(0xffffff, 0.5))
            meadowFace(f, k, 50, 53, spread: 21, rx: 8.5, ry: 11, iris: iris, tones: face, mouthY: 37.5, mouthW: 14, mouthH: 9)
            switch f.variant {
            case 1:
                let gl = MascotTones(Tone(0x3a3a6a), shade: Tone(0x26264a), line: Tone(0x14142a))
                k.with(about(50, 77, rot: 0.08)) {
                    k.stroke(line(37, 77, 63, 77), gl.line, k.bold)
                    k.cel(rrect(26, 72, 21, 10, 4.5), gl, k.line, k: 0.15)
                    k.cel(rrect(53, 72, 21, 10, 4.5), gl, k.line, k: 0.15)
                    k.fill(ell(31, 79, 3, 1.4, 0.3), Tone(0xffffff, 0.7))
                    k.fill(ell(58, 79, 3, 1.4, 0.3), Tone(0xffffff, 0.7))
                }
            case 2:
                meadowDaisy(k, 72, 72, 6.5, petal: .white, center: Tone(0xff8a3a), line: face.line)
            case 3:
                meadowBow(k, 68, 76, 7, MascotTones(Tone(0xff5fae), line: Tone(0x8a2e5e)), rot: -0.3)
            case 4:
                let cl = MascotTones(Tone(0xffffff), shade: Tone(0xc8d6f5), line: Tone(0x3a4a8a))
                let cloud = smooth([12, 13, 30, 12.5, 44, 13, 47.5, 19, 44, 26, 37.5, 28.5, 33, 35.5, 25, 37, 18.5, 31, 11, 29, 8, 21], t: 0.9)
                k.cel(cloud, cl, k.bold, k: 0.15)
                k.fill(circ(24, 20, 1.3), cl.line)
                k.fill(circ(31, 20, 1.3), cl.line)
                k.stroke(arc(25, 17, 30, 17, dip: 1.6), cl.line, k.line * 0.7)
            default:
                break
            }
            k.marks(82, 80, 13, edge: face.line)
        }
    }
}
