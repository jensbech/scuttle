import Foundation
import CoreGraphics
import ScuttleCore

enum PropArt: FigureShapes {
    static func thresholds(_ kind: PropKind) -> [Double] {
        switch kind {
        case .snowman: return [0.6, 0.79, 0.84, 0.89, 0.94, 0.999]
        case .igloo: return [0.25, 0.5, 0.71, 0.999]
        case .tree: return [0.2, 0.55, 0.999]
        case .giftStack: return [0.24, 0.49, 0.74, 0.99]
        case .leafPile: return [0.15, 0.4, 0.65, 0.88]
        case .nest: return [0.3, 0.7]
        case .sandcastle: return [0.3, 0.6, 0.999]
        case .campfire: return [0.4, 0.79, 0.999]
        case .pumpkin: return [0.2, 0.5, 0.999]
        case .cake: return [0.3, 0.6, 0.999]
        case .snowball: return [0.5]
        case .flower: return [0.3, 0.65]
        case .crumb: return [0.4, 0.8]
        default: return []
        }
    }

    static func stages(_ kind: PropKind) -> Int {
        kind == .leafPile ? 6 : thresholds(kind).count + 1
    }

    static func stage(_ kind: PropKind, progress: Double) -> Int {
        let p = progress.isFinite ? max(0, min(1, progress)) : 1
        var n = 0
        for t in thresholds(kind) where p >= t { n += 1 }
        return n
    }

    static func variants(_ kind: PropKind) -> Int {
        switch kind {
        case .rope, .banner: return 1
        case .present, .balloon: return 5
        case .crumb, .nest, .sandcastle, .igloo, .campfire: return 3
        default: return 4
        }
    }

    static func variant(_ kind: PropKind, _ v: Int) -> Int {
        let n = variants(kind)
        return ((v % n) + n) % n
    }

    static func draw(_ kind: PropKind, stage: Int, variant v: Int, _ b: PropBrush) {
        switch kind {
        case .acorn: acorn(b, v)
        case .leafPile: leafPile(b, stage, v)
        case .pumpkin: pumpkin(b, stage, v)
        case .candy: candy(b, v)
        case .lantern: lantern(b, v)
        case .snowball: snowball(b, stage, v)
        case .snowman: snowman(b, stage, v)
        case .igloo: igloo(b, stage, v)
        case .present: present(b, v)
        case .giftStack: giftStack(b, stage, v)
        case .tree: tree(b, stage, v)
        case .egg: egg(b, v)
        case .flower: flower(b, stage, v)
        case .nest: nest(b, stage, v)
        case .shell: shell(b, v)
        case .sandcastle: sandcastle(b, stage, v)
        case .ball: ball(b, v)
        case .rope: coil(b)
        case .cake: cake(b, stage, v)
        case .balloon: balloon(b, v)
        case .banner: pennant(b, v)
        case .campfire: campfire(b, stage, v)
        case .crumb: crumb(b, stage, v)
        }
    }

    static func leafPath(_ cx: CGFloat, _ cy: CGFloat, _ len: CGFloat, _ wid: CGFloat, _ rot: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.move(to: pt(-len / 2, 0))
        p.addQuadCurve(to: pt(len / 2, 0), control: pt(-len * 0.05, wid))
        p.addQuadCurve(to: pt(-len / 2, 0), control: pt(-len * 0.05, -wid))
        p.closeSubpath()
        return xf(p, CGAffineTransform(translationX: cx, y: cy).rotated(by: rot))
    }

    static func box(_ b: PropBrush, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, rot: CGFloat, paper: PropTone, ribbon: PropTone, bow: Bool, seed: Int) {
        b.with(about(x + w / 2, y, rot: rot)) {
            let lidH = min(h * 0.26, 12)
            let r = min(w, h) * 0.08
            let base = rrect(x + w * 0.04, y, w * 0.92, h - lidH * 0.6, r)
            b.body(base, paper, seed: seed)
            let band = max(w * 0.14, 3 * b.pt)
            b.flat(rrect(x + w / 2 - band / 2, y, band, h - lidH * 0.6, 0), ribbon, seed: seed + 1)
            let lid = rrect(x, y + h - lidH, w, lidH, r)
            b.body(lid, paper, seed: seed + 2)
            b.flat(rrect(x + w / 2 - band / 2, y + h - lidH, band, lidH, 0), ribbon, seed: seed + 3)
            if bow {
                let k = min(w, 44) / 44
                let by = y + h
                b.flat(smooth([x + w / 2, by + 1, x + w / 2 - 14 * k, by + 11 * k, x + w / 2 - 15 * k, by + 1 * k], t: 0.6), ribbon, seed: seed + 4)
                b.flat(smooth([x + w / 2, by + 1, x + w / 2 + 14 * k, by + 11 * k, x + w / 2 + 15 * k, by + 1 * k], t: 0.6), ribbon, seed: seed + 5)
                b.flat(circ(x + w / 2, by + 2 * k, 4 * k), ribbon, seed: seed + 6)
            }
        }
    }

    static func flameShape(_ cx: CGFloat, _ base: CGFloat, _ w: CGFloat, _ h: CGFloat, lean: CGFloat, tips: [CGFloat]) -> CGPath {
        let n = tips.count
        var pts: [CGPoint] = [pt(cx + w * 0.5, base + h * 0.18)]
        pts.append(pt(cx + w * 0.42, base + h * 0.02))
        pts.append(pt(cx, base - h * 0.04))
        pts.append(pt(cx - w * 0.42, base + h * 0.02))
        pts.append(pt(cx - w * 0.5, base + h * 0.18))
        for i in 0..<n {
            let u = (CGFloat(i) + 0.5) / CGFloat(n)
            let x = cx - w * 0.5 + w * u
            let centre = 1 - abs(u - 0.5) * 1.3
            let top = base + h * (0.45 + 0.55 * centre) * tips[i]
            pts.append(pt(x + lean * (top - base) * 0.3, top))
            if i < n - 1 {
                let xm = cx - w * 0.5 + w * (CGFloat(i) + 1) / CGFloat(n)
                pts.append(pt(xm + lean * h * 0.1, base + h * (0.38 + 0.3 * centre)))
            }
        }
        return smoothP(pts, t: 0.85)
    }

    static func flame(_ b: PropBrush, cx: CGFloat, base: CGFloat, w: CGFloat, h: CGFloat, frame: Int) {
        var r = Noise(frame &* 131 &+ 7)
        let tips = (0..<3).map { _ in r.range(0.7, 1.05) }
        let lean = r.range(-0.35, 0.35)
        let outer = flameShape(cx, base, w, h, lean: lean, tips: tips)
        let mid = flameShape(cx, base + h * 0.02, w * 0.66, h * 0.7, lean: lean * 1.2, tips: tips.map { min(1.1, $0 * r.range(0.85, 1.1)) })
        let core = flameShape(cx, base + h * 0.03, w * 0.34, h * 0.38, lean: lean, tips: [1])
        let red = PropTone(0xff5a2a, .red), orange = PropTone(0xffa62e, .cream), yellow = PropTone(0xfff2a0, .cream)
        switch b.style {
        case .kawaii:
            b.plain(outer, PropTone(0xff7a4a, .red))
            b.plain(mid, PropTone(0xffc04a, .cream))
            b.plain(core, PropTone(0xfff8d0, .cream))
        case .hose:
            b.flat(outer, red)
            b.plain(mid, PropTone(0xf7eedb, .cream))
        case .doodle:
            b.flat(outer, red, seed: frame)
            b.plain(mid, orange)
            b.plain(core, yellow)
        default:
            b.flat(outer, red)
            b.plain(mid, orange)
            b.plain(core, yellow)
        }
    }

    static func flameFrames() -> Int { 6 }
}

public enum PropCatalog {
    public static func stages(_ kind: PropKind) -> Int { PropArt.stages(kind) }

    public static func variants(_ kind: PropKind) -> Int { PropArt.variants(kind) }

    public static func stage(_ kind: PropKind, progress: Double) -> Int { PropArt.stage(kind, progress: progress) }

    public static func progress(_ kind: PropKind, stage: Int) -> Double {
        let t = PropArt.thresholds(kind)
        guard !t.isEmpty else { return 1 }
        if stage <= 0 { return t[0] * 0.5 }
        if stage >= t.count { return 1 }
        return (t[stage - 1] + t[stage]) / 2
    }
}
