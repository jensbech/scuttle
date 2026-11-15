import Foundation

public enum ProjectKind: String, CaseIterable, Codable, Sendable {
    case leafPile = "leafpile"
    case acornStash = "acornstash"
    case snowman
    case igloo
    case tree
    case jackLantern = "jacklantern"
    case nest
    case sandcastle
    case party
    case campfire
}

public enum ProjectPhase: String, CaseIterable, Codable, Sendable {
    case building
    case celebrating
    case using
    case finished
}

enum StepTask: Equatable {
    case fetch
    case roll
    case lift
    case work
}

struct ProjectStep {
    var task: StepTask
    var item = PropKind.acorn
    var count = 1
    var seconds = 0.0
    var to = 0.0
    var slot = -1
    var heavy = false
    var merge = false
    var builders = 3
    var rake = false
    var start = 0.4
    var final = 0.4
}

struct Project {
    var id: Int
    var kind: ProjectKind
    var x: Double
    var y: Double
    var unit: Double
    var steps: [ProjectStep]
    var step = 0
    var done = 0.0
    var phase = ProjectPhase.building
    var dormant = false
    var resumed = false
    var crew: [Int] = []
    var want = 2
    var sites = [-1, -1]
    var level = [0.0, 0.0]
    var from = 0.0
    var heap: [Int] = []
    var supply = Edge.left
    var supplyAlong = 0.0
    var clock = 0.0
    var total = 0.0
    var recruit = 0.0
    var useLength = 60.0
    var celebrate = 5.0
    var rollProp = -1
    var rollLeg = 0
    var rollClock = 0.0
    var wayX = 0.0
    var wayY = 0.0
    var endX = 0.0
    var endY = 0.0
    var lifting = false
    var liftProp = -1
    var jumper = -1
    var jumped = false
}

struct BuildMemory {
    var kind: ProjectKind
    var season: Season
    var x: Double
    var y: Double
    var unit: Double
    var step: Int
    var done: Double
    var level: [Double]
    var heap: [PropKind]
    var supply: Edge
    var supplyAlong: Double
    var saved: Double
}

public struct ProjectSnapshot: Sendable, Equatable {
    public var kind: ProjectKind
    public var phase: ProjectPhase
    public var progress: Double
    public var step: Int
    public var crew: Int
    public var dormant: Bool
    public var resumed: Bool
    public var x: Double
    public var y: Double
}

extension World {
    public var projects: [ProjectSnapshot] {
        stage.work.projects.map { p in
            ProjectSnapshot(kind: p.kind, phase: p.phase, progress: overall(p), step: p.step, crew: p.crew.count, dormant: p.dormant, resumed: p.resumed, x: p.x, y: p.y)
        }
    }

    public var rememberedProject: ProjectKind? { stage.work.memory?.kind }

    func projectIndex(_ id: Int) -> Int? {
        guard id >= 0 else { return nil }
        return stage.work.projects.firstIndex { $0.id == id }
    }

    func projectKinds(_ s: Season) -> [ProjectKind] {
        switch s {
        case .autumn: return [.leafPile, .acornStash, .campfire]
        case .winter: return [.snowman, .igloo, .campfire]
        case .christmas: return [.tree]
        case .halloween: return [.jackLantern, .campfire]
        case .spring: return [.nest]
        case .summer: return [.sandcastle, .campfire]
        case .newYear: return [.party]
        }
    }

    func recipe(_ k: ProjectKind) -> [ProjectStep] {
        switch k {
        case .leafPile:
            return [ProjectStep(task: .work, seconds: 40, to: 1, slot: 0, rake: true)]
        case .acornStash:
            return [ProjectStep(task: .fetch, item: .acorn, count: 7)]
        case .snowman:
            return [
                ProjectStep(task: .roll, item: .snowball, to: 1.0 / 3, slot: 0, start: 0.35, final: 1.1),
                ProjectStep(task: .roll, item: .snowball, to: 1.0 / 3, slot: 0, start: 0.3, final: 0.8),
                ProjectStep(task: .lift, item: .snowball, to: 2.0 / 3, slot: 0),
                ProjectStep(task: .fetch, item: .snowball, count: 1, to: 0.8, slot: 0, merge: true),
                ProjectStep(task: .work, seconds: 14, to: 1, slot: 0, builders: 2),
            ]
        case .igloo:
            return [
                ProjectStep(task: .fetch, item: .snowball, count: 6, to: 0.72, slot: 0, merge: true),
                ProjectStep(task: .work, seconds: 16, to: 1, slot: 0),
            ]
        case .tree:
            return [
                ProjectStep(task: .fetch, item: .present, count: 4, to: 1, slot: 1, merge: true),
                ProjectStep(task: .work, seconds: 30, to: 1, slot: 0),
            ]
        case .jackLantern:
            return [
                ProjectStep(task: .roll, item: .pumpkin, to: 0, slot: 0, start: 0.95, final: 0.95),
                ProjectStep(task: .work, seconds: 24, to: 1, slot: 0, builders: 2),
                ProjectStep(task: .fetch, item: .candy, count: 4),
            ]
        case .nest:
            return [
                ProjectStep(task: .work, seconds: 30, to: 1, slot: 0),
                ProjectStep(task: .fetch, item: .egg, count: 3),
            ]
        case .sandcastle:
            return [
                ProjectStep(task: .work, seconds: 42, to: 1, slot: 0),
                ProjectStep(task: .fetch, item: .shell, count: 3),
            ]
        case .party:
            return [
                ProjectStep(task: .fetch, item: .cake, count: 1, heavy: true),
                ProjectStep(task: .fetch, item: .balloon, count: 3),
                ProjectStep(task: .work, seconds: 20, to: 1, slot: 1, builders: 2),
            ]
        case .campfire:
            return [
                ProjectStep(task: .work, seconds: 30, to: 0.8, slot: 0),
                ProjectStep(task: .work, seconds: 3, to: 1, slot: 0, builders: 1),
            ]
        }
    }

    func itemSize(_ k: PropKind, unit u: Double, heavy: Bool = false) -> Double {
        switch k {
        case .acorn: return u * 0.42
        case .crumb: return u * 0.2
        case .candy: return u * 0.38
        case .egg: return u * 0.4
        case .flower: return u * 0.62
        case .shell: return u * 0.42
        case .snowball: return u * 0.42
        case .present: return u * (heavy ? 0.85 : 0.55)
        case .balloon: return u * 1.1
        case .lantern: return u * 0.5
        case .pumpkin: return u * 0.95
        case .cake: return u * 0.85
        case .ball: return u * 0.55
        case .rope: return u
        case .banner: return u * 0.55
        case .leafPile: return u * 1.6
        case .snowman: return u * 1.9
        case .igloo: return u * 1.8
        case .giftStack: return u * 1.3
        case .tree: return u * 2.1
        case .nest: return u * 1.15
        case .sandcastle: return u * 1.5
        case .campfire: return u * 1.2
        }
    }

    func siteHalf(_ k: ProjectKind, _ u: Double) -> Double {
        switch k {
        case .leafPile: return u * 0.9
        case .acornStash: return u * 0.8
        case .snowman: return u * 0.55
        case .igloo: return u * 1.0
        case .tree: return u * 1.4
        case .jackLantern: return u * 0.9
        case .nest: return u * 0.65
        case .sandcastle: return u * 0.85
        case .party: return u * 1.4
        case .campfire: return u * 0.7
        }
    }

    func overall(_ p: Project) -> Double {
        if p.phase != .building { return 1 }
        guard p.step < p.steps.count else { return 1 }
        let s = p.steps[p.step]
        var f: Double
        switch s.task {
        case .fetch: f = p.done / Double(max(1, s.count))
        case .work: f = p.done / max(0.1, s.seconds)
        case .roll, .lift: f = p.done
        }
        return (Double(p.step) + min(1, max(0, f))) / Double(max(1, p.steps.count))
    }

    func needsPusher(_ k: ProjectKind) -> Bool {
        k == .snowman || k == .jackLantern
    }

    func startLevel(_ steps: [ProjectStep], _ step: Int, _ slot: Int) -> Double {
        var v = 0.0
        guard slot >= 0 else { return 0 }
        for k in 0..<min(step, steps.count) where steps[k].slot == slot { v = steps[k].to }
        return v
    }

    func startProject(room: Int) -> Bool {
        let t = tuning
        var pool: [Int] = []
        for i in bugs.indices where bugs[i].mode != .hidden && workFree(bugs[i]) && canCarry(bugs[i]) { pool.append(i) }
        guard pool.count >= 2 else { return false }
        let seed = pool[pick(pool.count, workRng.unit())]
        var kinds = t.forceProject.map { [$0] } ?? projectKinds(config.season)
        if t.forceProject == nil, kinds.count > 1, let last = stage.work.lastProject { kinds.removeAll { $0 == last } }
        let pushers = pool.contains { canPush(bugs[$0]) }
        kinds = kinds.filter { !needsPusher($0) || pushers }
        guard !kinds.isEmpty else { return false }
        let kind = kinds[pick(kinds.count, workRng.unit())]
        let lo = max(2, t.projectCrew.lowerBound), hi = max(lo, t.projectCrew.upperBound)
        var want = stage.visible < 10 ? 2 : (stage.visible < 20 ? 3 : 4)
        want = min(max(want, lo), hi, room, pool.count)
        guard want >= 2 else { return false }
        let sx = bugs[seed].x, sy = bugs[seed].y
        pool.sort { a, b in
            let da = hypot(bugs[a].x - sx, bugs[a].y - sy), db = hypot(bugs[b].x - sx, bugs[b].y - sy)
            return da != db ? da < db : bugs[a].id < bugs[b].id
        }
        var crew = Array(pool.prefix(want))
        if needsPusher(kind) && !crew.contains(where: { canPush(bugs[$0]) }), let p = pool.first(where: { canPush(bugs[$0]) }) {
            crew[crew.count - 1] = p
        }
        var unit = 0.0, cx = 0.0, cy = 0.0
        for i in crew {
            unit += bugs[i].size
            cx += bugs[i].x
            cy += bugs[i].y
        }
        let n = Double(crew.count)
        unit = min(40, max(20, unit / n))
        guard let site = chooseSite(cx / n, cy / n, unit: unit, kind: kind) else { return false }
        for k in stage.work.projects.indices where stage.work.projects[k].phase == .finished { retireSite(stage.work.projects[k]) }
        stage.work.projects.removeAll { $0.phase == .finished }
        stage.work.serial += 1
        var p = Project(id: stage.work.serial, kind: kind, x: site.x, y: site.y, unit: unit, steps: recipe(kind))
        p.want = want
        chooseSupply(&p)
        createSites(&p)
        for (r, i) in crew.enumerated() {
            var j = Job(family: .crew)
            j.group = p.id
            j.role = r
            j.tripsMax = Int(workRng.range(Double(t.projectTrips.lowerBound)...Double(max(t.projectTrips.lowerBound, t.projectTrips.upperBound)) + 0.999))
            bugs[i].job = j
            bugs[i].restGesture = .none
            p.crew.append(bugs[i].id)
        }
        stage.census.workers += crew.count
        if let d = bugs.indices.first(where: { bugs[$0].mode != .hidden && bugs[$0].species.locomotion == .dart && workFree(bugs[$0]) && hypot(bugs[$0].x - p.x, bugs[$0].y - p.y) < 700 }), workRng.chance(0.6) {
            var j = Job(family: .crew)
            j.group = p.id
            j.task = .supervise
            j.sign = bugs[d].x >= p.x ? 1 : -1
            j.length = workRng.range(5...8)
            bugs[d].job = j
            p.crew.append(bugs[d].id)
            stage.census.workers += 1
        }
        p.recruit = 2
        stage.work.projects.append(p)
        stage.work.lastProject = kind
        stage.work.projectGap = workRng.range(t.projectCooldown)
        return true
    }

    func pick(_ count: Int, _ u: Double) -> Int {
        guard count > 1 else { return 0 }
        return min(count - 1, Int(u * Double(count)))
    }

    func retireSite(_ p: Project) {
        for id in p.sites + p.heap where id >= 0 {
            editProp(id) { q in
                q.doomed = true
                q.doomRate = 0.5
            }
        }
    }

    func chooseSite(_ cx: Double, _ cy: Double, unit u: Double, kind: ProjectKind) -> (x: Double, y: Double)? {
        let half = siteHalf(kind, u)
        let mx = min(width / 2 - 1, max(half + u * 2.2, 90))
        let lo = min(height * 0.3, max(u * 1.2, 40))
        let tall = kind == .tree || kind == .party || kind == .snowman
        let hi = max(lo, height * 0.55 - (tall ? u * 1.5 : 0))
        var best: (x: Double, y: Double)?
        var score = -Double.infinity
        for k in 0..<5 {
            let ox = k == 0 ? 0 : workRng.signed() * 420
            let oy = k == 0 ? 0 : workRng.signed() * 160
            let x = min(max(cx + ox, mx), max(mx, width - mx))
            let y = min(max(cy - u * 0.5 + oy, lo), hi)
            var clear = 2000.0
            for p in stage.work.projects where p.phase != .finished { clear = min(clear, hypot(p.x - x, p.y - y)) }
            for g in stage.work.games { clear = min(clear, hypot(g.x - x, g.y - y)) }
            guard clear > half * 2 + 140 else { continue }
            let s = min(clear, 600) - hypot(x - cx, y - cy) * 0.3
            if s > score {
                score = s
                best = (x, y)
            }
        }
        return best
    }

    func chooseSupply(_ p: inout Project) {
        var options: [Edge] = []
        var nearest = Edge.bottom
        var nearD = Double.infinity
        for e in [Edge.left, .right, .bottom] {
            let d = depth(p.x, p.y, from: e)
            if d >= 160 && d <= 520 { options.append(e) }
            if d >= 120 && d < nearD {
                nearD = d
                nearest = e
            }
        }
        p.supply = options.isEmpty ? nearest : options[pick(options.count, workRng.unit())]
        switch p.supply {
        case .left, .right:
            p.supplyAlong = min(max(p.y + p.unit * 0.5 + workRng.signed() * 90, 60), max(60, height * 0.6))
        default:
            let side: Double = workRng.chance(0.5) ? 1 : -1
            var a = p.x + side * workRng.range(250...450)
            if a < 60 || a > width - 60 { a = p.x - side * workRng.range(250...450) }
            p.supplyAlong = min(max(a, 60), max(60, width - 60))
        }
    }

    func createSites(_ p: inout Project) {
        let u = p.unit
        func make(_ kind: PropKind, _ x: Double, _ gy: Double, _ slot: Int) {
            let s = itemSize(kind, unit: u)
            let id = addProp(kind, x: x, y: gy + s * 0.5, size: s, progress: p.level[slot], layer: 0)
            editProp(id) { q in
                q.site = p.id
                q.fadeIn = 1.2
            }
            p.sites[slot] = id
        }
        switch p.kind {
        case .leafPile: make(.leafPile, p.x, p.y, 0)
        case .igloo: make(.igloo, p.x, p.y, 0)
        case .nest: make(.nest, p.x, p.y, 0)
        case .sandcastle: make(.sandcastle, p.x, p.y, 0)
        case .campfire: make(.campfire, p.x, p.y, 0)
        case .tree:
            make(.tree, p.x - u * 0.3, p.y, 0)
            make(.giftStack, p.x + u * 1.15, p.y - u * 0.15, 1)
        case .snowman:
            if p.level[0] >= 1.0 / 3 - 1e-6 { make(.snowman, p.x, p.y, 0) }
        case .jackLantern:
            if p.step > 0 { make(.pumpkin, p.x, p.y, 0) }
        case .party:
            if p.step >= 2 { hangBanner(&p) }
        case .acornStash:
            break
        }
    }

    func hangBanner(_ p: inout Project) {
        let u = p.unit
        let top = min(p.y + u * 2.5, height - u * 0.8)
        let ax = max(u, p.x - u * 2.1), bx = min(width - u, p.x + u * 2.1)
        let id = addProp(.banner, x: ax, y: top, size: itemSize(.banner, unit: u), progress: p.level[1], motion: .hung, layer: 1)
        editProp(id) { q in
            q.site = p.id
            q.hasEnd = true
            q.endX = bx
            q.endY = top
            q.fadeIn = 1.2
        }
        p.sites[1] = id
    }

    func applyLevel(_ p: inout Project, slot: Int, value: Double) {
        guard slot >= 0, slot < p.level.count else { return }
        p.level[slot] = min(1, max(0, value))
        let v = p.level[slot]
        if p.sites[slot] >= 0 { editProp(p.sites[slot]) { $0.progress = v } }
    }

    func heapSpot(_ p: Project, _ n: Int) -> (x: Double, y: Double, layer: Int) {
        let u = p.unit
        switch p.kind {
        case .acornStash:
            let s = itemSize(.acorn, unit: u)
            var row = 0, start = 0, len = 4
            while n >= start + len && len > 1 {
                start += len
                len -= 1
                row += 1
            }
            let c = Double(n - start) - Double(len - 1) / 2
            return (p.x + c * s * 0.9, p.y + Double(row) * s * 0.55, 2 + min(row, 3))
        case .jackLantern:
            let side: Double = n % 2 == 0 ? -1 : 1
            let k = Double(n / 2)
            return (p.x + side * (u * 0.75 + k * u * 0.38), p.y - u * 0.08 - k * u * 0.05, 2)
        case .nest:
            let nest = itemSize(.nest, unit: u)
            let off: [Double] = [-0.2, 0.2, 0]
            return (p.x + off[n % 3] * nest, p.y + nest * 0.3 + (n == 2 ? nest * 0.06 : 0), 3)
        case .sandcastle:
            let off: [Double] = [-0.62, 0.62, 0.0, -0.3, 0.3]
            return (p.x + off[n % off.count] * itemSize(.sandcastle, unit: u), p.y - u * 0.15, 2)
        case .party:
            if n == 0 { return (p.x, p.y - u * 0.1, 2) }
            let off: [Double] = [-1.05, 1.05, -1.6, 1.6]
            return (p.x + off[(n - 1) % off.count] * u, p.y + u * 0.25, 2)
        default:
            let a = Double(n) * 2.4
            return (p.x + cos(a) * u * 0.9, p.y + sin(a) * u * 0.3, 2)
        }
    }

    func mergeTarget(_ p: Project) -> (x: Double, y: Double) {
        let s = p.steps[min(p.step, p.steps.count - 1)]
        let slot = max(0, s.slot)
        if p.sites[slot] >= 0, let q = prop(p.sites[slot]) {
            switch q.kind {
            case .snowman: return (q.x, p.y + q.size * 0.82)
            case .giftStack: return (q.x, p.y + q.size * (0.2 + 0.6 * q.progress))
            default: return (q.x, p.y + q.size * 0.5)
            }
        }
        return (p.x, p.y + p.unit * 0.5)
    }

    func ringSpot(_ p: Project, _ n: Int, _ b: Bug, extra: Double = 0) -> (x: Double, y: Double) {
        let angles: [Double] = [0, .pi, -0.55, .pi + 0.55, -1.15, .pi + 1.15, 0.45, .pi - 0.45]
        let a = angles[n % angles.count]
        let rx = siteHalf(p.kind, p.unit) + b.size * 0.6 + extra + Double(n / angles.count) * b.size
        let ry = rx * 0.38
        let lift = b.species.isAirborne ? b.size * 0.9 : 0
        return spot(x: p.x + cos(a) * rx, y: p.y + sin(a) * ry + b.size * 0.5 + lift, pad: b.size * 0.6)
    }

    func freeSlot(_ p: Project, except id: Int) -> Int {
        var used = Set<Int>()
        for m in p.crew where m != id {
            if let i = index(of: m), let j = bugs[i].job, j.slot >= 0 { used.insert(j.slot) }
        }
        var n = 0
        while used.contains(n) { n += 1 }
        return n
    }

    func runProjects(_ h: Double) {
        guard !stage.work.projects.isEmpty else { return }
        let t = tuning
        var k = stage.work.projects.count - 1
        while k >= 0 {
            var p = stage.work.projects[k]
            p.clock += h
            p.total += h
            p.recruit -= h
            let pid = p.id
            p.crew.removeAll { id in
                guard let i = index(of: id), bugs[i].mode != .hidden, let j = bugs[i].job else { return true }
                return j.family != .crew || j.group != pid
            }
            if p.phase == .finished {
                stage.work.projects[k] = p
                k -= 1
                continue
            }
            let bad = max(light, targetLight) > t.duskLight || isJiggling || !t.workEnabled || !t.projectsEnabled
            if bad {
                p.dormant = true
                stage.work.projects[k] = p
                k -= 1
                continue
            }
            if p.dormant {
                p.dormant = false
                p.recruit = min(p.recruit, 1)
            }
            switch p.phase {
            case .building:
                advanceBuild(&p, h)
            case .celebrating:
                if p.clock >= p.celebrate {
                    p.phase = .using
                    p.clock = 0
                    for id in p.crew {
                        if let i = index(of: id) {
                            bugs[i].job?.stage = 0
                            bugs[i].job?.clock = 0
                        }
                    }
                }
            case .using:
                if p.clock >= p.useLength { p.phase = .finished }
            case .finished:
                break
            }
            if p.phase == .building && p.recruit <= 0 {
                p.recruit = 1.5
                recruitCrew(&p)
            }
            stage.work.projects[k] = p
            k -= 1
        }
    }

    func crewWorkers(_ p: Project) -> Int {
        var n = 0
        for id in p.crew {
            if let i = index(of: id), let j = bugs[i].job, j.task != .supervise { n += 1 }
        }
        return n
    }

    func recruitCrew(_ p: inout Project) {
        let t = tuning
        guard crewWorkers(p) < p.want, workCap() - stage.census.workers > 0, stage.visible >= 2 else { return }
        guard darkSeconds >= (p.resumed ? t.memoryAfter + 2 : min(t.projectAfter, 10)) else { return }
        var best = -1
        var bestD = 900.0
        for i in bugs.indices where bugs[i].mode != .hidden && workFree(bugs[i]) && canCarry(bugs[i]) {
            let d = hypot(bugs[i].x - p.x, bugs[i].y - p.y)
            if d < bestD {
                bestD = d
                best = i
            }
        }
        guard best >= 0 else { return }
        var j = Job(family: .crew)
        j.group = p.id
        j.role = p.crew.count
        j.tripsMax = Int(workRng.range(Double(t.projectTrips.lowerBound)...Double(max(t.projectTrips.lowerBound, t.projectTrips.upperBound)) + 0.999))
        bugs[best].job = j
        bugs[best].restGesture = .none
        p.crew.append(bugs[best].id)
        stage.census.workers += 1
    }

    func advanceBuild(_ p: inout Project, _ h: Double) {
        let t = tuning
        guard p.step < p.steps.count else {
            beginCelebration(&p)
            return
        }
        let s = p.steps[p.step]
        switch s.task {
        case .work:
            var builders = 0
            for id in p.crew {
                if let i = index(of: id), let j = bugs[i].job, j.task == .work, j.stage == 1, j.count == p.step { builders += 1 }
            }
            builders = min(builders, max(1, s.builders))
            p.done += h * Double(builders) * max(0, t.workSpeed)
            let f = min(1, p.done / max(0.1, s.seconds))
            applyLevel(&p, slot: s.slot, value: p.from + (s.to - p.from) * f)
            if f >= 1 { nextStep(&p) }
        case .fetch:
            if p.done >= Double(s.count) - 1e-9 { nextStep(&p) }
        case .roll:
            if p.done >= 1 { nextStep(&p) }
        case .lift:
            if p.done >= 1 {
                nextStep(&p)
            } else if !p.lifting {
                var ready = 0, lifters = 0
                for id in p.crew {
                    if let i = index(of: id), let j = bugs[i].job, j.task == .lift {
                        lifters += 1
                        if j.stage == 1 { ready += 1 }
                    }
                }
                if ready >= 2 || (ready >= 1 && lifters < 2 && p.clock > 8) || p.clock > 30 { startLift(&p) }
            }
        }
    }

    func startLift(_ p: inout Project) {
        guard let k = propIndex(p.liftProp) else {
            applyLevel(&p, slot: 0, value: 2.0 / 3)
            p.done = 1
            return
        }
        let snow = itemSize(.snowman, unit: p.unit)
        var q = stage.yard.bodies[k]
        q.motion = .flying
        q.fromX = q.x
        q.fromY = q.y
        q.toX = p.x
        q.toY = p.y + snow * 0.46 * 0.88 + q.size * 0.5
        q.clock = 0
        q.length = 1.3
        q.hump = p.unit * 0.5
        q.landing = .merge
        q.site = p.id
        q.claim = -1
        q.spin = 0
        stage.yard.bodies[k] = q
        p.lifting = true
    }

    func nextStep(_ p: inout Project) {
        p.step += 1
        p.done = 0
        p.clock = 0
        p.lifting = false
        p.rollProp = -1
        p.rollLeg = 0
        p.rollClock = 0
        guard p.step < p.steps.count else {
            beginCelebration(&p)
            return
        }
        let s = p.steps[p.step]
        p.from = s.slot >= 0 ? p.level[s.slot] : 0
        if p.kind == .party && s.task == .work && p.sites[1] < 0 { hangBanner(&p) }
    }

    func beginCelebration(_ p: inout Project) {
        let t = tuning
        p.phase = .celebrating
        p.clock = 0
        p.celebrate = workRng.range(t.celebrateLength)
        p.useLength = workRng.range(t.useLength)
        p.jumper = -1
        p.jumped = false
        if p.kind == .leafPile {
            for id in p.crew {
                if let i = index(of: id), onFoot(bugs[i]), bugs[i].job?.task != .supervise {
                    p.jumper = id
                    if bugs[i].species.locomotion == .hop { break }
                }
            }
            p.celebrate += 2.5
        }
        for id in p.crew {
            if let i = index(of: id) {
                bugs[i].job?.stage = 0
                bugs[i].job?.clock = 0
                bugs[i].job?.slot = -1
            }
        }
    }

    func mergeLanded(_ id: Int) {
        guard let q = prop(id) else { return }
        editProp(id) { r in
            r.doomed = true
            r.fade = 0
            r.doomRate = 50
        }
        guard let k = projectIndex(q.site) else { return }
        var p = stage.work.projects[k]
        guard p.phase == .building, p.step < p.steps.count else { return }
        let s = p.steps[p.step]
        if s.task == .lift && id == p.liftProp {
            p.done = 1
            p.lifting = false
            p.liftProp = -1
            applyLevel(&p, slot: 0, value: s.to)
        } else if s.task == .fetch && s.merge && q.kind == s.item {
            p.done += 1
            applyLevel(&p, slot: s.slot, value: p.from + (s.to - p.from) * min(1, p.done / Double(max(1, s.count))))
        }
        stage.work.projects[k] = p
    }

    func crewStep(_ b: inout Bug, _ j: inout Job, tr: SpeciesTraits, h: Double) -> Bool {
        guard let pi = projectIndex(j.group) else { return true }
        let p = stage.work.projects[pi]
        if p.dormant || p.phase == .finished { return true }
        if p.phase == .celebrating {
            celebrateStep(&b, &j, pi, tr: tr, h: h)
            return false
        }
        if p.phase == .using { return gatherStep(&b, &j, pi, tr: tr, h: h) }
        if j.task == .supervise {
            superviseStep(&b, &j, pi, tr: tr, h: h)
            return false
        }
        let busy = j.held >= 0 || j.pushing >= 0
        if j.alarm > 0 && !busy {
            holdStill(&b, tr: tr, h: h)
            turnTo(&b, x: j.alarmX)
            j.gesture = .look
            return false
        }
        let stale = j.task != .wait && j.task != .idle && j.count != p.step && !busy && j.lead
        if j.task == .idle || stale || (j.task == .wait && j.clock >= 0.6) {
            if j.trips >= j.tripsMax && !busy { return true }
            assignCrew(&b, &j, pi)
        }
        switch j.task {
        case .fetch: return fetchStep(&b, &j, pi, tr: tr, h: h)
        case .roll: return rollerStep(&b, &j, pi, tr: tr, h: h)
        case .lift: return lifterStep(&b, &j, pi, tr: tr, h: h)
        case .work: return builderStep(&b, &j, pi, tr: tr, h: h)
        default: return waitStep(&b, &j, pi, tr: tr, h: h)
        }
    }

    func holdStill(_ b: inout Bug, tr: SpeciesTraits, h: Double) {
        settleStill(&b, tr: tr, h: h)
        b.mode = .resting
    }

    func assignCrew(_ b: inout Bug, _ j: inout Job, _ pi: Int) {
        let p = stage.work.projects[pi]
        guard p.step < p.steps.count else {
            j.task = .wait
            j.clock = 0
            return
        }
        let s = p.steps[p.step]
        let keepSlot = j.task == .wait ? j.slot : -1
        j.count = p.step
        j.stage = 0
        j.clock = 0
        j.target = -1
        j.mate = -1
        j.lead = true
        j.slot = -1
        j.gesture = .none
        j.tripAt = -1
        switch s.task {
        case .fetch:
            assignFetch(&b, &j, pi)
        case .roll:
            var lead = false, helper = false
            for id in p.crew where id != b.id {
                if let i = index(of: id), let o = bugs[i].job, o.task == .roll, o.count == p.step {
                    if o.lead { lead = true } else { helper = true }
                }
            }
            if canPush(b) && (!lead || !helper) {
                j.task = .roll
                j.lead = !lead
                j.sign = workRng.chance(0.5) ? 1 : -1
            } else {
                j.task = .wait
            }
        case .lift:
            var lifters = 0
            for id in p.crew where id != b.id {
                if let i = index(of: id), bugs[i].job?.task == .lift { lifters += 1 }
            }
            if lifters < 2 && canCarry(b) {
                j.task = .lift
                j.sign = lifters == 0 ? -1 : 1
            } else {
                j.task = .wait
            }
        case .work:
            var builders = 0
            for id in p.crew where id != b.id {
                if let i = index(of: id), let o = bugs[i].job, o.task == .work, o.count == p.step { builders += 1 }
            }
            if builders < max(1, s.builders) {
                j.task = .work
                j.slot = freeSlot(p, except: b.id)
            } else {
                j.task = .wait
            }
        }
        if j.task == .wait { j.slot = keepSlot >= 0 ? keepSlot : freeSlot(p, except: b.id) }
    }

    func waitStep(_ b: inout Bug, _ j: inout Job, _ pi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        let p = stage.work.projects[pi]
        if j.slot < 0 { j.slot = freeSlot(p, except: b.id) }
        let s = ringSpot(p, j.slot, b, extra: b.size * 0.5)
        if j.stage == 0 {
            j.gesture = .none
            if walkTo(&b, s.x, s.y, pace: paceOf(b, tr) * 0.8, tr: tr, h: h) { j.stage = 1 }
            return false
        }
        stayAt(&b, s.x, s.y, tr: tr, h: h)
        turnTo(&b, x: p.x)
        let beat = Int(j.total / 2.2 + Double(j.role)) % 4
        j.gesture = beat == 0 ? .look : (beat == 2 && p.steps[p.step].task == .work ? .build : .none)
        return false
    }

    func builderStep(_ b: inout Bug, _ j: inout Job, _ pi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        let p = stage.work.projects[pi]
        let s = p.steps[min(p.step, p.steps.count - 1)]
        if j.slot < 0 { j.slot = freeSlot(p, except: b.id) }
        let rake = s.rake && onFoot(b)
        let spot = ringSpot(p, j.slot, b, extra: rake ? 26 : 0)
        if j.stage == 0 {
            j.gesture = .none
            if walkTo(&b, spot.x, spot.y, pace: paceOf(b, tr), tr: tr, h: h) {
                j.stage = 1
                j.clock = 0
            }
            if j.clock > 20 {
                j.stage = 1
                j.clock = 0
            }
            return false
        }
        if rake {
            let phase = j.clock.truncatingRemainder(dividingBy: 1.5)
            let inward = atan2(p.y + b.size * 0.5 - b.y, p.x - b.x)
            if phase < 0.75 {
                j.gesture = .push
                b.course = inward
                approach(&b.speed, b.species.locomotion == .hop ? 0 : max(6, b.size * 0.6), rate: 60, h: h)
            } else {
                j.gesture = .none
                let back = atan2(spot.y - b.y, spot.x - b.x)
                if hypot(spot.x - b.x, spot.y - b.y) > 3 {
                    b.course = back
                    b.backward = !b.species.isAirborne && b.species.locomotion != .hop
                    approach(&b.speed, max(6, b.size * 0.6), rate: 60, h: h)
                } else {
                    brake(&b, tau: 0.06, h: h)
                }
            }
            if phase < 0.75 { b.backward = false }
            workMove(&b)
            turnTo(&b, x: p.x)
            b.facingHold = max(b.facingHold, 0.3)
            return false
        }
        stayAt(&b, spot.x, spot.y, tr: tr, h: h)
        turnTo(&b, x: p.x)
        j.gesture = .build
        return false
    }

    func superviseStep(_ b: inout Bug, _ j: inout Job, _ pi: Int, tr: SpeciesTraits, h: Double) {
        let p = stage.work.projects[pi]
        if j.clock >= j.length {
            j.clock = 0
            j.length = workRng.range(5...8)
            j.sign = -j.sign
        }
        let s = spot(x: p.x + j.sign * (siteHalf(p.kind, p.unit) + p.unit * 1.3), y: p.y + p.unit * 2.3, pad: b.size)
        stayAt(&b, s.x, s.y, tr: tr, h: h)
        turnTo(&b, x: p.x)
        j.gesture = .look
    }

    func celebrateStep(_ b: inout Bug, _ j: inout Job, _ pi: Int, tr: SpeciesTraits, h: Double) {
        var p = stage.work.projects[pi]
        if j.task == .supervise {
            superviseStep(&b, &j, pi, tr: tr, h: h)
            j.gesture = .none
            return
        }
        if p.kind == .leafPile && b.id == p.jumper && !p.jumped {
            let pile = itemSize(.leafPile, unit: p.unit)
            switch j.stage {
            case 0:
                j.gesture = .none
                let side: Double = b.x >= p.x ? 1 : -1
                if walkTo(&b, p.x + side * (pile * 0.5 + b.size * 1.6), p.y + b.size * 0.5, pace: paceOf(b, tr), tr: tr, h: h) || j.clock > 12 {
                    j.stage = 1
                    j.clock = 0
                }
            case 1:
                j.gesture = .none
                if walkTo(&b, p.x, p.y + pile * 0.25, pace: paceOf(b, tr) * 1.8, tr: tr, h: h, within: b.size * 0.4) || j.clock > 4 {
                    j.stage = 2
                    j.clock = 0
                }
            default:
                j.gesture = .tumble
                brake(&b, tau: 0.08, h: h)
                if b.species.locomotion == .hop { b.speed = 0 }
                b.mode = .resting
                if j.clock > 0.25 && !p.jumped {
                    p.jumped = true
                    applyLevel(&p, slot: 0, value: 0.7)
                    stage.work.projects[pi] = p
                }
            }
            return
        }
        if j.slot < 0 { j.slot = freeSlot(p, except: b.id) }
        let s = ringSpot(p, j.slot, b)
        if j.stage == 0 {
            j.gesture = .none
            if walkTo(&b, s.x, s.y, pace: paceOf(b, tr), tr: tr, h: h) || j.clock > 6 {
                j.stage = 1
                j.clock = 0
            }
            return
        }
        if p.kind == .leafPile && !p.jumped {
            holdStill(&b, tr: tr, h: h)
            if let ji = index(of: p.jumper) { turnTo(&b, x: bugs[ji].x) }
            j.gesture = .look
            return
        }
        let dance = (Int(j.clock / 1.4) + j.role) % 2 == 0
        j.gesture = dance ? .dance : .cheer
        b.mode = .resting
        if b.species.isAirborne {
            hover(&b, tr: tr, h: h, spin: dance ? 2.6 : 0.9, scale: dance ? 1.4 : 1)
        } else {
            brake(&b, tau: 0.08, h: h)
            if b.species.locomotion == .hop { b.speed = 0 }
            if dance && b.facingHold <= 0 {
                b.facing = -b.facing
                b.facingHold = 0.55
            } else if !dance {
                turnTo(&b, x: p.x)
            }
        }
    }

    func gatherStep(_ b: inout Bug, _ j: inout Job, _ pi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        let p = stage.work.projects[pi]
        if j.task == .supervise {
            superviseStep(&b, &j, pi, tr: tr, h: h)
            return j.clock > 20
        }
        if p.kind == .leafPile && b.id == p.jumper {
            holdStill(&b, tr: tr, h: h)
            j.gesture = j.clock > 3 ? .sleep : .none
            return false
        }
        let sitter = p.kind == .nest && p.crew.first(where: { id in index(of: id).map { onFoot(bugs[$0]) } ?? false }) == b.id
        if sitter {
            let nest = itemSize(.nest, unit: p.unit)
            if j.stage == 0 {
                j.gesture = .none
                if walkTo(&b, p.x, p.y + nest * 0.35 + b.size * 0.3, pace: paceOf(b, tr) * 0.8, tr: tr, h: h) || j.clock > 10 {
                    j.stage = 1
                    j.clock = 0
                }
                return false
            }
            holdStill(&b, tr: tr, h: h)
            j.gesture = j.clock > 1.5 ? .sleep : .none
            return false
        }
        if j.slot < 0 { j.slot = freeSlot(p, except: b.id) }
        let s = ringSpot(p, j.slot, b, extra: p.kind == .campfire ? b.size * 0.3 : 0)
        if j.stage == 0 {
            j.gesture = .none
            if walkTo(&b, s.x, s.y, pace: paceOf(b, tr) * 0.8, tr: tr, h: h) || j.clock > 10 {
                j.stage = 1
                j.clock = 0
            }
            return false
        }
        stayAt(&b, s.x, s.y, tr: tr, h: h)
        turnTo(&b, x: p.x)
        let beat = Int(j.clock / 2.6) + j.role
        switch p.kind {
        case .campfire, .igloo:
            j.gesture = j.clock < 6 ? .none : (j.role % 2 == 1 && onFoot(b) ? .sleep : (beat % 4 == 0 ? .look : .none))
        case .party:
            j.gesture = beat % 3 == 0 ? .dance : (beat % 3 == 1 ? .cheer : .none)
            if j.gesture == .dance && !b.species.isAirborne && b.facingHold <= 0 {
                b.facing = -b.facing
                b.facingHold = 0.55
            }
        default:
            j.gesture = beat % 5 == 0 ? .cheer : (beat % 2 == 0 ? .look : .none)
        }
        return false
    }

    func joinFire(_ b: inout Bug, _ k: Int) -> Bool {
        var p = stage.work.projects[k]
        guard p.crew.count < 7, workCap() - stage.census.workers > 0 || p.crew.count < 4 else { return false }
        guard !b.rare, onScreen(b), b.species.locomotion != .dart, workRng.chance(0.5) else { return false }
        var j = Job(family: .crew)
        j.group = p.id
        j.role = p.crew.count
        b.job = j
        p.crew.append(b.id)
        stage.work.projects[k] = p
        stage.census.workers += 1
        return true
    }

    func rememberProjects() {
        let t = tuning
        guard t.buildMemoryEnabled else { return }
        var best: Project?
        var bestF = 0.0
        for p in stage.work.projects where p.phase == .building {
            let f = overall(p)
            if f >= 0.04 && f > bestF {
                bestF = f
                best = p
            }
        }
        guard var p = best, p.step < p.steps.count else { return }
        var done = p.done
        switch p.steps[p.step].task {
        case .roll:
            done = 0
        case .lift:
            if prop(p.liftProp) == nil {
                p.step -= 1
            }
            done = 0
        case .fetch:
            done = done.rounded(.down)
        case .work:
            break
        }
        var heap: [PropKind] = []
        for id in p.heap {
            if let q = prop(id), q.site == p.id { heap.append(q.kind) }
        }
        stage.work.memory = BuildMemory(
            kind: p.kind, season: config.season, x: p.x, y: p.y, unit: p.unit, step: max(0, p.step), done: done,
            level: p.level, heap: heap, supply: p.supply, supplyAlong: p.supplyAlong, saved: time
        )
    }

    func considerMemory() {
        let t = tuning
        guard let m = stage.work.memory else { return }
        if m.season != config.season || time - m.saved > t.buildMemorySeconds || !t.buildMemoryEnabled {
            stage.work.memory = nil
            return
        }
        guard t.workEnabled, t.projectsEnabled, stage.visible >= 1, isDarkNow, max(light, targetLight) <= t.duskLight, !isJiggling, darkSeconds >= t.memoryAfter else { return }
        guard stage.work.projects.allSatisfy({ $0.phase == .finished }) else { return }
        for k in stage.work.projects.indices { retireSite(stage.work.projects[k]) }
        stage.work.projects.removeAll()
        stage.work.serial += 1
        let half = siteHalf(m.kind, m.unit)
        let s = spot(x: m.x, y: m.y, pad: half + m.unit)
        var p = Project(id: stage.work.serial, kind: m.kind, x: s.x, y: min(s.y, height * 0.6), unit: m.unit, steps: recipe(m.kind))
        p.step = min(m.step, p.steps.count - 1)
        p.done = m.done
        p.level = m.level
        let st = p.steps[p.step]
        p.from = startLevel(p.steps, p.step, st.slot)
        p.supply = m.supply
        p.supplyAlong = m.supplyAlong
        p.resumed = true
        p.recruit = 0.5
        p.want = stage.visible < 10 ? 2 : (stage.visible < 20 ? 3 : 4)
        p.want = min(max(p.want, max(2, t.projectCrew.lowerBound)), max(2, t.projectCrew.upperBound))
        createSites(&p)
        for (n, kind) in m.heap.enumerated() {
            let spot = heapSpot(p, n)
            let size = itemSize(kind, unit: p.unit, heavy: kind == .cake)
            let id = addProp(kind, x: spot.x, y: spot.y + size * 0.5, size: size, layer: spot.layer)
            editProp(id) { q in
                q.site = p.id
                q.fadeIn = 1.2
            }
            p.heap.append(id)
        }
        stage.work.projects.append(p)
        stage.work.lastProject = p.kind
        stage.work.memory = nil
    }
}
