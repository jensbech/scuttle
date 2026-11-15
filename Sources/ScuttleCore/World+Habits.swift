import Foundation

public enum HabitKind: String, CaseIterable, Codable, Sendable {
    case pace
    case lookAround = "lookaround"
    case sniff
    case circle
    case zigzag
    case loop
    case zip
    case drift
    case spin
    case patrol
}

struct Habit {
    var kind: HabitKind
    var stage = 0
    var clock = 0.0
    var total = 0.0
    var length = 0.0
    var count = 0
    var sign = 1.0
    var angle = 0.0
    var speed = 0.0
    var x = 0.0
    var y = 0.0
    var homeX = 0.0
    var homeY = 0.0
    var gesture = Gesture.none
    var aloft = false
    var flipped = false
}

extension World {
    public var habitCounts: [HabitKind: Int] {
        var out: [HabitKind: Int] = [:]
        for b in bugs where b.mode != .hidden {
            if let k = b.habit { out[k.kind, default: 0] += 1 }
        }
        return out
    }

    func habitKinds(for b: Bug) -> [(HabitKind, Double)] {
        switch b.species.locomotion {
        case .crawl: return [(.sniff, 1), (.circle, 0.8), (.pace, 0.8)]
        case .walk: return [(.pace, 1), (.lookAround, 1), (.sniff, 0.6)]
        case .hop: return [(.zigzag, 1), (.lookAround, b.species == .owl ? 3 : 0.8)]
        case .flutter: return [(.loop, 1), (.circle, 1)]
        case .hover: return [(.zip, 1), (.circle, 0.7)]
        case .float: return b.species.stance == .topDown ? [(.drift, 1), (.spin, 1)] : [(.drift, 1)]
        case .dart: return [(.patrol, 1), (.zip, 0.6)]
        }
    }

    func considerHabit(_ b: inout Bug) {
        let t = tuning
        guard t.habitsEnabled, max(light, targetLight) < t.duskLight, !isJiggling, darkSeconds >= t.habitAfter else { return }
        guard b.stray == nil, !b.retiring, !b.fading, !b.scripted, onScreen(b), edgeDistance(b.x, b.y) > b.size * 1.5 else { return }
        let cap = max(1, Int(Double(stage.visible) * max(0, t.habitShare)))
        guard stage.census.habits < cap else { return }
        let kinds = habitKinds(for: b)
        var kind: HabitKind
        if let forced = t.forceHabit {
            guard kinds.contains(where: { $0.0 == forced }) else { return }
            kind = forced
        } else {
            guard socialRng.chance(t.habitChance) else { return }
            var total = 0.0
            for k in kinds { total += k.1 }
            var roll = socialRng.unit() * total
            kind = kinds[kinds.count - 1].0
            for k in kinds {
                roll -= k.1
                if roll <= 0 {
                    kind = k.0
                    break
                }
            }
        }
        let tr = t.traits(for: b.species)
        let pace = paceOf(b, tr)
        var k = Habit(kind: kind)
        k.sign = socialRng.chance(0.5) ? 1 : -1
        k.homeX = b.x
        k.homeY = b.y
        switch kind {
        case .pace:
            k.angle = b.course
            if edgeDistance(b.x, b.y) < b.size * 4 {
                k.angle = alongDirection(nearestEdge(b.x, b.y)) + (k.sign > 0 ? 0 : .pi)
            }
            k.speed = max(8, pace * 0.7)
            k.length = b.size * 1.3 / k.speed + 0.15
        case .lookAround:
            k.length = b.species == .owl ? socialRng.range(2.2...3.2) : socialRng.range(1.4...2.2)
            k.gesture = .look
        case .sniff:
            k.speed = max(6, pace * 0.6)
            k.length = 0.25
        case .circle:
            k.speed = max(8, pace * 0.6)
            k.length = socialRng.range(2.6...3.4)
        case .zigzag:
            k.angle = b.course
            k.speed = max(8, pace * 0.9)
            k.length = 3.5
        case .loop:
            k.speed = min(tuning.fleeSpeedCap * 0.5, max(20, pace * 1.5))
            k.length = socialRng.range(1.4...1.8)
        case .zip:
            k.speed = min(200, max(60, pace * 3.2))
            k.length = 0.22
            k.angle = socialRng.unit() * 2 * .pi
        case .drift:
            k.sign = b.y > height - b.size * 4 ? -1 : 1
            k.speed = max(6, pace * 0.8)
            k.length = socialRng.range(1.6...2.4)
        case .spin:
            k.speed = max(4, pace * 0.3)
            k.length = socialRng.range(1.5...2.5)
        case .patrol:
            let goal = safeGoal(b, angle: socialRng.unit() * 2 * .pi, distance: socialRng.range(140...220))
            k.x = goal.x
            k.y = goal.y
            k.speed = min(220, max(60, pace))
            k.length = 6
        }
        b.habit = k
        stage.census.habits += 1
    }

    func habitStep(_ b: inout Bug, tr: SpeciesTraits, h: Double) -> Double {
        guard var k = b.habit else { return 0 }
        let t = tuning
        k.clock += h
        k.total += h
        if max(light, targetLight) > t.duskLight || overReach(b, slack: t.ceilingSlack * 4) || k.total > 12 {
            b.habit = nil
            resume(&b, tr: tr)
            return 0
        }
        var done = false
        switch k.kind {
        case .pace:
            if k.stage % 2 == 0 {
                steer(&b, toward: k.angle, rate: 6, h: h)
                approach(&b.speed, k.speed, rate: k.speed / 0.15, h: h)
                b.mode = .wandering
                if k.clock >= k.length {
                    k.stage += 1
                    k.clock = 0
                }
            } else {
                brake(&b, tau: 0.06, h: h)
                b.mode = b.speed > 1 ? .wandering : .resting
                if k.clock >= 0.45 {
                    k.stage += 1
                    k.clock = 0
                    k.angle = wrap(k.angle + .pi)
                    done = k.stage >= 4
                }
            }
        case .lookAround:
            settleStill(&b, tr: tr, h: h)
            b.mode = .resting
            if !k.flipped && k.clock > k.length * 0.45 {
                k.flipped = true
                b.facing = -b.facing
                b.facingHold = 0.3
            }
            done = k.clock >= k.length
        case .sniff:
            if k.stage % 2 == 0 {
                if k.clock <= h { b.course = wrap(b.course + socialRng.gauss() * 0.5) }
                approach(&b.speed, k.speed, rate: k.speed / 0.08, h: h)
                b.mode = .wandering
                if k.clock >= k.length {
                    k.stage += 1
                    k.clock = 0
                }
            } else {
                brake(&b, tau: 0.05, h: h)
                b.mode = b.speed > 1 ? .wandering : .resting
                if k.clock >= 0.35 {
                    k.stage += 1
                    k.clock = 0
                    done = k.stage >= 8
                }
            }
        case .circle:
            b.course = wrap(b.course + k.sign * 2.2 * h)
            approach(&b.speed, k.speed, rate: k.speed / 0.2, h: h)
            b.mode = .wandering
            done = k.clock >= k.length
        case .zigzag:
            if b.lift > 0 {
                k.aloft = true
            } else if k.aloft {
                k.aloft = false
                k.count += 1
                k.sign = -k.sign
            }
            if b.lift == 0 { b.course = wrap(k.angle + k.sign * 0.65) }
            b.speed = k.count >= 4 || k.clock > k.length ? 0 : k.speed
            b.mode = b.speed > 1 || b.lift > 0 ? .wandering : .resting
            done = (k.count >= 4 || k.clock > k.length) && b.lift == 0
        case .loop:
            b.course = wrap(b.course + k.sign * 2 * .pi / max(0.5, k.length) * h)
            approach(&b.speed, k.speed, rate: k.speed / 0.2, h: h)
            b.mode = .wandering
            done = k.clock >= k.length
        case .zip:
            if k.stage % 2 == 0 {
                var a = k.angle
                let pad = b.size * 2
                if (b.x < pad && cos(a) < 0) || (b.x > width - pad && cos(a) > 0) { a = .pi - a }
                if (b.y < pad && sin(a) < 0) || (b.y > height - pad && sin(a) > 0) { a = -a }
                k.angle = wrap(a)
                steer(&b, toward: k.angle, rate: 12, h: h)
                approach(&b.speed, k.speed, rate: k.speed / 0.06, h: h)
                b.mode = .wandering
                if k.clock >= k.length {
                    k.stage += 1
                    k.clock = 0
                }
            } else {
                hover(&b, tr: tr, h: h)
                b.mode = .resting
                if k.clock >= 0.45 {
                    k.stage += 1
                    k.clock = 0
                    k.angle = wrap(k.angle + socialRng.signed() * 2.2)
                    done = k.stage >= 6
                }
            }
        case .drift:
            let up = k.stage == 0 ? k.sign : -k.sign
            steer(&b, toward: up > 0 ? .pi / 2 : -.pi / 2, rate: 1.5, h: h)
            approach(&b.speed, k.speed, rate: k.speed / 0.6, h: h)
            b.mode = .wandering
            if k.clock >= k.length {
                k.stage += 1
                k.clock = 0
                done = k.stage >= 2
            }
        case .spin:
            b.course = wrap(b.course + k.sign * 4 * h)
            approach(&b.speed, k.speed, rate: k.speed / 0.3, h: h)
            b.mode = .resting
            done = k.clock >= k.length
        case .patrol:
            switch k.stage % 4 {
            case 0, 2:
                let tx = k.stage % 4 == 0 ? k.x : k.homeX
                let ty = k.stage % 4 == 0 ? k.y : k.homeY
                let d = seek(&b, x: tx, y: ty, pace: k.speed, tr: tr, h: h, arrive: 8, turn: 12)
                b.mode = .wandering
                if d < 12 || k.clock > 2.5 {
                    k.stage += 1
                    k.clock = 0
                }
            default:
                brake(&b, tau: 0.06, h: h)
                b.mode = .resting
                if k.clock >= 0.5 {
                    k.stage += 1
                    k.clock = 0
                    done = k.stage >= 8
                }
            }
            done = done || k.total > k.length * 2
        }
        if done {
            b.habit = nil
            resume(&b, tr: tr)
        } else {
            b.habit = k
        }
        return 0
    }
}
