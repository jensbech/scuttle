import Foundation

public enum CatchQuirk: String, Codable, Sendable {
    case none
    case natural
    case glance
    case lookAround
    case wrongWay
    case slip
}

struct Beat {
    var start = 0.0
    var bolt = 0.0
    var windup = 0.2
    var quirk = CatchQuirk.none
    var look = 0.0
    var lookAt = 0.0
    var lookBack = 0.0
    var exit = Edge.bottom
    var turned = false
    var face = 1.0
}

struct CatchStage {
    var start = -Double.infinity
    var wake = false
    var count = 0
    var lastBolt = -Double.infinity
    var pending = false
    var woke = false
}

extension World {
    public var catchActive: Bool {
        time - stage.caught.start < 6 && bugs.contains { $0.beat != nil && $0.mode != .hidden }
    }

    public var catchStart: Double? {
        stage.caught.start.isFinite ? stage.caught.start : nil
    }

    public func wakeCatch() {
        stage.caught.woke = true
    }

    public func catchNow(since: Double = 0) {
        guard tuning.catchEnabled else { return }
        stage.caught.woke = true
        guard let first = bugs.indices.first(where: { catchable(bugs[$0]) && catchReady(bugs[$0]) }) else {
            stage.caught.woke = false
            return
        }
        var b = bugs[first]
        startle(&b, flinch: false)
        bugs[first] = b
        sweepCatch()
        let back = max(0, min(0.25, since))
        stage.caught.start -= back
        stage.caught.lastBolt -= back
        for i in bugs.indices where bugs[i].beat != nil {
            bugs[i].beat?.start -= back
            bugs[i].beat?.bolt -= back
            bugs[i].beat?.lookAt -= back
            bugs[i].beat?.lookBack -= back
            bugs[i].panic = max(bugs[i].panic, tuning.catchWakePanic)
            bugs[i].timer = max(0.05, bugs[i].timer - back)
        }
    }

    func catchable(_ b: Bug) -> Bool {
        b.mode != .hidden && b.beat == nil && b.stray == nil && !b.fading && b.peek == nil && (b.mode != .fleeing || b.sneak != nil)
    }

    var catchHolding: Bool {
        guard stage.caught.start.isFinite else { return false }
        return time < stage.caught.lastBolt && bugs.contains { $0.beat != nil && $0.mode == .startled }
    }

    func catchReady(_ b: Bug) -> Bool {
        tuning.catchEnabled && !b.retiring && b.stray == nil
    }

    func joinCatch(_ b: inout Bug) {
        let t = tuning
        let fresh = time - stage.caught.start > t.catchWindow
        if fresh {
            var c = CatchStage()
            c.start = time
            c.wake = stage.caught.woke
            c.pending = true
            stage.caught = c
        }
        var beat = Beat()
        let jitter = actRng.unit() * t.catchJitter
        beat.start = fresh ? time + jitter : max(time, stage.caught.start + jitter)
        let hold = actRng.range(t.catchHold) + (stage.caught.wake ? t.catchWakeHold : 0)
        beat.bolt = beat.start + t.catchReact + hold
        beat.windup = actRng.range(t.catchWindup)
        beat.exit = catchExit(b)
        beat.look = b.facing
        beat.face = b.facing
        b.beat = beat
        b.speed = 0
        b.dashStart = -1
        stage.caught.count += 1
        stage.caught.lastBolt = max(stage.caught.lastBolt, beat.bolt + beat.windup)
    }

    func sweepCatch() {
        guard stage.caught.pending else { return }
        stage.caught.pending = false
        stage.caught.woke = false
        let t = tuning
        for i in bugs.indices {
            var b = bugs[i]
            guard catchable(b) else { continue }
            if b.sneak != nil {
                b.sneak = nil
                b.backward = false
            }
            startle(&b, flinch: false)
            bugs[i] = b
        }
        var caught: [(index: Int, cost: Double)] = []
        for i in bugs.indices where bugs[i].beat != nil && bugs[i].mode == .startled {
            let b = bugs[i]
            guard let beat = b.beat, beat.start <= stage.caught.start + t.catchJitter + 1e-9 else { continue }
            caught.append((i, depth(b.x, b.y, from: beat.exit) / max(1, b.size)))
        }
        guard !caught.isEmpty else { return }
        caught.sort { $0.cost < $1.cost }
        let n = caught.count
        let spread = t.catchCascade * min(1, Double(n - 1) / 6)
        let base = stage.caught.start + t.catchReact + actRng.range(t.catchHold) + (stage.caught.wake ? t.catchWakeHold : 0)
        var last = -Double.infinity
        for (rank, item) in caught.enumerated() {
            guard var beat = bugs[item.index].beat else { continue }
            let u = n > 1 ? Double(rank) / Double(n - 1) : 0
            beat.bolt = base + spread * pow(u, 0.85) + actRng.signed() * 0.03
            bugs[item.index].beat = beat
            last = max(last, beat.bolt + beat.windup)
        }
        stage.caught.lastBolt = last
        assignQuirks(caught.map(\.index))
    }

    private func assignQuirks(_ ids: [Int]) {
        let t = tuning
        guard ids.count >= 2 else { return }
        var free = Set(ids)
        func grounded(_ i: Int) -> Bool { !bugs[i].species.isAirborne }
        if ids.count >= 3, t.forceCatchQuirk == nil || t.forceCatchQuirk == .glance {
            var best: (Int, Int, Double)?
            for a in ids where free.contains(a) {
                for b in ids where b > a && free.contains(b) {
                    let A = bugs[a], B = bugs[b]
                    let d = hypot(A.x - B.x, A.y - B.y) / max(1, (A.size + B.size) / 2)
                    guard d < t.catchGlanceRange, abs(A.x - B.x) > (A.size + B.size) * 0.25 else { continue }
                    if best == nil || d < best!.2 { best = (a, b, d) }
                }
            }
            if let (a, b, _) = best, t.forceCatchQuirk == .glance || actRng.chance(t.catchGlanceChance) {
                let at = stage.caught.start + t.catchReact + actRng.range(0.1...0.2)
                for (me, other) in [(a, b), (b, a)] {
                    guard var beat = bugs[me].beat else { continue }
                    beat.quirk = .glance
                    beat.look = bugs[other].x > bugs[me].x ? 1 : -1
                    beat.lookAt = at + (me == a ? 0 : 0.12)
                    beat.lookBack = min(beat.bolt - 0.08, beat.lookAt + 0.55)
                    bugs[me].beat = beat
                    free.remove(me)
                }
            }
        }
        let order = ids.filter { free.contains($0) }
        guard !order.isEmpty else { return }
        func take(_ want: CatchQuirk, chance: Double, where ok: (Int) -> Bool) {
            guard t.forceCatchQuirk == nil || t.forceCatchQuirk == want else { return }
            guard t.forceCatchQuirk == want || actRng.chance(chance) else { return }
            let pool = order.filter { free.contains($0) && ok($0) }
            guard !pool.isEmpty else { return }
            let i = pool[pick(pool.count)]
            guard var beat = bugs[i].beat else { return }
            beat.quirk = want
            switch want {
            case .natural:
                beat.bolt += 0.12
            case .lookAround:
                beat.lookAt = stage.caught.start + t.catchReact + 0.05
                beat.look = -bugs[i].facing
            case .slip:
                beat.windup = t.catchSlipWindup
            case .wrongWay:
                bugs[i].wrongWay = actRng.range(t.wrongWay)
            default:
                break
            }
            bugs[i].beat = beat
            free.remove(i)
        }
        let crowd = ids.count
        take(.natural, chance: crowd >= 4 ? t.catchNaturalChance : 0, where: { grounded($0) && self.bugs[$0].species.stance == .upright })
        take(.lookAround, chance: crowd >= 3 ? t.catchLookChance : 0, where: grounded)
        take(.wrongWay, chance: crowd >= 5 ? t.catchWrongWayChance : 0, where: { _ in true })
        take(.slip, chance: crowd >= 4 ? t.catchSlipChance : 0, where: { grounded($0) && self.bugs[$0].species.locomotion != .hop })
        for i in ids {
            guard let beat = bugs[i].beat else { continue }
            stage.caught.lastBolt = max(stage.caught.lastBolt, beat.bolt + beat.windup)
        }
    }

    func catchStep(_ b: inout Bug, tr: SpeciesTraits, h: Double, safe: Bool) {
        guard var beat = b.beat else { return }
        b.fleeElapsed += h
        if !b.retiring { b.panic = max(b.panic, panicLevel(rate: max(lightRate, peakRate))) }
        b.speed *= exp(-h / 0.02)
        if b.speed < 0.5 { b.speed = 0 }
        let now = time
        if now >= beat.bolt && safe && lightRate <= 0 && !stage.caught.wake {
            b.beat = nil
            settle(&b)
            return
        }
        switch beat.quirk {
        case .glance:
            b.facing = now >= beat.lookAt && now < beat.lookBack ? beat.look : beat.face
        case .lookAround:
            if now >= beat.lookAt && now < beat.bolt - 0.1 {
                let k = Int(((now - beat.lookAt) / 0.28).rounded(.down))
                b.facing = k % 2 == 0 ? beat.look : -beat.look
            }
        default:
            break
        }
        if now >= beat.bolt {
            if !beat.turned {
                beat.turned = true
                beat.exit = catchExit(b)
                let out = outward(beat.exit)
                b.course = out
                b.heading = out
                let c = cos(out)
                if abs(c) > 0.25 { b.facing = c > 0 ? 1 : -1 }
                if b.wrongWay > 0 {
                    let wrong = out + .pi
                    let cw = cos(wrong)
                    if abs(cw) > 0.25 { b.facing = cw > 0 ? 1 : -1 }
                }
            }
            if !b.species.isAirborne && b.species.locomotion != .hop {
                b.gaitPhase += h * 9
            }
            b.beat = beat
            if now >= beat.bolt + beat.windup {
                launch(&b, tr: tr)
            }
            return
        }
        b.beat = beat
    }

    func catchFacing(_ b: Bug) -> Double {
        guard let beat = b.beat, b.mode == .startled, !beat.turned, beat.quirk == .glance else { return b.facing }
        let now = time
        if now < beat.lookAt { return beat.face }
        if now < beat.lookBack {
            let u = min(1, (now - beat.lookAt) / 0.16)
            let e = u * u * (3 - 2 * u)
            return beat.face + (beat.look - beat.face) * e
        }
        let u = min(1, (now - beat.lookBack) / 0.08)
        return beat.look + (beat.face - beat.look) * u
    }

    func catchExit(_ b: Bug) -> Edge {
        let t = tuning
        var best = Edge.bottom
        var cost = Double.infinity
        for e in Edge.allCases {
            var c = max(0, depth(b.x, b.y, from: e)) + b.size
            switch e {
            case .left, .right: c *= t.catchSideBias
            case .top: c *= t.catchTopBias
            case .bottom: break
            }
            if c < cost {
                cost = c
                best = e
            }
        }
        return best
    }

    func launch(_ b: inout Bug, tr: SpeciesTraits) {
        let t = tuning
        let exit = b.beat?.exit
        beginFlee(&b, tr: tr)
        if let exit { b.fleeEdge = exit }
        b.fleeAim *= 0.5
        if b.wrongWay > 0 { b.wrongHeading = wrap(outward(b.fleeEdge) + .pi + actRng.signed() * 0.5) }
        b.fleeDeadline = t.catchDashDeadline + (b.wrongWay > 0 ? b.wrongWay : 0)
        b.wobbleAmp *= 0.45
        b.dashStart = time
        b.dashX = b.x
        b.dashY = b.y
        b.speed = max(b.speed, b.fleeTop * t.catchLaunch)
        b.course = b.wrongWay > 0 ? b.wrongHeading : outward(b.fleeEdge) + b.fleeAim
        b.heading = b.course
    }
}
