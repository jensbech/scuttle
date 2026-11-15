import Foundation
import CoreGraphics
import ScuttleCore

extension PropPainter {
    func ropeWidth(_ p: Prop) -> CGFloat {
        max(1.1, CGFloat(p.size) * 0.085)
    }

    func curve(_ a: CGPoint, _ b: CGPoint, sag: CGFloat) -> (path: CGPath, control: CGPoint) {
        let control = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 - 2 * sag)
        let path = CGMutablePath()
        path.move(to: a)
        path.addQuadCurve(to: b, control: control)
        return (path, control)
    }

    func along(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint, _ u: CGFloat) -> (point: CGPoint, tangent: CGFloat) {
        let v = 1 - u
        let p = CGPoint(x: v * v * a.x + 2 * v * u * c.x + u * u * b.x, y: v * v * a.y + 2 * v * u * c.y + u * u * b.y)
        let dx = 2 * v * (c.x - a.x) + 2 * u * (b.x - c.x)
        let dy = 2 * v * (c.y - a.y) + 2 * u * (b.y - c.y)
        return (p, atan2(dy, dx))
    }

    func wobbled(_ a: CGPoint, _ c: CGPoint, _ b: CGPoint, amp: CGFloat, seed: Int) -> CGPath {
        let n = max(6, Int(hypot(b.x - a.x, b.y - a.y) / 6))
        let path = CGMutablePath()
        let ph = CGFloat(seed % 13) + CGFloat(boil) * 1.7
        for i in 0...n {
            let u = CGFloat(i) / CGFloat(n)
            let q = along(a, c, b, u)
            let o = amp * sin(u * 11 + ph) * sin(u * .pi)
            let pnt = CGPoint(x: q.point.x - sin(q.tangent) * o, y: q.point.y + cos(q.tangent) * o)
            if i == 0 { path.move(to: pnt) } else { path.addLine(to: pnt) }
        }
        return path
    }

    func stroke(_ path: CGPath, _ t: Tone, _ w: CGFloat, _ a: CGFloat, dash: [CGFloat]? = nil) {
        ctx.addPath(path)
        ctx.setStrokeColor(red: t.r, green: t.g, blue: t.b, alpha: t.a * a)
        ctx.setLineWidth(w)
        if let dash { ctx.setLineDash(phase: 0, lengths: dash) } else { ctx.setLineDash(phase: 0, lengths: []) }
        ctx.strokePath()
    }

    func drawRope(_ p: Prop, from a: CGPoint, to b: CGPoint, sag: CGFloat, alpha: CGFloat, marker: Bool, wave: CGFloat = 0) {
        guard alpha > 0.01, a.x.isFinite, a.y.isFinite, b.x.isFinite, b.y.isFinite else { return }
        let w = ropeWidth(p)
        var (path, c) = curve(a, b, sag: sag)
        if wave > 0.2 {
            let m = CGMutablePath()
            let dx = b.x - a.x, dy = b.y - a.y
            m.move(to: a)
            m.addCurve(to: b, control1: CGPoint(x: a.x + dx * 0.33, y: a.y + dy * 0.33 + wave), control2: CGPoint(x: a.x + dx * 0.66, y: a.y + dy * 0.66 - wave))
            path = m
            c = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        }
        ctx.saveGState()
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        let tan = Tone(0xd4a464), dark = Tone(0x8a5a30)
        let twist: [CGFloat]? = w < 1.3 ? nil : [max(1.6, w * 1.3), max(2, w * 1.7)]
        switch style {
        case .kawaii:
            stroke(path, tan.lift(0.25), w, alpha)
            if let twist { stroke(path, Tone(0xfff3df), w * 0.45, alpha * 0.8, dash: twist) }
        case .sticker:
            stroke(path, .white, w + 3, alpha * 0.95)
            stroke(path, GesturePen.stickerInk, w + 1.5, alpha)
            stroke(path, tan.saturate(1.15), w, alpha)
            if let twist { stroke(path, dark, w * 0.4, alpha * 0.7, dash: twist) }
        case .hose:
            stroke(path, PropBrush.hoseCream, w + 2.6, alpha * 0.9)
            stroke(path, PropBrush.hoseInk, w + 1.3, alpha)
            stroke(path, PropBrush.hoseCream, w, alpha)
            if let twist { stroke(path, PropBrush.hoseInk, w * 0.42, alpha, dash: twist) }
        case .mascot:
            stroke(path, GesturePen.rim, w + 2.4, alpha * 0.8)
            stroke(path, dark.dim(0.55), w + 1.2, alpha)
            stroke(path, tan, w, alpha)
            if let twist { stroke(path, Tone(0xf6dcae), w * 0.35, alpha * 0.9, dash: twist) }
        case .doodle:
            let wob = wobbled(a, c, b, amp: w * 0.35, seed: p.id)
            stroke(wob, tan.saturate(1.3).dim(0.6), w * 0.95, alpha)
            stroke(wobbled(a, c, b, amp: w * 0.6, seed: p.id + 5), tan.saturate(1.2), w * 0.45, alpha * 0.9, dash: [max(1.6, w * 1.1), max(2.4, w * 1.8)])
        }
        if marker {
            let mid = along(a, c, b, 0.5).point
            let pen = GesturePen(ctx, style: style, size: max(10, CGFloat(p.size) * 0.6), time: time)
            let h = max(4, w * 3.2)
            let flag = [CGPoint(x: mid.x - h * 0.32, y: mid.y), CGPoint(x: mid.x + h * 0.32, y: mid.y), CGPoint(x: mid.x + h * 0.05, y: mid.y - h)]
            pen.shape(flag, pen.tone(Tone(0xe8453c), .red), alpha: alpha, smooth: false, w: 0.7)
        }
        ctx.restoreGState()
    }

    func drawBanner(_ p: Prop, from a: CGPoint, to b: CGPoint, sag: CGFloat, alpha: CGFloat, reveal: CGFloat = 1) {
        guard alpha > 0.01, a.x.isFinite, a.y.isFinite, b.x.isFinite, b.y.isFinite else { return }
        let size = CGFloat(p.size)
        let (path, c) = curve(a, b, sag: sag)
        ctx.saveGState()
        ctx.setLineCap(.round)
        let lw = max(0.8, size * 0.035)
        switch style {
        case .kawaii: stroke(path, Tone(0xd9cdf2), lw, alpha)
        case .sticker:
            stroke(path, .white, lw + 2.4, alpha)
            stroke(path, GesturePen.stickerInk, lw, alpha)
        case .hose:
            stroke(path, PropBrush.hoseCream, lw + 2, alpha)
            stroke(path, PropBrush.hoseInk, lw, alpha)
        case .mascot:
            stroke(path, GesturePen.rim, lw + 1.8, alpha * 0.8)
            stroke(path, Tone(0x3a2a50), lw, alpha)
        case .doodle: stroke(wobbled(a, c, b, amp: lw, seed: p.id), Tone(0x5a4a80), lw, alpha)
        }
        ctx.restoreGState()
        let flag = max(5, size * 0.55)
        let length = hypot(b.x - a.x, b.y - a.y) + abs(sag)
        let count = max(1, min(40, Int(length / (flag * 0.62))))
        let shown = max(0, min(1, reveal)) * CGFloat(count)
        for i in 0..<count where CGFloat(i) < shown {
            let grow = min(1, shown - CGFloat(i))
            let u = (CGFloat(i) + 0.5) / CGFloat(count)
            let q = along(a, c, b, u)
            var rot = q.tangent
            if rot > .pi / 2 { rot -= .pi } else if rot < -.pi / 2 { rot += .pi }
            let sway = 0.07 * sin(CGFloat(time) * 2.1 + CGFloat(i) * 1.3 + CGFloat(p.id))
            let turn = max(-7, min(7, Int(((rot * 0.8 + sway) / PropPainter.turnStep).rounded())))
            guard let sprite = sprite(.banner, stage: 0, variant: (i + p.variant) % 5, size: flag, turn: turn) else { continue }
            let fs = CGFloat(PropPainter.bucket(flag))
            let r = sprite.rect
            ctx.saveGState()
            let a = alpha * grow
            if a < 0.995 { ctx.setAlpha(a) }
            blit(sprite.image, origin: CGPoint(x: q.point.x + r.minX * fs, y: q.point.y + (r.minY - 0.44) * fs + (1 - grow) * fs * 0.3))
            ctx.restoreGState()
        }
    }
}
