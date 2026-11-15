import Foundation
import CoreGraphics
import ScuttleCore

extension PropArt {
    static func acorn(_ b: PropBrush, _ v: Int) {
        let nuts: [UInt32] = [0xd08f4e, 0xe0aa5c, 0xbf6e3e, 0xc79a52]
        let nut = PropTone(nuts[v], .cream)
        let cap = PropTone(v == 2 ? 0x8a5a30 : 0x6e4526, .ink)
        let body = smooth([50, 4, 63, 10, 73, 27, 74, 45, 68, 58, 32, 58, 26, 45, 27, 27, 37, 10], t: 0.9)
        b.body(body, nut, seed: 1)
        b.shine(37, 38, 4.5, 8, 0.25)
        let tilt: CGFloat = [0, -0.08, 0.06, 0.12][v]
        b.with(about(50, 55, rot: tilt)) {
            let capShape = smooth([16, 56, 30, 51, 50, 49, 70, 51, 84, 56, 82, 69, 69, 80, 50, 84, 31, 80, 18, 69], t: 0.9)
            b.stick(smooth([50, 82, 51, 91, 57, 96], closed: false), cap, w: 6, seed: 3)
            b.body(capShape, cap, seed: 2)
            if !b.small {
                for (x, y) in [(36.0, 64.0), (50.0, 66.0), (64.0, 64.0), (43.0, 74.0), (57.0, 74.0)] as [(CGFloat, CGFloat)] {
                    b.mark(arc(x - 4, y, x + 4, y, dip: 2.6), on: cap, alpha: 0.85, seed: Int(x))
                }
            }
        }
    }

    static let leafColours: [[UInt32]] = [
        [0xf07a2a, 0xd9452b, 0xf2b630, 0xb5662f],
        [0xf2b630, 0xe8902a, 0xc2852f, 0xf5d24a],
        [0xd9452b, 0xa8302f, 0xf07a2a, 0xe8902a],
        [0xb5662f, 0xd08f4e, 0xf07a2a, 0x9a8a3a],
    ]

    static func leafTone(_ v: Int, _ i: Int) -> PropTone {
        let roles: [InkRole] = [.red, .ink, .cream, .red]
        return PropTone(leafColours[v][i % 4], roles[i % 4])
    }

    static func leafPile(_ b: PropBrush, _ stage: Int, _ v: Int) {
        if stage == 5 {
            let spots: [(CGFloat, CGFloat, CGFloat)] = [(6, 8, 0.4), (18, 16, -0.6), (90, 10, 2.2), (82, 18, 0.9), (30, 6, 2.8), (70, 5, -0.3)]
            for (i, s) in spots.enumerated() {
                b.flat(leafPath(s.0, s.1, 22, 8, s.2), leafTone(v, i), seed: 70 + i)
            }
        }
        if stage == 0 {
            let spots: [(CGFloat, CGFloat, CGFloat)] = [(28, 10, 0.3), (52, 7, -0.2), (72, 12, 0.9), (44, 18, 2.4)]
            for (i, s) in spots.enumerated() {
                let leaf = leafPath(s.0, s.1, 30, 11, s.2)
                b.body(leaf, leafTone(v, i), seed: i)
                if !b.small { b.mark(line(s.0 - 11 * cos(s.2), s.1 - 11 * sin(s.2), s.0 + 11 * cos(s.2), s.1 + 11 * sin(s.2)), on: leafTone(v, i), alpha: 0.6) }
            }
            return
        }
        let heights: [CGFloat] = [0, 36, 54, 72, 90, 40]
        let halves: [CGFloat] = [0, 34, 44, 54, 62, 52]
        let h = heights[stage], hw = halves[stage]
        var outline: [CGPoint] = []
        let n = 9 + stage * 2
        for i in 0...n {
            let u = CGFloat(i) / CGFloat(n)
            let a = CGFloat.pi * (1 - u)
            let bump: CGFloat = i % 2 == 0 ? 1 : 0.9
            outline.append(pt(50 + hw * cos(a) * (i == 0 || i == n ? 1.02 : bump), 4 + (h - 4) * pow(sin(a), 0.8) * bump))
        }
        let heap = smoothP(outline, t: 0.8)
        b.body(heap, leafTone(v, 0), seed: 10)
        var r = Noise(stage * 31 + v * 7 + 3)
        let count = b.small ? 4 + stage : 6 + stage * 3
        for i in 0..<count {
            let u = r.range(0.08, 0.92)
            let a = CGFloat.pi * (1 - u)
            let depth = r.range(0.55, 0.98)
            let x = 50 + hw * cos(a) * depth
            let y = 4 + (h - 4) * pow(sin(a), 0.8) * depth
            let rot = a - .pi / 2 + r.range(-0.9, 0.9)
            let len = b.small ? 30 : r.range(20, 26)
            b.flat(leafPath(x, y, len, len * 0.38, rot), leafTone(v, i + 1), seed: 20 + i)
        }
        b.flat(leafPath(50 - hw - 4, 7, 22, 8, -0.3), leafTone(v, 2), seed: 60)
        b.flat(leafPath(50 + hw + 2, 6, 20, 7, 0.5), leafTone(v, 3), seed: 61)
        if stage >= 3, stage < 5 {
            b.stick(smooth([50 + hw * 0.1, h - 2, 50 + hw * 0.16, h + 9, 50 + hw * 0.24, h + 12], closed: false), PropTone(0x7a4a26, .ink), w: 3, seed: 62)
            b.flat(leafPath(50 + hw * 0.3, h + 12, 18, 7, 0.4), leafTone(v, 1), seed: 63)
        }
    }

    static func pumpkin(_ b: PropBrush, _ stage: Int, _ v: Int) {
        let skins: [(UInt32, InkRole)] = [(0xff8a2a, .red), (0xf06a1a, .red), (0xf3e4c8, .cream), (0xffb43a, .red)]
        let skin = PropTone(skins[v].0, skins[v].1)
        let stem = PropTone(v == 2 ? 0x6f8f3a : 0x7a5a2a, .ink)
        b.stick(smooth([52, 64, 53, 78, 58, 86], closed: false), stem, w: 9, seed: 9)
        let lobes = uni([ell(50, 36, 21, 32), ell(33, 35, 19, 30), ell(67, 35, 19, 30)])
        b.body(lobes, skin, seed: 1)
        b.mark(smooth([41, 64, 36, 36, 41, 6], closed: false), on: skin, alpha: 0.75, seed: 2)
        b.mark(smooth([59, 64, 64, 36, 59, 6], closed: false), on: skin, alpha: 0.75, seed: 3)
        b.shine(26, 46, 3.5, 7, 0.2)
        if !b.small {
            let leaf = PropTone(0x5fae4a, .ink)
            b.flat(leafPath(66, 72, 22, 8, 0.35), leaf, seed: 4)
            b.mark(smooth([56, 76, 50, 80, 46, 76, 48, 72], closed: false), on: leaf, w: 1.8, seed: 5)
        }
        guard stage >= 1 else { return }
        let lit = stage >= 3
        let glowTone = PropTone(0xffd04a, .cream)
        func cut(_ path: CGPath) {
            if lit { b.flat(path, glowTone, seed: 30) } else { b.inkFill(path) }
        }
        cut(polyP([pt(33, 40), pt(46, 40), pt(40, 52)]))
        cut(polyP([pt(54, 40), pt(67, 40), pt(60, 52)]))
        if stage >= 2 {
            cut(polyP([pt(46, 30), pt(54, 30), pt(50, 37)]))
            cut(polyP([pt(28, 24), pt(36, 21), pt(40, 25), pt(46, 20), pt(50, 24), pt(54, 20), pt(60, 25), pt(64, 21), pt(72, 24), pt(66, 13), pt(50, 9), pt(34, 13)]))
        }
    }

    static func candy(_ b: PropBrush, _ v: Int) {
        switch v {
        case 0, 1:
            let main = PropTone(v == 0 ? 0xff7aa8 : 0x5fd6b0, v == 0 ? .red : .cream)
            let stripe = PropTone(0xfff6ee, v == 0 ? .cream : .red)
            let left = smooth([30, 34, 8, 54, 4, 34, 8, 14], t: 0.5)
            let right = smooth([70, 34, 92, 54, 96, 34, 92, 14], t: 0.5)
            b.flat(left, main, seed: 1)
            b.flat(right, main, seed: 2)
            let ball = ell(50, 34, 26, 24)
            b.body(ball, main, seed: 3)
            if !b.tiny {
                b.clip(ball) {
                    for k in -1...1 {
                        let x = 50 + CGFloat(k) * 17
                        b.plain(smooth([x - 4, 8, x + 6, 8, x + 4, 60, x - 6, 60], t: 0.4), stripe)
                    }
                }
                b.edge(ball, main, seed: 3)
            }
            b.shine(40, 45, 5, 3.5, 0.4)
        case 2:
            let stickTone = PropTone(0xfff4e8, .cream)
            b.stick(line(50, 6, 50, 52), stickTone, w: 6, seed: 4)
            let disc = circ(50, 66, 28)
            b.body(disc, PropTone(0xff6f91, .red), seed: 5)
            b.clip(disc) {
                b.stick(spiral(50, 66, 26, turns: 2.2, spin: 1, start: 0.5), PropTone(0xfff4e8, .cream), w: b.small ? 7 : 5, seed: 6)
            }
            b.shine(40, 78, 5, 3.5, 0.6)
        default:
            let corn = smooth([50, 92, 58, 70, 74, 18, 66, 6, 34, 6, 26, 18, 42, 70], t: 0.55)
            b.body(corn, PropTone(0xfff2dc, .cream), seed: 7)
            b.clip(corn) {
                b.plain(rrect(10, 0, 80, 26, 0), PropTone(0xffc23a, .red))
                b.plain(rrect(10, 26, 80, 30, 0), PropTone(0xff8a2a, .red))
            }
            b.edge(corn, PropTone(0xff8a2a, .red), seed: 7)
        }
    }

    static func lantern(_ b: PropBrush, _ v: Int) {
        let frames: [(UInt32, InkRole)] = [(0xc8402e, .red), (0x40508a, .ink), (0x2f7a4a, .ink), (0xc89a3a, .red)]
        let frame = PropTone(frames[v].0, frames[v].1)
        let glass = PropTone(0xffe7a0, .cream)
        b.stick(smooth([38, 84, 40, 97, 50, 100, 60, 97, 62, 84], closed: false), frame, w: 4, seed: 1)
        b.body(rrect(30, 4, 40, 14, 4), frame, seed: 2)
        let pane = rrect(33, 17, 34, 58, 5)
        b.flat(pane, glass, seed: 3)
        b.clip(pane) {
            b.fill(circ(50, 38, 22), Tone(0xffffff, b.style == .hose ? 0 : 0.35))
        }
        b.flat(rrect(45, 19, 10, 18, 2), PropTone(0xfff6ea, .cream), seed: 4)
        if !b.small {
            b.stick(line(50, 17, 50, 75), frame, w: 2.2, seed: 5)
        }
        b.body(smooth([28, 74, 72, 74, 64, 86, 36, 86], t: 0.3), frame, seed: 6)
        b.flat(circ(50, 88, 4), frame, seed: 7)
    }

    static func crumb(_ b: PropBrush, _ stage: Int, _ v: Int) {
        if stage < 2 {
            let k: CGFloat = stage == 0 ? 0.5 : 1
            b.with(about(50, 4, sx: k, sy: k)) { crumbBody(b, v, bite: true) }
            return
        }
        crumbBody(b, v, bite: false)
    }

    static func crumbBody(_ b: PropBrush, _ v: Int, bite: Bool) {
        let looks: [(UInt32, InkRole, UInt32)] = [(0xd99a52, .cream, 0x5a3420), (0xf0d49a, .cream, 0xc2853f), (0xf6c8d6, .red, 0xfff4f0)]
        let (base, role, speck) = looks[v]
        let shapes: [[CGFloat]] = [
            [16, 10, 46, 4, 82, 12, 92, 40, 78, 70, 50, 78, 22, 66, 8, 38],
            [12, 14, 40, 6, 76, 4, 94, 30, 86, 62, 56, 72, 28, 70, 10, 44],
            [20, 6, 60, 6, 90, 22, 88, 56, 66, 76, 30, 74, 10, 48, 10, 22],
        ]
        var shape = smooth(shapes[v], t: 0.5)
        if bite { shape = shape.subtracting(uni([circ(84, 62, 20), circ(70, 76, 14)])) }
        b.body(shape, PropTone(base, role), seed: 1)
        if v == 2 {
            b.flat(smooth([24, 60, 50, 72, 78, 62, 82, 74, 52, 80, 22, 72], t: 0.6), PropTone(0xff8fb0, .red), seed: 2)
        } else {
            let dots: [(CGFloat, CGFloat, CGFloat)] = [(36, 34, 9), (64, 46, 8), (54, 20, 6)]
            for d in dots {
                b.dot(d.0, d.1, d.2, PropTone(speck, v == 0 ? .ink : .red), seed: Int(d.0))
            }
        }
    }
}
