import Foundation
import CoreGraphics
import ScuttleCore

enum ScreenEdge {
    case bottom
    case top
    case left
    case right

    static func nearest(to p: CGPoint, in bounds: CGSize) -> ScreenEdge {
        guard bounds.width > 0, bounds.height > 0 else { return .bottom }
        let d: [(ScreenEdge, CGFloat)] = [
            (.bottom, p.y), (.top, bounds.height - p.y), (.left, p.x), (.right, bounds.width - p.x),
        ]
        return d.min { $0.1 < $1.1 }!.0
    }

    var inward: CGPoint {
        switch self {
        case .bottom: return CGPoint(x: 0, y: 1)
        case .top: return CGPoint(x: 0, y: -1)
        case .left: return CGPoint(x: 1, y: 0)
        case .right: return CGPoint(x: -1, y: 0)
        }
    }

    func depth(of p: CGPoint, in bounds: CGSize) -> CGFloat {
        switch self {
        case .bottom: return p.y
        case .top: return bounds.height - p.y
        case .left: return p.x
        case .right: return bounds.width - p.x
        }
    }

    var spin: CGFloat {
        switch self {
        case .bottom: return 0
        case .top: return .pi
        case .left: return -.pi / 2
        case .right: return .pi / 2
        }
    }
}

struct GestureLook {
    var dx: CGFloat = 0
    var dy: CGFloat = 0
    var rise: CGFloat = 0
    var tilt: CGFloat = 0
    var px: CGFloat = 0
    var py: CGFloat = 0
    var spin: CGFloat = 0
    var lean: CGFloat = 0
    var sx: CGFloat = 0
    var sy: CGFloat = 0
    var face: CGFloat?
    var shadow: CGFloat = 0
    var mood: Mood?
    var phase: CGFloat?
    var lift: CGFloat?
    var blink: Bool?
    var twitch: CGFloat?

    mutating func add(_ o: GestureLook, _ w: CGFloat, base: CGFloat) {
        guard w > 0.0001 else { return }
        dx += o.dx * w
        dy += o.dy * w
        rise += o.rise * w
        if abs(o.tilt) > 0.0001 {
            let total = abs(tilt) + abs(o.tilt * w)
            let k = abs(o.tilt * w) / max(0.0001, total)
            px += (o.px - px) * k
            py += (o.py - py) * k
        }
        tilt += o.tilt * w
        spin += o.spin * w
        lean += o.lean * w
        sx += o.sx * w
        sy += o.sy * w
        shadow += o.shadow * w
        if let f = o.face {
            face = (face ?? base) + (f - base) * w
        }
        if w >= 0.5 {
            if let v = o.mood { mood = v }
            if let v = o.phase { phase = v }
            if let v = o.lift { lift = v }
            if let v = o.blink { blink = v }
            if let v = o.twitch { twitch = v }
        }
    }
}

struct GestureInput {
    var gesture: Gesture
    var t: CGFloat
    var leaving: CGFloat?
    var size: CGFloat
    var seed: CGFloat
    var facing: CGFloat
    var heading: CGFloat
    var position: CGPoint
    var bounds: CGSize
    var grounded: Bool
    var locomotion: Locomotion
    var gait: CGFloat
    var moving = false
    var extent = CGRect(x: -0.45, y: -0.46, width: 0.9, height: 0.92)
}

enum GestureMotion {
    static func smooth(_ x: CGFloat) -> CGFloat {
        let u = max(0, min(1, x))
        return u * u * (3 - 2 * u)
    }

    static func backOut(_ x: CGFloat, _ k: CGFloat = 1.7) -> CGFloat {
        let u = max(0, min(1, x)) - 1
        return 1 + u * u * ((k + 1) * u + k)
    }

    static func frac(_ x: CGFloat) -> CGFloat { x - x.rounded(.down) }

    static func hash(_ a: CGFloat) -> CGFloat { frac(sin(a * 12.9898 + 78.233) * 43758.5453) }

    static func entry(_ g: Gesture) -> CGFloat {
        switch g {
        case .peek, .popUp, .parachute, .tumble, .wave, .cheer: return 0.1
        case .kick: return 0.05
        case .build: return 0.2
        case .sleep: return 0.9
        case .perch: return 0.45
        case .shiver: return 0.25
        default: return 0.35
        }
    }

    static func exit(_ g: Gesture) -> CGFloat {
        switch g {
        case .parachute: return 0.75
        case .peek: return 0.5
        case .sleep: return 0.7
        case .tumble: return 0.5
        case .popUp: return 0.4
        case .kick: return 0.25
        default: return 0.35
        }
    }

    static func turn(_ u: CGFloat, hold a: CGFloat, hold b: CGFloat, swap: CGFloat = 0.2) -> CGFloat {
        let p = a + b
        let v = frac(u / p) * p
        if v < swap { return -1 + 2 * smooth(v / swap) }
        if v < a { return 1 }
        if v < a + swap { return 1 - 2 * smooth((v - a) / swap) }
        return -1
    }

    static func look(_ i: GestureInput) -> GestureLook {
        switch i.gesture {
        case .none: return GestureLook()
        case .peek: return peek(i)
        case .tiptoe: return tiptoe(i)
        case .wave: return wave(i)
        case .dance: return dance(i)
        case .cheer: return cheer(i)
        case .sleep: return sleep(i)
        case .look: return gaze(i)
        case .shiver: return shiver(i)
        case .tumble: return tumble(i)
        case .parachute: return parachute(i)
        case .popUp: return popUp(i)
        case .perch: return perch(i)
        case .carry: return carry(i)
        case .push: return push(i)
        case .pull: return pull(i)
        case .build: return build(i)
        case .count: return count(i)
        case .kick: return kick(i)
        }
    }

    static func still(_ i: GestureInput, _ l: inout GestureLook) {
        guard !i.locomotion.isFlying else { return }
        l.phase = 0
        l.lift = 0
    }

    static func peekReveal(_ i: GestureInput) -> CGFloat {
        let t = i.t
        let rise = backOut(t / 0.9, 1.2)
        var r = 0.62 + 0.05 * sin(t * 1.35 + i.seed) + 0.025 * sin(t * 3.1 + i.seed * 2)
        let period = 5.6 + 1.4 * hash(i.seed)
        let u = (t - 2.6 - 1.7 * hash(i.seed + 3)).truncatingRemainder(dividingBy: period)
        if t > 2.6, u >= 0, u < 1.05 {
            let down = smooth(u / 0.12)
            let up = u < 0.45 ? 0 : backOut((u - 0.45) / 0.6, 2.2)
            let low: CGFloat = 0.06
            r = r + (low - r) * down * (1 - up)
        }
        var reveal = r * rise
        if let q = i.leaving { reveal *= 1 - smooth(q * 1.3) }
        return reveal
    }

    static func peekDucked(_ i: GestureInput) -> Bool {
        let period = 5.6 + 1.4 * hash(i.seed)
        let u = (i.t - 2.6 - 1.7 * hash(i.seed + 3)).truncatingRemainder(dividingBy: period)
        return i.t > 2.6 && u >= 0 && u < 0.7
    }

    static func peek(_ i: GestureInput) -> GestureLook {
        var l = GestureLook()
        let s = i.size
        let edge = ScreenEdge.nearest(to: i.position, in: i.bounds)
        let depth = edge.depth(of: i.position, in: i.bounds)
        let reveal = peekReveal(i)
        let inward = i.bounds.width > 0 ? (i.position.x < i.bounds.width / 2 ? 1 : -1) : i.facing
        let lookSide = inward * turn(i.t + 0.6 + hash(i.seed + 1), hold: 1.7, hold: 1.4, swap: 0.22)
        l.shadow = -1
        still(i, &l)
        l.mood = .calm
        l.twitch = lookSide > 0 ? 1 : -1
        if peekDucked(i) { l.blink = true }
        if depth > edgeReach * s {
            let low = 1 - min(1, reveal / 0.62)
            l.face = lookSide
            l.dx = lookSide * 0.05 * s
            l.sy = -0.22 * low + 0.03 * sin(i.t * 1.35 + i.seed)
            l.sx = 0.12 * low
            l.tilt = -0.08 * lookSide
            l.px = 0
            l.py = -0.46 * s
            l.shadow = 0
            return l
        }
        switch edge {
        case .bottom, .top:
            let up: CGFloat = edge == .bottom ? 1 : -1
            let top = i.extent.maxY * s, height = i.extent.height * s
            let centre = reveal * height - top
            l.dy = up * (centre - depth)
            l.dx = lookSide * 0.05 * s
            l.face = lookSide
            if edge == .top {
                l.spin = .pi
                l.px = 0
                l.py = centre
                l.tilt = 0.12 * sin(i.t * 1.7 + i.seed) + 0.05 * lookSide
            } else {
                l.tilt = -0.07 * lookSide
                l.px = 0
                l.py = -0.46 * s
            }
        case .left, .right:
            let side: CGFloat = edge == .left ? 1 : -1
            let front = i.extent.maxX * s
            let centre = reveal * 0.62 * i.extent.width * s - front
            l.dx = side * (centre - depth)
            l.face = side
            let nod = turn(i.t + hash(i.seed + 2) * 2, hold: 1.9, hold: 1.3, swap: 0.3)
            l.tilt = -side * (0.34 + 0.1 * nod) * (0.4 + 0.6 * min(1, reveal / 0.5))
            l.px = 0
            l.py = -0.46 * s
            l.twitch = nod > 0 ? 1 : -1
        }
        return l
    }

    static func tiptoe(_ i: GestureInput) -> GestureLook {
        var l = GestureLook()
        let s = i.size
        let u = frac(i.gait * 2)
        let lift = sin(u * .pi)
        if i.locomotion.isFlying {
            l.rise = 0.08 * s * lift
            l.lean = 0.16
            l.sy = 0.05 * lift
            return l
        }
        let high = pow(lift, 1.6)
        l.rise = 0.17 * s * high
        l.lean = 0.17 + 0.06 * high
        let land = max(0, 1 - u / 0.18)
        l.sy = 0.09 * high - 0.08 * land
        l.sx = -0.04 * high + 0.06 * land
        l.dx = -i.facing * 0.03 * s * high
        l.shadow = -0.25 * high
        l.twitch = frac(i.gait) < 0.5 ? 1 : -1
        if i.locomotion == .hop {
            l.phase = 0.08
            l.lift = 0
        }
        return l
    }

    static func wave(_ i: GestureInput) -> GestureLook {
        var l = GestureLook()
        let s = i.size
        let t = i.t
        still(i, &l)
        l.mood = .calm
        if t < 0.34 {
            let u = t / 0.34
            l.rise = 0.24 * s * 4 * u * (1 - u)
            l.sy = 0.1 * sin(u * .pi)
            l.sx = -0.05 * sin(u * .pi)
        } else if t < 0.5 {
            let u = (t - 0.34) / 0.16
            l.sy = -0.12 * sin(u * .pi)
            l.sx = 0.07 * sin(u * .pi)
        }
        let a = smooth((t - 0.3) / 0.4)
        l.tilt = 0.11 * sin((t - 0.3) * 2 * .pi * 1.4) * a
        l.px = 0
        l.py = -0.46 * s
        if t > 0.5, t < 1.2 { l.blink = true }
        return l
    }

    static func dance(_ i: GestureInput) -> GestureLook {
        var l = GestureLook()
        let s = i.size
        let b = i.t * 2.1
        let bf = frac(b)
        let hop = sin(bf * .pi)
        l.rise = 0.1 * s * hop
        let land = exp(-bf * 9)
        l.sy = 0.07 * hop - 0.13 * land
        l.sx = -0.04 * hop + 0.09 * land
        l.tilt = 0.15 * sin(b * .pi)
        l.px = 0
        l.py = -0.46 * s
        l.dx = 0.06 * s * sin(b * .pi)
        let bar = frac(b / 8)
        l.face = i.facing * (bar < 0.5 ? 1 : -1)
        if bar > 0.45 && bar < 0.5 { l.face = i.facing * (1 - 2 * smooth((bar - 0.45) / 0.05)) }
        if bar > 0.95 { l.face = i.facing * (-1 + 2 * smooth((bar - 0.95) / 0.05)) }
        l.shadow = -0.25 * hop
        l.mood = .calm
        l.blink = Int(b.rounded(.down)) % 8 >= 6
        l.twitch = sin(b * .pi) > 0 ? 1 : -1
        if !i.locomotion.isFlying {
            l.phase = i.locomotion == .hop ? 0.1 : frac(b / 2)
            l.lift = 0
        }
        return l
    }

    static func cheerHop(_ t: CGFloat) -> (rise: CGFloat, sx: CGFloat, sy: CGFloat, air: Bool) {
        let c = frac(t / 1.55) * 1.55
        func arc(_ a: CGFloat, _ b: CGFloat, _ h: CGFloat) -> CGFloat {
            let u = (c - a) / (b - a)
            return h * 4 * u * (1 - u)
        }
        func squash(_ a: CGFloat, _ b: CGFloat, _ k: CGFloat) -> CGFloat {
            k * sin((c - a) / (b - a) * .pi)
        }
        if c < 0.3 { return (arc(0, 0.3, 0.24), -0.05, 0.1, true) }
        if c < 0.38 { let q = squash(0.3, 0.38, 0.14); return (0, q * 0.7, -q, false) }
        if c < 0.8 { return (arc(0.38, 0.8, 0.42), -0.06, 0.13, true) }
        if c < 0.95 { let q = squash(0.8, 0.95, 0.18); return (0, q * 0.7, -q, false) }
        return (0, 0, 0, false)
    }

    static func cheer(_ i: GestureInput) -> GestureLook {
        var l = GestureLook()
        let s = i.size
        let h = cheerHop(i.t)
        still(i, &l)
        l.rise = h.rise * s
        l.sx = h.sx
        l.sy = h.sy
        l.mood = .calm
        l.blink = h.air
        let c = frac(i.t / 1.55) * 1.55
        l.tilt = h.air ? 0.1 * sin(c * 14) : 0
        l.px = 0
        l.py = -0.46 * s
        l.shadow = -0.5 * min(1, h.rise / 0.42)
        if i.locomotion == .hop, h.air {
            l.phase = 0.55
            l.lift = 0
        }
        return l
    }

    static func sleep(_ i: GestureInput) -> GestureLook {
        var l = GestureLook()
        let s = i.size
        let br = sin(i.t * 2 * .pi / 3.6)
        l.phase = i.locomotion == .hop ? 0.04 : 0
        l.lift = 0
        l.sy = -0.07 + 0.035 * br
        l.sx = 0.045 - 0.02 * br
        l.lean = 0.05
        l.mood = .calm
        l.blink = true
        l.twitch = 0
        l.shadow = 0.15
        if i.locomotion.isFlying {
            l.dy = -0.12 * s
            l.rise = 0.02 * s * br
            l.shadow = 0.3
        } else {
            l.dy = -0.015 * s
        }
        return l
    }

    static func gazeSide(_ i: GestureInput) -> CGFloat {
        let along = cos(i.heading)
        let base: CGFloat = abs(along) > 0.5 && i.facing * along < 0 ? (along > 0 ? 1 : -1) : i.facing
        let t = i.t
        if t < 1.7 { return base }
        return base * -turn(t - 1.7, hold: 1.6, hold: 1.4, swap: 0.25)
    }

    static func gaze(_ i: GestureInput) -> GestureLook {
        var l = GestureLook()
        let s = i.size
        let side = gazeSide(i)
        let up = CGFloat(sin(i.heading))
        still(i, &l)
        l.face = side
        l.tilt = -side * 0.22 + (up > 0 ? side * 0.06 * up : -side * 0.08 * up)
        l.px = 0
        l.py = -0.46 * s
        l.dx = side * 0.05 * s
        l.lean = -0.06
        l.sy = 0.07 * max(0, up) - 0.05 * max(0, -up)
        l.sx = -0.03 * max(0, up) + 0.03 * max(0, -up)
        l.rise = 0.03 * s * max(0, up)
        l.twitch = side * i.facing > 0 ? 1 : -1
        l.mood = .calm
        return l
    }

    static func shiver(_ i: GestureInput) -> GestureLook {
        var l = GestureLook()
        let s = i.size
        let t = i.t
        still(i, &l)
        l.dx = 0.028 * s * sin(t * 2 * .pi * 11) + 0.01 * s * sin(t * 2 * .pi * 17 + 1)
        l.tilt = 0.035 * sin(t * 2 * .pi * 7.3)
        l.px = 0
        l.py = -0.46 * s
        l.sy = -0.08 + 0.015 * sin(t * 2 * .pi * 9)
        l.sx = 0.05
        l.mood = .fleeing
        l.twitch = sin(t * 2 * .pi * 6) > 0 ? 1 : -1
        return l
    }

    static let rollTime: CGFloat = 0.62

    static func tumble(_ i: GestureInput) -> GestureLook {
        var l = GestureLook()
        let s = i.size
        let t = i.t
        still(i, &l)
        l.mood = .dizzy
        l.shadow = 0
        if t < rollTime {
            let u = t / rollTime
            let e = 1 - (1 - u) * (1 - u)
            l.spin = -i.facing * 2 * .pi * 2 * e
            l.rise = 0.12 * s * abs(sin(e * 2 * .pi))
            l.sx = -0.1 * sin(u * .pi)
            l.sy = -0.1 * sin(u * .pi)
            l.dy = 0.04 * s
        } else {
            let v = t - rollTime
            l.tilt = 0.3 * exp(-3.2 * v) * sin(13 * v) * i.facing
            l.px = 0
            l.py = -0.46 * s
            let q = exp(-10 * v)
            l.sy = -0.2 * q
            l.sx = 0.14 * q
        }
        return l
    }

    static func parachute(_ i: GestureInput) -> GestureLook {
        var l = GestureLook()
        let s = i.size
        let t = i.t
        let sway = sin(t * 2 * .pi / 2.3 + i.seed)
        l.tilt = 0.17 * sway
        l.px = 0
        l.py = 1.12 * s
        l.lean = -0.05 * sin(t * 2 * .pi / 2.3 + i.seed - 0.8)
        l.shadow = -1
        l.mood = t < 0.35 ? .startled : .calm
        if !i.locomotion.isFlying {
            l.phase = i.locomotion == .hop ? 0.55 : frac(t * 0.35)
            l.lift = 0
        }
        l.sy = 0.04
        l.sx = -0.03
        if let q = i.leaving {
            let k = sin(min(1, q / 0.4) * .pi)
            l.sy = -0.2 * k
            l.sx = 0.14 * k
            l.tilt *= 1 - smooth(q * 3)
            l.shadow = -1 + smooth(q * 2.5)
            l.phase = 0
        }
        return l
    }

    static let edgeReach: CGFloat = 1.6

    static func popOffset(_ i: GestureInput) -> (edge: ScreenEdge, perp: CGFloat, start: CGFloat) {
        let edge = ScreenEdge.nearest(to: i.position, in: i.bounds)
        let depth = edge.depth(of: i.position, in: i.bounds)
        let reach: CGFloat
        switch edge {
        case .bottom: reach = i.extent.maxY
        case .top: reach = -i.extent.minY
        case .left, .right: reach = i.extent.maxX
        }
        let start = max(-2.4 * i.size, min(0, -(reach + 0.06) * i.size - depth))
        return (edge, depth, start)
    }

    static func popUp(_ i: GestureInput) -> GestureLook {
        var l = GestureLook()
        let s = i.size
        let t = i.t
        let pop = popOffset(i)
        let side = pop.edge == .left || pop.edge == .right
        still(i, &l)
        if pop.perp > edgeReach * s {
            let g = backOut(t / 0.32, 2.4)
            let v = max(0, t - 0.32)
            let q = t < 0.32 ? 0 : exp(-7 * v) * sin(17 * v)
            l.sx = -0.85 * (1 - g) - 0.12 * q - (t < 0.32 ? 0.12 * sin(t / 0.32 * .pi) : 0)
            l.sy = -0.85 * (1 - g) + 0.18 * q + (t < 0.32 ? 0.25 * sin(t / 0.32 * .pi) : 0)
            l.mood = t < 0.28 ? .startled : .calm
            if t > 0.62, t < 0.72 { l.blink = true }
            l.shadow = -1 + smooth(t / 0.3)
            return l
        }
        var off: CGFloat = 0
        var long: CGFloat = 0, wide: CGFloat = 0
        let bump = (side ? 0.1 : 0.24) * s * min(1, -pop.start / (0.5 * s))
        if t < 0.17 {
            let u = t / 0.17
            let e = 1 - pow(1 - u, 3)
            off = pop.start + (bump - pop.start) * e
            long = 0.32 * (1 - u * 0.6)
            wide = -0.18 * (1 - u * 0.6)
        } else if t < 0.36 {
            let u = (t - 0.17) / 0.19
            off = bump * (1 - u * u)
            long = 0.1 * (1 - u)
            wide = -0.06 * (1 - u)
        } else {
            let v = t - 0.36
            let q = exp(-7 * v) * cos(17 * v)
            l.sy = -0.2 * q
            l.sx = 0.14 * q
        }
        let n = pop.edge.inward
        l.dx = n.x * off
        l.dy = n.y * off
        if side {
            l.sx += long
            l.sy += wide
            l.rise = t < 0.36 ? 0.32 * s * sin(min(1, t / 0.36) * .pi) : 0
            l.face = n.x
            l.tilt = t < 0.36 ? -n.x * 0.3 * cos(min(1, t / 0.36) * .pi) : 0
            l.px = 0
            l.py = 0
        } else {
            l.sy += long
            l.sx += wide
        }
        l.mood = t < 0.28 ? .startled : .calm
        if t > 0.62, t < 0.72 { l.blink = true }
        l.shadow = pop.edge == .top ? -1 : -1 + smooth((t - 0.3) / 0.2)
        return l
    }

    static func perch(_ i: GestureInput) -> GestureLook {
        var l = GestureLook()
        let s = i.size
        let t = i.t
        still(i, &l)
        l.sy = -0.07 + 0.012 * sin(t * 2 * .pi / 3.4)
        l.sx = 0.05
        l.tilt = 0.04 * sin(t * 2 * .pi / 4.2 + i.seed)
        l.px = 0
        l.py = -0.46 * s
        l.mood = .calm
        l.shadow = 0.25
        l.dy = -0.01 * s
        return l
    }
}

extension Locomotion {
    var isFlying: Bool {
        switch self {
        case .flutter, .hover, .float, .dart: return true
        case .crawl, .walk, .hop: return false
        }
    }
}
