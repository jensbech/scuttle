import Foundation

public enum LidMood: String, CaseIterable, Codable, Sendable {
    case bright
    case tease
    case dusk
    case dark
    case deep
}

public enum LidArrival: String, CaseIterable, Codable, Sendable {
    case none
    case slam
    case steady
    case slow
}

struct LidTurn {
    var time: Double
    var angle: Double
}

struct LidSense {
    var previous = 110.0
    var velocity = 0.0
    var bandTime = 0.0
    var deepTime = 0.0
    var deepGrace = 0.0
    var direction = 0
    var extreme = 110.0
    var turns: [LidTurn] = []
    var shakeUntil = -1.0
    var shakeLevel = 0.0
    var pulse = false
    var onset = false
    var armed = true
    var arrival = LidArrival.none
    var arrivals = 0
}

extension World {
    public var lidArrival: LidArrival { lid.arrival }
    public var isJiggling: Bool { time < lid.shakeUntil }
    public var lidVelocity: Double { lid.velocity }
    public var deepSeconds: Double { lid.deepTime }

    func senseLid(_ h: Double) {
        let t = tuning
        let a = lidAngle
        let raw = (a - lid.previous) / h
        lid.previous = a
        lid.velocity += (raw - lid.velocity) * (1 - exp(-h / max(1e-3, t.lidVelocitySmoothing)))
        if raw == 0 && abs(lid.velocity) < 1e-3 { lid.velocity = 0 }
        lid.pulse = false
        lid.onset = false
        trackTurns(a)
        if !isJiggling { lid.shakeLevel = 0 }
        trackArrival(a)
        if a >= t.peekLowAngle && a <= t.peekHighAngle && lid.velocity < t.peekSteadyRate {
            lid.bandTime += h
        } else {
            lid.bandTime = 0
        }
        if a < t.deepAngle && light < 0.02 {
            lid.deepTime += h
            lid.deepGrace = 0
        } else if lid.deepTime > 0 {
            lid.deepGrace += h
            if lid.deepGrace > t.deepGrace {
                lid.deepTime = 0
                lid.deepGrace = 0
            }
        }
        mood = currentMood(a)
    }

    func currentMood(_ a: Double) -> LidMood {
        let t = tuning
        if a < t.deepAngle { return .deep }
        if light <= t.duskLight { return .dark }
        if isDarkNow { return .dusk }
        if a >= t.peekLowAngle && a <= t.peekHighAngle { return .tease }
        return .bright
    }

    private func trackTurns(_ a: Double) {
        let swing = max(0.1, tuning.jiggleMinSwing)
        switch lid.direction {
        case 1:
            if a > lid.extreme {
                lid.extreme = a
            } else if a < lid.extreme - swing {
                turn(at: lid.extreme)
                lid.direction = -1
                lid.extreme = a
            }
        case -1:
            if a < lid.extreme {
                lid.extreme = a
            } else if a > lid.extreme + swing {
                turn(at: lid.extreme)
                lid.direction = 1
                lid.extreme = a
            }
        default:
            if a > lid.extreme + swing {
                lid.direction = 1
                lid.extreme = a
            } else if a < lid.extreme - swing {
                lid.direction = -1
                lid.extreme = a
            }
        }
    }

    private func turn(at angle: Double) {
        let t = tuning
        lid.turns.append(LidTurn(time: time, angle: angle))
        lid.turns.removeAll { time - $0.time > t.jiggleWindow }
        if lid.turns.count > 12 { lid.turns.removeFirst(lid.turns.count - 12) }
        guard t.jiggleEnabled, lid.turns.count >= max(2, t.jiggleTurns) else { return }
        var low = Double.infinity
        var high = -Double.infinity
        var gap = 0.0
        for (i, p) in lid.turns.enumerated() {
            low = min(low, p.angle)
            high = max(high, p.angle)
            if i > 0 { gap = max(gap, p.time - lid.turns[i - 1].time) }
        }
        guard high - low <= t.jiggleMaxSpan, gap <= t.jiggleMaxGap else { return }
        if time >= lid.shakeUntil { lid.onset = true }
        lid.shakeUntil = time + t.jiggleHold
        let count = Double(lid.turns.count)
        lid.shakeLevel = min(1, max(lid.shakeLevel, (count - 2) / 5 + (high - low) / 25))
        lid.pulse = true
    }

    private func trackArrival(_ a: Double) {
        let t = tuning
        if !lid.armed && !isDarkNow && darkSeconds == 0 && a > t.arrivalProbeAngle {
            lid.armed = true
            lid.arrival = .none
            lid.arrivals = 0
        }
        guard lid.armed, a <= t.arrivalProbeAngle else { return }
        lid.armed = false
        lid.arrivals = 0
        let rate = max(0, -lid.velocity)
        if rate >= t.slamRate {
            lid.arrival = .slam
            cueBurst()
        } else if rate <= t.slowRate {
            lid.arrival = .slow
        } else {
            lid.arrival = .steady
        }
    }

    private func cueBurst() {
        let t = tuning
        guard t.slamBurst > 0 else { return }
        var picks: [Int] = []
        for i in bugs.indices where bugs[i].mode == .hidden && !bugs[i].retiring && !bugs[i].rare {
            picks.append(i)
        }
        picks.sort { a, b in
            bugs[a].emergeTimer != bugs[b].emergeTimer ? bugs[a].emergeTimer < bugs[b].emergeTimer : bugs[a].id < bugs[b].id
        }
        var at = 0.0
        for i in picks.prefix(t.slamBurst) {
            at += actRng.range(t.slamBurstSpacing)
            bugs[i].emergeTimer = min(bugs[i].emergeTimer, at)
        }
    }
}
