import Foundation

extension World {
    func idleMate(_ p: Project, except id: Int) -> Int? {
        for m in p.crew where m != id {
            guard let i = index(of: m), let o = bugs[i].job, o.task == .idle || o.task == .wait else { continue }
            guard o.held < 0, o.pushing < 0, canCarry(bugs[i]), bugs[i].species.locomotion != .dart else { continue }
            return i
        }
        return nil
    }

    func waitingLead(_ p: Project, except id: Int) -> Int? {
        for m in p.crew where m != id {
            guard let i = index(of: m), let o = bugs[i].job, o.task == .fetch, o.lead, o.heavy, o.count == p.step, o.held < 0 else { continue }
            if o.mate >= 0, let mi = index(of: o.mate), bugs[mi].mode != .hidden, bugs[mi].job?.mate == m { continue }
            return i
        }
        return nil
    }

    func pairMate(_ mi: Int, with lead: Bug, step: Int) {
        guard var o = bugs[mi].job else { return }
        o.task = .fetch
        o.lead = false
        o.heavy = true
        o.mate = lead.id
        o.count = step
        o.stage = 0
        o.clock = 0
        o.held = -1
        o.slot = -1
        o.sign = bugs[mi].x >= lead.x ? 1 : -1
        bugs[mi].job = o
    }

    func nextHeapSlot(_ p: Project) -> Int {
        var used = Set<Int>()
        for id in p.heap {
            if let q = prop(id) { used.insert(q.slot) }
        }
        var n = 0
        while used.contains(n) { n += 1 }
        return n
    }

    func looseItem(_ kind: PropKind, near b: Bug, project: Project) -> Int? {
        var best: Int?
        var bestD = 700.0
        for q in stage.yard.bodies where q.kind == kind && q.motion == .rest && q.claim < 0 && !q.doomed && !q.leaving && q.game < 0 && q.fade > 0.3 {
            guard q.site < 0 || (q.site == project.id && !project.heap.contains(q.id) && !project.sites.contains(q.id) && q.id != project.rollProp && q.id != project.liftProp) else { continue }
            let d = hypot(q.x - b.x, q.y - b.y)
            if d < bestD {
                bestD = d
                best = q.id
            }
        }
        return best
    }

    func assignFetch(_ b: inout Bug, _ j: inout Job, _ pi: Int) {
        let p = stage.work.projects[pi]
        let s = p.steps[p.step]
        j.heavy = false
        if canCarry(b), let li = waitingLead(p, except: b.id) {
            j.task = .fetch
            j.lead = false
            j.heavy = true
            j.mate = bugs[li].id
            j.sign = b.x >= bugs[li].x ? 1 : -1
            bugs[li].job?.mate = b.id
            return
        }
        var flight = 0
        for id in p.crew where id != b.id {
            if let i = index(of: id), let o = bugs[i].job, o.task == .fetch, o.lead, o.count == p.step { flight += 1 }
        }
        let remaining = s.count - Int((p.done + 1e-9).rounded(.down)) - flight
        guard remaining > 0, canCarry(b) else {
            j.task = .wait
            return
        }
        let pushes = canPush(b) && rounds(s.item) && (b.species.stance == .topDown || s.item == .pumpkin)
        var heavy = s.heavy
        var mate = heavy || s.item == .present ? idleMate(p, except: b.id) : nil
        if !heavy && s.item == .present && mate != nil && workRng.chance(0.5) { heavy = true }
        if !heavy { mate = nil }
        let size = itemSize(s.item, unit: p.unit, heavy: heavy)
        guard fits(b, size) || pushes || heavy || s.item == .balloon else {
            j.task = .wait
            return
        }
        j.task = .fetch
        j.lead = true
        j.heavy = heavy
        if heavy {
            if let mi = mate {
                pairMate(mi, with: b, step: p.step)
                j.mate = bugs[mi].id
            } else {
                j.stage = -1
            }
        }
        j.x = p.supplyAlong + workRng.signed() * 50
        if !heavy, let id = looseItem(s.item, near: b, project: p) {
            j.target = id
            editProp(id) { $0.claim = b.id }
        }
    }

    func mateReady(_ j: Job) -> Bool {
        guard j.mate >= 0, let mi = index(of: j.mate), bugs[mi].mode != .hidden, let o = bugs[mi].job else { return false }
        return o.task == .fetch && !o.lead && o.stage == 1
    }

    func mateValid(_ b: Bug, _ j: Job) -> Bool {
        guard j.mate >= 0, let mi = index(of: j.mate), bugs[mi].mode != .hidden, let o = bugs[mi].job else { return false }
        return o.task == .fetch && !o.lead && o.mate == b.id && o.group == j.group
    }

    func airLift(_ b: Bug) -> Double {
        b.species.isAirborne ? b.size * 0.8 : 0
    }

    func beside(_ q: PropBody, _ b: Bug) -> (x: Double, y: Double) {
        let side: Double = b.x >= q.x ? 1 : -1
        return spot(x: q.x + side * (q.size * 0.5 + b.size * 0.42), y: q.y - q.size * 0.5 + b.size * 0.5 + airLift(b), pad: b.size * 0.4)
    }

    func fetchStep(_ b: inout Bug, _ j: inout Job, _ pi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        if !j.lead { return mateStep(&b, &j, pi, tr: tr, h: h) }
        let p = stage.work.projects[pi]
        let s = p.steps[min(p.step, p.steps.count - 1)]
        let pace = paceOf(b, tr)
        switch j.stage {
        case -1:
            j.gesture = .look
            let r = ringSpot(p, max(0, j.role), b, extra: b.size * 0.5)
            stayAt(&b, r.x, r.y, tr: tr, h: h)
            turnTo(&b, x: p.x)
            if mateValid(b, j) {
                j.stage = 0
                j.clock = 0
            } else if j.clock > 8 {
                j.task = .idle
            }
        case 0:
            j.gesture = .none
            if j.heavy && !mateValid(b, j) {
                j.stage = -1
                j.clock = 0
                return false
            }
            if j.target >= 0 {
                guard let q = prop(j.target), q.claim == b.id, q.motion == .rest else {
                    j.target = -1
                    return false
                }
                let st = beside(q, b)
                if walkTo(&b, st.x, st.y, pace: pace, tr: tr, h: h) {
                    j.stage = 3
                    j.clock = 0
                }
            } else {
                let st = supplyPoint(p.supply, along: j.x, depth: b.size * 0.7)
                let arrived = walkTo(&b, st.x, st.y + airLift(b), pace: pace, tr: tr, h: h)
                if arrived && (!j.heavy || mateReady(j)) {
                    j.stage = 2
                    j.clock = 0
                    spawnSupply(&b, &j, p, s)
                } else if arrived {
                    j.gesture = .look
                }
            }
            if j.clock > 40 { j.task = .idle }
        case 2:
            holdStill(&b, tr: tr, h: h)
            j.gesture = .pull
            switch p.supply {
            case .left: turnTo(&b, x: -1)
            case .right: turnTo(&b, x: width + 1)
            default: break
            }
            guard let q = prop(j.target) else {
                j.stage = 0
                j.target = -1
                return false
            }
            if q.motion == .rest && j.clock >= 0.55 {
                j.stage = 3
                j.clock = 0
            }
        case 3:
            holdStill(&b, tr: tr, h: h)
            j.gesture = .build
            guard let q = prop(j.target), q.claim == b.id || q.claim < 0, q.motion == .rest || q.motion == .rolling else {
                j.task = .idle
                j.target = -1
                return false
            }
            turnTo(&b, x: q.x)
            if j.heavy && !mateReady(j) {
                if j.clock > 6 { j.task = .idle }
                return false
            }
            if j.clock >= 0.35 { liftItem(&b, &j, p, s) }
        case 4:
            let mine = j.held >= 0 ? prop(j.held).map { $0.motion == .carried } ?? false : (j.pushing >= 0 ? prop(j.pushing).map { $0.motion == .pushed && $0.claim == b.id } ?? false : false)
            guard mine else {
                j.held = -1
                j.pushing = -1
                j.task = .idle
                return false
            }
            var v = pace * (j.heavy ? 0.7 : (j.pushing >= 0 ? 0.55 : 0.8))
            if j.heavy, let mi = index(of: j.mate), hypot(bugs[mi].x - b.x, bugs[mi].y - b.y) > (bugs[mi].size + b.size) * 0.9 { v *= 0.3 }
            let within: Double? = j.pushing >= 0 ? b.size * 0.42 + (prop(j.pushing)?.size ?? 0) * 0.5 : nil
            let arrived = walkTo(&b, j.tx, j.ty, pace: v, tr: tr, h: h, within: within)
            j.gesture = j.pushing >= 0 ? .push : .carry
            if j.tripAt > 0 && j.held >= 0 && hypot(j.tx - b.x, j.ty - b.y) < j.span * (1 - j.tripAt) {
                trip(&b, &j)
                return false
            }
            if arrived || j.clock > 45 {
                j.stage = 5
                j.clock = 0
            }
        case 5:
            holdStill(&b, tr: tr, h: h)
            turnTo(&b, x: s.merge ? p.x : j.tx)
            j.gesture = .build
            if j.clock >= 0.45 { placeItem(&b, &j, pi) }
        case 6:
            brake(&b, tau: 0.08, h: h)
            if b.species.locomotion == .hop { b.speed = 0 }
            b.mode = .resting
            j.gesture = onFoot(b) ? .tumble : .look
            if j.clock > 0.75 {
                j.stage = 7
                j.clock = 0
            }
        case 7:
            j.gesture = .none
            guard let q = prop(j.target), q.motion == .rest || q.motion == .rolling, q.claim == b.id || q.claim < 0 else {
                j.task = .idle
                j.target = -1
                return false
            }
            editProp(q.id) { $0.claim = b.id }
            let st = beside(q, b)
            if walkTo(&b, st.x, st.y, pace: pace, tr: tr, h: h) || j.clock > 12 {
                j.stage = 3
                j.clock = 0
            }
        default:
            j.task = .idle
        }
        return false
    }

    func spawnSupply(_ b: inout Bug, _ j: inout Job, _ p: Project, _ s: ProjectStep) {
        let size = itemSize(s.item, unit: p.unit, heavy: j.heavy)
        let feet = b.species.isAirborne ? b.y - b.size * 0.9 : ground(b) + size * 0.5
        var to: (x: Double, y: Double)
        var from: (x: Double, y: Double)
        switch p.supply {
        case .left:
            to = (max(size * 0.5 + 2, b.x - b.size * 0.45 - size * 0.5), feet)
            from = (-size * 0.9, feet)
        case .right:
            to = (min(width - size * 0.5 - 2, b.x + b.size * 0.45 + size * 0.5), feet)
            from = (width + size * 0.9, feet)
        case .bottom:
            to = (b.x + b.facing * b.size * 0.35, max(size * 0.5, ground(b) + size * 0.2))
            from = (to.x, -size * 0.9)
        case .top:
            to = (b.x + b.facing * b.size * 0.35, min(height - size * 0.5, b.y + b.size * 0.4))
            from = (to.x, height + size * 0.9)
        }
        let id = addProp(s.item, x: from.x, y: from.y, size: size, motion: .flying)
        editProp(id) { q in
            q.fade = 1
            q.fromX = from.x
            q.fromY = from.y
            q.toX = to.x
            q.toY = to.y
            q.length = 0.55
            q.hump = 0
            q.landing = .rest
            q.claim = b.id
        }
        j.target = id
    }

    func liftItem(_ b: inout Bug, _ j: inout Job, _ p: Project, _ s: ProjectStep) {
        guard let k = propIndex(j.target) else {
            j.task = .idle
            return
        }
        var q = stage.yard.bodies[k]
        let pushes = !j.heavy && canPush(b) && rounds(q.kind) && (b.species.stance == .topDown || q.kind == .pumpkin || !fits(b, q.size))
        q.game = -1
        q.z = 0
        if pushes {
            q.motion = .pushed
            q.claim = b.id
            j.pushing = q.id
            j.held = -1
            b.course = atan2(q.y - b.y, q.x - b.x)
        } else {
            q.motion = .carried
            q.holder = b.id
            q.partner = j.heavy ? j.mate : -1
            q.claim = -1
            j.held = q.id
            if j.heavy, let mi = index(of: j.mate) { bugs[mi].job?.held = q.id }
        }
        stage.yard.bodies[k] = q
        j.target = -1
        if s.merge {
            let side: Double = b.x >= p.x ? 1 : -1
            let st = spot(x: p.x + side * (siteHalf(p.kind, p.unit) * 0.8 + b.size * 0.55 + (j.heavy ? b.size * 0.6 : 0)), y: p.y + b.size * 0.5 + airLift(b), pad: b.size * 0.6)
            j.tx = st.x
            j.ty = st.y
        } else {
            let hs = heapSpot(p, nextHeapSlot(p))
            if pushes {
                j.tx = hs.x
                j.ty = hs.y + b.size * 0.5
            } else {
                let side: Double = b.x >= hs.x ? 1 : -1
                let st = spot(x: hs.x + side * (q.size * 0.5 + b.size * 0.5 + (j.heavy ? b.size * 0.55 : 0)), y: hs.y + b.size * 0.5 + airLift(b), pad: b.size * 0.6)
                j.tx = st.x
                j.ty = st.y
            }
        }
        j.span = hypot(j.tx - b.x, j.ty - b.y)
        j.tripAt = !j.heavy && !pushes && j.span > 160 && workRng.chance(tuning.dropChance) ? workRng.range(0.35...0.65) : -1
        j.stage = 4
        j.clock = 0
    }

    func trip(_ b: inout Bug, _ j: inout Job) {
        guard let k = propIndex(j.held) else { return }
        var q = stage.yard.bodies[k]
        loosen(&q, from: b, gentle: false, vx: cos(b.heading) * b.pace * 0.6, vy: sin(b.heading) * b.pace * 0.2)
        q.claim = b.id
        stage.yard.bodies[k] = q
        j.target = q.id
        j.held = -1
        j.tripAt = -1
        j.stage = 6
        j.clock = 0
        b.speed *= 0.3
    }

    func placeItem(_ b: inout Bug, _ j: inout Job, _ pi: Int) {
        var p = stage.work.projects[pi]
        let s = p.steps[min(p.step, p.steps.count - 1)]
        let id = j.held >= 0 ? j.held : j.pushing
        guard let k = propIndex(id) else {
            j.held = -1
            j.pushing = -1
            j.task = .idle
            return
        }
        var q = stage.yard.bodies[k]
        q.holder = -1
        q.partner = -1
        q.claim = -1
        q.site = p.id
        q.fromX = q.x
        q.fromY = q.y + q.z
        q.z = 0
        q.clock = 0
        q.spin = 0
        q.motion = .flying
        let matches = p.phase == .building && s.task == .fetch && s.item == q.kind
        if s.merge && matches {
            let m = mergeTarget(p)
            q.toX = m.x
            q.toY = m.y
            q.length = 0.45
            q.hump = p.unit * 0.6
            q.landing = .merge
        } else {
            let n = nextHeapSlot(p)
            let hs = heapSpot(p, n)
            q.toX = hs.x
            q.toY = hs.y + q.size * 0.5
            q.length = 0.35
            q.hump = 6 + q.size * 0.3
            q.landing = .rest
            q.slot = n
            q.layer = hs.layer
            p.heap.append(q.id)
            if matches {
                p.done += 1
                if s.slot >= 0 { applyLevel(&p, slot: s.slot, value: p.from + (s.to - p.from) * min(1, p.done / Double(max(1, s.count)))) }
            }
        }
        stage.yard.bodies[k] = q
        stage.work.projects[pi] = p
        j.held = -1
        j.pushing = -1
        j.trips += 1
        j.task = .idle
        j.gesture = .none
    }

    func mateStep(_ b: inout Bug, _ j: inout Job, _ pi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        guard let li = index(of: j.mate), bugs[li].mode != .hidden, let lj = bugs[li].job, lj.family == .crew, lj.group == j.group, lj.mate == b.id, lj.task == .fetch, lj.lead else {
            if j.held >= 0 { j.trips += 1 }
            j.task = .idle
            j.held = -1
            j.mate = -1
            j.lead = true
            j.heavy = false
            return false
        }
        let lead = bugs[li]
        j.held = lj.held >= 0 && (prop(lj.held)?.partner == b.id) ? lj.held : -1
        let gap = (lead.size + b.size) * 0.5 + 4
        let tx = lead.x + j.sign * gap, ty = lead.y + (b.size - lead.size) * 0.5
        let d = hypot(tx - b.x, ty - b.y)
        if lj.stage == 4 && d < 6 {
            steer(&b, toward: lead.course, rate: 8, h: h)
            approach(&b.speed, lead.speed, rate: max(20, paceOf(b, tr)) / 0.15, h: h)
            workMove(&b)
            b.facing = lead.facing
            b.facingHold = 0.3
        } else if d > (lj.stage >= 2 ? 3 : 8) {
            _ = seek(&b, x: tx, y: ty, pace: paceOf(b, tr) * 1.4, tr: tr, h: h, arrive: 2)
            workMove(&b)
        } else {
            holdStill(&b, tr: tr, h: h)
            if lj.stage >= 2 { b.facing = lead.facing }
        }
        j.stage = d < max(10, b.size * 0.6) ? 1 : 0
        switch lj.stage {
        case 2: j.gesture = .pull
        case 3, 5: j.gesture = .build
        case 4: j.gesture = j.held >= 0 ? .carry : .none
        default: j.gesture = .none
        }
        return false
    }

    func createRollBall(_ p: inout Project) {
        let s = p.steps[p.step]
        let u = p.unit
        let size0 = s.start * u, final = s.final * u
        var sx: Double, sy: Double
        if s.item == .pumpkin {
            let sp = supplyPoint(p.supply, along: p.supplyAlong, depth: u * 1.3)
            sx = sp.x
            sy = p.supply == .bottom ? u * 0.5 : min(max(sp.y - u * 0.5, u * 0.5), height * 0.6)
        } else {
            let a = -.pi / 2 + workRng.signed() * 1.3
            let dist = workRng.range(150...230)
            let sp = spot(x: p.x + cos(a) * dist, y: p.y + sin(a) * dist * 0.5, pad: u * 1.5)
            sx = sp.x
            sy = max(u * 0.4, sp.y)
        }
        var ex = p.x, ey = p.y
        if p.kind == .snowman && p.step == 1 {
            let side: Double = sx >= p.x ? 1 : -1
            ex = min(max(p.x + side * u * 1.5, u), width - u)
            ey = p.y
        }
        let dx = ex - sx, dy = ey - sy
        let len = max(1, hypot(dx, dy))
        let off = workRng.range(40...90) * (workRng.chance(0.5) ? 1 : -1)
        let w = spot(x: (sx + ex) / 2 - dy / len * off, y: (sy + ey) / 2 + dx / len * off * 0.5, pad: u * 1.2)
        let path = hypot(w.x - sx, w.y - sy) + hypot(ex - w.x, ey - w.y)
        let id = addProp(s.item, x: sx, y: sy + size0 * 0.5, size: size0, progress: s.item == .pumpkin ? 0 : 1)
        editProp(id) { q in
            q.grows = final > size0 ? (final - size0) / max(1, path) : 0
            q.maxSize = final
            q.site = p.id
            q.fadeIn = 1.5
        }
        p.rollProp = id
        p.rollLeg = 0
        p.rollClock = 0
        p.wayX = w.x
        p.wayY = w.y
        p.endX = ex
        p.endY = ey
    }

    func rollerStep(_ b: inout Bug, _ j: inout Job, _ pi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        var p = stage.work.projects[pi]
        guard p.step < p.steps.count, p.steps[p.step].task == .roll, j.count == p.step else {
            if j.pushing >= 0 { setDown(j.pushing, by: b) }
            j.pushing = -1
            j.task = .idle
            return false
        }
        if !j.lead { return rollHelperStep(&b, &j, pi, tr: tr, h: h) }
        if prop(p.rollProp) == nil {
            createRollBall(&p)
            stage.work.projects[pi] = p
        }
        guard let k = propIndex(p.rollProp) else {
            j.task = .idle
            return false
        }
        let q = stage.yard.bodies[k]
        let last = p.rollLeg >= 1
        let wx = last ? p.endX : p.wayX, wy = last ? p.endY : p.wayY
        let r = q.size * 0.5
        let gby = q.y - r
        let dir = atan2(wy - gby, wx - q.x)
        let d = b.size * 0.42 + r
        switch j.stage {
        case 0:
            j.gesture = .none
            if q.motion == .pushed && q.claim != b.id {
                j.lead = false
                return false
            }
            let sx = q.x - cos(dir) * d, sy = gby - sin(dir) * d * 0.7 + b.size * 0.5
            if walkTo(&b, sx, sy, pace: paceOf(b, tr), tr: tr, h: h) || j.clock > 20 {
                j.stage = q.kind == .snowball && q.age < 4 ? 1 : 2
                j.clock = 0
            }
        case 1:
            holdStill(&b, tr: tr, h: h)
            turnTo(&b, x: q.x)
            j.gesture = .build
            if j.clock >= 1.1 {
                j.stage = 2
                j.clock = 0
            }
        case 2:
            editProp(q.id) { r in
                r.motion = .pushed
                r.claim = b.id
            }
            j.pushing = q.id
            b.course = dir
            j.stage = 3
            j.clock = 0
            j.gesture = .push
        default:
            guard q.motion == .pushed, q.claim == b.id else {
                j.pushing = -1
                j.stage = 0
                return false
            }
            j.gesture = .push
            let grow = q.maxSize > 0 ? min(1, q.size / q.maxSize) : 0
            let tx = wx - cos(dir) * d, ty = wy - sin(dir) * d * 0.7 + b.size * 0.5
            _ = seek(&b, x: tx, y: ty, pace: max(10, paceOf(b, tr) * 0.75 * (1.1 - 0.3 * grow)), tr: tr, h: h, arrive: 0, turn: 2.2)
            workMove(&b)
            turnTo(&b, x: wx)
            p.rollClock += h
            let ballDist = hypot(wx - q.x, wy - gby)
            if ballDist < 10 || p.rollClock > 30 || hypot(tx - b.x, ty - b.y) < 5 {
                if !last {
                    p.rollLeg = 1
                    p.rollClock = 0
                } else {
                    rollArrived(&p, k)
                    j.pushing = -1
                    j.task = .idle
                    j.trips += 1
                }
            }
            stage.work.projects[pi] = p
        }
        return false
    }

    func rollHelperStep(_ b: inout Bug, _ j: inout Job, _ pi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        let p = stage.work.projects[pi]
        var lead: Bug?
        for id in p.crew where id != b.id {
            if let i = index(of: id), let o = bugs[i].job, o.task == .roll, o.lead, o.count == p.step { lead = bugs[i] }
        }
        guard let l = lead else {
            j.lead = true
            j.stage = 0
            return false
        }
        let pushing = l.job?.pushing ?? -1
        let side = j.sign
        let tx = l.x - sin(l.course) * side * (l.size + b.size) * 0.45 - cos(l.course) * b.size * 0.2
        let ty = l.y + cos(l.course) * side * (l.size + b.size) * 0.3
        let s = spot(x: tx, y: ty, pad: b.size * 0.4)
        if hypot(s.x - b.x, s.y - b.y) > 4 {
            _ = seek(&b, x: s.x, y: s.y, pace: paceOf(b, tr) * 1.2, tr: tr, h: h, arrive: 2)
            workMove(&b)
        } else {
            steer(&b, toward: l.course, rate: 6, h: h)
            approach(&b.speed, l.speed, rate: 60, h: h)
            workMove(&b)
        }
        b.facing = l.facing
        b.facingHold = 0.3
        j.gesture = pushing >= 0 ? .push : .none
        return false
    }

    func rollArrived(_ p: inout Project, _ k: Int) {
        var q = stage.yard.bodies[k]
        let r = q.size * 0.5
        q.motion = .rest
        q.claim = -1
        q.x = p.endX
        q.y = p.endY + r
        q.site = p.id
        if p.kind == .snowman && p.step == 0 {
            q.doomed = true
            q.fade = 0
            q.doomRate = 50
            stage.yard.bodies[k] = q
            let size = itemSize(.snowman, unit: p.unit)
            let id = addProp(.snowman, x: p.x, y: p.y + size * 0.5, size: size, progress: 1.0 / 3, layer: 0)
            editProp(id) { s in
                s.site = p.id
                s.fade = 1
            }
            p.sites[0] = id
            applyLevel(&p, slot: 0, value: 1.0 / 3)
        } else if p.kind == .snowman {
            stage.yard.bodies[k] = q
            p.liftProp = q.id
        } else {
            q.layer = 0
            q.progress = 0
            stage.yard.bodies[k] = q
            p.sites[0] = q.id
            applyLevel(&p, slot: 0, value: 0)
        }
        p.done = 1
        p.rollProp = -1
    }

    func lifterStep(_ b: inout Bug, _ j: inout Job, _ pi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        let p = stage.work.projects[pi]
        guard p.step < p.steps.count, p.steps[p.step].task == .lift, let q = prop(p.liftProp) else {
            j.task = .idle
            return false
        }
        let r = q.size * 0.5
        let target = spot(x: q.x + j.sign * (r + b.size * 0.45), y: q.y - r + b.size * 0.5 + airLift(b), pad: b.size * 0.4)
        if j.stage == 0 {
            j.gesture = .none
            if walkTo(&b, target.x, target.y, pace: paceOf(b, tr), tr: tr, h: h) || j.clock > 15 {
                j.stage = 1
                j.clock = 0
            }
            return false
        }
        if p.lifting {
            stayAt(&b, q.x + j.sign * (r + b.size * 0.45), b.y, tr: tr, h: h)
            j.gesture = .carry
        } else {
            holdStill(&b, tr: tr, h: h)
            j.gesture = .build
        }
        turnTo(&b, x: q.x)
        return false
    }

    func stealOpen(room: Int) -> Bool {
        let t = tuning
        guard room > 0, t.stealChance > 0, stage.work.stealGap <= 0 else { return false }
        return stage.work.projects.contains { !$0.dormant && $0.heap.count >= 3 }
    }

    func startSteal() -> Bool {
        let t = tuning
        guard let pi = stage.work.projects.firstIndex(where: { !$0.dormant && $0.heap.count >= 3 }) else { return false }
        guard workRng.chance(t.stealChance) else {
            stage.work.stealGap = workRng.range(8...16)
            return false
        }
        let p = stage.work.projects[pi]
        guard let item = p.heap.last.flatMap({ prop($0) }), item.motion == .rest else { return false }
        var best = -1
        var bestD = 700.0
        for i in bugs.indices where bugs[i].mode != .hidden && workFree(bugs[i]) && canCarry(bugs[i]) && fits(bugs[i], item.size) {
            let d = hypot(bugs[i].x - item.x, bugs[i].y - item.y)
            if d < bestD && d > 80 {
                bestD = d
                best = i
            }
        }
        guard best >= 0 else { return false }
        var j = Job(family: .thief)
        j.group = p.id
        j.target = item.id
        bugs[best].job = j
        bugs[best].restGesture = .none
        editProp(item.id) { $0.claim = bugs[best].id }
        stage.work.stealGap = workRng.range(t.stealCooldown)
        stage.census.workers += 1
        return true
    }

    func thiefStep(_ b: inout Bug, _ j: inout Job, tr: SpeciesTraits, h: Double) -> Bool {
        switch j.stage {
        case 0:
            j.gesture = .tiptoe
            guard let q = prop(j.target), q.motion == .rest, q.claim == b.id else { return true }
            let st = beside(q, b)
            if walkTo(&b, st.x, st.y, pace: paceOf(b, tr) * 0.8, tr: tr, h: h) {
                j.stage = 1
                j.clock = 0
            }
            if j.clock > 25 { return true }
        case 1:
            holdStill(&b, tr: tr, h: h)
            j.gesture = .build
            guard let q = prop(j.target), q.motion == .rest else { return true }
            turnTo(&b, x: q.x)
            if j.clock >= 0.35 {
                if let pi = projectIndex(q.site) {
                    var p = stage.work.projects[pi]
                    p.heap.removeAll { $0 == q.id }
                    if p.phase == .building, p.step < p.steps.count {
                        let s = p.steps[p.step]
                        if s.task == .fetch && !s.merge && s.item == q.kind { p.done = max(0, p.done - 1) }
                    }
                    stage.work.projects[pi] = p
                    for id in p.crew {
                        if let i = index(of: id), hypot(bugs[i].x - b.x, bugs[i].y - b.y) < 450 {
                            bugs[i].job?.alarm = 1.4
                            bugs[i].job?.alarmX = b.x
                        }
                    }
                }
                editProp(q.id) { r in
                    r.motion = .carried
                    r.holder = b.id
                    r.site = -1
                    r.claim = -1
                    r.slot = -1
                    r.layer = 2
                }
                j.held = q.id
                j.target = -1
                let e = nearestSide(b.x, b.y)
                let pt = point(on: e, along: along(b.x, b.y, on: e), depth: b.size * 0.55)
                j.tx = pt.x
                j.ty = pt.y
                j.x = Double(Edge.allCases.firstIndex(of: e) ?? 0)
                j.stage = 2
                j.clock = 0
            }
        case 2:
            guard j.held >= 0, prop(j.held)?.motion == .carried else { return true }
            j.gesture = .carry
            if walkTo(&b, j.tx, j.ty, pace: paceOf(b, tr) * 1.3, tr: tr, h: h, within: b.size * 0.4) || j.clock > 20 {
                j.stage = 3
                j.clock = 0
            }
        default:
            holdStill(&b, tr: tr, h: h)
            j.gesture = .build
            if j.clock >= 0.3, j.held >= 0, let k = propIndex(j.held) {
                var q = stage.yard.bodies[k]
                let e = Edge.allCases[min(Edge.allCases.count - 1, max(0, Int(j.x)))]
                let out = point(on: e, along: along(q.x, q.y, on: e), depth: -q.size * 1.6)
                q.motion = .flying
                q.holder = -1
                q.fromX = q.x
                q.fromY = q.y
                q.toX = out.x
                q.toY = out.y
                q.clock = 0
                q.length = 0.45
                q.hump = 14
                q.landing = .vanish
                stage.yard.bodies[k] = q
                j.held = -1
            }
            if j.clock >= 0.8 { return true }
        }
        return false
    }
}
