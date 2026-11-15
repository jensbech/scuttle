import Foundation
import CoreGraphics
import ScuttleCore

extension DoodleArt {
    static func ghost(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0x9a7bff), Tone(0xf6f4ff)), (Tone(0x22b866), Tone(0xe6fff0)), (Tone(0xff8a2a), Tone(0xfff3d6)),
            (Tone(0xff4f8b), Tone(0xfff0f6)), (Tone(0x3f8cff), Tone(0xe8f3ff)),
        ]
        let (mk, body) = f.pick(looks)
        let t = f.t
        var rot: CGFloat = 0.05, sx: CGFloat = 1, sy: CGFloat = 1 + 0.02 * f.swing2
        var trail: CGFloat = 0, ripple: CGFloat = 1.6
        var la = [25, 42, 15, 49 + 3 * f.swing, 10, 54 + 5 * f.swing]
        var ra = [75, 42, 86, 47 - 3 * f.swing, 91, 45 - 5 * f.swing]
        var faceX: CGFloat = 0
        switch f.mood {
        case .calm:
            ra[5] += 7 * max(0, f.twitch)
        case .sleepy:
            sx = 1.04
            sy = 0.94
            ripple = 0.5
            la = [26, 38, 20, 30, 17, 23]
            ra = [74, 38, 80, 30, 83, 23]
        case .startled:
            sx = 0.95
            sy = 1.07
            ripple = 0.6
            la = [26, 50, 19, 62, 16, 76 + 2 * f.swing2]
            ra = [74, 50, 81, 62, 84, 76 - 2 * f.swing2]
        case .fleeing:
            trail = 8
            ripple = 2.6
            rot = 0.0
            la = [26, 44, 15, 46 + 3 * f.swing, 6, 42 + 5 * f.swing]
            ra = [74, 40, 82, 33, 78, 25]
            faceX = 3
        case .dizzy:
            rot = 0.05 + 0.13 * sin(t)
            la = [25, 42, 16, 48 + 6 * f.swing, 11, 40 - 4 * f.swing]
            ra = [75, 42, 84, 36 - 6 * f.swing, 90, 44 + 4 * f.swing]
        }
        k.with(about(50, 40, rot: rot, sx: sx, sy: sy)) {
            k.stick(la, mk, seed: 30, w: festivePen(k))
            k.stick(ra, mk, seed: 31, w: festivePen(k))
            festivePaint(k, doodleGhostBody(trail: trail, ripple: ripple, t: t), body, mk, seed: 32)
            doodleGhostHat(f, k, mk)
            k.face(50 + faceX, 57, seed: 33)
            k.marks(f.mood == .fleeing ? 24 : 76, 84, 13, ink: mk, seed: 40)
        }
    }

    private static func doodleGhostBody(trail: CGFloat, ripple: CGFloat, t: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.move(to: pt(25 - trail, 16))
        p.addCurve(to: pt(25, 57), control1: pt(25 - trail * 0.7, 30), control2: pt(25, 45))
        p.addArc(center: pt(50, 57), radius: 25, startAngle: .pi, endAngle: 0, clockwise: true)
        p.addCurve(to: pt(75 - trail, 16), control1: pt(75, 45), control2: pt(75 - trail * 0.7, 30))
        let teeth = P([69, 7, 62.5, 16, 56, 7, 50, 16, 44, 7, 37.5, 16, 31, 7, 25, 16])
        for (i, q) in teeth.enumerated() {
            let tip = i % 2 == 0
            let y = q.y + (tip ? ripple * sin(t + CGFloat(i) * 0.9) - trail * 0.25 : 0)
            p.addLine(to: pt(q.x - trail * (tip ? 1.25 : 1), y))
        }
        p.closeSubpath()
        return p
    }

    private static func doodleGhostHat(_ f: FigureFrame, _ k: DoodleKit, _ mk: Tone) {
        switch f.variant % 5 {
        case 1:
            for i in 0..<5 {
                let a = CGFloat(i) / 5 * 2 * .pi + 0.4
                festivePaint(k, circ(68 + cos(a) * 4.2, 78 + sin(a) * 4.2, 3.2), Tone(0xff7ab0), Tone(0xff3d8b), seed: 50 + i, w: festiveThin(k), hatch: false)
            }
            k.dot(68, 78, 2.6, 2.6, Tone(0xffc21a), seed: 56)
        case 2:
            let cone = smooth([37, 82, 63, 82, 57, 94, 66, 106, 49, 96], t: 0.5)
            festivePaint(k, cone, Tone(0x6a3fd0), Tone(0xb07aff), seed: 52, hatch: false)
            festivePaint(k, ell(50, 82, 21, 4), Tone(0x6a3fd0), Tone(0xb07aff), seed: 53, hatch: false)
        case 3:
            let pink = Tone(0xff4f8b)
            festivePaint(k, smooth([50, 84, 40, 90, 40, 78], t: 0.4), pink, Tone(0xe0186a), seed: 54, w: festiveThin(k), hatch: false)
            festivePaint(k, smooth([50, 84, 60, 90, 60, 78], t: 0.4), pink, Tone(0xe0186a), seed: 55, w: festiveThin(k), hatch: false)
            k.dot(50, 84, 2.4, 2.4, pink, seed: 56)
        case 4:
            let cone = poly([40, 81, 60, 81, 51, 103])
            festivePaint(k, cone, Tone(0x2fd6c0), Tone(0x14a894), seed: 57, hatch: false)
            for y in [86, 93] as [CGFloat] {
                k.marker(line(44 + (y - 81) * 0.35, y, 57 - (y - 81) * 0.4, y + 1), Tone(0xff4f8b), festiveThin(k), seed: Int(y))
            }
            k.dot(51, 104, 3, 3, Tone(0xffc21a), seed: 58)
        default:
            break
        }
    }

    private static func festivePen(_ k: DoodleKit) -> CGFloat { k.width(3.4, minPt: 1.3) }

    private static func festiveThin(_ k: DoodleKit) -> CGFloat { k.width(2.4, minPt: 1.0) }

    private static func festivePaint(_ k: DoodleKit, _ shape: CGPath, _ fill: Tone, _ ink: Tone, seed: Int, w: CGFloat? = nil, hatch: Bool = true) {
        let sd = k.seed(seed)
        var r = Noise(sd &+ 577)
        let ox = r.range(-1.3, 1.3), oy = r.range(-1.3, 1.3)
        let region = CGMutablePath()
        for (i, sub) in DoodleKit.flatten(shape, step: 2.2).enumerated() where sub.1 {
            let wob = DoodleKit.wobble(sub.0, closed: true, seed: sd &+ i &* 13, amp: 1.2)
            region.addPath(DoodleKit.curve(wob, closed: true), transform: CGAffineTransform(translationX: ox, y: oy))
        }
        k.fill(region, fill)
        let bb = shape.boundingBoxOfPath
        if hatch, bb.width > 9, bb.height > 9 {
            let gap = max(6.5, 2.4 * k.pt)
            let lw = max(1.6, 0.8 * k.pt)
            let ang = r.range(0.95, 1.2)
            let dx = cos(ang), dy = sin(ang)
            let diag = hypot(bb.width, bb.height) + 6
            let lines = CGMutablePath()
            var off: CGFloat = -diag / 2 + r.range(0, gap)
            while off < diag / 2 {
                let cx = bb.midX + dy * off, cy = bb.midY - dx * off
                let half = diag / 2
                lines.move(to: CGPoint(x: cx - dx * half, y: cy - dy * half))
                lines.addLine(to: CGPoint(x: cx + dx * half + r.range(-1.5, 1.5), y: cy + dy * half))
                off += gap * r.range(0.85, 1.25)
            }
            let shade = fill.luma > 0.8 ? fill.mix(ink, 0.18) : fill.dim(0.82)
            k.clip(region) { k.stroke(lines, shade, lw) }
        }
        k.marker(shape, ink, w ?? festivePen(k), seed: seed)
    }

    private static func festiveCapsule(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat, _ r: CGFloat) -> CGPath {
        line(x0, y0, x1, y1).copy(strokingWithWidth: 2 * r, lineCap: .round, lineJoin: .round, miterLimit: 2)
    }

    private static func festiveTube(_ a: [CGFloat], _ r: CGFloat) -> CGPath {
        smooth(a, closed: false).copy(strokingWithWidth: 2 * r, lineCap: .round, lineJoin: .round, miterLimit: 2)
    }

    private static func festiveGait(_ f: FigureFrame, _ which: Int, reach: CGFloat, lift: CGFloat) -> (CGFloat, CGFloat) {
        let s: CGFloat = which == 0 ? 1 : -1
        return (s * f.sway * reach, max(0, -s * f.swing) * lift)
    }

    private static func festiveBow(_ k: DoodleKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ fill: Tone, _ ink: Tone, seed: Int) {
        let p = CGMutablePath()
        p.addPath(smooth([x, y, x - 8 * s, y + 6 * s, x - 8 * s, y - 6 * s], t: 0.5))
        p.addPath(smooth([x, y, x + 8 * s, y + 6 * s, x + 8 * s, y - 6 * s], t: 0.5))
        festivePaint(k, p, fill, ink, seed: seed, w: festiveThin(k), hatch: false)
        k.dot(x, y, 2.6 * s, 2.6 * s, ink, seed: seed + 1)
    }

    private static func festiveWitchHat(_ k: DoodleKit, _ cx: CGFloat, _ by: CGFloat, _ s: CGFloat, tip: CGFloat = 0, seed: Int) {
        let fill = Tone(0x6a3fd0), ink = Tone(0xb07aff)
        let cone = smooth([cx - 9 * s, by + 1, cx + 9 * s, by + 1, cx + 4 * s, by + 12 * s, cx + (13 + tip) * s, by + 21 * s, cx - 2 * s, by + 14 * s], t: 0.5)
        festivePaint(k, cone, fill, ink, seed: seed, hatch: false)
        k.marker(line(cx - 8 * s, by + 4.5 * s, cx + 7.5 * s, by + 4.5 * s), Tone(0xff8a1a), festiveThin(k), seed: seed + 1)
        festivePaint(k, ell(cx, by, 15 * s, 3.4 * s), fill, ink, seed: seed + 2, hatch: false)
    }

    private static func festivePartyHat(_ k: DoodleKit, _ cx: CGFloat, _ by: CGFloat, _ s: CGFloat, _ fill: Tone, _ ink: Tone, seed: Int) {
        festivePaint(k, poly([cx - 8 * s, by, cx + 8 * s, by, cx + 1 * s, by + 18 * s]), fill, ink, seed: seed, hatch: false)
        k.marker(line(cx - 4.5 * s, by + 7 * s, cx + 5 * s, by + 8 * s), Tone(0xff4f8b), festiveThin(k), seed: seed + 1)
        k.dot(cx + 1 * s, by + 19 * s, 3.2 * s, 3.2 * s, Tone(0xffc21a), seed: seed + 2)
    }

    private static func festiveCandyCane(_ k: DoodleKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, seed: Int) {
        let p = smooth([x, y, x, y + 16 * s, x + 2.5 * s, y + 20 * s, x + 6.5 * s, y + 19.5 * s, x + 8 * s, y + 15 * s], closed: false, t: 0.8)
        k.marker(p, Tone(0xff2f4f), k.width(4.2 * s, minPt: 1.5), seed: seed)
        k.marker(p, .white, k.width(1.5 * s, minPt: 0.5), seed: seed + 1)
    }

    private static func festiveMiniGift(_ k: DoodleKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ fill: Tone, _ ink: Tone, seed: Int) {
        festivePaint(k, rrect(x - 7 * s, y - 6 * s, 14 * s, 12 * s, 2), fill, ink, seed: seed, w: festiveThin(k), hatch: false)
        k.marker(line(x, y - 6 * s, x, y + 6 * s), Tone(0xffc21a), festiveThin(k), seed: seed + 1)
        festiveBow(k, x, y + 6.5 * s, 0.55 * s, Tone(0xffc21a), Tone(0xf06a10), seed: seed + 2)
    }

    static func bat(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0x8a66f0), Tone(0x6a45d8), Tone(0xff3d8b)), (Tone(0x3fcf8a), Tone(0x22ad6c), Tone(0x6a32d0)),
            (Tone(0xff9030), Tone(0xf26d12), Tone(0x7a2fd0)), (Tone(0xff7ab8), Tone(0xff4f9e), Tone(0x8a2fe0)),
            (Tone(0x4f8cff), Tone(0x2f68e8), Tone(0xff6a1a)),
        ]
        let (body, wingTone, ink) = f.pick(looks)
        var a: CGFloat = 0.12 + 0.5 * f.swing
        var rot: CGFloat = 0, sx: CGFloat = 1, sy: CGFloat = 1, fx: CGFloat = 0
        var ear: CGFloat = f.mood == .calm ? 2.5 * f.twitch : 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            a = -0.95 + 0.06 * f.swing
            sx = 1.05
            sy = 0.93
            ear = -2
        case .startled:
            a = 0.8 + 0.12 * f.swing2
            sx = 0.94
            sy = 1.07
            ear = 2
        case .fleeing:
            a = 0.05 + 0.7 * f.swing
            rot = -0.16
            fx = 3
            ear = -3
        case .dizzy:
            a = 0.15 + 0.35 * f.swing
            rot = 0.13 * sin(f.t)
        }
        k.with(about(50, 48, rot: rot, sx: sx, sy: sy)) {
            let rw = xf(festiveBatWing(), about(63, 52, rot: a))
            festivePaint(k, mirror(rw), wingTone, ink, seed: 1)
            festivePaint(k, rw, wingTone, ink, seed: 2)
            k.stick([45, 34, 44, 27], ink, seed: 3, w: festiveThin(k))
            k.stick([55, 34, 56, 27], ink, seed: 4, w: festiveThin(k))
            let head = uni([ell(50, 47, 17.5, 16.5), poly([35, 52, 36 + ear * 0.5, 73 + ear, 47, 60]), poly([53, 60, 63 + ear, 74 + ear, 65, 52])])
            festivePaint(k, head, body, ink, seed: 5)
            k.face(52 + fx, 48, spread: 6.5, rx: 3.3, ry: 4.4, seed: 30)
            if f.mood != .startled && f.mood != .fleeing {
                let fang = poly([54 + fx, 38.5, 58.5 + fx, 38.5, 56.5 + fx, 33.5])
                k.fill(fang, .white)
                k.marker(fang, k.felt, k.width(1.3, minPt: 0.5), seed: 6)
            }
            festiveBatAccessory(f, k, a)
            k.marks(f.mood == .fleeing ? 28 : 70, 72, 13, ink: ink, seed: 40)
        }
    }

    private static func festiveBatWing() -> CGPath {
        let p = CGMutablePath()
        p.move(to: pt(58, 58))
        p.addQuadCurve(to: pt(99, 70), control: pt(80, 78))
        p.addQuadCurve(to: pt(91, 49), control: pt(89, 62))
        p.addQuadCurve(to: pt(78, 47), control: pt(85, 55))
        p.addQuadCurve(to: pt(62, 40), control: pt(69, 50))
        p.closeSubpath()
        return p
    }

    private static func festiveBatAccessory(_ f: FigureFrame, _ k: DoodleKit, _ a: CGFloat) {
        switch f.variant % 5 {
        case 1:
            festivePaint(k, uni([poly([51, 32, 42, 37, 42, 27]), poly([51, 32, 60, 37, 60, 27])]), Tone(0xff8a1a), Tone(0xe0401a), seed: 50, w: festiveThin(k), hatch: false)
            k.dot(51, 32, 2.4, 2.4, Tone(0xe0401a), seed: 51)
        case 2:
            festiveWitchHat(k, 50, 61, 0.95, tip: 2 * f.twitch, seed: 52)
        case 3:
            festiveBow(k, 62, 66, 0.95, Tone(0xffd23a), Tone(0xf06a10), seed: 55)
        case 4:
            let t = about(63, 52, rot: a)
            for (i, q) in P([84, 63, 74, 58]).enumerated() {
                let r = q.applying(t)
                k.dot(r.x, r.y, 3, 3, Tone(0xffd23a), seed: 57 + i)
                k.dot(100 - r.x, r.y, 3, 3, Tone(0xffd23a), seed: 59 + i)
            }
        default:
            break
        }
    }

    static func pumpkin(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xff8a1a), Tone(0xe0361a)), (Tone(0xfff0dc), Tone(0xff6a1a)), (Tone(0xff7038), Tone(0xc8201a)),
            (Tone(0xffc21a), Tone(0xf0600f)), (Tone(0x7fd65a), Tone(0x16954a)),
        ]
        let (fill, ink) = f.pick(looks)
        var sx: CGFloat = 1 + 0.08 * f.squat - 0.04 * f.stretch
        var sy: CGFloat = 1 - 0.16 * f.squat + 0.1 * f.stretch
        var rot: CGFloat = 0, fx: CGFloat = 0
        let tuck: CGFloat = f.airborne ? (1 - abs(f.stretch)) * 4 : 0
        var la: [CGFloat] = [20, 36, 11, 41, 6, 47 + 3 * f.swing]
        var ra: [CGFloat] = [80, 36, 89, 41, 94, 47 - 3 * f.swing + 7 * max(0, f.twitch)]
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sx *= 1.05
            sy *= 0.92
            la = [21, 30, 16, 22, 15, 15]
            ra = [79, 30, 84, 22, 85, 15]
        case .startled:
            sx *= 0.95
            sy *= 1.07
            la = [20, 42, 13, 53, 10, 66]
            ra = [80, 42, 87, 53, 90, 66]
        case .fleeing:
            rot = -0.06
            fx = 3
            la = [20, 36, 10, 35, 2, 40 + 4 * f.swing]
            ra = [80, 38, 86, 30, 80, 23 + 3 * f.swing]
        case .dizzy:
            rot = 0.12 * sin(f.t)
            la = [20, 36, 12, 44, 8, 38 + 5 * f.swing]
            ra = [80, 36, 88, 30, 94, 36 - 5 * f.swing]
        }
        k.with(about(50, 5, rot: rot, sx: sx, sy: sy)) {
            k.stick([42, 14, 40, 5 + tuck], ink, seed: 1, w: festivePen(k))
            k.stick([58, 14, 60, 5 + tuck], ink, seed: 2, w: festivePen(k))
            k.stick(la, ink, seed: 3, w: festivePen(k))
            k.stick(ra, ink, seed: 4, w: festivePen(k))
            let gourd = uni([ell(50, 36, 19, 26), ell(35, 35, 16.5, 24), ell(65, 35, 16.5, 24)])
            festivePaint(k, gourd, fill, ink, seed: 5)
            k.marker(smooth([41, 57, 37, 36, 41, 14], closed: false), ink.alpha(0.75), festiveThin(k), seed: 6)
            k.marker(smooth([59, 57, 63, 36, 59, 14], closed: false), ink.alpha(0.75), festiveThin(k), seed: 7)
            let stemFill = f.variant % 5 == 4 ? Tone(0xb8743e) : Tone(0x45c24a)
            let stemInk = f.variant % 5 == 4 ? Tone(0x8a4a1a) : Tone(0x14904a)
            festivePaint(k, poly([45, 58, 54, 58, 57, 71, 50, 72]), stemFill, stemInk, seed: 8, hatch: false)
            k.face(53 + fx, 38, spread: 9, rx: 3.6, ry: 4.8, seed: 30)
            if f.mood == .calm || f.mood == .dizzy {
                k.fill(poly([50.5 + fx, 32, 55.5 + fx, 32, 53 + fx, 28.5]), k.felt)
            }
            festivePumpkinAccessory(f, k)
            k.marks(f.mood == .fleeing ? 22 : 76, 66, 13, ink: ink, seed: 40)
        }
    }

    private static func festivePumpkinAccessory(_ f: FigureFrame, _ k: DoodleKit) {
        let green = Tone(0x45c24a), greenInk = Tone(0x14904a)
        switch f.variant % 5 {
        case 0:
            festivePaint(k, ell(63, 66, 8, 4, 0.45), green, greenInk, seed: 50, w: festiveThin(k), hatch: false)
            k.marker(spiral(41, 66, 5, turns: 1.3, spin: -1, start: 0), greenInk, festiveThin(k), seed: 51)
        case 1:
            festiveBow(k, 50, 62, 1.05, Tone(0xff5f9e), Tone(0xe0186a), seed: 52)
        case 2:
            festiveWitchHat(k, 50, 66, 1.05, tip: 2 * f.twitch, seed: 54)
        case 3:
            for (i, x) in ([36, 50, 64] as [CGFloat]).enumerated() {
                let y: CGFloat = i == 1 ? 72 : 66
                k.dot(x, y, 4.2, 4.2, Tone(0xff4f8b), seed: 57 + i)
                k.dot(x, y, 1.8, 1.8, Tone(0xfff3b0), seed: 60 + i)
            }
        case 4:
            festivePaint(k, uni([poly([50, 16, 41, 21, 41, 11]), poly([50, 16, 59, 21, 59, 11])]), Tone(0xff8a1a), Tone(0xe0401a), seed: 63, w: festiveThin(k), hatch: false)
            k.dot(50, 16, 2.4, 2.4, Tone(0xe0401a), seed: 64)
        default:
            break
        }
    }

    static func spider(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0x7f58e8), Tone(0xff4f9a)), (Tone(0xff9a2a), Tone(0x7a3fd0)), (Tone(0x4f8cff), Tone(0xff6a1a)),
            (Tone(0xff7ab8), Tone(0x9a3fe0)), (Tone(0x34c98a), Tone(0xff4f6a)),
        ]
        let (body, ink) = f.pick(looks)
        let e = f.energy
        var cy: CGFloat = 31 + 1.2 * f.swing2 * e
        var rot: CGFloat = 0, fx: CGFloat = 0
        var reach: CGFloat = 3 * e, lift: CGFloat = 5 * e, back: CGFloat = 0
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            cy = 22
            reach = 0
            lift = 0
        case .startled:
            cy = 38
        case .fleeing:
            reach = 6
            lift = 7
            back = 5
            fx = 3
        case .dizzy:
            rot = 0.12 * sin(f.t)
        }
        k.with(about(50, 5, rot: rot)) {
            var sd = 1
            for side in [-1, 1] as [CGFloat] {
                for i in 0..<4 {
                    let fi = CGFloat(i)
                    let ph = f.t + fi * .pi * 0.5 + (side > 0 ? .pi : 0)
                    let up = max(0, sin(ph)) * lift
                    let dx = cos(ph) * reach - back
                    let ang: CGFloat = 1.0 - fi * 0.42
                    let hx = 50 + side * 10, hy = cy + 2 - fi * 2
                    var kx = 50 + side * cos(ang) * 30, ky = cy + sin(ang) * 26 + up * 0.4
                    var tx = kx + side * (4 + fi * 2) + dx, ty = 5 + up
                    if f.mood == .sleepy {
                        kx = 50 + side * (22 + fi * 3)
                        ky = cy + 4 - fi * 2
                        tx = 50 + side * (27 + fi * 4)
                        ty = 5
                    } else if f.mood == .startled && i < 2 {
                        tx = kx + side * 9
                        ty = ky + 13 + 2 * f.swing2 * side
                    }
                    k.marker(poly([hx, hy, kx, ky, tx, ty], closed: false), ink, festivePen(k), seed: sd)
                    if f.variant % 5 == 1 && !(f.mood == .startled && i < 2) {
                        k.dot(tx + side * 1.5, ty + 0.5, 3, 2.4, Tone(0x3fbfff), seed: 20 + sd)
                    }
                    sd += 1
                }
            }
            festivePaint(k, ell(50, cy, 21, 19), body, ink, seed: 10)
            k.marker(line(45, cy + 18, 42, cy + 24), ink, festiveThin(k), seed: 11)
            k.marker(line(51, cy + 19, 52, cy + 26), ink, festiveThin(k), seed: 12)
            k.face(52 + fx, cy + 2, spread: 7.5, rx: 3.8, ry: 5, seed: 30)
            switch f.variant % 5 {
            case 2:
                festiveWitchHat(k, 53, cy + 17, 0.9, tip: 2 * f.twitch, seed: 50)
            case 3:
                festiveBow(k, 64, cy + 15, 0.95, Tone(0xffd23a), Tone(0xf06a10), seed: 54)
            case 4:
                festivePartyHat(k, 55, cy + 17, 0.95, Tone(0xffd23a), Tone(0xf06a10), seed: 56)
            default:
                break
            }
            k.marks(f.mood == .fleeing ? 26 : 74, cy + 22, 12, ink: ink, seed: 40)
        }
    }

    static func gingerbread(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0xc8783a), Tone(0xe2501a), .white), (Tone(0xc8783a), Tone(0xe2501a), .white), (Tone(0xe09a50), Tone(0xe0441a), Tone(0xff7ab8)),
            (Tone(0x9a5a32), Tone(0xff7a2a), .white), (Tone(0xc8783a), Tone(0xe2501a), .white),
        ]
        let (dough, ink, icing) = f.pick(looks)
        let e = f.energy
        let bob: CGFloat = f.bounce * 1.5 * e
        var rot: CGFloat = 0, sy: CGFloat = 1, fx: CGFloat = 0
        let a = festiveGait(f, 0, reach: 6 * e, lift: 4 * e)
        let b = festiveGait(f, 1, reach: 6 * e, lift: 4 * e)
        var feet: [CGFloat] = [44 + a.0, 9 + a.1, 56 + b.0, 9 + b.1]
        var hands: [CGFloat] = [24, 40 - 4 * f.swing * e, 76, 40 + 4 * f.swing * e + 10 * max(0, f.twitch)]
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sy = 0.95
            feet = [45, 9, 55, 9]
            hands = [30, 30, 70, 30]
        case .startled:
            sy = 1.05
            feet = [38, 9, 62, 9]
            hands = [24, 64, 76, 64]
        case .fleeing:
            fx = 3
            hands = [26 - 6 * f.swing, 46 + 6 * f.swing, 74 + 6 * f.swing, 46 - 6 * f.swing]
        case .dizzy:
            rot = 0.12 * sin(f.t)
            hands = [24, 48 + 6 * f.swing, 76, 48 - 6 * f.swing]
        }
        k.with(about(50, 5, rot: rot, sy: sy)) {
            k.with(CGAffineTransform(translationX: 0, y: bob)) {
                let head = circ(51, 71, 15)
                let torso = rrect(36, 22, 28, 33, 13)
                let cookie = uni([head, torso, festiveCapsule(38, 46, hands[0], hands[1], 6), festiveCapsule(62, 46, hands[2], hands[3], 6),
                                  festiveCapsule(44, 26, feet[0], feet[1], 6.5), festiveCapsule(56, 26, feet[2], feet[3], 6.5)])
                festivePaint(k, cookie, dough, ink, seed: 1)
                festiveGingerIcing(k, 38, 46, hands[0], hands[1], icing, seed: 2)
                festiveGingerIcing(k, 62, 46, hands[2], hands[3], icing, seed: 3)
                festiveGingerIcing(k, 44, 26, feet[0], feet[1], icing, seed: 4)
                festiveGingerIcing(k, 56, 26, feet[2], feet[3], icing, seed: 5)
                let buttons: [Tone] = f.variant % 5 == 3 ? [Tone(0xff4f8b), Tone(0xff4f8b)] : [Tone(0xff3048), Tone(0x2fcf5a)]
                k.dot(50, 44, 3, 3, buttons[0], seed: 6)
                k.dot(50, 34, 3, 3, buttons[1], seed: 7)
                k.face(53 + fx, 72, spread: 6, rx: 3, ry: 4, seed: 30)
                festiveGingerAccessory(f, k, hands)
                k.marks(f.mood == .fleeing ? 30 : 70, 86, 12, ink: ink, seed: 40)
            }
        }
    }

    private static func festiveGingerIcing(_ k: DoodleKit, _ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat, _ tone: Tone, seed: Int) {
        let l = max(0.001, hypot(x1 - x0, y1 - y0))
        let ux = (x1 - x0) / l, uy = (y1 - y0) / l
        let cx = x1 - ux * 4.5, cy = y1 - uy * 4.5
        k.marker(zigzag(cx + uy * 5, cy - ux * 5, cx - uy * 5, cy + ux * 5, teeth: 2, amp: 1.6), tone, festiveThin(k), seed: seed)
    }

    private static func festiveGingerAccessory(_ f: FigureFrame, _ k: DoodleKit, _ hands: [CGFloat]) {
        switch f.variant % 5 {
        case 1:
            let red = Tone(0x2fcf5a), redInk = Tone(0x0f8a3a)
            festivePaint(k, rrect(37, 52, 28, 7, 3.5), red, redInk, seed: 50, w: festiveThin(k), hatch: false)
            festivePaint(k, poly([40, 55, 46, 55, 43, 41, 36, 43]), red, redInk, seed: 51, w: festiveThin(k), hatch: false)
        case 2:
            festiveBow(k, 60, 85, 1, Tone(0xff7ab8), Tone(0xe0186a), seed: 52)
        case 3:
            festivePaint(k, uni([poly([51, 54, 43, 58, 43, 50]), poly([51, 54, 59, 58, 59, 50])]), Tone(0xff3048), Tone(0xb8102a), seed: 54, w: festiveThin(k), hatch: false)
        case 4:
            festiveCandyCane(k, hands[2] + 1, hands[3] - 6, 1, seed: 56)
        default:
            break
        }
    }

    static func present(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone, Tone, Tone)] = [
            (Tone(0xff3b3b), Tone(0xb80f30), Tone(0xffc21a), Tone(0xf06a10)),
            (Tone(0x2fc46a), Tone(0x0b8a3a), Tone(0xff3b5a), Tone(0xc8102a)),
            (Tone(0x4f8cff), Tone(0x1f4fd0), Tone(0xff7ab0), Tone(0xe02f7a)),
            (Tone(0xa05cf0), Tone(0x6a2fd0), Tone(0x6ee07a), Tone(0x1f9a4a)),
            (Tone(0xffc21a), Tone(0xf06010), Tone(0x3f8cff), Tone(0x1f55d8)),
        ]
        let (box, boxInk, rib, ribInk) = f.pick(looks)
        var sx: CGFloat = 1 + 0.08 * f.squat - 0.04 * f.stretch
        var sy: CGFloat = 1 - 0.16 * f.squat + 0.1 * f.stretch
        var rot: CGFloat = 0, fx: CGFloat = 0
        let tuck: CGFloat = f.airborne ? (1 - abs(f.stretch)) * 4 : 0
        var lidUp: CGFloat = 3 * max(0, -f.stretch), lidRot: CGFloat = 0.05 * f.stretch
        var la: [CGFloat] = [25, 32, 15, 36, 9, 42 + 3 * f.swing]
        var ra: [CGFloat] = [75, 32, 85, 36, 91, 42 - 3 * f.swing + 7 * max(0, f.twitch)]
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            sx *= 1.04
            sy *= 0.93
            lidUp = -1
            lidRot = -0.06
            la = [25, 28, 19, 21, 18, 15]
            ra = [75, 28, 81, 21, 82, 15]
        case .startled:
            sx *= 0.96
            sy *= 1.04
            lidUp = 9 + 1.5 * f.swing2
            lidRot = 0.28
            la = [25, 36, 17, 47, 13, 58]
            ra = [75, 36, 83, 47, 87, 58]
        case .fleeing:
            fx = 3
            rot = -0.05
            lidUp = 2
            lidRot = 0.18 + 0.05 * f.swing
            la = [25, 32, 15, 30, 7, 35 + 4 * f.swing]
            ra = [75, 34, 81, 26, 75, 20 + 3 * f.swing]
        case .dizzy:
            rot = 0.12 * sin(f.t)
            lidRot = -0.15 * sin(f.t)
            la = [25, 32, 16, 40, 11, 34 + 5 * f.swing]
            ra = [75, 32, 84, 26, 90, 32 - 5 * f.swing]
        }
        k.with(about(50, 5, rot: rot, sx: sx, sy: sy)) {
            k.stick([40, 14, 39, 5 + tuck], boxInk, seed: 1, w: festivePen(k))
            k.stick([60, 14, 61, 5 + tuck], boxInk, seed: 2, w: festivePen(k))
            k.stick(la, boxInk, seed: 3, w: festivePen(k))
            k.stick(ra, boxInk, seed: 4, w: festivePen(k))
            festivePaint(k, rrect(25, 13, 50, 35, 3), box, boxInk, seed: 5)
            festivePresentPattern(f, k)
            festivePaint(k, rrect(33, 13, 9, 35, 1), rib, ribInk, seed: 6, w: festiveThin(k), hatch: false)
            k.face(60 + fx, 31, spread: 7, rx: 3.4, ry: 4.6, seed: 30)
            k.with(about(30, 51, rot: lidRot).concatenating(CGAffineTransform(translationX: 0, y: lidUp))) {
                festivePaint(k, rrect(21, 45, 58, 12, 3), box, boxInk, seed: 7, hatch: false)
                festivePaint(k, rrect(32, 45, 11, 12, 1), rib, ribInk, seed: 8, w: festiveThin(k), hatch: false)
                let loops = CGMutablePath()
                loops.addPath(smooth([37.5, 57, 26, 66, 29, 57], t: 0.5))
                loops.addPath(smooth([37.5, 57, 49, 66, 46, 57], t: 0.5))
                festivePaint(k, loops, rib, ribInk, seed: 9, w: festiveThin(k), hatch: false)
                k.dot(37.5, 57.5, 3, 2.6, ribInk, seed: 10)
            }
            k.marks(f.mood == .fleeing ? 18 : 76, 70, 13, ink: boxInk, seed: 40)
        }
    }

    private static func festivePresentPattern(_ f: FigureFrame, _ k: DoodleKit) {
        switch f.variant % 5 {
        case 2:
            for (i, q) in P([50, 42, 70, 43, 29, 21, 50, 19]).enumerated() {
                k.dot(q.x, q.y, 2.4, 2.4, .white, seed: 50 + i)
            }
        case 3:
            k.marker(line(46, 46, 52, 15), Tone(0xffd23a), festiveThin(k), seed: 55)
            k.marker(line(70, 46, 74, 30), Tone(0xffd23a), festiveThin(k), seed: 56)
        case 4:
            k.marker(smooth([75, 44, 82, 38, 86, 30], closed: false), Tone(0x1f55d8), festiveThin(k), seed: 57)
            festivePaint(k, rrect(81, 21, 10, 9, 2), .white, Tone(0xff4f8b), seed: 58, w: festiveThin(k), hatch: false)
        default:
            break
        }
    }

    static func elf(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0x34c46a), Tone(0x0f8f42), Tone(0xff3048)), (Tone(0xff4a4a), Tone(0xc8142a), Tone(0x2fcf5a)),
            (Tone(0x4f8cff), Tone(0x1f50d8), Tone(0xffc21a)), (Tone(0xa66cf5), Tone(0x6f30d6), Tone(0x3fd0c0)),
            (Tone(0x2fd0c0), Tone(0x0f9a8a), Tone(0xff4f8b)),
        ]
        let (suit, suitInk, trim) = f.pick(looks)
        let skin = Tone(0xffc9a0), skinInk = Tone(0xff6a3a)
        let e = f.energy
        let bob: CGFloat = f.bounce * 1.5 * e
        var rot: CGFloat = 0, sy: CGFloat = 1, fx: CGFloat = 0
        let a = festiveGait(f, 0, reach: 6 * e, lift: 4 * e)
        let b = festiveGait(f, 1, reach: 6 * e, lift: 4 * e)
        var feet: [CGFloat] = [45 + a.0, 7 + a.1, 55 + b.0, 7 + b.1]
        var la: [CGFloat] = [41, 42, 33, 36 - 3 * f.swing * e, 28, 31 - 4 * f.swing * e]
        var ra: [CGFloat] = [59, 42, 67, 36 + 3 * f.swing * e, 72, 31 + 4 * f.swing * e]
        var tip: [CGFloat] = [28, 84 + 2 * f.twitch]
        switch f.mood {
        case .calm:
            if f.twitch > 0 { ra = [59, 42, 69, 47, 74, 56] }
        case .sleepy:
            sy = 0.95
            feet = [46, 7, 54, 7]
            la = [41, 42, 37, 34, 36, 27]
            ra = [59, 42, 63, 34, 64, 27]
            tip = [33, 74]
        case .startled:
            sy = 1.05
            feet = [40, 7, 60, 7]
            la = [41, 42, 33, 51, 29, 60]
            ra = [59, 42, 67, 51, 71, 60]
            tip = [36, 98]
        case .fleeing:
            fx = 3
            la = [41, 42, 33, 38 - 6 * f.swing, 26, 40 - 8 * f.swing]
            ra = [59, 42, 67, 38 + 6 * f.swing, 72, 40 + 8 * f.swing]
            tip = [18, 80 + 2 * f.swing]
        case .dizzy:
            rot = 0.12 * sin(f.t)
            la = [41, 42, 33, 46, 28, 40 + 5 * f.swing]
            ra = [59, 42, 67, 46, 72, 40 - 5 * f.swing]
            tip = [30 + 4 * f.swing, 84]
        }
        k.with(about(50, 5, rot: rot, sy: sy)) {
            k.with(CGAffineTransform(translationX: 0, y: bob)) {
                k.stick([45, 22, feet[0], feet[1] + 2], trim, seed: 1, w: festivePen(k))
                k.stick([55, 22, feet[2], feet[3] + 2], trim, seed: 2, w: festivePen(k))
                festivePaint(k, ell(feet[0] + 3, feet[1], 6, 3.4), suit, suitInk, seed: 3, w: festiveThin(k), hatch: false)
                festivePaint(k, ell(feet[2] + 3, feet[3], 6, 3.4), suit, suitInk, seed: 4, w: festiveThin(k), hatch: false)
                k.stick(la, suitInk, seed: 5, w: festivePen(k))
                k.stick(ra, suitInk, seed: 6, w: festivePen(k))
                k.dot(la[4], la[5], 3, 3, skin, seed: 7)
                k.dot(ra[4], ra[5], 3, 3, skin, seed: 8)
                let tunic = poly([41, 46, 59, 46, 66, 19, 60, 23, 55, 18, 50, 23, 45, 18, 40, 23, 34, 19])
                festivePaint(k, tunic, suit, suitInk, seed: 9)
                k.marker(line(38, 30, 62, 30), Tone(0x3a2618), festiveThin(k), seed: 10)
                k.dot(50, 30, 2.6, 2.4, Tone(0xffc21a), seed: 11)
                let ears = CGMutablePath()
                ears.addPath(poly([63, 61, 75, 67, 64, 53]))
                ears.addPath(poly([41, 61, 29, 67, 40, 53]))
                festivePaint(k, ears, skin, skinInk, seed: 12, w: festiveThin(k), hatch: false)
                festivePaint(k, circ(52, 57, 13.5), skin, skinInk, seed: 13, hatch: false)
                k.face(55 + fx, 57, spread: 5.5, rx: 2.9, ry: 3.9, seed: 30)
                festiveElfHat(f, k, suit, suitInk, trim, tip)
                festiveElfAccessory(f, k, la, ra)
                k.marks(f.mood == .fleeing ? 30 : 70, 80, 12, ink: suitInk, seed: 40)
            }
        }
    }

    private static func festiveElfHat(_ f: FigureFrame, _ k: DoodleKit, _ suit: Tone, _ ink: Tone, _ trim: Tone, _ tip: [CGFloat]) {
        let tx = tip[0], ty = tip[1]
        let mx = (tx + 52) / 2 + 4, my = max(ty, 82) + 4
        let cone = smooth([38, 66, 66, 66, 62, 76, mx, my, tx, ty, 44, 74], t: 0.6)
        festivePaint(k, cone, suit, ink, seed: 14, hatch: false)
        if f.variant % 5 == 4 {
            k.marker(line(43, 74, 60, 74), trim, festiveThin(k), seed: 15)
            k.marker(line(45, 80, 57, 81), trim, festiveThin(k), seed: 16)
        }
        festivePaint(k, rrect(36, 63, 32, 7, 3.5), .white, ink, seed: 17, w: festiveThin(k), hatch: false)
        k.dot(tx, ty, 3.6, 3.6, Tone(0xffc21a), seed: 18)
        k.marker(circ(tx, ty, 3.6), Tone(0xf06a10), festiveThin(k), seed: 19)
    }

    private static func festiveElfAccessory(_ f: FigureFrame, _ k: DoodleKit, _ la: [CGFloat], _ ra: [CGFloat]) {
        switch f.variant % 5 {
        case 1:
            festiveCandyCane(k, ra[4] + 1, ra[5] - 7, 0.95, seed: 50)
        case 2:
            let red = Tone(0xff3048), redInk = Tone(0xb8102a)
            festivePaint(k, rrect(39, 42, 25, 6, 3), red, redInk, seed: 52, w: festiveThin(k), hatch: false)
            festivePaint(k, poly([42, 44, 48, 44, 45, 31, 39, 33]), red, redInk, seed: 53, w: festiveThin(k), hatch: false)
        case 3:
            festiveMiniGift(k, ra[4] + 2, ra[5] + 1, 0.85, Tone(0xff3b3b), Tone(0xb80f30), seed: 55)
        default:
            break
        }
    }

    static func reindeer(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone, Tone)] = [
            (Tone(0xb8743e), Tone(0xe8581a), Tone(0xff2a3a)), (Tone(0xc8844a), Tone(0xe8581a), Tone(0x5a3020)),
            (Tone(0xa8683a), Tone(0xe8581a), Tone(0x5a3020)), (Tone(0xe3b27a), Tone(0xe0601a), Tone(0x5a3020)),
            (Tone(0x8a5434), Tone(0xff8a3a), Tone(0x5a3020)),
        ]
        let (fur, ink, nose) = f.pick(looks)
        let antler = Tone(0xe0a040)
        let e = f.energy
        let bob: CGFloat = f.bounce * 1.5 * e
        var rot: CGFloat = 0, fx: CGFloat = 0, drop: CGFloat = 0
        var hx: CGFloat = 0, hy: CGFloat = 0, ear: CGFloat = 0.5 + 0.25 * f.twitch
        var reach: CGFloat = 6 * e, back: CGFloat = 0, tail: CGFloat = 0.3 * f.twitch
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            drop = 14
            hx = 2
            hy = -9
            ear = -0.2
            reach = 0
        case .startled:
            hy = 5
            hx = -1
            ear = 1.0
            reach = 0
            tail = 0.8
        case .fleeing:
            fx = 2
            hx = 3
            hy = -3
            ear = -0.3
            back = 0
            reach = 10
            tail = -0.4
        case .dizzy:
            rot = 0.12 * sin(f.t)
        }
        k.with(about(50, 5, rot: rot)) {
            k.with(CGAffineTransform(translationX: 0, y: bob - drop)) {
                let legs: [(CGFloat, Int)] = [(36, 1), (62, 0), (28, 0), (54, 1)]
                for (i, leg) in legs.enumerated() {
                    let g = festiveGait(f, leg.1, reach: reach, lift: 4 * e)
                    var fx0 = leg.0 + g.0 - back, fy0 = 5 + g.1 + drop
                    if f.mood == .sleepy {
                        fx0 = leg.0 + 9
                        fy0 = 21
                    } else if f.mood == .startled {
                        fx0 = leg.0 + (leg.0 > 45 ? 5 : -5)
                    }
                    let tone = i < 2 ? ink : ink.dim(0.82)
                    k.stick([leg.0, 30, fx0, fy0], tone, seed: 1 + i, w: festivePen(k))
                    k.dot(fx0, fy0, 3, 2.4, Tone(0x5a3020), seed: 5 + i)
                }
                k.with(about(22, 40, rot: tail)) {
                    festivePaint(k, ell(19, 43, 5.5, 3.5, 0.7), Tone(0xfff0dc), ink, seed: 9, w: festiveThin(k), hatch: false)
                }
                let cx: CGFloat = 72 + hx, cy: CGFloat = 57 + hy
                k.with(about(cx - 6, cy + 7, rot: ear)) {
                    festivePaint(k, ell(cx - 14, cy + 7, 7, 3.4), fur, ink, seed: 10, w: festiveThin(k), hatch: false)
                }
                festiveReindeerAntler(k, cx - 5, cy + 9, 1, antler, seed: 11)
                festiveReindeerAntler(k, cx + 3, cy + 10, 0.9, antler.dim(0.9), seed: 12)
                let deer = uni([ell(45, 35, 24, 12), festiveCapsule(60, 38, cx - 4, cy - 2, 7), ell(cx, cy, 12, 11), ell(cx + 9, cy - 4, 8.5, 6.5)])
                festivePaint(k, deer, fur, ink, seed: 13)
                k.face(cx + 3 + fx, cy + 1, spread: 4.4, rx: 2.7, ry: 3.6, mouth: false, cheeks: false, seed: 30)
                k.mouth(cx + 9 + fx, cy - 8, 5, seed: 36)
                if f.variant % 5 == 0 { k.glow(cx + 17, cy - 3, 11, Tone(0xff4040), 0.45) }
                k.dot(cx + 17, cy - 3, 4, 3.8, nose, seed: 37)
                k.fill(circ(cx + 18, cy - 1.8, 1.1), Tone(1, 1, 1, 0.8))
                festiveReindeerAccessory(f, k, cx, cy)
                k.marks(f.mood == .fleeing ? 46 : 86, cy + 18, 12, ink: ink, seed: 40)
            }
        }
    }

    private static func festiveReindeerAntler(_ k: DoodleKit, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat, _ tone: Tone, seed: Int) {
        let p = CGMutablePath()
        p.addPath(smooth([x, y, x - 2 * s, y + 10 * s, x - 7 * s, y + 18 * s], closed: false))
        p.move(to: pt(x - 2 * s, y + 9 * s))
        p.addLine(to: pt(x + 5 * s, y + 15 * s))
        p.move(to: pt(x - 4.5 * s, y + 14.5 * s))
        p.addLine(to: pt(x - 1 * s, y + 21 * s))
        k.marker(p, tone, k.width(3.6, minPt: 1.35), seed: seed)
    }

    private static func festiveReindeerAccessory(_ f: FigureFrame, _ k: DoodleKit, _ cx: CGFloat, _ cy: CGFloat) {
        switch f.variant % 5 {
        case 1:
            let red = Tone(0xff3048), redInk = Tone(0xb8102a)
            festivePaint(k, festiveCapsule(cx - 14, cy - 10, cx - 3, cy - 11, 3.4), red, redInk, seed: 50, w: festiveThin(k), hatch: false)
            festivePaint(k, poly([cx - 13, cy - 11, cx - 9, cy - 12, cx - 13, cy - 24, cx - 17, cy - 22]), Tone(0x2fcf5a), Tone(0x0f8a3a), seed: 51, w: festiveThin(k), hatch: false)
        case 2:
            k.marker(smooth([cx - 15, cy - 6, cx - 9, cy - 10, cx - 2, cy - 10], closed: false), Tone(0xff3048), k.width(3.8, minPt: 1.4), seed: 52)
            k.dot(cx - 8, cy - 13.5, 3.4, 3.4, Tone(0xffc21a), seed: 53)
            k.marker(circ(cx - 8, cy - 13.5, 3.4), Tone(0xf06a10), festiveThin(k), seed: 54)
        case 3:
            let red = Tone(0xff3048), redInk = Tone(0xc8102a)
            festivePaint(k, smooth([cx - 9, cy + 8, cx + 7, cy + 8, cx + 1, cy + 18, cx - 10, cy + 22, cx - 4, cy + 14], t: 0.5), red, redInk, seed: 55, hatch: false)
            festivePaint(k, rrect(cx - 11, cy + 6, 20, 5, 2.5), .white, redInk, seed: 56, w: festiveThin(k), hatch: false)
            k.dot(cx - 11, cy + 22, 3.2, 3.2, .white, seed: 57)
        case 4:
            let bulbs: [Tone] = [Tone(0xff3048), Tone(0xffc21a), Tone(0x3fd06a), Tone(0x4f9cff)]
            for (i, q) in P([cx - 7, cy + 19, cx - 1, cy + 25, cx + 5, cy + 22, cx - 7, cy + 26]).enumerated() {
                k.dot(q.x, q.y, 2.6, 2.6, bulbs[i], seed: 58 + i)
            }
        default:
            break
        }
    }

    static func blackCat(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xa070ff), Tone(0xffd84a)), (Tone(0xff8a2a), Tone(0x9aff6a)), (Tone(0x3fd07a), Tone(0xffd84a)),
            (Tone(0xff4f9a), Tone(0x6ad8ff)), (Tone(0x4f9cff), Tone(0xffd84a)),
        ]
        let (ink, eyeTone) = f.pick(looks)
        let fur = Tone(0x342c4e)
        let e = f.energy
        let bob: CGFloat = f.bounce * 1.2 * e
        var rot: CGFloat = 0, fx: CGFloat = 0, drop: CGFloat = 0, hy: CGFloat = 0
        var reach: CGFloat = 6 * e, legTop: CGFloat = 24
        var earFlat: CGFloat = 0
        let tw = f.twitch
        var tailPts: [CGFloat] = [22, 30, 12, 38, 9, 52, 14 + 3 * tw, 62 + 2 * f.swing2]
        var torso = ell(44, 29, 23, 11.5)
        switch f.mood {
        case .calm:
            break
        case .sleepy:
            drop = 13
            hy = -4
            reach = 0
            tailPts = [26, 22, 34, 18, 50, 17, 62, 19]
        case .startled:
            torso = smooth([20, 20, 25, 40, 42, 56, 60, 44, 68, 22, 56, 26, 44, 32, 32, 26], t: 0.9)
            legTop = 23
            reach = 0
            hy = 2
            tailPts = [22, 32, 18, 46, 19, 60, 17, 74]
            earFlat = -2
        case .fleeing:
            fx = 2
            reach = 11
            hy = -2
            earFlat = 4
            tailPts = [22, 31, 12, 35, 2, 37, -6, 40 + 2 * f.swing]
            torso = ell(44, 29, 25, 10.5)
        case .dizzy:
            rot = 0.12 * sin(f.t)
            tailPts = [22, 30, 12, 38, 9 + 4 * f.swing, 52, 14 - 4 * f.swing, 62]
        }
        k.with(about(50, 5, rot: rot)) {
            k.with(CGAffineTransform(translationX: 0, y: bob - drop)) {
                if f.mood != .sleepy {
                    let legs: [(CGFloat, Int)] = [(30, 1), (58, 0), (24, 0), (52, 1)]
                    for (i, leg) in legs.enumerated() {
                        let g = festiveGait(f, leg.1, reach: reach, lift: 4 * e)
                        var tx = leg.0 + g.0, ty = 5 + g.1
                        if f.mood == .startled { tx = leg.0 + (leg.0 > 45 ? 4 : -4) }
                        if f.mood == .fleeing && leg.0 < 40 { tx -= 4 }
                        let tone = i < 2 ? ink : ink.dim(0.8)
                        k.stick([leg.0, legTop, tx, ty], tone, seed: 1 + i, w: festivePen(k))
                    }
                }
                let cx: CGFloat = 70, cy: CGFloat = 45 + hy
                let earL = poly([cx - 12, cy + 6, cx - 9 + earFlat * 0.5, cy + 22 - earFlat, cx - 3, cy + 11])
                let earR = poly([cx + 1, cy + 12, cx + 9 + tw * 1.5 + earFlat, cy + 22 - earFlat, cx + 12, cy + 6])
                let tail = festiveTube(tailPts, f.mood == .startled ? 5 : 3.6)
                let cat = uni([torso, circ(cx, cy, 15.5), earL, earR, tail])
                festivePaint(k, cat, fur, ink, seed: 10)
                k.fill(poly([cx - 9.5, cy + 8, cx - 8 + earFlat * 0.4, cy + 17 - earFlat, cx - 5, cy + 10]), ink.alpha(0.55))
                let eyeInk = f.mood == .startled ? k.felt : eyeTone
                k.eye(cx + 1 + fx, cy + 2, 3.2, 4.3, side: -1, ink: eyeInk, seed: 30)
                k.eye(cx + 10 + fx, cy + 2, 3.2, 4.3, side: 1, ink: eyeInk, seed: 31)
                k.fill(poly([cx + 4 + fx, cy - 3, cx + 7.5 + fx, cy - 3, cx + 5.8 + fx, cy - 5.5]), Tone(0xff8ab0))
                k.mouth(cx + 5.8 + fx, cy - 7, 6, ink: Tone(0xff8ab0), seed: 32)
                k.marker(line(cx + 13, cy - 3, cx + 21, cy - 1), ink, festiveThin(k), seed: 33)
                k.marker(line(cx + 13, cy - 6, cx + 21, cy - 7), ink, festiveThin(k), seed: 34)
                festiveCatAccessory(f, k, cx, cy, ink)
                k.marks(f.mood == .fleeing ? 44 : 86, cy + 22, 12, ink: ink, seed: 40)
            }
        }
    }

    private static func festiveCatAccessory(_ f: FigureFrame, _ k: DoodleKit, _ cx: CGFloat, _ cy: CGFloat, _ ink: Tone) {
        switch f.variant % 5 {
        case 1:
            festiveWitchHat(k, cx, cy + 13, 0.9, tip: 2 * f.twitch, seed: 50)
        case 2:
            k.marker(smooth([cx - 12, cy - 6, cx - 2, cy - 13, cx + 8, cy - 12], closed: false), Tone(0xff3048), k.width(3.8, minPt: 1.4), seed: 53)
            k.dot(cx - 1, cy - 16, 3.4, 3.4, Tone(0xffc21a), seed: 54)
            k.marker(circ(cx - 1, cy - 16, 3.4), Tone(0xf06a10), festiveThin(k), seed: 55)
        case 3:
            festiveBow(k, cx + 8, cy + 14, 0.95, Tone(0xff7ab8), Tone(0xff2f7a), seed: 56)
        case 4:
            festivePaint(k, poly([cx - 13, cy - 7, cx + 6, cy - 12, cx - 6, cy - 20]), Tone(0xff8a1a), Tone(0xe0401a), seed: 58, w: festiveThin(k), hatch: false)
            k.dot(cx - 5, cy - 13, 1.6, 1.6, .white, seed: 59)
        default:
            break
        }
    }

    static func santa(_ f: FigureFrame, _ k: DoodleKit) {
        let looks: [(Tone, Tone)] = [
            (Tone(0xff3040), Tone(0xc00f2a)), (Tone(0xff3040), Tone(0xc00f2a)), (Tone(0x2fbf5a), Tone(0x0b8a3a)),
            (Tone(0xff3040), Tone(0xc00f2a)), (Tone(0x4f7cff), Tone(0x1f45d0)),
        ]
        let (suit, ink) = f.pick(looks)
        let skin = Tone(0xffc9a0), beardInk = Tone(0x7a8cff), boot = Tone(0x3a2a3a)
        let e = f.energy
        let bob: CGFloat = f.bounce * 1.5 * e
        var rot: CGFloat = 0, sy: CGFloat = 1, fx: CGFloat = 0
        let a = festiveGait(f, 0, reach: 5 * e, lift: 4 * e)
        let b = festiveGait(f, 1, reach: 5 * e, lift: 4 * e)
        var feet: [CGFloat] = [42 + a.0, 8 + a.1, 58 + b.0, 8 + b.1]
        var la: [CGFloat] = [28, 44, 20, 38 - 3 * f.swing * e, 17, 31 - 4 * f.swing * e]
        var ra: [CGFloat] = [72, 44, 80, 38 + 3 * f.swing * e, 83, 31 + 4 * f.swing * e]
        var tip: [CGFloat] = [28, 88 + 2 * f.twitch]
        switch f.mood {
        case .calm:
            if f.twitch > 0 { ra = [72, 44, 82, 52, 86, 62] }
        case .sleepy:
            sy = 0.95
            feet = [43, 8, 57, 8]
            la = [28, 44, 32, 34, 40, 30]
            ra = [72, 44, 68, 34, 60, 30]
            tip = [34, 78]
        case .startled:
            sy = 1.05
            feet = [37, 8, 63, 8]
            la = [28, 46, 20, 56, 17, 66]
            ra = [72, 46, 80, 56, 83, 66]
            tip = [36, 100]
        case .fleeing:
            fx = 3
            la = [28, 44, 19, 40 - 6 * f.swing, 12, 42 - 8 * f.swing]
            ra = [72, 44, 81, 40 + 6 * f.swing, 86, 42 + 8 * f.swing]
            tip = [16, 82 + 2 * f.swing]
        case .dizzy:
            rot = 0.12 * sin(f.t)
            la = [28, 44, 20, 48, 15, 42 + 5 * f.swing]
            ra = [72, 44, 80, 48, 85, 42 - 5 * f.swing]
        }
        let v = f.variant % 5
        if v == 1 && f.mood != .startled && f.mood != .sleepy { la = [30, 46, 24, 56, 26, 64] }
        k.with(about(50, 5, rot: rot, sy: sy)) {
            k.with(CGAffineTransform(translationX: 0, y: bob)) {
                if v == 1 {
                    festivePaint(k, smooth([12, 50, 30, 50, 34, 66, 26, 74, 16, 72, 10, 62], t: 0.8), Tone(0xc8925a), Tone(0xe0701a), seed: 50)
                    k.marker(line(20, 72, 26, 75), Tone(0xe0701a), festiveThin(k), seed: 51)
                }
                k.stick([43, 18, feet[0], feet[1] + 2], boot, seed: 1, w: festivePen(k))
                k.stick([57, 18, feet[2], feet[3] + 2], boot, seed: 2, w: festivePen(k))
                festivePaint(k, ell(feet[0] + 2, feet[1], 6.5, 4), boot, ink, seed: 3, w: festiveThin(k), hatch: false)
                festivePaint(k, ell(feet[2] + 2, feet[3], 6.5, 4), boot, ink, seed: 4, w: festiveThin(k), hatch: false)
                let arm = k.width(5.5, minPt: 1.9)
                k.stick(la, ink, seed: 5, w: arm)
                k.stick(ra, ink, seed: 6, w: arm)
                k.dot(la[4], la[5], 3.4, 3.4, .white, seed: 7)
                k.dot(ra[4], ra[5], 3.4, 3.4, .white, seed: 8)
                festivePaint(k, ell(50, 34, 24, 21.5), suit, ink, seed: 9)
                festivePaint(k, rrect(26, 24, 48, 7, 3), boot, boot, seed: 10, w: festiveThin(k), hatch: false)
                festivePaint(k, rrect(44, 23, 11, 9, 2), Tone(0xffd23a), Tone(0xf06a10), seed: 11, w: festiveThin(k), hatch: false)
                festivePaint(k, circ(52 + fx, 64, 10.5), skin, Tone(0xff6a3a), seed: 12, hatch: false)
                let beard = smooth([34 + fx, 62, 70 + fx, 62, 70 + fx, 51, 61 + fx, 41, 52 + fx, 37, 42 + fx, 41, 34 + fx, 51], t: 0.8)
                festivePaint(k, beard, .white, beardInk, seed: 13)
                k.face(53 + fx, 67, spread: 4.6, rx: 2.5, ry: 3.4, mouth: false, cheeks: false, seed: 30)
                k.mouth(53 + fx, 52, 7, seed: 36)
                k.dot(53.5 + fx, 61, 2.8, 2.4, Tone(0xff7a8a), seed: 37)
                festiveSantaHat(k, suit, ink, tip, fx, seed: 14)
                festiveSantaAccessory(f, k, la, ra)
                k.marks(f.mood == .fleeing ? 26 : 74, 82, 12, ink: ink, seed: 40)
            }
        }
    }

    private static func festiveSantaHat(_ k: DoodleKit, _ suit: Tone, _ ink: Tone, _ tip: [CGFloat], _ fx: CGFloat, seed: Int) {
        let tx = tip[0] + fx, ty = tip[1]
        let mx = (tx + 52 + fx) / 2 + 4, my = max(ty, 84) + 3
        let cone = smooth([40 + fx, 72, 64 + fx, 72, 61 + fx, 81, mx, my, tx, ty, 45 + fx, 79], t: 0.6)
        festivePaint(k, cone, suit, ink, seed: seed, hatch: false)
        festivePaint(k, rrect(38 + fx, 69, 28, 7, 3.5), .white, Tone(0x7a8cff), seed: seed + 1, w: festiveThin(k), hatch: false)
        k.dot(tx, ty, 4.4, 4.4, .white, seed: seed + 2)
        k.marker(circ(tx, ty, 4.4), Tone(0x7a8cff), festiveThin(k), seed: seed + 3)
    }

    private static func festiveSantaAccessory(_ f: FigureFrame, _ k: DoodleKit, _ la: [CGFloat], _ ra: [CGFloat]) {
        switch f.variant % 5 {
        case 2:
            let bell = smooth([ra[4] - 5, ra[5] - 9, ra[4] + 5, ra[5] - 9, ra[4] + 3, ra[5] - 3, ra[4], ra[5] - 1, ra[4] - 3, ra[5] - 3], t: 0.7)
            festivePaint(k, bell, Tone(0xffc21a), Tone(0xf06a10), seed: 52, w: festiveThin(k), hatch: false)
            k.dot(ra[4], ra[5] - 10, 1.8, 1.8, Tone(0xf06a10), seed: 53)
        case 3:
            festiveCandyCane(k, ra[4] + 1, ra[5] - 7, 1, seed: 54)
        case 4:
            festiveMiniGift(k, ra[4] + 3, ra[5] + 1, 0.95, Tone(0xffc21a), Tone(0xf06010), seed: 56)
        default:
            break
        }
    }
}
