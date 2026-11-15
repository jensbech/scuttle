import Foundation
import CoreGraphics
import ScuttleCore

struct PropTone {
    var base: Tone
    var role: InkRole

    init(_ hex: UInt32, _ role: InkRole = .red) {
        base = Tone(hex)
        self.role = role
    }

    init(_ base: Tone, _ role: InkRole) {
        self.base = base
        self.role = role
    }
}

final class PropBrush: FigureShapes {
    let style: ArtStyle
    let size: CGFloat
    let canvas: FigureCanvas
    private let kawaii: KawaiiKit?
    private let sticker: StickerKit?
    private let hose: HoseKit?
    private let mascot: MascotKit?
    private let doodle: DoodleKit?

    static let hoseInk = Tone(0x17121a)
    static let hoseCream = Tone(0xf7eedb)
    static let hoseRed = Tone(0xd8402b)

    init(_ ctx: CGContext, style: ArtStyle, size: CGFloat, boil: Int = 0) {
        self.style = style
        self.size = size
        let frame = FigureFrame(species: .acorn, style: style, variant: 0, phase: CGFloat(boil % 4) * 0.25, mood: .calm, size: size)
        switch style {
        case .kawaii:
            let k = KawaiiKit(ctx, frame)
            kawaii = k; sticker = nil; hose = nil; mascot = nil; doodle = nil
            canvas = k
        case .sticker:
            let k = StickerKit(ctx, frame)
            kawaii = nil; sticker = k; hose = nil; mascot = nil; doodle = nil
            canvas = k
        case .hose:
            let k = HoseKit(ctx, frame)
            kawaii = nil; sticker = nil; hose = k; mascot = nil; doodle = nil
            canvas = k
        case .mascot:
            let k = MascotKit(ctx, frame)
            kawaii = nil; sticker = nil; hose = nil; mascot = k; doodle = nil
            canvas = k
        case .doodle:
            let k = DoodleKit(ctx, frame)
            kawaii = nil; sticker = nil; hose = nil; mascot = nil; doodle = k
            canvas = k
        }
    }

    var ctx: CGContext { canvas.ctx }
    var pt: CGFloat { canvas.pt }
    var small: Bool { size < 17 }
    var tiny: Bool { size < 11 }
    var big: Bool { size >= 26 }

    var outlined: Bool { style == .sticker || style == .hose || style == .mascot }

    func tone(_ t: PropTone) -> Tone {
        switch style {
        case .kawaii: return t.base.lift(0.3)
        case .sticker: return t.base.saturate(1.12)
        case .hose:
            switch t.role {
            case .red: return PropBrush.hoseRed
            case .cream: return PropBrush.hoseCream
            case .ink: return PropBrush.hoseInk
            }
        case .mascot: return t.base.saturate(1.06)
        case .doodle: return t.base.saturate(1.2)
        }
    }

    func pen(_ t: Tone) -> Tone {
        let spread = max(t.r, t.g, t.b) - min(t.r, t.g, t.b)
        if t.luma > 0.8, spread < 0.2 { return Tone(0x6e78d8) }
        return t.saturate(1.5).dim(0.6)
    }

    var lineW: CGFloat {
        switch style {
        case .kawaii: return canvas.width(1.5, minPt: 0.6)
        case .sticker: return sticker!.line
        case .hose: return hose!.line
        case .mascot: return mascot!.line
        case .doodle: return doodle!.line
        }
    }

    var thinW: CGFloat {
        switch style {
        case .kawaii: return canvas.width(1.2, minPt: 0.5)
        case .sticker: return sticker!.thin
        case .hose: return hose!.line * 0.75
        case .mascot: return mascot!.line * 0.8
        case .doodle: return doodle!.thin
        }
    }

    func width(_ design: CGFloat, minPt: CGFloat) -> CGFloat { canvas.width(design, minPt: minPt) }

    func body(_ p: CGPath, _ t: PropTone, seed: Int = 0) {
        let c = tone(t)
        switch style {
        case .kawaii: kawaii!.body(p, c)
        case .sticker: sticker!.part(p, c)
        case .hose:
            if t.role == .ink { hose!.solid(p) } else { hose!.part(p, c) }
        case .mascot: mascot!.cel(p, MascotTones(c))
        case .doodle: doodle!.part(p, fill: c, line: pen(c), seed: seed)
        }
    }

    func flat(_ p: CGPath, _ t: PropTone, seed: Int = 0) {
        let c = tone(t)
        switch style {
        case .kawaii: canvas.fill(p, c)
        case .sticker: sticker!.flat(p, c, w: sticker!.thin)
        case .hose:
            if t.role == .ink { hose!.fill(p, c); hose!.stroke(p, c, hose!.line * 0.8) } else { hose!.part(p, c, w: hose!.line * 0.8) }
        case .mascot: mascot!.cel(p, MascotTones(c), mascot!.line * 0.8, k: 0.12)
        case .doodle: doodle!.part(p, fill: c, line: pen(c), seed: seed, w: doodle!.thin)
        }
    }

    func edge(_ p: CGPath, _ t: PropTone, seed: Int = 0) {
        let c = tone(t)
        switch style {
        case .kawaii: break
        case .sticker: canvas.stroke(p, sticker!.ink, sticker!.line)
        case .hose: canvas.stroke(p, PropBrush.hoseInk, hose!.line)
        case .mascot: canvas.stroke(p, MascotTones(c).line, mascot!.line)
        case .doodle: doodle!.marker(p, pen(c), doodle!.line, seed: seed)
        }
    }

    func plain(_ p: CGPath, _ t: PropTone) {
        canvas.fill(p, tone(t))
    }

    func stick(_ p: CGPath, _ t: PropTone, w: CGFloat, seed: Int = 0) {
        let c = tone(t)
        let lw = canvas.width(w, minPt: 0.7)
        switch style {
        case .kawaii:
            canvas.stroke(p, c, lw)
        case .sticker:
            canvas.stroke(p, sticker!.ink, lw + sticker!.thin * 1.6)
            canvas.stroke(p, c, lw)
        case .hose:
            canvas.stroke(p, PropBrush.hoseInk, lw + hose!.line * 1.4)
            if t.role != .ink { canvas.stroke(p, c, lw) }
        case .mascot:
            canvas.stroke(p, MascotTones(c).line, lw + mascot!.line * 1.3)
            canvas.stroke(p, c, lw)
        case .doodle:
            doodle!.marker(p, c.luma > 0.82 ? pen(c) : c, lw, seed: seed)
        }
    }

    func mark(_ p: CGPath, on t: PropTone, w: CGFloat? = nil, alpha: CGFloat = 1, seed: Int = 0) {
        let c = tone(t)
        let lw = w.map { canvas.width($0, minPt: 0.5) } ?? thinW
        switch style {
        case .kawaii: canvas.stroke(p, c.dim(0.78).mix(Tone(0x9d86d6), 0.2).alpha(alpha), lw)
        case .sticker: canvas.stroke(p, sticker!.ink.alpha(alpha), lw)
        case .hose: canvas.stroke(p, (t.role == .ink ? PropBrush.hoseCream : PropBrush.hoseInk).alpha(alpha), lw)
        case .mascot: canvas.stroke(p, MascotTones(c).line.alpha(alpha), lw)
        case .doodle: doodle!.marker(p, pen(c).alpha(alpha), lw, seed: seed)
        }
    }

    func ink(_ p: CGPath, w: CGFloat? = nil, seed: Int = 0) {
        let lw = w.map { canvas.width($0, minPt: 0.55) } ?? thinW
        switch style {
        case .kawaii: canvas.stroke(p, Tone(0x5a4660), lw)
        case .sticker: canvas.stroke(p, sticker!.ink, lw)
        case .hose: canvas.stroke(p, PropBrush.hoseInk, lw)
        case .mascot: canvas.stroke(p, Tone(0x2a1830), lw)
        case .doodle: doodle!.marker(p, doodle!.felt, lw, seed: seed)
        }
    }

    func inkFill(_ p: CGPath) {
        switch style {
        case .kawaii: canvas.fill(p, Tone(0x5a4660))
        case .sticker: canvas.fill(p, sticker!.ink)
        case .hose: canvas.fill(p, PropBrush.hoseInk)
        case .mascot: canvas.fill(p, Tone(0x2a1830))
        case .doodle: canvas.fill(p, doodle!.felt)
        }
    }

    func dot(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ t: PropTone, seed: Int = 0) {
        let c = tone(t)
        let p = Self.circ(x, y, r)
        switch style {
        case .kawaii: canvas.fill(p, c)
        case .sticker:
            canvas.fill(p, c)
            if r > 1.4 * pt { canvas.stroke(p, sticker!.ink, sticker!.thin * 0.7) }
        case .hose:
            canvas.fill(p, c)
            if t.role != .ink, r > 1.4 * pt { canvas.stroke(p, PropBrush.hoseInk, hose!.line * 0.6) }
        case .mascot:
            canvas.fill(p, c)
            if r > 1.4 * pt { canvas.stroke(p, MascotTones(c).line, mascot!.line * 0.6) }
        case .doodle: doodle!.dot(x, y, r, r, c, seed: seed)
        }
    }

    func shine(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ rot: CGFloat = 0.6) {
        switch style {
        case .kawaii: kawaii!.shine(x, y, rx, ry, rot)
        case .sticker: sticker!.gloss(x, y, rx, ry, rot)
        case .hose:
            let e = Self.ell(x, y, rx, ry, rot)
            let R = max(rx, ry) * 3
            let dir: CGFloat = -0.75
            let wedge = Self.polyP([CGPoint(x: x, y: y), CGPoint(x: x + cos(dir - 0.4) * R, y: y + sin(dir - 0.4) * R), CGPoint(x: x + cos(dir + 0.4) * R, y: y + sin(dir + 0.4) * R)])
            canvas.fill(e.subtracting(wedge), Tone.white.alpha(0.85))
        case .mascot:
            canvas.fill(Self.ell(x, y, rx, ry, rot), Tone(0xfffaf0, 0.75))
        case .doodle:
            let p = CGMutablePath()
            p.move(to: CGPoint(x: x - rx * 0.6, y: y - ry * 0.7))
            p.addQuadCurve(to: CGPoint(x: x + rx * 0.5, y: y + ry * 0.8), control: CGPoint(x: x - rx * 0.9, y: y + ry * 0.6))
            doodle!.marker(p, Tone.white.alpha(0.9), max(rx, ry) * 0.7, seed: 77)
        }
    }

    func rim(_ p: CGPath, alpha: CGFloat = 0.5) {
        guard style == .mascot else { return }
        let bb = p.boundingBoxOfPath
        canvas.clip(p) {
            let inner = Self.xf(p, CGAffineTransform(translationX: bb.width * 0.06, y: -bb.height * 0.06))
            canvas.fill(p.subtracting(inner), Tone(0xfff6e0, alpha))
        }
    }

    func face(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, spread: CGFloat? = nil) {
        guard style == .kawaii, size >= 20, let k = kawaii else { return }
        k.face(cx, cy, spread: spread ?? r * 3.4, r: r, mouth: .cat)
    }

    func clip(_ p: CGPath, _ body: () -> Void) { canvas.clip(p, body) }
    func with(_ t: CGAffineTransform, _ body: () -> Void) { canvas.with(t, body) }
    func fill(_ p: CGPath, _ t: Tone) { canvas.fill(p, t) }
    func stroke(_ p: CGPath, _ t: Tone, _ w: CGFloat) { canvas.stroke(p, t, w) }
}
