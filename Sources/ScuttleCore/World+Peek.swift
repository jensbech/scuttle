import Foundation

enum PeekPhase: Equatable {
    case rise
    case watch
    case dare
    case duck
}

struct Peek {
    var edge: Edge
    var along: Double
    var phase = PeekPhase.rise
    var clock = 0.0
    var length = 0.0
    var rise = 0.8
    var depth = 0.0
    var low = 0.0
    var lookTimer = 0.0
    var slide = 0.0
    var lean = 0.0
    var duckRate = 0.0
    var dare = false
    var waving = 0.0

    var gesture: Gesture {
        phase == .dare && waving > 0 ? .wave : .peek
    }
}

extension World {
    public var peekerCount: Int {
        var n = 0
        for b in bugs where b.peek != nil && b.mode != .hidden { n += 1 }
        return n
    }

    func peekFraction() -> Double {
        let t = tuning
        let span = max(1e-3, t.peekHighAngle - t.peekLowAngle)
        return clamp01((t.peekHighAngle - lidAngle) / span)
    }

    func schedulePeeks(_ h: Double) {
        let t = tuning
        stage.peekGap -= h
        if lidAngle < t.peekLowAngle || lidAngle > t.peekHighAngle {
            stage.peekSession = 0
            stage.dared = false
            stage.peekGap = min(stage.peekGap, t.peekGap.lowerBound)
        }
        guard t.peekEnabled, t.peekMax > 0, lid.bandTime >= t.peekDwell, !isJiggling, stage.peekGap <= 0 else { return }
        guard t.peekGiveUp <= 0 || lid.bandTime < t.peekGiveUp else { return }
        let allowed = min(t.peekMax, 1 + Int(peekFraction() * Double(t.peekMax)))
        var peeking = 0
        for b in bugs where b.peek != nil { peeking += 1 }
        guard peeking < allowed else { return }
        guard let i = pickPeeker() else {
            stage.peekGap = 1
            return
        }
        var b = bugs[i]
        startPeek(&b)
        bugs[i] = b
        stage.peekGap = actRng.range(t.peekGap) * peekBoredom()
        noteEmerged(1)
    }

    private func pickPeeker() -> Int? {
        let t = tuning
        var pool = stage.picks
        pool.removeAll(keepingCapacity: true)
        for i in bugs.indices {
            let b = bugs[i]
            guard b.mode == .hidden, !b.retiring, !b.rare, time >= b.peekRest else { continue }
            pool.append(i)
        }
        defer { stage.picks = pool }
        guard !pool.isEmpty else { return nil }
        pool.sort { a, b in
            bugs[a].nerve != bugs[b].nerve ? bugs[a].nerve > bugs[b].nerve : bugs[a].id < bugs[b].id
        }
        let top = pool.prefix(max(1, t.peekPool))
        var total = 0.0
        for i in top { total += pow(max(0.01, bugs[i].nerve), 4) }
        var roll = actRng.unit() * total
        for i in top {
            roll -= pow(max(0.01, bugs[i].nerve), 4)
            if roll <= 0 { return i }
        }
        return top.last
    }

    private func peekEdge() -> Edge {
        let t = tuning
        let bottom = max(0, t.peekBottomWeight)
        let side = max(0, t.peekSideWeight)
        let total = bottom + side * 2
        guard total > 0 else { return .bottom }
        var roll = actRng.unit() * total
        roll -= bottom
        if roll <= 0 { return .bottom }
        roll -= side
        return roll <= 0 ? .left : .right
    }

    func startPeek(_ b: inout Bug) {
        let t = tuning
        let edge = peekEdge()
        let margin = min(max(t.entryCornerMargin, 0.1), 0.45)
        var p = Peek(edge: edge, along: span(edge) * actRng.range(margin...(1 - margin)))
        p.depth = -b.size * 0.95
        p.length = actRng.range(t.peekWatch)
        p.rise = actRng.range(t.peekRise)
        p.low = lidAngle
        p.lookTimer = actRng.range(t.peekLook)
        p.lean = actRng.signed() * 0.2
        stage.peekSession += 1
        if let forced = t.forcePeekDare {
            p.dare = forced
        } else if !stage.dared && stage.peekSession >= 2 && actRng.chance(t.peekDareChance) {
            p.dare = true
        }
        if p.dare { stage.dared = true }
        b.mode = .emerging
        b.entry = edge
        b.speed = 0
        b.targetSpeed = 0
        b.pace = 0
        b.lift = 0
        b.hopSpeed = 0
        b.alpha = 1
        b.fading = false
        b.litTime = 0
        b.flinched = false
        b.stray = nil
        b.confusion = 0
        b.bend = 0
        b.meander = 0
        b.peekTimer = 0
        b.goalTimer = 0
        clearScripts(&b)
        b.course = wrap(inward(edge) + p.lean)
        b.heading = b.course
        b.desired = b.course
        switch edge {
        case .left: b.facing = 1
        case .right: b.facing = -1
        default: b.facing = actRng.chance(0.5) ? 1 : -1
        }
        b.facingHold = 0
        if b.species.locomotion == .hop { b.gaitPhase = b.gaitPhase.rounded(.down) }
        b.peek = p
        placePeek(&b, p)
        refreshGesture(&b)
    }

    private func placePeek(_ b: inout Bug, _ p: Peek) {
        let s = span(p.edge)
        let a = min(max(p.along, b.size), max(b.size, s - b.size))
        let pt = point(on: p.edge, along: a, depth: p.depth)
        b.x = pt.x
        b.y = pt.y
    }

    func peekBoredom() -> Double {
        let t = tuning
        return lid.bandTime > t.peekPatience ? max(1, t.peekBoredScale) : 1
    }

    func peekTarget(_ b: Bug) -> Double {
        let t = tuning
        return b.size * (t.peekShallow + (t.peekDeep - t.peekShallow) * peekFraction())
    }

    func peekStep(_ b: inout Bug, tr: SpeciesTraits, h: Double) -> Double {
        guard var p = b.peek else { return 0 }
        let t = tuning
        p.clock += h
        p.low = min(p.low, lidAngle)
        let size = b.size
        if p.phase != .duck {
            let opened = lidAngle > t.peekHighAngle + 0.5 || lidAngle > p.low + t.peekDuckRise || lid.velocity > t.peekDuckRate
            if b.retiring || light >= t.fullLight || opened || isJiggling {
                p.phase = .duck
                p.duckRate = size * 1.9 / max(0.05, t.peekDuckTime)
                stage.peekGap = max(stage.peekGap, actRng.range(t.peekScareGap))
                b.peekRest = time + actRng.range(t.peekCooldown) * 0.5
            } else if light < b.nerve - t.nerveHysteresis && lightRate < t.startleRate * 0.5 {
                b.peek = nil
                creepSetup(&b, tr: tr, spread: 0.25)
                return 0
            }
        }
        let target = peekTarget(b)
        switch p.phase {
        case .rise:
            p.depth = min(target, p.depth + size * 1.25 / max(0.1, p.rise) * h)
            if p.depth >= target - 0.5 {
                p.phase = .watch
                p.clock = 0
            }
        case .watch:
            approach(&p.depth, target, rate: size * 0.8, h: h)
            lookAbout(&b, &p, h: h)
            if p.dare && p.clock > p.length * 0.4 {
                p.phase = .dare
                p.clock = 0
                p.slide = 0
            } else if p.clock >= p.length {
                p.phase = .duck
                p.duckRate = size * 1.9 / 0.7
                b.peekRest = time + actRng.range(t.peekCooldown)
                stage.peekGap = max(stage.peekGap, actRng.range(t.peekGap) * peekBoredom())
            }
        case .dare:
            let full = size * 1.15
            if p.waving <= 0 {
                approach(&p.depth, full, rate: size * 1.6, h: h)
                if p.depth >= full - 0.5 {
                    p.waving = actRng.range(t.peekDareWave)
                } else if p.clock > 4 {
                    p.phase = .duck
                    p.duckRate = size * 2.2 / 0.6
                }
            } else {
                p.waving -= h
                if p.waving <= 0 {
                    p.waving = 0
                    p.phase = .duck
                    p.duckRate = size * 2.2 / 0.6
                    b.peekRest = time + actRng.range(t.peekCooldown)
                    stage.peekGap = max(stage.peekGap, actRng.range(t.peekGap))
                }
            }
        case .duck:
            p.depth -= p.duckRate * h
            if p.depth <= -size * 0.95 {
                b.peekRest = max(b.peekRest, time + 1)
                let rest = b.peekRest
                hide(&b)
                b.peekRest = rest
                return 0
            }
        }
        let lean = p.lean * cos(p.clock * 0.8)
        b.course = wrap(inward(p.edge) + lean)
        b.speed = 0
        b.peek = p
        placePeek(&b, p)
        return 0
    }

    private func lookAbout(_ b: inout Bug, _ p: inout Peek, h: Double) {
        let t = tuning
        p.lookTimer -= h
        if p.lookTimer <= 0 {
            p.lookTimer = actRng.range(t.peekLook)
            if p.edge == .bottom {
                b.facing = -b.facing
            } else if actRng.chance(0.3) {
                b.facing = -b.facing
                p.lookTimer = min(p.lookTimer, 0.7)
            } else {
                b.facing = p.edge == .left ? 1 : -1
            }
            b.facingHold = 0.3
            if p.slide == 0 && actRng.chance(t.peekSlideChance) {
                p.slide = actRng.signed() * 70
                if abs(p.slide) < 25 { p.slide = p.slide < 0 ? -25 : 25 }
            }
        }
        if p.slide != 0 {
            let step = min(abs(p.slide), 45 * h) * (p.slide < 0 ? -1 : 1)
            let s = span(p.edge)
            let lo = s * 0.08, hi = s * 0.92
            let next = p.along + step
            if next < lo || next > hi {
                p.slide = 0
            } else {
                p.along = next
                p.slide -= step
                if abs(p.slide) < 0.5 { p.slide = 0 }
            }
        }
    }
}
