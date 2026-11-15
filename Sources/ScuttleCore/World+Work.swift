import Foundation

public enum WorkKind: String, CaseIterable, Codable, Sendable {
    case errand
    case haul
    case build
    case celebrate
    case gather
    case supervise
    case play
    case inspect
    case steal
}

enum JobFamily: Equatable {
    case errand
    case crew
    case play
    case visit
    case thief
}

enum CrewTask: Equatable {
    case idle
    case wait
    case fetch
    case roll
    case lift
    case work
    case supervise
}

struct Job {
    var family: JobFamily
    var group = -1
    var role = 0
    var task = CrewTask.idle
    var errand = ErrandKind.deliver
    var stage = 0
    var clock = 0.0
    var total = 0.0
    var length = 0.0
    var held = -1
    var pushing = -1
    var target = -1
    var mate = -1
    var lead = true
    var x = 0.0
    var y = 0.0
    var tx = 0.0
    var ty = 0.0
    var gesture = Gesture.none
    var sign = 1.0
    var count = 0
    var trips = 0
    var tripsMax = 4
    var pace = 0.0
    var aloft = false
    var edgeOnly = false
    var slot = -1
    var tripAt = -1.0
    var span = 0.0
    var alarm = 0.0
    var alarmX = 0.0
    var heavy = false
    var spots: [Int] = []
}

struct WorkStage {
    var clock = 2.0
    var serial = 0
    var projects: [Project] = []
    var games: [Game] = []
    var memory: BuildMemory?
    var errandGap = 0.0
    var projectGap = 0.0
    var gameGap = 0.0
    var stealGap = 0.0
    var inspectGap = 0.0
    var lastProject: ProjectKind?
    var lastGame: GameKind?
}

extension World {
    public var workCounts: [WorkKind: Int] {
        var out: [WorkKind: Int] = [:]
        for b in bugs where b.mode != .hidden {
            if let j = b.job { out[workKind(j), default: 0] += 1 }
        }
        return out
    }

    public var workerCount: Int {
        var n = 0
        for b in bugs where b.mode != .hidden && b.job != nil { n += 1 }
        return n
    }

    func workKind(_ j: Job) -> WorkKind {
        switch j.family {
        case .errand: return .errand
        case .play: return .play
        case .visit: return .inspect
        case .thief: return .steal
        case .crew:
            if let p = projectIndex(j.group) {
                switch stage.work.projects[p].phase {
                case .celebrating: return .celebrate
                case .using: return .gather
                default: break
                }
            }
            switch j.task {
            case .fetch, .roll, .lift: return .haul
            case .supervise: return .supervise
            case .idle, .wait, .work: return .build
            }
        }
    }

    func workCap() -> Int {
        let t = tuning
        let v = stage.visible
        if v <= 3 { return min(1, max(0, t.workMax)) }
        return min(max(0, t.workMax), max(2, Int(Double(v) * max(0, t.workShare))))
    }

    func siteLimit() -> Int {
        stage.visible >= 120 ? 2 : 1
    }

    func tendWork(_ h: Double) {
        let t = tuning
        stage.work.clock -= h
        stage.work.errandGap -= h
        stage.work.projectGap -= h
        stage.work.gameGap -= h
        stage.work.stealGap -= h
        stage.work.inspectGap -= h
        runProjects(h)
        runGames(h)
        considerMemory()
        guard t.workEnabled else { return }
        guard stage.work.clock <= 0 else { return }
        stage.work.clock = workRng.range(t.workTick)
        guard stage.visible >= 1, !isJiggling, isDarkNow, targetLight < t.nerveRange.upperBound, darkSeconds >= t.errandAfter else { return }
        let forced = t.forceErrand != nil || t.forceProject != nil || t.forceGame != nil
        guard forced || workRng.chance(t.workChance) else { return }
        let dusk = max(light, targetLight) > t.duskLight
        let deep = lidAngle < t.deepAngle
        let room = workCap() - stage.census.workers
        var options: [(Int, Double)] = []
        if !dusk {
            if t.projectsEnabled && (t.forceGame == nil && t.forceErrand == nil || t.forceProject != nil) && projectOpen(room: room) {
                options.append((1, t.forceProject != nil ? 50 : 1.4))
            }
            if t.gamesEnabled && deep && (t.forceProject == nil && t.forceErrand == nil || t.forceGame != nil) && gameOpen(room: room) {
                options.append((2, t.forceGame != nil ? 50 : 1.0))
            }
            let open = t.forceErrand == nil && t.forceGame == nil
            if open && inspectOpen() { options.append((3, 2.5)) }
            if open && stealOpen(room: room) { options.append((4, t.forceProject != nil ? 5 : 0.5)) }
        }
        if t.errandsEnabled && (t.forceProject == nil && t.forceGame == nil || t.forceErrand != nil) && errandOpen(room: room, dusk: dusk) {
            options.append((0, t.forceErrand != nil ? 50 : 1.0))
        }
        var tries = 0
        while !options.isEmpty && tries < 4 {
            tries += 1
            var total = 0.0
            for o in options { total += o.1 }
            guard total > 0 else { return }
            var roll = workRng.unit() * total
            var chosen = options.count - 1
            for (n, o) in options.enumerated() {
                roll -= o.1
                if roll <= 0 {
                    chosen = n
                    break
                }
            }
            let ok: Bool
            switch options[chosen].0 {
            case 0: ok = startErrand(dusk: dusk)
            case 1: ok = startProject(room: room)
            case 2: ok = startGame(room: room)
            case 3: ok = startInspect()
            default: ok = startSteal()
            }
            if ok { return }
            options.remove(at: chosen)
        }
    }

    func errandOpen(room: Int, dusk: Bool) -> Bool {
        let t = tuning
        guard room > 0, t.forceErrand != nil || stage.work.errandGap <= 0 else { return false }
        let cap = dusk ? 1 : max(1, Int(Double(stage.visible) * max(0, t.errandShare)))
        return stage.census.errands < cap
    }

    func projectOpen(room: Int) -> Bool {
        let t = tuning
        guard room >= 2, darkSeconds >= t.projectAfter, stage.visible >= max(2, t.projectMinVisible) else { return false }
        guard t.forceProject != nil || stage.work.projectGap <= 0 else { return false }
        var active = 0
        for p in stage.work.projects where p.phase != .finished { active += 1 }
        return active < siteLimit()
    }

    func gameOpen(room: Int) -> Bool {
        let t = tuning
        guard room >= 2, lid.deepTime >= t.gameAfter, darkSeconds >= t.gameAfter, stage.visible >= max(2, t.gameMinVisible) else { return false }
        guard t.forceGame != nil || stage.work.gameGap <= 0 else { return false }
        return stage.work.games.count < siteLimit()
    }

    func workFree(_ b: Bug) -> Bool {
        b.free && !b.rare && b.mode != .emerging && onScreen(b) && edgeDistance(b.x, b.y) > b.size * 0.8 && time >= b.lureCalm
    }

    func canCarry(_ b: Bug) -> Bool {
        b.species.locomotion != .dart
    }

    func canPush(_ b: Bug) -> Bool {
        b.species.locomotion == .walk || b.species.locomotion == .crawl
    }

    func onFoot(_ b: Bug) -> Bool {
        !b.species.isAirborne
    }

    func fits(_ b: Bug, _ size: Double) -> Bool {
        if b.species.isAirborne { return size <= b.size * 0.8 }
        if b.species.stance == .topDown { return size <= b.size * 1.1 }
        return true
    }

    func workMove(_ b: inout Bug) {
        b.mode = b.speed > 1 || b.lift > 0 ? .wandering : .resting
    }

    func near(_ b: Bug) -> Double {
        b.species.locomotion == .hop ? max(8, b.size * 0.6) : 7
    }

    @discardableResult
    func walkTo(_ b: inout Bug, _ x: Double, _ y: Double, pace: Double, tr: SpeciesTraits, h: Double, within: Double? = nil) -> Bool {
        let tol = within ?? near(b)
        let d = seek(&b, x: x, y: y, pace: pace, tr: tr, h: h, arrive: tol * 0.6)
        workMove(&b)
        return d <= tol && b.lift == 0
    }

    func stayAt(_ b: inout Bug, _ x: Double, _ y: Double, tr: SpeciesTraits, h: Double) {
        let d = hypot(x - b.x, y - b.y)
        if d > (b.species.isAirborne ? 10 : near(b) + 4) {
            _ = seek(&b, x: x, y: y, pace: max(10, paceOf(b, tr) * 0.6), tr: tr, h: h, arrive: 3)
            workMove(&b)
        } else {
            settleStill(&b, tr: tr, h: h)
            b.mode = .resting
        }
    }

    func turnTo(_ b: inout Bug, x: Double) {
        guard abs(x - b.x) > 2 else { return }
        let f: Double = x > b.x ? 1 : -1
        if f != b.facing {
            b.facing = f
            b.facingHold = max(b.facingHold, 0.3)
        }
        b.facingHold = max(b.facingHold, 0.2)
    }

    func spot(x: Double, y: Double, pad: Double) -> (x: Double, y: Double) {
        let px = min(pad, width / 2), py = min(pad, height / 2)
        return (min(max(x, px), width - px), min(max(y, py), height - py))
    }

    func supplyPoint(_ e: Edge, along a: Double, depth d: Double) -> (x: Double, y: Double) {
        let s = span(e)
        let m = min(60, s * 0.2)
        return point(on: e, along: min(max(a, m), s - m), depth: d)
    }

    func nearestSide(_ x: Double, _ y: Double, top: Bool = false) -> Edge {
        var best = Edge.bottom
        var cost = Double.infinity
        for e in Edge.allCases where top || e != .top {
            let c = depth(x, y, from: e)
            if c < cost {
                cost = c
                best = e
            }
        }
        return best
    }

    func jobStep(_ b: inout Bug, tr: SpeciesTraits, h: Double) -> Double {
        guard var j = b.job else { return 0 }
        let t = tuning
        j.clock += h
        j.total += h
        j.alarm -= h
        var done: Bool
        switch j.family {
        case .errand: done = errandStep(&b, &j, tr: tr, h: h)
        case .crew: done = crewStep(&b, &j, tr: tr, h: h)
        case .play: done = playStep(&b, &j, tr: tr, h: h)
        case .visit: done = inspectStep(&b, &j, tr: tr, h: h)
        case .thief: done = thiefStep(&b, &j, tr: tr, h: h)
        }
        if j.total > t.jobMaxSeconds { done = true }
        if done {
            endJob(&b, j, tr: tr)
        } else if b.job != nil {
            b.job = j
        }
        return 0
    }

    func jobGesture(_ b: Bug, _ j: Job) -> Gesture {
        switch j.gesture {
        case .tiptoe, .wave:
            return lid.velocity > 30 ? .look : j.gesture
        case .dance, .cheer, .sleep:
            if b.mode != .resting { return .none }
            if !b.species.isAirborne && b.speed >= 1 { return .none }
            if mood != .deep { return j.gesture == .sleep ? .none : (lid.velocity > 30 ? .look : .wave) }
            return j.gesture
        default:
            return j.gesture
        }
    }

    func endJob(_ b: inout Bug, _ j: Job, tr: SpeciesTraits) {
        b.job = nil
        if j.held >= 0 { setDown(j.held, by: b) }
        if j.pushing >= 0 { setDown(j.pushing, by: b) }
        if !b.fading && b.alpha < 1 { b.alpha = 1 }
        workResume(&b, tr: tr)
    }

    func workResume(_ b: inout Bug, tr: SpeciesTraits) {
        b.backward = false
        b.glide = false
        b.pinned = false
        if b.mode == .emerging {
            let e = nearestEdge(b.x, b.y)
            let d = depth(b.x, b.y, from: e)
            if d < b.size * 0.6 {
                b.entry = e
                creepSetup(&b, tr: tr, spread: 0.2)
                return
            }
        }
        b.mode = .wandering
        b.desired = wrap(b.course + workRng.signed() * 1.2)
        b.targetSpeed = paceOf(b, tr) * workRng.range(0.8...1.1)
        b.timer = workRng.range(tr.burst)
        b.restGesture = .none
        b.goalTimer = 0
    }

    func release(_ i: Int) {
        guard i >= 0, i < bugs.count, let j = bugs[i].job else { return }
        var b = bugs[i]
        endJob(&b, j, tr: tuning.traits(for: b.species))
        bugs[i] = b
    }

    func considerWatching(_ b: inout Bug) {
        let t = tuning
        guard t.workEnabled, t.watchChance > 0, b.restGesture == .none, b.job == nil, b.stray == nil, !b.rare else { return }
        guard !stage.work.games.isEmpty || !stage.work.projects.isEmpty else { return }
        var best: (x: Double, y: Double)?
        var bestD = t.watchRange
        var fire = -1
        for g in stage.work.games {
            let d = hypot(g.x - b.x, g.y - b.y)
            if d < bestD {
                bestD = d
                best = (g.x, g.y)
            }
        }
        for (k, p) in stage.work.projects.enumerated() where !p.dormant && p.phase != .finished {
            let d = hypot(p.x - b.x, p.y - b.y)
            if d < bestD {
                bestD = d
                best = (p.x, p.y)
                fire = p.kind == .campfire && p.phase == .using ? k : -1
            }
        }
        guard let s = best else { return }
        if fire >= 0, b.scripted == false, joinFire(&b, fire) { return }
        guard workRng.chance(t.watchChance) else { return }
        b.restGesture = .look
        if abs(s.x - b.x) > 2 {
            b.facing = s.x > b.x ? 1 : -1
            b.facingHold = 0.6
        }
    }

    func propLanded(_ id: Int, _ kind: PropLanding) {
        guard let p = prop(id) else { return }
        if p.game >= 0 && kind == .splat {
            snowballLanded(id)
        } else if p.site >= 0 && kind == .merge {
            mergeLanded(id)
        } else {
            editProp(id) { q in
                q.doomed = true
                q.doomRate = 5
            }
        }
    }

    func forgetWork() {
        rememberProjects()
        stage.work.projects.removeAll()
        stage.work.games.removeAll()
        for i in bugs.indices where bugs[i].job != nil {
            bugs[i].job = nil
        }
    }

    func closeWork() {
        clearProps()
    }
}
