import Foundation
import CoreGraphics

enum GestureGeo: FigureShapes {}

enum InkRole {
    case red
    case cream
    case ink
}

struct GesturePen {
    let ctx: CGContext
    let style: ArtStyle
    let unit: CGFloat
    let boil: Int

    static let stickerInk = Tone(0x1d1630)
    static let hoseInk = Tone(0x17121a)
    static let hoseCream = Tone(0xf7eedb)
    static let hoseRed = Tone(0xd8402b)
    static let palette = [Tone(0xff6f91), Tone(0xffc93c), Tone(0x4fc3f7), Tone(0x7bd88f), Tone(0xb388ff)]
    static let roles: [InkRole] = [.red, .cream, .red, .ink, .cream]

    init(_ ctx: CGContext, style: ArtStyle, size: CGFloat, time: Double) {
        self.ctx = ctx
        self.style = style
        unit = max(0.75, size * 0.032)
        boil = Int((time * 7).rounded(.down))
    }

    var ink: Tone { style == .hose ? GesturePen.hoseInk : GesturePen.stickerInk }

    func tone(_ base: Tone, _ role: InkRole = .red) -> Tone {
        switch style {
        case .kawaii: return base.lift(0.38)
        case .sticker: return base.saturate(1.25)
        case .hose:
            switch role {
            case .red: return GesturePen.hoseRed
            case .cream: return GesturePen.hoseCream
            case .ink: return GesturePen.hoseInk
            }
        case .mascot: return base.saturate(1.15)
        case .doodle: return base.saturate(1.4)
        }
    }

    static let rim = Tone(0xf2efff)

    func accent(_ i: Int) -> Tone {
        let n = GesturePen.palette.count
        let k = ((i % n) + n) % n
        return tone(GesturePen.palette[k], GesturePen.roles[k])
    }

    func edge(_ base: Tone) -> Tone {
        switch style {
        case .mascot: return base.dim(0.32).mix(Tone(0x1a1030), 0.45)
        case .doodle: return base.saturate(1.6).dim(0.7)
        default: return ink
        }
    }

    func wobble(_ pts: [CGPoint], seed: Int, amp: CGFloat) -> [CGPoint] {
        let b = CGFloat(boil &+ seed &* 7)
        var out = pts
        for i in out.indices {
            let k = CGFloat(i)
            out[i].x += amp * sin(k * 2.17 + b * 1.31 + CGFloat(seed) * 0.37)
            out[i].y += amp * cos(k * 1.73 + b * 0.97 + CGFloat(seed) * 0.53)
        }
        return out
    }

    func path(_ pts: [CGPoint], closed: Bool, smooth: Bool, seed: Int = 0) -> CGPath {
        let use = style == .doodle ? wobble(pts, seed: seed, amp: unit * 0.35) : pts
        return smooth ? GestureGeo.smoothP(use, closed: closed) : GestureGeo.polyP(use, closed: closed)
    }

    func fill(_ p: CGPath, _ t: Tone, _ a: CGFloat) {
        guard t.a * a > 0.004 else { return }
        ctx.addPath(p)
        ctx.setFillColor(red: t.r, green: t.g, blue: t.b, alpha: t.a * a)
        ctx.fillPath()
    }

    func stroke(_ p: CGPath, _ t: Tone, _ w: CGFloat, _ a: CGFloat) {
        guard t.a * a > 0.004, w > 0 else { return }
        ctx.addPath(p)
        ctx.setStrokeColor(red: t.r, green: t.g, blue: t.b, alpha: t.a * a)
        ctx.setLineWidth(w)
        ctx.strokePath()
    }

    func shape(_ pts: [CGPoint], _ base: Tone, alpha a: CGFloat, smooth: Bool = true, w: CGFloat = 1, seed: Int = 0, shine: CGPoint? = nil) {
        guard a > 0.01, pts.count > 2 else { return }
        let lw = unit * w
        let p = path(pts, closed: true, smooth: smooth, seed: seed)
        switch style {
        case .kawaii:
            fill(p, base, a)
        case .sticker:
            stroke(p, .white, lw * 3.4, a * 0.9)
            fill(p, base, a)
            stroke(p, ink, lw, a)
        case .hose:
            stroke(p, GesturePen.hoseCream, lw * 3, a * 0.85)
            fill(p, base, a)
            stroke(p, GesturePen.hoseInk, lw, a)
        case .mascot:
            stroke(p, GesturePen.rim, lw * 3, a * 0.85)
            fill(p, base, a)
            stroke(p, edge(base), lw, a)
        case .doodle:
            let filled = GestureGeo.smoothP(wobble(pts, seed: seed &+ 11, amp: unit * 0.5), closed: true)
            fill(filled, base.lift(0.12), a * 0.85)
            stroke(p, edge(base), lw * 0.9, a)
        }
        if let s = shine, style != .doodle {
            let r = unit * 0.9
            fill(CGPath(ellipseIn: CGRect(x: s.x - r, y: s.y - r * 0.7, width: 2 * r, height: 1.4 * r), transform: nil), .white, a * 0.8)
        }
    }

    func mark(_ pts: [CGPoint], _ t: Tone, alpha a: CGFloat, w: CGFloat = 1, smooth: Bool = true, seed: Int = 0) {
        guard a > 0.01, pts.count > 1 else { return }
        let lw = unit * w
        let p = path(pts, closed: false, smooth: smooth, seed: seed)
        switch style {
        case .kawaii:
            stroke(p, t, lw, a)
        case .sticker:
            stroke(p, t.luma > 0.75 ? ink : .white, lw + unit * 1.6, a * 0.95)
            stroke(p, t, lw, a)
        case .hose:
            if t.luma < 0.2 {
                stroke(p, GesturePen.hoseCream, lw + unit * 1.4, a * 0.85)
            } else {
                stroke(p, GesturePen.hoseInk, lw + unit * 1.3, a)
            }
            stroke(p, t, lw, a)
        case .mascot:
            stroke(p, GesturePen.rim, lw + unit * 2.4, a * 0.8)
            stroke(p, edge(t), lw + unit * 1.1, a)
            stroke(p, t, lw, a)
        case .doodle:
            stroke(p, t, lw * 0.95, a)
        }
    }

    static func ring(_ c: CGPoint, _ rx: CGFloat, _ ry: CGFloat, n: Int = 10, rot: CGFloat = 0) -> [CGPoint] {
        let cr = cos(rot), sr = sin(rot)
        return (0..<n).map { i in
            let a = CGFloat(i) / CGFloat(n) * 2 * .pi
            let x = rx * cos(a), y = ry * sin(a)
            return CGPoint(x: c.x + x * cr - y * sr, y: c.y + x * sr + y * cr)
        }
    }

    static func star(_ c: CGPoint, _ r: CGFloat, points: Int = 4, inner: CGFloat = 0.42, spin: CGFloat = 0) -> [CGPoint] {
        (0..<(points * 2)).map { i in
            let rad = i % 2 == 0 ? r : r * inner
            let a = spin + .pi / 2 + CGFloat(i) * .pi / CGFloat(points)
            return CGPoint(x: c.x + rad * cos(a), y: c.y + rad * sin(a))
        }
    }
}
