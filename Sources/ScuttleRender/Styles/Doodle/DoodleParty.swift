import Foundation
import CoreGraphics
import ScuttleCore

extension DoodleArt {
    private static func partyW(_ k: DoodleKit) -> CGFloat { k.width(3.4, minPt: 1.3) }

    private static func partyThin(_ k: DoodleKit) -> CGFloat { k.width(2.4, minPt: 1.0) }

    private static func partyFill(_ k: DoodleKit, _ shape: CGPath, _ tone: Tone, _ ink: Tone, seed raw: Int) {
        let sd = k.seed(raw)
        var r = Noise(sd &+ 5151)
        let bb = shape.boundingBoxOfPath
        guard bb.width > 0.5, bb.height > 0.5 else { return }
        let s = max(0.88, 1 - 2.2 / max(bb.width, bb.height))
        let ox = r.range(-1.3, 1.3), oy = r.range(-1.3, 1.3)
        let rot = r.range(-0.035, 0.035)
        let t = CGAffineTransform(translationX: bb.midX + ox, y: bb.midY + oy).rotated(by: rot).scaledBy(x: s, y: s).translatedBy(x: -bb.midX, y: -bb.midY)
        let region = xf(shape, t)
        k.fill(region, tone)
        guard min(bb.width, bb.height) > 19 else { return }
        let gap = max(4.2, 1.9 * k.pt)
        let lw = max(1.3, 0.6 * k.pt)
        let ang = r.range(0.95, 1.2)
        let dx = cos(ang), dy = sin(ang)
        let half = (hypot(bb.width, bb.height) + 8) / 2
        var off: CGFloat = -half + r.range(0, gap)
        let hatch = CGMutablePath()
        let nx = -dy * lw / 2, ny = dx * lw / 2
        while off < half {
            let cx = bb.midX + dy * off, cy = bb.midY - dx * off
            let j = r.range(-1.5, 1.5)
            let ax = cx - dx * half, ay = cy - dy * half
            let bx = cx + dx * half + j, by = cy + dy * half
            hatch.addLines(between: [CGPoint(x: ax + nx, y: ay + ny), CGPoint(x: bx + nx, y: by + ny), CGPoint(x: bx - nx, y: by - ny), CGPoint(x: ax - nx, y: ay - ny)])
            hatch.closeSubpath()
            off += gap * r.range(0.85, 1.25)
        }
        k.clip(region) {
            k.fill(hatch, tone.mix(ink, 0.3).alpha(0.45))
        }
    }

    private static func partyStroke(_ k: DoodleKit, _ a: [CGFloat], _ tone: Tone, _ w: CGFloat) {
        k.stroke(smooth(a, closed: false), tone, w)
    }

    private static func partyCheeks(_ k: DoodleKit, _ x0: CGFloat, _ x1: CGFloat, _ y: CGFloat, _ r: CGFloat) {
        k.fill(ell(x0, y, r * 1.1, r * 0.8), k.cheek.alpha(0.85))
        k.fill(ell(x1, y, r * 1.1, r * 0.8), k.cheek.alpha(0.85))
    }

    private static func partyPart(_ k: DoodleKit, _ shape: CGPath, _ fill: Tone?, _ ink: Tone, seed: Int, w: CGFloat? = nil) {
        if let fill { partyFill(k, shape, fill, ink, seed: seed) }
        k.marker(shape, ink, w ?? partyW(k), seed: seed)
    }

    private static func partyStep(_ f: FigureFrame, _ which: Int, reach: CGFloat, lift: CGFloat) -> (x: CGFloat, y: CGFloat) {
        let tt = f.t + (which == 0 ? 0 : .pi)
        return (reach * cos(tt), lift * max(0, -sin(tt)))
    }

    private static func partyHat(_ k: DoodleKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, rot: CGFloat, fill: Tone, ink: Tone, seed: Int) {
        k.with(about(x, y, rot: rot)) {
            let cone = poly([x - s * 0.55, y, x + s * 0.55, y, x + s * 0.08, y + s * 1.15])
            partyPart(k, cone, fill, ink, seed: seed)
            k.dot(x + s * 0.08, y + s * 1.18, s * 0.22, s * 0.22, Tone(0xffc21a), seed: seed + 1)
        }
    }

    private static func partyBow(_ k: DoodleKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ tone: Tone, seed: Int) {
        let ink = tone.saturate(1.2).dim(0.78)
        let tie = poly([x - s, y + s * 0.65, x + s, y - s * 0.65, x + s, y + s * 0.65, x - s, y - s * 0.65])
        partyPart(k, tie, tone, ink, seed: seed, w: partyThin(k))
        k.dot(x, y, s * 0.32, s * 0.32, ink, seed: seed + 1)
    }

    private static func partyFlower(_ k: DoodleKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ petal: Tone, seed: Int) {
        let p = softStar(x, y, s, points: 5, inner: 0.5, spin: 0.3, t: 1.6)
        partyPart(k, p, petal, petal.saturate(1.2).dim(0.75), seed: seed, w: partyThin(k))
        k.dot(x, y, s * 0.34, s * 0.34, Tone(0xffc21a), seed: seed + 1)
    }

    static func balloon(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xff4d5e), Tone(0xb8124a)), (Tone(0x4aa8ff), Tone(0x2a4fd0)), (Tone(0xffd23f), Tone(0xff6a10)),
            (Tone(0x4fd17a), Tone(0x168a42)), (Tone(0xb57bff), Tone(0x6a2fd8)),
        ]
        let (body, ink) = f.pick(looks)
        let t = f.t
        var rot: CGFloat = 0.05 * f.swing
        var sx: CGFloat = 1, sy: CGFloat = 1 + 0.025 * f.swing2
        var endX: CGFloat = 46 + 5 * f.swing, endY: CGFloat = -4
        var bend: CGFloat = 4 * f.sway
        var lift: CGFloat = 0
        var faceX: CGFloat = 0
        switch f.mood {
        case .calm:
            endX += 5 * f.twitch
        case .sleepy:
            sx = 1.07
            sy = 0.88
            lift = -6
            rot = -0.16 + 0.02 * f.swing
            bend = 1.2 * f.sway
            endX = 48
        case .startled:
            sx = 0.92
            sy = 1.1
            lift = 3
            bend = 0.8 * f.swing2
            endX = 50
            endY = -6
        case .fleeing:
            rot = 0.14
            endX = 12
            endY = 6 + 3 * f.swing
            bend = 6 * f.swing
            faceX = 3
        case .dizzy:
            rot = 0.14 * sin(t)
            bend = 5 * sin(t * 2)
        }
        let knotY: CGFloat = 25 + lift
        let string = smooth([50, knotY - 2, 50 + bend, knotY - 9, (50 + endX) / 2 - bend, (knotY + endY) / 2 - 3, endX, endY], closed: false)
        k.marker(string, ink, partyThin(k), seed: 1)
        k.with(about(50, knotY, rot: rot, sx: sx, sy: sy)) {
            let y0 = lift
            let shape: CGPath
            if f.variant % 5 == 4 {
                shape = xf(heart(50, 62, 27), about(50, 62, sy: 1.08))
            } else {
                shape = smooth([50, 91 + y0, 71, 84 + y0, 78, 62 + y0, 68, 37 + y0, 50, 28 + y0, 32, 37 + y0, 22, 62 + y0, 29, 84 + y0])
            }
            let shifted = f.variant % 5 == 4 ? moved(shape, 0, y0) : shape
            partyPart(k, poly([50, 30 + y0, 44, 23 + y0, 56, 23 + y0]), body, ink, seed: 2)
            partyPart(k, shifted, body, ink, seed: 3)
            if f.variant % 5 == 3 {
                k.dot(35, 48 + y0, 5, 5, .white, seed: 4)
                k.dot(67, 42 + y0, 4.4, 4.4, .white, seed: 5)
                k.dot(64, 77 + y0, 4, 4, .white, seed: 6)
            }
            k.marker(arc(30, 66 + y0, 39, 82 + y0, dip: -4), .white, partyW(k), seed: 7)
            k.face(51 + faceX, 59 + y0, spread: 8.5, rx: 3.7, ry: 5.2, cheeks: false, seed: 10)
            if f.variant % 5 != 0 { partyCheeks(k, 35 + faceX, 67 + faceX, 49 + y0, 3.6) }
            switch f.variant % 5 {
            case 1:
                partyHat(k, 52, 88 + y0, 15, rot: -0.2, fill: Tone(0xffd23f), ink: Tone(0xff6a10), seed: 20)
            case 2:
                partyBow(k, 50, 23 + y0, 10, Tone(0xff5aa8), seed: 22)
            default:
                break
            }
            k.marks(74, 88 + y0, 13, ink: ink, seed: 30)
        }
    }

    static func star(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xffd23f), Tone(0xff6a10)), (Tone(0xff7ab8), Tone(0xd8186e)), (Tone(0x5ec8ff), Tone(0x2a5fe0)),
            (Tone(0x7ee08a), Tone(0x179a44)), (Tone(0xc49bff), Tone(0x6a2fd8)),
        ]
        let (body, ink) = f.pick(looks)
        let t = f.t
        var r: CGFloat = 37, inner: CGFloat = 0.52
        var rot: CGFloat = 0.06 * f.swing
        var sx: CGFloat = 1, sy: CGFloat = 1
        var faceX: CGFloat = 0
        var trail = false
        var twinkle = true
        switch f.mood {
        case .calm:
            rot += 0.06 * f.twitch
        case .sleepy:
            r = 34
            inner = 0.58
            rot = 0.3
            sy = 0.92
            twinkle = false
        case .startled:
            r = 40
            inner = 0.45
            sx = 0.96
            sy = 1.06
        case .fleeing:
            rot = -0.18
            trail = true
            faceX = 3
        case .dizzy:
            rot = 0.16 * sin(t)
        }
        if trail {
            for i in 0..<3 {
                let y = 38 + CGFloat(i) * 12
                let len = 12 + 4 * sin(t * 2 + CGFloat(i))
                partyStroke(k, [10 - len, y, 10, y + 1], ink, partyW(k))
            }
        }
        if twinkle {
            let on = f.frameIndex % 8 < 4
            let sp: [CGFloat] = on ? [90, 84, 6, 24] : [10, 86, 92, 22]
            for i in 0..<2 {
                let x = sp[i * 2], y = sp[i * 2 + 1]
                let s: CGFloat = 5.5
                let p = CGMutablePath()
                p.addPath(line(x - s, y + 0.4, x + s, y - 0.4))
                p.addPath(line(x + 0.4, y - s, x - 0.4, y + s))
                k.stroke(p, ink, partyThin(k))
            }
        }
        k.with(about(50, 48, rot: rot, sx: sx, sy: sy)) {
            var pts: [CGPoint] = []
            for i in 0..<10 {
                let a = CGFloat.pi / 2 + CGFloat(i) * .pi / 5
                let pulse: CGFloat = 1 + 0.05 * sin(t * 2 + CGFloat(i))
                let rad = i % 2 == 0 ? r * pulse : r * inner
                pts.append(CGPoint(x: 50 + rad * cos(a), y: 48 + rad * sin(a)))
            }
            partyPart(k, smoothP(pts, t: 0.45), body, ink, seed: 3)
            k.marker(arc(36, 60, 42, 68, dip: -2), .white, partyW(k), seed: 4)
            k.face(50 + faceX, 47, spread: 8.5, rx: 3.6, ry: 5, cheeks: false, seed: 10)
            if f.variant % 5 != 1 { partyCheeks(k, 35 + faceX, 65 + faceX, 37, 3.4) }
            switch f.variant % 5 {
            case 1:
                partyBow(k, 50, 82, 8, Tone(0x5ec8ff), seed: 20)
            case 2:
                partyHat(k, 51, 76, 16, rot: -0.12, fill: Tone(0xff7ab8), ink: Tone(0xd8186e), seed: 22)
            case 3:
                partyFlower(k, 79, 60, 7.5, Tone(0xff7ab8), seed: 24)
            case 4:
                let crown = poly([40, 76, 60, 76, 63, 90, 56, 83, 50, 93, 44, 83, 37, 90])
                partyPart(k, crown, Tone(0xffd23f), Tone(0xff6a10), seed: 26)
            default:
                break
            }
            k.marks(78, 82, 13, ink: ink, seed: 30)
        }
    }

    static func sparkler(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xffd23f), Tone(0xff6a10)), (Tone(0xff8ad0), Tone(0xd8186e)), (Tone(0x7fd8ff), Tone(0x2a5fe0)),
            (Tone(0xa8f06a), Tone(0x2a9a3a)), (Tone(0xffd23f), Tone(0xff3d8b)),
        ]
        let (burst, ink) = f.pick(looks)
        let rays: [Tone] = f.variant % 5 == 4 ? [Tone(0xff3d8b), Tone(0x2a8bff), Tone(0x22b866), Tone(0xff8a1a)] : [ink, burst.saturate(1.3).dim(0.92)]
        let stickFill = Tone(0xd4d4e4), stickInk = Tone(0x6a5cd0)
        let t = f.t
        let e = f.energy
        var rOut: CGFloat = 22, rIn: CGFloat = 14.5
        var rayLen: CGFloat = 7
        var headRot: CGFloat = 0
        var rot: CGFloat = 0
        var sy: CGFloat = 1
        var reach: CGFloat = 6 * e
        var armL: [CGFloat] = [50, 31, 39, 33 + 3 * f.swing, 31, 39 + 3 * f.swing]
        var armR: [CGFloat] = [50, 31, 61, 33 - 3 * f.swing, 69, 39 - 3 * f.swing]
        var stream: CGFloat = 0
        var faceX: CGFloat = 0
        switch f.mood {
        case .calm:
            armR[5] += 7 * max(0, f.twitch)
            armR[4] += 1 * max(0, f.twitch)
        case .sleepy:
            rOut = 18
            rIn = 13.5
            rayLen = 0
            headRot = -0.3
            sy = 0.94
            reach = 2
            armL = [50, 30, 43, 24, 41, 17]
            armR = [50, 30, 57, 24, 59, 17]
        case .startled:
            rOut = 26
            rIn = 15
            rayLen = 11
            sy = 1.06
            armL = [50, 32, 37, 38, 29, 47]
            armR = [50, 32, 63, 38, 71, 47]
        case .fleeing:
            rayLen = 9
            stream = 1
            reach = 9
            armL = [50, 31, 38, 31, 27, 29 + 4 * f.swing]
            armR = [50, 31, 61, 27, 69, 31 - 4 * f.swing]
            faceX = 3
        case .dizzy:
            rot = 0.13 * sin(t)
        }
        let bob = 1.4 * f.bounce * e
        k.with(about(50, 4, rot: rot, sx: 1, sy: sy)) {
            for which in 0..<2 {
                let s = partyStep(f, which, reach: reach, lift: 3.5 * e)
                let hx: CGFloat = which == 0 ? 47 : 53
                k.stick([hx, 16 + bob, hx + s.x * 0.5, 10 + s.y, hx + s.x, 4 + s.y, hx + s.x + 4, 4 + s.y], stickInk, seed: 1 + which, w: partyW(k))
            }
            k.stick(armL, stickInk, seed: 3, w: partyW(k))
            k.stick(armR, stickInk, seed: 4, w: partyW(k))
            partyPart(k, rrect(45.5, 13 + bob, 9, 36, 4.5), stickFill, stickInk, seed: 5)
            if f.variant % 5 == 1 {
                partyBow(k, 50, 30 + bob, 6.5, Tone(0x5ec8ff), seed: 20)
            }
            if f.variant % 5 == 2 {
                k.marker(line(45, 40 + bob, 55, 38 + bob), Tone(0xff4f5e), partyW(k) * 1.4, seed: 22)
                k.marker(smooth([46, 39 + bob, 42, 32 + bob, 38 - 3 * stream, 30 + bob + f.swing], closed: false), Tone(0xff4f5e), partyW(k) * 1.2, seed: 23)
            }
            let cx: CGFloat = 50, cy: CGFloat = 68 + bob
            k.with(about(50, 48 + bob, rot: headRot)) {
                if rayLen > 0 {
                    let flick = f.frameIndex % 2
                    for i in 0..<10 {
                        let a0 = CGFloat(i) * .pi / 5 + (flick == 0 ? 0 : .pi / 10)
                        var a = a0
                        if stream > 0 {
                            let back: CGFloat = .pi
                            let d = atan2(sin(back - a0), cos(back - a0))
                            a = a0 + d * 0.45
                        }
                        let n0 = CGFloat((i * 7 + f.frameIndex * 3) % 5) / 5
                        let r0 = rOut + 3
                        let r1 = rOut + 3 + rayLen * (0.6 + 0.6 * n0) * (stream > 0 && cos(a) < 0 ? 1.5 : 1)
                        partyStroke(k, [cx + r0 * cos(a), cy + r0 * sin(a), cx + r1 * cos(a), cy + r1 * sin(a)], rays[i % rays.count], partyThin(k))
                    }
                }
                var pts: [CGPoint] = []
                var nz = Noise(77 &+ f.frameIndex / 2 &* 13)
                for i in 0..<20 {
                    let a = CGFloat(i) * .pi / 10
                    let rad = i % 2 == 0 ? rOut * nz.range(0.9, 1.08) : rIn
                    pts.append(CGPoint(x: cx + rad * cos(a), y: cy + rad * sin(a)))
                }
                partyPart(k, polyP(pts), burst, ink, seed: 6)
                k.face(cx + 2 + faceX, cy, spread: 6.5, rx: 3.3, ry: 4.6, cheeks: false, seed: 10)
                if f.variant % 5 == 3 {
                    partyHat(k, cx + 3, cy + rIn - 1, 14, rot: -0.25, fill: Tone(0xb57bff), ink: Tone(0x6a2fd8), seed: 24)
                }
                k.marks(cx + 22, cy + 18, 12, ink: ink, seed: 30)
            }
        }
    }

    static func rocket(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone, Tone, Tone)] = [
            (Tone(0xf6f8ff), Tone(0x3a6cf0), Tone(0xff4d5e), Tone(0xb8124a)),
            (Tone(0x5ec8ff), Tone(0x2a4fd0), Tone(0xffd23f), Tone(0xff6a10)),
            (Tone(0xffd23f), Tone(0xff6a10), Tone(0xb57bff), Tone(0x6a2fd8)),
            (Tone(0x7ee08a), Tone(0x179a44), Tone(0xff7ab8), Tone(0xd8186e)),
            (Tone(0xff9a3c), Tone(0xd9480f), Tone(0x5e9cff), Tone(0x2a4fd0)),
        ]
        let (body, ink, trim, trimInk) = f.pick(looks)
        let t = f.t
        var flame: CGFloat = 16
        var rot: CGFloat = 0
        var sx: CGFloat = 1, sy: CGFloat = 1
        var faceX: CGFloat = 0
        var streaks = false
        var puffs = false
        switch f.mood {
        case .calm:
            rot = 0.04 * f.twitch
        case .sleepy:
            flame = 7
            rot = -0.1
            sy = 0.94
        case .startled:
            flame = 22
            sx = 1.06
            sy = 1.05
        case .fleeing:
            flame = 30
            streaks = true
            faceX = 1.5
        case .dizzy:
            rot = 0.14 * sin(t)
            puffs = true
        }
        let flick: CGFloat = 1 + 0.16 * sin(t * 4) + 0.08 * sin(t * 6 + 1)
        let fl = flame * flick
        if puffs {
            for i in 0..<2 {
                let px = 8 - CGFloat(i) * 9 + 2 * sin(t + CGFloat(i))
                let py = 54 + CGFloat(i) * 6 + 3 * cos(t * 2 + CGFloat(i))
                partyPart(k, circ(px, py, 5 - CGFloat(i)), Tone(0xdcdcea), Tone(0x8a84b8), seed: 70 + i, w: partyThin(k))
            }
        }
        if streaks {
            for i in 0..<2 {
                let y: CGFloat = i == 0 ? 68 : 32
                let x0 = 4 - 6 * sin(t * 2 + CGFloat(i))
                partyStroke(k, [x0 - 12, y, x0, y], ink, partyThin(k))
            }
        }
        k.with(about(50, 50, rot: rot, sx: sx, sy: sy)) {
            let wob = 1.5 * sin(t * 4)
            let outer = smooth([22, 57, 22 - fl * 0.45, 58 + wob, 22 - fl, 50, 22 - fl * 0.45, 42 - wob, 22, 43], t: 0.8)
            partyPart(k, outer, Tone(0xff9a1f), Tone(0xff4a10), seed: 1)
            let inner = smooth([22, 54, 22 - fl * 0.3, 53, 22 - fl * 0.6, 50, 22 - fl * 0.3, 47, 22, 46], t: 0.8)
            partyFill(k, inner, Tone(0xffe23a), Tone(0xffb000), seed: 2)
            let finT = smooth([26, 58, 18, 74, 32, 72, 44, 60], t: 0.7)
            partyPart(k, finT, trim, trimInk, seed: 3)
            partyPart(k, xf(finT, CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: 100)), trim, trimInk, seed: 4)
            let hull = smooth([20, 44, 20, 56, 34, 63, 58, 64, 74, 61, 74, 39, 58, 36, 34, 37], t: 0.8)
            partyPart(k, hull, body, ink, seed: 5)
            switch f.variant % 5 {
            case 1:
                k.marker(line(34, 39, 34, 61), trim.dim(0.9), partyW(k) * 1.5, seed: 20)
            case 2:
                partyPart(k, star(34, 50, 7, inner: 0.48), Tone(0xff7ab8), Tone(0xd8186e), seed: 21, w: partyThin(k))
            case 3:
                k.dot(30, 44, 2.8, 2.8, .white, seed: 22)
                k.dot(36, 56, 2.6, 2.6, .white, seed: 23)
            case 4:
                k.stick([30, 61, 30, 74], trimInk, seed: 24, w: partyThin(k))
                partyPart(k, poly([30, 74, 30, 66, 40 + 2 * sin(t * 3), 71]), Tone(0xffd23f), Tone(0xff6a10), seed: 25, w: partyThin(k))
            default:
                break
            }
            let nose = smooth([72, 63, 84, 58, 93, 50, 84, 42, 72, 37], closed: true, t: 0.8)
            partyPart(k, nose, trim, trimInk, seed: 6)
            partyPart(k, circ(55 + faceX * 0.3, 50, 12), Tone(0x9fe2ff), trimInk, seed: 7)
            k.face(55 + faceX, 52.5, spread: 5.2, rx: 3.2, ry: 4.2, cheeks: false, seed: 10)
            k.marks(70, 70, 12, ink: ink, seed: 30)
        }
    }

    static func bunny(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xfdfaf6), Tone(0xff3d8b)), (Tone(0xd9955a), Tone(0xa8460f)), (Tone(0xbac2d6), Tone(0x3f5fd8)),
            (Tone(0xffe9b0), Tone(0xff7a1a)), (Tone(0xd6bcff), Tone(0x6a2fd8)),
        ]
        let (fur, ink) = f.pick(looks)
        let pink = Tone(0xff8ab8)
        let t = f.t
        let sq = f.squat, st = f.stretch
        var sy: CGFloat = 1 - 0.16 * sq + 0.1 * st
        var sx: CGFloat = 1 + 0.1 * sq - 0.05 * st
        var earBack: CGFloat = 0.25 * max(0, st) - 0.15 * sq - 0.1 * max(0, -st)
        var earFlop: CGFloat = 0.2 * f.twitch
        var rot: CGFloat = 0
        var footDX: CGFloat = -5 * max(0, st) + 4 * max(0, -st)
        var footDY: CGFloat = f.airborne ? 3 * sin(f.air * .pi) : 0
        var faceX: CGFloat = 0
        var earLen: CGFloat = 1
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sy = 0.9
            sx = 1.05
            earBack = 1.15
            earFlop = 0.15
            footDX = 0
            footDY = 0
            earLen = 0.92
        case .startled:
            sy = 1.08 + 0.04 * st
            sx = 0.95
            earBack = -0.12
            earFlop = 0
            earLen = 1.12
        case .fleeing:
            earBack = 0.95
            earFlop = 0.1 * f.swing
            faceX = 2
            footDX -= 3
        case .dizzy:
            rot = 0.12 * sin(t)
            earBack = 0.3 * sin(t)
            earFlop = -0.4 * sin(t)
        }
        k.with(about(48, 4, rot: rot, sx: sx, sy: sy)) {
            partyPart(k, ell(38 + footDX, 8 + footDY, 10, 4.5), fur, ink, seed: 1)
            partyPart(k, circ(23, 32, 7.5), .white, ink, seed: 2)
            partyPart(k, ell(45, 27, 21, 18), fur, ink, seed: 3)
            partyPart(k, ell(57 + footDX * 0.6, 8 + footDY, 7, 4.2), fur, ink, seed: 4)
            let earA: CGFloat = 0.15 + earBack
            let earB: CGFloat = -0.08 + earBack * 0.9 + earFlop
            let px: CGFloat = 60, py: CGFloat = 58
            for (i, a) in [earA, earB].enumerated() {
                let ex: CGFloat = i == 0 ? px - 4 : px + 5
                k.with(about(ex, py, rot: a, sx: 1, sy: earLen)) {
                    let outer = ell(ex, py + 14, 5.6, 15)
                    partyPart(k, outer, fur, ink, seed: 5 + i * 2)
                    partyFill(k, ell(ex, py + 14, 2.6, 10), pink, pink, seed: 6 + i * 2)
                }
            }
            partyPart(k, ell(62, 48, 17, 15), fur, ink, seed: 9)
            k.face(66 + faceX, 50, spread: 6.5, rx: 3.3, ry: 4.6, mouth: true, cheeks: false, seed: 10)
            k.dot(66 + faceX, 44, 2.6, 2, pink.dim(0.95), seed: 16)
            partyCheeks(k, 57 + faceX, 76 + faceX, 42, 2.8)
            switch f.variant % 5 {
            case 1:
                partyFlower(k, 52, 60, 6.5, Tone(0xffd23f), seed: 20)
            case 2:
                partyBow(k, 66, 31, 6, Tone(0x4aa8ff), seed: 22)
            case 3:
                let carrot = poly([70, 30, 78, 32, 74, 14])
                partyPart(k, carrot, Tone(0xff8a1a), Tone(0xd94a0a), seed: 24, w: partyThin(k))
                k.marker(smooth([74, 31, 73, 36, 70, 38], closed: false), Tone(0x22a04a), partyThin(k), seed: 25)
                k.marker(smooth([75, 31, 78, 37, 81, 38], closed: false), Tone(0x22a04a), partyThin(k), seed: 26)
            case 4:
                partyHat(k, 70, 60, 14, rot: -0.35, fill: Tone(0x4fd17a), ink: Tone(0x168a42), seed: 27)
            default:
                break
            }
            k.marks(82, 70, 13, ink: ink, seed: 30)
        }
    }

    static func turtle(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0x3fc46a), Tone(0x137a3c), Tone(0x1f9a4c)), (Tone(0x4aa8ff), Tone(0x2a4fd0), Tone(0x2a74e0)),
            (Tone(0xff9a3c), Tone(0xc8440c), Tone(0xe06a1a)), (Tone(0xb57bff), Tone(0x5f2acc), Tone(0x8a4ff0)),
            (Tone(0xff7ab8), Tone(0xc8125e), Tone(0xffffff)),
        ]
        let (shell, ink, spot) = f.pick(looks)
        let skin = Tone(0xbdec5e), skinInk = Tone(0x4f9a1e)
        let t = f.t
        let e = f.energy
        var headX: CGFloat = 86, headY: CGFloat = 26
        var legLift: CGFloat = 3 * e, legReach: CGFloat = 3 * e
        var tuck: CGFloat = 0
        var splay: CGFloat = 0
        var hop: CGFloat = 0
        var rot: CGFloat = 0
        var faceX: CGFloat = 0
        switch f.mood {
        case .calm:
            headY += 1.2 * f.swing
            headX += 1.5 * f.twitch
        case .sleepy:
            headX = 79
            headY = 20
            tuck = 4
            legLift = 0
            legReach = 0
        case .startled:
            headX = 88
            headY = 36
            splay = 6
            hop = 3
            legLift = 0
        case .fleeing:
            headX = 92
            headY = 25 + 1.5 * f.swing2
            legReach = 7
            legLift = 4
            faceX = 1.5
        case .dizzy:
            rot = 0.12 * sin(t)
            headY += 2 * sin(t * 2)
        }
        k.with(about(50, 6, rot: rot)) {
            let legX: [CGFloat] = [22, 66, 32, 74]
            for i in [2, 3, 0, 1] {
                let ph = t + CGFloat(i) * .pi / 2 + (i % 2 == 0 ? 0 : .pi)
                let lx = legX[i] + legReach * cos(ph) + (i % 2 == 0 ? -splay : splay)
                let ly = 9 + legLift * max(0, sin(ph)) + tuck + hop
                let far = i >= 2
                partyPart(k, ell(lx, ly - 1, 7.5, 7 - tuck * 0.4), far ? skin.dim(0.86) : skin, skinInk, seed: 1 + i)
            }
            partyPart(k, poly([18, 18 + hop, 8, 13 + hop, 18, 12 + hop]), skin, skinInk, seed: 5, w: partyThin(k))
            let neck = smooth([72, 22 + hop, headX - 4, headY - 3, headX - 4, headY + 4, 72, 30 + hop], t: 0.6)
            partyPart(k, neck, skin, skinInk, seed: 6)
            partyPart(k, circ(headX, headY + hop, 12), skin, skinInk, seed: 7)
            k.face(headX + 1.5 + faceX, headY + 2.5 + hop, spread: 5, rx: 2.9, ry: 4, cheeks: false, seed: 10)
            let dome = CGMutablePath()
            dome.move(to: pt(14, 16 + hop))
            dome.addCurve(to: pt(47, 54 + hop), control1: pt(14, 40 + hop), control2: pt(29, 54 + hop))
            dome.addCurve(to: pt(80, 16 + hop), control1: pt(65, 54 + hop), control2: pt(80, 40 + hop))
            dome.closeSubpath()
            partyPart(k, dome, shell, ink, seed: 8)
            for (i, c) in [(32, 30, 6.5), (48, 41, 7), (63, 30, 6.5)].enumerated() {
                partyPart(k, circ(CGFloat(c.0), CGFloat(c.1) + hop, CGFloat(c.2)), spot, ink, seed: 16 + i, w: partyThin(k))
            }
            partyPart(k, rrect(11, 11 + hop, 72, 8, 4), shell.lift(0.35), ink, seed: 19)
            switch f.variant % 5 {
            case 1:
                partyBow(k, headX - 3, headY + 11 + hop, 5.5, Tone(0xff4f8b), seed: 20)
            case 2:
                partyFlower(k, 48, 56 + hop, 7.5, Tone(0xff5aa8), seed: 22)
            case 3:
                partyHat(k, headX - 1, headY + 9 + hop, 13, rot: -0.3, fill: Tone(0xffd23f), ink: Tone(0xff6a10), seed: 24)
            default:
                break
            }
            k.marks(headX + 8, headY + 16 + hop, 11, ink: skinInk, seed: 30)
        }
    }

    static func fox(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xff8a2a), Tone(0xc23a0a)), (Tone(0xff8a2a), Tone(0xc23a0a)), (Tone(0xeef2ff), Tone(0x3f6cf0)),
            (Tone(0xe8542a), Tone(0x8f1e0a)), (Tone(0xffc23a), Tone(0xd06a06)),
        ]
        let (fur, ink) = f.pick(looks)
        let legInk = ink.dim(0.8)
        let cream = Tone(0xfff8ee)
        let t = f.t
        let e = f.energy
        let bob = 1.4 * f.bounce * e
        var headDY: CGFloat = 0
        var earRot: CGFloat = 0.06 * f.twitch
        var earLen: CGFloat = 1
        var tailRot: CGFloat = 0.12 * f.swing + 0.15 * f.twitch
        var reach: CGFloat = 6 * e
        var rot: CGFloat = 0
        var faceX: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            headDY = -5
            earRot = 0.35
            earLen = 0.9
            tailRot = 0.9
            reach = 2
        case .startled:
            headDY = 3
            earLen = 1.2
            tailRot = -0.4
        case .fleeing:
            tailRot = 0.55 + 0.1 * f.swing
            earRot = -0.3
            reach = 10
            faceX = 2
        case .dizzy:
            rot = 0.12 * sin(t)
            tailRot = 0.3 * sin(t * 2)
        }
        k.with(about(50, 4, rot: rot)) {
            let legs: [(CGFloat, Int)] = [(34, 1), (58, 0), (28, 0), (52, 1)]
            for (i, l) in legs.enumerated() {
                let s = partyStep(f, l.1, reach: reach, lift: 4 * e)
                let w = i >= 2 ? partyW(k) : partyW(k) * 1.15
                k.stick([l.0, 24 + bob, l.0 + s.x * 0.5, 13 + s.y, l.0 + s.x, 4 + s.y], i >= 2 ? legInk.lift(0.15) : legInk, seed: 1 + i, w: w)
            }
            k.with(about(28, 34 + bob, rot: tailRot)) {
                let tail = smooth([30, 38 + bob, 16, 30 + bob, 4, 40 + bob, 4, 58 + bob, 14, 54 + bob, 24, 44 + bob], t: 0.9)
                partyPart(k, tail, fur, ink, seed: 5)
                partyPart(k, ell(6, 55 + bob, 5.5, 5, 0.4), cream, ink, seed: 6, w: partyThin(k))
            }
            partyPart(k, ell(45, 31 + bob, 22, 12), fur, ink, seed: 7)
            let hy: CGFloat = 50 + bob + headDY
            k.both { s in
                let ex: CGFloat = 70 + s * 9
                k.with(about(ex, hy + 9, rot: -s * earRot, sx: 1, sy: earLen)) {
                    partyPart(k, poly([ex - 6, hy + 8, ex + s * 2, hy + 26, ex + 6, hy + 8]), fur, ink, seed: s > 0 ? 8 : 9)
                }
            }
            let head = smooth([55, hy + 11, 70, hy + 15, 85, hy + 11, 80, hy - 2, 70, hy - 13, 60, hy - 2], t: 0.75)
            partyPart(k, head, fur, ink, seed: 12)
            partyFill(k, smooth([62, hy - 3, 70, hy - 1, 78, hy - 3, 70, hy - 12], t: 0.8), cream, ink, seed: 13)
            k.face(70 + faceX, hy + 3, spread: 5.6, rx: 2.9, ry: 3.9, mouth: false, cheeks: false, seed: 14)
            k.dot(70 + faceX, hy - 10, 3, 2.4, Tone(0x2a1a22), seed: 20)
            k.mouth(70 + faceX, hy - 5.5, 6, seed: 21)
            switch f.variant % 5 {
            case 1:
                k.marker(smooth([58, 38 + bob + headDY, 66, 34 + bob + headDY, 76, 36 + bob + headDY], closed: false), Tone(0x3a7cff), partyW(k) * 1.8, seed: 22)
                k.marker(smooth([60, 36 + bob + headDY, 57, 26 + bob, 54 - 2 * f.swing, 22 + bob], closed: false), Tone(0x3a7cff), partyW(k) * 1.5, seed: 23)
            case 3:
                partyHat(k, 72, hy + 13, 14, rot: -0.2, fill: Tone(0x4aa8ff), ink: Tone(0x2a4fd0), seed: 24)
            case 4:
                partyFlower(k, 82, hy + 13, 6.5, Tone(0xff5aa8), seed: 26)
            default:
                break
            }
            k.marks(88, hy + 22, 12, ink: ink, seed: 30)
        }
    }

    static func polarBear(_ f: FigureFrame, _ k: DoodleKit) {
        let inks: [Tone] = [Tone(0x3a7cff), Tone(0x1e9ab8), Tone(0x6a4fe8), Tone(0xff3d8b), Tone(0x3a7cff)]
        let ink = f.pick(inks)
        let fur = Tone(0xfafcff), far = Tone(0xdfe8fa)
        let t = f.t
        let e = f.energy
        let bob = 1.2 * f.bounce * e
        var headDY: CGFloat = 0, headDX: CGFloat = 0
        var reach: CGFloat = 5 * e
        var legH: CGFloat = 16
        var rot: CGFloat = 0
        var faceX: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            headDY = -6
            headDX = -1
            reach = 1.5
            legH = 13
        case .startled:
            headDY = 4
            legH = 18
        case .fleeing:
            headDX = 3
            headDY = -1
            reach = 8
            faceX = 1.5
        case .dizzy:
            rot = 0.1 * sin(t)
        }
        k.with(about(50, 4, rot: rot)) {
            let legs: [(CGFloat, Int, Bool)] = [(32, 0, true), (62, 1, true), (22, 1, false), (52, 0, false)]
            for (i, l) in legs.enumerated() {
                let s = partyStep(f, l.1, reach: reach, lift: 3.5 * e)
                partyPart(k, rrect(l.0 + s.x - 5.5, 4 + s.y, 11, legH + bob, 5), l.2 ? far : fur, ink, seed: 1 + i)
            }
            partyPart(k, circ(14, 38 + bob + 1.5 * f.twitch, 4.5), fur, ink, seed: 5, w: partyThin(k))
            partyPart(k, ell(44, 32 + bob, 30, 17), fur, ink, seed: 6)
            let hx: CGFloat = 76 + headDX, hy: CGFloat = 44 + bob + headDY
            let tw = 1.5 * f.twitch
            partyPart(k, circ(hx - 7, hy + 12 + tw, 5), fur, ink, seed: 7)
            partyPart(k, circ(hx + 6, hy + 13, 5), fur, ink, seed: 8)
            partyPart(k, circ(hx, hy, 14), fur, ink, seed: 9)
            partyPart(k, ell(hx + 10, hy - 5, 8.5, 6.5), fur, ink, seed: 12)
            k.dot(hx + 15, hy - 2.5, 3, 2.4, Tone(0x2a1a22), seed: 13)
            k.face(hx + 1 + faceX, hy + 4, spread: 4.6, rx: 2.8, ry: 3.8, mouth: false, cheeks: false, seed: 14)
            k.mouth(hx + 11, hy - 8.5, 6, seed: 20)
            k.fill(ell(hx - 7, hy - 4, 3.3, 2.4), k.cheek.alpha(0.85))
            switch f.variant % 5 {
            case 1:
                k.marker(smooth([hx - 12, hy - 4, hx - 6, hy - 13, hx + 4, hy - 15], closed: false), Tone(0xff3d4e), partyW(k) * 2, seed: 22)
                k.marker(smooth([hx - 9, hy - 9, hx - 13 - 2 * f.swing, hy - 22, hx - 16 - 3 * f.swing, hy - 26], closed: false), Tone(0xff3d4e), partyW(k) * 1.6, seed: 23)
            case 2:
                let cap = CGMutablePath()
                cap.addArc(center: pt(hx, hy + 6), radius: 13.5, startAngle: 0.15, endAngle: .pi - 0.15, clockwise: false)
                cap.closeSubpath()
                partyPart(k, cap, Tone(0x3fc46a), Tone(0x137a3c), seed: 24)
                k.dot(hx, hy + 20, 4, 4, Tone(0xff4f5e), seed: 25)
            case 3:
                k.marker(arc(hx - 9, hy + 10, hx + 8, hy + 11, dip: -8), Tone(0xff3d8b), partyW(k), seed: 26)
                partyPart(k, circ(hx - 9, hy + 9, 5), Tone(0xff8ad0), Tone(0xd8186e), seed: 27)
            case 4:
                partyHat(k, hx + 1, hy + 12, 15, rot: -0.25, fill: Tone(0xffd23f), ink: Tone(0xff6a10), seed: 28)
            default:
                break
            }
            k.marks(hx + 14, hy + 20, 12, ink: ink, seed: 30)
        }
    }

    static func comet(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone, Tone, Tone)] = [
            (Tone(0xffd23f), Tone(0xff6a10), Tone(0xff9a2a), Tone(0xe0400a)),
            (Tone(0x7fe0ff), Tone(0x2a6fe0), Tone(0xb59bff), Tone(0x6a2fd8)),
            (Tone(0xff8ad0), Tone(0xd8186e), Tone(0xffc23a), Tone(0xe06a06)),
            (Tone(0xa8f06a), Tone(0x228a32), Tone(0x6ad0ff), Tone(0x1e6ad8)),
            (Tone(0xfff3c0), Tone(0xff6a10), Tone(0xff6ab0), Tone(0xd8186e)),
        ]
        let (head, ink, tail, tailInk) = f.pick(looks)
        let t = f.t
        var len: CGFloat = 1
        var spread: CGFloat = 1
        var droop: CGFloat = 0
        var rot: CGFloat = 0
        var faceX: CGFloat = 0
        var streak = false
        switch f.mood {
        case .calm:
            spread += 0.06 * f.twitch
        case .sleepy:
            len = 0.62
            droop = -8
            spread = 0.85
        case .startled:
            len = 0.85
            spread = 1.3
        case .fleeing:
            len = 1.3
            spread = 0.85
            streak = true
            faceX = 1.5
        case .dizzy:
            rot = 0.14 * sin(t)
            droop = 6 * sin(t * 2)
        }
        k.with(about(66, 50, rot: rot)) {
            let w1 = 3 * sin(t * 2), w2 = 3 * sin(t * 2 + 2)
            let L = 60 * len
            let sp = spread
            let dr = droop
            let tailPts: [CGFloat] = [
                68, 50 + 18 * sp,
                46, 50 + 15 * sp + w1 * 0.5,
                68 - L * 0.78, 50 + 19 * sp + dr * 0.8 + w2,
                50, 50 + 6 * sp + dr * 0.3,
                68 - L, 50 + dr + w1,
                50, 50 - 5 * sp + dr * 0.3,
                68 - L * 0.7, 50 - 15 * sp + dr * 0.7 - w2,
                46, 50 - 14 * sp - w1 * 0.5,
                68, 50 - 18 * sp,
            ]
            let tailP = smooth(tailPts, t: 0.55)
            partyPart(k, tailP, tail, tailInk, seed: 1)
            let stripes: [Tone] = f.variant % 5 == 4 ? [Tone(0x3a8bff), Tone(0x22b866)] : [.white, tail.lift(0.5)]
            for i in 0..<2 {
                let yy: CGFloat = 50 + (i == 0 ? 7 : -5) * spread
                let x0: CGFloat = 52 - 6 * CGFloat(i)
                k.marker(smooth([x0, yy, x0 - 12 * len, yy + w1 * 0.4 + droop * 0.3, x0 - 24 * len, yy + w2 * 0.5 + droop * 0.5], closed: false), stripes[i], partyW(k), seed: 2 + i)
            }
            if streak {
                for i in 0..<2 {
                    let y: CGFloat = i == 0 ? 76 : 26
                    let x0 = 30 - 8 * sin(t * 2 + CGFloat(i) * 2)
                    partyStroke(k, [x0 - 14, y, x0, y], tailInk, partyThin(k))
                }
            }
            if f.variant % 5 == 1 {
                for i in 0..<2 {
                    let on = (f.frameIndex / 4 + i) % 2 == 0
                    let x: CGFloat = i == 0 ? 30 : 16
                    let y: CGFloat = i == 0 ? 60 : 44
                    partyPart(k, star(x, y + droop * 0.5, on ? 5.5 : 4, inner: 0.45), .white, tailInk, seed: 24 + i, w: partyThin(k))
                }
            }
            partyPart(k, circ(68, 50, 18), head, ink, seed: 8)
            k.marker(arc(57, 56, 63, 64, dip: -2), .white, partyW(k), seed: 9)
            k.face(70 + faceX, 50, spread: 6.5, rx: 3.4, ry: 4.7, cheeks: false, seed: 10)
            if f.variant % 5 != 2 { partyCheeks(k, 57 + faceX, 83 + faceX, 41, 3.2) }
            switch f.variant % 5 {
            case 2:
                partyBow(k, 68, 68, 6.5, Tone(0x4aa8ff), seed: 20)
            case 3:
                partyHat(k, 70, 66, 15, rot: -0.15, fill: Tone(0xff7ab8), ink: Tone(0xd8186e), seed: 22)
            default:
                break
            }
            k.marks(84, 70, 12, ink: ink, seed: 30)
        }
    }

    static func ufo(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone, Tone, Tone)] = [
            (Tone(0xa98bff), Tone(0x5a2fc0), Tone(0x7ee05a), Tone(0x2a8a2a)),
            (Tone(0xff9a3c), Tone(0xc8400a), Tone(0xff8ad0), Tone(0xc8125e)),
            (Tone(0x3fd6c0), Tone(0x0f7a6a), Tone(0xc49bff), Tone(0x6a2fd8)),
            (Tone(0xff5a6e), Tone(0xb0124a), Tone(0x7fd8ff), Tone(0x2a5fe0)),
            (Tone(0xffd23f), Tone(0xe05a06), Tone(0x7ee05a), Tone(0x2a8a2a)),
        ]
        let (saucer, ink, alien, alienInk) = f.pick(looks)
        let glass = Tone(0xd6f6ff)
        let t = f.t
        let buzz: CGFloat = (f.frameIndex % 2 == 0 ? 0.7 : -0.7) * f.energy
        var rot: CGFloat = 0
        var dy: CGFloat = buzz
        var lightsOn = true
        var allOn = false
        var beam = false
        var antA: CGFloat = 0.2 * f.twitch
        var antUp: CGFloat = 0
        var puffs = false
        var faceX: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            rot = -0.08
            dy = -3
            lightsOn = false
            antA = 0.5
            antUp = -2
        case .startled:
            dy = 3 + buzz
            beam = true
            antUp = 3
            allOn = true
        case .fleeing:
            rot = -0.1
            puffs = true
            allOn = true
            antA = -0.5
            faceX = 2
        case .dizzy:
            rot = 0.14 * sin(t)
        }
        if beam {
            let b = poly([38, 24, 62, 24, 76, -4, 24, -4])
            k.fill(b, Tone(0xfff6a8, 0.82))
            k.marker(line(38, 24, 24, -4), Tone(0xffa000), partyThin(k), seed: 70)
            k.marker(line(62, 24, 76, -4), Tone(0xffa000), partyThin(k), seed: 71)
        }
        if puffs {
            for i in 0..<2 {
                let px = 6 - CGFloat(i) * 9 + 2 * sin(t * 2 + CGFloat(i))
                let py = 36 + CGFloat(i) * 3
                partyPart(k, circ(px, py, 5.5 - CGFloat(i) * 1.5), Tone(0xe2e2f0), Tone(0x8a84b8), seed: 72 + i, w: partyThin(k))
            }
        }
        k.with(about(50, 40, rot: rot).concatenating(CGAffineTransform(translationX: 0, y: dy))) {
            let dome = CGMutablePath()
            dome.addArc(center: pt(50, 40), radius: 26, startAngle: 0, endAngle: .pi, clockwise: false)
            dome.closeSubpath()
            partyFill(k, dome, glass, Tone(0x7fc8e8), seed: 1)
            partyPart(k, ell(50, 53, 13, 11), alien, alienInk, seed: 6)
            switch f.variant % 5 {
            case 1:
                k.face(50 + faceX, 53, spread: 5.4, rx: 2.8, ry: 3.6, mouth: false, cheeks: false, seed: 10)
                k.eye(50 + faceX, 60, 2.3, 2.9, side: 0, seed: 16)
            case 3:
                k.eye(50 + faceX, 55, 4.2, 5.2, side: 1, seed: 10)
            default:
                k.face(50 + faceX, 55, spread: 5.4, rx: 3, ry: 4, mouth: false, cheeks: false, seed: 10)
            }
            k.marker(dome, Tone(0x5ab0e0), partyW(k), seed: 7)
            k.both { s in
                let bx: CGFloat = 50 + s * 5
                let tipX = bx + s * 6 + (s > 0 ? antA : -antA) * 5
                let tipY: CGFloat = 73 + antUp
                k.stick([bx, 63, tipX, tipY], alienInk, seed: s > 0 ? 2 : 3, w: partyThin(k))
                k.dot(tipX, tipY, 3, 3, alienInk, seed: s > 0 ? 4 : 5)
            }
            if f.variant % 5 == 2 {
                partyBow(k, 59, 63, 5.5, Tone(0xff4f8b), seed: 20)
            }
            k.marker(arc(30, 50, 36, 60, dip: -2), .white, partyW(k), seed: 8)
            partyPart(k, ell(50, 27, 20, 6), saucer.dim(0.82), ink, seed: 9)
            partyPart(k, ell(50, 35, 43, 10), saucer, ink, seed: 11)
            if f.variant % 5 == 4 {
                k.dot(26, 39, 2.6, 2, ink, seed: 21)
                k.dot(74, 39, 2.6, 2, ink, seed: 22)
            }
            let xs: [CGFloat] = [18, 34, 50, 66, 82]
            for (i, x) in xs.enumerated() {
                let lit = lightsOn && (allOn || (i + f.frameIndex / 2) % 3 == 0)
                let y: CGFloat = 33 - abs(x - 50) * 0.08
                k.dot(x, y, 3.4, 3, lit ? Tone(0xfff06a) : saucer.dim(0.72), seed: 40 + i)
            }
            k.mouth(50 + faceX, 48.5, 6.5, seed: 50)
            k.marks(78, 66, 12, ink: ink, seed: 60)
        }
    }
}

