import Foundation

enum LureKind: Equatable {
    case shy
    case bowled
    case scamper
    case curious
    case follow
}

struct Lure {
    var kind: LureKind
    var stage = 0
    var clock = 0.0
    var length = 0.0
    var angle = 0.0
    var speed = 0.0
    var ahead = -1
    var gap = 0.0
    var gesture = Gesture.none
    var aloft = false
}

struct PointerStage {
    var present = false
    var inside = false
    var x = 0.0
    var y = 0.0
    var speed = 0.0
    var anchorX = 0.0
    var anchorY = 0.0
    var still = 0.0
    var lastX = 0.0
    var lastY = 0.0
    var dirX = 1.0
    var dirY = 0.0
    var slow = 0.0
    var tick = 0.0
    var session = 0.0
    var cooldown = 0.0
    var waved = false
    var bored = false
    var followCooldown = 0.0
    var followTick = 0.0
    var slots: [Double] = []
}

extension World {
    public var curiousCount: Int {
        var n = 0
        for b in bugs where b.mode != .hidden && b.lure?.kind == .curious { n += 1 }
        return n
    }

    public var followerCount: Int {
        var n = 0
        for b in bugs where b.mode != .hidden && b.lure?.kind == .follow { n += 1 }
        return n
    }

    public var shyCount: Int {
        var n = 0
        for b in bugs where b.mode != .hidden {
            if let l = b.lure, l.kind == .shy || l.kind == .bowled || l.kind == .scamper { n += 1 }
        }
        return n
    }

    func sensePointer(_ h: Double) {
        let t = tuning
        stage.pointer.cooldown -= h
        stage.pointer.followCooldown -= h
        stage.pointer.tick -= h
        stage.pointer.followTick -= h
        guard t.pointerEnabled, let p = surroundings.pointer, p.x.isFinite, p.y.isFinite else {
            forgetPointer()
            return
        }
        let px = Double(p.x), py = Double(p.y)
        let raw = surroundings.pointerSpeed
        let speed = raw.isFinite ? max(0, raw) : 0
        var ps = stage.pointer
        if ps.present {
            let dx = px - ps.lastX, dy = py - ps.lastY
            let d = hypot(dx, dy)
            if d > 0.5 {
                let k = min(1, h / 0.1)
                ps.dirX += (dx / d - ps.dirX) * k
                ps.dirY += (dy / d - ps.dirY) * k
                let m = max(1e-6, hypot(ps.dirX, ps.dirY))
                ps.dirX /= m
                ps.dirY /= m
            }
        }
        ps.present = true
        ps.x = px
        ps.y = py
        ps.lastX = px
        ps.lastY = py
        ps.speed = speed
        ps.inside = px >= 0 && py >= 0 && px <= width && py <= height
        if hypot(px - ps.anchorX, py - ps.anchorY) > t.pointerStillRadius || speed > t.pointerStillSpeed {
            ps.anchorX = px
            ps.anchorY = py
            if ps.still > 0 && ps.session > 0 { ps.cooldown = max(ps.cooldown, 4) }
            ps.still = 0
            ps.session = 0
            ps.waved = false
            ps.bored = false
            ps.slots.removeAll(keepingCapacity: true)
        } else {
            ps.still += h
        }
        if speed >= t.followSpeed.lowerBound && speed <= t.followSpeed.upperBound {
            ps.slow += h
        } else {
            ps.slow = 0
        }
        stage.pointer = ps
        guard ps.inside, stage.visible > 0 || !stage.yard.bodies.isEmpty else { return }
        if speed >= t.pointerScamperSpeed { knockLoose(px, py, speed: speed, dirX: ps.dirX, dirY: ps.dirY) }
        guard stage.visible > 0 else { return }
        if speed >= t.pointerShySpeed { shyPass(px, py, speed) }
        if t.curiosityEnabled && ps.still >= t.curiosityDelay { curiosity(h) }
        if t.followEnabled { considerFollow() }
    }

    private func forgetPointer() {
        stage.pointer.present = false
        stage.pointer.inside = false
        stage.pointer.still = 0
        stage.pointer.session = 0
        stage.pointer.slow = 0
        stage.pointer.speed = 0
        stage.pointer.waved = false
        stage.pointer.slots.removeAll(keepingCapacity: true)
    }

    private func shyPass(_ px: Double, _ py: Double, _ speed: Double) {
        let t = tuning
        let swipe = speed >= t.pointerSwipeSpeed
        let fast = speed >= t.pointerScamperSpeed
        let ps = stage.pointer
        for i in bugs.indices {
            let b = bugs[i]
            guard b.mode != .hidden else { continue }
            let reach = t.pointerShyRadius + b.size * 0.5
            let dx = b.x - px
            if dx > reach || dx < -reach { continue }
            let dy = b.y - py
            if dy > reach || dy < -reach { continue }
            let d = hypot(dx, dy)
            guard d < reach, lureable(b) else { continue }
            let level = swipe && d < t.pointerBowlRadius + b.size * 0.5 ? 3 : (fast ? 2 : 1)
            var current = 0
            if let l = b.lure {
                switch l.kind {
                case .bowled: current = 3
                case .scamper: current = 2
                case .shy: current = 1
                case .follow: if !fast { continue }
                case .curious: break
                }
            }
            if current >= level { continue }
            if current == 0 && time < b.lureCalm { continue }
            if b.job != nil && level < 2 { continue }
            var nb = b
            if nb.job != nil { knockHeld(nb, dirX: ps.dirX, dirY: ps.dirY, speed: speed) }
            nb.lureCalm = time + pointerRng.range(t.pointerCooldown)
            if nb.perch != nil {
                spookPerch(&nb, fromX: px, speed: speed)
                bugs[i] = nb
                continue
            }
            clearOwn(&nb)
            nb.act = nil
            nb.restGesture = .none
            let away = d > 1e-6 ? atan2(dy, dx) : atan2(ps.dirY, ps.dirX)
            var l: Lure
            let tr = t.traits(for: nb.species)
            if level == 3 {
                l = Lure(kind: .bowled)
                let vx = ps.dirX * 0.75 + cos(away) * 0.6, vy = ps.dirY * 0.75 + sin(away) * 0.6
                l.angle = atan2(vy, vx)
                l.speed = min(t.fleeSpeedCap * 0.9, pointerRng.range(170...240))
                l.length = 0.62
                l.gesture = .tumble
                nb.course = l.angle
                nb.glide = true
                if nb.species.locomotion == .hop { nb.gaitPhase = nb.gaitPhase.rounded(.down) }
                nb.mode = .resting
            } else if level == 2 {
                l = Lure(kind: .scamper)
                l.angle = away + pointerRng.signed() * 0.4
                l.length = pointerRng.range(0.5...0.9)
                l.speed = min(170, max(60, paceOf(nb, tr) * 2.4))
                nb.mode = .wandering
            } else {
                l = Lure(kind: .shy)
                l.angle = away
                l.gesture = .look
                if nb.species.locomotion == .hop {
                    l.speed = nb.size * 0.8
                    l.length = 0.9
                } else if nb.species.isAirborne {
                    l.speed = min(80, max(25, paceOf(nb, tr) * 1.3))
                    l.length = pointerRng.range(0.5...0.8)
                } else {
                    l.speed = min(55, max(18, paceOf(nb, tr) * 0.9))
                    l.length = pointerRng.range(0.5...0.8)
                    nb.backward = true
                    nb.course = away
                }
                nb.mode = .resting
            }
            nb.lure = l
            bugs[i] = nb
            if l.kind == .bowled { ripple(fromX: nb.x, y: nb.y, except: nb.id) }
        }
    }

    private func curiosity(_ h: Double) {
        let t = tuning
        stage.pointer.session += h
        if stage.pointer.session > t.curiosityBored {
            if !stage.pointer.bored {
                stage.pointer.bored = true
                stage.pointer.cooldown = pointerRng.range(t.curiosityCooldown)
                var k = 0
                for i in bugs.indices where bugs[i].mode != .hidden && bugs[i].lure?.kind == .curious {
                    bugs[i].lure?.stage = 3
                    bugs[i].lure?.clock = 0
                    bugs[i].lure?.length = 0.6 + Double(k) * 1.3
                    k += 1
                }
            }
            return
        }
        guard stage.pointer.cooldown <= 0, stage.pointer.tick <= 0 else { return }
        stage.pointer.tick = pointerRng.range(t.curiosityTick)
        let want = stage.pointer.still >= t.audienceDelay ? t.audienceMax : t.curiousMax
        guard stage.census.curious < want else { return }
        guard t.forceCuriosity ?? pointerRng.chance(t.curiosityChance) else { return }
        let px = stage.pointer.anchorX, py = stage.pointer.anchorY
        var chosen = -1
        var best = -Double.infinity
        for i in bugs.indices {
            let b = bugs[i]
            guard b.mode != .hidden, b.nerve >= t.curiosityNerve, b.free || b.habit != nil, lureable(b), time >= b.lureCalm else { continue }
            let d = hypot(b.x - px, b.y - py)
            guard d <= t.curiosityRange, d > b.size * 1.5 else { continue }
            let score = b.nerve - 0.5 * d / max(1, t.curiosityRange) + 0.15 * pointerRng.unit()
            if score > best {
                best = score
                chosen = i
            }
        }
        guard chosen >= 0 else { return }
        var b = bugs[chosen]
        clearOwn(&b)
        var a = atan2(b.y - py, b.x - px)
        let sep = 0.5
        for _ in 0..<6 {
            var moved = false
            for e in stage.pointer.slots {
                let d = wrap(a - e)
                if abs(d) < sep {
                    a = e + (d >= 0 ? sep : -sep)
                    moved = true
                }
            }
            if !moved { break }
        }
        stage.pointer.slots.append(a)
        var l = Lure(kind: .curious)
        l.angle = a
        l.gap = b.size * 2 + 34
        b.lure = l
        bugs[chosen] = b
    }

    private func considerFollow() {
        let t = tuning
        let ps = stage.pointer
        guard ps.slow >= 1, ps.followCooldown <= 0, ps.followTick <= 0, stage.census.followers == 0 else { return }
        stage.pointer.followTick = 1
        guard t.forceFollow ?? pointerRng.chance(t.followChance) else { return }
        var chosen = -1
        var best = Double.infinity
        for i in bugs.indices {
            let b = bugs[i]
            guard b.mode != .hidden, b.species.locomotion != .dart, b.free || b.habit != nil || b.lure?.kind == .curious, lureable(b) else { continue }
            let d = hypot(b.x - ps.x, b.y - ps.y)
            guard d <= t.followRange, d < best else { continue }
            best = d
            chosen = i
        }
        guard chosen >= 0 else { return }
        var lead = bugs[chosen]
        clearOwn(&lead)
        var l = Lure(kind: .follow)
        l.length = pointerRng.range(t.followLength)
        l.gap = lead.size * 2.4 + 34
        lead.lure = l
        bugs[chosen] = lead
        stage.pointer.followCooldown = l.length + pointerRng.range(t.followCooldown)
        guard pointerRng.chance(t.followTrainChance) else { return }
        var second = -1
        var near = Double.infinity
        for i in bugs.indices where i != chosen {
            let b = bugs[i]
            guard b.mode != .hidden, b.species.locomotion != .dart, b.free, lureable(b) else { continue }
            let d = hypot(b.x - lead.x, b.y - lead.y)
            guard d <= 220, d < near else { continue }
            near = d
            second = i
        }
        guard second >= 0 else { return }
        var f = Lure(kind: .follow)
        f.ahead = lead.id
        f.length = l.length + 1
        f.gap = (lead.size + bugs[second].size) * 0.62 + 8
        bugs[second].lure = f
    }

    func lureStep(_ b: inout Bug, tr: SpeciesTraits, h: Double) -> Double {
        guard var l = b.lure else { return 0 }
        l.clock += h
        var done = false
        switch l.kind {
        case .shy: done = shyStep(&b, &l, tr: tr, h: h)
        case .bowled: done = bowledStep(&b, &l, tr: tr, h: h)
        case .scamper: done = scamperStep(&b, &l, tr: tr, h: h)
        case .curious: done = curiousStep(&b, &l, tr: tr, h: h)
        case .follow: done = followStep(&b, &l, tr: tr, h: h)
        }
        if done {
            b.lure = nil
            resume(&b, tr: tr)
        } else {
            b.lure = l
        }
        return 0
    }

    private func shyStep(_ b: inout Bug, _ l: inout Lure, tr: SpeciesTraits, h: Double) -> Bool {
        b.mode = .resting
        l.gesture = .look
        if l.stage == 0 {
            b.course = l.angle
            if b.species.locomotion == .hop {
                if b.lift > 0 {
                    l.aloft = true
                    b.speed = l.speed
                } else if l.aloft || l.clock > l.length {
                    b.speed = 0
                    l.stage = 1
                    l.clock = 0
                } else {
                    b.speed = l.speed
                }
            } else {
                approach(&b.speed, l.speed, rate: l.speed / 0.12, h: h)
                if l.clock >= l.length {
                    l.stage = 1
                    l.clock = 0
                    b.backward = false
                }
            }
            return false
        }
        b.backward = false
        if stage.pointer.present {
            gaze(&b, tr: tr, x: stage.pointer.x, y: stage.pointer.y, h: h)
        } else {
            settleStill(&b, tr: tr, h: h)
        }
        return l.clock >= 0.8
    }

    private func bowledStep(_ b: inout Bug, _ l: inout Lure, tr: SpeciesTraits, h: Double) -> Bool {
        b.mode = .resting
        if l.stage == 0 {
            l.gesture = .tumble
            b.glide = true
            b.course = l.angle
            b.speed = l.speed * exp(-l.clock / 0.25)
            let pad = b.size * 0.6
            if b.x < pad || b.x > width - pad { l.angle = .pi - l.angle }
            if b.y < pad || b.y > height - pad { l.angle = -l.angle }
            if l.clock >= l.length {
                l.stage = 1
                l.clock = 0
                l.gesture = .look
                land(&b)
            }
            return false
        }
        l.gesture = .look
        b.glide = false
        settleStill(&b, tr: tr, h: h)
        return l.clock >= 0.9
    }

    private func scamperStep(_ b: inout Bug, _ l: inout Lure, tr: SpeciesTraits, h: Double) -> Bool {
        if l.stage == 0 {
            l.gesture = .none
            var a = l.angle
            let pad = b.size * 1.5
            if (b.x < pad && cos(a) < 0) || (b.x > width - pad && cos(a) > 0) { a = .pi - a }
            if (b.y < pad && sin(a) < 0) || (b.y > height - pad && sin(a) > 0) { a = -a }
            l.angle = wrap(a)
            steer(&b, toward: l.angle, rate: 9, h: h)
            approach(&b.speed, l.speed, rate: l.speed / 0.1, h: h)
            b.mode = .wandering
            if l.clock >= l.length {
                l.stage = 1
                l.clock = 0
            }
            return false
        }
        l.gesture = .look
        b.mode = .resting
        if stage.pointer.present {
            gaze(&b, tr: tr, x: stage.pointer.x, y: stage.pointer.y, h: h)
        } else {
            settleStill(&b, tr: tr, h: h)
        }
        return l.clock >= 0.6
    }

    private func curiousStep(_ b: inout Bug, _ l: inout Lure, tr: SpeciesTraits, h: Double) -> Bool {
        let t = tuning
        let ps = stage.pointer
        let here = ps.present && ps.inside
        if l.stage != 3 && (!here || (ps.still < t.curiosityDelay && l.clock > 0.2)) {
            if here && ps.speed >= t.followSpeed.lowerBound && ps.speed <= t.followSpeed.upperBound && t.followEnabled && stage.census.followers == 0 && ps.followCooldown <= 0 && pointerRng.chance(t.followTrainChance) {
                var f = Lure(kind: .follow)
                f.length = pointerRng.range(t.followLength)
                f.gap = b.size * 2.4 + 34
                l = f
                stage.pointer.followCooldown = f.length + pointerRng.range(t.followCooldown)
                return false
            }
            l.stage = 3
            l.clock = 0
            l.length = 0.6
        }
        switch l.stage {
        case 0:
            l.gesture = .none
            let pad = b.size * 0.8
            let tx = min(max(ps.anchorX + cos(l.angle) * l.gap, pad), width - pad)
            let ty = min(max(ps.anchorY + sin(l.angle) * l.gap, pad), height - pad)
            let d = seek(&b, x: tx, y: ty, pace: max(12, paceOf(b, tr) * 0.75), tr: tr, h: h, arrive: 5)
            b.mode = b.speed > 1 || b.lift > 0 ? .wandering : .resting
            if d <= 6 || l.clock > 12 {
                l.stage = 1
                l.clock = 0
            }
        case 1, 2:
            b.mode = .resting
            gaze(&b, tr: tr, x: ps.x, y: ps.y, h: h, gap: l.gap)
            if l.stage == 1 {
                l.gesture = .look
                let can = !b.species.isAirborne && b.species.stance == .upright && !ps.waved
                if can && l.clock > 2 && pointerRng.chance(t.curiousWaveChance * h) {
                    stage.pointer.waved = true
                    l.stage = 2
                    l.clock = 0
                }
            } else {
                l.gesture = .wave
                if l.clock >= 1.5 {
                    l.stage = 1
                    l.clock = 0
                }
            }
        default:
            b.mode = .resting
            l.gesture = .look
            if here {
                gaze(&b, tr: tr, x: ps.x, y: ps.y, h: h)
            } else {
                settleStill(&b, tr: tr, h: h)
            }
            if l.clock >= l.length { return true }
        }
        return false
    }

    private func followStep(_ b: inout Bug, _ l: inout Lure, tr: SpeciesTraits, h: Double) -> Bool {
        let t = tuning
        let ps = stage.pointer
        if l.stage == 0 {
            var tx = 0.0, ty = 0.0
            var lost = l.clock > l.length
            if l.ahead < 0 {
                lost = lost || !ps.present || !ps.inside || ps.speed > t.followLose
                tx = ps.x
                ty = ps.y
            } else if let i = index(of: l.ahead), bugs[i].mode != .hidden, bugs[i].lure?.kind == .follow, bugs[i].lure?.stage == 0 {
                tx = bugs[i].x
                ty = bugs[i].y
            } else {
                lost = true
            }
            if lost {
                l.stage = 1
                l.clock = 0
            } else {
                let dx = tx - b.x, dy = ty - b.y
                let d = hypot(dx, dy)
                let pace = min(160, max(30, paceOf(b, tr) * 2.2))
                let want = min(pace, max(0, (d - l.gap) * 2))
                if want > 2 {
                    if d > 1e-6 { steer(&b, toward: atan2(dy, dx), rate: max(4, tr.turnRate * 1.6), h: h) }
                    approach(&b.speed, want, rate: pace / 0.2, h: h)
                    b.mode = .wandering
                    l.gesture = .none
                } else {
                    b.mode = b.lift > 0 ? .wandering : .resting
                    if b.lift == 0 {
                        gaze(&b, tr: tr, x: tx, y: ty, h: h, gap: l.gap)
                        l.gesture = .look
                    } else {
                        settleStill(&b, tr: tr, h: h)
                    }
                }
                return false
            }
        }
        settleStill(&b, tr: tr, h: h)
        b.mode = .resting
        l.gesture = .look
        return l.clock >= 0.8
    }
}
