import Foundation

public enum ErrandKind: String, CaseIterable, Codable, Sendable {
    case deliver
    case crumb
    case plant
    case pollinate
    case lantern
    case slide
}

extension World {
    public var errandsRunning: [ErrandKind] {
        var out: [ErrandKind] = []
        for b in bugs where b.mode != .hidden {
            if let j = b.job, j.family == .errand { out.append(j.errand) }
        }
        return out
    }

    func seasonItem(_ s: Season) -> PropKind {
        switch s {
        case .autumn: return .acorn
        case .halloween: return .candy
        case .winter: return .snowball
        case .christmas: return .present
        case .spring: return .egg
        case .summer: return .shell
        case .newYear: return .balloon
        }
    }

    func unitOf(_ b: Bug) -> Double {
        min(40, max(20, b.size))
    }

    func looseFlowers() -> Int {
        var n = 0
        for q in stage.yard.bodies where q.kind == .flower && !q.doomed && q.site < 0 { n += 1 }
        return n
    }

    func errandKinds(_ b: Bug) -> [(ErrandKind, Double)] {
        let t = tuning
        let s = config.season
        var out: [(ErrandKind, Double)] = []
        switch b.species {
        case .snail, .robin, .ladybird, .spider, .chick, .hedgehog, .crab:
            out.append((.crumb, 1.2))
        default:
            break
        }
        if s == .spring && onFoot(b) && looseFlowers() < max(0, t.flowerMax) { out.append((.plant, 1.4)) }
        if (b.species == .bumblebee || b.species == .butterfly) && looseFlowers() > 0 { out.append((.pollinate, 2.5)) }
        if b.species == .ghost { out.append((.lantern, 2.5)) }
        if b.species == .penguin && s == .winter { out.append((.slide, 2.5)) }
        let item = seasonItem(s)
        if canCarry(b) && fits(b, itemSize(item, unit: unitOf(b))) && b.species.locomotion != .float { out.append((.deliver, 1)) }
        if b.species.locomotion == .float && item == .balloon { out.append((.deliver, 0.6)) }
        if let f = t.forceErrand { out = out.filter { $0.0 == f } }
        return out
    }

    func startErrand(dusk: Bool) -> Bool {
        let t = tuning
        var pool: [Int] = []
        for i in bugs.indices where bugs[i].mode != .hidden && workFree(bugs[i]) {
            if dusk && edgeDistance(bugs[i].x, bugs[i].y) > t.duskBand { continue }
            pool.append(i)
        }
        guard !pool.isEmpty else { return false }
        for _ in 0..<min(6, pool.count) {
            let i = pool[pick(pool.count, workRng.unit())]
            let kinds = errandKinds(bugs[i])
            guard !kinds.isEmpty else { continue }
            var total = 0.0
            for k in kinds { total += k.1 }
            var roll = workRng.unit() * total
            var kind = kinds[kinds.count - 1].0
            for k in kinds {
                roll -= k.1
                if roll <= 0 {
                    kind = k.0
                    break
                }
            }
            var j = Job(family: .errand)
            j.errand = kind
            j.edgeOnly = dusk
            j.count = 0
            bugs[i].job = j
            bugs[i].restGesture = .none
            stage.census.workers += 1
            stage.census.errands += 1
            stage.work.errandGap = workRng.range(t.errandCooldown)
            return true
        }
        return false
    }

    func errandSpot(_ b: Bug, _ j: Job, reach: ClosedRange<Double>) -> (x: Double, y: Double) {
        let t = tuning
        if j.edgeOnly {
            let e = nearestSide(b.x, b.y)
            let a = along(b.x, b.y, on: e) + workRng.signed() * reach.upperBound
            let d = workRng.range(b.size...max(b.size, min(t.duskBand * 0.8, t.duskBand - b.size)))
            let p = supplyPoint(e, along: a, depth: d)
            return spot(x: p.x, y: p.y, pad: b.size)
        }
        let a = workRng.unit() * 2 * .pi
        let r = workRng.range(reach)
        let g = safeGoal(b, angle: a, distance: r)
        return spot(x: g.x, y: min(g.y, height * 0.75), pad: b.size * 1.2)
    }

    func slideItem(_ kind: PropKind, size: Double, toward b: Bug, edge: Edge) -> Int {
        let feet = b.species.isAirborne ? max(size * 0.5, b.y - b.size * 0.9) : max(size * 0.5, ground(b) + size * 0.5)
        var to: (x: Double, y: Double)
        var from: (x: Double, y: Double)
        switch edge {
        case .left:
            to = (max(size * 0.5 + 2, b.x - b.size * 0.45 - size * 0.5), feet)
            from = (-size * 0.9, feet)
        case .right:
            to = (min(width - size * 0.5 - 2, b.x + b.size * 0.45 + size * 0.5), feet)
            from = (width + size * 0.9, feet)
        case .bottom:
            to = (b.x + b.facing * b.size * 0.4, max(size * 0.5, ground(b) + size * 0.2))
            from = (to.x, -size * 0.9)
        case .top:
            to = (b.x + b.facing * b.size * 0.4, min(height - size * 0.5, b.y + b.size * 0.4))
            from = (to.x, height + size * 0.9)
        }
        let id = addProp(kind, x: from.x, y: from.y, size: size, motion: .flying)
        editProp(id) { q in
            q.fade = 1
            q.fromX = from.x
            q.fromY = from.y
            q.toX = to.x
            q.toY = to.y
            q.length = 0.55
            q.landing = .rest
            q.claim = b.id
        }
        return id
    }

    func placeDown(_ id: Int, by b: Bug, life: Double) {
        guard let k = propIndex(id) else { return }
        var q = stage.yard.bodies[k]
        let floor = b.species.isAirborne ? max(q.size * 0.5, b.y - b.size * 0.5 - q.size * 0.1) : ground(b) + q.size * 0.5
        q.motion = .flying
        q.holder = -1
        q.partner = -1
        q.claim = -1
        q.fromX = q.x
        q.fromY = q.y + q.z
        q.z = 0
        q.toX = min(max(b.x + b.facing * (b.size * 0.5 + q.size * 0.55), q.size * 0.5), width - q.size * 0.5)
        q.toY = max(q.size * 0.5, floor)
        q.clock = 0
        q.length = 0.3
        q.hump = 5
        q.landing = .rest
        q.life = life
        q.leaving = false
        stage.yard.bodies[k] = q
    }

    func errandStep(_ b: inout Bug, _ j: inout Job, tr: SpeciesTraits, h: Double) -> Bool {
        if j.alarm > 0 { j.alarm = 0 }
        switch j.errand {
        case .deliver: return deliverStep(&b, &j, tr: tr, h: h)
        case .crumb: return crumbStep(&b, &j, tr: tr, h: h)
        case .plant: return plantStep(&b, &j, tr: tr, h: h)
        case .pollinate: return pollinateStep(&b, &j, tr: tr, h: h)
        case .lantern: return lanternStep(&b, &j, tr: tr, h: h)
        case .slide: return slideStep(&b, &j, tr: tr, h: h)
        }
    }

    func deliverStep(_ b: inout Bug, _ j: inout Job, tr: SpeciesTraits, h: Double) -> Bool {
        let pace = paceOf(b, tr)
        switch j.stage {
        case 0:
            let e = nearestSide(b.x, b.y)
            j.x = Double(Edge.allCases.firstIndex(of: e) ?? 0)
            let p = supplyPoint(e, along: along(b.x, b.y, on: e), depth: b.size * 0.7)
            j.tx = p.x
            j.ty = p.y + airLift(b)
            j.stage = 1
            j.clock = 0
        case 1:
            j.gesture = .none
            if walkTo(&b, j.tx, j.ty, pace: pace * 0.85, tr: tr, h: h) || j.clock > 20 {
                let e = Edge.allCases[min(3, max(0, Int(j.x)))]
                j.target = slideItem(seasonItem(config.season), size: itemSize(seasonItem(config.season), unit: unitOf(b)), toward: b, edge: e)
                j.stage = 2
                j.clock = 0
            }
        case 2:
            holdStill(&b, tr: tr, h: h)
            j.gesture = .pull
            guard let q = prop(j.target) else { return true }
            turnTo(&b, x: q.x)
            if q.motion == .rest && j.clock > 0.6 {
                j.stage = 3
                j.clock = 0
            }
        case 3:
            holdStill(&b, tr: tr, h: h)
            j.gesture = .build
            guard let k = propIndex(j.target) else { return true }
            if j.clock >= 0.35 {
                stage.yard.bodies[k].motion = .carried
                stage.yard.bodies[k].holder = b.id
                stage.yard.bodies[k].claim = -1
                j.held = j.target
                j.target = -1
                let s = errandSpot(b, j, reach: 160...380)
                j.tx = s.x
                j.ty = s.y
                j.stage = 4
                j.clock = 0
            }
        case 4:
            guard j.held >= 0, prop(j.held)?.motion == .carried else { return true }
            j.gesture = .carry
            if walkTo(&b, j.tx, j.ty, pace: pace * 0.7, tr: tr, h: h) || j.clock > 30 {
                j.stage = 5
                j.clock = 0
            }
        case 5:
            holdStill(&b, tr: tr, h: h)
            j.gesture = .build
            if j.clock >= 0.4 {
                placeDown(j.held, by: b, life: 45)
                j.target = j.held
                j.held = -1
                j.stage = 6
                j.clock = 0
            }
        default:
            holdStill(&b, tr: tr, h: h)
            if let q = prop(j.target) { turnTo(&b, x: q.x) }
            j.gesture = j.clock < 1.4 ? .look : .cheer
            if j.clock > 2.2 { return true }
        }
        return false
    }

    func crumbStep(_ b: inout Bug, _ j: inout Job, tr: SpeciesTraits, h: Double) -> Bool {
        switch j.stage {
        case 0:
            let s = errandSpot(b, j, reach: 120...280)
            let u = unitOf(b)
            let size = itemSize(.crumb, unit: u) * workRng.range(0.9...1.3)
            let id = addProp(.crumb, x: s.x, y: max(size * 0.5, s.y - b.size * 0.5 + size * 0.5), size: size)
            editProp(id) { q in
                q.fadeIn = 1.2
                q.claim = b.id
            }
            j.target = id
            j.length = workRng.range(4...6)
            j.stage = 1
            j.clock = 0
        case 1:
            guard let q = prop(j.target) else { return true }
            j.gesture = j.clock < 1 ? .look : .none
            if j.clock < 1 {
                holdStill(&b, tr: tr, h: h)
                turnTo(&b, x: q.x)
                return false
            }
            let st = beside(q, b)
            if walkTo(&b, st.x, st.y, pace: paceOf(b, tr) * 0.6, tr: tr, h: h) || j.clock > 30 {
                j.stage = 2
                j.clock = 0
            }
        case 2:
            holdStill(&b, tr: tr, h: h)
            guard let q = prop(j.target) else { return true }
            turnTo(&b, x: q.x)
            j.gesture = .build
            let left = max(0, 1 - j.clock / max(0.5, j.length))
            editProp(q.id) { r in
                r.progress = left
                r.claim = b.id
            }
            if left <= 0 {
                editProp(q.id) { r in
                    r.doomed = true
                    r.doomRate = 4
                }
                j.target = -1
                j.stage = 3
                j.clock = 0
            }
        default:
            holdStill(&b, tr: tr, h: h)
            j.gesture = j.clock < 1.2 ? .cheer : .sleep
            if j.clock > 3 { return true }
        }
        return false
    }

    func plantStep(_ b: inout Bug, _ j: inout Job, tr: SpeciesTraits, h: Double) -> Bool {
        let t = tuning
        switch j.stage {
        case 0:
            if j.count == 0 { j.length = Double(1 + Int(workRng.unit() * 3)) }
            let s = j.count == 0 ? errandSpot(b, j, reach: 80...240) : spot(x: b.x + b.facing * workRng.range(50...80), y: b.y + workRng.signed() * 20, pad: b.size * 1.2)
            j.tx = s.x
            j.ty = s.y
            j.stage = 1
            j.clock = 0
        case 1:
            j.gesture = .none
            if walkTo(&b, j.tx, j.ty, pace: paceOf(b, tr) * 0.8, tr: tr, h: h) || j.clock > 20 {
                j.stage = 2
                j.clock = 0
            }
        case 2:
            holdStill(&b, tr: tr, h: h)
            j.gesture = .build
            if j.clock >= 0.8 && j.target < 0 {
                let size = itemSize(.flower, unit: unitOf(b))
                let x = min(max(b.x + b.facing * (b.size * 0.5 + size * 0.3), size), width - size)
                let id = addProp(.flower, x: x, y: max(size * 0.5, ground(b) + size * 0.5), size: size, progress: 0)
                editProp(id) { q in
                    q.growRate = 1 / max(0.3, t.plantGrow)
                    q.life = 90
                    q.fadeIn = 3
                }
                j.target = id
            }
            if j.clock >= 1.6 {
                j.stage = 3
                j.clock = 0
            }
        default:
            holdStill(&b, tr: tr, h: h)
            if let q = prop(j.target) { turnTo(&b, x: q.x) }
            j.gesture = j.clock < 1.5 ? .look : .cheer
            if j.clock > 2.3 {
                j.count += 1
                j.target = -1
                if Double(j.count) >= j.length || looseFlowers() >= max(0, t.flowerMax) { return true }
                j.stage = 0
                j.clock = 0
            }
        }
        return false
    }

    func pollinateStep(_ b: inout Bug, _ j: inout Job, tr: SpeciesTraits, h: Double) -> Bool {
        if j.stage == 0 {
            var ids: [(Double, Int)] = []
            for q in stage.yard.bodies where q.kind == .flower && !q.doomed && q.progress > 0.5 {
                ids.append((hypot(q.x - b.x, q.y - b.y), q.id))
            }
            ids.sort { $0.0 < $1.0 }
            j.spots = ids.prefix(3).map { $0.1 }
            guard !j.spots.isEmpty else { return true }
            j.count = 0
            j.stage = 1
            j.clock = 0
        }
        guard j.count < j.spots.count else {
            holdStill(&b, tr: tr, h: h)
            j.gesture = .cheer
            return j.clock > 1.2
        }
        guard let q = prop(j.spots[j.count]) else {
            j.count += 1
            j.stage = 1
            j.clock = 0
            return false
        }
        let above = spot(x: q.x, y: q.y + q.size * 0.55 + b.size * 0.45, pad: b.size * 0.5)
        if j.stage == 1 {
            j.gesture = .none
            if walkTo(&b, above.x, above.y, pace: paceOf(b, tr) * 0.8, tr: tr, h: h, within: 6) || j.clock > 15 {
                j.stage = 2
                j.clock = 0
                j.length = workRng.range(1.8...3)
            }
        } else {
            hover(&b, tr: tr, h: h, spin: 0.6, scale: 0.6)
            b.mode = .resting
            j.gesture = .look
            if j.clock >= j.length {
                j.count += 1
                j.stage = 1
                j.clock = 0
            }
        }
        return false
    }

    func lanternStep(_ b: inout Bug, _ j: inout Job, tr: SpeciesTraits, h: Double) -> Bool {
        let t = tuning
        switch j.stage {
        case 0:
            let size = itemSize(.lantern, unit: unitOf(b))
            let c = carryPoint(b, size: size)
            let id = addProp(.lantern, x: c.x, y: c.y, size: size, motion: .carried)
            editProp(id) { q in
                q.holder = b.id
                q.fadeIn = 1.5
            }
            j.held = id
            j.length = workRng.range(t.lanternWalk)
            j.stage = 1
            j.clock = 0
            j.count = 0
            let s = errandSpot(b, j, reach: 120...260)
            j.tx = s.x
            j.ty = s.y
        case 1:
            guard j.held >= 0, prop(j.held)?.motion == .carried else { return true }
            j.gesture = .carry
            let arrived = walkTo(&b, j.tx, j.ty, pace: paceOf(b, tr) * 0.45, tr: tr, h: h, within: 14)
            if arrived {
                j.stage = 2
                j.y = j.clock
            }
            if j.clock >= j.length {
                j.stage = 3
                j.clock = 0
            }
        case 2:
            guard j.held >= 0, prop(j.held)?.motion == .carried else { return true }
            holdStill(&b, tr: tr, h: h)
            j.gesture = .look
            if b.facingHold <= 0 && j.clock - j.y > 0.8 {
                b.facing = -b.facing
                b.facingHold = 0.9
            }
            if j.clock - j.y > 2 {
                let s = errandSpot(b, j, reach: 120...260)
                j.tx = s.x
                j.ty = s.y
                j.stage = 1
            }
            if j.clock >= j.length {
                j.stage = 3
                j.clock = 0
            }
        case 3:
            holdStill(&b, tr: tr, h: h)
            j.gesture = .build
            if j.clock >= 0.4 {
                placeDown(j.held, by: b, life: 20)
                j.target = j.held
                j.held = -1
                j.stage = 4
                j.clock = 0
            }
        default:
            holdStill(&b, tr: tr, h: h)
            if let q = prop(j.target) { turnTo(&b, x: q.x) }
            j.gesture = .look
            if j.clock > 1.6 { return true }
        }
        return false
    }

    func slideStep(_ b: inout Bug, _ j: inout Job, tr: SpeciesTraits, h: Double) -> Bool {
        switch j.stage {
        case 0:
            if j.count == 0 { j.length = Double(2 + Int(workRng.unit() * 2)) }
            let room = width - b.x > b.x ? 1.0 : -1.0
            j.sign = room
            holdStill(&b, tr: tr, h: h)
            turnTo(&b, x: b.x + room * 10)
            j.gesture = .build
            if j.target < 0 || prop(j.target) == nil {
                if j.clock >= 0.9 {
                    let size = itemSize(.snowball, unit: unitOf(b))
                    let x = min(max(b.x + room * (b.size * 0.42 + size * 0.5), size), width - size)
                    let id = addProp(.snowball, x: x, y: max(size * 0.5, ground(b) + size * 0.5), size: size)
                    editProp(id) { q in
                        q.fadeIn = 3
                        q.claim = b.id
                        q.life = 30
                    }
                    j.target = id
                    j.stage = 1
                    j.clock = 0
                }
            } else {
                j.stage = 1
                j.clock = 0
            }
        case 1:
            guard let q = prop(j.target), q.motion == .rest || q.motion == .rolling else { return true }
            j.gesture = .none
            let sx = q.x - j.sign * (b.size * 0.42 + q.size * 0.5)
            let sy = q.y - q.size * 0.5 + b.size * 0.5
            if walkTo(&b, sx, sy, pace: paceOf(b, tr), tr: tr, h: h) || j.clock > 12 {
                editProp(q.id) { r in
                    r.motion = .pushed
                    r.claim = b.id
                }
                j.pushing = q.id
                b.course = j.sign > 0 ? 0 : .pi
                j.stage = 2
                j.clock = 0
            }
        case 2:
            guard j.pushing >= 0, prop(j.pushing)?.motion == .pushed else { return true }
            j.gesture = .push
            steer(&b, toward: j.sign > 0 ? 0 : .pi, rate: 6, h: h)
            approach(&b.speed, paceOf(b, tr) * 0.9, rate: 80, h: h)
            workMove(&b)
            let wall = j.sign > 0 ? width - b.x : b.x
            if j.clock > 1.3 || wall < 160 {
                if let k = propIndex(j.pushing) {
                    stage.yard.bodies[k].motion = .rolling
                    stage.yard.bodies[k].claim = -1
                    stage.yard.bodies[k].vx = j.sign * 230
                    stage.yard.bodies[k].vy = 0
                }
                j.pushing = -1
                b.glide = true
                b.speed = 150
                b.course = j.sign > 0 ? 0 : .pi
                j.stage = 3
                j.clock = 0
            }
        case 3:
            j.gesture = .none
            b.glide = true
            brake(&b, tau: 0.75, h: h)
            b.mode = .wandering
            if b.speed < 12 || edgeDistance(b.x, b.y) < b.size {
                b.glide = false
                j.stage = 4
                j.clock = 0
            }
        default:
            b.glide = false
            holdStill(&b, tr: tr, h: h)
            j.gesture = .cheer
            if j.clock > 1 {
                j.count += 1
                if Double(j.count) >= j.length { return true }
                j.stage = 1
                j.clock = 0
                if let q = prop(j.target), q.motion == .rest {
                    j.sign = width - q.x > q.x ? 1 : -1
                    editProp(q.id) { $0.claim = b.id }
                } else {
                    return true
                }
            }
        }
        return false
    }

    func inspectOpen() -> Bool {
        let t = tuning
        guard t.inspectChance > 0, stage.work.inspectGap <= 0 else { return false }
        guard stage.work.projects.contains(where: { !$0.dormant && $0.phase != .finished }) else { return false }
        return bugs.contains { $0.rare && $0.mode != .hidden && $0.free && onScreen($0) }
    }

    func startInspect() -> Bool {
        let t = tuning
        guard let pi = stage.work.projects.firstIndex(where: { !$0.dormant && $0.phase != .finished }) else { return false }
        guard let i = bugs.indices.first(where: { bugs[$0].rare && bugs[$0].mode != .hidden && bugs[$0].free && onScreen(bugs[$0]) }) else { return false }
        stage.work.inspectGap = workRng.range(t.inspectCooldown)
        guard workRng.chance(t.inspectChance) else { return false }
        var j = Job(family: .visit)
        j.group = stage.work.projects[pi].id
        j.sign = bugs[i].x >= stage.work.projects[pi].x ? 1 : -1
        bugs[i].job = j
        bugs[i].restGesture = .none
        return true
    }

    func unheap(_ id: Int, from pi: Int) {
        var p = stage.work.projects[pi]
        p.heap.removeAll { $0 == id }
        if p.phase == .building, p.step < p.steps.count, let q = prop(id) {
            let s = p.steps[p.step]
            if s.task == .fetch && !s.merge && s.item == q.kind { p.done = max(0, p.done - 1) }
        }
        stage.work.projects[pi] = p
    }

    func inspectStep(_ b: inout Bug, _ j: inout Job, tr: SpeciesTraits, h: Double) -> Bool {
        guard let pi = projectIndex(j.group) else { return true }
        let p = stage.work.projects[pi]
        if p.dormant { return true }
        switch j.stage {
        case 0:
            j.gesture = .none
            let s = spot(x: p.x + j.sign * (siteHalf(p.kind, p.unit) + b.size * 0.8), y: p.y + b.size * 0.5 + airLift(b), pad: b.size)
            if walkTo(&b, s.x, s.y, pace: paceOf(b, tr) * 0.8, tr: tr, h: h) || j.clock > 25 {
                j.stage = 1
                j.clock = 0
            }
        case 1:
            holdStill(&b, tr: tr, h: h)
            turnTo(&b, x: p.x)
            j.gesture = .look
            if j.clock > 2.4 {
                j.stage = 2
                j.clock = 0
            }
        case 2:
            holdStill(&b, tr: tr, h: h)
            turnTo(&b, x: p.x)
            switch b.species {
            case .fox, .blackCat:
                if let id = p.heap.last, let q = prop(id), q.motion == .rest, fits(b, q.size) {
                    j.family = .thief
                    j.target = id
                    j.stage = 0
                    j.clock = 0
                    editProp(id) { $0.claim = b.id }
                    return false
                }
                j.gesture = .build
            case .santa:
                j.gesture = .build
                if j.clock >= 0.5 && j.target < 0 {
                    let n = nextHeapSlot(p)
                    let hs = heapSpot(p, n)
                    let size = itemSize(.present, unit: p.unit)
                    let c = carryPoint(b, size: size)
                    let id = addProp(.present, x: c.x, y: c.y, size: size, motion: .flying)
                    editProp(id) { q in
                        q.fade = 0.4
                        q.fadeIn = 4
                        q.fromX = c.x
                        q.fromY = c.y
                        q.toX = hs.x
                        q.toY = hs.y + size * 0.5
                        q.length = 0.5
                        q.hump = 20
                        q.site = p.id
                        q.slot = n
                        q.layer = hs.layer
                    }
                    stage.work.projects[pi].heap.append(id)
                    j.target = id
                }
            case .ufo:
                j.gesture = .look
                if j.clock >= 0.6 && j.target < 0, let id = p.heap.last, let k = propIndex(id), stage.yard.bodies[k].motion == .rest {
                    unheap(id, from: pi)
                    var q = stage.yard.bodies[k]
                    q.motion = .flying
                    q.fromX = q.x
                    q.fromY = q.y
                    q.toX = b.x
                    q.toY = height + q.size * 2
                    q.clock = 0
                    q.length = 1.6
                    q.hump = 0
                    q.spin = 2
                    q.landing = .vanish
                    q.site = -1
                    q.slot = -1
                    stage.yard.bodies[k] = q
                    j.target = id
                }
            case .bunny:
                j.gesture = .build
                if j.clock >= 0.8 && j.target < 0 {
                    let size = itemSize(.flower, unit: unitOf(b))
                    let x = min(max(b.x + b.facing * (b.size * 0.5 + size * 0.3), size), width - size)
                    let id = addProp(.flower, x: x, y: max(size * 0.5, ground(b) + size * 0.5), size: size, progress: 0)
                    editProp(id) { q in
                        q.growRate = 1 / max(0.3, tuning.plantGrow)
                        q.life = 60
                    }
                    j.target = id
                }
            default:
                j.gesture = j.clock < 1.2 ? .build : .cheer
            }
            if j.clock > 2.2 {
                j.stage = 3
                j.clock = 0
            }
        default:
            holdStill(&b, tr: tr, h: h)
            j.gesture = b.species == .fox || b.species == .blackCat ? .look : .cheer
            if j.clock > 1.4 { return true }
        }
        return false
    }
}
