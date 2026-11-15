import Foundation
import CoreGraphics
import ScuttleCore

extension MascotArt {
    private static func mascotPartyFace(_ f: FigureFrame, _ k: MascotKit, _ x: CGFloat, _ y: CGFloat, spread: CGFloat, rx: CGFloat, ry: CGFloat, iris: Tone, tones: MascotTones, far: CGFloat = 1, mouthX: CGFloat, mouthY: CGFloat, mouthW: CGFloat = 12, mouthH: CGFloat = 8, blush: Bool = true) {
        let fx: CGFloat = f.mood == .fleeing ? 2.5 : 0
        let lx = x - spread / 2 + fx
        let rx2 = x + spread / 2 + fx
        let look: CGFloat = f.mood == .fleeing ? 0.3 : 0.14
        if blush {
            k.blush(lx - rx * 1.3, y - ry * 1.2, 4.4, 2.5)
            k.blush(rx2 + rx * far * 1.3, y - ry * 1.2, 4.4, 2.5)
        }
        k.eye(lx, y, rx, ry, iris: iris, edge: tones.line, lid: tones.base, side: -1, look: look)
        k.eye(rx2, y, rx * far, ry * far, iris: iris, edge: tones.line, lid: tones.base, side: 1, look: look)
        k.brow(lx, y + ry + 4.5, rx * 1.25, side: -1, edge: tones.line)
        k.brow(rx2, y + ry * far + 4.5, rx * far * 1.25, side: 1, edge: tones.line)
        k.mouth(mouthX + fx, mouthY, mouthW, mouthH, edge: tones.line)
    }

    private static func mascotPartyHat(_ k: MascotKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ rot: CGFloat, _ cone: MascotTones, _ stripe: Tone) {
        k.with(about(x, y, rot: rot)) {
            let w: CGFloat = 10 * s
            let h: CGFloat = 24 * s
            let p = poly([x - w, y, x + w, y, x, y + h])
            k.cel(p, cone, k.line, k: 0.15)
            k.clip(p) {
                k.fill(poly([x - w, y + h * 0.28, x + w, y + h * 0.46, x + w, y + h * 0.62, x - w, y + h * 0.44]), stripe)
            }
            k.stroke(p, cone.line, k.line)
            k.fs(circ(x, y + h, 3.2 * s + 0.9), stripe, cone.line, k.line * 0.85)
        }
    }

    private static func mascotPartyBow(_ k: MascotKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ rot: CGFloat, _ t: MascotTones) {
        k.with(about(x, y, rot: rot)) {
            let l = smooth([x, y, x - 12 * s, y + 7.5 * s, x - 13 * s, y - 6.5 * s], t: 0.45)
            let r = smooth([x, y, x + 12 * s, y + 7.5 * s, x + 13 * s, y - 6.5 * s], t: 0.45)
            k.cel(l, t, k.line * 0.9)
            k.cel(r, t, k.line * 0.9)
            k.fs(circ(x, y, 3.2 * s + 0.6), t.base, t.line, k.line * 0.9)
        }
    }

    private static func mascotPartyFlower(_ k: MascotKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ petal: Tone, _ edge: Tone) {
        var petals: [CGPath] = []
        for i in 0..<5 {
            let a = CGFloat(i) * 2 * .pi / 5 + 0.3
            petals.append(circ(x + cos(a) * 4.6 * s, y + sin(a) * 4.6 * s, 3.9 * s))
        }
        for p in petals { k.stroke(p, edge, k.line * 1.8) }
        for p in petals { k.fill(p, petal) }
        k.fs(circ(x, y, 2.9 * s), Tone(0xffd23f), edge, k.line * 0.7)
    }

    private static func mascotPartySparkle(_ k: MascotKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ tone: Tone, _ edge: Tone) {
        guard s > 1 else { return }
        let p = star(x, y, s, points: 4, inner: 0.38)
        k.stroke(p, edge, k.line * 1.5)
        k.fill(p, tone)
    }

    static func balloon(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, Tone)] = [
            (MascotTones(Tone(0xff4d5e), shade: Tone(0xd42848), line: Tone(0x6e0f24)), Tone(0x2f7de0)),
            (MascotTones(Tone(0x55a8ff), shade: Tone(0x2f72dc), line: Tone(0x16306e)), Tone(0xff7a2f)),
            (MascotTones(Tone(0xff8fc8), shade: Tone(0xe85aa4), line: Tone(0x7a1e52)), Tone(0x8a3ad8)),
            (MascotTones(Tone(0xffd23f), shade: Tone(0xf0a21c), line: Tone(0x7a4a08)), Tone(0x2f7de0)),
            (MascotTones(Tone(0x6edc8a), shade: Tone(0x34b066), line: Tone(0x14583a)), Tone(0xd0408a)),
        ]
        let (tones, iris) = f.pick(looks)
        let v = f.variant % 5
        let t = f.t
        let b = k.bounce()
        var tilt: CGFloat = 0, sx: CGFloat = 1, sy: CGFloat = 1
        var s0: CGFloat = 2 * sin(t), s1: CGFloat = 4 * sin(t - 0.9), s2: CGFloat = 6 * sin(t - 1.8)
        var endY: CGFloat = 0
        var la = (x: CGFloat(20), y: CGFloat(38) + 2 * f.swing, a: CGFloat(-0.7) + 0.25 * f.swing)
        var ra = (x: CGFloat(80), y: CGFloat(38) - 2 * f.swing, a: CGFloat(0.7) - 0.25 * f.swing)
        switch f.mood {
        case .calm:
            ra.a -= 0.8 * max(0, f.twitch)
            ra.y += 6 * max(0, f.twitch)
            s2 += 3 * f.twitch
        case .sleepy:
            tilt = 0.14
            sx = 1.06
            sy = 0.9
            s0 = 1
            s1 = 2.5 + sin(t)
            s2 = 2 + 1.5 * sin(t)
            la = (21, 40, -0.25)
            ra = (79, 38, 0.3)
        case .startled:
            sx = 0.93
            sy = 1.1
            s0 = 0.5
            s1 = -1
            s2 = 1.5 * sin(2 * t)
            la = (14, 70, 0.2 + 0.1 * f.swing2)
            ra = (86, 72, -0.2 - 0.1 * f.swing2)
        case .fleeing:
            tilt = -0.12
            s0 = -4
            s1 = -12 + 2 * sin(2 * t)
            s2 = -22 + 3 * sin(2 * t + 1)
            endY = 6
            la = (14, 58, 1.25 + 0.2 * f.swing)
            ra = (80, 36, 1.5)
        case .dizzy:
            tilt = 0.13 * sin(t)
            s0 = 3 * sin(2 * t)
            s1 = -5 * sin(2 * t)
            s2 = 6 * sin(2 * t)
            la = (15, 58 + 4 * f.swing, 1.2)
            ra = (85, 46 - 4 * f.swing, -1.2)
        }
        let tr = about(50, 50, rot: tilt).concatenating(about(50, 24, sx: sx * b.sx, sy: sy * b.sy))
        k.with(tr) {
            let str = smooth([50, 21, 50 + s0, 15 + endY * 0.3, 50 + s1, 8 + endY * 0.6, 50 + s2, 1 + endY], closed: false)
            k.stroke(str, tones.line, k.width(1.9, minPt: 0.75))
            k.cel(ell(la.x, la.y, 3.8, 7.2, la.a), tones, k.line * 0.92)
            k.cel(ell(ra.x, ra.y, 3.8, 7.2, ra.a), tones, k.line * 0.92)
            let body = v == 2 ? heart(50, 57, 31) : smooth([50, 92, 71, 87, 81, 68, 77, 46, 63, 30, 50, 25, 37, 30, 23, 46, 19, 68, 29, 87])
            k.cel(body, tones, k.bold, k: 0.12)
            if v == 3 {
                let dots: [(CGFloat, CGFloat, CGFloat)] = [(27, 77, 4.2), (72, 82, 3.8), (22, 57, 3.2), (79, 61, 3.4), (34, 35, 3.4), (66, 34, 3.2), (50, 88, 3)]
                k.clip(body) {
                    for d in dots { k.fill(circ(d.0, d.1, d.2), Tone(0xfff6c8)) }
                }
            }
            k.fill(ell(31, 75, 4.2, 8, -0.5), Tone(0xffffff, 0.82))
            k.fill(circ(37.5, 85.5, 2.3), Tone(0xffffff, 0.82))
            k.fs(smooth([50, 26.5, 55.5, 19.5, 50, 18.5, 44.5, 19.5], t: 0.6), tones.shade, tones.line, k.line * 0.9)
            mascotPartyFace(f, k, 50, 60, spread: 19, rx: 8.2, ry: 10.8, iris: iris, tones: tones, mouthX: 50, mouthY: 45, mouthW: 13, mouthH: 8.5)
            switch v {
            case 1:
                mascotPartyHat(k, 61, 86, 0.95, -0.38, MascotTones(Tone(0xffd23f), line: Tone(0x6a4208)), Tone(0xff5fae))
            case 4:
                mascotPartyBow(k, 50, 19, 0.62, 0, MascotTones(Tone(0xff5fae), line: Tone(0x7a1e52)))
            default:
                break
            }
            k.marks(82, 90, 13, edge: tones.line)
        }
    }

    static func star(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, Tone)] = [
            (MascotTones(Tone(0xffd43a), shade: Tone(0xf2a01e), line: Tone(0x7a4606)), Tone(0x2f7de0)),
            (MascotTones(Tone(0xff9ccf), shade: Tone(0xec66a8), line: Tone(0x7a1e52)), Tone(0x7a3ad8)),
            (MascotTones(Tone(0x8fd4ff), shade: Tone(0x4fa0ec), line: Tone(0x173f7a)), Tone(0xff7a2f)),
            (MascotTones(Tone(0x8ef0c0), shade: Tone(0x46c88e), line: Tone(0x145a40)), Tone(0xd0408a)),
            (MascotTones(Tone(0xd2b4ff), shade: Tone(0xa27ae8), line: Tone(0x40207a)), Tone(0xe08a10)),
        ]
        let (tones, iris) = f.pick(looks)
        let v = f.variant % 5
        let t = f.t
        let b = k.bounce()
        let cx: CGFloat = 50, cy: CGFloat = 46, ri: CGFloat = 26
        var ang: [CGFloat] = [90, 18, -54, -126, -198].map { $0 * .pi / 180 }
        var len: [CGFloat] = [46, 46, 46, 46, 46]
        var tilt: CGFloat = 0, sy: CGFloat = 1, glint: CGFloat = 1
        switch f.mood {
        case .calm:
            ang[1] += 0.24 * max(0, f.twitch) + 0.06 * f.swing
            ang[4] -= 0.06 * f.swing
            ang[2] += 0.07 * f.swing
            ang[3] += 0.07 * f.swing
        case .sleepy:
            ang[1] -= 0.3
            ang[4] += 0.3
            ang[0] += 0.18
            len[0] = 42
            ang[2] -= 0.1
            ang[3] += 0.1
            sy = 0.93
            glint = 0.5
        case .startled:
            ang[1] += 0.45
            ang[4] -= 0.45
            ang[2] += 0.16
            ang[3] -= 0.16
            len[1] = 49
            len[4] = 49
            sy = 1.05
            glint = 1.3
        case .fleeing:
            tilt = -0.15
            ang[1] += 0.7 + 0.1 * f.swing2
            ang[4] -= 0.35
            ang[2] += 0.3 * f.swing
            ang[3] -= 0.3 * f.swing
        case .dizzy:
            tilt = 0.12 * sin(t)
            ang[1] += 0.3 * sin(t)
            ang[4] += 0.3 * sin(t + 1)
        }
        var pts: [CGPoint] = []
        for i in 0..<5 {
            let a = ang[i]
            pts.append(pt(cx + cos(a) * len[i], cy + sin(a) * len[i]))
            let next = i == 4 ? ang[0] - 2 * .pi : ang[i + 1]
            let m = (a + next) / 2
            pts.append(pt(cx + cos(m) * ri, cy + sin(m) * ri))
        }
        let spots: [(CGFloat, CGFloat)] = [(91, 80), (9, 76), (90, 14)]
        for (i, s) in spots.enumerated() {
            let r = 5.5 * glint * max(0, sin(2 * t + CGFloat(i) * 2.1))
            mascotPartySparkle(k, s.0, s.1, r, Tone(0xfffbe0), tones.line)
        }
        let tr = about(cx, cy, rot: tilt).concatenating(about(50, 30, sx: b.sx / sy.squareRoot(), sy: b.sy * sy))
        k.with(tr) {
            let body = smoothP(pts, t: 0.45)
            k.cel(body, tones, k.bold, k: 0.1)
            k.fill(ell(33, 62, 2.6, 5, -0.6), Tone(0xffffff, 0.8))
            mascotPartyFace(f, k, 50, 50, spread: 17, rx: 7, ry: 9.4, iris: iris, tones: tones, mouthX: 50, mouthY: 38.5, mouthW: 11, mouthH: 7)
            let a0 = ang[0]
            switch v {
            case 1:
                let bx = cx + cos(a0 + 0.3) * 33, by = cy + sin(a0 + 0.3) * 33
                mascotPartyBow(k, bx, by, 0.6, 0.35, MascotTones(Tone(0xff4d8a), line: Tone(0x6e1446)))
            case 2:
                let hx = cx + cos(a0) * (len[0] - 13), hy = cy + sin(a0) * (len[0] - 13)
                mascotPartyHat(k, hx, hy, 0.62, a0 - .pi / 2 - 0.12, MascotTones(Tone(0xff6fb8), line: Tone(0x6e1446)), Tone(0xffe066))
            case 3:
                let a4 = ang[4]
                mascotPartyFlower(k, cx + cos(a4) * 36, cy + sin(a4) * 36, 0.95, Tone(0xff7ab0), tones.line)
            case 4:
                let hx = cx + cos(a0) * (len[0] - 11), hy = cy + sin(a0) * (len[0] - 11)
                k.with(about(hx, hy, rot: a0 - .pi / 2)) {
                    let crown = poly([hx - 8, hy, hx + 8, hy, hx + 9.5, hy + 10, hx + 4.5, hy + 5, hx, hy + 12, hx - 4.5, hy + 5, hx - 9.5, hy + 10])
                    k.cel(crown, MascotTones(Tone(0xffd23f), line: Tone(0x6a4208)), k.line * 0.9, k: 0.15)
                    k.fill(circ(hx, hy + 4, 1.8), Tone(0xff4d8a))
                }
            default:
                break
            }
            k.marks(80, 78, 12, edge: tones.line)
        }
    }

    private static func sparklerCorona(_ f: FigureFrame, _ k: MascotKit, _ cx: CGFloat, _ cy: CGFloat, _ scale: CGFloat, _ t: MascotTones, lean: CGFloat, swirl: CGFloat) {
        var n = Noise(f.frameIndex * 31 + 7)
        let spin = CGFloat(f.frameIndex % 4) * 0.09 + swirl
        let count = 17
        var pts: [CGPoint] = []
        for i in 0..<(2 * count) {
            let a = spin + CGFloat(i) * .pi / CGFloat(count) + n.range(-0.06, 0.06)
            let tip = i % 2 == 0
            let r: CGFloat = tip ? n.range(28, 39) * scale : n.range(22.5, 25)
            var x = cx + cos(a) * r
            let y = cy + sin(a) * r * (1 - lean * 0.15)
            if tip { x -= lean * (r - 20) * (1 + cos(a)) * 0.6 }
            pts.append(pt(x, y))
        }
        let ring = polyP(pts)
        k.cel(ring, t, k.line, k: 0.1)
        for i in 0..<5 {
            let a = spin * 1.6 + CGFloat(i) * 1.257 + n.range(-0.25, 0.25)
            let r = n.range(37, 47) * scale
            let ox = -lean * 14 * (1 + cos(a))
            let sz = n.range(2.8, 5.2) * scale * ((i + f.frameIndex) % 3 == 0 ? 0.5 : 1)
            mascotPartySparkle(k, cx + cos(a) * r + ox, cy + sin(a) * r, sz, i % 2 == 0 ? Tone(0xfffbe8) : t.base.lift(0.45), t.line)
        }
    }

    static func sparkler(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, MascotTones, Tone)] = [
            (MascotTones(Tone(0xffb02a), shade: Tone(0xff7a1a), line: Tone(0x6a2a06)), MascotTones(Tone(0xfff4c8), shade: Tone(0xffd06a), line: Tone(0x6a3406)), Tone(0x2f7de0)),
            (MascotTones(Tone(0xff6fb8), shade: Tone(0xe0408a), line: Tone(0x6e1446)), MascotTones(Tone(0xfff0f6), shade: Tone(0xffbcd8), line: Tone(0x6e1446)), Tone(0x7a3ad8)),
            (MascotTones(Tone(0x4fc8ff), shade: Tone(0x2a90e0), line: Tone(0x14306e)), MascotTones(Tone(0xf0fbff), shade: Tone(0xb8e4ff), line: Tone(0x14306e)), Tone(0xff7a2f)),
            (MascotTones(Tone(0x9ff05a), shade: Tone(0x5cc43a), line: Tone(0x1e5014)), MascotTones(Tone(0xf8ffe8), shade: Tone(0xd4f4a0), line: Tone(0x1e5014)), Tone(0xd0408a)),
            (MascotTones(Tone(0xc58cff), shade: Tone(0x9a5ae8), line: Tone(0x3a1a6e)), MascotTones(Tone(0xfaf2ff), shade: Tone(0xdcc4ff), line: Tone(0x3a1a6e)), Tone(0xe08a10)),
        ]
        let (corona, head, iris) = f.pick(looks)
        let v = f.variant % 5
        let t = f.t
        let b = k.bounce()
        let stepA = 4.5 * cos(t) * f.energy
        let liftA = max(0, -sin(t)) * 3 * f.energy
        let liftB = max(0, sin(t)) * 3 * f.energy
        let bob = 1.4 * abs(sin(t)) * f.energy
        var tilt: CGFloat = 0, headTilt: CGFloat = 0, headUp: CGFloat = 0
        var burst: CGFloat = 1, lean: CGFloat = 0, swirl: CGFloat = 0
        let swingArm = 3 * cos(t) * f.energy
        var hl = (x: CGFloat(36) - swingArm, y: CGFloat(24))
        var hr = (x: CGFloat(64) + swingArm, y: CGFloat(24))
        switch f.mood {
        case .calm:
            hr = (66 + 2 * max(0, f.twitch), 24 + 16 * max(0, f.twitch))
        case .sleepy:
            burst = 0.72
            headTilt = 0.14
            headUp = -2
            hl = (40, 19)
            hr = (60, 19)
        case .startled:
            burst = 1.2
            headUp = 3
            hl = (30, 44 + 2 * f.swing2)
            hr = (70, 44 - 2 * f.swing2)
        case .fleeing:
            tilt = -0.07
            lean = 1
            hl = (32, 34 + 2 * f.swing)
            hr = (36, 22 - 2 * f.swing)
        case .dizzy:
            tilt = 0.12 * sin(t)
            swirl = t
            hl = (34, 30 + 4 * f.swing)
            hr = (66, 30 - 4 * f.swing)
        }
        let stick = MascotTones(Tone(0xc4cadb), shade: Tone(0x8c96b0), line: Tone(0x2c3450))
        let limbW = k.width(3.2, minPt: 1.0)
        k.with(about(50, 4, rot: tilt)) {
            let feet: [(CGFloat, CGFloat, CGFloat)] = [(46, stepA, liftA), (54, -stepA, liftB)]
            for (x, s, l) in feet {
                k.stroke(line(x, 20, x + s, 7 + l), stick.line, limbW)
                k.fs(ell(x + s + 2, 5.5 + l, 5.4, 3.2), corona.base, corona.line, k.line * 0.9)
            }
            k.with(CGAffineTransform(translationX: 0, y: bob)) {
                let hands: [(CGFloat, CGFloat)] = [(hl.x, hl.y), (hr.x, hr.y)]
                for h in hands {
                    k.stroke(line(50, 31, h.0, h.1), stick.line, limbW)
                    k.fs(circ(h.0, h.1, 3.6), head.base, head.line, k.line * 0.85)
                }
                let rod = rrect(45, 16, 10, 30, 4)
                k.cel(rod, stick, k.line, k: 0.15)
                if v == 2 {
                    k.clip(rod) {
                        for i in 0..<4 {
                            let y0 = 14 + CGFloat(i) * 9
                            k.fill(poly([44, y0, 56, y0 + 5, 56, y0 + 9, 44, y0 + 4]), Tone(0xff5f6e))
                        }
                    }
                    k.stroke(rod, stick.line, k.line)
                }
                if v == 1 {
                    mascotPartyBow(k, 50, 31, 0.72, 0, MascotTones(Tone(0xff4d8a), line: Tone(0x6e1446)))
                }
                if v == 3 {
                    let w = 2 * sin(2 * t) + (f.mood == .fleeing ? 4 : 0)
                    let scarf = MascotTones(Tone(0xff5f6e), line: Tone(0x6a1420))
                    k.cel(smooth([46, 38, 36, 32 + w, 26, 27 + w * 1.5, 28, 23 + w, 38, 28 + w * 0.5, 47, 33], t: 0.7), scarf, k.line * 0.9)
                    k.cel(rrect(42, 33, 16, 7, 3.5), scarf, k.line * 0.9, k: 0.15)
                }
                k.with(about(50, 40, rot: headTilt).concatenating(CGAffineTransform(translationX: 0, y: headUp)).concatenating(about(50, 40, sx: b.sx, sy: b.sy))) {
                    sparklerCorona(f, k, 50, 63, burst, corona, lean: lean, swirl: swirl)
                    k.cel(circ(50, 63, 23), head, k.bold, k: 0.12)
                    k.fill(ell(38, 75, 2.6, 4.5, -0.6), Tone(0xffffff, 0.9))
                    mascotPartyFace(f, k, 51, 64, spread: 17, rx: 7.2, ry: 9.6, iris: iris, tones: head, mouthX: 52, mouthY: 52, mouthW: 11, mouthH: 7)
                    if v == 4 && f.mood != .dizzy {
                        let fx: CGFloat = f.mood == .fleeing ? 2.5 : 0
                        k.both { s in
                            let p = star(51 + s * 8.5 + fx, 64, 12.5, points: 5, inner: 0.62)
                            k.stroke(p, head.line, k.line * 2.1)
                            k.stroke(p, Tone(0xff5fae), k.line * 0.95)
                        }
                    }
                    k.marks(80, 86, 12, edge: head.line)
                }
            }
        }
    }

    static func rocket(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, MascotTones, Tone)] = [
            (MascotTones(Tone(0xf4f6fb), shade: Tone(0xbcc6de), line: Tone(0x26305a)), MascotTones(Tone(0xff4d5e), shade: Tone(0xd42848), line: Tone(0x5e0f20)), Tone(0x2f7de0)),
            (MascotTones(Tone(0x8fd0ff), shade: Tone(0x4f98e6), line: Tone(0x173a74)), MascotTones(Tone(0xffd23f), shade: Tone(0xf0a21c), line: Tone(0x6a4208)), Tone(0xff7a2f)),
            (MascotTones(Tone(0xb8f5d8), shade: Tone(0x6ccfa4), line: Tone(0x145a40)), MascotTones(Tone(0xff9a3c), shade: Tone(0xe06a1a), line: Tone(0x6e2e08)), Tone(0x7a3ad8)),
            (MascotTones(Tone(0xdcc8ff), shade: Tone(0xa888ea), line: Tone(0x3a2070)), MascotTones(Tone(0xff6fb8), shade: Tone(0xd8408c), line: Tone(0x6e1446)), Tone(0x22a06c)),
            (MascotTones(Tone(0xffe680), shade: Tone(0xf0b83a), line: Tone(0x6e4a08)), MascotTones(Tone(0x4f8cff), shade: Tone(0x2f5fd8), line: Tone(0x14286e)), Tone(0xd04040)),
        ]
        let (hull, trim, iris) = f.pick(looks)
        let v = f.variant % 5
        let t = f.t
        let b = k.bounce()
        var rot: CGFloat = 0, sx: CGFloat = 1, sy: CGFloat = 1
        var flameL: CGFloat = 24, fin: CGFloat = 0.06 * f.swing2 + 0.08 * f.twitch
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            rot = -0.08
            sx = 0.97
            flameL = 9
            fin = -0.06
        case .startled:
            sx = 1.07
            sy = 0.95
            flameL = 32
            fin = 0.22 + 0.05 * f.swing2
        case .fleeing:
            sx = 1.1
            sy = 0.93
            flameL = 42
            fin = -0.12
        case .dizzy:
            rot = 0.13 * sin(t)
            flameL = 18
        }
        let flick: CGFloat = 1 + 0.16 * sin(4 * t) + 0.08 * sin(6 * t + 1)
        let fl = flameL * flick
        let tr = about(50, 50, rot: rot).concatenating(about(50, 50, sx: sx * b.sy, sy: sy * b.sx))
        k.with(tr) {
            let fire = MascotTones(Tone(0xff8a2a), shade: Tone(0xf0561a), line: Tone(0x7a2208))
            let w0: CGFloat = f.mood == .sleepy ? 6 : 9.5
            let wig = 2.5 * sin(4 * t + 0.5)
            let outer = smooth([14, 50 + w0, 14 - 0.35 * fl, 50 + 1.15 * w0, 14 - fl, 50 + wig, 14 - 0.35 * fl, 50 - 1.15 * w0, 14, 50 - w0], t: 0.8)
            k.cel(outer, fire, k.line, k: 0.1)
            let w1 = w0 * 0.62, l1 = fl * 0.7
            k.fill(smooth([14, 50 + w1, 14 - 0.35 * l1, 50 + 1.1 * w1, 14 - l1, 50 + wig * 0.6, 14 - 0.35 * l1, 50 - 1.1 * w1, 14, 50 - w1], t: 0.8), Tone(0xffd23f))
            let w2 = w0 * 0.3, l2 = fl * 0.42
            k.fill(smooth([14, 50 + w2, 14 - 0.4 * l2, 50 + w2, 14 - l2, 50, 14 - 0.4 * l2, 50 - w2, 14, 50 - w2], t: 0.8), Tone(0xfffbe8))
            if f.mood == .sleepy || f.mood == .dizzy {
                let u = CGFloat(f.frameIndex % 8) / 8
                for j in 0..<2 {
                    let uu = (u + CGFloat(j) * 0.5).truncatingRemainder(dividingBy: 1)
                    let puff = circ(2 - uu * 16, 52 + uu * 8 + CGFloat(j) * 3, 3 + uu * 4)
                    k.fs(puff, Tone(0xeef0f8, 1 - uu * 0.6), hull.line.alpha(1 - uu * 0.6), k.line * 0.8)
                }
            }
            k.with(about(36, 64, rot: fin)) {
                k.cel(smooth([46, 64, 32, 84, 18, 88, 18, 74, 24, 62], t: 0.6), trim, k.line, k: 0.15)
            }
            k.with(about(36, 36, rot: -fin)) {
                k.cel(smooth([46, 36, 32, 16, 18, 12, 18, 26, 24, 38], t: 0.6), trim, k.line, k: 0.15)
            }
            k.cel(rrect(10, 40, 10, 20, 3), MascotTones(Tone(0x9aa4be), line: hull.line), k.line, k: 0.15)
            let body = smooth([95, 50, 85, 63, 66, 72, 40, 72, 24, 66, 16, 50, 24, 34, 40, 28, 66, 28, 85, 37])
            k.cel(body, hull, k.bold, k: 0.12)
            k.clip(body) {
                k.cel(circ(112, 50, 35), trim, k.line * 1.4, k: 0.1)
                if v == 2 {
                    k.fill(rrect(28, 20, 6, 60, 0), trim.base)
                    k.fill(rrect(37, 20, 3, 60, 0), trim.base)
                }
                if v == 4 {
                    k.cel(rrect(70, 20, 7, 60, 2), MascotTones(Tone(0xff4d5e), line: Tone(0x5e0f20)), k.line, k: 0.15)
                }
            }
            k.stroke(body, hull.line, k.bold)
            k.fill(ell(40, 66, 9, 2.4, 0.05), Tone(0xffffff, 0.75))
            if v == 1 {
                k.cel(star(31, 50, 7.5, points: 5, inner: 0.48), MascotTones(Tone(0xffd23f), line: Tone(0x6a4208)), k.line * 0.85, k: 0.15)
            }
            if v == 3 {
                let tip = 105 + 1.5 * f.twitch
                k.stroke(line(94, 50, tip, 50 + 3 * f.twitch + 2 * f.swing2), trim.line, k.line * 1.1)
                k.cel(circ(tip + 1, 50 + 3 * f.twitch + 2 * f.swing2, 3.4), MascotTones(Tone(0xffd23f), line: trim.line), k.line * 0.85)
            }
            if v == 4 {
                let w = 2.5 * sin(4 * t)
                let streamer: CGFloat = f.mood == .fleeing ? 1.4 : 1
                let scarf = MascotTones(Tone(0xff4d5e), line: Tone(0x5e0f20))
                k.cel(smooth([74, 71, 62, 78 + w, 64 - 22 * streamer, 79 + w * 1.6, 62 - 24 * streamer, 73 + w * 1.6, 60, 72 + w * 0.5, 72, 66], t: 0.7), scarf, k.line * 0.9)
            }
            mascotPartyFace(f, k, 57, 53, spread: 15.5, rx: 6.6, ry: 9, iris: iris, tones: hull, far: 0.96, mouthX: 58, mouthY: 40.5, mouthW: 10, mouthH: 6)
            k.marks(80, 76, 12, edge: hull.line)
        }
    }

    private static func bunnyEar(_ k: MascotKit, _ bx: CGFloat, _ by: CGFloat, _ ang: CGFloat, _ len: CGFloat, _ fur: MascotTones, _ inner: Tone) {
        let cx = bx - sin(ang) * len * 0.5
        let cy = by + cos(ang) * len * 0.5
        k.cel(ell(cx, cy, 7.2, len * 0.5 + 3, ang), fur, k.line, k: 0.15)
        let ix = bx - sin(ang) * len * 0.56
        let iy = by + cos(ang) * len * 0.56
        k.fill(ell(ix, iy, 3.4, len * 0.5 - 2.5, ang), inner)
    }

    static func bunny(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, Tone, Tone)] = [
            (MascotTones(Tone(0xfdf8f2), shade: Tone(0xe2cdd8), line: Tone(0x5e3a52)), Tone(0xffa8c0), Tone(0xd0406a)),
            (MascotTones(Tone(0xc89068), shade: Tone(0x9a6440), line: Tone(0x4a2410)), Tone(0xffb8a8), Tone(0x2a6fe0)),
            (MascotTones(Tone(0xc6cadb), shade: Tone(0x9298b4), line: Tone(0x2e3254)), Tone(0xffa8c8), Tone(0x9a4ad8)),
            (MascotTones(Tone(0xf2c28a), shade: Tone(0xd89458), line: Tone(0x6a3a10)), Tone(0xffb0a0), Tone(0x22a06c)),
            (MascotTones(Tone(0xfff6ea), shade: Tone(0xe6d0c0), line: Tone(0x5a3a2a)), Tone(0xffb0b8), Tone(0x2f7de0)),
        ]
        let (fur, inner, iris) = f.pick(looks)
        let v = f.variant % 5
        let t = f.t
        let b = k.bounce()
        let lag: CGFloat = f.airborne ? 0.22 * f.stretch : -0.12 * f.squat
        var angL: CGFloat = 0.28 + 0.04 * f.swing + lag
        var angR: CGFloat = -0.1 - 0.4 * f.twitch + lag
        var lenL: CGFloat = 26, lenR: CGFloat = 27
        var tilt: CGFloat = 0
        var pawL = (x: CGFloat(44), y: CGFloat(15), a: CGFloat(0.3))
        var pawR = (x: CGFloat(59), y: CGFloat(15), a: CGFloat(-0.3))
        let footRot: CGFloat = f.airborne ? -0.45 * f.stretch : 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            angL = 1.55
            angR = 1.25
            lenL = 24
            lenR = 25
            pawL = (45, 13, 1.2)
            pawR = (58, 13, -1.2)
        case .startled:
            angL = 0.08 + lag * 0.3
            angR = -0.06 + lag * 0.3
            lenL = 31
            lenR = 32
            pawL = (27, 38, -0.4)
            pawR = (79, 38, 0.4)
        case .fleeing:
            angL = 1.05 + 0.08 * sin(2 * t)
            angR = 0.85 + 0.08 * sin(2 * t + 1)
            pawL = (40, 17, 1.2)
            pawR = (54, 15, 1.4)
        case .dizzy:
            tilt = 0.12 * sin(t)
            angL = 0.45 + 0.3 * sin(t)
            angR = -1.0
        }
        let pawT = MascotTones(fur.base, shade: fur.shade, line: fur.line)
        k.with(about(50, 4, rot: tilt).concatenating(about(50, 4, sx: b.sx, sy: b.sy))) {
            k.cel(circ(34, 17, 6.5), MascotTones(Tone(0xffffff), shade: Tone(0xdcd6e6), line: fur.line), k.line)
            k.cel(ell(41, 6, 8, 3.8, footRot), fur, k.line)
            k.cel(ell(49, 18, 14, 12.5), fur, k.line, k: 0.15)
            k.cel(ell(60, 6, 8.5, 4, footRot), fur, k.line)
            let earT = v == 4 ? MascotTones(Tone(0xa8724c), shade: Tone(0x80502e), line: fur.line) : fur
            bunnyEar(k, 44, 72, angL, lenL, fur, inner)
            bunnyEar(k, 60, 74, angR, lenR, earT, inner)
            if f.mood != .startled {
                if v == 3 {
                    let carrot = MascotTones(Tone(0xff8a2a), shade: Tone(0xe0601a), line: Tone(0x6a2a08))
                    k.with(about(64, 16, rot: -0.7)) {
                        k.cel(smooth([60, 16, 68, 16, 64, 34], t: 0.4), carrot, k.line * 0.9)
                        k.cel(ell(64, 13, 2.4, 4.5), MascotTones(Tone(0x5fc85a), line: Tone(0x1e4a14)), k.line * 0.8)
                    }
                }
                k.cel(ell(pawL.x, pawL.y, 3.6, 5.2, pawL.a), pawT, k.line * 0.9)
                k.cel(ell(pawR.x, pawR.y, 3.6, 5.2, pawR.a), pawT, k.line * 0.9)
            }
            let head = circ(53, 50, 27)
            k.cel(head, fur, k.bold, k: 0.12)
            if v == 4 {
                k.clip(head) { k.fill(ell(66, 62, 15, 14, 0.3), Tone(0xa8724c)) }
                k.stroke(head, fur.line, k.bold)
            }
            mascotPartyFace(f, k, 52, 56, spread: 19, rx: 7.8, ry: 10.2, iris: iris, tones: fur, far: 0.95, mouthX: 56, mouthY: 41, mouthW: 9.5, mouthH: 6)
            k.cel(ell(56 + (f.mood == .fleeing ? 2.5 : 0), 44, 3.4, 2.5), MascotTones(Tone(0xff8aa8), line: fur.line), k.line * 0.8)
            if f.mood == .startled {
                k.cel(ell(pawL.x, pawL.y, 3.8, 5.4, pawL.a), pawT, k.line * 0.9)
                k.cel(ell(pawR.x, pawR.y, 3.8, 5.4, pawR.a), pawT, k.line * 0.9)
            }
            switch v {
            case 1:
                mascotPartyFlower(k, 42, 74, 1.05, Tone(0xffe066), fur.line)
            case 2:
                mascotPartyBow(k, 61, 75, 0.6, -0.25, MascotTones(Tone(0xff5fae), line: Tone(0x6e1446)))
            default:
                break
            }
            k.marks(78, 80, 13, edge: fur.line)
        }
    }

    static func turtle(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, MascotTones, MascotTones, Tone, Tone)] = [
            (MascotTones(Tone(0xb2e47e), shade: Tone(0x78c050), line: Tone(0x234a14)), MascotTones(Tone(0x3fa860), shade: Tone(0x2a7a46), line: Tone(0x143a24)), MascotTones(Tone(0xf2d27a), shade: Tone(0xd8a84a), line: Tone(0x143a24)), Tone(0x86d66e), Tone(0x8a4a1a)),
            (MascotTones(Tone(0xb2e47e), shade: Tone(0x78c050), line: Tone(0x234a14)), MascotTones(Tone(0x3fb8b0), shade: Tone(0x2a8a8a), line: Tone(0x123c40)), MascotTones(Tone(0xe8f6a0), shade: Tone(0xc4d870), line: Tone(0x123c40)), Tone(0x8ae8de), Tone(0x2f7de0)),
            (MascotTones(Tone(0xbfe88a), shade: Tone(0x84c45a), line: Tone(0x2a4a14)), MascotTones(Tone(0xe0943a), shade: Tone(0xb86a20), line: Tone(0x5a2e08)), MascotTones(Tone(0xfff0b0), shade: Tone(0xe8c870), line: Tone(0x5a2e08)), Tone(0xffc46a), Tone(0x2f7de0)),
            (MascotTones(Tone(0xb8eea0), shade: Tone(0x7ccc62), line: Tone(0x204a1a)), MascotTones(Tone(0x9a6ae0), shade: Tone(0x7448c0), line: Tone(0x2c1a5e)), MascotTones(Tone(0xf0e0ff), shade: Tone(0xc8b0f0), line: Tone(0x2c1a5e)), Tone(0xffd23f), Tone(0xe06a1a)),
            (MascotTones(Tone(0xb2e47e), shade: Tone(0x78c050), line: Tone(0x234a14)), MascotTones(Tone(0xff6a5a), shade: Tone(0xd8403e), line: Tone(0x5e1414)), MascotTones(Tone(0xfff2e0), shade: Tone(0xe8d0b8), line: Tone(0x5e1414)), Tone(0xfffaf0), Tone(0x2f7de0)),
        ]
        let (skin, shell, rim, plate, iris) = f.pick(looks)
        let v = f.variant % 5
        let t = f.t
        let b = k.bounce(0.6)
        var hx: CGFloat = 76, hy: CGFloat = 54 + 1.2 * f.swing
        var tilt: CGFloat = 0
        var legAmp: CGFloat = 3 * f.energy, legOut: CGFloat = 0
        let rock: CGFloat = 0.035 * f.swing * f.energy
        switch f.mood {
        case .calm:
            hy += 1.5 * max(0, f.twitch)
        case .sleepy:
            hx = 69
            hy = 40
            legAmp = 0.6
            legOut = -2
        case .startled:
            hx = 78
            hy = 64
            legOut = 3
        case .fleeing:
            hx = 82
            hy = 48 + 1.5 * f.swing2
            legAmp = 5
        case .dizzy:
            tilt = 0.1 * sin(t)
        }
        k.with(about(40, 4, rot: tilt).concatenating(about(40, 4, sx: b.sx, sy: b.sy))) {
            let legX: [CGFloat] = [14, 28, 50, 62]
            for (i, lx) in legX.enumerated() {
                let ph = t + CGFloat(i) * .pi / 2
                let dx = legAmp * sin(ph) + (lx < 40 ? -legOut : legOut)
                let dy = max(0, cos(ph)) * legAmp * 0.6
                k.cel(ell(lx + dx, 9 + dy, 6.2, 6.5), skin, k.line, k: 0.15)
            }
            k.cel(poly([8, 19, -2, 14 + 1.5 * f.swing, 8, 13]), skin, k.line * 0.9)
            let nx0: CGFloat = 62, ny0: CGFloat = 22
            let nx1 = hx - 5, ny1 = hy - 12
            let nl = hypot(nx1 - nx0, ny1 - ny0)
            let na = -atan2(nx1 - nx0, ny1 - ny0)
            k.cel(ell((nx0 + nx1) / 2, (ny0 + ny1) / 2, 8.5, nl / 2 + 6, na), skin, k.line, k: 0.15)
            k.with(about(38, 14, rot: rock)) {
                let dome = smooth([3, 17, 7, 38, 22, 54, 40, 59, 58, 54, 71, 38, 74, 17])
                k.cel(dome, shell, k.bold, k: 0.1)
                k.clip(dome) {
                    switch v {
                    case 3:
                        let st: [(CGFloat, CGFloat, CGFloat)] = [(38, 37, 9), (17, 30, 6.5), (60, 30, 6.5), (28, 50, 4.5), (50, 50, 4.5)]
                        for s in st { k.fs(star(s.0, s.1, s.2, points: 5, inner: 0.48), plate, shell.line, k.line * 0.8) }
                    case 4:
                        let dt: [(CGFloat, CGFloat, CGFloat)] = [(38, 38, 7), (17, 30, 5), (60, 30, 5), (28, 51, 4), (50, 51, 4), (8, 22, 3.5), (68, 22, 3.5)]
                        for d in dt { k.fill(circ(d.0, d.1, d.2), plate) }
                    default:
                        let hx0: [(CGFloat, CGFloat, CGFloat)] = [(38, 36, 11), (15, 28, 9.5), (61, 28, 9.5)]
                        for h in hx0 {
                            var pp: [CGFloat] = []
                            for j in 0..<6 {
                                let a = CGFloat(j) * .pi / 3
                                pp.append(h.0 + cos(a) * h.2)
                                pp.append(h.1 + sin(a) * h.2 * 0.9)
                            }
                            k.fs(poly(pp), plate, shell.line, k.line * 0.8)
                        }
                    }
                    k.fill(ell(26, 48, 7, 3, 0.4), Tone(0xffffff, 0.45))
                }
                k.stroke(dome, shell.line, k.bold)
                k.cel(rrect(1, 10, 76, 10, 5), rim, k.line, k: 0.15)
            }
            k.with(about(hx, hy - 20, rot: tilt * 0.5)) {
                k.cel(circ(hx, hy, 23), skin, k.bold, k: 0.12)
                k.fill(ell(hx - 9, hy + 15, 4, 2.4, 0.3), Tone(0xffffff, 0.6))
                mascotPartyFace(f, k, hx + 1, hy + 3, spread: 16, rx: 7, ry: 9.4, iris: iris, tones: skin, far: 0.92, mouthX: hx + 3, mouthY: hy - 8, mouthW: 11, mouthH: 7)
                switch v {
                case 1:
                    mascotPartyFlower(k, hx - 11, hy + 19, 1.0, Tone(0xff7ab0), skin.line)
                case 2:
                    mascotPartyHat(k, hx + 3, hy + 20, 0.8, -0.3, MascotTones(Tone(0x5aa8ff), line: Tone(0x14306e)), Tone(0xffe066))
                default:
                    break
                }
                k.marks(hx + 19, hy + 26, 12, edge: skin.line)
            }
        }
    }

    static func fox(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, Tone)] = [
            (MascotTones(Tone(0xff8a2a), shade: Tone(0xe0601a), line: Tone(0x5e2008)), Tone(0x22a06c)),
            (MascotTones(Tone(0xf0603a), shade: Tone(0xc83e24), line: Tone(0x5a140a)), Tone(0x2f7de0)),
            (MascotTones(Tone(0xffb440), shade: Tone(0xe88a1e), line: Tone(0x6a3a08)), Tone(0x7a3ad8)),
            (MascotTones(Tone(0xb8c2d8), shade: Tone(0x8a94b4), line: Tone(0x2a3050)), Tone(0xe0a020)),
            (MascotTones(Tone(0xf59a50), shade: Tone(0xd8702e), line: Tone(0x5e2a0a)), Tone(0x22a06c)),
        ]
        let (fur, iris) = f.pick(looks)
        let v = f.variant % 5
        let white = MascotTones(Tone(0xfff8ee), shade: Tone(0xead6c6), line: fur.line)
        let dark = MascotTones(Tone(0x6a3a3a), shade: Tone(0x4a2428), line: fur.line.dim(0.8))
        let t = f.t
        let b = k.bounce()
        let stepA = 4 * cos(t) * f.energy
        let liftA = max(0, -sin(t)) * 3 * f.energy
        let liftB = max(0, sin(t)) * 3 * f.energy
        let bob = 1.4 * abs(sin(t)) * f.energy
        var ta: CGFloat = 0.08 * f.swing + 0.16 * f.twitch
        var earL: CGFloat = 0, earR: CGFloat = -0.22 * f.twitch, earS: CGFloat = 1
        var tilt: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            ta = 0.6
            earL = 0.35
            earR = -0.35
            earS = 0.9
        case .startled:
            ta = -0.4 + 0.05 * f.swing2
            earS = 1.15
        case .fleeing:
            ta = 0.75 + 0.1 * sin(2 * t)
            earL = 0.5
            earR = 0.45
        case .dizzy:
            tilt = 0.12 * sin(t)
            ta = 0.3 * sin(t)
            earL = 0.3 * sin(t)
            earR = -0.3 * sin(t)
        }
        k.with(about(50, 4, rot: tilt)) {
            let farDark = MascotTones(dark.shade, shade: dark.shade.dim(0.8), line: dark.line)
            let legs: [(CGFloat, CGFloat, CGFloat)] = [(39, -stepA, liftB), (55, stepA, liftA)]
            for l in legs { k.cel(ell(l.0 + l.1, 9 + l.2, 3.6, 6.2), farDark, k.line * 0.9) }
            k.with(CGAffineTransform(translationX: 0, y: bob)) {
                k.with(about(38, 20, rot: ta)) {
                    let tail = smooth([38, 25, 28, 37, 14, 49, 4, 52, 6, 40, 13, 28, 25, 18, 36, 15])
                    k.cel(tail, fur, k.line, k: 0.15)
                    k.clip(tail) { k.cel(circ(5, 48, 10), white, k.line, k: 0.15) }
                    k.stroke(tail, fur.line, k.line)
                }
                k.cel(ell(48, 19, 15, 11), fur, k.line, k: 0.15)
                k.cel(ell(57, 19, 7, 8), white, k.line * 0.9, k: 0.15)
            }
            let legs2: [(CGFloat, CGFloat, CGFloat)] = [(44, stepA, liftA), (60, -stepA, liftB)]
            for l in legs2 { k.cel(ell(l.0 + l.1, 8.5 + l.2, 3.8, 6.4), dark, k.line * 0.9) }
            k.with(CGAffineTransform(translationX: 0, y: bob).concatenating(about(56, 20, sx: b.sx, sy: b.sy))) {
                k.with(about(40, 74, rot: earL).concatenating(about(40, 74, sy: earS))) {
                    let e = smooth([31, 68, 29, 97, 51, 77], t: 0.45)
                    k.cel(e, fur, k.line, k: 0.15)
                    k.fill(smooth([34, 72, 32, 90, 45, 77], t: 0.45), dark.base)
                }
                k.with(about(72, 75, rot: earR).concatenating(about(72, 75, sy: earS))) {
                    let e = smooth([62, 78, 84, 97, 83, 68], t: 0.45)
                    k.cel(e, fur, k.line, k: 0.15)
                    k.fill(smooth([66, 77, 81, 90, 80, 72], t: 0.45), dark.base)
                }
                let head = smooth([57, 81, 72, 78, 82, 67, 89, 47, 80, 35, 69, 27, 57, 24, 45, 27, 34, 35, 25, 47, 32, 67, 42, 78])
                k.cel(head, fur, k.bold, k: 0.12)
                k.clip(head) {
                    k.cel(smooth([18, 20, 18, 47, 32, 46, 45, 40, 57, 43, 69, 40, 82, 46, 96, 47, 96, 20], t: 0.7), white, k.line * 0.9, k: 0.1)
                }
                k.stroke(head, fur.line, k.bold)
                let fx: CGFloat = f.mood == .fleeing ? 2.5 : 0
                k.cel(ell(73 + fx, 41, 11, 7.5, 0.1), white, k.line * 0.9, k: 0.12)
                k.fill(ell(42, 70, 3, 5, 0.5), Tone(0xffffff, 0.55))
                mascotPartyFace(f, k, 57, 57, spread: 18, rx: 7.6, ry: 10, iris: iris, tones: fur, far: 0.9, mouthX: 72, mouthY: 38, mouthW: 9, mouthH: 5.5)
                k.cel(circ(83.5 + fx, 44, 3.6), MascotTones(Tone(0x3a2228), line: fur.line), k.line * 0.8)
                k.fill(ell(82.5 + fx, 45.3, 1.3, 0.8), Tone(0xffffff))
                switch v {
                case 1:
                    let scarf = MascotTones(Tone(0x2fc0b0), shade: Tone(0x1e9288), line: Tone(0x0e3e3a))
                    let w = 2 * sin(2 * t) + (f.mood == .fleeing ? 4 : 0)
                    k.cel(smooth([46, 26, 36, 18 + w, 28, 12 + w * 1.3, 32, 9 + w, 40, 16, 50, 21], t: 0.7), scarf, k.line * 0.9)
                    k.cel(smooth([34, 27, 57, 30, 80, 28, 78, 21, 57, 22, 36, 20], t: 0.8), scarf, k.line * 0.9, k: 0.15)
                case 2:
                    mascotPartyFlower(k, 40, 77, 1.05, Tone(0xff7ab0), fur.line)
                case 3:
                    mascotPartyBow(k, 58, 23, 0.72, 0, MascotTones(Tone(0x3f7fe0), line: Tone(0x14286e)))
                case 4:
                    k.with(about(46, 81, rot: 0.35)) {
                        k.stroke(line(46, 78, 46, 84), Tone(0x6a3a08), k.line)
                        k.cel(softStar(46, 87, 8, points: 5, inner: 0.5), MascotTones(Tone(0xe8402a), shade: Tone(0xb82a1a), line: Tone(0x5a1008)), k.line * 0.9, k: 0.15)
                    }
                default:
                    break
                }
                k.marks(84, 82, 13, edge: fur.line)
            }
        }
    }

    static func polarBear(_ f: FigureFrame, _ k: MascotKit) {
        let fur = MascotTones(Tone(0xf6f8fd), shade: Tone(0xbccaf0), line: Tone(0x2b3a6a))
        let cream = MascotTones(Tone(0xfffaf0), shade: Tone(0xeadcc8), line: fur.line)
        let irises: [Tone] = [Tone(0x2a6fe0), Tone(0x2a6fe0), Tone(0x7a3ad8), Tone(0x22a06c), Tone(0xd0408a)]
        let iris = f.pick(irises)
        let v = f.variant % 5
        let t = f.t
        let b = k.bounce()
        let stepA = 4 * cos(t) * f.energy
        let liftA = max(0, -sin(t)) * 2.6 * f.energy
        let liftB = max(0, sin(t)) * 2.6 * f.energy
        let bob = 1.3 * abs(sin(t)) * f.energy
        var tilt: CGFloat = 0, earDY: CGFloat = 1.2 * f.twitch, hsx: CGFloat = 1, hsy: CGFloat = 1, nod: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            hsx = 1.04
            hsy = 0.94
            earDY = -1.5
            nod = 0.14
        case .startled:
            hsy = 1.06
            hsx = 0.96
            earDY = 2.5
        case .fleeing:
            tilt = -0.04
        case .dizzy:
            tilt = 0.12 * sin(t)
        }
        let farT = MascotTones(fur.shade.mix(fur.base, 0.35), shade: fur.shade.dim(0.9), line: fur.line)
        k.with(about(50, 4, rot: tilt)) {
            let far: [(CGFloat, CGFloat, CGFloat)] = [(37, -stepA, liftB), (58, stepA, liftA)]
            for l in far { k.cel(ell(l.0 + l.1, 9 + l.2, 5.6, 6.8), farT, k.line) }
            k.with(CGAffineTransform(translationX: 0, y: bob)) {
                k.cel(circ(30, 20, 4), fur, k.line)
                k.cel(ell(50, 21, 20, 13.5), fur, k.line, k: 0.15)
            }
            let near: [(CGFloat, CGFloat, CGFloat)] = [(43, stepA, liftA), (64, -stepA, liftB)]
            for l in near {
                k.cel(ell(l.0 + l.1, 8.5 + l.2, 5.8, 7), fur, k.line)
                k.fill(ell(l.0 + l.1, 4.5 + l.2, 3.4, 1.4), fur.shade)
            }
            k.with(about(54, 28, rot: nod).concatenating(CGAffineTransform(translationX: 0, y: bob)).concatenating(about(54, 26, sx: hsx * b.sx, sy: hsy * b.sy))) {
                let ears: [(CGFloat, CGFloat)] = [(33, 76 + earDY * 0.5), (72, 79 + earDY)]
                for e in ears {
                    k.cel(circ(e.0, e.1, 7.8), fur, k.line, k: 0.15)
                    k.fill(circ(e.0 + 0.5, e.1 - 0.5, 4), fur.shade)
                }
                if v == 3 {
                    let muff = MascotTones(Tone(0xff7ab0), shade: Tone(0xe04a8a), line: Tone(0x6e1446))
                    k.stroke(arc(30, 74, 75, 77, dip: -26), muff.line, k.line * 2.6)
                    k.stroke(arc(30, 74, 75, 77, dip: -26), muff.base, k.line * 1.2)
                }
                let head = circ(54, 55, 28)
                k.cel(head, fur, k.bold, k: 0.12)
                let fx: CGFloat = f.mood == .fleeing ? 2.5 : 0
                k.cel(ell(59 + fx, 42.5, 13, 9.5), cream, k.line * 0.9, k: 0.12)
                k.fill(ell(40, 72, 4, 2.4, 0.4), Tone(0xffffff))
                mascotPartyFace(f, k, 53, 62, spread: 18, rx: 7.2, ry: 9.4, iris: iris, tones: fur, far: 0.95, mouthX: 60, mouthY: 43.5, mouthW: 9.5, mouthH: 5.5)
                k.cel(ell(60.5 + fx, 48.5, 4.6, 3.2), MascotTones(Tone(0x2e3456), line: fur.line), k.line * 0.8)
                k.fill(ell(59.3 + fx, 49.6, 1.5, 0.8), Tone(0xffffff))
                switch v {
                case 1:
                    let scarf = MascotTones(Tone(0xff4d5e), shade: Tone(0xd42848), line: Tone(0x5e0f20))
                    let w = 2 * sin(2 * t) + (f.mood == .fleeing ? 4 : 0)
                    k.cel(smooth([40, 30, 32, 20 + w, 24, 13 + w * 1.3, 28, 10 + w, 36, 17, 46, 26], t: 0.7), scarf, k.line * 0.9)
                    k.cel(smooth([30, 31, 54, 33, 80, 31, 78, 23, 54, 24, 32, 23], t: 0.8), scarf, k.line * 0.9, k: 0.15)
                    k.fill(rrect(30, 26, 50, 2.4, 1.2), Tone(0xffffff, 0.55))
                case 2:
                    let cap = MascotTones(Tone(0x4f8cff), shade: Tone(0x2f5fd8), line: Tone(0x14286e))
                    k.cel(smooth([28, 70, 34, 86, 54, 92, 74, 86, 80, 70, 54, 74], t: 0.8), cap, k.line, k: 0.15)
                    k.cel(smooth([27, 74, 54, 78, 81, 74, 82, 67, 54, 71, 26, 67], t: 0.7), MascotTones(Tone(0xfff6ea), line: cap.line), k.line * 0.9)
                    k.cel(circ(56, 94, 5.5 + 0.4 * f.twitch), MascotTones(Tone(0xfff6ea), line: cap.line), k.line * 0.9)
                case 3:
                    let muff = MascotTones(Tone(0xff7ab0), shade: Tone(0xe04a8a), line: Tone(0x6e1446))
                    k.cel(circ(30, 72, 8.5), muff, k.line, k: 0.15)
                    k.cel(circ(78, 74, 8.5), muff, k.line, k: 0.15)
                case 4:
                    mascotPartyHat(k, 60, 81, 0.95, -0.3, MascotTones(Tone(0xffd23f), line: Tone(0x6a4208)), Tone(0x3fb8b0))
                default:
                    break
                }
                k.marks(84, 84, 13, edge: fur.line)
            }
        }
    }

    static func comet(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, Tone, Tone, Tone, Tone)] = [
            (MascotTones(Tone(0xffe46a), shade: Tone(0xf5a623), line: Tone(0x7a3a0a)), Tone(0xff7a3a), Tone(0xffc23a), Tone(0xfff4c0), Tone(0x2f7de0)),
            (MascotTones(Tone(0xd2f0ff), shade: Tone(0x86c4f0), line: Tone(0x173a74)), Tone(0x3f8cff), Tone(0x6ad8ff), Tone(0xe8fbff), Tone(0x7a3ad8)),
            (MascotTones(Tone(0xffc4e4), shade: Tone(0xf08ac0), line: Tone(0x6e1446)), Tone(0xc04ae0), Tone(0xff6fb8), Tone(0xffe8f4), Tone(0x2f7de0)),
            (MascotTones(Tone(0xd4ffc0), shade: Tone(0x8ee07a), line: Tone(0x1e5a22)), Tone(0x2fb86a), Tone(0x9ff05a), Tone(0xf0ffe0), Tone(0xd0408a)),
            (MascotTones(Tone(0xf0e2ff), shade: Tone(0xc0a4f0), line: Tone(0x3c2272)), Tone(0xff5a6a), Tone(0xffd23f), Tone(0xffffff), Tone(0x2f7de0)),
        ]
        let (head, outerT, midT, coreT, iris) = f.pick(looks)
        let v = f.variant % 5
        let t = f.t
        let b = k.bounce()
        let hx: CGFloat = 66, hy: CGFloat = 50, hr: CGFloat = 25
        var lenK: CGFloat = 1, widK: CGFloat = 1, fan: CGFloat = 1, sag: CGFloat = 0, wav: CGFloat = 3
        var rot: CGFloat = 0, hsx: CGFloat = 1, hsy: CGFloat = 1
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            lenK = 0.55
            sag = -9
            wav = 1.2
            hsx = 1.04
            hsy = 0.95
        case .startled:
            lenK = 0.85
            widK = 1.15
            fan = 1.5
            hsx = 0.94
            hsy = 1.08
        case .fleeing:
            lenK = 1.3
            widK = 0.9
            fan = 0.8
            hsx = 1.06
            hsy = 0.95
        case .dizzy:
            rot = 0.12 * sin(t)
            wav = 7
        }
        let rainbow: [Tone] = [Tone(0xff5a6a), Tone(0xffd23f), Tone(0x3fb8ff)]
        let tongues: [(CGFloat, CGFloat, CGFloat)] = [(11, 9, 50), (0, 12.5, 70), (-11, 9, 48)]
        func tongue(_ i: Int, _ wk: CGFloat, _ lk: CGFloat) -> CGPath {
            let g = tongues[i]
            let cy = hy + g.0 * fan
            let w = g.1 * widK * wk
            let fl: CGFloat = 1 + 0.1 * sin(2 * t + CGFloat(i) * 2.1)
            let l = g.2 * lenK * lk * fl
            let w1 = wav * sin(2 * t + CGFloat(i) * 1.7)
            let w2 = wav * 1.4 * sin(2 * t + CGFloat(i) * 1.7 + 1.2)
            let x0 = hx - 4
            return smooth([x0, cy + w, x0 - 0.4 * l, cy + 0.85 * w + w1 + sag * 0.4, x0 - l, cy + w2 + sag, x0 - 0.4 * l, cy - 0.85 * w + w1 + sag * 0.4, x0, cy - w], t: 0.85)
        }
        k.with(about(hx, hy, rot: rot)) {
            let outer = (0..<3).map { tongue($0, 1, 1) }
            for p in outer { k.stroke(p, head.line, k.line * 2) }
            for (i, p) in outer.enumerated() { k.fill(p, v == 4 ? rainbow[i] : outerT) }
            for i in 0..<3 { k.fill(tongue(i, 0.62, 0.74), v == 4 ? rainbow[i].lift(0.45) : midT) }
            for i in 0..<3 { k.fill(tongue(i, 0.3, 0.45), coreT) }
            for i in 0..<3 {
                let u = (f.phase * 2 + CGFloat(i) / 3).truncatingRemainder(dividingBy: 1)
                let sx0 = hx - 26 - u * 40 * lenK
                let sy0 = hy + CGFloat([7, -6, 1][i]) * fan + sag * u
                mascotPartySparkle(k, sx0, sy0, 4.5 * (1 - u * 0.6), Tone(0xffffff), head.line)
            }
            k.with(about(hx, hy - hr, sx: hsx * b.sx, sy: hsy * b.sy)) {
                k.cel(circ(hx, hy, hr), head, k.bold, k: 0.12)
                k.fill(ell(hx - 13, hy + 13, 3.4, 5.5, -0.7), Tone(0xffffff, 0.85))
                mascotPartyFace(f, k, hx + 1, hy + 3, spread: 16, rx: 7.2, ry: 9.6, iris: iris, tones: head, mouthX: hx + 1, mouthY: hy - 9, mouthW: 11, mouthH: 7)
                switch v {
                case 2:
                    mascotPartyBow(k, hx - 9, hy + 22, 0.62, 0.35, MascotTones(Tone(0xc04ae0), line: Tone(0x3c1260)))
                case 3:
                    mascotPartyHat(k, hx + 4, hy + 21, 0.75, -0.3, MascotTones(Tone(0xff6fb8), line: Tone(0x6e1446)), Tone(0xffe066))
                default:
                    break
                }
                k.marks(hx + 20, hy + 26, 12, edge: head.line)
            }
        }
    }

    static func ufo(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, MascotTones, Tone, Tone)] = [
            (MascotTones(Tone(0xdfe6f2), shade: Tone(0xa4b0cc), line: Tone(0x283458)), MascotTones(Tone(0x9be86a), shade: Tone(0x62bf3e), line: Tone(0x1e4a12)), Tone(0x8a3ad8), Tone(0xffd23f)),
            (MascotTones(Tone(0xb894f5), shade: Tone(0x8a66d8), line: Tone(0x2e1a5e)), MascotTones(Tone(0xffb0d6), shade: Tone(0xf07aae), line: Tone(0x6e1e4a)), Tone(0x22a06c), Tone(0x7affd8)),
            (MascotTones(Tone(0xffd76a), shade: Tone(0xe8a83a), line: Tone(0x6a4208)), MascotTones(Tone(0x8ad4ff), shade: Tone(0x52a4ec), line: Tone(0x173a74)), Tone(0xd0408a), Tone(0xff6fb8)),
            (MascotTones(Tone(0xff7a6a), shade: Tone(0xd84a44), line: Tone(0x641414)), MascotTones(Tone(0xa8ee7a), shade: Tone(0x6cc44a), line: Tone(0x1e4a12)), Tone(0x2f7de0), Tone(0xfff27a)),
            (MascotTones(Tone(0x6adcc8), shade: Tone(0x3ab09e), line: Tone(0x0f4a42)), MascotTones(Tone(0xffb46a), shade: Tone(0xf08a3a), line: Tone(0x6a3008)), Tone(0x2f7de0), Tone(0xff8ad0)),
        ]
        let (saucer, alien, iris, light) = f.pick(looks)
        let v = f.variant % 5
        let t = f.t
        let b = k.bounce(0.5)
        var tilt: CGFloat = 0.03 * sin(t), lift: CGFloat = 0, dim: CGFloat = 1
        var antL: CGFloat = 0.25, antR: CGFloat = -0.25 - 0.3 * f.twitch, antLen: CGFloat = 9
        var handL = (x: CGFloat(33), y: CGFloat(46)), handR = (x: CGFloat(67), y: CGFloat(46) + 3 * max(0, f.twitch))
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            tilt = 0.1
            lift = -2
            dim = 0.35
            antL = 0.9
            antR = 0.6
            antLen = 8
        case .startled:
            lift = 3
            antL = 0.05
            antR = -0.05
            antLen = 11
            handL = (32, 58)
            handR = (68, 58)
        case .fleeing:
            tilt = -0.16
            antL = 0.8
            antR = 0.7
            handL = (34, 47)
            handR = (62, 47)
        case .dizzy:
            tilt = 0.14 * sin(t)
            antL = 0.25 + 0.4 * sin(2 * t)
            antR = -0.25 - 0.4 * sin(2 * t)
        }
        k.with(about(50, 34, rot: tilt).concatenating(CGAffineTransform(translationX: 0, y: lift)).concatenating(about(50, 30, sx: b.sx, sy: b.sy))) {
            let dome = ell(50, 57, 28, 37)
            k.fill(dome, Tone(0xd8f4ff, 0.72))
            k.clip(dome) {
                let fx: CGFloat = f.mood == .fleeing ? 2.5 : 0
                if v == 4 {
                    mascotPartyHat(k, 51 + fx, 81, 0.5, -0.2, MascotTones(Tone(0xff6fb8), line: Tone(0x6e1446)), Tone(0xffe066))
                } else {
                    k.both { s in
                        let a = s < 0 ? antL : antR
                        let bx = 50 + s * 7 + fx, by: CGFloat = 81
                        let ex = bx - sin(a) * antLen, ey = by + cos(a) * antLen
                        k.stroke(line(bx, by, ex, ey), alien.line, k.line * 1.1)
                        k.fs(circ(ex, ey, 2.8), light, alien.line, k.line * 0.8)
                    }
                }
                k.cel(circ(50 + fx * 0.5, 65, 19.5), alien, k.bold, k: 0.12)
                if v == 3 {
                    let ex = 50 + fx
                    k.blush(36 + fx, 58, 3.6, 2.2)
                    k.blush(64 + fx, 58, 3.6, 2.2)
                    k.eye(ex, 68, 10, 12, iris: iris, edge: alien.line, lid: alien.base, side: 1, look: f.mood == .fleeing ? 0.3 : 0.12)
                    k.brow(ex, 84, 12, side: 1, edge: alien.line)
                    k.mouth(ex, 55, 9, 5, edge: alien.line)
                } else {
                    mascotPartyFace(f, k, 50, 68, spread: 16, rx: 7.3, ry: 9.8, iris: iris, tones: alien, mouthX: 50, mouthY: 55, mouthW: 9.5, mouthH: 5.5)
                }
            }
            k.stroke(arc(30, 72, 42, 87, dip: -3), Tone(0xffffff, 0.85), k.width(2.6, minPt: 0.9))
            k.stroke(dome, saucer.line, k.line)
            k.cel(ell(50, 24, 22, 8), MascotTones(saucer.shade, shade: saucer.shade.dim(0.82), line: saucer.line), k.line, k: 0.15)
            let disc = ell(50, 34, 46, 12)
            k.cel(disc, saucer, k.bold, k: 0.12)
            k.stroke(arc(6, 35, 94, 35, dip: 7), saucer.line.alpha(0.7), k.line * 0.7)
            k.fill(ell(30, 40, 9, 2, -0.1), Tone(0xffffff, 0.7))
            for i in 0..<5 {
                let a = CGFloat(200 + i * 35) * .pi / 180
                let lx = 50 + 36 * cos(a), ly = 31 + 8 * sin(a)
                let lit = (i + f.frameIndex) % 3 == 0
                let tone = lit ? light.lift(0.25) : light.dim(0.55).mix(saucer.shade, 0.4)
                k.fs(circ(lx, ly, 3.4), dim < 0.5 ? tone.dim(0.7) : tone, saucer.line, k.line * 0.75)
            }
            let hands: [(CGFloat, CGFloat)] = [(handL.x, handL.y), (handR.x, handR.y)]
            for h in hands { k.fs(circ(h.0, h.1, 3.6), alien.base, alien.line, k.line * 0.85) }
            k.marks(82, 90, 13, edge: saucer.line)
        }
    }
}
