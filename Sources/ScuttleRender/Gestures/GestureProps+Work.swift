import Foundation
import CoreGraphics
import ScuttleCore

extension GestureProps {
    func puffRecipe() -> (StampRecipe, CGFloat) {
        let r0 = max(1.3, 0.06 * s) * 1.3
        let tone = soft()
        let st = StampRecipe(kind: .puff, tint: 0, half: r0 + pen.unit * 3 + 1) { p in
            p.shape(GesturePen.ring(.zero, r0, r0, n: 8), tone, alpha: 1, w: 0.6)
        }
        return (st, r0)
    }

    func dust(at foot: CGPoint, drift: CGFloat, q: CGFloat, alpha: CGFloat) {
        guard alpha > 0.01, q >= 0, q < 1 else { return }
        let (st, r0) = puffRecipe()
        let a = alpha * (1 - q * q)
        let r = max(1.2, 0.055 * s) * (0.6 + 0.7 * q)
        for (k, o) in ([(0.0, 0.25), (1.0, 0.7)] as [(CGFloat, CGFloat)]).enumerated() {
            let c = CGPoint(x: foot.x + drift * (0.06 + 0.16 * q + 0.07 * o.0) * s, y: foot.y + (0.02 + o.1 * 0.07 * (0.4 + q)) * s)
            let k2 = r / r0 * (k == 0 ? 1 : 0.75)
            put(st, at: c, sx: k2, sy: k2 * 0.85, alpha: a)
        }
    }

    func strain(at head: CGPoint, side: CGFloat, amount: CGFloat, alpha: CGFloat) {
        guard amount > 0.05, alpha > 0.01 else { return }
        let tone = cool()
        let len = max(2.2, 0.13 * s) * (0.6 + 0.4 * amount)
        for k in 0..<3 {
            let ang = .pi / 2 + side * (0.35 + 0.42 * CGFloat(k))
            let r0 = 0.08 * s + 1
            let a0 = CGPoint(x: head.x + cos(ang) * r0, y: head.y + sin(ang) * r0)
            let a1 = CGPoint(x: a0.x + cos(ang) * len, y: a0.y + sin(ang) * len)
            pen.mark([a0, a1], tone, alpha: alpha * amount, w: 0.85, smooth: false, seed: k)
        }
    }

    func effort(t: CGFloat, alpha: CGFloat, tugging: Bool) {
        let r = stage.rect
        let f = stage.face
        let head = stage.local(r.minX * 0.55, r.maxY * 0.92)
        if tugging {
            let period: CGFloat = 0.95
            let u = GestureMotion.frac((t + GestureMotion.hash(stage.seed + 4) * period) / period)
            if !stage.flying {
                let heel = CGPoint(x: stage.anchor.x + f * 0.22 * s, y: stage.ground)
                dust(at: heel, drift: f, q: u / 0.55, alpha: alpha * 0.9)
            }
            let k = u < 0.1 ? GestureMotion.smooth(u / 0.1) : exp(-(u - 0.1) * 7)
            strain(at: head, side: -f, amount: k, alpha: alpha)
            return
        }
        let clock = stage.moving ? stage.gait : t * 1.4 + GestureMotion.hash(stage.seed)
        let heave = 0.5 + 0.5 * sin(clock * 4 * .pi)
        if !stage.flying {
            let u = GestureMotion.frac(clock * 2)
            let foot = CGPoint(x: stage.anchor.x - f * 0.28 * s, y: stage.ground)
            dust(at: foot, drift: -f, q: u / 0.6, alpha: alpha)
        }
        strain(at: head, side: -f, amount: 0.35 + 0.65 * heave, alpha: alpha * 0.85)
    }

    func burstRecipe(tint: Int) -> StampRecipe {
        let R = max(3.2, 0.19 * s)
        let tone = tint == 0 ? pen.tone(Tone(0xffd84a), .cream) : soft()
        return StampRecipe(kind: .burst, tint: tint, half: R * 1.1 + pen.unit * 3 + 1) { p in
            for k in 0..<7 {
                let a = CGFloat(k) / 7 * 2 * .pi + 0.2
                let inner: CGFloat = k % 2 == 0 ? 0.42 : 0.55
                let a0 = CGPoint(x: cos(a) * R * inner, y: sin(a) * R * inner)
                let a1 = CGPoint(x: cos(a) * R, y: sin(a) * R)
                p.mark([a0, a1], tone, alpha: 1, w: max(0.8, R * 0.13 / p.unit), smooth: false, seed: k)
            }
        }
    }

    func taps(t: CGFloat, alpha: CGFloat) {
        var input = GestureInput(gesture: .build, t: t, leaving: nil, size: s, seed: stage.seed, facing: stage.face, heading: 0,
                                 position: stage.origin, bounds: stage.bounds, grounded: stage.grounded,
                                 locomotion: stage.flying ? .hover : .walk, gait: stage.gait)
        input.moving = stage.moving
        let phase = GestureMotion.buildLoop(input)
        let r = stage.rect
        if let u = phase.hit, u > 0.56, u < 0.86 {
            let q = (u - 0.56) / 0.3
            let spot = stage.local(r.maxX + 0.12, r.minY + r.height * 0.28)
            let k = (0.55 + 0.6 * q)
            put(burstRecipe(tint: 1), at: spot, rot: q * 0.4, sx: k * 0.8, sy: k * 0.8, alpha: alpha * (1 - q) * 0.9)
            if q < 0.6 {
                let sk = max(2, 0.12 * s) * (1 - q) / starRef
                put(star(4, tint: 9), at: CGPoint(x: spot.x + stage.face * 0.05 * s, y: spot.y + 0.1 * s * q), rot: q, sx: sk, sy: sk, alpha: alpha)
            }
        } else if let v = phase.admire, v > 0.3, v < 0.8 {
            let q = (v - 0.3) / 0.5
            let tw = sin(q * .pi)
            let spot = stage.local(r.maxX + 0.3, r.maxY * 0.8 + 0.1 * q)
            let sk = max(2.2, 0.14 * s) * tw / starRef
            put(star(4, tint: 9), at: spot, rot: q * 1.5, sx: sk, sy: sk, alpha: alpha * tw)
        }
    }

    static let digitStrokes: [[CGPoint]] = [
        [],
        [CGPoint(x: -0.16, y: 0.3), CGPoint(x: 0.04, y: 0.5), CGPoint(x: 0.04, y: -0.5)],
        [CGPoint(x: -0.27, y: 0.24), CGPoint(x: -0.1, y: 0.46), CGPoint(x: 0.16, y: 0.45), CGPoint(x: 0.27, y: 0.2), CGPoint(x: 0.08, y: -0.08), CGPoint(x: -0.28, y: -0.5), CGPoint(x: 0.3, y: -0.5)],
        [CGPoint(x: -0.26, y: 0.4), CGPoint(x: 0.18, y: 0.46), CGPoint(x: 0.0, y: 0.06), CGPoint(x: 0.26, y: -0.2), CGPoint(x: 0.06, y: -0.48), CGPoint(x: -0.27, y: -0.4)],
        [CGPoint(x: 0.12, y: -0.5), CGPoint(x: 0.12, y: 0.5), CGPoint(x: -0.3, y: -0.14), CGPoint(x: 0.3, y: -0.14)],
        [CGPoint(x: 0.26, y: 0.48), CGPoint(x: -0.2, y: 0.48), CGPoint(x: -0.24, y: 0.04), CGPoint(x: 0.14, y: 0.08), CGPoint(x: 0.28, y: -0.24), CGPoint(x: 0.06, y: -0.5), CGPoint(x: -0.27, y: -0.4)],
        [CGPoint(x: 0.22, y: 0.46), CGPoint(x: -0.12, y: 0.3), CGPoint(x: -0.27, y: -0.2), CGPoint(x: -0.04, y: -0.5), CGPoint(x: 0.24, y: -0.28), CGPoint(x: 0.08, y: -0.02), CGPoint(x: -0.25, y: -0.14)],
        [CGPoint(x: -0.28, y: 0.48), CGPoint(x: 0.3, y: 0.48), CGPoint(x: -0.06, y: -0.5)],
        [CGPoint(x: 0.0, y: 0.02), CGPoint(x: -0.22, y: 0.24), CGPoint(x: 0.0, y: 0.48), CGPoint(x: 0.22, y: 0.24), CGPoint(x: 0.0, y: 0.02), CGPoint(x: -0.25, y: -0.24), CGPoint(x: 0.0, y: -0.5), CGPoint(x: 0.25, y: -0.24), CGPoint(x: 0.0, y: 0.02)],
        [CGPoint(x: 0.24, y: 0.14), CGPoint(x: 0.0, y: -0.02), CGPoint(x: -0.24, y: 0.22), CGPoint(x: 0.0, y: 0.48), CGPoint(x: 0.24, y: 0.22), CGPoint(x: 0.16, y: -0.2), CGPoint(x: -0.2, y: -0.5)],
    ]

    func digit(_ n: Int, h: CGFloat) -> StampRecipe {
        let tone = pen.style == .hose ? GesturePen.hoseCream : pen.tone(Tone(0xffe9a8), .cream)
        let strokes = GestureProps.digitStrokes[max(1, min(9, n))]
        let smoothed = n != 1 && n != 4 && n != 7
        return StampRecipe(kind: .digit, tint: n, half: h * 0.75 + pen.unit * 3 + 1) { p in
            let pts = strokes.map { CGPoint(x: $0.x * h, y: $0.y * h) }
            p.mark(pts, tone, alpha: 1, w: max(0.9, h * 0.16 / p.unit), smooth: smoothed, seed: n)
        }
    }

    func tally(t: CGFloat, alpha: CGFloat) {
        let r = stage.rect
        let tick = GestureMotion.countTick
        let head = stage.local(r.midX, r.maxY)
        let h = max(4.5, 0.26 * s)
        let n = Int(t / tick)
        for back in 0..<2 {
            let k = n - back
            guard k >= 0 else { continue }
            let age = t - CGFloat(k) * tick
            let q = age / (tick * 1.7)
            guard q < 1 else { continue }
            let pop = min(1, GestureMotion.backOut(age / 0.18, 2.2))
            let fade = 1 - GestureMotion.smooth((q - 0.45) / 0.55)
            let side: CGFloat = k % 2 == 0 ? 1 : -1
            let c = CGPoint(x: head.x + stage.face * 0.12 * s + side * 0.07 * s, y: head.y + 0.12 * s + 0.45 * s * q)
            put(digit(k % 9 + 1, h: h), at: c, rot: -0.1 * side, sx: pop, sy: pop, alpha: alpha * fade, needed: back == 0)
        }
        let palm = max(2.4, 0.11 * s)
        let tone = glove()
        let st = StampRecipe(kind: .glove, tint: 1, half: palm * 1.9 + pen.unit * 3 + 1) { p in
            p.shape(GesturePen.ring(CGPoint(x: -palm * 0.85, y: -palm * 0.1), palm * 0.42, palm * 0.6, n: 8, rot: 0.6), tone, alpha: 1, w: 0.8, seed: 1)
            p.shape(GesturePen.ring(.zero, palm, palm * 1.08, n: 10), tone, alpha: 1, w: 0.8, seed: 2)
        }
        let eyes = stage.local(r.maxX * 0.62, r.minY + r.height * 0.62)
        let bob = 0.015 * s * sin(t * 2 * .pi / tick)
        put(st, at: CGPoint(x: eyes.x, y: eyes.y + bob), rot: -stage.face * 0.5, sx: stage.face, sy: 1, alpha: alpha, needed: true)
    }

    func impact(t: CGFloat, alpha: CGFloat) {
        let r = stage.rect
        let f = stage.face
        let wind = GestureMotion.kickWind
        if t > wind * 0.4, t < wind + 0.06 {
            let q = (t - wind * 0.4) / (wind * 0.6 + 0.06)
            let foot = stage.local(r.minX * 0.6, r.minY + 0.1)
            let tone = soft()
            var pts: [CGPoint] = []
            for j in 0..<5 {
                let a = CGFloat.pi * (1.1 + 0.18 * CGFloat(j)) * 1
                pts.append(CGPoint(x: foot.x + f * cos(a) * 0.22 * s, y: foot.y + 0.12 * s + sin(a) * 0.18 * s))
            }
            pen.mark(pts, tone, alpha: alpha * sin(q * .pi) * 0.7, w: 0.8, seed: 2)
        }
        let start = wind + GestureMotion.kickSnap * 0.55
        let age = t - start
        guard age > 0, age < 0.32 else { return }
        let q = age / 0.32
        let spot = stage.local(r.maxX + 0.1, r.minY + 0.14)
        let k = 0.6 + 0.6 * GestureMotion.backOut(min(1, q / 0.35), 2)
        put(burstRecipe(tint: 0), at: spot, rot: 0.3 * q, sx: k, sy: k, alpha: alpha * (1 - GestureMotion.smooth((q - 0.35) / 0.65)), needed: true)
        let sk = max(2.2, 0.13 * s) * (1 - q) / starRef
        put(star(4, tint: 9), at: spot, rot: q * 2, sx: sk, sy: sk, alpha: alpha * (1 - q))
    }
}
