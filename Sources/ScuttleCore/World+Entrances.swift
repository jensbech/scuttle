import Foundation

public enum EntranceStyle: String, CaseIterable, Codable, Sendable {
    case creep
    case careful
    case popUp = "popup"
    case parachute
    case swoop
    case tumble
    case shy
    case conga
}

struct Entrance {
    var style: EntranceStyle
    var stage = 0
    var clock = 0.0
    var total = 0.0
    var length = 0.0
    var sign = 1.0
    var rate = 0.0
    var from = 0.0
    var to = 0.0
    var along = 0.0
    var phase = 0.0
    var tries = 0
    var flipped = false
    var leader = -1
    var ahead = -1
    var slot = 0
    var spacing = 0.0
    var pace = 0.0

    var gesture: Gesture {
        switch style {
        case .popUp: return stage == 1 ? .look : (stage == 0 ? .popUp : .none)
        case .parachute: return stage == 0 ? .parachute : .look
        case .tumble: return stage == 0 ? .tumble : .look
        case .shy:
            switch stage {
            case 1: return .look
            case 2: return .tiptoe
            default: return .none
            }
        case .conga: return stage == 2 ? .cheer : .dance
        case .creep, .careful, .swoop: return .none
        }
    }
}

extension World {
    public var entranceCounts: [EntranceStyle: Int] {
        var out: [EntranceStyle: Int] = [:]
        for b in bugs where b.mode != .hidden {
            if let e = b.entrance { out[e.style, default: 0] += 1 }
        }
        return out
    }

    func chooseEntrance(_ b: inout Bug, room: Int) -> Int {
        let t = tuning
        let order = lid.arrivals
        lid.arrivals += 1
        let style = pickEntrance(b, order: order, room: room)
        let tr = t.traits(for: b.species)
        let special = t.forceEntrance == nil && style != .creep && style != .careful
        let burst = lid.arrival == .slam && order < t.slamBurst
        if special && !burst { stage.entranceGap = t.entranceGap }
        switch style {
        case .creep:
            return 0
        case .careful:
            b.peekTimer = actRng.range(t.peekPause) * max(1, t.carefulPeekScale) + 0.4
            b.peekDepth = b.size * actRng.range(-0.2...0.05)
            return 0
        case .popUp:
            beginPopUp(&b)
        case .parachute:
            beginParachute(&b)
        case .swoop:
            beginSwoop(&b, tr: tr)
        case .tumble:
            beginTumble(&b)
        case .shy:
            beginShy(&b)
        case .conga:
            return beginConga(&b, tr: tr, room: room)
        }
        return 0
    }

    private func grounded(_ b: Bug) -> Bool {
        !b.species.isAirborne
    }

    private func flyer(_ b: Bug) -> Bool {
        switch b.species.locomotion {
        case .flutter, .hover, .dart: return true
        default: return false
        }
    }

    private func pickEntrance(_ b: Bug, order: Int, room: Int) -> EntranceStyle {
        let t = tuning
        let ground = grounded(b)
        if let forced = t.forceEntrance {
            switch forced {
            case .popUp, .parachute, .shy: return ground ? forced : .creep
            case .swoop: return flyer(b) ? forced : .creep
            case .conga: return canConga(b, room: room, forced: true) ? forced : .creep
            default: return forced
            }
        }
        if lid.arrival == .slam && order < t.slamBurst {
            return ground && b.entry == .bottom ? .popUp : .tumble
        }
        if lid.arrival == .slow && order < t.carefulArrivals { return .careful }
        guard stage.entranceGap <= 0 else { return .creep }
        var options: [(EntranceStyle, Double)] = []
        if ground && b.entry == .bottom { options.append((.popUp, t.popUpChance)) }
        if ground && b.entry == .top { options.append((.parachute, t.parachuteChance)) }
        if flyer(b) { options.append((.swoop, t.swoopChance)) }
        if ground && !b.rare { options.append((.shy, t.shyChance)) }
        if canConga(b, room: room, forced: false) { options.append((.conga, t.congaChance)) }
        var roll = actRng.unit()
        for (style, chance) in options {
            if roll < chance { return style }
            roll -= max(0, chance)
        }
        return .creep
    }

    private func relocate(_ b: inout Bug, to edge: Edge) {
        guard b.entry != edge else { return }
        let margin = min(max(tuning.entryCornerMargin, 0), 0.45)
        let a = span(edge) * actRng.range(margin...(1 - margin))
        let p = point(on: edge, along: a, depth: -b.size * 0.6)
        b.entry = edge
        b.x = p.x
        b.y = p.y
        b.course = inward(edge)
        b.heading = b.course
        b.desired = b.course
    }

    private func beginPopUp(_ b: inout Bug) {
        let t = tuning
        relocate(&b, to: .bottom)
        var e = Entrance(style: .popUp)
        e.length = actRng.range(t.popUpRise)
        e.along = b.x
        e.from = -b.size * 0.9
        e.to = b.size * actRng.range(0.6...0.85)
        b.y = e.from
        b.speed = 0
        b.course = wrap(.pi / 2 + actRng.signed() * 0.2)
        b.heading = b.course
        b.peekTimer = 0
        b.entrance = e
    }

    private func beginParachute(_ b: inout Bug) {
        let t = tuning
        relocate(&b, to: .top)
        var e = Entrance(style: .parachute)
        let top = max(b.size * 1.8, height * 0.6)
        e.from = min(top, max(b.size * 1.8, min(height * actRng.range(t.parachuteLand), reach(for: b) * 0.9)))
        e.rate = max(actRng.range(t.parachuteSpeed), (e.from + b.size * 1.1) / max(1, t.parachuteMaxSeconds))
        e.along = b.x
        e.phase = actRng.unit() * 2 * .pi
        e.to = actRng.range(10...18)
        b.y = height + b.size * 1.1
        b.speed = 0
        b.course = -.pi / 2
        b.heading = b.course
        b.peekTimer = 0
        b.entrance = e
    }

    private func beginSwoop(_ b: inout Bug, tr: SpeciesTraits) {
        let t = tuning
        var e = Entrance(style: .swoop)
        let n = inward(b.entry)
        let centre = atan2(height / 2 - b.y, width / 2 - b.x)
        e.sign = wrap(centre - n) >= 0 ? 1 : -1
        e.length = actRng.range(t.swoopTime)
        let lean = actRng.range(0.6...1.0)
        e.rate = -e.sign * min(actRng.range(1.0...1.3), (lean + 1.0) / max(0.2, e.length))
        let cruise = tr.cruise * b.size * b.tempo
        e.from = min(280, max(120, cruise * t.swoopBoost))
        e.to = cruise
        b.course = wrap(n + e.sign * lean)
        b.heading = b.course
        b.speed = e.from
        b.peekTimer = 0
        b.entrance = e
    }

    private func beginTumble(_ b: inout Bug) {
        let t = tuning
        var e = Entrance(style: .tumble)
        e.from = actRng.range(t.tumbleSpeed)
        e.length = actRng.range(t.tumbleTime)
        b.course = wrap(inward(b.entry) + actRng.signed() * 0.35)
        b.heading = b.course
        b.speed = e.from
        b.glide = b.species.locomotion == .hop
        b.peekTimer = 0
        b.entrance = e
    }

    private func beginShy(_ b: inout Bug) {
        let t = tuning
        var e = Entrance(style: .shy)
        e.to = b.size * actRng.range(t.shyDepth)
        b.peekTimer = 0
        b.entrance = e
    }

    private func congaReady(_ b: Bug) -> Bool {
        grounded(b) && !b.rare && !b.retiring && tuning.traits(for: b.species).cruise >= 0.8
    }

    private func canConga(_ b: Bug, room: Int, forced: Bool) -> Bool {
        let t = tuning
        guard congaReady(b), !stage.congaActive, room >= 2 - max(0, t.congaBorrow) else { return false }
        if !forced && (darkSeconds < t.congaMinDark || stage.congaCooldown > 0) { return false }
        var n = 0
        for c in bugs where c.mode == .hidden && c.id != b.id && congaReady(c) && light < c.nerve - t.nerveHysteresis {
            n += 1
            if n >= 2 { return true }
        }
        return false
    }

    private func beginConga(_ b: inout Bug, tr: SpeciesTraits, room: Int) -> Int {
        let t = tuning
        let lo = max(3, t.congaSize.lowerBound), hi = max(lo, t.congaSize.upperBound)
        let size = lo + pick(hi - lo + 1)
        var followers: [Int] = []
        for i in bugs.indices {
            let c = bugs[i]
            if c.mode == .hidden && c.id != b.id && congaReady(c) && light < c.nerve - t.nerveHysteresis { followers.append(i) }
        }
        followers.sort { a, c in
            bugs[a].emergeTimer != bugs[c].emergeTimer ? bugs[a].emergeTimer < bugs[c].emergeTimer : bugs[a].id < bugs[c].id
        }
        let reach = room >= size ? size - 1 : room + max(0, t.congaBorrow)
        let want = min(size - 1, reach, followers.count)
        guard want >= 2 else { return 0 }
        var pace = tr.cruise * b.size * b.tempo
        for i in followers.prefix(want) {
            let c = bugs[i]
            pace = min(pace, t.traits(for: c.species).cruise * c.size * c.tempo)
        }
        pace = min(60, max(26, pace * 0.9))
        var lead = Entrance(style: .conga)
        lead.leader = b.id
        lead.length = actRng.range(t.congaLength)
        lead.pace = pace
        lead.to = b.size * 2 + 30
        lead.sign = along(b.x, b.y, on: b.entry) < span(b.entry) / 2 ? 1 : -1
        b.course = inward(b.entry)
        b.heading = b.course
        b.desired = b.course
        b.speed = 0
        b.peekTimer = 0
        b.entrance = lead
        var ahead = b
        for (k, i) in followers.prefix(want).enumerated() {
            var c = bugs[i]
            freshenFollower(&c, like: b)
            var e = Entrance(style: .conga)
            e.leader = b.id
            e.ahead = ahead.id
            e.slot = k + 1
            e.pace = pace
            e.spacing = (ahead.size + c.size) * 0.62 + 4
            c.entrance = e
            refreshGesture(&c)
            bugs[i] = c
            ahead = c
        }
        stage.congaActive = true
        stage.congaDirty = true
        stage.congaCooldown = actRng.range(t.congaCooldown)
        return want
    }

    private func freshenFollower(_ c: inout Bug, like b: Bug) {
        c.mode = .emerging
        c.entry = b.entry
        c.x = b.x
        c.y = b.y
        c.course = inward(b.entry)
        c.heading = c.course
        c.desired = c.course
        c.speed = 0
        c.targetSpeed = 0
        c.timer = 4
        c.emergeDepth = c.size * 1.3
        c.peekTimer = 0
        c.alpha = 1
        c.bend = 0
        c.meander = 0
        c.fading = false
        c.litTime = 0
        c.flinched = false
        c.goalTimer = 0
        c.stray = nil
        c.confusion = 0
        c.pace = 0
        c.lift = 0
        c.hopSpeed = 0
        c.facingHold = 0
        clearScripts(&c)
        let cc = cos(c.course)
        if abs(cc) > 0.2 { c.facing = cc > 0 ? 1 : -1 }
        if c.species.locomotion == .hop { c.gaitPhase = c.gaitPhase.rounded(.down) }
    }

    func indexConga() {
        guard stage.congaActive else { return }
        stage.congaDirty = false
        stage.congaIndex.removeAll(keepingCapacity: true)
        for i in bugs.indices where bugs[i].entrance?.style == .conga && bugs[i].mode != .hidden {
            stage.congaIndex[bugs[i].id] = i
        }
        if stage.congaIndex.isEmpty { stage.congaActive = false }
    }

    private func congaMember(_ id: Int) -> Int? {
        if let i = stage.congaIndex[id], i < bugs.count, bugs[i].id == id { return i }
        guard stage.congaDirty else { return nil }
        indexConga()
        return stage.congaIndex[id]
    }

    func entranceStep(_ b: inout Bug, tr: SpeciesTraits, h: Double) -> Double {
        guard var e = b.entrance else { return 0 }
        let t = tuning
        e.clock += h
        e.total += h
        if e.total > t.entranceMaxSeconds {
            b.entrance = nil
            finishEntrance(&b, tr: tr)
            return 0
        }
        var done = false
        switch e.style {
        case .popUp: done = popUpStep(&b, &e, h: h)
        case .parachute: done = parachuteStep(&b, &e, h: h)
        case .swoop: done = swoopStep(&b, &e, h: h)
        case .tumble: done = tumbleStep(&b, &e, h: h)
        case .shy: done = shyStep(&b, &e, tr: tr, h: h)
        case .conga: done = congaStep(&b, &e, tr: tr, h: h)
        case .creep, .careful: done = true
        }
        if done {
            b.entrance = nil
            if e.style != .shy { finishEntrance(&b, tr: tr) }
        } else {
            b.entrance = e
        }
        return 0
    }

    func finishEntrance(_ b: inout Bug, tr: SpeciesTraits) {
        b.backward = false
        b.glide = false
        if homeDepth(b) < b.size * 0.5 {
            creepSetup(&b, tr: tr, spread: 0.3)
        } else {
            startBurst(&b, tr: tr)
        }
    }

    private func backOut(_ u: Double) -> Double {
        let c1 = 1.70158, c3 = c1 + 1
        let v = u - 1
        return 1 + c3 * v * v * v + c1 * v * v
    }

    private func popUpStep(_ b: inout Bug, _ e: inout Entrance, h: Double) -> Bool {
        let t = tuning
        b.speed = 0
        e.along = min(max(e.along, b.size), max(b.size, width - b.size))
        b.x = e.along
        switch e.stage {
        case 0:
            let u = min(1, e.clock / max(0.05, e.length))
            b.y = e.from + (e.to - e.from) * backOut(u)
            if u >= 1 {
                e.stage = 1
                e.clock = 0
                e.length = actRng.range(t.popUpLook)
                e.flipped = false
            }
        case 1:
            b.y = e.to
            if !e.flipped && e.clock > e.length * 0.5 {
                e.flipped = true
                b.facing = -b.facing
                b.facingHold = 0.3
            }
            if e.clock >= e.length {
                if e.tries == 0 && actRng.chance(t.moleChance) {
                    e.stage = 2
                    e.clock = 0
                    e.length = 0.22
                } else {
                    return true
                }
            }
        case 2:
            let u = min(1, e.clock / max(0.05, e.length))
            b.y = e.to + (e.from - e.to) * u * u
            if u >= 1 {
                let shift = actRng.range(t.moleShift) * (actRng.chance(0.5) ? 1 : -1)
                let lo = width * 0.06, hi = width * 0.94
                var target = e.along + shift
                if target < lo || target > hi { target = e.along - shift }
                e.rate = min(max(target, lo), hi)
                e.stage = 3
                e.clock = 0
                e.length = max(0.35, abs(e.rate - e.along) / 260)
                e.sign = e.along
            }
        default:
            let u = min(1, e.clock / max(0.05, e.length))
            b.y = e.from
            e.along = e.sign + (e.rate - e.sign) * u
            b.x = e.along
            if u >= 1 {
                e.tries += 1
                e.stage = 0
                e.clock = 0
                e.length = actRng.range(t.popUpRise)
                b.facing = e.rate > e.sign ? 1 : -1
            }
        }
        return false
    }

    private func parachuteStep(_ b: inout Bug, _ e: inout Entrance, h: Double) -> Bool {
        b.speed = 0
        e.along = min(max(e.along, b.size + e.to), max(b.size + e.to, width - b.size - e.to))
        e.from = min(e.from, max(b.size * 1.8, height * 0.6))
        switch e.stage {
        case 0:
            let fall = -b.size * 1.1 + e.rate * e.clock
            let sway = sin(e.clock * 1.7 + e.phase)
            b.x = e.along + e.to * sway
            b.y = height - min(fall, e.from)
            b.course = wrap(-.pi / 2 + 0.25 * cos(e.clock * 1.7 + e.phase))
            if abs(sway) > 0.2 && b.facingHold <= 0 {
                let f: Double = cos(e.clock * 1.7 + e.phase) > 0 ? 1 : -1
                if f != b.facing {
                    b.facing = f
                    b.facingHold = 0.3
                }
            }
            if fall >= e.from {
                e.stage = 1
                e.clock = 0
                e.length = actRng.range(0.45...0.8)
                b.course = -.pi / 2
            }
        default:
            if e.clock >= e.length { return true }
        }
        return false
    }

    private func swoopStep(_ b: inout Bug, _ e: inout Entrance, h: Double) -> Bool {
        let u = min(1, e.clock / max(0.05, e.length))
        b.course = wrap(b.course + e.rate * h)
        b.speed = e.from + (e.to - e.from) * u * u
        return u >= 1
    }

    private func tumbleStep(_ b: inout Bug, _ e: inout Entrance, h: Double) -> Bool {
        switch e.stage {
        case 0:
            b.speed = e.from * exp(-e.clock / max(0.05, e.length * 0.45))
            if e.clock >= e.length {
                e.stage = 1
                e.clock = 0
                e.length = actRng.range(0.5...0.9)
                b.glide = false
            }
        default:
            brake(&b, tau: 0.06, h: h)
            if e.clock >= e.length { return true }
        }
        return false
    }

    private func shyStep(_ b: inout Bug, _ e: inout Entrance, tr: SpeciesTraits, h: Double) -> Bool {
        let t = tuning
        let cruise = max(18, tr.cruise * b.size * b.tempo)
        let depth = homeDepth(b)
        switch e.stage {
        case 0:
            steer(&b, toward: inward(b.entry), rate: tr.turnRate, h: h)
            approach(&b.speed, cruise * 0.7, rate: cruise / 0.2, h: h)
            if depth >= e.to || e.clock > 5 {
                e.stage = 1
                e.clock = 0
                e.length = actRng.range(0.7...1.2)
                e.flipped = false
            }
        case 1:
            brake(&b, tau: 0.06, h: h)
            if !e.flipped && e.clock > e.length * 0.45 {
                e.flipped = true
                b.facing = -b.facing
                b.facingHold = 0.3
            }
            if e.clock >= e.length {
                e.stage = 2
                e.clock = 0
                b.backward = true
                b.course = outward(b.entry)
            }
        case 2:
            b.course = outward(b.entry)
            approach(&b.speed, cruise * 0.8, rate: cruise / 0.25, h: h)
            if depth <= -b.size * 0.75 || e.clock > 6 {
                e.stage = 3
                e.clock = 0
                e.length = actRng.range(t.shyWait)
                b.backward = false
                b.speed = 0
                b.course = inward(b.entry)
            }
        default:
            b.speed = 0
            if e.clock >= e.length {
                e.tries += 1
                let shift = actRng.signed() * 60
                let s = span(b.entry)
                let a = min(max(along(b.x, b.y, on: b.entry) + shift, s * 0.06), s * 0.94)
                let p = point(on: b.entry, along: a, depth: -b.size * 0.6)
                b.x = p.x
                b.y = p.y
                if e.tries < 2 && actRng.chance(t.shyRetryChance) {
                    e.stage = 0
                    e.clock = 0
                    e.to = b.size * actRng.range(t.shyDepth)
                } else {
                    creepSetup(&b, tr: tr, spread: 0.3)
                    b.peekTimer = actRng.range(t.peekPause) * 1.4
                    b.peekDepth = b.size * actRng.range(-0.15...0.2)
                    return true
                }
            }
        }
        return false
    }

    private func congaStep(_ b: inout Bug, _ e: inout Entrance, tr: SpeciesTraits, h: Double) -> Bool {
        if e.slot == 0 { return leadConga(&b, &e, tr: tr, h: h) }
        guard let li = congaMember(e.leader), let lead = bugs[li].entrance, lead.style == .conga, lead.leader == e.leader else {
            return true
        }
        if lead.stage == 2 {
            if e.stage != 2 && lead.clock >= Double(e.slot) * 0.14 {
                e.stage = 2
                e.clock = 0
            }
            brake(&b, tau: 0.08, h: h)
            return false
        }
        guard let ai = congaMember(e.ahead) else { return true }
        let a = bugs[ai]
        let dx = a.x - b.x, dy = a.y - b.y
        let d = hypot(dx, dy)
        if d > 1e-6 { steer(&b, toward: atan2(dy, dx), rate: 7, h: h) }
        let want = d < e.spacing * 0.8 ? 0 : min(e.pace * 1.8, e.pace * d / max(1, e.spacing))
        approach(&b.speed, want, rate: e.pace / 0.2, h: h)
        return false
    }

    private func leadConga(_ b: inout Bug, _ e: inout Entrance, tr: SpeciesTraits, h: Double) -> Bool {
        let depth = homeDepth(b)
        switch e.stage {
        case 0:
            steer(&b, toward: inward(b.entry), rate: 2.5, h: h)
            approach(&b.speed, e.pace, rate: e.pace / 0.3, h: h)
            if depth >= e.to || e.clock > 6 {
                e.stage = 1
                e.clock = 0
            }
        case 1:
            let n = inward(b.entry)
            let s = span(b.entry)
            let a = along(b.x, b.y, on: b.entry)
            let ahead = e.sign > 0 ? s - a : a
            if ahead < 140 { e.sign = -e.sign }
            let tangent = alongDirection(b.entry) + (e.sign > 0 ? 0 : .pi)
            let hold = max(-0.6, min(0.6, (e.to - depth) / 120))
            let side = wrap(n - tangent) >= 0 ? 1.0 : -1.0
            let desired = tangent + side * hold + 0.35 * sin(e.clock * 1.7)
            steer(&b, toward: desired, rate: 2.2, h: h)
            approach(&b.speed, e.pace, rate: e.pace / 0.3, h: h)
            if e.clock >= e.length {
                e.stage = 2
                e.clock = 0
                e.length = 1.4
            }
        default:
            brake(&b, tau: 0.08, h: h)
            if e.clock >= e.length { return true }
        }
        return false
    }

    func alongDirection(_ e: Edge) -> Double {
        switch e {
        case .bottom, .top: return 0
        case .left, .right: return .pi / 2
        }
    }
}
