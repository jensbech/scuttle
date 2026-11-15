import Foundation
import CoreGraphics
import ScuttleCore

extension MascotArt {
    static func ghost(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, Tone)] = [
            (MascotTones(Tone(0xf8f6ff), shade: Tone(0xbcb2f2), line: Tone(0x4b3f93)), Tone(0x5a46d8)),
            (MascotTones(Tone(0xeafff4), shade: Tone(0x9fdcc0), line: Tone(0x2f6a58)), Tone(0x22a06c)),
            (MascotTones(Tone(0xf3ffd9), shade: Tone(0xc2e483), line: Tone(0x4f6a1f)), Tone(0xe0a020)),
            (MascotTones(Tone(0xffeef6), shade: Tone(0xf0a8c8), line: Tone(0x8a2e5e)), Tone(0xd0408a)),
            (MascotTones(Tone(0xeef4ff), shade: Tone(0xa8c0f0), line: Tone(0x2c3f8a)), Tone(0x3f7fe0)),
        ]
        let (tones, iris) = f.pick(looks)
        let t = f.t
        let b = k.bounce()
        var tilt: CGFloat = 0, swish: CGFloat = 5 * sin(t), tailUp: CGFloat = 0
        var la = (x: CGFloat(18), y: CGFloat(53) + 2 * f.swing, a: CGFloat(0.6) + 0.3 * f.swing)
        var ra = (x: CGFloat(82), y: CGFloat(49) - 2 * f.swing, a: CGFloat(-0.9) - 0.3 * f.swing)
        var faceX: CGFloat = 0
        switch f.mood {
        case .calm:
            ra.a -= 0.6 * max(0, f.twitch)
            ra.y += 4 * max(0, f.twitch)
        case .sleepy:
            swish = 2 * sin(t)
            tailUp = -3
            la = (22, 44, -0.4)
            ra = (78, 42, 0.4)
        case .startled:
            swish = 1.5 * sin(2 * t)
            la = (15, 72, 0.15 + 0.1 * f.swing2)
            ra = (85, 74, -0.15 - 0.1 * f.swing2)
        case .fleeing:
            swish = -12 + 3 * sin(t)
            tailUp = 7
            la = (14, 56, 1.2 + 0.2 * f.swing)
            ra = (80, 40, 1.4)
            faceX = 3
        case .dizzy:
            tilt = 0.14 * sin(t)
            la = (17, 58 + 4 * f.swing, 1.2)
            ra = (83, 46 - 4 * f.swing, -1.2)
        }
        k.with(about(50, 30, rot: tilt).concatenating(about(50, 0, sx: 0.9 * b.sx, sy: 1.08 * b.sy))) {
            k.cel(ell(la.x, la.y, 3.6, 7, la.a), tones, k.line * 0.92)
            k.cel(ell(ra.x, ra.y, 3.6, 7, ra.a), tones, k.line * 0.92)
            let body = smooth([50, 89, 71, 84, 81, 65, 79, 45, 71, 31, 64 + swish * 0.3, 21 + tailUp * 0.5, 69 + swish * 0.7, 11 + tailUp, 60 + swish, 5 + tailUp * 1.4, 49 + swish * 0.5, 11 + tailUp * 0.6, 36, 21, 22, 37, 19, 59, 28, 80])
            k.cel(body, tones, k.bold, k: 0.12)
            mascotGhostHat(f, k)
            let ex = 40 + faceX, ex2 = 60 + faceX
            k.eye(ex, 60, 8.5, 11, iris: iris, edge: tones.line, lid: tones.base, side: -1, look: faceX > 0 ? 0.3 : 0.12)
            k.eye(ex2, 60, 8.5, 11, iris: iris, edge: tones.line, lid: tones.base, side: 1, look: faceX > 0 ? 0.3 : 0.12)
            k.brow(ex, 76, 10, side: -1, edge: tones.line)
            k.brow(ex2, 76, 10, side: 1, edge: tones.line)
            k.blush(29 + faceX, 47)
            k.blush(71 + faceX, 47)
            k.mouth(50 + faceX, 44, 14, 9, edge: tones.line)
            k.marks(78, 86, 13, edge: tones.line)
        }
    }

    private static func mascotGhostHat(_ f: FigureFrame, _ k: MascotKit) {
        switch f.variant % 5 {
        case 1:
            let cap = MascotTones(Tone(0xff4d4d), line: Tone(0x6a1414))
            k.with(about(50, 86, rot: -0.12)) {
                k.cel(smooth([58, 90, 86, 92, 84, 86, 60, 85], t: 0.5), cap)
                k.cel(smooth([30, 86, 34, 100, 50, 106, 66, 100, 70, 86, 50, 83], t: 0.8), cap, k.line, k: 0.15)
                k.fill(circ(50, 105, 2.4), cap.line)
            }
        case 3:
            let bow = MascotTones(Tone(0xff5fae), line: Tone(0x8a2e5e))
            k.cel(smooth([62, 86, 50, 93, 49, 81], t: 0.45), bow)
            k.cel(smooth([62, 86, 74, 94, 76, 80], t: 0.45), bow)
            k.cel(circ(62, 86, 3.4), bow)
        case 4:
            let hat = MascotTones(Tone(0x8a5ce6), line: Tone(0x2c1a5e))
            let cone = smooth([34, 88, 66, 88, 58, 102, 72, 116, 48, 104], t: 0.5)
            k.cel(cone, hat, k.line, k: 0.15)
            k.clip(cone) { k.fill(rrect(30, 89, 40, 5, 0), Tone(0xffd34d)) }
            k.stroke(cone, hat.line, k.line)
            k.cel(ell(50, 88, 24, 5), hat)
        default:
            break
        }
    }

    private static func mascotFestiveBead(_ k: MascotKit, _ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ t: MascotTones, _ lw: CGFloat, rot: CGFloat = 0) {
        k.fill(ell(x, y, rx, ry, rot), t.shade)
        k.fill(ell(x - rx * 0.16, y + ry * 0.16, rx * 0.78, ry * 0.78, rot), t.base)
        k.stroke(ell(x, y, rx, ry, rot), t.line, lw)
    }

    private static func mascotFestiveLimb(_ k: MascotKit, _ a: [CGFloat], _ w: CGFloat, _ t: MascotTones, _ lw: CGFloat) {
        let p = a.count > 4 ? smooth(a, closed: false, t: 0.8) : poly(a, closed: false)
        k.stroke(p, t.line, w + 2 * lw)
        k.stroke(p, t.shade, w)
        k.stroke(moved(p, -w * 0.13, w * 0.13), t.base, w * 0.6)
    }

    private static func mascotFestiveBlob(_ k: MascotKit, _ parts: [CGPath], _ t: MascotTones, _ lw: CGFloat, k kk: CGFloat) {
        let p = CGMutablePath()
        for q in parts { p.addPath(q) }
        let bb = p.boundingBoxOfPath
        let s = kk * min(bb.width, bb.height)
        k.stroke(p, t.line, 2 * lw)
        k.fill(p, t.shade)
        k.clip(p) { k.fill(xf(p, CGAffineTransform(translationX: -s, y: s * 0.9)), t.base) }
    }

    private static func mascotFestiveBranch(_ k: MascotKit, _ p: CGPath, _ t: MascotTones, _ w: CGFloat) {
        k.stroke(p, t.line, w + 2 * k.line * 0.85)
        k.stroke(p, t.shade, w)
        k.stroke(moved(p, -w * 0.18, w * 0.16), t.base, w * 0.55)
    }

    private static func mascotFestiveEyes(_ f: FigureFrame, _ k: MascotKit, _ x: CGFloat, _ y: CGFloat, spread: CGFloat, rx: CGFloat, ry: CGFloat, iris: Tone, edge: Tone, lid: Tone, far: CGFloat = 1, blushX: CGFloat = 1.3, blushY: CGFloat = 2) {
        let fx: CGFloat = f.mood == .fleeing ? 3 : 0
        let look: CGFloat = f.mood == .fleeing ? 0.3 : 0.12
        let lx = x - spread + fx, rx2 = x + spread + fx
        k.eye(lx, y, rx * far, ry * far, iris: iris, edge: edge, lid: lid, side: -1, look: look)
        k.eye(rx2, y, rx, ry, iris: iris, edge: edge, lid: lid, side: 1, look: look)
        k.brow(lx, y + ry * far + 5, rx * 1.2 * far, side: -1, edge: edge)
        k.brow(rx2, y + ry + 5, rx * 1.2, side: 1, edge: edge)
        k.blush(lx - rx * blushX * far, y - ry - blushY)
        k.blush(rx2 + rx * blushX, y - ry - blushY)
    }

    private static func mascotFestiveStep(_ f: FigureFrame, _ which: Int, reach: CGFloat, lift: CGFloat) -> (x: CGFloat, y: CGFloat) {
        let dir: CGFloat = which == 0 ? 1 : -1
        let e = f.energy
        return (dir * cos(f.t) * reach * e, max(0, -dir * sin(f.t)) * lift * e)
    }

    private static func mascotFestiveHands(_ f: FigureFrame, _ cx: CGFloat, _ sy: CGFloat, _ span: CGFloat, up: CGFloat = 15) -> (l: CGPoint, r: CGPoint) {
        let c = cos(f.t), s = sin(f.t)
        switch f.mood {
        case .calm:
            let l = pt(cx - span - 2 * c, sy - 9)
            let r = f.twitch > 0 ? pt(cx + span + 3, sy + 11) : pt(cx + span + 2 * c, sy - 9)
            return (l, r)
        case .sleepy:
            return (pt(cx - span * 0.75, sy - 14), pt(cx + span * 0.75, sy - 14))
        case .startled:
            return (pt(cx - span - 3, sy + up + 1.5 * f.swing2), pt(cx + span + 3, sy + up - 1.5 * f.swing2))
        case .fleeing:
            return (pt(cx - span - 6 - 3 * c, sy + 6 + 3 * s), pt(cx + span - 2 + 7 * c, sy + 2 - 5 * s))
        case .dizzy:
            return (pt(cx - span - 4, sy - 1 + 6 * s), pt(cx + span + 4, sy - 1 - 6 * s))
        }
    }

    private static func mascotFestiveQuadLegs(_ f: FigureFrame, _ k: MascotKit, hips: [CGFloat], hipY: CGFloat, near: MascotTones, far: MascotTones, foot: MascotTones, width: CGFloat, reach: CGFloat, lift: CGFloat, splay: CGFloat) {
        let pair = [0, 1, 1, 0]
        let order = [0, 2, 1, 3]
        for i in order {
            let s = mascotFestiveStep(f, pair[i], reach: reach, lift: lift)
            let hx = hips[i]
            let sp: CGFloat = i < 2 ? -splay : splay
            let fx = hx + s.x + sp, fy = 6.5 + s.y
            let tones = i % 2 == 0 ? far : near
            mascotFestiveLimb(k, [hx, hipY, (hx + fx) / 2 + 1, (hipY + fy) / 2, fx, fy], width, tones, k.line * 0.85)
            k.cel(ell(fx + 0.8, fy - 1.2, width * 0.62, width * 0.42), i % 2 == 0 ? MascotTones(foot.shade, shade: foot.shade.dim(0.85), line: foot.line) : foot, k.line * 0.8)
        }
    }

    static func bat(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, Tone, Tone)] = [
            (MascotTones(Tone(0x8a74cc), shade: Tone(0x4e3c92), line: Tone(0x22154a)), Tone(0xe8dcff), Tone(0xe0508a)),
            (MascotTones(Tone(0xd480b4), shade: Tone(0x96487e), line: Tone(0x481638)), Tone(0xffe2f0), Tone(0x8a3fd0)),
            (MascotTones(Tone(0x52a6b8), shade: Tone(0x2c6684), line: Tone(0x0f2e42)), Tone(0xdcf8f4), Tone(0xe08a20)),
            (MascotTones(Tone(0x6c70c8), shade: Tone(0x3a3e8e), line: Tone(0x171a4c)), Tone(0xe4e4ff), Tone(0xd83a3a)),
            (MascotTones(Tone(0xc48a52), shade: Tone(0x86522c), line: Tone(0x3c1e0c)), Tone(0xffe8c8), Tone(0x6a3fc0)),
        ]
        let (tones, maskTone, iris) = f.pick(looks)
        let mask = MascotTones(maskTone, shade: maskTone.mix(tones.shade, 0.32), line: tones.line)
        let wing = MascotTones(tones.base.mix(tones.shade, 0.45), shade: tones.shade.dim(0.82), line: tones.line)
        let b = k.bounce()
        let t = f.t
        var tilt: CGFloat = 0
        var wl: CGFloat = -0.05 + 0.55 * f.swing, wr: CGFloat = -0.05 + 0.55 * f.swing
        var earRot: CGFloat = -0.18, earScale: CGFloat = 1, wingScale: CGFloat = 1, rScale: CGFloat = 1
        var feetDy: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            wl = -1.25 + 0.05 * f.swing
            wr = wl
            earRot = -0.55
            wingScale = 0.8
            feetDy = 2
        case .startled:
            wl = 0.5 + 0.12 * f.swing2
            wr = wl
            earRot = 0.02
            earScale = 1.15
            wingScale = 1.1
        case .fleeing:
            wl = 0.05 + 0.6 * f.swing
            wr = -0.15 + 0.5 * sin(t + 0.7)
            rScale = 0.72
            earRot = 0.55
        case .dizzy:
            tilt = 0.13 * sin(t)
            wl = 0.2 + 0.55 * sin(t)
            wr = 0.2 + 0.55 * cos(t)
            earRot = -0.4
        }
        let fx: CGFloat = f.mood == .fleeing ? 3 : 0
        k.with(about(50, 50, rot: tilt).concatenating(about(50, 30, sx: b.sx, sy: b.sy))) {
            k.both { s in
                let a: CGFloat = s < 0 ? wl : wr
                let ws: CGFloat = s > 0 ? wingScale * rScale : wingScale
                let tr = CGAffineTransform(translationX: 50 + s * 19, y: 42).scaledBy(x: s * ws * 1.08, y: ws).rotated(by: a)
                k.with(tr) { mascotBatWing(k, wing) }
            }
            if f.variant % 5 == 3 {
                let collar = MascotTones(Tone(0xe0344e), shade: Tone(0x9a1830), line: Tone(0x4a0a18))
                k.both { s in
                    let p = smooth([50 + s * 6, 28, 50 + s * 30, 26, 50 + s * 36, 44, 50 + s * 22, 36], t: 0.6)
                    k.cel(p, collar, k.line)
                }
            }
            mascotFestiveBead(k, 45, 15 + feetDy, 3.2, 4, wing, k.line * 0.8)
            mascotFestiveBead(k, 55, 15 + feetDy, 3.2, 4, wing, k.line * 0.8)
            mascotFestiveBead(k, 50, 25, 12, 9.5, tones, k.line)
            k.both { s in
                var r: CGFloat = earRot
                if f.mood == .fleeing { r = earRot * s }
                if s > 0 && f.mood == .calm { r -= 0.3 * f.twitch }
                let tr = CGAffineTransform(translationX: 50 + s * 15, y: 68).scaledBy(x: s, y: earScale).rotated(by: r)
                k.with(tr) {
                    k.cel(smooth([-10, 0, -3, 24, 2, 26, 10, 3, 0, -5], t: 0.6), tones, k.line)
                    k.fill(smooth([-4.5, 4, 0, 19, 4.5, 4], t: 0.6), Tone(0xff9ec4, 0.9))
                }
            }
            mascotFestiveBead(k, 50, 52, 27, 27, tones, k.bold)
            mascotFestiveBlob(k, [circ(40.5 + fx, 54, 12.5), circ(59.5 + fx, 54, 12.5), ell(50 + fx, 41, 15, 10.5)], mask, k.line * 0.9, k: 0.1)
            mascotBatHat(f, k)
            mascotFestiveEyes(f, k, 50, 54, spread: 9.5, rx: 8, ry: 10, iris: iris, edge: tones.line, lid: maskTone, blushX: 1.05, blushY: 0)
            k.mouth(50 + fx, 40, 12, 7.5, edge: tones.line)
            if f.mood == .calm || f.mood == .fleeing {
                k.fs(poly([53.2 + fx, 40.2, 57 + fx, 40.2, 55.2 + fx, 36.2]), .white, tones.line, k.line * 0.5)
            }
            k.marks(77, 80, 12, edge: tones.line)
        }
    }

    private static func mascotBatWing(_ k: MascotKit, _ t: MascotTones) {
        let p = CGMutablePath()
        p.move(to: pt(-3, 9))
        p.addQuadCurve(to: pt(40, 19), control: pt(16, 31))
        let tips: [CGFloat] = [40, 19, 33, 1, 21, -5, 8, -7, -3, -3]
        for i in 1..<5 {
            let ax = tips[i * 2 - 2], ay = tips[i * 2 - 1], bx = tips[i * 2], by = tips[i * 2 + 1]
            p.addQuadCurve(to: pt(bx, by), control: pt((ax + bx) / 2 - 1.5, (ay + by) / 2 + 5.5))
        }
        p.closeSubpath()
        k.cel(p, t, k.line, k: 0.16)
        for i in 1..<4 {
            k.stroke(line(1, 5, tips[i * 2] - 1, tips[i * 2 + 1] + 2), t.line.alpha(0.5), k.line * 0.6)
        }
    }

    private static func mascotBatHat(_ f: FigureFrame, _ k: MascotKit) {
        switch f.variant % 5 {
        case 1:
            let bow = MascotTones(Tone(0x8a4ae0), line: Tone(0x2c1260))
            k.cel(smooth([66, 76, 56, 83, 56, 70], t: 0.45), bow)
            k.cel(smooth([66, 76, 76, 84, 77, 70], t: 0.45), bow)
            mascotFestiveBead(k, 66, 76, 3.2, 3.2, bow, k.line)
        case 2:
            let hat = MascotTones(Tone(0x7a4ad0), line: Tone(0x241050))
            let cone = smooth([38, 78, 62, 78, 57, 92, 66, 104, 46, 94], t: 0.5)
            k.cel(cone, hat, k.line, k: 0.15)
            k.clip(cone) { k.fill(rrect(34, 79, 32, 4.5, 0), Tone(0xffd34d)) }
            k.stroke(cone, hat.line, k.line)
            mascotFestiveBead(k, 50, 78, 18, 4.2, hat, k.line)
        case 4:
            k.cel(softStar(35, 75, 6, points: 5, inner: 0.48), MascotTones(Tone(0xffd84a), line: Tone(0x6a4a08)), k.line * 0.85, k: 0.15)
        default:
            break
        }
    }

    static func pumpkin(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, Tone)] = [
            (MascotTones(Tone(0xff9a2a), shade: Tone(0xd95e1a), line: Tone(0x5a2008)), Tone(0x3f9a3a)),
            (MascotTones(Tone(0xffc43c), shade: Tone(0xe2861a), line: Tone(0x5a3006)), Tone(0x8a4ad8)),
            (MascotTones(Tone(0xfff3e2), shade: Tone(0xe6c2a4), line: Tone(0x5a3a2a)), Tone(0xe0602a)),
            (MascotTones(Tone(0xf26c2c), shade: Tone(0xb83c18), line: Tone(0x4a1206)), Tone(0x2a8ad8)),
            (MascotTones(Tone(0xffa88c), shade: Tone(0xe06e5e), line: Tone(0x5a1e20)), Tone(0x3fa070)),
        ]
        let (tones, iris) = f.pick(looks)
        let vine = MascotTones(Tone(0x6fae3e), shade: Tone(0x4a7e28), line: Tone(0x1e3a0e))
        let leaf = MascotTones(Tone(0x86d45a), shade: Tone(0x55a03a), line: Tone(0x1e3a10))
        let stem = MascotTones(Tone(0x9a8a4a), shade: Tone(0x6e5e2a), line: Tone(0x2e260e))
        let b = k.bounce()
        let t = f.t
        let c = cos(t), sn = sin(t)
        var hands = (l: pt(7, 22 - 2 * c), r: pt(93, 22 + 2 * c))
        switch f.mood {
        case .calm: if f.twitch > 0 { hands.r = pt(95, 42) }
        case .sleepy: hands = (pt(14, 13), pt(86, 13))
        case .startled: hands = (pt(7, 63 + 2 * f.swing2), pt(93, 63 - 2 * f.swing2))
        case .fleeing: hands = (pt(3, 44 + 4 * sn), pt(96, 48 - 6 * sn))
        case .dizzy: hands = (pt(5, 30 + 7 * sn), pt(95, 30 - 7 * sn))
        }
        var stemRot: CGFloat = 0.08 * sin(t) - 0.2 * f.stretch
        var tilt: CGFloat = 0
        switch f.mood {
        case .sleepy: stemRot = 0.35
        case .startled: stemRot = -0.1
        case .fleeing: stemRot = 0.45 + 0.1 * sin(t)
        case .dizzy: tilt = 0.12 * sin(t)
        default: break
        }
        let feetDy: CGFloat = f.airborne ? 3 * sin(f.air * .pi) : 0
        let fx: CGFloat = f.mood == .fleeing ? 3 : 0
        k.with(about(50, 30, rot: tilt).concatenating(about(50, 4, sx: b.sx, sy: b.sy))) {
            for (sx, h) in [(CGFloat(20), hands.l), (CGFloat(80), hands.r)] {
                mascotFestiveLimb(k, [sx, 34, (sx + h.x) / 2, (34 + h.y) / 2 + 2, h.x, h.y], 5, vine, k.line * 0.8)
                mascotFestiveBead(k, h.x, h.y, 4.4, 4.4, leaf, k.line * 0.85)
            }
            mascotFestiveBead(k, 40, 7 + feetDy, 7.5, 4.6, vine, k.line)
            mascotFestiveBead(k, 61, 7 + feetDy, 7.5, 4.6, vine, k.line)
            k.with(about(50, 68, rot: stemRot)) {
                if f.variant % 5 != 1 && f.variant % 5 != 3 {
                    k.stroke(smooth([52, 76, 60, 82, 66, 80, 66, 76, 62, 77], closed: false), vine.line, k.line * 1.9)
                    k.stroke(smooth([52, 76, 60, 82, 66, 80, 66, 76, 62, 77], closed: false), vine.base, k.line * 0.8)
                    mascotFestiveLimb(k, [50, 66, 49, 76, 53, 83], 7.5, stem, k.line * 0.9)
                    k.cel(smooth([52, 74, 60, 82, 70, 82, 64, 74], t: 0.7), leaf, k.line * 0.85)
                    k.stroke(line(54, 75, 66, 80), leaf.line.alpha(0.6), k.line * 0.5)
                }
            }
            mascotFestiveBead(k, 30, 40, 19, 27.5, tones, k.line)
            mascotFestiveBead(k, 70, 40, 19, 27.5, tones, k.line)
            mascotFestiveBead(k, 50, 41, 23, 30, tones, k.bold)
            mascotPumpkinHat(f, k)
            mascotFestiveEyes(f, k, 50, 46, spread: 10.5, rx: 8, ry: 10, iris: iris, edge: tones.line, lid: tones.base, blushX: 1.2)
            k.mouth(50 + fx, 32, 13, 8, edge: tones.line)
            k.marks(82, 72, 12, edge: tones.line)
        }
    }

    private static func mascotPumpkinHat(_ f: FigureFrame, _ k: MascotKit) {
        switch f.variant % 5 {
        case 1:
            let hat = MascotTones(Tone(0x7a4ad0), line: Tone(0x241050))
            k.with(about(50, 70, rot: -0.12)) {
                let cone = smooth([35, 71, 65, 71, 59, 87, 72, 100, 46, 90], t: 0.5)
                k.cel(cone, hat, k.line, k: 0.15)
                k.clip(cone) { k.fill(rrect(30, 72, 40, 5, 0), Tone(0xff9a2a)) }
                k.stroke(cone, hat.line, k.line)
                mascotFestiveBead(k, 50, 71, 23, 5, hat, k.line)
            }
        case 2:
            let bow = MascotTones(Tone(0xff5fae), line: Tone(0x8a2e5e))
            k.cel(smooth([40, 70, 28, 77, 29, 64], t: 0.45), bow)
            k.cel(smooth([40, 70, 51, 78, 53, 65], t: 0.45), bow)
            mascotFestiveBead(k, 40, 70, 3.4, 3.4, bow, k.line)
        case 3:
            let top = MascotTones(Tone(0x4a4070), shade: Tone(0x2c2650), line: Tone(0x120e26))
            k.with(about(52, 70, rot: 0.15)) {
                k.cel(rrect(41, 70, 22, 18, 3), top, k.line, k: 0)
                k.fill(rrect(41, 72.5, 22, 4.5, 0), Tone(0x3fc070))
                k.stroke(rrect(41, 70, 22, 18, 3), top.line, k.line)
                mascotFestiveBead(k, 52, 71, 17, 3.8, top, k.line)
            }
        case 4:
            let petal = MascotTones(Tone(0xffd6ec), shade: Tone(0xf29ac6), line: Tone(0x7a2a52))
            k.cel(softStar(62, 76, 8, points: 5, inner: 0.55), petal, k.line * 0.9, k: 0.15)
            mascotFestiveBead(k, 62, 76, 3, 3, MascotTones(Tone(0xffd23a), line: Tone(0x6a4a08)), k.line * 0.7)
        default:
            break
        }
    }

    static func spider(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, Tone, Tone)] = [
            (MascotTones(Tone(0x7464bc), shade: Tone(0x3c3080), line: Tone(0x1a1240)), Tone(0xff7fb0), Tone(0x38c070)),
            (MascotTones(Tone(0x4aa6a0), shade: Tone(0x26696a), line: Tone(0x0c2e30)), Tone(0xffd04a), Tone(0xd04a8a)),
            (MascotTones(Tone(0xe0803a), shade: Tone(0xa84e1e), line: Tone(0x48180a)), Tone(0x8a5ae0), Tone(0x7a4ad0)),
            (MascotTones(Tone(0xd27ab8), shade: Tone(0x96467e), line: Tone(0x4a1438)), Tone(0x6ad0ff), Tone(0x3a7ae0)),
            (MascotTones(Tone(0x5a7ed2), shade: Tone(0x30509a), line: Tone(0x0f2048)), Tone(0xff6a4a), Tone(0xe0a020)),
        ]
        let (tones, shoeTone, iris) = f.pick(looks)
        let shoe = MascotTones(shoeTone)
        let legT = MascotTones(tones.base.mix(tones.shade, 0.15), shade: tones.shade, line: tones.line)
        let b = k.bounce()
        let t = f.t
        let e = f.energy
        var tilt: CGFloat = 0
        var bodyDy: CGFloat = 0.8 * sin(2 * t)
        var shift: CGFloat = 0
        var sx: [CGFloat] = [21, 24, 23, 19]
        let sy: [CGFloat] = [44, 36, 28, 21]
        var kx: [CGFloat] = [37, 40, 37, 30]
        var ky: [CGFloat] = [52, 41, 29, 17]
        var fxs: [CGFloat] = [44, 46, 42, 33]
        var fys: [CGFloat] = [40, 22, 10, 4]
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            bodyDy = -3
            kx = [33, 36, 34, 28]
            ky = [40, 32, 24, 14]
            fxs = [40, 42, 39, 32]
            fys = [24, 16, 8, 4]
        case .startled:
            bodyDy = 5
            kx = [40, 46, 38, 31]
            ky = [66, 52, 30, 17]
            fxs = [47, 53, 43, 34]
            fys = [80, 62, 10, 4]
        case .fleeing:
            shift = -7
            kx = [37, 41, 38, 31]
            ky = [58, 42, 29, 17]
            fxs = [42, 48, 44, 35]
            fys = [62, 22, 10, 4]
        case .dizzy:
            tilt = 0.12 * sin(t)
            sx = [21, 24, 23, 19]
        }
        let fx: CGFloat = f.mood == .fleeing ? 3 : 0
        k.with(about(50, 30, rot: tilt).concatenating(about(50, 4, sx: b.sx, sy: b.sy))) {
            for i in 0..<4 {
                k.both { s in
                    var lift: CGFloat = 0, step: CGFloat = 0
                    let ph: CGFloat = 2 * t + CGFloat(i) * 2.1 + (s > 0 ? .pi : 0)
                    if i > 0 && !(f.mood == .startled && i == 1) {
                        lift = 3.5 * e * max(0, sin(ph))
                        step = 2.2 * e * cos(ph)
                    }
                    if i == 0 {
                        switch f.mood {
                        case .calm: lift = s > 0 ? 16 * max(0, f.twitch) : 2 * sin(t)
                        case .startled: lift = 3 * f.swing2 * s
                        case .fleeing: lift = 5 * sin(2 * t + (s > 0 ? .pi : 0))
                        case .dizzy: lift = 6 * sin(t) * s
                        default: break
                        }
                    }
                    if f.mood == .dizzy && i > 0 { lift += 2 * sin(t + CGFloat(i)) }
                    let shx = 50 + s * sx[i], shy = sy[i] + bodyDy
                    let kxx = 50 + s * kx[i] + shift * 0.6 + step * 0.5, kyy = ky[i] + bodyDy * 0.6 + lift * 0.6
                    let fxx = 50 + s * fxs[i] + shift + step, fyy = fys[i] + lift
                    mascotFestiveLimb(k, [shx, shy, kxx, kyy, fxx, fyy], 6, legT, k.line * 0.75)
                    if i == 0 {
                        mascotFestiveBead(k, fxx, fyy, 3.9, 3.9, shoe, k.line * 0.8)
                    } else {
                        mascotFestiveBead(k, fxx + s * 1.5, fyy - 0.5, 4.6, 3.2, shoe, k.line * 0.8)
                    }
                }
            }
            if f.variant % 5 != 2 && f.variant % 5 != 4 {
                k.cel(smooth([43, 62 + bodyDy, 45, 72 + bodyDy, 49, 66 + bodyDy, 53, 74 + bodyDy, 55, 65 + bodyDy, 59, 70 + bodyDy, 58, 61 + bodyDy], t: 0.5), tones, k.line, k: 0.1)
            }
            mascotFestiveBead(k, 50, 40 + bodyDy, 28, 26, tones, k.bold)
            k.with(CGAffineTransform(translationX: 0, y: bodyDy)) {
                mascotSpiderHat(f, k)
                mascotFestiveEyes(f, k, 50, 44, spread: 10.5, rx: 8.5, ry: 10.5, iris: iris, edge: tones.line, lid: tones.base, blushX: 1.15)
                k.mouth(50 + fx, 29.5, 13, 8, edge: tones.line)
                k.marks(78, 66, 12, edge: tones.line)
            }
        }
    }

    private static func mascotSpiderHat(_ f: FigureFrame, _ k: MascotKit) {
        switch f.variant % 5 {
        case 1:
            let bow = MascotTones(Tone(0xff5fae), line: Tone(0x8a2e5e))
            k.cel(smooth([62, 64, 51, 71, 50, 59], t: 0.45), bow)
            k.cel(smooth([62, 64, 73, 72, 75, 58], t: 0.45), bow)
            mascotFestiveBead(k, 62, 64, 3.3, 3.3, bow, k.line)
        case 2:
            let hat = MascotTones(Tone(0x5a3aa8), line: Tone(0x1c0e40))
            k.with(about(50, 64, rot: -0.1)) {
                let cone = smooth([36, 64, 64, 64, 58, 80, 70, 92, 46, 82], t: 0.5)
                k.cel(cone, hat, k.line, k: 0.15)
                k.clip(cone) { k.fill(rrect(30, 65, 40, 5, 0), Tone(0x6ad06a)) }
                k.stroke(cone, hat.line, k.line)
                mascotFestiveBead(k, 50, 64, 22, 4.6, hat, k.line)
            }
        case 3:
            let petal = MascotTones(Tone(0xfff2a8), shade: Tone(0xf0c860), line: Tone(0x6a4a08))
            k.cel(softStar(64, 63, 7.5, points: 5, inner: 0.55), petal, k.line * 0.9, k: 0.15)
            mascotFestiveBead(k, 64, 63, 2.8, 2.8, MascotTones(Tone(0xff7a3a), line: Tone(0x6a2a08)), k.line * 0.7)
        case 4:
            let cap = MascotTones(Tone(0xe8483e), shade: Tone(0xb02a2a), line: Tone(0x4a0e14))
            let cuff = MascotTones(Tone(0xfff6f0), shade: Tone(0xe0d2d6), line: Tone(0x4a0e14))
            k.cel(smooth([30, 60, 34, 74, 50, 80, 66, 74, 70, 60, 50, 64], t: 0.8), cap, k.line, k: 0.15)
            mascotFestiveBead(k, 50, 82, 5, 5, cuff, k.line * 0.9)
            k.cel(smooth([29, 58, 50, 63, 71, 58, 70, 64, 50, 69, 30, 64], t: 0.6), cuff, k.line * 0.9)
        default:
            break
        }
    }

    static func gingerbread(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, Tone, Tone, Tone)] = [
            (MascotTones(Tone(0xd08c4c), shade: Tone(0x9a5a28), line: Tone(0x4a2410)), Tone(0x2f8ad8), Tone(0xff4a4a), Tone(0x3fc060)),
            (MascotTones(Tone(0xbc7840), shade: Tone(0x87501f), line: Tone(0x3e1c08)), Tone(0x3aa060), Tone(0x3fc060), Tone(0xffd040)),
            (MascotTones(Tone(0xdea062), shade: Tone(0xa86a34), line: Tone(0x52280e)), Tone(0xd0408a), Tone(0xff7ab0), Tone(0xb070ff)),
            (MascotTones(Tone(0xd08c4c), shade: Tone(0x9a5a28), line: Tone(0x4a2410)), Tone(0x6a46d0), Tone(0x5aa0ff), Tone(0xff4a4a)),
            (MascotTones(Tone(0xac6c3a), shade: Tone(0x7a4420), line: Tone(0x361806)), Tone(0x2f8ad8), Tone(0xff4a4a), Tone(0xffffff)),
        ]
        let (tones, iris, drop1, drop2) = f.pick(looks)
        let icing = Tone(0xffffff)
        let b = k.bounce()
        let t = f.t
        let bob = 1.5 * f.bounce
        var tilt: CGFloat = 0
        var reach: CGFloat = 6, lift: CGFloat = 4
        switch f.mood {
        case .sleepy: reach = 2; lift = 1
        case .startled: reach = 3
        case .dizzy: tilt = 0.12 * sin(t)
        default: break
        }
        let hands = mascotFestiveHands(f, 50, 36 + bob, 17, up: 9)
        let fx: CGFloat = f.mood == .fleeing ? 3 : 0
        let iw = k.width(1.7, minPt: 0.55)
        k.with(about(50, 30, rot: tilt).concatenating(about(50, 4, sx: b.sx, sy: b.sy))) {
            for which in [1, 0] {
                let s = mascotFestiveStep(f, which, reach: reach, lift: lift)
                let hx: CGFloat = which == 0 ? 56 : 44
                let footX = hx + s.x, footY = 9.5 + s.y
                mascotFestiveLimb(k, [hx, 22 + bob, footX, footY], 11, which == 0 ? tones : MascotTones(tones.base.mix(tones.shade, 0.3), shade: tones.shade, line: tones.line), k.line)
                k.stroke(wavy(footX - 4.2, footY + 3.2, footX + 4.2, footY + 3.2, waves: 1.5, amp: 1.1), icing, iw)
            }
            mascotFestiveBead(k, 50, 29 + bob, 15, 12.5, tones, k.line)
            mascotFestiveBead(k, 50, 32.5 + bob, 3.4, 2.9, MascotTones(drop1), k.line * 0.7)
            mascotFestiveBead(k, 50, 23.5 + bob, 3.4, 2.9, MascotTones(drop2), k.line * 0.7)
            for (sxp, h) in [(CGFloat(39), hands.l), (CGFloat(61), hands.r)] {
                mascotFestiveLimb(k, [sxp, 35 + bob, h.x, h.y], 10, tones, k.line)
                let dx = h.x - sxp, dy = h.y - (35 + bob)
                let len = max(1, (dx * dx + dy * dy).squareRoot())
                let ux = dx / len, uy = dy / len
                let cx = h.x - ux * 3.5, cy = h.y - uy * 3.5
                k.stroke(wavy(cx - uy * 3.6, cy + ux * 3.6, cx + uy * 3.6, cy - ux * 3.6, waves: 1.5, amp: 1.1), icing, iw)
            }
            if f.variant % 5 == 3 { mascotGingerbreadCane(k, hands.r) }
            mascotFestiveBead(k, 50, 63 + bob, 25, 25, tones, k.bold)
            k.stroke(arc(31, 74 + bob, 69, 74 + bob, dip: -11), icing, iw)
            k.with(CGAffineTransform(translationX: 0, y: bob)) {
                mascotGingerbreadHat(f, k)
                mascotFestiveEyes(f, k, 50, 62, spread: 10, rx: 8, ry: 10, iris: iris, edge: tones.line, lid: tones.base, blushX: 1.1)
                k.mouth(50 + fx, 48.5, 13, 8, edge: tones.line)
                k.marks(78, 84, 12, edge: tones.line)
            }
        }
    }

    private static func mascotGingerbreadCane(_ k: MascotKit, _ h: CGPoint) {
        let cane = smooth([h.x, h.y - 10, h.x, h.y + 8, h.x + 3, h.y + 13, h.x + 7, h.y + 11], closed: false, t: 0.8)
        k.stroke(cane, Tone(0x5a0e18), k.line * 2.6)
        k.stroke(cane, .white, k.line * 1.5)
        k.clip(cane.copy(strokingWithWidth: k.line * 1.5, lineCap: .round, lineJoin: .round, miterLimit: 4)) {
            for i in 0..<6 {
                let y = h.y - 10 + CGFloat(i) * 4.5
                k.stroke(line(h.x - 6, y, h.x + 8, y + 5), Tone(0xff3a4a), k.line * 0.8)
            }
        }
        mascotFestiveBead(k, h.x, h.y, 4.6, 4.6, MascotTones(Tone(0xd08c4c), shade: Tone(0x9a5a28), line: Tone(0x4a2410)), k.line * 0.85)
    }

    private static func mascotGingerbreadHat(_ f: FigureFrame, _ k: MascotKit) {
        switch f.variant % 5 {
        case 1:
            let tie = MascotTones(Tone(0x3fc060), shade: Tone(0x2a8a40), line: Tone(0x0f3a1a))
            k.cel(smooth([50, 39, 41, 44, 41, 34], t: 0.4), tie, k.line * 0.85)
            k.cel(smooth([50, 39, 59, 44, 59, 34], t: 0.4), tie, k.line * 0.85)
            mascotFestiveBead(k, 50, 39, 2.6, 2.6, tie, k.line * 0.8)
        case 2:
            let bow = MascotTones(Tone(0xff6fb4), line: Tone(0x8a2e5e))
            k.cel(smooth([64, 84, 53, 91, 52, 79], t: 0.45), bow)
            k.cel(smooth([64, 84, 75, 92, 77, 78], t: 0.45), bow)
            mascotFestiveBead(k, 64, 84, 3.4, 3.4, bow, k.line)
        case 4:
            let cap = MascotTones(Tone(0xe8483e), shade: Tone(0xb02a2a), line: Tone(0x4a0e14))
            let fur = MascotTones(Tone(0xffffff), shade: Tone(0xd8dcf0), line: Tone(0x4a0e14))
            k.with(about(50, 84, rot: -0.15)) {
                k.cel(smooth([31, 84, 69, 84, 62, 98, 76, 102, 50, 100], t: 0.6), cap, k.line, k: 0.15)
                mascotFestiveBead(k, 77, 101, 4.4, 4.4, fur, k.line * 0.9)
                k.cel(rrect(28, 80, 44, 8, 4), fur, k.line * 0.9)
            }
        default:
            break
        }
    }

    static func present(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, MascotTones, Tone)] = [
            (MascotTones(Tone(0xe8483e), shade: Tone(0xb02a2a), line: Tone(0x4a0e14)), MascotTones(Tone(0xffd23a), shade: Tone(0xe0a018), line: Tone(0x5a3a06)), Tone(0x2f8ad8)),
            (MascotTones(Tone(0x42b062), shade: Tone(0x2a7a44), line: Tone(0x0f3a20)), MascotTones(Tone(0xff4a4a), shade: Tone(0xc02a30), line: Tone(0x4a0e14)), Tone(0xe0602a)),
            (MascotTones(Tone(0x4a8ae8), shade: Tone(0x2f5cb0), line: Tone(0x10224a)), MascotTones(Tone(0xf6f8ff), shade: Tone(0xc8d0ea), line: Tone(0x10224a)), Tone(0xe0a020)),
            (MascotTones(Tone(0xa066dc), shade: Tone(0x6e3eaa), line: Tone(0x2a1050)), MascotTones(Tone(0xff7ab8), shade: Tone(0xd84a8c), line: Tone(0x5a1238)), Tone(0x30b070)),
            (MascotTones(Tone(0xffc43c), shade: Tone(0xe08a1a), line: Tone(0x5a3006)), MascotTones(Tone(0xe8483e), shade: Tone(0xb02a2a), line: Tone(0x4a0e14)), Tone(0x6a46d0)),
        ]
        let (box, rib, iris) = f.pick(looks)
        let b = k.bounce()
        let t = f.t
        var lidDy: CGFloat = f.airborne ? 4 * max(0, -f.stretch) : 0
        var lidRot: CGFloat = 0
        var tilt: CGFloat = 0
        var la = (x: CGFloat(15), y: CGFloat(28) + f.swing, a: CGFloat(0.35))
        var ra = (x: CGFloat(85), y: CGFloat(28) - f.swing, a: CGFloat(-0.35))
        switch f.mood {
        case .calm:
            lidDy += 2.5 * max(0, f.twitch)
            ra = (87, 28 + 8 * max(0, f.twitch), -0.35 - 1.1 * max(0, f.twitch))
        case .sleepy:
            lidDy = -1.5
            lidRot = -0.05
            la = (17, 20, -0.1)
            ra = (83, 20, 0.1)
        case .startled:
            lidDy = 10 + 1.5 * f.swing2
            lidRot = 0.12
            la = (12, 44, -0.5)
            ra = (88, 44, 0.5)
        case .fleeing:
            lidDy = 3
            lidRot = 0.16 + 0.04 * sin(t)
            la = (11, 40 + 3 * sin(t), 1.1)
            ra = (88, 38 - 3 * sin(t), 0.9)
        case .dizzy:
            tilt = 0.12 * sin(t)
            lidRot = 0.12 * sin(t + 1)
            la = (12, 32 + 5 * sin(t), 0.9)
            ra = (88, 32 - 5 * sin(t), -0.9)
        }
        let fx: CGFloat = f.mood == .fleeing ? 3 : 0
        let feetDy: CGFloat = f.airborne ? 3 * sin(f.air * .pi) : 0
        k.with(about(50, 30, rot: tilt).concatenating(about(50, 4, sx: b.sx, sy: b.sy))) {
            mascotFestiveBead(k, la.x, la.y, 4.2, 7.5, box, k.line, rot: la.a)
            mascotFestiveBead(k, ra.x, ra.y, 4.2, 7.5, box, k.line, rot: ra.a)
            mascotFestiveBead(k, 37, 6 + feetDy, 7, 3.8, MascotTones(box.shade, line: box.line), k.line)
            mascotFestiveBead(k, 63, 6 + feetDy, 7, 3.8, MascotTones(box.shade, line: box.line), k.line)
            let body = rrect(19, 8, 62, 50, 8)
            k.cel(body, box, k.bold, k: 0.1)
            k.clip(body) {
                if f.variant % 5 == 2 {
                    for i in 0..<5 {
                        let x0 = 4 + CGFloat(i) * 22
                        k.stroke(line(x0, 4, x0 + 30, 60), box.base.lift(0.35).alpha(0.75), 4.5)
                    }
                }
                if f.variant % 5 == 3 {
                    for (dx, dy) in [(26, 15), (28, 46), (73, 46), (72, 14), (35, 30), (66, 30)] as [(CGFloat, CGFloat)] {
                        k.fill(circ(dx, dy, 3), Tone(0xffffff, 0.85))
                    }
                }
                k.cel(rrect(46, 4, 8, 56, 0), rib, k.line * 0.8, k: 0.25)
            }
            k.stroke(body, box.line, k.bold)
            k.with(CGAffineTransform(translationX: 0, y: lidDy).concatenating(about(50, 58 + lidDy, rot: lidRot))) {
                if f.variant % 5 == 4 {
                    k.stroke(smooth([46, 68, 34, 64, 26, 58], closed: false), rib.line, k.line * 0.8)
                    k.with(about(24, 53, rot: 0.25 + 0.1 * sin(t))) {
                        let tag = MascotTones(Tone(0xfff6e0), shade: Tone(0xe8d4a8), line: Tone(0x5a3a06))
                        k.cel(rrect(19, 46, 10, 9, 2), tag, k.line * 0.8)
                        k.fill(circ(24, 52.5, 1.1), tag.line)
                    }
                }
                let bowSag: CGFloat = f.mood == .sleepy ? -4 : 0
                let stream: CGFloat = f.mood == .fleeing ? -6 : 0
                k.cel(smooth([50, 69, 28 + stream, 84 + bowSag, 27 + stream, 70 + bowSag * 0.5, 34 + stream, 66 + bowSag * 0.3], t: 0.6), rib, k.line, k: 0.15)
                k.cel(smooth([50, 69, 72 + stream * 0.5, 84 + bowSag, 73 + stream * 0.3, 70 + bowSag * 0.5, 66 + stream * 0.3, 66 + bowSag * 0.3], t: 0.6), rib, k.line, k: 0.15)
                let lid = rrect(14, 56, 72, 14, 5)
                k.cel(lid, box, k.bold, k: 0.15)
                k.clip(lid) { k.cel(rrect(45, 52, 10, 22, 0), rib, k.line * 0.8, k: 0.25) }
                k.stroke(lid, box.line, k.bold)
                mascotFestiveBead(k, 50, 71, 5.5, 4.5, rib, k.line)
            }
            mascotFestiveEyes(f, k, 50, 37, spread: 12.5, rx: 9, ry: 11, iris: iris, edge: box.line, lid: box.base, blushX: 0.95, blushY: 0)
            k.mouth(50 + fx, 22.5, 14, 9, edge: box.line)
            k.marks(84, 62 + lidDy, 12, edge: box.line)
        }
    }

    static func elf(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, MascotTones, Tone, Tone, Tone)] = [
            (MascotTones(Tone(0x42b062), shade: Tone(0x2a7a44), line: Tone(0x0f3a20)), MascotTones(Tone(0xe8483e), shade: Tone(0xb02a2a), line: Tone(0x4a0e14)), Tone(0x8a5a32), Tone(0x2f8ad8), Tone(0xe8483e)),
            (MascotTones(Tone(0xe8483e), shade: Tone(0xb02a2a), line: Tone(0x4a0e14)), MascotTones(Tone(0x42b062), shade: Tone(0x2a7a44), line: Tone(0x0f3a20)), Tone(0xd8742e), Tone(0x30a060), Tone(0x42b062)),
            (MascotTones(Tone(0x4a9ae8), shade: Tone(0x2f68b8), line: Tone(0x10264a)), MascotTones(Tone(0xf6f8ff), shade: Tone(0xc8d0ea), line: Tone(0x10264a)), Tone(0xf0d890), Tone(0x6a46d0), Tone(0x8ad0ff)),
            (MascotTones(Tone(0x42b062), shade: Tone(0x2a7a44), line: Tone(0x0f3a20)), MascotTones(Tone(0xffd23a), shade: Tone(0xe0a018), line: Tone(0x5a3a06)), Tone(0x3a2a2a), Tone(0x8a4a20), Tone(0xffd23a)),
            (MascotTones(Tone(0x9a5ad8), shade: Tone(0x6a38a8), line: Tone(0x26104a)), MascotTones(Tone(0xffd23a), shade: Tone(0xe0a018), line: Tone(0x5a3a06)), Tone(0xd8742e), Tone(0x30a060), Tone(0xff7ab8)),
        ]
        let (suit, trim, hair, iris, stripe) = f.pick(looks)
        let skin = MascotTones(Tone(0xffd6b8), shade: Tone(0xf0a88c), line: Tone(0x5a2a1a))
        let fur = MascotTones(Tone(0xffffff), shade: Tone(0xd8dcf0), line: suit.line)
        let b = k.bounce()
        let t = f.t
        let bob = 1.5 * f.bounce
        var tilt: CGFloat = 0
        var reach: CGFloat = 5.5, lift: CGFloat = 4
        var tip = pt(20 + 2 * sin(t) + 3 * f.twitch, 99 - 2 * f.twitch)
        var earRot: CGFloat = 0.25
        switch f.mood {
        case .calm: break
        case .sleepy: reach = 2; lift = 1; tip = pt(19, 84); earRot = -0.05
        case .startled: reach = 3; tip = pt(50, 110); earRot = 0.55
        case .fleeing: tip = pt(8 + 2 * sin(2 * t), 90); earRot = 0.05
        case .dizzy: tilt = 0.12 * sin(t); tip = pt(30 + 12 * sin(t), 102)
        }
        let hands = mascotFestiveHands(f, 50, 34 + bob, 15, up: 6)
        let fx: CGFloat = f.mood == .fleeing ? 3 : 0
        k.with(about(50, 30, rot: tilt).concatenating(about(50, 4, sx: b.sx, sy: b.sy))) {
            for which in [1, 0] {
                let s = mascotFestiveStep(f, which, reach: reach, lift: lift)
                let hx: CGFloat = which == 0 ? 55 : 45
                let footX = hx + s.x, footY = 8 + s.y
                let lp = poly([hx, 17 + bob, footX, footY], closed: false)
                k.stroke(lp, suit.line, 6.5 + 2 * k.line * 0.85)
                k.stroke(lp, fur.base, 6.5)
                for j in 0..<3 {
                    let tt = (CGFloat(j) * 3.6 + 1.5) / max(1, 17 + bob - footY)
                    let cx = footX + (hx - footX) * tt, cy = footY + (17 + bob - footY) * tt
                    k.stroke(line(cx - 3, cy - 0.4, cx + 3, cy + 0.4), stripe, 1.9)
                }
                let shoe = smooth([footX - 4, footY - 3.5, footX + 6, footY - 3.5, footX + 9.5, footY + 0.5, footX + 8, footY + 2.2, footX + 5.5, footY, footX - 4.5, footY + 1.5], t: 0.7)
                k.cel(shoe, which == 0 ? suit : MascotTones(suit.shade, line: suit.line), k.line * 0.85)
            }
            for (sxp, h) in [(CGFloat(41), hands.l)] {
                mascotFestiveLimb(k, [sxp, 33 + bob, h.x, h.y], 6, suit, k.line * 0.85)
                mascotFestiveBead(k, h.x, h.y, 3.6, 3.6, skin, k.line * 0.8)
            }
            let tunic = smooth([40, 38 + bob, 60, 38 + bob, 66, 18 + bob, 60, 13.5 + bob, 55, 17.5 + bob, 50, 13.5 + bob, 45, 17.5 + bob, 40, 13.5 + bob, 34, 18 + bob], t: 0.35)
            k.cel(tunic, suit, k.line, k: 0.15)
            k.cel(rrect(37, 22 + bob, 26, 4.6, 2), MascotTones(Tone(0x5a3a22), line: suit.line), k.line * 0.7)
            k.cel(rrect(47, 21 + bob, 6.5, 6.6, 1.2), trim, k.line * 0.7)
            for (sxp, h) in [(CGFloat(59), hands.r)] {
                mascotFestiveLimb(k, [sxp, 33 + bob, h.x, h.y], 6, suit, k.line * 0.85)
                if f.variant % 5 == 1 { mascotElfCane(k, h) }
                if f.variant % 5 == 3 { mascotElfGift(k, h) }
                mascotFestiveBead(k, h.x, h.y, 3.6, 3.6, skin, k.line * 0.8)
            }
            k.with(CGAffineTransform(translationX: 0, y: bob)) {
                if f.variant % 5 == 2 {
                    let scarf = MascotTones(Tone(0xf6f8ff), shade: Tone(0xc8d0ea), line: suit.line)
                    k.cel(smooth([38, 34, 32 - 3 * f.swing, 24, 37 - 3 * f.swing, 22, 43, 32], t: 0.6), scarf, k.line * 0.85)
                }
                k.both { s in
                    let tr = CGAffineTransform(translationX: 50 + s * 19, y: 56).scaledBy(x: s, y: 1).rotated(by: earRot + (s > 0 ? -0.2 * f.twitch : 0))
                    k.with(tr) {
                        k.cel(smooth([0, 6, 15, 7, 0, -6], t: 0.55), skin, k.line * 0.9)
                        k.fill(smooth([2, 3, 10, 5, 2, -2], t: 0.55), skin.shade.alpha(0.7))
                    }
                }
                mascotFestiveBead(k, 50, 56, 22, 22, skin, k.bold)
                if f.variant % 5 == 2 {
                    let scarf = MascotTones(Tone(0xf6f8ff), shade: Tone(0xc8d0ea), line: suit.line)
                    k.cel(smooth([34, 37, 50, 33, 66, 37, 64, 32, 50, 29, 36, 32], t: 0.6), scarf, k.line * 0.85)
                }
                k.cel(smooth([29, 70, 33, 64, 38, 69, 33, 72], t: 0.6), MascotTones(hair, line: skin.line), k.line * 0.8)
                k.cel(smooth([71, 70, 67, 64, 62, 69, 67, 72], t: 0.6), MascotTones(hair, line: skin.line), k.line * 0.8)
                let cone = smooth([29, 76, 71, 76, 66, 90, tip.x, tip.y, 42, 93], t: 0.55)
                k.cel(cone, suit, k.line, k: 0.15)
                if f.variant % 5 == 4 {
                    mascotFestiveBead(k, tip.x, tip.y - 2, 4.6, 4.6, MascotTones(Tone(0xffd23a), shade: Tone(0xe0a018), line: Tone(0x5a3a06)), k.line * 0.85)
                    k.fill(circ(tip.x, tip.y - 4, 1.2), Tone(0x5a3a06))
                } else {
                    mascotFestiveBead(k, tip.x, tip.y, 4.6, 4.6, fur, k.line * 0.85)
                }
                k.cel(rrect(26, 70, 48, 8, 4), trim, k.line * 0.9, k: 0.2)
                mascotFestiveEyes(f, k, 50, 55, spread: 9.5, rx: 7.6, ry: 9, iris: iris, edge: skin.line, lid: skin.base, blushX: 1.15)
                k.mouth(50 + fx, 43, 12, 7.5, edge: skin.line)
                k.marks(76, 80, 12, edge: suit.line)
            }
        }
    }

    private static func mascotElfCane(_ k: MascotKit, _ h: CGPoint) {
        let cane = smooth([h.x, h.y - 12, h.x, h.y + 9, h.x + 3, h.y + 14, h.x + 7, h.y + 12], closed: false, t: 0.8)
        k.stroke(cane, Tone(0x5a0e18), k.line * 2.5)
        k.stroke(cane, .white, k.line * 1.4)
        k.clip(cane.copy(strokingWithWidth: k.line * 1.4, lineCap: .round, lineJoin: .round, miterLimit: 4)) {
            for i in 0..<7 {
                let y = h.y - 12 + CGFloat(i) * 4.5
                k.stroke(line(h.x - 6, y, h.x + 8, y + 5), Tone(0xff3a4a), k.line * 0.8)
            }
        }
    }

    private static func mascotElfGift(_ k: MascotKit, _ h: CGPoint) {
        let box = MascotTones(Tone(0xe8483e), shade: Tone(0xb02a2a), line: Tone(0x4a0e14))
        let g = rrect(h.x - 3, h.y - 1, 13, 11, 2)
        k.cel(g, box, k.line * 0.85, k: 0.2)
        k.clip(g) { k.fill(rrect(h.x + 2, h.y - 2, 3, 14, 0), Tone(0xffd23a)) }
        k.stroke(g, box.line, k.line * 0.85)
        mascotFestiveBead(k, h.x + 3.5, h.y + 11, 2.4, 2.4, MascotTones(Tone(0xffd23a), line: Tone(0x5a3a06)), k.line * 0.7)
    }

    static func reindeer(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, MascotTones, Tone)] = [
            (MascotTones(Tone(0xb07a4e), shade: Tone(0x7a4a2c), line: Tone(0x3a1c0c)), MascotTones(Tone(0xf4d8b0), shade: Tone(0xdcae7e), line: Tone(0x3a1c0c)), Tone(0x8a4a20)),
            (MascotTones(Tone(0xa46e46), shade: Tone(0x704026), line: Tone(0x34180a)), MascotTones(Tone(0xf4d8b0), shade: Tone(0xdcae7e), line: Tone(0x34180a)), Tone(0x2f8ad8)),
            (MascotTones(Tone(0xb88454), shade: Tone(0x84542e), line: Tone(0x3e200c)), MascotTones(Tone(0xf8e0bc), shade: Tone(0xe2b688), line: Tone(0x3e200c)), Tone(0x30a060)),
            (MascotTones(Tone(0xd49a5e), shade: Tone(0xa06a36), line: Tone(0x4a2610)), MascotTones(Tone(0xfff0d4), shade: Tone(0xeacaa0), line: Tone(0x4a2610)), Tone(0x6a46d0)),
            (MascotTones(Tone(0xcfcadc), shade: Tone(0x9a94b4), line: Tone(0x34304e)), MascotTones(Tone(0xffffff), shade: Tone(0xdcdcee), line: Tone(0x34304e)), Tone(0x3f7fe0)),
        ]
        let (fur, muzzle, iris) = f.pick(looks)
        let antler = MascotTones(Tone(0xf0cc94), shade: Tone(0xc89a5a), line: fur.line)
        let hoof = MascotTones(Tone(0x5a3a2e), shade: Tone(0x3a2620), line: fur.line)
        let farFur = MascotTones(fur.shade, shade: fur.shade.dim(0.82), line: fur.line)
        let b = k.bounce()
        let t = f.t
        let bob = 1.3 * f.bounce
        var tilt: CGFloat = 0, headRot: CGFloat = 0, headDy: CGFloat = 0, bodyDy: CGFloat = 0
        var reach: CGFloat = 5, lift: CGFloat = 4, splay: CGFloat = 0
        var earRot: CGFloat = 0.45 + 0.08 * sin(t), tailRot: CGFloat = 0.3 * f.twitch
        switch f.mood {
        case .calm: break
        case .sleepy:
            reach = 1.5; lift = 1; bodyDy = -3; headRot = -0.1; headDy = -3; earRot = -0.2; tailRot = -0.3
        case .startled:
            reach = 2; headDy = 4; bodyDy = 2; earRot = 0.95; splay = 4; tailRot = 0.6
        case .fleeing:
            reach = 7; lift = 6; headRot = -0.05; earRot = -0.05 + 0.1 * sin(2 * t); tailRot = 0.9
        case .dizzy:
            tilt = 0.12 * sin(t); headRot = 0.08 * sin(t + 1); earRot = 0.3 + 0.4 * sin(t)
        }
        let fx: CGFloat = f.mood == .fleeing ? 3 : 0
        let by = bob + bodyDy
        k.with(about(50, 30, rot: tilt).concatenating(about(50, 4, sx: b.sx, sy: b.sy))) {
            k.with(about(20, 32 + by, rot: tailRot)) {
                k.cel(smooth([22, 30 + by, 13, 36 + by, 12, 41 + by, 19, 38 + by], t: 0.7), muzzle, k.line * 0.85)
            }
            mascotFestiveQuadLegs(f, k, hips: [25, 31, 45, 52], hipY: 22 + by, near: fur, far: farFur, foot: hoof, width: 6.5, reach: reach, lift: lift, splay: splay)
            mascotFestiveBead(k, 38, 27 + by, 20, 12, fur, k.line)
            k.clip(ell(38, 27 + by, 20, 12)) { k.fill(ell(42, 16 + by, 15, 6.5), muzzle.base) }
            k.stroke(ell(38, 27 + by, 20, 12), fur.line, k.line)
            k.with(CGAffineTransform(translationX: fx, y: by + headDy).concatenating(about(56, 38 + by, rot: headRot))) {
                let left = smooth([48, 74, 44, 86, 37, 95], closed: false)
                let left2 = smooth([44, 85, 50, 91, 51, 96], closed: false)
                let left3 = smooth([40, 91, 33, 90], closed: false)
                let right = smooth([64, 76, 69, 89, 76, 98], closed: false)
                let right2 = smooth([69, 88, 63, 95, 62, 100], closed: false)
                let right3 = smooth([73, 94, 81, 93], closed: false)
                let both = CGMutablePath()
                for p in [left, left2, left3, right, right2, right3] { both.addPath(p) }
                mascotFestiveBranch(k, both, antler, 4.4)
                if f.variant % 5 == 4 { mascotReindeerHolly(k, 42, 88) }
                k.with(about(37, 70, rot: earRot)) {
                    mascotFestiveBead(k, 30, 70, 9, 4.2, fur, k.line * 0.9)
                    k.fill(ell(30, 70, 5.5, 2), Tone(0xffa8b8, 0.85))
                }
                k.with(about(76, 72, rot: -earRot - (f.mood == .calm ? 0.25 * f.twitch : 0))) {
                    mascotFestiveBead(k, 83, 72, 9, 4.2, fur, k.line * 0.9)
                    k.fill(ell(83, 72, 5.5, 2), Tone(0xffa8b8, 0.85))
                }
                mascotFestiveBead(k, 57, 57, 22, 22, fur, k.bold)
                mascotFestiveBead(k, 70, 44, 14, 10.5, muzzle, k.line * 0.95, rot: 0.08)
                mascotFestiveEyes(f, k, 58.5, 60, spread: 7.6, rx: 7.2, ry: 9.4, iris: iris, edge: fur.line, lid: fur.base, far: 0.86, blushX: 0.9, blushY: 3)
                let fxm: CGFloat = 0
                if f.variant % 5 == 1 {
                    k.glow(83 + fxm, 49, 8, Tone(0xff4050), 0.45)
                    mascotFestiveBead(k, 82.5 + fxm, 48.5, 5, 5, MascotTones(Tone(0xff3a48), shade: Tone(0xc01a2a), line: Tone(0x4a0a10)), k.line * 0.85)
                } else {
                    mascotFestiveBead(k, 82 + fxm, 48.5, 4.8, 4, MascotTones(Tone(0x5a3a3a), shade: Tone(0x2e1c1e), line: fur.line), k.line * 0.85)
                }
                k.fill(ell(81 + fxm, 50, 1.6, 1.1), Tone(0xffffff, 0.85))
                k.mouth(72, 41, 10, 6.5, edge: fur.line)
                k.marks(84, 84, 12, edge: fur.line)
            }
            if f.variant % 5 == 2 {
                k.stroke(arc(41 + fx, 41 + by, 63 + fx, 36 + by, dip: 5), Tone(0x4a0e14), k.line * 3.2)
                k.stroke(arc(41 + fx, 41 + by, 63 + fx, 36 + by, dip: 5), Tone(0xe8483e), k.line * 1.7)
                mascotFestiveBead(k, 53 + fx, 32.5 + by, 4, 4, MascotTones(Tone(0xffd23a), shade: Tone(0xe0a018), line: Tone(0x5a3a06)), k.line * 0.85)
                k.fill(circ(53 + fx, 31.5 + by, 1), Tone(0x5a3a06))
            }
            if f.variant % 5 == 3 {
                let scarf = MascotTones(Tone(0x42b062), shade: Tone(0x2a7a44), line: Tone(0x0f3a20))
                let flap: CGFloat = f.mood == .fleeing ? -8 : -2 * sin(t)
                k.cel(smooth([46 + fx, 37 + by, 38 + flap, 24 + by, 43 + flap, 22 + by, 50 + fx, 34 + by], t: 0.6), scarf, k.line * 0.85)
                k.cel(smooth([40 + fx, 41 + by, 52 + fx, 35 + by, 64 + fx, 37 + by, 63 + fx, 32 + by, 52 + fx, 30 + by, 40 + fx, 35 + by], t: 0.6), scarf, k.line * 0.85)
                k.stroke(line(48 + fx, 30.5 + by, 49 + fx, 36 + by), Tone(0xe8483e), k.line)
                k.stroke(line(56 + fx, 31 + by, 56.5 + fx, 36 + by), Tone(0xe8483e), k.line)
            }
        }
    }

    private static func mascotReindeerHolly(_ k: MascotKit, _ x: CGFloat, _ y: CGFloat) {
        let leaf = MascotTones(Tone(0x3fae5a), shade: Tone(0x2a7a40), line: Tone(0x0f3a1a))
        mascotFestiveBead(k, x - 5, y, 6, 3, leaf, k.line * 0.8, rot: 0.4)
        mascotFestiveBead(k, x + 5, y + 1, 6, 3, leaf, k.line * 0.8, rot: -0.4)
        mascotFestiveBead(k, x - 1, y + 2, 2.4, 2.4, MascotTones(Tone(0xff3a48), line: Tone(0x4a0a10)), k.line * 0.7)
        mascotFestiveBead(k, x + 2, y + 3.5, 2.4, 2.4, MascotTones(Tone(0xff3a48), line: Tone(0x4a0a10)), k.line * 0.7)
    }

    static func blackCat(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, Tone, Tone)] = [
            (MascotTones(Tone(0x5a5694), shade: Tone(0x2e2b62), line: Tone(0x14112e)), Tone(0x6ad040), Tone(0x7a76b4)),
            (MascotTones(Tone(0x5a5694), shade: Tone(0x2e2b62), line: Tone(0x14112e)), Tone(0xffb02a), Tone(0x7a76b4)),
            (MascotTones(Tone(0x544e86), shade: Tone(0x2c2658), line: Tone(0x120e2a)), Tone(0xffd23a), Tone(0x746eaa)),
            (MascotTones(Tone(0x5a5694), shade: Tone(0x2e2b62), line: Tone(0x14112e)), Tone(0x40c0d0), Tone(0x7a76b4)),
            (MascotTones(Tone(0x5c5890), shade: Tone(0x302c60), line: Tone(0x14112e)), Tone(0xffd23a), Tone(0xf6f4ff)),
        ]
        let (fur, iris, patchTone) = f.pick(looks)
        let tux = f.variant % 5 == 4
        let patch = MascotTones(patchTone, shade: tux ? Tone(0xc8c4e4) : patchTone.mix(fur.shade, 0.4), line: fur.line)
        let farFur = MascotTones(fur.shade, shade: fur.shade.dim(0.8), line: fur.line)
        let paw = tux ? patch : fur
        let b = k.bounce()
        let t = f.t
        let bob = 1.2 * f.bounce
        var tilt: CGFloat = 0, headRot: CGFloat = 0, headDy: CGFloat = 0, bodyDy: CGFloat = 0
        var reach: CGFloat = 5, lift: CGFloat = 3.5, splay: CGFloat = 0
        var earRot: CGFloat = 0
        var tail: [CGFloat] = [19, 28, 9, 34, 6, 50, 11 + 3 * f.twitch, 62, 18 + 4 * f.twitch, 62]
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            reach = 1.5; lift = 1; bodyDy = -3; headDy = -3; headRot = -0.08; earRot = -0.25
            tail = [19, 26, 8, 22, 6, 14, 14, 9, 24, 9]
        case .startled:
            reach = 2; bodyDy = 3; headDy = 4; earRot = 0.15; splay = 4
            tail = [19, 30, 13, 44, 12, 60, 14, 72, 13, 80]
        case .fleeing:
            reach = 7; lift = 5; earRot = 0.55
            tail = [19, 30, 8, 33, -2, 36, -8, 40 + 3 * sin(2 * t), -12, 44 + 4 * sin(2 * t)]
        case .dizzy:
            tilt = 0.12 * sin(t); headRot = 0.07 * sin(t + 1)
            tail = [19, 28, 9, 34, 6 + 3 * sin(t), 48, 14 + 5 * sin(t), 56, 20, 52]
        }
        let fx: CGFloat = f.mood == .fleeing ? 3 : 0
        let by = bob + bodyDy
        k.with(about(50, 30, rot: tilt).concatenating(about(50, 4, sx: b.sx, sy: b.sy))) {
            var tp = tail
            for i in stride(from: 1, to: tp.count, by: 2) { tp[i] += by }
            mascotFestiveLimb(k, tp, 6.2, fur, k.line * 0.9)
            mascotFestiveQuadLegs(f, k, hips: [24, 30, 44, 51], hipY: 21 + by, near: fur, far: farFur, foot: paw, width: 6.6, reach: reach, lift: lift, splay: splay)
            mascotFestiveBead(k, 36, 26 + by, 20, 11.5, fur, k.line)
            if tux {
                k.clip(ell(36, 26 + by, 20, 11.5)) { k.fill(ell(54, 22 + by, 9, 13), patch.base) }
                k.stroke(ell(36, 26 + by, 20, 11.5), fur.line, k.line)
            }
            k.with(CGAffineTransform(translationX: fx, y: by + headDy).concatenating(about(58, 36 + by, rot: headRot))) {
                k.with(about(46, 72, rot: earRot)) {
                    k.cel(smooth([39, 70, 40, 93, 57, 76], t: 0.45), fur, k.line)
                    k.fill(smooth([42.5, 73, 43, 86, 52, 76], t: 0.5), Tone(0xff9ec4, 0.9))
                }
                k.with(about(72, 72, rot: -earRot - (f.mood == .calm ? 0.25 * f.twitch : 0))) {
                    k.cel(smooth([63, 77, 78, 93, 81, 70], t: 0.45), fur, k.line)
                    k.fill(smooth([67, 77, 76.5, 87, 78, 73], t: 0.5), Tone(0xff9ec4, 0.9))
                }
                if f.variant % 5 == 2 { mascotBlackCatHat(k) }
                mascotFestiveBead(k, 59, 55, 23, 23, fur, k.bold)
                mascotFestiveBead(k, 62, 42.5, 12, 8, patch, k.line * 0.8)
                if f.variant % 5 == 1 {
                    let bow = MascotTones(Tone(0xb070ff), line: Tone(0x3a1270))
                    k.cel(smooth([72, 74, 63, 81, 62, 70], t: 0.45), bow)
                    k.cel(smooth([72, 74, 81, 82, 83, 70], t: 0.45), bow)
                    mascotFestiveBead(k, 72, 74, 3, 3, bow, k.line)
                }
                mascotFestiveEyes(f, k, 60.5, 57, spread: 8.2, rx: 7.8, ry: 10, iris: iris, edge: fur.line, lid: fur.base, far: 0.88, blushX: 0.95, blushY: 3)
                let wh = Tone(0xdcd6ff, 0.9)
                let ww = k.line * 0.55
                k.stroke(line(71, 45, 80, 47), wh, ww)
                k.stroke(line(71, 43, 80, 41.5), wh, ww)
                k.stroke(line(52, 45, 41, 47), wh, ww)
                k.stroke(line(52, 43, 41, 41.5), wh, ww)
                k.mouth(62.5, 43, 9, 6, edge: fur.line)
                k.fs(smooth([60, 47.5, 65, 47.5, 62.5, 44.5], t: 0.6), Tone(0xff8aa8), fur.line, k.line * 0.6)
                k.marks(84, 82, 12, edge: fur.line)
            }
            if f.variant % 5 == 3 {
                k.stroke(arc(46 + fx, 37 + by, 68 + fx, 34 + by, dip: 4.5), Tone(0x4a0e14), k.line * 3.2)
                k.stroke(arc(46 + fx, 37 + by, 68 + fx, 34 + by, dip: 4.5), Tone(0xe8483e), k.line * 1.7)
                mascotFestiveBead(k, 57 + fx, 29.5 + by, 3.8, 3.8, MascotTones(Tone(0xffd23a), shade: Tone(0xe0a018), line: Tone(0x5a3a06)), k.line * 0.85)
                k.fill(circ(57 + fx, 28.5 + by, 0.9), Tone(0x5a3a06))
            }
        }
    }

    private static func mascotBlackCatHat(_ k: MascotKit) {
        let hat = MascotTones(Tone(0x8a5ce6), line: Tone(0x2c1a5e))
        k.with(about(60, 76, rot: -0.15)) {
            let cone = smooth([46, 76, 74, 76, 68, 90, 80, 102, 56, 92], t: 0.5)
            k.cel(cone, hat, k.line, k: 0.15)
            k.clip(cone) { k.fill(rrect(40, 77, 40, 5, 0), Tone(0xff9a2a)) }
            k.stroke(cone, hat.line, k.line)
            mascotFestiveBead(k, 60, 76, 21, 4.6, hat, k.line)
        }
    }

    static func santa(_ f: FigureFrame, _ k: MascotKit) {
        let looks: [(MascotTones, Tone)] = [
            (MascotTones(Tone(0xe23a3a), shade: Tone(0xa82228), line: Tone(0x480a10)), Tone(0x2f8ad8)),
            (MascotTones(Tone(0xe23a3a), shade: Tone(0xa82228), line: Tone(0x480a10)), Tone(0x30a060)),
            (MascotTones(Tone(0xe23a3a), shade: Tone(0xa82228), line: Tone(0x480a10)), Tone(0x6a46d0)),
            (MascotTones(Tone(0x3a9a4e), shade: Tone(0x22683a), line: Tone(0x0c3018)), Tone(0x8a4a20)),
            (MascotTones(Tone(0xd8344a), shade: Tone(0x9c1e34), line: Tone(0x460a18)), Tone(0x3f7fe0)),
        ]
        let (coat, iris) = f.pick(looks)
        let v = f.variant % 5
        let skin = MascotTones(Tone(0xffd6b8), shade: Tone(0xf0a88c), line: Tone(0x5a2a1a))
        let fur = MascotTones(Tone(0xffffff), shade: Tone(0xd6daf0), line: Tone(0x4a3a5a))
        let boot = MascotTones(Tone(0x3e3448), shade: Tone(0x241e2c), line: Tone(0x120c18))
        let b = k.bounce()
        let t = f.t
        let bob = 1.4 * f.bounce
        var tilt: CGFloat = 0
        var reach: CGFloat = 5, lift: CGFloat = 3.5
        var tip = pt(17 + 2 * sin(t), 92 + 2 * f.twitch)
        switch f.mood {
        case .calm: break
        case .sleepy: reach = 1.5; lift = 1; tip = pt(18, 80)
        case .startled: reach = 2; tip = pt(36, 112)
        case .fleeing: tip = pt(6 + 2 * sin(2 * t), 90)
        case .dizzy: tilt = 0.12 * sin(t); tip = pt(26 + 10 * sin(t), 98)
        }
        var hands = mascotFestiveHands(f, 50, 28 + bob, 23)
        if v == 4 && f.mood == .calm { hands.r = pt(80, 46 + 2 * f.twitch) }
        let fx: CGFloat = f.mood == .fleeing ? 3 : 0
        k.with(about(50, 30, rot: tilt).concatenating(about(50, 4, sx: b.sx, sy: b.sy))) {
            if v == 1 {
                let sack = MascotTones(Tone(0xc08850), shade: Tone(0x8a5a30), line: Tone(0x3a2010))
                k.cel(smooth([30, 30 + bob, 14, 36 + bob, 10, 56 + bob, 20, 68 + bob, 34, 60 + bob, 38, 44 + bob], t: 0.8), sack, k.line, k: 0.15)
                k.stroke(line(22, 66 + bob, 28, 70 + bob), Tone(0x3a2010), k.line)
            }
            for which in [1, 0] {
                let s = mascotFestiveStep(f, which, reach: reach, lift: lift)
                let hx: CGFloat = which == 0 ? 56 : 44
                let footX = hx + s.x, footY = 8 + s.y
                mascotFestiveLimb(k, [hx, 14 + bob, footX, footY], 8, boot, k.line * 0.85)
                mascotFestiveBead(k, footX + 2, footY - 2, 6.5, 3.8, which == 0 ? boot : MascotTones(boot.shade, line: boot.line), k.line * 0.85)
            }
            mascotFestiveBead(k, 50, 22 + bob, 19, 14, coat, k.line)
            k.cel(rrect(31, 9 + bob, 38, 5, 2.5), fur, k.line * 0.8)
            k.cel(rrect(31.5, 18 + bob, 37, 5, 2), boot, k.line * 0.7)
            k.cel(rrect(46, 17 + bob, 8, 7, 1.5), MascotTones(Tone(0xffd23a), shade: Tone(0xe0a018), line: Tone(0x5a3a06)), k.line * 0.7)
            k.with(CGAffineTransform(translationX: 0, y: bob)) {
                mascotFestiveBead(k, 50, 60, 23, 23, skin, k.bold)
                mascotFestiveBlob(k, [circ(30, 48, 8.5), circ(37, 38, 9.5), circ(50, 34, 10.5), circ(63, 38, 9.5), circ(70, 48, 8.5), ell(50 + fx * 0.5, 45, 19, 12)], fur, k.line, k: 0.12)
                let cone = smooth([28, 80, 72, 80, 66, 96, 44, 104, tip.x, tip.y], t: 0.6)
                k.cel(cone, coat, k.line, k: 0.15)
                if v == 3 { mascotReindeerHolly(k, 64, 86) }
                mascotFestiveBead(k, tip.x, tip.y, 5, 5, fur, k.line * 0.9)
                k.cel(smooth([25, 79, 30, 84, 40, 85, 50, 85.5, 60, 85, 70, 84, 75, 79, 70, 74.5, 60, 75, 50, 74.5, 40, 75, 30, 74.5], t: 0.7), fur, k.line * 0.9, k: 0.2)
                mascotFestiveEyes(f, k, 50, 61.5, spread: 9.6, rx: 7.8, ry: 9.2, iris: iris, edge: skin.line, lid: skin.base, blushX: 1.2, blushY: -2)
                if v == 2 {
                    let gw = k.line * 0.8
                    let gold = Tone(0xc8901a)
                    let gx: CGFloat = 50 + fx
                    k.stroke(circ(gx - 9, 61.5, 9.5), gold, gw)
                    k.stroke(circ(gx + 9, 61.5, 9.5), gold, gw)
                    k.stroke(arc(gx - 1.5, 63, gx + 1.5, 63, dip: -1.5), gold, gw)
                }
                k.mouth(50 + fx, 44, 11, 7, edge: skin.line)
                mascotFestiveBead(k, 43.5 + fx, 49, 7, 4, fur, k.line * 0.85, rot: -0.25)
                mascotFestiveBead(k, 56.5 + fx, 49, 7, 4, fur, k.line * 0.85, rot: 0.25)
                mascotFestiveBead(k, 50 + fx, 52.5, 4, 4, MascotTones(Tone(0xff9a9a), shade: Tone(0xe86a72), line: skin.line), k.line * 0.8)
                k.marks(78, 82, 12, edge: coat.line)
            }
            for (sxp, h) in [(CGFloat(35), hands.l), (CGFloat(65), hands.r)] {
                mascotFestiveLimb(k, [sxp, 26 + bob, h.x, h.y], 7.5, coat, k.line * 0.9)
                if v == 4 && sxp > 50 { mascotSantaBell(f, k, h) }
                mascotFestiveBead(k, h.x, h.y, 4.4, 4.4, fur, k.line * 0.85)
            }
        }
    }

    private static func mascotSantaBell(_ f: FigureFrame, _ k: MascotKit, _ h: CGPoint) {
        let gold = MascotTones(Tone(0xffd23a), shade: Tone(0xe0a018), line: Tone(0x5a3a06))
        k.with(about(h.x, h.y, rot: -0.3 + 0.3 * f.twitch)) {
            k.stroke(line(h.x, h.y, h.x, h.y - 6), gold.line, k.line)
            k.cel(smooth([h.x - 3, h.y - 5, h.x + 3, h.y - 5, h.x + 7, h.y - 14, h.x, h.y - 15.5, h.x - 7, h.y - 14], t: 0.7), gold, k.line * 0.85)
            mascotFestiveBead(k, h.x, h.y - 15.5, 2, 2, gold, k.line * 0.7)
        }
    }
}
