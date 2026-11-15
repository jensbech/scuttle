import Foundation
import CoreGraphics
import ScuttleCore

extension PropArt {
    static let snow = PropTone(0xf4f7ff, .cream)
    static let coal = PropTone(0x2a2430, .ink)
    static let carrot = PropTone(0xff8a2a, .red)
    static let twig = PropTone(0x7a4a26, .ink)

    static func snowBall(_ b: PropBrush, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, seed: Int, lumpy: CGFloat = 0.04) {
        var n = Noise(seed &* 17 &+ 5)
        let pts = (0..<12).map { i -> CGPoint in
            let a = CGFloat(i) / 12 * 2 * .pi
            let rr = r * (1 + n.range(-lumpy, lumpy))
            return pt(cx + rr * cos(a), cy + rr * sin(a) * 0.97)
        }
        let p = smoothP(pts, t: 1)
        b.body(p, snow, seed: seed)
        if b.style == .hose, r > 14 {
            b.clip(p) {
                b.stroke(arc(cx - r * 0.75, cy - r * 0.35, cx + r * 0.2, cy - r * 0.92, dip: r * 0.25), PropBrush.hoseInk.alpha(0.8), b.thinW)
            }
        }
        b.shine(cx - r * 0.38, cy + r * 0.4, r * 0.16, r * 0.1, 0.6)
    }

    static func snowball(_ b: PropBrush, _ stage: Int, _ v: Int) {
        if stage == 0 {
            var n = Noise(v * 7 + 3)
            var pts: [CGPoint] = []
            for i in 0..<14 {
                let a = CGFloat(i) / 14 * 2 * .pi
                let rr: CGFloat = i % 2 == 0 ? n.range(36, 46) : n.range(20, 28)
                pts.append(pt(50 + rr * cos(a), 12 + rr * sin(a) * 0.3))
            }
            b.body(smoothP(pts, t: 0.8), snow, seed: v + 40)
            for (i, d) in ([(10, 22, 4.5), (88, 20, 4), (24, 30, 3), (76, 30, 3.5)] as [(CGFloat, CGFloat, CGFloat)]).enumerated() {
                b.body(circ(d.0, d.1, d.2), snow, seed: v + 41 + i)
            }
            return
        }
        let r: CGFloat = v == 3 ? 43 : 45
        snowBall(b, 50, 4 + r * (v == 3 ? 0.9 : 1), r, seed: v + 1, lumpy: v == 1 ? 0.07 : 0.03)
        if v == 2, !b.small {
            b.plain(star(66, 66, 6, points: 4, inner: 0.35), PropTone(0xffffff, .cream))
            b.plain(star(32, 28, 4.5, points: 4, inner: 0.35), PropTone(0xffffff, .cream))
        }
    }

    static func snowman(_ b: PropBrush, _ stage: Int, _ v: Int) {
        let scarves: [(UInt32, InkRole)] = [(0xe8453c, .red), (0x4a86e8, .red), (0x3fae5a, .red), (0xf2b630, .red)]
        let scarf = PropTone(scarves[v].0, scarves[v].1)
        snowBall(b, 50, 26, 22, seed: 1)
        if stage >= 1 { snowBall(b, 50, 58, 16, seed: 2) }
        if stage >= 2 { snowBall(b, 50, 82, 12, seed: 3) }
        guard stage >= 3 else { return }
        let eye: CGFloat = b.small ? 2.6 : 2.1
        b.dot(45, 85, eye, coal, seed: 4)
        b.dot(55, 85, eye, coal, seed: 5)
        if !b.small {
            for (i, x) in ([44, 47.5, 52.5, 56] as [CGFloat]).enumerated() {
                b.dot(x, 76 - abs(x - 50) * 0.25, 1.1, coal, seed: 7 + i)
            }
        }
        guard stage >= 4 else { return }
        b.dot(50, 62, b.small ? 2.4 : 2, coal, seed: 12)
        b.dot(50, 53, b.small ? 2.4 : 2, coal, seed: 13)
        b.dot(50, 44, b.small ? 2.4 : 2, coal, seed: 23)
        guard stage >= 5 else { return }
        b.flat(smooth([50, 82, 64, 79, 50, 77.5], t: 0.4), carrot, seed: 6)
        guard stage >= 6 else { return }
        b.stick(smooth([36, 60, 24, 68, 14, 78], closed: false), twig, w: 3.4, seed: 14)
        b.stick(smooth([22, 70, 17, 66], closed: false), twig, w: 2.6, seed: 15)
        b.stick(smooth([64, 60, 76, 70, 86, 74], closed: false), twig, w: 3.4, seed: 16)
        b.stick(smooth([78, 71, 82, 79], closed: false), twig, w: 2.6, seed: 17)
        b.flat(smooth([37, 72, 50, 69, 63, 72, 62, 77, 50, 74.5, 38, 77], t: 0.6), scarf, seed: 18)
        b.flat(smooth([56, 73, 63, 71, 66, 58, 60, 57], t: 0.6), scarf, seed: 19)
        if v % 2 == 0 {
            b.body(rrect(34, 91, 32, 4, 1.6), coal, seed: 20)
            b.body(rrect(39, 93, 22, 17, 2.4), coal, seed: 21)
            b.flat(rrect(39, 95, 22, 4, 0), scarf, seed: 22)
        } else {
            let hat = smooth([36, 92, 64, 92, 61, 104, 50, 109, 39, 104], t: 0.7)
            b.body(hat, scarf, seed: 20)
            b.body(rrect(35, 89, 30, 6, 3), PropTone(0xfff6ee, .cream), seed: 21)
            b.body(circ(50, 110, 4.4), PropTone(0xfff6ee, .cream), seed: 22)
        }
    }

    static func igloo(_ b: PropBrush, _ stage: Int, _ v: Int) {
        let ice = PropTone(v == 1 ? 0xe6f2ff : 0xf4f7ff, .cream)
        let rx: CGFloat = 46, ry: CGFloat = 58
        let tops: [CGFloat] = [18, 32, 46, ry, ry]
        let top = tops[stage]
        let shape: CGPath
        if stage >= 3 {
            shape = ell(50, 4, rx, ry).intersection(rrect(0, 4, 100, 70, 0))
        } else {
            var pts: [CGPoint] = [pt(4, 4)]
            let n = 9
            for i in 0...n {
                let u = CGFloat(i) / CGFloat(n)
                let x = 4 + 92 * u
                let dome = ry * sqrt(max(0, 1 - pow((x - 50) / rx, 2)))
                let cap = min(dome, top - (i % 2 == 0 ? 0 : 7))
                pts.append(pt(x, 4 + max(8, cap)))
            }
            pts.append(pt(96, 4))
            shape = polyP(pts)
        }
        b.body(shape, ice, seed: 1)
        if !b.tiny {
            let rows: [CGFloat] = [20, 36, 50]
            b.clip(shape) {
                for (i, y) in rows.enumerated() where y < top + 4 {
                    b.mark(line(0, y, 100, y), on: ice, alpha: 0.55, seed: i)
                    let half = rx * sqrt(max(0, 1 - pow((y - 4) / ry, 2)))
                    let step: CGFloat = b.small ? 30 : 18
                    var x = 50 - half + (i % 2 == 0 ? step * 0.5 : step)
                    while x < 50 + half {
                        b.mark(line(x, y - 16, x, y), on: ice, alpha: 0.45, seed: Int(x))
                        x += step
                    }
                }
            }
        }
        guard stage == 4 else { return }
        let door = ell(50, 4, 19, 27).intersection(rrect(0, 4, 100, 40, 0))
        b.body(door, ice, seed: 2)
        b.inkFill(ell(50, 4, 11, 19).intersection(rrect(0, 4, 100, 40, 0)))
        b.shine(30, 46, 5, 3, 0.5)
        if v == 2, !b.small {
            b.flat(smooth([60, 60, 72, 58, 74, 54, 62, 55], t: 0.5), PropTone(0xe8453c, .red), seed: 3)
        }
    }

    static let papers: [(PropTone, PropTone)] = [
        (PropTone(0xe8453c, .red), PropTone(0xf6d25a, .cream)),
        (PropTone(0x3fae5a, .ink), PropTone(0xe8453c, .red)),
        (PropTone(0x4a86e8, .cream), PropTone(0xfff6ee, .red)),
        (PropTone(0x9a6ad8, .ink), PropTone(0xf6d25a, .cream)),
        (PropTone(0xff8fb0, .red), PropTone(0x7fe0c8, .cream)),
    ]

    static func present(_ b: PropBrush, _ v: Int) {
        let (paper, ribbon) = papers[v]
        box(b, x: 14, y: 4, w: 72, h: 66, rot: 0, paper: paper, ribbon: ribbon, bow: true, seed: 1)
        b.shine(24, 50, 4, 2.6, 0.5)
        b.face(50, 34, 3.2, spread: 18)
    }

    static func giftStack(_ b: PropBrush, _ stage: Int, _ v: Int) {
        let boxes: [(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (6, 4, 50, 44, -0.02),
            (56, 4, 38, 34, 0.03),
            (22, 46, 46, 34, -0.06),
            (66, 36, 26, 22, 0.1),
            (34, 79, 28, 22, 0.08),
        ]
        guard stage >= 1 else { return }
        let order = [0, 1, 2, 3]
        for n in 0..<min(4, stage) {
            let i = order[n]
            let bx = boxes[i]
            let (paper, ribbon) = papers[(v + i * 2) % papers.count]
            box(b, x: bx.0, y: bx.1, w: bx.2, h: bx.3, rot: bx.4, paper: paper, ribbon: ribbon, bow: n == min(4, stage) - 1 && !b.tiny, seed: i * 10)
        }
    }

    static func tree(_ b: PropBrush, _ stage: Int, _ v: Int) {
        let greens: [UInt32] = [0x2f9a52, 0x2a8a6a, 0x3aa85a, 0x267a48]
        let needles = PropTone(greens[v], .ink)
        b.body(rrect(44, 4, 12, 14, 2), PropTone(0x8a5a30, .ink), seed: 1)
        let tiers: [(CGFloat, CGFloat, CGFloat)] = [(14, 34, 52), (22, 30, 70), (31, 25, 88)]
        var tierPaths: [CGPath] = []
        for (i, t) in tiers.enumerated() {
            let base = i == 0 ? CGFloat(14) : tiers[i - 1].2 - 22
            let hw = 50 - t.0
            var pts: [CGPoint] = [pt(50, t.2)]
            let scallops = 3
            for j in 0...scallops * 2 {
                let u = CGFloat(j) / CGFloat(scallops * 2)
                let x = 50 + hw - 2 * hw * u
                pts.append(pt(x, base + (j % 2 == 1 ? -3 : 1)))
            }
            let p = smoothP(pts, t: 0.45)
            tierPaths.append(p)
            b.body(p, needles, seed: 2 + i)
            if b.style == .kawaii || b.style == .mascot {
                b.rim(p)
            }
        }
        if v == 2, !b.small {
            for p in tierPaths.prefix(2) {
                let bb = p.boundingBoxOfPath
                b.plain(smooth([bb.minX + 6, bb.minY + 6, bb.midX, bb.minY + 2, bb.maxX - 6, bb.minY + 6, bb.midX, bb.minY + 9], t: 0.6), snow)
            }
        }
        if stage >= 1 {
            let baubles: [(CGFloat, CGFloat)] = [(34, 26), (62, 22), (48, 38), (40, 52), (60, 47), (52, 64), (44, 72)]
            let colours: [(UInt32, InkRole)] = [(0xe8453c, .red), (0xf6d25a, .cream), (0x4a86e8, .cream), (0xff8fb0, .red)]
            if !b.small, stage >= 2 {
                b.stick(smooth([24, 30, 50, 22, 76, 30], closed: false), PropTone(0xf6d25a, .cream), w: 2.2, seed: 9)
                b.stick(smooth([30, 52, 50, 46, 68, 52], closed: false), PropTone(0xf6d25a, .cream), w: 2.2, seed: 10)
            }
            for (i, p) in baubles.enumerated() {
                let c = colours[(i + v) % colours.count]
                b.dot(p.0, p.1, b.small ? 5.5 : 4.4, PropTone(c.0, c.1), seed: 20 + i)
            }
        }
        if stage >= 3 {
            let star = softStar(50, 91, 11, points: 5, inner: 0.46, t: 0.25)
            b.body(star, PropTone(0xffd84a, .red), seed: 30)
            b.shine(47, 94, 2, 1.4, 0.5)
        }
    }
}
