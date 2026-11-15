import Foundation

struct Act {
    var kind: Gesture
    var delay = 0.0
    var clock = 0.0
    var length = 0.0
    var flip = 0.55
    var waking = false
}

extension World {
    public var gestureCounts: [Gesture: Int] {
        var out: [Gesture: Int] = [:]
        for c in critters where c.gesture != .none { out[c.gesture, default: 0] += 1 }
        return out
    }

    func scheduleActs(_ h: Double) {
        let t = tuning
        stage.actClock -= h
        stage.greetCooldown -= h
        stage.rippleCooldown -= h
        guard stage.actClock <= 0 else { return }
        stage.actClock = actRng.range(t.actTick)
        guard stage.visible > 0, light < t.duskLight, !isJiggling else { return }
        if lidAngle < t.deepAngle { deepActs() }
        greet()
    }

    private func collect(_ test: (Bug) -> Bool) -> [Int] {
        var pool = stage.picks
        pool.removeAll(keepingCapacity: true)
        for i in bugs.indices where test(bugs[i]) { pool.append(i) }
        return pool
    }

    private func deepActs() {
        let t = tuning
        let deep = lid.deepTime
        if t.playEnabled && deep >= t.rippleAfter && stage.rippleCooldown <= 0 && (t.forceRipple ?? actRng.chance(t.rippleChance)) {
            stage.rippleCooldown = actRng.range(t.rippleCooldown)
            ripple()
            return
        }
        if t.playEnabled && deep >= t.playAfter {
            let playing = playingNow()
            let cap = playCap()
            if playing < cap && actRng.chance(t.playChance) {
                let pool = collect { $0.free && self.onScreen($0) }
                if !pool.isEmpty {
                    let i = pool[pick(pool.count)]
                    var b = bugs[i]
                    let dance = actRng.chance(0.55)
                    b.act = Act(kind: dance ? .dance : .cheer, length: actRng.range(dance ? t.danceLength : t.cheerLength))
                    bugs[i] = b
                }
                stage.picks = pool
            }
        }
        if t.sleepEnabled && deep >= t.sleepAfter {
            let ramp = clamp01((deep - t.sleepAfter) / max(1, t.sleepRamp))
            let target = Int((Double(stage.visible) * max(0, t.sleepShare) * ramp).rounded(.up))
            var sleeping = 0
            for b in bugs where b.act?.kind == .sleep && b.mode != .hidden { sleeping += 1 }
            if sleeping < target {
                let pool = collect { b in
                    b.free && b.mode == .resting && self.onScreen(b) && (!b.species.isAirborne || b.species.locomotion == .float)
                }
                if !pool.isEmpty {
                    let i = pool[pick(pool.count)]
                    bugs[i].act = Act(kind: .sleep, length: actRng.range(t.sleepLength))
                }
                stage.picks = pool
            }
        }
    }

    private func ripple() {
        let t = tuning
        let forward = actRng.chance(0.5)
        for i in bugs.indices {
            let b = bugs[i]
            guard b.free, onScreen(b) else { continue }
            let u = clamp01(b.x / max(1, width))
            let delay = 0.1 + (forward ? u : 1 - u) * max(0, t.rippleSpan)
            bugs[i].act = Act(kind: .cheer, delay: delay, length: actRng.range(0.8...1.1))
        }
    }

    private func greet() {
        let t = tuning
        guard darkSeconds >= t.greetAfter, stage.greetCooldown <= 0 else { return }
        guard t.forceGreeting ?? actRng.chance(t.greetChance) else { return }
        let centre = min(width, height) * max(0, t.greetCentre)
        let pool = collect { b in
            b.free && b.species.stance == .upright && !b.species.isAirborne && self.edgeDistance(b.x, b.y) > centre
        }
        defer { stage.picks = pool }
        guard !pool.isEmpty else { return }
        let i = pool[pick(pool.count)]
        bugs[i].act = Act(kind: .wave, length: actRng.range(t.greetLength))
        stage.greetCooldown = actRng.range(t.greetCooldown)
    }

    func actStep(_ b: inout Bug, tr: SpeciesTraits, h: Double) -> Double? {
        guard var a = b.act else { return nil }
        let t = tuning
        if a.delay > 0 {
            a.delay -= h
            if a.delay <= 0 {
                a.delay = 0
                b.mode = .resting
            }
            b.act = a
            if a.delay > 0 { return nil }
        }
        a.clock += h
        if a.kind == .sleep && !a.waking {
            let stirred = lidAngle > t.deepAngle + t.wakeMargin || lid.velocity > t.wakeRate || isJiggling
            if stirred || a.clock >= a.length {
                a.waking = true
                a.kind = .look
                a.clock = 0
                a.length = actRng.range(t.wakeLength)
            }
        }
        b.mode = .resting
        if b.species.isAirborne {
            switch a.kind {
            case .dance: hover(&b, tr: tr, h: h, spin: 2.6, scale: 1.6)
            case .sleep: hover(&b, tr: tr, h: h, spin: 0.3, scale: 0.5)
            default: hover(&b, tr: tr, h: h)
            }
        } else {
            brake(&b, tau: 0.08, h: h)
            if b.species.locomotion == .hop { b.speed = 0 }
            if a.kind == .dance {
                a.flip -= h
                if a.flip <= 0 {
                    a.flip = 0.55
                    b.facing = -b.facing
                    b.facingHold = 0.3
                }
            }
        }
        if a.clock >= a.length {
            b.act = nil
            startBurst(&b, tr: tr)
            return 0
        }
        b.act = a
        return 0
    }
}
