import Foundation
import CoreGraphics
import ScuttleCore

extension PropArt {
    static func eggPath(_ cx: CGFloat, _ base: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGPath {
        let hw = w / 2
        return smoothP([
            pt(cx, base), pt(cx + hw * 0.82, base + h * 0.12), pt(cx + hw, base + h * 0.38), pt(cx + hw * 0.78, base + h * 0.72),
            pt(cx, base + h), pt(cx - hw * 0.78, base + h * 0.72), pt(cx - hw, base + h * 0.38), pt(cx - hw * 0.82, base + h * 0.12),
        ], t: 1)
    }

    static func egg(_ b: PropBrush, _ v: Int) {
        let looks: [(PropTone, PropTone)] = [
            (PropTone(0xff9ec0, .red), PropTone(0xfff6ee, .cream)),
            (PropTone(0x7ec8f0, .cream), PropTone(0xf6d25a, .red)),
            (PropTone(0xf6d25a, .cream), PropTone(0xff7aa8, .red)),
            (PropTone(0x8fe0b8, .ink), PropTone(0x9a6ad8, .cream)),
        ]
        let (shellTone, paint) = looks[v]
        let shape = eggPath(50, 4, 64, 88)
        b.body(shape, shellTone, seed: 1)
        b.clip(shape) {
            switch v {
            case 0:
                b.stick(zigzag(14, 62, 86, 62, teeth: b.small ? 3 : 5, amp: 6), paint, w: b.small ? 7 : 5, seed: 2)
            case 1:
                for (i, d) in ([(34, 52), (64, 50), (50, 66), (40, 78), (60, 78), (26, 34), (74, 32)] as [(CGFloat, CGFloat)]).enumerated() {
                    b.dot(d.0, d.1, b.small ? 6 : 4.5, paint, seed: 3 + i)
                }
            case 2:
                b.plain(rrect(0, 50, 100, 9, 0), paint)
                b.plain(rrect(0, 68, 100, 8, 0), paint)
            default:
                b.stick(wavy(12, 56, 88, 56, waves: 2, amp: 5), paint, w: b.small ? 7 : 5, seed: 4)
                if !b.small { b.stick(wavy(14, 72, 86, 72, waves: 1.6, amp: 4), paint, w: 3, seed: 5) }
            }
        }
        b.edge(shape, shellTone, seed: 6)
        b.shine(34, 70, 3.5, 6, 0.4)
        b.face(51, 30, 3.2, spread: 11)
    }

    static func flower(_ b: PropBrush, _ stage: Int, _ v: Int) {
        let stem = PropTone(0x4fae4a, .ink)
        if stage == 0 {
            b.stick(smooth([50, 4, 49, 18, 51, 32], closed: false), stem, w: 5, seed: 1)
            b.flat(leafPath(40, 14, 20, 8, 0.5), stem, seed: 2)
            b.flat(leafPath(60, 18, 18, 7, -0.6), stem, seed: 3)
            let tips: [UInt32] = [0xfff8f0, 0xe8453c, 0xffc83a, 0xff8fc0]
            b.body(smooth([51, 46, 57, 38, 55, 30, 47, 30, 45, 38], t: 0.7), stem, seed: 4)
            b.flat(smooth([51, 46, 55, 40, 47, 40], t: 0.6), PropTone(tips[v], .red), seed: 5)
            return
        }
        b.stick(smooth([50, 4, 48, 30, 51, 62], closed: false), stem, w: 5, seed: 1)
        b.flat(leafPath(37, 22, 26, 9, 0.55), stem, seed: 2)
        b.flat(leafPath(62, 32, 22, 8, -0.6), stem, seed: 3)
        if stage == 1 {
            b.with(about(51, 62, sx: 0.62, sy: 0.62)) { flowerHead(b, v, cx: 51, cy: 72) }
            return
        }
        flowerHead(b, v, cx: 51, cy: 72)
    }

    static func flowerHead(_ b: PropBrush, _ v: Int, cx: CGFloat, cy: CGFloat) {
        switch v {
        case 0, 3:
            let petal = v == 0 ? PropTone(0xfff8f0, .cream) : PropTone(0xff8fc0, .red)
            let n = v == 0 ? 8 : 5
            let rad: CGFloat = v == 0 ? 15 : 13
            var petals: [CGPath] = []
            for i in 0..<n {
                let a = CGFloat(i) / CGFloat(n) * 2 * .pi + 0.2
                petals.append(ell(cx + cos(a) * rad, cy + sin(a) * rad, v == 0 ? 9 : 11, v == 0 ? 5.5 : 10, a))
            }
            let all = uni(petals)
            b.body(all, petal, seed: 4)
            b.body(circ(cx, cy, v == 0 ? 9 : 8), PropTone(0xffc83a, v == 0 ? .red : .cream), seed: 5)
        case 1:
            let cup = smooth([cx - 15, cy + 14, cx - 9, cy + 6, cx - 3, cy + 16, cx + 3, cy + 6, cx + 9, cy + 16, cx + 15, cy + 8, cx + 13, cy - 8, cx, cy - 13, cx - 13, cy - 8], t: 0.55)
            b.body(cup, PropTone(0xe8453c, .red), seed: 6)
            b.mark(smooth([cx, cy - 10, cx + 1, cy + 4, cx + 3, cy + 6], closed: false), on: PropTone(0xe8453c, .red), alpha: 0.7, seed: 7)
            b.shine(cx - 7, cy + 2, 2.4, 4.5, 0.2)
        default:
            let ray = softStar(cx, cy, 24, points: 12, inner: 0.62, spin: 0.1, t: 0.55)
            b.body(ray, PropTone(0xffc83a, .red), seed: 8)
            b.body(circ(cx, cy, 11), PropTone(0x7a4a26, .ink), seed: 9)
            if !b.small {
                for (i, d) in ([(-4, 3), (3, 4), (0, -4), (5, -2), (-5, -3)] as [(CGFloat, CGFloat)]).enumerated() {
                    b.dot(cx + d.0, cy + d.1, 1.2, PropTone(0x4a2a16, .cream), seed: 10 + i)
                }
            }
        }
    }

    static func nest(_ b: PropBrush, _ stage: Int, _ v: Int) {
        let straw = PropTone(v == 1 ? 0xb8864a : 0xa8743e, .ink)
        let light = PropTone(0xd8aa6a, .cream)
        if stage == 0 {
            let sticks: [[CGFloat]] = [[8, 8, 46, 16, 88, 9], [16, 19, 52, 6, 92, 21], [30, 4, 58, 22, 76, 31], [22, 28, 40, 14, 66, 7], [44, 30, 60, 16, 84, 26]]
            for (i, s) in sticks.enumerated() {
                b.stick(smooth(s, closed: false), i % 2 == 0 ? straw : light, w: b.small ? 6 : 4, seed: i)
            }
            return
        }
        let cy: CGFloat = stage == 1 ? 22 : 30
        let rx0: CGFloat = stage == 1 ? 40 : 44
        var rim: [CGPoint] = []
        var n = Noise(v * 13 + 5)
        let count = 16
        for i in 0..<count {
            let a = CGFloat(i) / CGFloat(count) * 2 * .pi
            let lower = sin(a) < 0
            let rx: CGFloat = rx0 * (1 + n.range(-0.04, 0.06))
            let ry: CGFloat = lower ? cy - 4 : 9 + n.range(-1, 3)
            rim.append(pt(50 + rx * cos(a), cy + ry * sin(a) + (i % 2 == 0 ? 2.5 : -1.5)))
        }
        let bowl = smoothP(rim, t: 0.7)
        b.body(bowl, straw, seed: 1)
        b.inkFill(ell(50, cy + 2, rx0 * 0.75, 7))
        b.plain(ell(50, cy, rx0 * 0.64, 4.2), PropTone(0x6a4424, .ink))
        b.flat(smooth([50 - rx0 * 0.9, cy - 1, 50, cy - 9, 50 + rx0 * 0.9, cy - 1, 50 + rx0 * 0.86, cy - 7, 50, cy - 15, 50 - rx0 * 0.86, cy - 7], t: 0.8), straw, seed: 25)
        if !b.tiny {
            let weave: [[CGFloat]] = [[10, cy - 6, 40, cy - 14, 70, cy - 10, 92, cy - 4], [16, cy - 16, 46, cy - 22, 82, cy - 16], [8, cy - 2, 30, cy - 8, 52, cy - 4, 84, cy - 9]]
            b.clip(bowl) {
                for (i, w) in weave.enumerated() {
                    b.mark(smooth(w, closed: false), on: straw, alpha: 0.8, seed: 10 + i)
                }
            }
            let tufts: [[CGFloat]] = stage == 1
                ? [[10, cy, 0, cy + 10], [90, cy, 100, cy + 6], [60, 6, 92, 2], [30, cy + 6, 22, cy + 16]]
                : [[8, cy + 2, 0, cy + 10], [92, cy, 100, cy + 6], [20, cy + 8, 14, cy + 16], [78, cy + 8, 86, cy + 15]]
            for (i, t) in tufts.enumerated() {
                b.stick(line(t[0], t[1], t[2], t[3]), i % 2 == 0 ? light : straw, w: 2.6, seed: 15 + i)
            }
        }
    }

    static func shell(_ b: PropBrush, _ v: Int) {
        if v == 3 {
            let conch = smooth([20, 10, 44, 4, 78, 10, 92, 30, 82, 54, 60, 70, 42, 86, 34, 74, 26, 52, 14, 30], t: 0.8)
            let tone = PropTone(0xf6c8a8, .cream)
            b.body(conch, tone, seed: 1)
            b.mark(spiral(60, 36, 22, turns: 1.6, spin: -1, start: 2), on: tone, alpha: 0.8, seed: 2)
            b.flat(smooth([24, 14, 40, 8, 54, 14, 48, 28, 32, 30], t: 0.7), PropTone(0xff9ec0, .red), seed: 3)
            return
        }
        let tones: [(UInt32, InkRole)] = [(0xffb8c8, .red), (0xfff0d8, .cream), (0xff9070, .red)]
        let tone = PropTone(tones[v].0, tones[v].1)
        var fan: [CGPoint] = [pt(50, 8)]
        let ribs = 7
        for i in 0...(ribs * 2) {
            let u = CGFloat(i) / CGFloat(ribs * 2)
            let a = CGFloat.pi * (0.92 - 0.84 * u)
            let r: CGFloat = i % 2 == 0 ? 74 : 80
            fan.append(pt(50 + cos(a) * r * 0.58, 8 + sin(a) * r))
        }
        let body = smoothP(fan, t: 0.5)
        b.flat(smooth([36, 4, 64, 4, 60, 16, 40, 16], t: 0.4), tone, seed: 4)
        b.body(body, tone, seed: 5)
        if !b.tiny {
            let count = b.small ? 3 : 6
            for i in 1..<count {
                let u = CGFloat(i) / CGFloat(count)
                let a = CGFloat.pi * (0.92 - 0.84 * u)
                b.mark(line(50, 12, 50 + cos(a) * 44 * 0.58 * 1.3, 12 + sin(a) * 66), on: tone, alpha: 0.7, seed: i)
            }
        }
    }

    static let sand = PropTone(0xe8c27a, .cream)

    static func tower(_ b: PropBrush, _ x: CGFloat, _ w: CGFloat, _ h: CGFloat, seed: Int, window: Bool) {
        let top = 4 + h
        let tw = w * 0.86
        let teeth = 3
        var pts: [CGPoint] = [pt(x - w / 2, 4), pt(x + w / 2, 4), pt(x + tw / 2, top)]
        let step = tw / CGFloat(teeth * 2 - 1)
        for i in 0..<(teeth * 2 - 1) {
            let xr = x + tw / 2 - CGFloat(i) * step
            let up = i % 2 == 0
            pts.append(pt(xr, top + (up ? 7 : 0)))
            pts.append(pt(xr - step, top + (up ? 7 : 0)))
        }
        pts.append(pt(x - tw / 2, top))
        let p = polyP(pts)
        b.body(p, sand, seed: seed)
        if window, h > 26 {
            b.inkFill(rrect(x - w * 0.1, 4 + h * 0.5, w * 0.2, h * 0.24, w * 0.1))
        }
        if !b.small {
            b.mark(line(x - w * 0.42, 4 + h * 0.3, x + w * 0.42, 4 + h * 0.3), on: sand, alpha: 0.45, seed: seed + 1)
        }
    }

    static func sandcastle(_ b: PropBrush, _ stage: Int, _ v: Int) {
        let mound = smooth([6, 4, 94, 4, 84, 22, 62, 32, 40, 34, 18, 22], t: 0.8)
        if stage == 0 {
            b.body(mound, sand, seed: 1)
            if !b.small {
                b.dot(36, 20, 2, PropTone(0xc89a52, .ink), seed: 2)
                b.dot(62, 16, 1.6, PropTone(0xc89a52, .ink), seed: 3)
            }
            let spade = PropTone([0xe8453c, 0x4a86e8, 0xf2b630][v], .red)
            b.stick(line(74, 26, 84, 52), PropTone(0xfff2dc, .cream), w: 3.6, seed: 4)
            b.flat(smooth([68, 12, 80, 8, 82, 26, 72, 30], t: 0.4), spade, seed: 5)
            return
        }
        if stage >= 2 {
            b.body(rrect(20, 4, 60, 26, 2), sand, seed: 6)
            tower(b, 18, 26, 36, seed: 7, window: false)
            tower(b, 82, 26, 36, seed: 8, window: false)
        }
        tower(b, 50, 38, stage >= 2 ? 56 : 50, seed: 9, window: true)
        if stage >= 3 {
            let top: CGFloat = 4 + 56 + 7
            b.stick(line(50, top, 50, top + 28), PropTone(0x7a4a26, .ink), w: 2.4, seed: 10)
            let flagTone = PropTone([0xe8453c, 0x4a86e8, 0xf2b630][v], .red)
            b.flat(smooth([51, top + 28, 70, top + 22, 51, top + 16], t: 0.3), flagTone, seed: 11)
            b.flat(smooth([42, 10, 48, 18, 54, 10, 48, 6], t: 0.6), PropTone(0xffb8c8, .red), seed: 12)
        }
    }

    static func ball(_ b: PropBrush, _ v: Int) {
        let cx: CGFloat = 50, cy: CGFloat = 48, r: CGFloat = 44
        let disc = circ(cx, cy, r)
        switch v {
        case 0:
            b.body(disc, PropTone(0xfff8f0, .cream), seed: 1)
            b.clip(disc) {
                b.plain(ell(cx, cy, 15, r), PropTone(0xe8453c, .red))
                let ring = ell(cx, cy, r + 2, r + 2).subtracting(ell(cx, cy, 33, r))
                b.plain(ring.intersection(rrect(0, 0, cx, 100, 0)), PropTone(0xf6d25a, .ink))
                b.plain(ring.intersection(rrect(cx, 0, 50, 100, 0)), PropTone(0x4a86e8, .ink))
                if b.outlined || b.style == .doodle {
                    b.mark(ell(cx, cy, 15, r), on: PropTone(0xfff8f0, .cream), seed: 3)
                    b.mark(ell(cx, cy, 33, r), on: PropTone(0xfff8f0, .cream), seed: 4)
                }
            }
            b.edge(disc, PropTone(0xfff8f0, .cream), seed: 5)
        case 1:
            b.body(disc, PropTone(0xfafafa, .cream), seed: 1)
            b.clip(disc) {
                let pent = { (x: CGFloat, y: CGFloat, s: CGFloat, rot: CGFloat) -> CGPath in
                    polyP((0..<5).map { i in
                        let a = rot + CGFloat(i) / 5 * 2 * .pi + .pi / 2
                        return pt(x + cos(a) * s, y + sin(a) * s)
                    })
                }
                b.inkFill(pent(cx, cy, 13, 0))
                for k in 0..<5 {
                    let a = CGFloat(k) / 5 * 2 * .pi - .pi / 2
                    b.inkFill(pent(cx + cos(a) * 40, cy + sin(a) * 40, 12, .pi))
                    if !b.small {
                        b.ink(line(cx + cos(a) * 13, cy + sin(a) * 13, cx + cos(a) * 30, cy + sin(a) * 30), w: 2)
                    }
                }
            }
            b.edge(disc, PropTone(0xfafafa, .cream), seed: 5)
        case 2:
            b.body(disc, PropTone(0xe8453c, .red), seed: 1)
            b.clip(disc) {
                b.plain(rrect(0, cy - 8, 100, 16, 0), PropTone(0xfff2dc, .cream))
            }
            b.body(softStar(cx, cy, 13, points: 5, inner: 0.48, t: 0.3), PropTone(0xf6d25a, .ink), seed: 2)
            b.edge(disc, PropTone(0xe8453c, .red), seed: 5)
        default:
            b.body(disc, PropTone(0xd8e84a, .cream), seed: 1)
            b.clip(disc) {
                b.stick(arc(cx - r * 1.1, cy + r * 0.5, cx + r * 0.1, cy + r * 1.1, dip: r * 0.55), PropTone(0xfffff0, .ink), w: 4, seed: 2)
                b.stick(arc(cx - r * 0.1, cy - r * 1.1, cx + r * 1.1, cy - r * 0.5, dip: -r * 0.55), PropTone(0xfffff0, .ink), w: 4, seed: 3)
            }
            b.edge(disc, PropTone(0xd8e84a, .cream), seed: 5)
        }
        b.shine(cx - r * 0.45, cy + r * 0.45, r * 0.13, r * 0.08, 0.7)
    }
}
