import Foundation

public enum GameKind: String, CaseIterable, Codable, Sendable {
    case ball
    case tug
    case snowballs
    case hideAndSeek = "hideandseek"
}

public enum GamePhase: String, CaseIterable, Codable, Sendable {
    case gather
    case play
    case end
}

struct Game {
    var id: Int
    var kind: GameKind
    var members: [Int]
    var phase = GamePhase.gather
    var clock = 0.0
    var total = 0.0
    var length = 30.0
    var x: Double
    var y: Double
    var unit: Double
    var prop = -1
    var kicks = 0
    var kicksMax = 12
    var next = -1
    var last = -1
    var shift = 0.0
    var shiftV = 0.0
    var force = [1.0, 1.0]
    var forceClock = 0.0
    var winner = 0.0
    var seeker = -1
    var found: [Int] = []
    var hits = 0
    var endClock = 0.0
    var quiet = false
    var shallow = 0.0
    var ready = false
}

public struct GameSnapshot: Sendable, Equatable {
    public var kind: GameKind
    public var phase: GamePhase
    public var members: Int
    public var kicks: Int
    public var hits: Int
    public var found: Int
    public var winner: Double
    public var x: Double
    public var y: Double
}

extension World {
    public var games: [GameSnapshot] {
        stage.work.games.map { g in
            GameSnapshot(kind: g.kind, phase: g.phase, members: g.members.count, kicks: g.kicks, hits: g.hits, found: g.found.count, winner: g.winner, x: g.x, y: g.y)
        }
    }

    func gameIndex(_ id: Int) -> Int? {
        guard id >= 0 else { return nil }
        return stage.work.games.firstIndex { $0.id == id }
    }

    func minMembers(_ k: GameKind) -> Int {
        switch k {
        case .ball: return 2
        case .tug: return 4
        case .snowballs: return 2
        case .hideAndSeek: return 2
        }
    }

    func playable(_ b: Bug, _ k: GameKind) -> Bool {
        switch k {
        case .ball, .tug, .snowballs: return onFoot(b)
        case .hideAndSeek: return b.species.locomotion != .dart
        }
    }

    func startGame(room: Int) -> Bool {
        let t = tuning
        var pool: [Int] = []
        for i in bugs.indices where bugs[i].mode != .hidden && workFree(bugs[i]) { pool.append(i) }
        guard pool.count >= 2 else { return false }
        var kinds: [GameKind] = t.forceGame.map { [$0] } ?? GameKind.allCases.filter { $0 != .snowballs || config.season == .winter }
        if t.forceGame == nil, kinds.count > 1, let last = stage.work.lastGame { kinds.removeAll { $0 == last } }
        kinds = kinds.filter { k in
            let need = k == .tug ? 4 : (k == .ball || k == .hideAndSeek ? 3 : 4)
            return min(room, pool.filter { playable(bugs[$0], k) }.count) >= need
        }
        guard !kinds.isEmpty else { return false }
        let kind = kinds[pick(kinds.count, workRng.unit())]
        let able = pool.filter { playable(bugs[$0], kind) }
        var want: Int
        switch kind {
        case .ball: want = 3 + (workRng.chance(0.5) ? 1 : 0)
        case .tug: want = able.count >= 10 && room >= 6 && workRng.chance(0.4) ? 6 : 4
        case .snowballs: want = 4 + Int(workRng.unit() * 3)
        case .hideAndSeek: want = 3 + Int(workRng.unit() * 3)
        }
        want = min(want, room, able.count)
        if kind == .tug { want -= want % 2 }
        guard want >= (kind == .tug ? 4 : 3) else { return false }
        let seed = able[pick(able.count, workRng.unit())]
        let sx = bugs[seed].x, sy = bugs[seed].y
        let sorted = able.sorted { a, b in
            let da = hypot(bugs[a].x - sx, bugs[a].y - sy), db = hypot(bugs[b].x - sx, bugs[b].y - sy)
            return da != db ? da < db : bugs[a].id < bugs[b].id
        }
        var crew = Array(sorted.prefix(want))
        if kind == .hideAndSeek, let k = crew.firstIndex(where: { onFoot(bugs[$0]) }), k > 0 { crew.swapAt(0, k) }
        var cx = 0.0, cy = 0.0, unit = 0.0
        for i in crew {
            cx += bugs[i].x
            cy += bugs[i].y
            unit += bugs[i].size
        }
        let n = Double(crew.count)
        unit = min(40, max(18, unit / n))
        let reach: Double = kind == .tug ? unit * 2.2 + unit * 1.3 * Double(crew.count / 2) + 40 : (kind == .snowballs ? unit * 6.5 + 40 : 240)
        let mx = min(width / 2, max(reach, width * 0.18))
        var x = min(max(cx / n, mx), max(mx, width - mx))
        let y = min(max(cy / n, max(unit * 2, height * 0.22)), max(unit * 2, height * 0.5))
        for p in stage.work.projects where p.phase != .finished && abs(p.x - x) < reach + 200 {
            let alt = width - x
            if abs(p.x - alt) > abs(p.x - x) { x = min(max(alt, mx), max(mx, width - mx)) }
        }
        stage.work.serial += 1
        var g = Game(id: stage.work.serial, kind: kind, members: [], x: x, y: y, unit: unit)
        switch kind {
        case .ball:
            g.length = workRng.range(t.ballLength)
            g.kicksMax = Int(workRng.range(Double(t.ballKicks.lowerBound)...Double(max(t.ballKicks.lowerBound, t.ballKicks.upperBound)) + 0.999))
        case .tug:
            g.length = workRng.range(t.tugLength)
        case .snowballs:
            g.length = workRng.range(t.fightLength)
        case .hideAndSeek:
            g.length = t.hideLength + t.hideCount.upperBound + 20
        }
        for (r, i) in crew.enumerated() {
            var j = Job(family: .play)
            j.group = g.id
            j.role = r
            j.sign = kind == .tug || kind == .snowballs ? (r % 2 == 0 ? -1 : 1) : 1
            bugs[i].job = j
            bugs[i].restGesture = .none
            g.members.append(bugs[i].id)
        }
        if kind == .hideAndSeek { g.seeker = g.members[0] }
        if kind == .tug { makeRope(&g) }
        stage.census.workers += crew.count
        stage.census.players += crew.count
        stage.work.games.append(g)
        stage.work.lastGame = kind
        stage.work.gameGap = workRng.range(t.gameCooldown)
        return true
    }

    func tugSpot(_ g: Game, _ j: Job, _ b: Bug) -> (x: Double, y: Double) {
        let k = Double(j.role / 2)
        let x = g.x + g.shift + j.sign * (g.unit * 2.2 + k * g.unit * 1.3)
        return (x, g.y + b.size * 0.5)
    }

    func tugAnchor(_ g: Game, sign: Double) -> Int {
        var best = -1
        var role = -1
        for id in g.members {
            if let i = index(of: id), let j = bugs[i].job, j.sign == sign, j.role > role {
                role = j.role
                best = id
            }
        }
        return best
    }

    func makeRope(_ g: inout Game) {
        let half = g.unit * 2.2 + g.unit * 1.3 * Double(max(0, g.members.count / 2 - 1)) + g.unit * 0.3
        let gy = g.y + 3
        let id = addProp(.rope, x: g.x - half, y: gy, size: g.unit, progress: 0, layer: 1)
        editProp(id) { q in
            q.hasEnd = true
            q.endX = g.x + half
            q.endY = gy
            q.fromY = gy
            q.game = g.id
            q.fadeIn = 1.5
        }
        g.prop = id
    }

    func runGames(_ h: Double) {
        guard !stage.work.games.isEmpty else { return }
        let t = tuning
        var k = stage.work.games.count - 1
        while k >= 0 {
            var g = stage.work.games[k]
            g.clock += h
            g.total += h
            let gid = g.id
            g.members.removeAll { id in
                guard let i = index(of: id), bugs[i].mode != .hidden, let j = bugs[i].job else { return true }
                return j.family != .play || j.group != gid
            }
            if g.phase != .end {
                let bad = max(light, targetLight) > t.duskLight || isJiggling || !t.workEnabled || !t.gamesEnabled
                g.shallow = lidAngle > t.deepAngle + 6 ? g.shallow + h : 0
                if bad || g.shallow > 4 || g.members.count < minMembers(g.kind) || g.total > g.length + 40 {
                    endGame(&g, quiet: bad || g.members.count < minMembers(g.kind))
                } else {
                    switch g.kind {
                    case .ball:
                        if prop(g.prop) == nil && g.phase == .play { endGame(&g, quiet: true) }
                        if g.phase == .gather && g.total > 25 { endGame(&g, quiet: true) }
                        if g.phase == .play && (g.kicks >= g.kicksMax || g.total > g.length) { endGame(&g, quiet: false) }
                    case .tug:
                        runTug(&g, h)
                    case .snowballs:
                        if g.phase == .gather && g.clock > 1 {
                            g.phase = .play
                            g.clock = 0
                        }
                        if g.total > g.length { endGame(&g, quiet: false) }
                    case .hideAndSeek:
                        let hiders = g.members.filter { $0 != g.seeker }
                        if g.seeker >= 0 && !g.members.contains(g.seeker) {
                            endGame(&g, quiet: true)
                        } else if g.phase == .play && (hiders.allSatisfy { g.found.contains($0) } || g.clock > t.hideLength) {
                            g.winner = hiders.allSatisfy { g.found.contains($0) } ? -1 : 1
                            endGame(&g, quiet: false)
                        }
                    }
                }
            } else {
                g.endClock += h
            }
            if g.phase == .end && (g.members.isEmpty || g.endClock > 6) {
                for id in g.members {
                    if let i = index(of: id) { release(i) }
                }
                stage.work.games.remove(at: k)
            } else {
                stage.work.games[k] = g
            }
            k -= 1
        }
    }

    func runTug(_ g: inout Game, _ h: Double) {
        let t = tuning
        switch g.phase {
        case .gather:
            var ready = true
            for id in g.members {
                if let i = index(of: id), let j = bugs[i].job, j.stage < 1 { ready = false }
            }
            if ready || g.clock > 14 {
                let a = tugAnchor(g, sign: -1), c = tugAnchor(g, sign: 1)
                guard let ai = index(of: a), let ci = index(of: c), let k = propIndex(g.prop) else {
                    endGame(&g, quiet: true)
                    return
                }
                bugs[ai].job?.held = g.prop
                bugs[ci].job?.held = g.prop
                stage.yard.bodies[k].motion = .rope
                stage.yard.bodies[k].holder = a
                stage.yard.bodies[k].partner = c
                g.phase = .play
                g.clock = 0
            }
        case .play:
            guard let q = prop(g.prop), q.motion == .rope else {
                endGame(&g, quiet: true)
                return
            }
            guard g.clock > 1 else { return }
            g.forceClock -= h
            if g.forceClock <= 0 {
                g.forceClock = workRng.range(0.6...1.2)
                var f = [0.0, 0.0]
                for id in g.members {
                    if let i = index(of: id), let j = bugs[i].job {
                        f[j.sign < 0 ? 0 : 1] += bugs[i].size * workRng.range(0.6...1.4)
                    }
                }
                g.force = f
            }
            let total = max(1, g.force[0] + g.force[1])
            let want = (g.force[1] - g.force[0]) / total * 45
            approach(&g.shiftV, want, rate: 60, h: h)
            g.shift += g.shiftV * h
            if abs(g.shift) > g.unit * 1.8 || g.clock > g.length {
                g.winner = g.shift == 0 ? (workRng.chance(0.5) ? 1 : -1) : (g.shift > 0 ? 1 : -1)
                endGame(&g, quiet: false)
            }
            _ = t
        case .end:
            break
        }
    }

    func endGame(_ g: inout Game, quiet: Bool) {
        g.phase = .end
        g.endClock = 0
        g.quiet = quiet
        for k in stage.yard.bodies.indices where stage.yard.bodies[k].game == g.id {
            var q = stage.yard.bodies[k]
            q.game = -1
            switch q.kind {
            case .rope:
                q.motion = .rest
                q.holder = -1
                q.partner = -1
                q.doomed = true
                q.doomRate = 0.35
            case .ball:
                if q.motion == .carried { break }
                q.doomed = true
                q.doomRate = 0.45
            default:
                q.life = 6
            }
            stage.yard.bodies[k] = q
        }
        for id in g.members {
            if let i = index(of: id), var j = bugs[i].job {
                j.held = j.held >= 0 && prop(j.held)?.kind == .rope ? -1 : j.held
                j.clock = 0
                bugs[i].job = j
            }
        }
    }

    func playStep(_ b: inout Bug, _ j: inout Job, tr: SpeciesTraits, h: Double) -> Bool {
        guard let gi = gameIndex(j.group) else { return true }
        let g = stage.work.games[gi]
        if g.phase == .end { return endStep(&b, &j, gi, tr: tr, h: h) }
        switch g.kind {
        case .ball: return ballStep(&b, &j, gi, tr: tr, h: h)
        case .tug: return tugStep(&b, &j, gi, tr: tr, h: h)
        case .snowballs: return fightStep(&b, &j, gi, tr: tr, h: h)
        case .hideAndSeek: return hideStep(&b, &j, gi, tr: tr, h: h)
        }
    }

    func endStep(_ b: inout Bug, _ j: inout Job, _ gi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        let g = stage.work.games[gi]
        if g.quiet { return true }
        if b.mode == .emerging {
            let inside = spot(x: b.x, y: b.y, pad: b.size)
            _ = seek(&b, x: inside.x, y: inside.y, pace: paceOf(b, tr), tr: tr, h: h, arrive: 3)
            if hypot(inside.x - b.x, inside.y - b.y) < 4 { b.mode = .resting } else { b.mode = .emerging }
        }
        switch g.kind {
        case .tug:
            let won = j.sign == g.winner
            if !won && g.endClock < 1.2 {
                j.gesture = .tumble
                if g.endClock < 0.35 {
                    b.course = j.sign < 0 ? 0 : .pi
                    approach(&b.speed, 50, rate: 300, h: h)
                    workMove(&b)
                } else {
                    brake(&b, tau: 0.08, h: h)
                    b.mode = .resting
                }
            } else {
                b.backward = false
                holdStill(&b, tr: tr, h: h)
                j.gesture = won ? .cheer : (g.endClock < 2 ? .look : .wave)
                if won && b.facingHold <= 0 {
                    b.facing = -b.facing
                    b.facingHold = 0.6
                }
            }
            return g.endClock > 3.2 + Double(j.role) * 0.15
        case .ball:
            if b.mode != .emerging { holdStill(&b, tr: tr, h: h) }
            j.gesture = b.id == g.last ? .cheer : .wave
            return g.endClock > 1.8 + Double(j.role) * 0.2
        case .snowballs:
            if b.mode != .emerging { holdStill(&b, tr: tr, h: h) }
            if j.alarm > 0 {
                j.gesture = j.aloft ? .tumble : .shiver
                return false
            }
            j.gesture = j.role % 2 == 0 ? .cheer : .wave
            return g.endClock > 2 + Double(j.role) * 0.2
        case .hideAndSeek:
            if b.mode != .emerging {
                let s = spot(x: g.x + Double(j.role % 2 == 0 ? 1 : -1) * Double(j.role) * g.unit * 0.9, y: g.y + b.size * 0.5, pad: b.size)
                if hypot(s.x - b.x, s.y - b.y) > 30 && g.endClock < 2 {
                    walkTo(&b, s.x, s.y, pace: paceOf(b, tr), tr: tr, h: h)
                } else {
                    holdStill(&b, tr: tr, h: h)
                }
            }
            let seekerWon = g.winner < 0
            j.gesture = (b.id == g.seeker) == seekerWon ? .cheer : .look
            return g.endClock > 2.8 + Double(j.role) * 0.2
        }
    }

    func ringPoint(_ g: Game, _ role: Int, _ b: Bug) -> (x: Double, y: Double) {
        let n = max(2, g.members.count)
        let a = Double(role) / Double(n) * 2 * .pi + 0.4
        let rx = min(230, max(140, g.unit * 5.5))
        return spot(x: g.x + cos(a) * rx, y: g.y + sin(a) * rx * 0.42 + b.size * 0.5, pad: b.size * 1.2)
    }

    func ballStep(_ b: inout Bug, _ j: inout Job, _ gi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        let t = tuning
        var g = stage.work.games[gi]
        let home = ringPoint(g, j.role, b)
        if j.alarm > 0 {
            holdStill(&b, tr: tr, h: h)
            j.gesture = .tumble
            return false
        }
        if g.phase == .gather {
            if j.role != 0 {
                if walkTo(&b, home.x, home.y, pace: paceOf(b, tr), tr: tr, h: h) {
                    holdStill(&b, tr: tr, h: h)
                    turnTo(&b, x: g.x)
                }
                j.gesture = .none
                return false
            }
            switch j.stage {
            case 0:
                let e = nearestSide(b.x, b.y)
                j.x = Double(Edge.allCases.firstIndex(of: e) ?? 0)
                let p = supplyPoint(e, along: along(b.x, b.y, on: e), depth: b.size * 0.8)
                j.tx = p.x
                j.ty = p.y
                j.stage = 1
                j.clock = 0
            case 1:
                j.gesture = .none
                if walkTo(&b, j.tx, j.ty, pace: paceOf(b, tr), tr: tr, h: h) || j.clock > 15 {
                    let e = Edge.allCases[min(3, max(0, Int(j.x)))]
                    g.prop = slideItem(.ball, size: itemSize(.ball, unit: g.unit), toward: b, edge: e)
                    editProp(g.prop) { $0.game = g.id }
                    stage.work.games[gi] = g
                    j.stage = 2
                    j.clock = 0
                }
            case 2:
                holdStill(&b, tr: tr, h: h)
                j.gesture = .pull
                guard let q = prop(g.prop) else { return true }
                turnTo(&b, x: q.x)
                if q.motion == .rest {
                    j.stage = 3
                    j.clock = 0
                }
            default:
                guard let q = prop(g.prop) else { return true }
                j.gesture = .none
                let dir = atan2(g.y - q.y, g.x - q.x)
                let r = q.size * 0.5
                let kx = q.x - cos(dir) * (r + b.size * 0.4), ky = q.y - r - sin(dir) * (r + b.size * 0.4) * 0.6 + b.size * 0.5
                if walkTo(&b, kx, ky, pace: paceOf(b, tr), tr: tr, h: h) || j.clock > 6 {
                    kickBall(&g, by: &b, &j, toward: (g.x, g.y))
                    if g.members.count > 1 {
                        g.next = g.members[1 % g.members.count]
                    }
                    g.phase = .play
                    g.clock = 0
                    stage.work.games[gi] = g
                }
            }
            return false
        }
        guard let q = prop(g.prop) else { return true }
        let speed = hypot(q.vx, q.vy)
        if j.y > 0 {
            j.y -= h
            j.gesture = .kick
            holdStill(&b, tr: tr, h: h)
            return false
        }
        if b.id == g.next && (q.motion == .rest || q.motion == .rolling) && speed < 220 {
            if j.mate < 0 || !g.members.contains(j.mate) || j.mate == b.id {
                let others = g.members.filter { $0 != b.id && $0 != g.last }
                let pool = others.isEmpty ? g.members.filter { $0 != b.id } : others
                guard !pool.isEmpty else { return false }
                j.mate = pool[pick(pool.count, workRng.unit())]
            }
            guard let ti = index(of: j.mate) else {
                j.mate = -1
                return false
            }
            let tx = bugs[ti].x, ty = bugs[ti].y - bugs[ti].size * 0.5
            let r = q.size * 0.5
            let dir = atan2(ty - (q.y - r), tx - q.x)
            let kx = q.x - cos(dir) * (r + b.size * 0.42)
            let ky = q.y - r - sin(dir) * (r + b.size * 0.42) * 0.6 + b.size * 0.5
            j.gesture = .none
            let reach = walkTo(&b, kx, ky, pace: paceOf(b, tr) * 1.25, tr: tr, h: h, within: max(8, b.size * 0.35))
            if reach || (j.clock > 10 && hypot(q.x - b.x, q.y - b.y) < b.size + q.size) {
                if workRng.chance(t.missChance) && onFoot(b) {
                    j.alarm = 0.8
                    if let k = propIndex(q.id) {
                        stage.yard.bodies[k].motion = .rolling
                        stage.yard.bodies[k].vx += workRng.signed() * 40
                        stage.yard.bodies[k].vy += workRng.signed() * 20
                    }
                    j.clock = 0
                } else {
                    kickBall(&g, by: &b, &j, toward: (tx, ty))
                    g.next = j.mate
                    j.mate = -1
                    stage.work.games[gi] = g
                }
            }
            return false
        }
        if b.id != g.next { j.mate = -1 }
        if walkTo(&b, home.x, home.y, pace: paceOf(b, tr) * 0.8, tr: tr, h: h) {
            holdStill(&b, tr: tr, h: h)
        }
        turnTo(&b, x: q.x)
        j.gesture = speed > 40 ? .look : .none
        j.clock = 0
        return false
    }

    func kickBall(_ g: inout Game, by b: inout Bug, _ j: inout Job, toward target: (Double, Double)) {
        guard let k = propIndex(g.prop) else { return }
        var q = stage.yard.bodies[k]
        let r = q.size * 0.5
        let dx = target.0 - q.x, dy = target.1 - (q.y - r)
        let d = max(1, hypot(dx, dy))
        let tau = max(0.05, tuning.ballFriction)
        let v = min(560, max(120, d / tau * 1.02))
        q.motion = .rolling
        q.claim = -1
        q.vx = dx / d * v
        q.vy = dy / d * v
        q.vz = 120
        q.z = max(q.z, 0.5)
        stage.yard.bodies[k] = q
        g.kicks += 1
        g.last = b.id
        j.y = 0.45
        j.gesture = .kick
        turnTo(&b, x: target.0)
    }

    func tugStep(_ b: inout Bug, _ j: inout Job, _ gi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        let g = stage.work.games[gi]
        let s = tugSpot(g, j, b)
        if g.phase == .gather {
            j.gesture = .none
            if j.stage == 0 {
                if walkTo(&b, s.x, s.y, pace: paceOf(b, tr), tr: tr, h: h) || j.clock > 14 { j.stage = 1 }
            } else {
                stayAt(&b, s.x, s.y, tr: tr, h: h)
                turnTo(&b, x: g.x)
                j.gesture = .look
            }
            return false
        }
        let dx = s.x - b.x
        if abs(dx) > 1.5 || abs(s.y - b.y) > 3 {
            _ = seek(&b, x: s.x, y: s.y, pace: max(12, abs(g.shiftV) * 1.4 + 10), tr: tr, h: h, arrive: 1)
            workMove(&b)
        } else {
            settleStill(&b, tr: tr, h: h)
            b.mode = .resting
        }
        let facingIn: Double = j.sign < 0 ? 1 : -1
        b.facing = facingIn
        b.facingHold = 0.3
        b.backward = dx * facingIn < -0.5
        j.gesture = g.clock < 1 ? .look : .pull
        return false
    }

    func fightStep(_ b: inout Bug, _ j: inout Job, _ gi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        let g = stage.work.games[gi]
        if j.alarm > 0 {
            holdStill(&b, tr: tr, h: h)
            j.gesture = j.aloft ? .tumble : .shiver
            return false
        }
        switch j.stage {
        case 0:
            if j.tx == 0 && j.ty == 0 {
                let k = Double(j.role / 2)
                let x = g.x + j.sign * (g.unit * 5 + workRng.range(0...g.unit * 1.5))
                let y = g.y + (k - 1) * 70 + workRng.signed() * 15
                let s = spot(x: x, y: y + b.size * 0.5, pad: b.size * 1.2)
                j.tx = s.x
                j.ty = s.y
            }
            j.gesture = .none
            if walkTo(&b, j.tx, j.ty, pace: paceOf(b, tr), tr: tr, h: h) || j.clock > 12 {
                j.stage = 1
                j.clock = 0
                j.length = workRng.range(0.6...1.6)
            }
        case 1:
            holdStill(&b, tr: tr, h: h)
            j.gesture = .build
            turnTo(&b, x: g.x)
            if g.phase == .play && j.clock >= j.length {
                let size = itemSize(.snowball, unit: g.unit) * 0.85
                let c = carryPoint(b, size: size)
                let id = addProp(.snowball, x: c.x, y: c.y, size: size, motion: .carried)
                editProp(id) { q in
                    q.holder = b.id
                    q.fade = 1
                    q.game = g.id
                }
                j.held = id
                let foes = g.members.filter { m in
                    guard let i = index(of: m), let o = bugs[i].job else { return false }
                    return o.sign != j.sign
                }
                j.mate = foes.isEmpty ? -1 : foes[pick(foes.count, workRng.unit())]
                j.stage = 2
                j.clock = 0
            }
        case 2:
            holdStill(&b, tr: tr, h: h)
            guard j.held >= 0, prop(j.held)?.motion == .carried else {
                j.held = -1
                j.stage = 1
                j.clock = 0
                return false
            }
            guard let ti = index(of: j.mate), bugs[ti].mode != .hidden else {
                j.stage = 1
                j.clock = 0
                return false
            }
            turnTo(&b, x: bugs[ti].x)
            j.gesture = .carry
            if j.clock >= 0.45, let k = propIndex(j.held) {
                let target = bugs[ti]
                var q = stage.yard.bodies[k]
                let ex = target.x + workRng.signed() * target.size * 0.7
                let ey = target.y + workRng.signed() * target.size * 0.4
                let d = hypot(ex - q.x, ey - q.y)
                q.motion = .flying
                q.holder = -1
                q.fromX = q.x
                q.fromY = q.y
                q.toX = ex
                q.toY = ey
                q.clock = 0
                q.length = min(1.1, max(0.45, d / 480))
                q.hump = 30 + d * 0.12
                q.spin = workRng.signed() * 6
                q.landing = .splat
                q.thrower = b.id
                q.target = target.id
                q.game = g.id
                stage.yard.bodies[k] = q
                j.held = -1
                j.stage = 3
                j.clock = 0
                j.length = workRng.range(1.0...2.2)
                j.x = workRng.signed() * 30
            }
        default:
            j.gesture = .none
            if j.clock < 0.5 {
                holdStill(&b, tr: tr, h: h)
            } else {
                stayAt(&b, j.tx, j.ty + j.x, tr: tr, h: h)
            }
            turnTo(&b, x: g.x)
            if j.clock >= j.length {
                j.stage = 1
                j.clock = 0
                j.length = workRng.range(0.6...1.4)
            }
        }
        return false
    }

    func snowballLanded(_ id: Int) {
        guard let q = prop(id) else { return }
        if let i = index(of: q.target), bugs[i].mode != .hidden {
            let b = bugs[i]
            if hypot(b.x - q.x, b.y - q.y) < b.size * 0.6 + q.size * 0.5 + 6, var j = b.job, j.family == .play, j.group == q.game {
                j.alarm = 1.1
                j.aloft = workRng.chance(0.3)
                bugs[i].job = j
                if let gi = gameIndex(q.game) { stage.work.games[gi].hits += 1 }
            }
        }
        editProp(id) { r in
            r.progress = 0
            r.motion = .rest
            r.spin = 0
            r.rotation = 0
            r.game = -1
            r.doomed = true
            r.doomRate = 1.2
            r.fade = min(r.fade, 1)
        }
    }

    func hideSpot(_ g: Game, _ b: Bug, _ j: Job) -> (x: Double, y: Double, inX: Double, inY: Double, ledge: Bool) {
        var used: [(Double, Double)] = []
        for id in g.members where id != b.id {
            if let i = index(of: id), let o = bugs[i].job, o.stage >= 1 { used.append((o.tx, o.ty)) }
        }
        if !surroundings.ledges.isEmpty && workRng.chance(0.5) {
            for _ in 0..<4 {
                let r = surroundings.ledges[pick(surroundings.ledges.count, workRng.unit())]
                let top = Double(r.maxY), lo = Double(r.minX) + b.size, hi = Double(r.maxX) - b.size
                guard top.isFinite, lo.isFinite, hi.isFinite, hi > lo, top > b.size * 2, top < height - b.size else { continue }
                let x = workRng.range(lo...hi)
                let y = top - b.size * 0.22
                if used.contains(where: { hypot($0.0 - x, $0.1 - y) < b.size * 2 }) { continue }
                return (x, y, x, y - b.size * 0.4, true)
            }
        }
        var edges: [Edge] = [.left, .right, .bottom]
        edges.sort { depth(b.x, b.y, from: $0) < depth(b.x, b.y, from: $1) }
        let e = workRng.chance(0.7) ? edges[0] : edges[1]
        for _ in 0..<4 {
            let a = along(b.x, b.y, on: e) + workRng.signed() * 220
            let out = supplyPoint(e, along: a, depth: b.size * 0.22)
            if used.contains(where: { hypot($0.0 - out.x, $0.1 - out.y) < b.size * 2 }) { continue }
            let inner = supplyPoint(e, along: a, depth: b.size * 0.9)
            return (out.x, out.y, inner.x, inner.y, false)
        }
        let out = supplyPoint(e, along: along(b.x, b.y, on: e), depth: b.size * 0.22)
        let inner = supplyPoint(e, along: along(b.x, b.y, on: e), depth: b.size * 0.9)
        return (out.x, out.y, inner.x, inner.y, false)
    }

    func hideStep(_ b: inout Bug, _ j: inout Job, _ gi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        let t = tuning
        var g = stage.work.games[gi]
        if b.id == g.seeker {
            if g.phase == .gather {
                if j.stage == 0 {
                    j.gesture = .none
                    if walkTo(&b, g.x, g.y + b.size * 0.5, pace: paceOf(b, tr), tr: tr, h: h) || j.clock > 10 {
                        j.stage = 1
                        j.clock = 0
                        j.length = workRng.range(t.hideCount)
                    }
                    return false
                }
                holdStill(&b, tr: tr, h: h)
                j.gesture = .count
                if j.clock >= j.length {
                    g.phase = .play
                    g.clock = 0
                    stage.work.games[gi] = g
                    j.stage = 2
                    j.clock = 0
                    j.mate = -1
                }
                return false
            }
            var best = -1
            var bestD = Double.infinity
            for id in g.members where id != b.id && !g.found.contains(id) {
                if let i = index(of: id) {
                    let d = hypot(bugs[i].x - b.x, bugs[i].y - b.y)
                    if d < bestD {
                        bestD = d
                        best = i
                    }
                }
            }
            guard best >= 0 else {
                holdStill(&b, tr: tr, h: h)
                j.gesture = .look
                return false
            }
            let hid = bugs[best]
            let pause = j.clock.truncatingRemainder(dividingBy: 4.2) > 3.5
            if j.stage == 3 {
                holdStill(&b, tr: tr, h: h)
                j.gesture = .cheer
                if j.clock > 0.7 {
                    j.stage = 2
                    j.clock = 0
                }
                return false
            }
            if pause && bestD > 120 {
                holdStill(&b, tr: tr, h: h)
                j.gesture = .look
                if b.facingHold <= 0 {
                    b.facing = -b.facing
                    b.facingHold = 0.5
                }
                return false
            }
            j.gesture = .none
            let tx = min(max(hid.x, b.size), width - b.size), ty = min(max(hid.y, b.size * 0.6), height - b.size)
            walkTo(&b, tx, ty, pace: paceOf(b, tr) * 1.05, tr: tr, h: h)
            if bestD < (b.size + hid.size) * 0.6 + 34 {
                g.found.append(hid.id)
                stage.work.games[gi] = g
                j.stage = 3
                j.clock = 0
                turnTo(&b, x: hid.x)
            }
            return false
        }
        if g.found.contains(b.id) {
            if b.mode == .emerging || j.stage == 3 {
                let inside = spot(x: j.x, y: j.y, pad: b.size)
                _ = seek(&b, x: inside.x, y: inside.y, pace: paceOf(b, tr), tr: tr, h: h, arrive: 2)
                b.mode = hypot(inside.x - b.x, inside.y - b.y) < 4 ? .resting : .emerging
                j.gesture = .popUp
                if b.mode == .resting {
                    j.stage = 4
                    j.clock = 0
                }
                return false
            }
            if j.stage < 4 {
                j.stage = 4
                j.clock = 0
            }
            let n = g.found.firstIndex(of: b.id) ?? 0
            let s = spot(x: g.x + Double(n % 2 == 0 ? -1 : 1) * Double(n / 2 + 1) * g.unit * 1.1, y: g.y + b.size * 0.5, pad: b.size)
            if j.clock < 0.9 {
                holdStill(&b, tr: tr, h: h)
                j.gesture = .wave
            } else if walkTo(&b, s.x, s.y, pace: paceOf(b, tr) * 0.8, tr: tr, h: h) {
                holdStill(&b, tr: tr, h: h)
                if let si = index(of: g.seeker) { turnTo(&b, x: bugs[si].x) }
                j.gesture = .look
            } else {
                j.gesture = .none
            }
            return false
        }
        switch j.stage {
        case 0:
            let s = hideSpot(g, b, j)
            j.tx = s.x
            j.ty = s.y
            j.x = s.inX
            j.y = s.inY
            j.aloft = s.ledge
            j.stage = 1
            j.clock = 0
        case 1:
            j.gesture = .tiptoe
            if walkTo(&b, j.x, j.y, pace: paceOf(b, tr) * 0.95, tr: tr, h: h) || j.clock > 14 {
                j.stage = 2
                j.clock = 0
            }
        default:
            let away = hypot(j.tx - b.x, j.ty - b.y)
            if away > 30 {
                if j.clock > 8 {
                    j.stage = 0
                    j.clock = 0
                    return false
                }
                _ = seek(&b, x: j.tx, y: j.ty, pace: max(15, paceOf(b, tr) * 0.6), tr: tr, h: h, arrive: 1)
            } else {
                let k = min(1, h / 0.35)
                b.x += (j.tx - b.x) * k
                b.y += (j.ty - b.y) * k
                b.speed = 0
                b.lift = 0
            }
            b.mode = j.aloft ? .resting : .emerging
            j.stage = 3
            let settled = away < 8
            let peek = Int(j.total / 1.7 + Double(j.role)) % 3 == 0
            j.gesture = settled && (j.aloft || (g.phase == .play && peek)) ? .peek : .none
        }
        return false
    }
}
