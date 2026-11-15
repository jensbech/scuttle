import Foundation
import CoreGraphics
import ScuttleCore

struct GestureStage {
    var body: CGAffineTransform
    var size: CGFloat
    var face: CGFloat
    var alpha: CGFloat
    var origin: CGPoint
    var anchor: CGPoint
    var seed: CGFloat
    var gait: CGFloat
    var bounds: CGSize
    var grounded: Bool
    var flying: Bool
    var place: CGAffineTransform = .identity
    var rect = CGRect(x: -0.45, y: -0.46, width: 0.9, height: 0.92)
    var moving = false

    func local(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x * size, y: y * size).applying(place)
    }

    func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x * size, y: y * size).applying(body)
    }

    var ground: CGFloat { anchor.y + FigurePainter.ground * size }
}

struct GestureProps {
    let pen: GesturePen
    let stage: GestureStage
    let stamps: GestureStamps

    var s: CGFloat { stage.size }
    var ctx: CGContext { pen.ctx }

    func draw(_ g: Gesture, t: CGFloat, weight: CGFloat, leaving: CGFloat?, front: Bool) {
        let a = stage.alpha * weight
        guard a > 0.01 else { return }
        switch g {
        case .parachute where !front: canopy(t: t, alpha: stage.alpha, collapse: leaving ?? 0)
        case .tiptoe where front: puffs(alpha: a)
        case .wave where front: hand(t: t, alpha: a)
        case .dance where front: notes(t: t, alpha: a)
        case .cheer where front: confetti(t: t, alpha: a)
        case .sleep where front: snore(t: t, alpha: a)
        case .shiver where front: tremble(t: t, alpha: a)
        case .tumble where front: dizzy(t: t, alpha: a)
        case .popUp where front: flecks(t: t, alpha: stage.alpha)
        case .look where front: swish(t: t, alpha: a)
        case .push where front: effort(t: t, alpha: a, tugging: false)
        case .pull where front: effort(t: t, alpha: a, tugging: true)
        case .build where front: taps(t: t, alpha: a)
        case .count where front: tally(t: t, alpha: a)
        case .kick where front: impact(t: t, alpha: a)
        default: break
        }
    }

    func soft() -> Tone {
        switch pen.style {
        case .kawaii: return Tone(0xf6f0ff)
        case .sticker: return .white
        case .hose: return GesturePen.hoseCream
        case .mascot: return Tone(0xe2e8ff)
        case .doodle: return Tone(0xb8b4d8)
        }
    }

    func cool() -> Tone {
        switch pen.style {
        case .kawaii: return Tone(0x9db4f0)
        case .sticker: return Tone(0x7fd0ff)
        case .hose: return GesturePen.hoseInk
        case .mascot: return Tone(0x8fb8ff)
        case .doodle: return Tone(0x5a8fff)
        }
    }

    func glove() -> Tone {
        switch pen.style {
        case .kawaii: return Tone(0xfff1e8)
        case .hose: return GesturePen.hoseCream
        case .doodle: return Tone(0xfff6ea)
        default: return .white
        }
    }

    func put(_ r: StampRecipe, at c: CGPoint, rot: CGFloat = 0, sx: CGFloat = 1, sy: CGFloat = 1, alpha: CGFloat, needed: Bool = false) {
        guard abs(sx) > 0.01, abs(sy) > 0.01 else { return }
        put(r, CGAffineTransform(translationX: c.x, y: c.y).rotated(by: rot).scaledBy(x: sx, y: sy), alpha: alpha, needed: needed)
    }

    func put(_ r: StampRecipe, _ t: CGAffineTransform, alpha: CGFloat, needed: Bool = false) {
        guard alpha > 0.01, needed || stamps.spare else { return }
        stamps.spend()
        if pen.style == .kawaii {
            ctx.saveGState()
            ctx.concatenate(t)
            ctx.setAlpha(alpha)
            r.draw(GesturePen(ctx, style: pen.style, size: s, time: 0))
            ctx.restoreGState()
        } else if let st = stamps.stamp(r.kind, tint: r.tint, size: s, half: r.half, boil: pen.boil, draw: r.draw) {
            GestureStamps.place(st, in: ctx, t, alpha: alpha)
        }
    }

    var starRef: CGFloat { max(3, 0.2 * s) }

    func star(_ points: Int, tint: Int) -> StampRecipe {
        let r = starRef
        let tone = tint == 9 ? pen.tone(Tone(0xffd84a), .cream) : pen.accent(tint)
        return StampRecipe(kind: points == 4 ? .star4 : .star5, tint: tint, half: r + pen.unit * 3 + 1) { p in
            p.shape(GesturePen.star(.zero, r, points: points, inner: points == 4 ? 0.37 : 0.45), tone, alpha: 1, smooth: p.style == .kawaii, w: 0.75)
        }
    }

    func snore(t: CGFloat, alpha: CGFloat) {
        let start = stage.at(0.2 * stage.face, 0.36)
        let h0 = max(3.2, 0.19 * s)
        let tone = cool()
        let st = StampRecipe(kind: .zed, tint: 0, half: h0 * 0.75 + pen.unit * 3 + 1) { p in
            let h = h0
            let pts = [CGPoint(x: -h / 2, y: h / 2), CGPoint(x: h / 2, y: h / 2), CGPoint(x: -h / 2, y: -h / 2), CGPoint(x: h / 2, y: -h / 2)]
            p.mark(pts, tone, alpha: 1, w: max(0.8, h * 0.19 / p.unit), smooth: false)
        }
        for k in 0..<2 {
            let age = t - 0.7 - CGFloat(k) * 1.3
            guard age > 0 else { continue }
            let a = GestureMotion.frac(age / 2.6)
            let fade = GestureMotion.smooth(a / 0.15) * (1 - GestureMotion.smooth((a - 0.6) / 0.4))
            guard fade > 0.02 else { continue }
            let h = max(3.2, (0.1 + 0.09 * a) * s)
            let c = CGPoint(
                x: start.x + stage.face * (0.1 + 0.5 * a) * s + 0.05 * s * sin(a * 6 + CGFloat(k)),
                y: start.y + (0.12 + 0.55 * a) * s)
            let k = h / h0
            put(st, at: c, rot: -0.18 * stage.face + 0.1 * sin(a * 4), sx: k, sy: k, alpha: alpha * fade)
        }
    }

    func notes(t: CGFloat, alpha: CGFloat) {
        let h0 = max(5, 0.3 * s)
        for k in 0..<2 {
            let age = t - 0.3 - CGFloat(k) * 0.95
            guard age > 0 else { continue }
            let a = GestureMotion.frac(age / 1.9)
            let idx = Int(age / 1.9) * 2 + k
            let fade = GestureMotion.smooth(a / 0.12) * (1 - GestureMotion.smooth((a - 0.55) / 0.45))
            guard fade > 0.02 else { continue }
            let side: CGFloat = idx % 2 == 0 ? 1 : -1
            let base = stage.at(side * 0.4, 0.3)
            let c = CGPoint(x: base.x + side * 0.16 * a * s + 0.07 * s * sin(a * 7 + CGFloat(idx)), y: base.y + 0.8 * a * s)
            let pop = min(1, GestureMotion.backOut(a / 0.14, 2.4))
            let beamed = idx % 3 == 2
            let tint = (idx + Int(stage.seed)) % 5
            let tone = pen.accent(tint)
            let st = StampRecipe(kind: beamed ? .beamed : .note, tint: tint, half: h0 * 0.8 + pen.unit * 3 + 1) { p in
                note(p, h: h0, tone: tone, beamed: beamed)
            }
            put(st, at: c, rot: 0.25 * sin(a * 5 + CGFloat(idx)), sx: pop, sy: pop, alpha: alpha * fade)
        }
    }

    func note(_ p: GesturePen, h: CGFloat, tone: Tone, beamed: Bool) {
        func q(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: h * (x - 0.1), y: h * (y - 0.42)) }
        let w = max(0.7, h * 0.09 / p.unit)
        let heads: [CGPoint] = beamed ? [q(-0.25, 0), q(0.3, 0.1)] : [q(0, 0)]
        let tops: [CGPoint] = beamed ? [q(-0.08, 0.85), q(0.47, 0.95)] : [q(0.17, 0.88)]
        for (i, hd) in heads.enumerated() {
            let foot = beamed ? (i == 0 ? q(-0.08, 0.05) : q(0.47, 0.15)) : q(0.17, 0.05)
            p.mark([foot, tops[i]], tone, alpha: 1, w: w, smooth: false, seed: i)
            p.shape(GesturePen.ring(hd, h * 0.21, h * 0.15, n: 9, rot: -0.4), tone, alpha: 1, w: 0.8, seed: 3 &+ i)
        }
        if beamed {
            p.mark([tops[0], tops[1]], tone, alpha: 1, w: w * 1.9, smooth: false, seed: 5)
        } else {
            p.mark([tops[0], q(0.42, 0.6), q(0.36, 0.38)], tone, alpha: 1, w: w, seed: 5)
        }
    }

    func confetti(t: CGFloat, alpha: CGFloat) {
        let cycle: CGFloat = 1.55
        let c = GestureMotion.frac(t / cycle) * cycle
        var age = c - 0.6
        var round = Int(t / cycle)
        if age < 0 {
            age += cycle
            round -= 1
        }
        guard round >= 0, age < 1.15 else { return }
        let o = CGPoint(x: stage.anchor.x, y: stage.anchor.y + 0.9 * s)
        let fade = 1 - GestureMotion.smooth((age - 0.55) / 0.55)
        let seed = stage.seed * 3.1 + CGFloat(round) * 7.7
        let w = max(1.4, 0.065 * s), hh = max(0.9, 0.04 * s)
        for i in 0..<5 {
            let h1 = GestureMotion.hash(seed + CGFloat(i) * 1.37)
            let h2 = GestureMotion.hash(seed + CGFloat(i) * 2.91 + 5)
            let ang = .pi / 2 + (h1 - 0.5) * 2.4
            let v = (1.5 + 1.3 * h2) * s
            let q = CGPoint(x: o.x + cos(ang) * v * age, y: o.y + sin(ang) * v * age - 2.6 * s * age * age)
            let spin = age * (6 + 6 * h2) * (i % 2 == 0 ? 1 : -1) + h1 * 6
            let flutter = max(0.15, abs(cos(age * 9 + h1 * 6)))
            let tint = i % 5
            let tone = pen.accent(tint)
            let st = StampRecipe(kind: .confetti, tint: tint, half: w * 1.5 + pen.unit * 3 + 1) { p in
                p.shape([CGPoint(x: -w, y: -hh), CGPoint(x: w, y: -hh), CGPoint(x: w, y: hh), CGPoint(x: -w, y: hh)], tone, alpha: 1, smooth: false, w: 0.6)
            }
            put(st, at: q, rot: spin, sx: 1, sy: flutter, alpha: alpha * fade)
        }
        let pop = sin(min(1, age / 0.35) * .pi)
        if pop > 0.02 {
            let k = max(2.5, 0.2 * s) * pop / starRef
            put(star(4, tint: 1), at: o, rot: age * 2, sx: k, sy: k, alpha: alpha * pop)
        }
    }

    func hand(t: CGFloat, alpha: CGFloat) {
        let appear = GestureMotion.backOut((t - 0.25) / 0.3, 2)
        guard appear > 0.01 else { return }
        let f = stage.face
        let w = (t - 0.25) * 2 * .pi * 2.2
        let theta = 0.45 + 0.55 * sin(w)
        let r: CGFloat = 0.3
        let pivot = CGPoint(x: f * 0.4, y: 0.08)
        let c = stage.at(pivot.x + f * r * sin(theta), pivot.y + r * cos(theta))
        let tilt = -f * theta
        let arcs = abs(cos(w))
        let soft = soft()
        for (k, rr) in ([r + 0.15, r + 0.25] as [CGFloat]).enumerated() {
            let dir: CGFloat = cos(w) > 0 ? -1 : 1
            var pts: [CGPoint] = []
            for j in 0..<5 {
                let th = theta + dir * (0.12 + CGFloat(j) * 0.11)
                pts.append(stage.at(pivot.x + f * rr * sin(th), pivot.y + rr * cos(th)))
            }
            pen.mark(pts, soft, alpha: alpha * arcs * (k == 0 ? 0.85 : 0.55), w: 0.9, seed: k)
        }
        let palm = max(2.4, 0.11 * s)
        let tone = glove()
        let st = StampRecipe(kind: .glove, tint: 0, half: palm * 1.9 + pen.unit * 3 + 1) { p in
            p.shape(GesturePen.ring(CGPoint(x: -palm * 0.85, y: -palm * 0.1), palm * 0.42, palm * 0.6, n: 8, rot: 0.6), tone, alpha: 1, w: 0.8, seed: 1)
            p.shape(GesturePen.ring(.zero, palm, palm * 1.08, n: 10), tone, alpha: 1, w: 0.8, seed: 2)
            if p.style == .hose || p.style == .mascot || p.style == .sticker {
                for k in [-1, 1] as [CGFloat] {
                    let x0 = k * palm * 0.36, y0 = palm * 0.15
                    p.stroke(GestureGeo.line(x0, y0, x0, y0 + palm * 0.4), p.edge(tone), max(0.5, p.unit * 0.6), 1)
                }
            }
        }
        put(st, at: c, rot: tilt, sx: f * appear, sy: appear, alpha: alpha, needed: true)
    }

    func puffs(alpha: CGFloat) {
        guard !stage.flying else { return }
        let u = GestureMotion.frac(stage.gait * 2)
        guard u < 0.5 else { return }
        let q = u / 0.5
        let parity = Int((stage.gait * 2).rounded(.down)) & 1
        let x = stage.anchor.x + stage.face * (parity == 0 ? 0.16 : -0.06) * s
        let y = stage.ground + 0.01 * s
        let a = alpha * (1 - q * q)
        let r0 = max(1.3, 0.06 * s) * 1.3
        let r = max(1.3, 0.06 * s) * (0.6 + 0.7 * q)
        let tone = soft()
        let st = StampRecipe(kind: .puff, tint: 0, half: r0 + pen.unit * 3 + 1) { p in
            p.shape(GesturePen.ring(.zero, r0, r0, n: 8), tone, alpha: 1, w: 0.6)
        }
        for o in [(-1.0, 0.2), (1.0, 0.2), (0.0, 0.9)] as [(CGFloat, CGFloat)] {
            let c = CGPoint(x: x + o.0 * (0.08 + 0.1 * q) * s, y: y + (0.02 + o.1 * 0.06 * (0.5 + q)) * s)
            put(st, at: c, sx: r / r0, sy: r / r0 * 0.85, alpha: a)
        }
        if q < 0.55 {
            let ta = alpha * (1 - q / 0.55)
            for k in [-1, 1] as [CGFloat] {
                let b = CGPoint(x: x + k * 0.1 * s, y: y + 0.1 * s)
                pen.mark([b, CGPoint(x: b.x + k * 0.07 * s, y: b.y + 0.09 * s)], tone, alpha: ta, w: 0.8, smooth: false, seed: Int(k))
            }
        }
    }

    func tremble(t: CGFloat, alpha: CGFloat) {
        let on = sin(t * 2 * .pi * 4.5)
        let tone = cool()
        let cx = stage.anchor.x, cy = stage.anchor.y - 0.04 * s
        for side in [-1, 1] as [CGFloat] {
            for k in 0..<2 {
                let flick = (side * on > 0) == (k == 0)
                let a = alpha * (flick ? 0.95 : 0.35)
                let x = cx + side * (0.5 + 0.09 * CGFloat(k)) * s + side * 0.015 * s * sin(t * 70)
                let h = (k == 0 ? 0.2 : 0.13) * s
                let pts = [CGPoint(x: x, y: cy - h), CGPoint(x: x + side * 0.03 * s, y: cy), CGPoint(x: x, y: cy + h)]
                pen.mark(pts, tone, alpha: a, w: 0.9, smooth: false, seed: k)
            }
        }
    }

    func dizzy(t: CGFloat, alpha: CGFloat) {
        let rt = GestureMotion.rollTime
        if t > rt, t < rt + 0.45 {
            let q = (t - rt) / 0.45
            let r0 = max(1.3, 0.06 * s) * 1.3
            let tone = soft()
            let st = StampRecipe(kind: .puff, tint: 0, half: r0 + pen.unit * 3 + 1) { p in
                p.shape(GesturePen.ring(.zero, r0, r0, n: 8), tone, alpha: 1, w: 0.6)
            }
            for k in [-1, 1] as [CGFloat] {
                let c = CGPoint(x: stage.anchor.x + k * (0.3 + 0.25 * q) * s, y: stage.ground + 0.06 * s + 0.06 * q * s)
                let r = max(1.2, 0.07 * s) * (0.7 + 0.6 * q)
                put(st, at: c, sx: r / r0, sy: r / r0 * 0.8, alpha: alpha * (1 - q))
            }
        }
        let amount = GestureMotion.smooth((t - rt * 0.5) / 0.4) * (1 - GestureMotion.smooth((t - 3.2) / 1.2))
        guard amount > 0.02 else { return }
        let head = stage.at(0, 0.5)
        let rx = 0.42 * s + 2, ry = rx * 0.3
        let st = star(5, tint: 9)
        for k in 0..<3 {
            let ang = t * 5.5 + CGFloat(k) * 2 * .pi / 3
            let depth: CGFloat = sin(ang) > 0 ? 0.75 : 1
            let c = CGPoint(x: head.x + rx * cos(ang), y: head.y + 0.04 * s + ry * sin(ang))
            let r = max(2, 0.07 * s + 0.8) * depth / starRef
            put(st, at: c, rot: t * 3 + CGFloat(k), sx: r, sy: r, alpha: alpha * amount)
        }
    }

    func swish(t: CGFloat, alpha: CGFloat) {
        let marks: [CGFloat] = [1.7, 3.3, 4.7, 6.3, 7.7]
        guard let m = marks.first(where: { t >= $0 - 0.05 && t < $0 + 0.35 }) else { return }
        let q = (t - m + 0.05) / 0.4
        let a = alpha * sin(q * .pi) * 0.8
        let head = stage.at(0, 0.32)
        let back = -stage.face
        for k in 0..<2 {
            let y = head.y + (CGFloat(k) * 0.14 - 0.02) * s
            let x0 = head.x + back * (0.42 + 0.06 * CGFloat(k)) * s
            pen.mark([CGPoint(x: x0, y: y), CGPoint(x: x0 + back * 0.12 * s, y: y + 0.02 * s), CGPoint(x: x0 + back * 0.22 * s, y: y)], soft(), alpha: a, w: 0.8, seed: k)
        }
    }

    func flecks(t: CGFloat, alpha: CGFloat) {
        let age = t - 0.05
        guard age > 0, age < 0.95 else { return }
        let edge = ScreenEdge.nearest(to: stage.origin, in: stage.bounds)
        var n = edge.inward
        let depth = edge.depth(of: stage.origin, in: stage.bounds)
        var e = CGPoint(x: stage.origin.x - n.x * depth, y: stage.origin.y - n.y * depth)
        if depth > GestureMotion.edgeReach * s {
            n = CGPoint(x: 0, y: 1)
            e = CGPoint(x: stage.origin.x, y: stage.origin.y + FigurePainter.ground * s)
        }
        let tan = CGPoint(x: n.y, y: -n.x)
        let fade = 1 - GestureMotion.smooth((age - 0.45) / 0.5)
        let dirt: [Tone] = [Tone(0x8a5a3c), Tone(0x6b4a2f), Tone(0xa57a52)]
        let r0 = max(1.2, 0.055 * s) * 1.2
        let sparkle = star(4, tint: 1)
        for i in 0..<6 {
            let h1 = GestureMotion.hash(stage.seed + CGFloat(i) * 1.91)
            let h2 = GestureMotion.hash(stage.seed + CGFloat(i) * 3.17 + 2)
            let ang = (0.12 + 0.76 * (CGFloat(i) + h1 * 0.8) / 6) * .pi
            let v = (1.3 + 1.2 * h2) * s
            let along = cos(ang) * v * age
            let up = sin(ang) * v * age - 2.8 * s * age * age
            guard up > -0.05 * s else { continue }
            let q = CGPoint(x: e.x + tan.x * along + n.x * up, y: e.y + tan.y * along + n.y * up)
            if i % 3 == 1 {
                let r = max(1.8, 0.1 * s) * (0.6 + 0.4 * sin(age * 12 + h1 * 5)) / starRef
                put(sparkle, at: q, rot: age * 4, sx: r, sy: r, alpha: alpha * fade)
            } else {
                let tint = i % 3
                let base = pen.style == .hose ? GesturePen.hoseInk : dirt[tint]
                let tone = pen.style == .kawaii ? base.lift(0.25) : base
                let st = StampRecipe(kind: .dirt, tint: tint, half: r0 * 1.2 + pen.unit * 3 + 1) { p in
                    let pts = (0..<5).map { j -> CGPoint in
                        let aa = CGFloat(j) * 1.2566
                        let rr = r0 * (0.75 + 0.4 * GestureMotion.hash(CGFloat(tint * 5 + j)))
                        return CGPoint(x: rr * cos(aa), y: rr * sin(aa))
                    }
                    p.shape(pts, tone, alpha: 1, smooth: false, w: 0.5)
                }
                let k = (0.8 + 0.4 * h2) / 1.2
                put(st, at: q, rot: age * 7 + h1 * 6, sx: k, sy: k, alpha: alpha * fade)
            }
        }
    }

    func canopy(t: CGFloat, alpha: CGFloat, collapse q: CGFloat) {
        let open = min(1.15, GestureMotion.backOut(t / 0.45, 2.2))
        guard open > 0.02 else { return }
        let fall = GestureMotion.smooth(q)
        let a = alpha * (1 - GestureMotion.smooth((q - 0.25) / 0.75))
        guard a > 0.01 else { return }
        let f = stage.face
        let kx = open * (1 + 0.2 * fall)
        let ky = open * (1 - 0.82 * GestureMotion.smooth(q * 1.4))
        let cx = f * 0.4 * fall, cy = 1.04 - 0.75 * fall
        let rot = 0.5 * fall * f
        let W: CGFloat = 0.62, H: CGFloat = 0.42
        let scallops = 4
        let place = stage.body.translatedBy(x: cx * s, y: cy * s).rotated(by: rot).scaledBy(x: kx, y: ky)
        let feet = (0...scallops).map { j in
            CGPoint(x: (-W + 2 * W * CGFloat(j) / CGFloat(scallops)) * s, y: 0).applying(place)
        }
        let shoulders = [stage.at(-0.18, 0.2), stage.at(0.18, 0.2)]
        let lineTone: Tone
        var halo: Tone?
        switch pen.style {
        case .kawaii: lineTone = Tone(0xd9cdf2)
        case .sticker: lineTone = pen.ink; halo = .white
        case .hose: lineTone = GesturePen.hoseInk; halo = GesturePen.hoseCream
        case .mascot: lineTone = Tone(0xd6dcff)
        case .doodle: lineTone = Tone(0xcbbde6)
        }
        let strings = CGMutablePath()
        for (j, ft) in feet.enumerated() {
            let sh = shoulders[j < 2 || (j == 2 && f < 0) ? 0 : 1]
            let sag = 0.25 * s * fall
            strings.move(to: ft)
            strings.addQuadCurve(to: sh, control: CGPoint(x: (ft.x + sh.x) / 2 + sag * f, y: (ft.y + sh.y) / 2 - sag))
        }
        let sw = max(0.45, pen.unit * 0.45)
        let sa = a * (1 - fall)
        if let halo { pen.stroke(strings, halo, sw * 2.6, sa * 0.8) }
        pen.stroke(strings, lineTone, sw, sa)
        let size = s
        let st = StampRecipe(kind: .canopy, tint: 0, half: (W + 0.05) * s + pen.unit * 4 + 2) { p in
            canopyArt(p, W: W * size, H: H * size)
        }
        put(st, place, alpha: a, needed: true)
    }

    func canopyArt(_ p: GesturePen, W: CGFloat, H: CGFloat) {
        let main: Tone, stripe: Tone
        switch p.style {
        case .kawaii: main = Tone(0xffb8cf); stripe = Tone(0xfff3d6)
        case .sticker: main = Tone(0xff4a5f); stripe = .white
        case .hose: main = GesturePen.hoseRed; stripe = GesturePen.hoseCream
        case .mascot: main = Tone(0xff8a3d); stripe = Tone(0xffd84a)
        case .doodle: main = Tone(0xe8453c); stripe = Tone(0xfff0c0)
        }
        let scallops = 4
        let lift = 0.02 * s, dip = 0.09 * s
        var outline: [CGPoint] = []
        for i in 0...12 {
            let ang = CGFloat(i) / 12 * .pi
            outline.append(CGPoint(x: W * cos(ang), y: H * sin(ang) + lift))
        }
        var feet: [CGPoint] = []
        for j in 0...scallops { feet.append(CGPoint(x: -W + 2 * W * CGFloat(j) / CGFloat(scallops), y: 0)) }
        for j in 0..<scallops {
            outline.append(CGPoint(x: (feet[j].x + feet[j + 1].x) / 2, y: dip))
            if j < scallops - 1 { outline.append(feet[j + 1]) }
        }
        let apex = CGPoint(x: 0, y: H + lift)
        p.shape(outline, main, alpha: 1, smooth: true, w: 0.9, seed: 3)
        for j in [1, 3] {
            let mid = CGPoint(x: (feet[j].x + feet[j + 1].x) / 2, y: dip)
            if p.style == .doodle {
                p.mark([feet[j], apex, feet[j + 1]], p.edge(main), alpha: 0.8, w: 0.7, smooth: false, seed: j)
            } else {
                p.fill(GestureGeo.polyP([apex, feet[j], mid, feet[j + 1]]), stripe, 1)
            }
        }
        if p.style == .mascot {
            p.mark([CGPoint(x: -W * 0.62, y: H * 0.55), CGPoint(x: -W * 0.35, y: H * 0.82), CGPoint(x: -W * 0.05, y: H * 0.93)], Tone(0xffe6b0), alpha: 0.9, w: 1.1)
        }
        if p.style != .kawaii && p.style != .doodle {
            p.stroke(GestureGeo.smoothP(outline), p.edge(main), p.unit * 0.9, 1)
        }
    }
}

extension GestureProps {
    func fright(at head: CGPoint, age: CGFloat, alpha: CGFloat) {
        let pop = min(1, age / 0.1)
        let over = 1 + 0.35 * sin(min(1, age / 0.22) * .pi)
        let h = max(8, 0.34 * s + 4) * pop * over
        guard h > 0.5 else { return }
        let w = max(2.2, h * 0.3)
        let x = head.x + s * 0.02 * sin(age * 40)
        let base = head.y + 3
        let top = base + h, low = base + w * 1.25
        let wedge = [
            CGPoint(x: x - w * 0.5, y: top - w * 0.2), CGPoint(x: x, y: top + w * 0.08), CGPoint(x: x + w * 0.5, y: top - w * 0.2),
            CGPoint(x: x + w * 0.16, y: low + w * 0.1), CGPoint(x: x, y: low - w * 0.05), CGPoint(x: x - w * 0.16, y: low + w * 0.1),
        ]
        let tone: Tone
        switch pen.style {
        case .kawaii: tone = Tone(0xff8fa8)
        case .sticker: tone = Tone(0xff4d4d)
        case .hose: tone = GesturePen.hoseRed
        case .mascot: tone = Tone(0xffa21f)
        case .doodle: tone = Tone(0xff4a3d)
        }
        let dot = CGPoint(x: x, y: base + w * 0.32)
        let shine = pen.style == .doodle ? nil : CGPoint(x: x - w * 0.12, y: top - w * 0.45)
        pen.shape(wedge, tone, alpha: alpha, smooth: true, w: 1.1, seed: 1, shine: shine)
        pen.shape(GesturePen.ring(dot, w * 0.36, w * 0.36, n: 8), tone, alpha: alpha, w: 1.1, seed: 2)
    }

    func question(at head: CGPoint, phase ap: CGFloat, amount conf: CGFloat, alpha: CGFloat) {
        let a = min(1, conf * 2.2) * alpha
        let qh = max(7, 0.3 * s + 3) * (0.7 + 0.3 * conf)
        let bob = sin(ap * 0.7) * 0.9
        let qx = head.x + sin(ap * 0.33) * 1.2
        let qy = head.y + 3 + qh * 0.55 + bob
        let rad = qh * 0.24
        let cy = qy + qh * 0.2
        var curve: [CGPoint] = []
        for i in 0...7 {
            let ang = CGFloat.pi * 0.95 - CGFloat(i) / 7 * CGFloat.pi * 1.4
            curve.append(CGPoint(x: qx + rad * cos(ang), y: cy + rad * sin(ang)))
        }
        curve.append(CGPoint(x: qx + rad * 0.12, y: cy - rad * 1.05))
        curve.append(CGPoint(x: qx, y: qy - qh * 0.12))
        let tone: Tone
        switch pen.style {
        case .kawaii: tone = Tone(0xb9a4ff)
        case .sticker: tone = Tone(0xffd23f)
        case .hose: tone = GesturePen.hoseCream
        case .mascot: tone = Tone(0xffd84a)
        case .doodle: tone = Tone(0x5a8fff)
        }
        let w = max(1.2, qh * 0.17) / pen.unit
        pen.mark(curve, tone, alpha: a, w: w, seed: 4)
        let dot = CGPoint(x: qx, y: qy - qh * 0.4)
        let r = max(0.9, qh * 0.11)
        pen.shape(GesturePen.ring(dot, r, r, n: 8), tone, alpha: a, w: 0.9, seed: 5)
        if conf > 0.2 {
            let count = conf > 0.6 ? 3 : 2
            let rx = s * 0.42 + 3, ry = rx * 0.3
            let sr = max(1.8, 0.07 * s + 0.9) * (0.7 + 0.3 * conf)
            let sa = min(1, (conf - 0.2) * 3) * alpha
            for k in 0..<count {
                let ang = ap * 1.15 + CGFloat(k) * 2 * .pi / CGFloat(count)
                let depth: CGFloat = sin(ang) > 0 ? 0.8 : 1
                let c = CGPoint(x: head.x + rx * cos(ang), y: head.y - 1 + ry * sin(ang))
                pen.shape(GesturePen.star(c, sr * depth * 1.15, points: 5, inner: 0.45, spin: ap * 0.9 + CGFloat(k)), pen.tone(Tone(0xffd84a), .cream), alpha: sa, smooth: pen.style == .kawaii, w: 0.7, seed: k)
            }
        }
    }
}
