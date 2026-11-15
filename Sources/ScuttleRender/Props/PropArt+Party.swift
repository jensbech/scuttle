import Foundation
import CoreGraphics
import ScuttleCore

struct PropFlame {
    var x: CGFloat
    var base: CGFloat
    var w: CGFloat
    var h: CGFloat
}

struct PropGlow {
    var x: CGFloat
    var y: CGFloat
    var r: CGFloat
    var strength: CGFloat
}

extension PropArt {
    static func flames(_ kind: PropKind, stage: Int) -> [PropFlame] {
        switch kind {
        case .campfire:
            if stage == 2 { return [PropFlame(x: 50, base: 18, w: 28, h: 34)] }
            if stage >= 3 { return [PropFlame(x: 50, base: 16, w: 50, h: 76)] }
            return []
        case .cake where stage >= 3:
            return [PropFlame(x: 40, base: 81, w: 7, h: 12), PropFlame(x: 50, base: 83, w: 7, h: 12), PropFlame(x: 60, base: 81, w: 7, h: 12)]
        case .lantern:
            return [PropFlame(x: 50, base: 37, w: 8, h: 14)]
        default:
            return []
        }
    }

    static func glows(_ kind: PropKind, stage: Int) -> [PropGlow] {
        switch kind {
        case .campfire:
            if stage == 2 { return [PropGlow(x: 50, y: 26, r: 56, strength: 0.44)] }
            if stage >= 3 { return [PropGlow(x: 50, y: 34, r: 88, strength: 0.62)] }
            return []
        case .pumpkin where stage >= 3:
            return [PropGlow(x: 50, y: 34, r: 66, strength: 0.4)]
        case .cake where stage >= 3:
            return [PropGlow(x: 50, y: 88, r: 46, strength: 0.25)]
        case .lantern:
            return [PropGlow(x: 50, y: 44, r: 66, strength: 0.34)]
        case .tree where stage >= 3:
            return [PropGlow(x: 50, y: 91, r: 26, strength: 0.28)]
        default:
            return []
        }
    }

    static func cake(_ b: PropBrush, _ stage: Int, _ v: Int) {
        let icings: [(UInt32, InkRole)] = [(0xff9ec0, .red), (0x7a4a2e, .ink), (0xfff6ee, .cream), (0x8fe0c8, .cream)]
        let icing = PropTone(icings[v].0, icings[v].1)
        let sponge = PropTone(v == 1 ? 0xd9a05a : 0xf6d8a0, .cream)
        b.body(ell(50, 7, 42, 5), PropTone(0xf2f0f8, .cream), seed: 1)
        func tier(_ x0: CGFloat, _ x1: CGFloat, _ y0: CGFloat, _ y1: CGFloat, seed: Int) {
            let body = rrect(x0, y0, x1 - x0, y1 - y0, 4)
            b.body(body, sponge, seed: seed)
            let drips = Int((x1 - x0) / 12)
            var pts: [CGPoint] = [pt(x0, y1 + 1), pt(x1, y1 + 1)]
            for i in 0...drips {
                let u = CGFloat(i) / CGFloat(drips)
                let x = x1 - (x1 - x0) * u
                pts.append(pt(x, y1 - (i % 2 == 0 ? 5 : 11)))
            }
            let top = smoothP(pts, t: 0.55)
            b.flat(top, icing, seed: seed + 1)
            if !b.small, stage >= 2 {
                b.mark(line(x0 + 3, (y0 + y1) / 2 - 2, x1 - 3, (y0 + y1) / 2 - 2), on: sponge, alpha: 0.5, seed: seed + 2)
            }
        }
        tier(16, 84, 8, 42, seed: 2)
        if stage >= 1 { tier(28, 72, 42, 66, seed: 5) }
        if stage == 0 { b.face(50, 24, 3.2, spread: 14) }
        if stage >= 2 {
            let top: CGFloat = 66
            for (i, x) in ([34, 50, 66] as [CGFloat]).enumerated() {
                b.body(circ(x, top + 4, 5.5), PropTone(0xe8453c, .red), seed: 10 + i)
                if !b.small { b.shine(x - 1.8, top + 6, 1.4, 1, 0.5) }
            }
            if !b.small {
                let sprinkle: [(CGFloat, CGFloat, UInt32)] = [(24, 36, 0x4a86e8), (40, 30, 0xf6d25a), (62, 34, 0x3fae5a), (74, 28, 0xe8453c), (52, 22, 0x9a6ad8)]
                for s in sprinkle {
                    b.stick(line(s.0 - 2, s.1, s.0 + 2, s.1 + 1.5), PropTone(s.2, .cream), w: 1.6)
                }
            }
            b.face(50, 24, 3.2, spread: 14)
        }
        if stage >= 3 {
            let wax: [(UInt32, InkRole)] = [(0x7ec8f0, .cream), (0xfff2dc, .red), (0xff9ec0, .cream)]
            for (i, x) in ([40, 50, 60] as [CGFloat]).enumerated() {
                let top: CGFloat = i == 1 ? 82 : 80
                b.flat(rrect(x - 2.6, 66, 5.2, top - 66, 1.2), PropTone(wax[i].0, wax[i].1), seed: 20 + i)
                b.ink(line(x, top, x, top + 2.5), w: 1)
            }
        }
    }

    static func balloon(_ b: PropBrush, _ v: Int) {
        let colours: [(UInt32, InkRole)] = [(0xe8453c, .red), (0x4a86e8, .ink), (0xf6d25a, .cream), (0x3fae5a, .ink), (0xff8fc0, .red)]
        let skin = PropTone(colours[v].0, colours[v].1)
        b.stick(smooth([50, 46, 47, 34, 53, 22, 48, 12, 50, 4], closed: false), PropTone(0xf2f0f8, .cream), w: 1.6, seed: 1)
        let body = smooth([50, 47, 64, 56, 70, 72, 64, 90, 50, 97, 36, 90, 30, 72, 36, 56], t: 1)
        b.flat(poly([50, 49, 45, 43, 55, 43]), skin, seed: 2)
        b.body(body, skin, seed: 3)
        b.shine(41, 82, 3.2, 6, 0.45)
    }

    static func pennant(_ b: PropBrush, _ v: Int) {
        let colours: [(UInt32, InkRole)] = [(0xe8453c, .red), (0xf6d25a, .cream), (0x4a86e8, .ink), (0x3fae5a, .red), (0xff8fc0, .cream)]
        let c = colours[((v % 5) + 5) % 5]
        b.body(smooth([22, 94, 78, 94, 50, 18], t: 0.15), PropTone(c.0, c.1), seed: v)
        if !b.small, b.style != .hose {
            b.dot(50, 74, 6, PropTone(0xfff8f0, .cream), seed: v + 9)
        }
    }

    static func coil(_ b: PropBrush) {
        let rope = PropTone(0xd4a464, .cream)
        let loops: [(CGFloat, CGFloat)] = [(16, 38), (32, 34), (48, 30), (62, 26)]
        for (i, l) in loops.enumerated() {
            b.stick(ell(50, l.0, l.1, 11), rope, w: 9, seed: i)
        }
        b.stick(smooth([76, 62, 90, 40, 96, 12], closed: false), rope, w: 9, seed: 5)
        if !b.small {
            for (i, l) in loops.enumerated() {
                for k in 0..<5 {
                    let a = CGFloat(k) / 5 * .pi + 0.3 + CGFloat(i)
                    let x = 50 + cos(a) * l.1, y = l.0 - sin(a) * 9
                    b.mark(line(x - 2, y - 2, x + 2, y + 2), on: rope, alpha: 0.7, seed: k)
                }
            }
        }
    }

    static func campfire(_ b: PropBrush, _ stage: Int, _ v: Int) {
        let stone = PropTone(v == 1 ? 0xa8a4b8 : 0x9a96a8, .cream)
        let wood = PropTone(0x8a5a30, .ink)
        let cut = PropTone(0xe8c08a, .cream)
        if stage == 1 {
            b.stick(line(30, 8, 54, 56), wood, w: 6, seed: 1)
            b.stick(line(70, 8, 46, 56), wood, w: 6, seed: 2)
            b.stick(line(50, 6, 50, 58), wood, w: 6, seed: 3)
        }
        let logs: [(CGFloat, CGFloat)] = stage == 0 ? [(-0.08, 0)] : [(-0.32, 0), (0.32, 1)]
        if stage == 0 {
            b.stick(line(62, 22, 86, 30), wood, w: 5, seed: 8)
        }
        for l in logs {
            b.with(about(50, 14, rot: l.0)) {
                b.body(rrect(18, 9, 64, 11, 5.5), wood, seed: 4 + Int(l.1))
                b.flat(ell(l.0 < 0 ? 20 : 80, 14.5, 3.6, 5.2), cut, seed: 6 + Int(l.1))
            }
        }
        if stage >= 2 {
            b.plain(ell(50, 13, 16, 5), PropTone(0xff8a2a, .red))
        }
        let stones: [(CGFloat, CGFloat, CGFloat)] = [(12, 8, 9), (28, 5, 9), (50, 4, 9), (72, 5, 9), (88, 8, 9)]
        for (i, s) in stones.enumerated() {
            b.body(ell(s.0, s.1 + 3, s.2, 5.5), stone, seed: 10 + i)
        }
    }
}
