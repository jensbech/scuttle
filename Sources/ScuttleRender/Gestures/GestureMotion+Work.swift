import Foundation
import CoreGraphics
import ScuttleCore

extension GestureMotion {
    static func strainStep(_ i: GestureInput, clock: CGFloat, reach: CGFloat) -> CGFloat {
        switch i.locomotion {
        case .walk: return frac(1 + reach * sin(clock * 2 * .pi))
        case .hop: return 0.04 + 0.16 * (0.5 + 0.5 * sin(clock * 2 * .pi))
        default: return frac(clock * 0.5)
        }
    }

    static func carryBob(gait: CGFloat, t: CGFloat, moving: Bool) -> CGFloat {
        moving ? abs(sin(gait * 2 * .pi)) : 0.5 + 0.5 * sin(t * 2 * .pi / 1.9)
    }

    static func carry(_ i: GestureInput) -> GestureLook {
        var l = GestureLook()
        let s = i.size
        l.mood = .calm
        if i.locomotion.isFlying {
            l.lean = -0.06
            l.dy = -0.05 * s
            l.sy = -0.03
            l.sx = 0.02
            return l
        }
        l.lean = 0.07
        l.sy = 0.05
        l.sx = -0.03
        l.px = 0
        l.py = -0.46 * s
        if i.moving {
            let w = i.gait * 2 * .pi
            l.rise = 0.022 * s * abs(sin(w))
            l.tilt = 0.04 * sin(w)
            l.sy += 0.02 * abs(sin(w))
        } else {
            still(i, &l)
            let br = carryBob(gait: i.gait, t: i.t, moving: false)
            l.sy += 0.02 * br
            l.tilt = 0.025 * sin(i.t * 2 * .pi / 3.1 + i.seed)
        }
        return l
    }

    static func push(_ i: GestureInput) -> GestureLook {
        var l = GestureLook()
        let s = i.size
        l.mood = .fleeing
        let clock = i.moving ? i.gait : i.t * 1.4 + hash(i.seed)
        let w = clock * 2 * .pi
        if i.locomotion.isFlying {
            l.lean = -0.24 - 0.03 * sin(w * 2)
            l.dx = -i.facing * 0.03 * s * (0.5 + 0.5 * sin(w * 2))
            return l
        }
        let heave = 0.5 + 0.5 * sin(w * 2)
        l.lean = -0.3 - 0.05 * heave
        l.sy = -0.07 + 0.025 * heave
        l.sx = 0.05 - 0.015 * heave
        l.dx = -i.facing * 0.025 * s * heave
        l.phase = strainStep(i, clock: clock, reach: 0.075)
        l.lift = 0
        l.twitch = sin(w) > 0 ? 1 : -1
        return l
    }

    static func tug(_ i: GestureInput) -> CGFloat {
        let period: CGFloat = 0.95
        let u = frac((i.t + hash(i.seed + 4) * period) / period)
        return u < 0.1 ? smooth(u / 0.1) : exp(-(u - 0.1) * 7)
    }

    static func pull(_ i: GestureInput) -> GestureLook {
        var l = GestureLook()
        let s = i.size
        let k = tug(i)
        l.mood = k > 0.35 ? .fleeing : .calm
        if k <= 0.35 { l.blink = true }
        if i.locomotion.isFlying {
            l.lean = 0.22 + 0.1 * k
            l.dx = -i.facing * (0.04 + 0.06 * k) * s
            return l
        }
        l.lean = 0.27 + 0.11 * k
        l.dx = -i.facing * (0.02 + 0.06 * k) * s
        l.sy = -0.05 - 0.04 * k
        l.sx = 0.03 + 0.03 * k
        if i.moving {
            l.phase = strainStep(i, clock: i.gait, reach: 0.07)
        } else {
            switch i.locomotion {
            case .walk: l.phase = 0.22
            case .hop: l.phase = 0.1 + 0.06 * k
            default: l.phase = 0
            }
        }
        l.lift = 0
        l.twitch = k > 0.5 ? 1 : -1
        return l
    }

    static let buildHits = 4
    static let buildHit: CGFloat = 0.55
    static let buildAdmire: CGFloat = 1.5

    static func buildLoop(_ i: GestureInput) -> (hit: CGFloat?, admire: CGFloat?) {
        let work = CGFloat(buildHits) * buildHit
        let loop = work + buildAdmire
        let c = frac((i.t + hash(i.seed + 6) * work) / loop) * loop
        if c < work { return (frac(c / buildHit), nil) }
        return (nil, (c - work) / buildAdmire)
    }

    static func build(_ i: GestureInput) -> GestureLook {
        var l = GestureLook()
        let s = i.size
        l.mood = .calm
        l.px = 0
        l.py = -0.46 * s
        let phase = buildLoop(i)
        if let u = phase.hit {
            still(i, &l)
            var lean: CGFloat, sy: CGFloat, rise: CGFloat = 0
            if u < 0.5 {
                let w = smooth(u / 0.5)
                lean = 0.08 * w
                sy = 0.05 * w
                rise = 0.03 * s * w
            } else if u < 0.62 {
                let w = smooth((u - 0.5) / 0.12)
                lean = 0.08 - 0.32 * w
                sy = 0.05 - 0.15 * w
                rise = 0.03 * s * (1 - w)
            } else {
                let w = (u - 0.62) / 0.38
                let ring = exp(-w * 5) * cos(w * 9)
                lean = -0.24 * ring
                sy = -0.1 * ring
            }
            l.lean = lean
            l.sy = sy
            l.sx = -0.6 * sy
            l.rise = rise
            l.blink = u > 0.52 && u < 0.7
            if i.locomotion.isFlying {
                l.rise = 0
                l.dy = -0.06 * s * max(0, -lean / 0.24)
            }
        } else if let v = phase.admire {
            let back = sin(min(1, v / 0.85) * .pi)
            let hopU = (v - 0.3) / 0.35
            l.dx = -i.facing * 0.2 * s * smooth(min(1, v / 0.4)) * (1 - smooth((v - 0.75) / 0.25))
            l.lean = 0.07 * back
            l.blink = v > 0.3 && v < 0.75
            l.rise = hopU > 0 && hopU < 1 ? 0.06 * s * sin(hopU * .pi) : 0
            l.shadow = -0.3 * (l.rise / max(0.001, 0.06 * s))
            l.tilt = 0.06 * sin(v * 2 * .pi * 2)
            if !i.locomotion.isFlying {
                if i.locomotion == .walk {
                    l.phase = v < 0.4 || v > 0.75 ? frac(v * 2.5) : 0
                } else {
                    l.phase = 0
                }
                l.lift = 0
            }
        }
        return l
    }

    static let countTick: CGFloat = 0.85

    static func count(_ i: GestureInput) -> GestureLook {
        var l = GestureLook()
        let s = i.size
        still(i, &l)
        l.mood = .calm
        l.blink = true
        l.twitch = 0
        let u = frac(i.t / countTick)
        let nod = exp(-u * 7) * sin(min(1, u / 0.6) * .pi)
        l.lean = -0.13 - 0.05 * nod
        l.face = i.facing * 0.72
        l.sy = -0.04 - 0.035 * nod
        l.sx = 0.02
        l.dy = -0.01 * s * nod
        l.tilt = 0.02 * sin(i.t * 2 * .pi / 2.3)
        l.px = 0
        l.py = -0.46 * s
        if i.locomotion.isFlying {
            l.dy -= 0.04 * s
        }
        return l
    }

    static let kickWind: CGFloat = 0.32
    static let kickSnap: CGFloat = 0.1

    static func kick(_ i: GestureInput) -> GestureLook {
        var l = GestureLook()
        let s = i.size
        let t = i.t
        let snapEnd = kickWind + kickSnap
        l.px = 0
        l.py = -0.46 * s
        l.lift = 0
        if t < kickWind {
            let w = smooth(t / kickWind)
            l.lean = 0.24 * w
            l.dx = -i.facing * 0.06 * s * w
            l.sy = -0.06 * w
            l.sx = 0.04 * w
            l.mood = .calm
            switch i.locomotion {
            case .walk: l.phase = frac(1 - 0.22 * w)
            case .hop: l.phase = 0.04 + 0.1 * w
            default: l.phase = 0
            }
        } else if t < snapEnd {
            let q = (t - kickWind) / kickSnap
            let e = backOut(q, 2)
            l.lean = 0.24 - 0.48 * e
            l.dx = i.facing * s * (-0.06 + 0.12 * e)
            l.sy = -0.06 + 0.14 * e
            l.sx = 0.04 - 0.1 * e
            l.rise = 0.04 * s * sin(q * .pi)
            l.mood = .fleeing
            switch i.locomotion {
            case .walk: l.phase = frac(0.78 + 0.47 * q)
            case .hop: l.phase = 0.3
            default: l.phase = 0
            }
        } else {
            let v = t - snapEnd
            let settle = exp(-v * 4.5)
            l.lean = -0.24 * settle * cos(v * 7)
            l.dx = i.facing * 0.06 * s * settle
            l.sy = 0.08 * settle * cos(v * 9)
            l.sx = -0.05 * settle * cos(v * 9)
            l.mood = v < 0.25 ? .fleeing : .calm
            let ready = smooth((v - 0.4) / 0.3)
            l.rise = 0.025 * s * abs(sin(v * 5.5)) * ready
            l.phase = i.locomotion == .walk ? frac(0.25 * settle) : 0
        }
        if i.locomotion.isFlying {
            l.phase = nil
            l.lift = nil
            l.rise = 0
        }
        return l
    }
}
