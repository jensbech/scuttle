import Foundation
import CoreGraphics

class FigureCanvas: FigureShapes {
    let ctx: CGContext
    let f: FigureFrame
    let pt: CGFloat
    private let space = CGColorSpace(name: CGColorSpace.sRGB)!

    init(_ ctx: CGContext, _ f: FigureFrame) {
        self.ctx = ctx
        self.f = f
        pt = f.pt
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
    }

    func width(_ design: CGFloat, minPt: CGFloat) -> CGFloat {
        max(design, minPt * pt)
    }

    func fill(_ p: CGPath, _ t: Tone) {
        guard t.a > 0 else { return }
        ctx.addPath(p)
        ctx.setFillColor(red: t.r, green: t.g, blue: t.b, alpha: t.a)
        ctx.fillPath()
    }

    func fillEvenOdd(_ p: CGPath, _ t: Tone) {
        ctx.addPath(p)
        ctx.setFillColor(red: t.r, green: t.g, blue: t.b, alpha: t.a)
        ctx.fillPath(using: .evenOdd)
    }

    func stroke(_ p: CGPath, _ t: Tone, _ w: CGFloat) {
        guard t.a > 0, w > 0 else { return }
        ctx.addPath(p)
        ctx.setStrokeColor(red: t.r, green: t.g, blue: t.b, alpha: t.a)
        ctx.setLineWidth(w)
        ctx.strokePath()
    }

    func fs(_ p: CGPath, _ fillTone: Tone, _ line: Tone, _ w: CGFloat) {
        fill(p, fillTone)
        stroke(p, line, w)
    }

    func clip(_ p: CGPath, _ body: () -> Void) {
        ctx.saveGState()
        ctx.addPath(p)
        ctx.clip()
        body()
        ctx.restoreGState()
    }

    func with(_ t: CGAffineTransform, _ body: () -> Void) {
        ctx.saveGState()
        ctx.concatenate(t)
        body()
        ctx.restoreGState()
    }

    func layer(_ alpha: CGFloat = 1, _ body: () -> Void) {
        ctx.saveGState()
        ctx.setAlpha(alpha)
        ctx.beginTransparencyLayer(auxiliaryInfo: nil)
        body()
        ctx.endTransparencyLayer()
        ctx.restoreGState()
    }

    func both(_ body: (CGFloat) -> Void) {
        body(-1)
        body(1)
    }

    func glow(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ t: Tone, _ alpha: CGFloat = 0.6) {
        let comps: [CGFloat] = [t.r, t.g, t.b, alpha, t.r, t.g, t.b, alpha * 0.35, t.r, t.g, t.b, 0]
        guard let g = CGGradient(colorSpace: space, colorComponents: comps, locations: [0, 0.4, 1], count: 3) else { return }
        let c = CGPoint(x: cx, y: cy)
        ctx.drawRadialGradient(g, startCenter: c, startRadius: 0, endCenter: c, endRadius: r, options: [])
    }

    func gradient(_ p: CGPath, _ top: Tone, _ bottom: Tone) {
        let box = p.boundingBoxOfPath
        let comps: [CGFloat] = [top.r, top.g, top.b, top.a, bottom.r, bottom.g, bottom.b, bottom.a]
        guard box.height > 0, let g = CGGradient(colorSpace: space, colorComponents: comps, locations: [0, 1], count: 2) else { return }
        clip(p) {
            ctx.drawLinearGradient(g, start: CGPoint(x: box.midX, y: box.maxY), end: CGPoint(x: box.midX, y: box.minY), options: [])
        }
    }
}
