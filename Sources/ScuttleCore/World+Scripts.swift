import Foundation

struct Stage {
    var visible = 0
    var peekGap = 0.0
    var peekSession = 0
    var dared = false
    var entranceGap = 0.0
    var congaCooldown = 0.0
    var congaActive = false
    var congaDirty = false
    var congaIndex: [Int: Int] = [:]
    var actClock = 0.0
    var greetCooldown = 0.0
    var rippleCooldown = 0.0
    var waveByeGap = 0.0
    var picks: [Int] = []
    var ids: [Int: Int] = [:]
    var idsStamp = -1.0
    var census = Census()
    var social = SocialStage()
    var pointer = PointerStage()
    var perch = PerchStage()
    var yard = PropYard()
    var work = WorkStage()
    var caught = CatchStage()
}

struct Census {
    var social = 0
    var habits = 0
    var curious = 0
    var followers = 0
    var perchers = 0
    var docked = 0
    var playing = 0
    var sleepers = 0
    var workers = 0
    var errands = 0
    var players = 0
    var rare = -1
    var stray = -1
    var kinds: [SocialKind: Int] = [:]
}

extension Bug {
    var scripted: Bool {
        peek != nil || entrance != nil || act != nil || sneak != nil || shake != nil || ownScript
    }

    var ownScript: Bool {
        social != nil || lure != nil || perch != nil || habit != nil || job != nil
    }

    var calm: Bool {
        mode == .emerging || mode == .wandering || mode == .resting
    }

    var free: Bool {
        !scripted && stray == nil && !retiring && !fading && (mode == .wandering || mode == .resting)
    }
}

extension World {
    func direct(_ h: Double) {
        stage.entranceGap -= h
        stage.congaCooldown -= h
        stage.waveByeGap -= h
        indexConga()
        takeCensus()
        schedulePeeks(h)
        if lid.onset { beginShakes() }
        scheduleActs(h)
        sensePointer(h)
        tendPerches(h)
        runGroups(h)
        scheduleSocial(h)
        tendWork(h)
    }

    func scriptStep(_ b: inout Bug, tr: SpeciesTraits, h: Double, leave: Bool, safe: Bool) -> Double? {
        if b.sneak != nil { return sneakStep(&b, tr: tr, h: h, safe: safe) }
        if b.peek != nil { return peekStep(&b, tr: tr, h: h) }
        guard b.calm else {
            clearScripts(&b)
            return nil
        }
        if leave {
            depart(&b, tr: tr)
            return 0
        }
        if b.shake != nil { return shakeStep(&b, tr: tr, h: h) }
        if b.entrance != nil { return entranceStep(&b, tr: tr, h: h) }
        if b.act != nil { return actStep(&b, tr: tr, h: h) }
        if b.ownScript && lightRate > tuning.flinchRate && !b.flinched {
            clearScripts(&b)
            b.flinched = true
            startle(&b, flinch: true)
            return 0
        }
        if b.lure != nil { return lureStep(&b, tr: tr, h: h) }
        if b.perch != nil { return perchStep(&b, tr: tr, h: h) }
        if b.social != nil { return socialStep(&b, tr: tr, h: h) }
        if b.job != nil { return jobStep(&b, tr: tr, h: h) }
        if b.habit != nil { return habitStep(&b, tr: tr, h: h) }
        return nil
    }

    func clearScripts(_ b: inout Bug) {
        b.peek = nil
        b.entrance = nil
        b.act = nil
        b.sneak = nil
        b.shake = nil
        clearOwn(&b)
        b.backward = false
        b.glide = false
        b.restGesture = .none
    }

    func clearOwn(_ b: inout Bug) {
        b.social = nil
        b.lure = nil
        b.perch = nil
        b.habit = nil
        b.job = nil
        b.pinned = false
        b.backward = false
        b.glide = false
        if !b.fading && b.alpha < 1 { b.alpha = 1 }
    }

    func index(of id: Int) -> Int? {
        if let i = stage.ids[id], i < bugs.count, bugs[i].id == id { return i }
        guard stage.idsStamp != time else { return nil }
        stage.idsStamp = time
        stage.ids.removeAll(keepingCapacity: true)
        for i in bugs.indices { stage.ids[bugs[i].id] = i }
        return stage.ids[id]
    }

    func takeCensus() {
        var c = Census()
        c.kinds = stage.census.kinds
        c.kinds.removeAll(keepingCapacity: true)
        for i in bugs.indices {
            let b = bugs[i]
            guard b.mode != .hidden else { continue }
            if b.rare && c.rare < 0 { c.rare = b.id }
            if let s = b.stray, s.started, !s.exiting, c.stray < 0 { c.stray = b.id }
            if let a = b.act {
                if a.delay <= 0 && (a.kind == .dance || a.kind == .cheer) { c.playing += 1 }
                if a.kind == .sleep && !a.waking { c.sleepers += 1 }
            }
            if let s = b.social {
                c.kinds[s.kind, default: 0] += 1
                if s.kind.counts { c.social += 1 }
                if s.kind.plays { c.playing += 1 }
            }
            if b.habit != nil { c.habits += 1 }
            if let j = b.job, j.family != .visit {
                c.workers += 1
                if j.family == .errand { c.errands += 1 }
                if j.family == .play { c.players += 1 }
            }
            if let l = b.lure {
                if l.kind == .curious { c.curious += 1 }
                if l.kind == .follow { c.followers += 1 }
            }
            if let p = b.perch {
                c.perchers += 1
                if p.dock { c.docked += 1 }
            }
        }
        stage.census = c
    }

    func refreshGesture(_ b: inout Bug) {
        let g = gestureNow(b)
        if g != b.gesture {
            b.gesture = g
            b.gestureStart = time
        }
    }

    func gestureNow(_ b: Bug) -> Gesture {
        if b.mode == .hidden { return .none }
        if let s = b.sneak { return s.gesture }
        if let p = b.peek { return p.gesture }
        if let k = b.shake { return k.gesture }
        if let e = b.entrance { return e.gesture }
        if let a = b.act, a.delay <= 0 { return a.kind == .wave && lid.velocity > 30 ? .look : a.kind }
        if let l = b.lure { return l.gesture }
        if let p = b.perch { return p.gesture }
        if let s = b.social { return s.gesture }
        if let j = b.job { return jobGesture(b, j) }
        if let k = b.habit { return k.gesture }
        if b.mode == .resting && b.restGesture != .none {
            if (b.restGesture == .wave || b.restGesture == .tiptoe) && lid.velocity > 30 { return .look }
            return b.restGesture
        }
        if b.mode == .emerging && b.peekTimer > 0 && homeDepth(b) >= b.peekDepth - 0.5 { return .peek }
        return .none
    }

    func onScreen(_ b: Bug) -> Bool {
        b.x >= 0 && b.y >= 0 && b.x <= width && b.y <= height
    }

    func brake(_ b: inout Bug, tau: Double, h: Double) {
        b.speed *= exp(-h / max(1e-3, tau))
        if b.speed < 0.5 { b.speed = 0 }
    }

    func hover(_ b: inout Bug, tr: SpeciesTraits, h: Double, spin: Double = 0.9, scale: Double = 1) {
        let drift = restDrift(b, tr: tr) * scale
        if drift > 0 {
            approach(&b.speed, drift, rate: max(drift, b.speed) / 0.4, h: h)
            if b.species.locomotion == .flutter || spin > 0.9 {
                b.course = wrap(b.course + b.circle * spin * h)
            }
        } else {
            brake(&b, tau: 0.07, h: h)
        }
    }

    func steer(_ b: inout Bug, toward angle: Double, rate: Double, h: Double) {
        let d = wrap(angle - b.course)
        b.course = wrap(b.course + max(-rate, min(rate, d * 6)) * h)
    }

    func pick(_ count: Int) -> Int {
        guard count > 1 else { return 0 }
        return min(count - 1, Int(actRng.unit() * Double(count)))
    }

    func creepSetup(_ b: inout Bug, tr: SpeciesTraits, spread: Double = 0.3) {
        b.mode = .emerging
        b.course = wrap(inward(b.entry) + actRng.signed() * spread)
        b.heading = b.course
        b.desired = b.course
        b.targetSpeed = tr.cruise * b.size * b.tempo * 0.85
        b.timer = 4
        b.emergeDepth = max(homeDepth(b) + b.size * 0.8, b.size * 1.3 + actRng.unit() * 90)
        b.peekTimer = 0
        b.backward = false
        b.glide = false
    }

    func goalHug() -> Double {
        light > tuning.duskLight && light < 1 ? min(1, max(0, tuning.duskHug)) : 1
    }

    func duskCaution() -> Double {
        light > tuning.duskLight && light < 1 ? min(1, max(0.1, tuning.duskReach)) : 1
    }

    func beganRest(_ b: inout Bug) {
        let t = tuning
        considerHabit(&b)
        considerWatching(&b)
        guard light > t.duskLight, light < 1, t.duskLookChance > 0, b.stray == nil else { return }
        if actRng.chance(t.duskLookChance) { b.restGesture = .look }
    }

    func seek(_ b: inout Bug, x: Double, y: Double, pace: Double, tr: SpeciesTraits, h: Double, arrive: Double = 6, turn: Double? = nil) -> Double {
        let dx = x - b.x, dy = y - b.y
        let d = hypot(dx, dy)
        b.backward = false
        if d > 1e-6 { steer(&b, toward: atan2(dy, dx), rate: turn ?? max(3, tr.turnRate * 1.6), h: h) }
        let off = abs(wrap(atan2(dy, dx) - b.course))
        var want = d <= arrive ? 0 : min(pace, max(pace * 0.25, d * 2.2))
        want *= 0.35 + 0.65 * max(0, cos(off))
        if b.species.locomotion == .flutter { want = max(want, restDrift(b, tr: tr) * 0.6) }
        approach(&b.speed, want, rate: max(pace, 20) / 0.18, h: h)
        return d
    }

    func paceOf(_ b: Bug, _ tr: SpeciesTraits) -> Double {
        tr.cruise * b.size * b.tempo
    }

    func faceToward(_ b: inout Bug, x: Double) {
        let dx = x - b.x
        guard abs(dx) > 2, b.facingHold <= 0 else { return }
        let f: Double = dx > 0 ? 1 : -1
        if f != b.facing {
            b.facing = f
            b.facingHold = 0.3
        }
    }

    func gaze(_ b: inout Bug, tr: SpeciesTraits, x: Double, y: Double, h: Double, gap: Double? = nil) {
        let dx = x - b.x, dy = y - b.y
        let d = hypot(dx, dy)
        let toward = atan2(dy, dx)
        if b.species.isAirborne {
            let drift = max(4, restDrift(b, tr: tr) > 0 ? restDrift(b, tr: tr) : paceOf(b, tr) * 0.3)
            let keep = gap ?? d
            let away = d < keep - 4
            b.backward = away
            steer(&b, toward: away ? toward + .pi : toward, rate: 4, h: h)
            let need = min(1, max(b.species.locomotion == .flutter ? 0.3 : 0, abs(d - keep) / 20))
            approach(&b.speed, drift * need, rate: max(drift, b.speed) / 0.3, h: h)
        } else {
            brake(&b, tau: 0.08, h: h)
            if b.species.locomotion == .hop && b.lift == 0 { b.speed = 0 }
            if d > 1 { steer(&b, toward: toward, rate: 3, h: h) }
        }
        if abs(dx) > 2 { b.facing = dx > 0 ? 1 : -1 }
        b.facingHold = max(b.facingHold, 0.35)
    }

    func settleStill(_ b: inout Bug, tr: SpeciesTraits, h: Double) {
        if b.species.isAirborne {
            hover(&b, tr: tr, h: h)
        } else {
            brake(&b, tau: 0.08, h: h)
            if b.species.locomotion == .hop && b.lift == 0 { b.speed = 0 }
        }
    }

    func resume(_ b: inout Bug, tr: SpeciesTraits, toward angle: Double? = nil) {
        b.backward = false
        b.glide = false
        b.pinned = false
        guard let a = angle else {
            startBurst(&b, tr: tr)
            return
        }
        b.mode = .wandering
        b.desired = wrap(a)
        b.targetSpeed = paceOf(b, tr) * socialRng.range(0.8...1.1)
        b.timer = socialRng.range(tr.burst)
        b.restGesture = .none
    }

    func lureable(_ b: Bug) -> Bool {
        b.calm && b.mode != .emerging && b.peek == nil && b.sneak == nil && b.shake == nil && b.entrance == nil && b.stray == nil && !b.retiring && !b.fading
    }
}
