import Foundation

enum StrayBeat: Equatable {
    case bolt
    case look
    case dither
    case doubleBack
    case edgeRun
    case spin
    case freeze
    case spot
}

struct Stray {
    var started = false
    var exiting = false
    var beat = StrayBeat.bolt
    var clock = 0.0
    var length = 0.0
    var angle = 0.0
    var sign = 1.0
    var amp = 0.0
    var swings = 2.0
    var stage = 0
    var stageEnd = 0.0
    var stageAngle = 0.0
    var targetX = 0.0
    var targetY = 0.0
    var wall = Edge.bottom
    var movers: [StrayBeat] = []
    var stoppers: [StrayBeat] = []
    var lastMover = StrayBeat.bolt
    var elapsed = 0.0
    var alone = false
    var froze = false
    var aloneElapsed = 0.0
    var aloneTarget = 0.0
    var spotLength = 0.5
    var exit = Edge.bottom
}

struct StrayBox {
    var minX: Double
    var maxX: Double
    var minY: Double
    var maxY: Double
}

extension World {
    func considerStraggler(panic: Double) {
        let t = tuning
        guard panic >= t.confusedMinPanic else { return }
        guard !bugs.contains(where: { $0.stray != nil }) else { return }
        let roll = strayRng.unit()
        guard t.forceStraggler ?? (roll < t.confusedStragglerChance) else { return }
        let half = max(1, min(width, height) * 0.5)
        var picks: [(index: Int, weight: Double)] = []
        for strict in [true, false] where picks.isEmpty {
            for i in bugs.indices {
                let b = bugs[i]
                guard !b.retiring, !b.fading, !b.rare, b.mode == .fleeing || (b.mode == .startled && !b.flinchOnly) else { continue }
                let d = edgeDistance(b.x, b.y)
                guard d > b.size * 1.5, !strict || d >= t.confusedMinDepth else { continue }
                var weight = pow(min(1, d / half), 2) + 0.02
                if b.species.locomotion == .dart { weight *= max(0, t.confusedDartWeight) }
                if weight > 0 { picks.append((i, weight)) }
            }
        }
        guard !picks.isEmpty else { return }
        var total = 0.0
        for p in picks { total += p.weight }
        var pick = strayRng.unit() * total
        var chosen = picks[picks.count - 1].index
        for p in picks {
            pick -= p.weight
            if pick <= 0 {
                chosen = p.index
                break
            }
        }
        var b = bugs[chosen]
        var s = Stray()
        s.movers = shuffled([.doubleBack, .edgeRun, .bolt])
        s.stoppers = shuffled([.look, .dither, .spin])
        s.spotLength = strayRng.range(t.confusedSpot)
        b.stray = s
        if b.mode == .fleeing { startRoutine(&b) }
        bugs[chosen] = b
        pushEvent(.straggler)
    }

    func strayBox(_ b: Bug) -> StrayBox {
        let t = tuning
        let side = max(t.confusedMargin, b.size * 1.2)
        let top = max(t.confusedTopMargin, b.size * 1.2)
        let minX = min(side, width / 2)
        let minY = min(side, height / 2)
        return StrayBox(minX: minX, maxX: max(minX, width - side), minY: minY, maxY: max(minY, height - top))
    }

    func keepInBox(_ b: inout Bug, h: Double) {
        let box = strayBox(b)
        let tx = min(max(b.x, box.minX), box.maxX)
        let ty = min(max(b.y, box.minY), box.maxY)
        let dx = tx - b.x, dy = ty - b.y
        let d = hypot(dx, dy)
        if d > 1e-9 {
            let k = min(1, 160 * h / d)
            b.x += dx * k
            b.y += dy * k
        }
        let pad = b.size * 0.3
        b.x = min(max(b.x, pad), max(pad, width - pad))
        b.y = min(max(b.y, pad), max(pad, height - pad))
    }

    func strayStep(_ b: inout Bug, tr: SpeciesTraits, h: Double, safe: Bool) -> Double {
        guard var s = b.stray else { return 0 }
        let t = tuning
        if b.retiring {
            b.stray = nil
            if b.mode != .fleeing { beginFlee(&b, tr: tr) }
            return 0
        }
        if safe && lightRate <= 0.02 && b.x > 0 && b.y > 0 && b.x < width && b.y < height {
            b.stray = nil
            settle(&b)
            return 0
        }
        if !s.started {
            b.fleeElapsed += h
            b.panic = max(b.panic, panicLevel(rate: max(lightRate, peakRate)))
            b.speed *= exp(-h / 0.035)
            if b.speed < 0.5 { b.speed = 0 }
            b.timer -= h
            if b.timer <= 0 { startRoutine(&b) }
            return 0
        }
        if s.exiting {
            flee(&b, h: h)
            b.confusion = max(0, b.confusion - h / max(1e-3, t.confusedCalmTime))
            return 0
        }
        s.elapsed += h
        s.clock += h
        if !s.alone && !othersRunning {
            s.alone = true
            s.aloneTarget = strayRng.range(t.confusedDuration)
        }
        if s.alone && s.beat != .spot {
            s.aloneElapsed += h
            if !s.froze && s.aloneElapsed >= t.confusedRealiseDelay {
                s.froze = true
                begin(.freeze, &b, &s)
            } else if s.froze && s.beat != .freeze {
                let edge = exitEdge(for: b)
                if s.aloneElapsed + s.spotLength + exitEstimate(b, edge) >= s.aloneTarget {
                    begin(.spot, &b, &s)
                }
            }
        }
        if s.beat != .spot && s.elapsed > t.confusedMaxSeconds {
            begin(.spot, &b, &s)
        }
        if s.clock >= s.length {
            if s.beat == .spot {
                beginExit(&b, &s)
                b.stray = s
                return 0
            }
            begin(nextBeat(&s), &b, &s)
        }
        if s.beat == .spot {
            b.confusion = max(0, b.confusion - h / max(0.05, s.length * 0.8))
        } else {
            let rate = (s.beat == .freeze ? 2.5 : 1) / max(1e-3, t.confusedRampTime)
            b.confusion = min(1, b.confusion + h * rate)
        }
        let pivot = perform(&b, &s, h: h)
        b.stray = s
        return pivot
    }

    private func startRoutine(_ b: inout Bug) {
        guard var s = b.stray else { return }
        b.wrongWay = 0
        beginFlee(&b, tr: tuning.traits(for: b.species))
        s.started = true
        b.litTime = 0
        begin(.bolt, &b, &s)
        s.angle = wrap(outward(b.fleeEdge) + .pi + strayRng.signed() * 0.7)
        b.stray = s
    }

    private func exitTop(_ b: Bug) -> Double {
        min(tuning.fleeSpeedCap, b.fleeTop * max(0.5, tuning.confusedExitBoost))
    }

    private func exitEstimate(_ b: Bug, _ edge: Edge) -> Double {
        let dist = max(0, depth(b.x, b.y, from: edge)) + b.size * 0.6
        return dist / max(60, exitTop(b)) + tuning.fleeAccelTime * 0.5 + 0.1
    }

    private func beginExit(_ b: inout Bug, _ s: inout Stray) {
        s.exiting = true
        b.fleeEdge = s.exit
        b.fleeAim = strayRng.signed() * 0.15
        let estimate = exitEstimate(b, s.exit)
        b.fleeTop = exitTop(b)
        b.fleeElapsed = 0
        b.fleeDeadline = estimate * 1.2 + 0.3
        b.wrongWay = 0
        b.wobbleAmp *= 0.5
        b.litTime = 0
        b.mode = .fleeing
        b.confusion = 0
    }

    private func shuffled(_ beats: [StrayBeat]) -> [StrayBeat] {
        var out = beats
        if out.count < 2 { return out }
        for i in stride(from: out.count - 1, to: 0, by: -1) {
            let j = Int(strayRng.unit() * Double(i + 1)) % (i + 1)
            out.swapAt(i, j)
        }
        return out
    }

    private func nextBeat(_ s: inout Stray) -> StrayBeat {
        switch s.beat {
        case .bolt, .doubleBack, .edgeRun:
            if s.stoppers.isEmpty { s.stoppers = shuffled([.look, .dither]) }
            return s.stoppers.removeFirst()
        default:
            if s.movers.isEmpty { s.movers = shuffled([.doubleBack, .edgeRun, .bolt]) }
            if s.movers.count > 1 && s.movers[0] == s.lastMover { s.movers.swapAt(0, s.movers.count - 1) }
            s.lastMover = s.movers[0]
            return s.movers.removeFirst()
        }
    }

    private func begin(_ beat: StrayBeat, _ b: inout Bug, _ s: inout Stray) {
        let t = tuning
        let box = strayBox(b)
        s.beat = beat
        s.clock = 0
        s.stage = 0
        s.sign = strayRng.chance(0.5) ? 1 : -1
        let centre = atan2((box.minY + box.maxY) / 2 - b.y, (box.minX + box.maxX) / 2 - b.x)
        switch beat {
        case .bolt:
            s.length = strayRng.range(t.confusedBolt)
            s.angle = wrap(centre + strayRng.signed() * 1.4)
        case .look:
            s.length = strayRng.range(t.confusedLook)
            s.angle = b.course
            s.amp = strayRng.range(t.confusedLookSwing)
            s.swings = strayRng.range(1.5...2.5)
        case .dither:
            s.length = strayRng.range(t.confusedDither)
            s.angle = b.course
            s.stageEnd = strayRng.range(0.18...0.32)
            s.stageAngle = guardAngle(b, wrap(s.angle + strayRng.signed() * 1.4), box)
        case .doubleBack:
            s.amp = strayRng.range(t.confusedDoubleBack)
            s.length = s.amp * 2.1 + 0.3
            s.angle = wrap(centre + strayRng.signed() * 1.2)
        case .edgeRun:
            let gaps: [(Edge, Double)] = [
                (.left, b.x - box.minX), (.right, box.maxX - b.x),
                (.bottom, b.y - box.minY), (.top, box.maxY - b.y),
            ]
            var wall = Edge.left
            var gap = Double.infinity
            for (e, g) in gaps where g < gap {
                gap = g
                wall = e
            }
            if gap < b.size * 2 {
                let other = gaps.filter { $0.0 != wall }.min { $0.1 < $1.1 }
                wall = other?.0 ?? wall
                gap = other?.1 ?? gap
            }
            let dash = max(40, b.fleeTop * t.confusedRunFactor) * t.confusedEdgeRunBoost
            s.wall = wall
            let inset = b.size * 0.6
            let slide = strayRng.signed() * 70
            switch wall {
            case .left:
                s.targetX = box.minX + inset
                s.targetY = min(max(b.y + slide, box.minY), box.maxY)
            case .right:
                s.targetX = box.maxX - inset
                s.targetY = min(max(b.y + slide, box.minY), box.maxY)
            case .bottom:
                s.targetX = min(max(b.x + slide, box.minX), box.maxX)
                s.targetY = box.minY + inset
            case .top:
                s.targetX = min(max(b.x + slide, box.minX), box.maxX)
                s.targetY = box.maxY - inset
            }
            let dist = hypot(s.targetX - b.x, s.targetY - b.y)
            s.stageEnd = min(t.confusedEdgeRunMax, dist / dash * 1.3 + 0.3)
            s.amp = strayRng.range(t.confusedEdgePause)
            s.length = s.stageEnd + s.amp + 0.5
        case .spin:
            s.length = strayRng.range(t.confusedSpin)
        case .freeze:
            s.length = strayRng.range(t.confusedFreeze)
            s.angle = b.course
        case .spot:
            s.length = s.spotLength
            s.exit = exitEdge(for: b)
        }
    }

    private func guardAngle(_ b: Bug, _ angle: Double, _ box: StrayBox) -> Double {
        var a = angle
        let look = b.size * 1.5 + b.speed * 0.3
        if b.x - box.minX < look && cos(a) < 0 { a = .pi - a }
        if box.maxX - b.x < look && cos(a) > 0 { a = .pi - a }
        if b.y - box.minY < look && sin(a) < 0 { a = -a }
        if box.maxY - b.y < look && sin(a) > 0 { a = -a }
        return wrap(a)
    }

    private func drive(_ b: inout Bug, toward angle: Double, speed: Double, turn: Double, h: Double) {
        let d = wrap(angle - b.course)
        b.course = wrap(b.course + max(-turn, min(turn, d * 10)) * h)
        let target = speed * (0.3 + 0.7 * max(0, cos(d)))
        approach(&b.speed, target, rate: max(speed, 40) / 0.15, h: h)
    }

    private func brake(_ b: inout Bug, h: Double, tau: Double) {
        b.speed *= exp(-h / tau)
        if b.speed < 0.5 { b.speed = 0 }
    }

    private func pivot(_ b: inout Bug, toward angle: Double, rate: Double, h: Double) -> Double {
        let d = wrap(angle - b.course)
        let step = max(-rate, min(rate, d * 8)) * h
        b.course = wrap(b.course + step)
        return abs(step) * 0.3
    }

    private func perform(_ b: inout Bug, _ s: inout Stray, h: Double) -> Double {
        let t = tuning
        let run = max(40, b.fleeTop * t.confusedRunFactor)
        let box = strayBox(b)
        switch s.beat {
        case .bolt:
            b.mode = .fleeing
            let a = guardAngle(b, s.angle, box)
            if abs(wrap(a - s.angle)) > 0.01 {
                s.length = min(s.length, s.clock + 0.12)
                s.angle = a
            }
            drive(&b, toward: a, speed: run, turn: t.fleeTurnRate, h: h)
        case .look:
            b.mode = .startled
            brake(&b, h: h, tau: 0.06)
            let phase = s.clock / max(0.1, s.length) * s.swings * 2 * .pi
            let shaped = tanh(2.2 * sin(phase)) / tanh(2.2)
            return pivot(&b, toward: s.angle + s.sign * s.amp * shaped, rate: 7, h: h)
        case .dither:
            b.mode = .startled
            if s.clock >= s.stageEnd {
                s.stage += 1
                if s.stage % 2 == 0 {
                    s.stageEnd = s.clock + strayRng.range(0.18...0.32)
                    s.stageAngle = guardAngle(b, wrap(s.angle + strayRng.signed() * 1.4), box)
                } else {
                    s.stageEnd = s.clock + strayRng.range(0.15...0.3)
                    s.sign = -s.sign
                }
            }
            if s.stage % 2 == 0 {
                drive(&b, toward: s.stageAngle, speed: run * 0.4, turn: 9, h: h)
            } else {
                brake(&b, h: h, tau: 0.05)
                return pivot(&b, toward: s.stageAngle + s.sign * 0.7, rate: 6, h: h)
            }
        case .doubleBack:
            if s.clock < s.amp {
                b.mode = .fleeing
                drive(&b, toward: guardAngle(b, s.angle, box), speed: run, turn: t.fleeTurnRate, h: h)
            } else if s.clock < s.amp + 0.3 {
                b.mode = .startled
                brake(&b, h: h, tau: 0.05)
            } else {
                b.mode = .fleeing
                drive(&b, toward: guardAngle(b, wrap(s.angle + .pi), box), speed: run * 0.85, turn: 10, h: h)
            }
        case .edgeRun:
            if s.clock < s.stageEnd {
                b.mode = .fleeing
                let dx = s.targetX - b.x, dy = s.targetY - b.y
                let dist = hypot(dx, dy)
                if dist < 6 {
                    s.length -= s.stageEnd - s.clock
                    s.stageEnd = s.clock
                }
                drive(&b, toward: atan2(dy, dx), speed: min(run * t.confusedEdgeRunBoost, dist * 3 + 15), turn: 9, h: h)
            } else if s.clock < s.stageEnd + s.amp {
                b.mode = .startled
                brake(&b, h: h, tau: 0.04)
                let into = outward(s.wall)
                let peer = (s.clock - s.stageEnd) / max(0.1, s.amp)
                return pivot(&b, toward: into + s.sign * 0.45 * sin(peer * 2 * .pi), rate: 5, h: h)
            } else {
                b.mode = .fleeing
                drive(&b, toward: guardAngle(b, inward(s.wall) + s.sign * 0.5, box), speed: run * 0.6, turn: 7, h: h)
            }
        case .spin:
            b.mode = .startled
            approach(&b.speed, b.size * 1.2, rate: 200, h: h)
            let step = s.sign * 2 * .pi / max(0.3, s.length) * h
            b.course = wrap(b.course + step)
            return abs(step) * 0.3
        case .freeze:
            b.mode = .startled
            brake(&b, h: h, tau: 0.03)
            if s.clock > s.length * 0.6 {
                return pivot(&b, toward: s.angle + s.sign * 0.55, rate: 5, h: h)
            }
        case .spot:
            b.mode = .startled
            brake(&b, h: h, tau: 0.05)
            return pivot(&b, toward: outward(s.exit), rate: 6, h: h)
        }
        return 0
    }
}
