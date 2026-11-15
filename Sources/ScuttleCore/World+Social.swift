import Foundation

public enum SocialKind: String, CaseIterable, Codable, Sendable {
    case stroll
    case string
    case tag
    case huddle
    case duet
    case nudge
    case visit
    case admire
    case race
    case roll
    case slide
    case bob
    case peekaboo
    case rainDance = "raindance"
    case watch
    case flinch

    var counts: Bool { self != .flinch && self != .watch }

    var plays: Bool { self == .duet || self == .rainDance }

    var grouped: Bool {
        switch self {
        case .stroll, .string, .tag, .huddle, .duet, .nudge, .visit, .admire, .race, .peekaboo: return true
        case .roll, .slide, .bob, .rainDance, .watch, .flinch: return false
        }
    }

    var room: Int {
        switch self {
        case .string, .huddle: return 3
        case .stroll, .tag, .duet, .visit, .admire, .race, .peekaboo: return 2
        case .nudge, .roll, .slide, .bob, .rainDance, .watch, .flinch: return 1
        }
    }

    var weight: Double {
        switch self {
        case .stroll: return 1.0
        case .string: return 0.5
        case .tag: return 0.7
        case .huddle: return 0.6
        case .duet: return 0.9
        case .nudge: return 1.2
        case .visit: return 1.0
        case .admire: return 4.0
        case .race: return 1.2
        case .roll: return 0.9
        case .slide: return 0.9
        case .bob: return 0.8
        case .peekaboo: return 1.0
        case .rainDance: return 1.0
        case .watch, .flinch: return 0
        }
    }
}

struct Social {
    var kind: SocialKind
    var group = -1
    var role = 0
    var target = -1
    var stage = 0
    var clock = 0.0
    var length = 0.0
    var delay = 0.0
    var x = 0.0
    var y = 0.0
    var angle = 0.0
    var sign = 1.0
    var pace = 0.0
    var spacing = 0.0
    var offset = 0.0
    var gesture = Gesture.none
    var ending = false
    var away: Double?
    var count = 0
    var prev = 0.0
    var aloft = false
}

struct SocialGroup {
    var id: Int
    var kind: SocialKind
    var members: [Int]
    var stage = 0
    var clock = 0.0
    var length = 0.0
    var total = 0.0
    var x = 0.0
    var y = 0.0
    var it = -1
    var freeze = 0.0
    var beat = 0.3
    var tags = 0
    var radius = 0.0
    var pace = 0.0
    var angle = 0.0
    var waver = -1
}

struct SocialStage {
    var clock = 0.0
    var serial = 0
    var groups: [SocialGroup] = []
    var cooldown: [SocialKind: Double] = [:]
    var ripples = 0
    var watchGap = 0.0
    var slots: [Int] = []
}

extension World {
    public var socialCounts: [SocialKind: Int] {
        var out: [SocialKind: Int] = [:]
        for b in bugs where b.mode != .hidden {
            if let s = b.social { out[s.kind, default: 0] += 1 }
        }
        return out
    }

    public var socialGroupCount: Int { stage.social.groups.count }

    func playCap() -> Int {
        max(1, Int(Double(stage.visible) * max(0, tuning.playShare)))
    }

    func playingNow() -> Int {
        var n = 0
        for b in bugs where b.mode != .hidden {
            if let a = b.act, a.delay <= 0, a.kind == .dance || a.kind == .cheer {
                n += 1
            } else if let s = b.social, s.kind.plays {
                n += 1
            }
        }
        return n
    }

    func socialWeight(_ k: SocialKind) -> Double {
        max(0, tuning.socialWeights[k] ?? k.weight)
    }

    func socialFree(_ b: Bug) -> Bool {
        b.free && !b.rare && onScreen(b) && edgeDistance(b.x, b.y) > b.size * 1.2 && time >= b.lureCalm
    }

    func scheduleSocial(_ h: Double) {
        let t = tuning
        stage.social.clock -= h
        stage.social.watchGap -= h
        stage.social.ripples = 0
        for k in SocialKind.allCases {
            if let v = stage.social.cooldown[k], v > 0 { stage.social.cooldown[k] = v - h }
        }
        guard t.socialEnabled else { return }
        if stage.census.stray >= 0 && stage.social.watchGap <= 0 && light < 1 { watchStray() }
        guard stage.social.clock <= 0 else { return }
        stage.social.clock = socialRng.range(t.socialTick)
        guard stage.visible >= 1, max(light, targetLight) < t.duskLight, !isJiggling, darkSeconds >= t.socialAfter else { return }
        let cap = min(max(0, t.socialMax), max(2, Int(Double(stage.visible) * max(0, t.socialShare))))
        let room = cap - stage.census.social
        guard room > 0 else { return }
        guard t.forceSocial != nil || socialRng.chance(t.socialChance) else { return }
        var options = socialOptions(room: room)
        var tries = 0
        while !options.isEmpty && tries < 3 {
            tries += 1
            var total = 0.0
            for o in options { total += o.1 }
            guard total > 0 else { return }
            var roll = socialRng.unit() * total
            var chosen = options.count - 1
            for (n, o) in options.enumerated() {
                roll -= o.1
                if roll <= 0 {
                    chosen = n
                    break
                }
            }
            let kind = options[chosen].0
            if startSocial(kind, room: room) {
                stage.social.cooldown[kind] = socialRng.range(t.socialCooldown)
                return
            }
            options.remove(at: chosen)
        }
    }

    private func socialOptions(room: Int) -> [(SocialKind, Double)] {
        let t = tuning
        let deep = lidAngle < t.deepAngle
        var present = Set<Species>()
        var free = 0
        for b in bugs where b.mode != .hidden && socialFree(b) {
            present.insert(b.species)
            free += 1
        }
        var out: [(SocialKind, Double)] = []
        let kinds: [SocialKind] = t.forceSocial.map { [$0] } ?? SocialKind.allCases
        for k in kinds where k.weight > 0 {
            if t.forceSocial == nil {
                if (stage.social.cooldown[k] ?? 0) > 0 { continue }
                if socialWeight(k) <= 0 { continue }
            }
            if k.room > room { continue }
            if k.grouped && (stage.census.kinds[k] ?? 0) > 0 { continue }
            if !k.grouped && (stage.census.kinds[k] ?? 0) >= 2 { continue }
            var ok = free >= max(1, k.room - (k == .nudge || k == .admire ? 1 : 0))
            switch k {
            case .duet: ok = ok && deep && playingNow() + 2 <= playCap()
            case .nudge: ok = ok && deep && stage.census.sleepers > 0
            case .visit: ok = ok && present.contains { isVisitor($0) }
            case .admire: ok = ok && stage.census.rare >= 0
            case .race: ok = ok && (present.contains(.snail) || present.contains(.crab))
            case .roll: ok = ok && present.contains { rolls($0) }
            case .slide: ok = ok && present.contains(.penguin)
            case .bob: ok = ok && present.contains(.balloon)
            case .peekaboo: ok = ok && present.contains(.ghost)
            case .rainDance:
                let wet = config.weather == .rain || config.weather == .storm
                ok = ok && wet && present.contains(.frog) && playingNow() < playCap() + (deep ? 0 : 1)
            default: break
            }
            if ok { out.append((k, t.forceSocial == nil ? socialWeight(k) : 1)) }
        }
        return out
    }

    func isVisitor(_ s: Species) -> Bool {
        switch s {
        case .butterfly, .bumblebee, .firefly, .bat, .dragonfly, .cloud, .sun: return true
        default: return false
        }
    }

    func rolls(_ s: Species) -> Bool {
        s == .hedgehog || s == .acorn || s == .pumpkin
    }

    private func candidates(_ test: (Bug) -> Bool) -> [Int] {
        var pool = stage.picks
        pool.removeAll(keepingCapacity: true)
        for i in bugs.indices where bugs[i].mode != .hidden && socialFree(bugs[i]) && test(bugs[i]) { pool.append(i) }
        return pool
    }

    private func pickSeed(_ test: (Bug) -> Bool) -> Int? {
        let pool = candidates(test)
        defer { stage.picks = pool }
        guard !pool.isEmpty else { return nil }
        return pool[min(pool.count - 1, Int(socialRng.unit() * Double(pool.count)))]
    }

    private func neighbours(of i: Int, within radius: Double, limit: Int, _ test: (Bug) -> Bool) -> [Int] {
        let a = bugs[i]
        var found: [(Int, Double)] = []
        for j in bugs.indices where j != i {
            let b = bugs[j]
            guard b.mode != .hidden else { continue }
            let dx = b.x - a.x
            if dx > radius || dx < -radius { continue }
            let dy = b.y - a.y
            if dy > radius || dy < -radius { continue }
            let d = hypot(dx, dy)
            guard d <= radius, socialFree(b), test(b) else { continue }
            found.append((j, d))
        }
        found.sort { $0.1 != $1.1 ? $0.1 < $1.1 : bugs[$0.0].id < bugs[$1.0].id }
        return found.prefix(max(0, limit)).map(\.0)
    }

    private func newGroup(_ kind: SocialKind, _ members: [Int]) -> SocialGroup {
        stage.social.serial += 1
        return SocialGroup(id: stage.social.serial, kind: kind, members: members.map { bugs[$0].id })
    }

    func groupIndex(_ id: Int) -> Int? {
        stage.social.groups.firstIndex { $0.id == id }
    }

    func startSocial(_ kind: SocialKind, room: Int) -> Bool {
        switch kind {
        case .stroll: return startStroll()
        case .string: return startString(room: room)
        case .tag: return startTag(room: room)
        case .huddle: return startHuddle(room: room)
        case .duet: return startDuet()
        case .nudge: return startNudge()
        case .visit: return startVisit()
        case .admire: return startAdmire(room: room)
        case .race: return startRace()
        case .roll, .slide, .bob, .rainDance: return startSolo(kind)
        case .peekaboo: return startPeekaboo()
        case .watch, .flinch: return false
        }
    }

    func safeGoal(_ b: Bug, angle: Double, distance: Double) -> (x: Double, y: Double) {
        let m = max(b.size * 2.5, 60)
        var a = angle
        var best = (x: b.x, y: b.y)
        for k in 0..<6 {
            let x = b.x + cos(a) * distance, y = b.y + sin(a) * distance
            best = (min(max(x, m), max(m, width - m)), min(max(y, m), max(m, height - m)))
            if x > m && x < width - m && y > m && y < height - m { return (x, y) }
            a += (k % 2 == 0 ? 1 : -1) * Double(k + 1) * 0.7
        }
        return best
    }

    private func startStroll() -> Bool {
        let t = tuning
        guard let i = pickSeed({ $0.species.locomotion != .dart }) else { return false }
        let air = bugs[i].species.isAirborne
        guard let j = neighbours(of: i, within: t.strollReach, limit: 1, { $0.species.locomotion != .dart && $0.species.isAirborne == air }).first else { return false }
        let pa = paceOf(bugs[i], t.traits(for: bugs[i].species)), pb = paceOf(bugs[j], t.traits(for: bugs[j].species))
        var g = newGroup(.stroll, [i, j])
        g.length = socialRng.range(t.strollLength)
        g.pace = max(10, min(pa, pb) * 0.8)
        let lead = bugs[i]
        let goal = safeGoal(lead, angle: lead.course + socialRng.gauss() * 0.5, distance: socialRng.range(220...360))
        var s = Social(kind: .stroll, group: g.id, role: 0)
        s.x = goal.x
        s.y = goal.y
        s.pace = g.pace
        bugs[i].social = s
        var f = Social(kind: .stroll, group: g.id, role: 1, target: lead.id)
        let side = cos(lead.course) * (bugs[j].y - lead.y) - sin(lead.course) * (bugs[j].x - lead.x)
        f.sign = side >= 0 ? 1 : -1
        f.offset = (lead.size + bugs[j].size) * 0.62 + 4
        f.pace = g.pace
        bugs[j].social = f
        stage.social.groups.append(g)
        return true
    }

    private func startString(room: Int) -> Bool {
        let t = tuning
        guard let i = pickSeed({ $0.species.locomotion != .dart && $0.species.locomotion != .float }) else { return false }
        let air = bugs[i].species.isAirborne
        let lo = max(3, t.stringSize.lowerBound), hi = max(lo, t.stringSize.upperBound)
        let size = min(room, lo + Int(socialRng.unit() * Double(hi - lo + 1)))
        guard size >= 3 else { return false }
        let others = neighbours(of: i, within: 260, limit: size - 1, { $0.species.locomotion != .dart && $0.species.locomotion != .float && $0.species.isAirborne == air })
        guard others.count >= 2 else { return false }
        var g = newGroup(.string, [i] + others)
        g.length = socialRng.range(t.stringLength)
        var pace = paceOf(bugs[i], t.traits(for: bugs[i].species))
        for j in others { pace = min(pace, paceOf(bugs[j], t.traits(for: bugs[j].species))) }
        g.pace = max(10, pace * 0.8)
        let lead = bugs[i]
        let goal = safeGoal(lead, angle: lead.course, distance: socialRng.range(160...300))
        var s = Social(kind: .string, group: g.id, role: 0)
        s.x = goal.x
        s.y = goal.y
        s.pace = g.pace
        bugs[i].social = s
        var ahead = lead
        for j in others {
            var f = Social(kind: .string, group: g.id, role: 1, target: ahead.id)
            f.spacing = (ahead.size + bugs[j].size) * 0.62 + 6
            f.pace = g.pace
            bugs[j].social = f
            ahead = bugs[j]
        }
        stage.social.groups.append(g)
        return true
    }

    private func tagReady(_ b: Bug) -> Bool {
        let loc = b.species.locomotion
        guard loc != .dart && loc != .float else { return false }
        return paceOf(b, tuning.traits(for: b.species)) >= 22
    }

    private func startTag(room: Int) -> Bool {
        let t = tuning
        guard let i = pickSeed({ self.tagReady($0) }) else { return false }
        let air = bugs[i].species.isAirborne
        let want = room >= 3 && socialRng.chance(0.5) ? 2 : 1
        let others = neighbours(of: i, within: 200, limit: want, { self.tagReady($0) && $0.species.isAirborne == air })
        guard !others.isEmpty else { return false }
        let all = [i] + others
        var g = newGroup(.tag, all)
        g.length = socialRng.range(t.tagLength)
        var pace = Double.infinity
        var cx = 0.0, cy = 0.0
        for j in all {
            pace = min(pace, paceOf(bugs[j], t.traits(for: bugs[j].species)))
            cx += bugs[j].x
            cy += bugs[j].y
        }
        g.pace = min(80, max(22, pace))
        g.radius = t.tagRadius
        let m = min(g.radius * 0.6, min(width, height) * 0.3)
        g.x = min(max(cx / Double(all.count), m), width - m)
        g.y = min(max(cy / Double(all.count), m), height - m)
        g.it = bugs[i].id
        g.freeze = 0.9
        for (n, j) in all.enumerated() {
            var s = Social(kind: .tag, group: g.id, role: n)
            s.sign = n % 2 == 0 ? 1 : -1
            bugs[j].social = s
        }
        stage.social.groups.append(g)
        return true
    }

    private func startHuddle(room: Int) -> Bool {
        let t = tuning
        guard let i = pickSeed({ !$0.species.isAirborne }) else { return false }
        let lo = max(3, t.huddleSize.lowerBound), hi = max(lo, t.huddleSize.upperBound)
        let size = min(room, lo + Int(socialRng.unit() * Double(hi - lo + 1)))
        guard size >= 3 else { return false }
        let others = neighbours(of: i, within: 280, limit: size - 1, { !$0.species.isAirborne })
        guard others.count >= 2 else { return false }
        let all = [i] + others
        var cx = 0.0, cy = 0.0, avg = 0.0
        for j in all {
            cx += bugs[j].x
            cy += bugs[j].y
            avg += bugs[j].size
        }
        let n = Double(all.count)
        avg /= n
        var g = newGroup(.huddle, [])
        g.radius = max(avg * 0.85, n * avg * 0.95 / (2 * .pi)) + 4
        let m = g.radius * 1.3 + avg * 1.5
        g.x = min(max(cx / n, m), max(m, width - m))
        g.y = min(max(cy / n, m), max(m, height - m))
        g.length = socialRng.range(t.huddleChat)
        let ordered = all.sorted { atan2(bugs[$0].y - g.y, bugs[$0].x - g.x) < atan2(bugs[$1].y - g.y, bugs[$1].x - g.x) }
        g.members = ordered.map { bugs[$0].id }
        let base = atan2(bugs[ordered[0]].y - g.y, bugs[ordered[0]].x - g.x)
        for (k, j) in ordered.enumerated() {
            var s = Social(kind: .huddle, group: g.id, role: k)
            s.angle = base + 2 * .pi * Double(k) / n
            s.x = g.x + cos(s.angle) * g.radius * 1.25
            s.y = g.y + sin(s.angle) * g.radius * 0.6
            s.pace = max(12, paceOf(bugs[j], t.traits(for: bugs[j].species)) * 0.8)
            bugs[j].social = s
        }
        stage.social.groups.append(g)
        return true
    }

    private func startDuet() -> Bool {
        let t = tuning
        guard let i = pickSeed({ $0.species.locomotion != .dart }) else { return false }
        let air = bugs[i].species.isAirborne
        guard let j = neighbours(of: i, within: 220, limit: 1, { $0.species.locomotion != .dart && $0.species.isAirborne == air }).first else { return false }
        var g = newGroup(.duet, [i, j])
        g.length = socialRng.range(t.duetLength)
        let a = bugs[i], b = bugs[j]
        let mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2
        var dx = b.x - a.x, dy = (b.y - a.y) * 0.3
        let d = max(1e-6, hypot(dx, dy))
        dx /= d
        dy /= d
        let gap = (a.size + b.size) * 0.55 + 6
        for (n, k) in [i, j].enumerated() {
            var s = Social(kind: .duet, group: g.id, role: n)
            let sgn: Double = n == 0 ? -1 : 1
            s.x = mx + sgn * dx * gap / 2
            s.y = my + sgn * dy * gap / 2
            s.pace = max(12, paceOf(bugs[k], t.traits(for: bugs[k].species)) * 0.8)
            s.target = bugs[n == 0 ? j : i].id
            bugs[k].social = s
        }
        stage.social.groups.append(g)
        return true
    }

    private func startNudge() -> Bool {
        let t = tuning
        var sleeper = -1
        var best = -1.0
        for i in bugs.indices {
            let b = bugs[i]
            guard b.mode != .hidden, let a = b.act, a.kind == .sleep, !a.waking, a.delay <= 0, a.clock >= t.nudgeAfter, onScreen(b) else { continue }
            let u = socialRng.unit()
            if u > best {
                best = u
                sleeper = i
            }
        }
        guard sleeper >= 0 else { return false }
        guard let j = neighbours(of: sleeper, within: 360, limit: 1, { !$0.species.isAirborne && $0.species.stance == .upright }).first else { return false }
        let g = newGroup(.nudge, [j, sleeper])
        var s = Social(kind: .nudge, group: g.id, role: 0, target: bugs[sleeper].id)
        s.sign = bugs[j].x >= bugs[sleeper].x ? 1 : -1
        s.pace = max(12, paceOf(bugs[j], t.traits(for: bugs[j].species)) * 0.9)
        bugs[j].social = s
        stage.social.groups.append(g)
        return true
    }

    private func startVisit() -> Bool {
        let t = tuning
        guard let i = pickSeed({ self.isVisitor($0.species) }) else { return false }
        guard let j = neighbours(of: i, within: 420, limit: 1, { $0.mode == .resting && !$0.species.isAirborne }).first else { return false }
        var g = newGroup(.visit, [i, j])
        let shade = bugs[i].species == .cloud || bugs[i].species == .sun
        g.length = socialRng.range(shade ? t.shadeLength : t.visitLength)
        var v = Social(kind: .visit, group: g.id, role: 0, target: bugs[j].id)
        v.pace = min(130, max(30, paceOf(bugs[i], t.traits(for: bugs[i].species)) * (shade ? 1.6 : 1.4)))
        v.sign = socialRng.chance(0.5) ? 1 : -1
        bugs[i].social = v
        bugs[j].social = Social(kind: .visit, group: g.id, role: 1, target: bugs[i].id)
        stage.social.groups.append(g)
        return true
    }

    private func startAdmire(room: Int) -> Bool {
        let t = tuning
        guard let r = index(of: stage.census.rare) else { return false }
        let star = bugs[r]
        guard star.calm, star.mode != .emerging, !star.ownScript, onScreen(star) else { return false }
        let lo = max(1, t.admireSize.lowerBound), hi = max(lo, t.admireSize.upperBound)
        let want = min(room, lo + Int(socialRng.unit() * Double(hi - lo + 1)))
        let fans = neighbours(of: r, within: 460, limit: want, { _ in true })
        guard !fans.isEmpty else { return false }
        var g = newGroup(.admire, [r] + fans)
        g.length = socialRng.range(t.admireLength)
        var cx = 0.0, cy = 0.0
        for j in fans {
            cx += bugs[j].x
            cy += bugs[j].y
        }
        let n = Double(fans.count)
        g.angle = atan2(cy / n - star.y, cx / n - star.x)
        for (k, j) in fans.enumerated() {
            var s = Social(kind: .admire, group: g.id, role: k + 1, target: star.id)
            s.angle = (Double(k) - (n - 1) / 2) * 0.55
            s.offset = (star.size + bugs[j].size) * 0.75 + 36
            s.pace = max(12, paceOf(bugs[j], t.traits(for: bugs[j].species)) * 0.8)
            bugs[j].social = s
            if g.waver < 0 && !bugs[j].species.isAirborne && bugs[j].species.stance == .upright && socialRng.chance(0.6) {
                g.waver = bugs[j].id
            }
        }
        stage.social.groups.append(g)
        return true
    }

    private func startRace() -> Bool {
        let t = tuning
        guard let i = pickSeed({ $0.species == .snail || $0.species == .crab }) else { return false }
        let kind = bugs[i].species
        guard let j = neighbours(of: i, within: 220, limit: 1, { $0.species == kind }).first else { return false }
        var g = newGroup(.race, [i, j])
        g.length = socialRng.range(t.raceLength)
        let a = bugs[i]
        let near = nearestEdge(a.x, a.y)
        var dir = alongDirection(near)
        let ahead = along(a.x, a.y, on: near)
        if ahead > span(near) / 2 { dir += .pi }
        g.angle = wrap(dir + socialRng.signed() * 0.25)
        for (n, k) in [i, j].enumerated() {
            var s = Social(kind: .race, group: g.id, role: n)
            s.pace = max(6, paceOf(bugs[k], t.traits(for: bugs[k].species)) * 1.6)
            bugs[k].social = s
        }
        stage.social.groups.append(g)
        return true
    }

    private func startSolo(_ kind: SocialKind) -> Bool {
        let t = tuning
        let test: (Bug) -> Bool
        switch kind {
        case .roll: test = { self.rolls($0.species) }
        case .slide: test = { $0.species == .penguin }
        case .bob: test = { $0.species == .balloon }
        default: test = { $0.species == .frog }
        }
        guard let i = pickSeed(test) else { return false }
        var b = bugs[i]
        var s = Social(kind: kind)
        switch kind {
        case .roll, .slide:
            let dist = b.size * (kind == .roll ? socialRng.range(t.rollDistance) : socialRng.range(3...4.5))
            let goal = safeGoal(b, angle: socialRng.unit() * 2 * .pi, distance: dist)
            s.angle = atan2(goal.y - b.y, goal.x - b.x)
            s.offset = hypot(goal.x - b.x, goal.y - b.y)
            guard s.offset > b.size else { return false }
            s.length = kind == .roll ? 0.62 : 0.3
            if kind == .roll { s.gesture = .tumble }
        case .bob:
            let room = height - b.y - b.size * 1.2
            s.offset = min(b.size * socialRng.range(t.bobHeight), room)
            guard s.offset > b.size * 0.5 else { return false }
            s.length = 0.9
        default:
            s.length = socialRng.range(t.rainDanceLength)
            s.gesture = .cheer
            s.sign = socialRng.chance(0.5) ? 1 : -1
        }
        b.social = s
        b.mode = .resting
        bugs[i] = b
        return true
    }

    private func startPeekaboo() -> Bool {
        let t = tuning
        guard let i = pickSeed({ $0.species == .ghost }) else { return false }
        guard let j = neighbours(of: i, within: t.peekabooReach, limit: 1, { $0.species != .ghost }).first else { return false }
        let g = newGroup(.peekaboo, [i, j])
        var s = Social(kind: .peekaboo, group: g.id, role: 0, target: bugs[j].id)
        s.sign = bugs[i].x <= bugs[j].x ? -1 : 1
        s.pace = min(90, max(40, paceOf(bugs[i], t.traits(for: bugs[i].species)) * 2.5))
        bugs[i].social = s
        bugs[j].social = Social(kind: .peekaboo, group: g.id, role: 1, target: bugs[i].id)
        stage.social.groups.append(g)
        return true
    }

    private func watchStray() {
        let t = tuning
        stage.social.watchGap = 1.5
        guard let si = index(of: stage.census.stray) else { return }
        let watchers = neighbours(of: si, within: 420, limit: 2, { _ in true })
        for j in watchers {
            var s = Social(kind: .watch, target: bugs[si].id)
            s.length = socialRng.range(t.watchLength)
            s.gesture = .look
            bugs[j].social = s
        }
    }

    func ripple(fromX x: Double, y: Double, except id: Int) {
        let t = tuning
        guard t.socialEnabled, t.flinchEnabled, t.flinchMax > 0, stage.social.ripples < 3 else { return }
        stage.social.ripples += 1
        let r = max(1, t.flinchRadius)
        var best: [(Int, Double)] = []
        for j in bugs.indices {
            let b = bugs[j]
            guard b.mode != .hidden, b.id != id else { continue }
            let dx = b.x - x
            if dx > r || dx < -r { continue }
            let dy = b.y - y
            if dy > r || dy < -r { continue }
            let d = hypot(dx, dy)
            guard d <= r, d > 1, lureable(b), b.lure == nil, b.perch == nil, b.act == nil, b.job == nil, b.social == nil || b.social?.kind == .watch else { continue }
            best.append((j, d))
        }
        guard !best.isEmpty else { return }
        best.sort { $0.1 != $1.1 ? $0.1 < $1.1 : bugs[$0.0].id < bugs[$1.0].id }
        for (j, d) in best.prefix(t.flinchMax) {
            var b = bugs[j]
            clearOwn(&b)
            var s = Social(kind: .flinch)
            s.delay = 0.06 + d / 420
            s.x = x
            s.y = y
            b.social = s
            b.mode = .resting
            bugs[j] = b
        }
    }

    func runGroups(_ h: Double) {
        guard !stage.social.groups.isEmpty else { return }
        let t = tuning
        var k = stage.social.groups.count - 1
        var slots = stage.social.slots
        while k >= 0 {
            var g = stage.social.groups[k]
            g.clock += h
            g.total += h
            slots.removeAll(keepingCapacity: true)
            var alive = 0
            for (n, id) in g.members.enumerated() {
                if let i = index(of: id), bugs[i].mode != .hidden, belongs(bugs[i], to: g, slot: n) {
                    slots.append(i)
                    alive += 1
                } else {
                    slots.append(-1)
                }
            }
            var viable: Bool
            switch g.kind {
            case .admire: viable = slots[0] >= 0 && alive >= 2
            case .nudge: viable = slots[0] >= 0 && slots.count > 1 && slots[1] >= 0
            case .string: viable = slots[0] >= 0 && alive >= 2
            case .huddle: viable = alive >= 2
            default: viable = alive == g.members.count
            }
            if max(light, targetLight) > t.duskLight || isJiggling || g.total > t.socialMaxSeconds { viable = false }
            if viable { advance(&g, slots, h) }
            if !viable || g.stage < 0 {
                dissolve(g, slots)
                stage.social.groups.remove(at: k)
            } else {
                stage.social.groups[k] = g
            }
            k -= 1
        }
        stage.social.slots = slots
    }

    private func belongs(_ b: Bug, to g: SocialGroup, slot n: Int) -> Bool {
        if g.kind == .nudge && n == 1 {
            guard let a = b.act else { return false }
            return a.kind == .sleep || a.waking
        }
        if g.kind == .admire && n == 0 { return b.calm && b.mode != .emerging }
        return b.social?.group == g.id
    }

    private func dissolve(_ g: SocialGroup, _ slots: [Int]) {
        for (n, i) in slots.enumerated() where i >= 0 {
            guard bugs[i].social?.group == g.id else { continue }
            bugs[i].social?.ending = true
            switch g.kind {
            case .huddle:
                let a = atan2(bugs[i].y - g.y, bugs[i].x - g.x) + socialRng.signed() * 0.3
                bugs[i].social?.away = a
            case .string, .tag, .stroll:
                if n > 0 {
                    let a = bugs[i].course + (n % 2 == 0 ? 1 : -1) * socialRng.range(0.6...1.4)
                    bugs[i].social?.away = a
                }
            default:
                break
            }
        }
    }

    private func advance(_ g: inout SocialGroup, _ slots: [Int], _ h: Double) {
        let t = tuning
        switch g.kind {
        case .stroll:
            if g.stage == 0 && g.clock >= g.length {
                g.stage = 1
                g.clock = 0
            } else if g.stage == 1 && g.clock >= 1.0 {
                g.stage = -1
            }
        case .string:
            var ahead = -1
            for i in slots {
                guard i >= 0 else { continue }
                if ahead >= 0, bugs[i].social?.target != bugs[ahead].id {
                    let id = bugs[ahead].id
                    let gap = (bugs[ahead].size + bugs[i].size) * 0.62 + 6
                    bugs[i].social?.target = id
                    bugs[i].social?.spacing = gap
                }
                ahead = i
            }
            if g.stage == 0 && g.clock >= g.length {
                g.stage = 1
                g.clock = 0
            } else if g.stage == 1 && g.clock >= 0.9 {
                g.stage = -1
            }
        case .tag:
            if g.stage == 0 {
                g.freeze -= h
                if g.freeze <= 0, let itIndex = index(of: g.it) {
                    let it = bugs[itIndex]
                    for i in slots where i >= 0 && i != itIndex {
                        let r = bugs[i]
                        if hypot(r.x - it.x, r.y - it.y) < (r.size + it.size) * 0.55 + 4 {
                            g.it = r.id
                            g.freeze = 0.9
                            g.tags += 1
                            break
                        }
                    }
                }
                if g.clock >= g.length || g.tags >= max(1, t.tagTouches) {
                    g.stage = 1
                    g.clock = 0
                }
            } else if g.clock >= 1.0 {
                g.stage = -1
            }
        case .huddle:
            if g.stage == 0 {
                var arrived = true
                for i in slots where i >= 0 && (bugs[i].social?.count ?? 0) == 0 { arrived = false }
                if arrived || g.clock > 6 {
                    g.stage = 1
                    g.clock = 0
                    g.beat = 0.4
                }
            } else {
                g.beat -= h
                if g.beat <= 0 {
                    g.beat = socialRng.range(0.9...1.6)
                    let live = slots.filter { $0 >= 0 }
                    if !live.isEmpty {
                        let speaker = live[min(live.count - 1, Int(socialRng.unit() * Double(live.count)))]
                        if bugs[speaker].social?.stage == 0 {
                            let hopper = bugs[speaker].species.locomotion == .hop
                            bugs[speaker].social?.stage = hopper && socialRng.chance(0.35) ? 2 : 1
                            bugs[speaker].social?.clock = 0
                        }
                        if live.count > 2 && socialRng.chance(0.45) {
                            let other = live[min(live.count - 1, Int(socialRng.unit() * Double(live.count)))]
                            if other != speaker && bugs[other].facingHold <= 0 {
                                let f: Double = bugs[speaker].x > bugs[other].x ? 1 : -1
                                if f != bugs[other].facing {
                                    bugs[other].facing = f
                                    bugs[other].facingHold = 0.6
                                }
                            }
                        }
                    }
                }
                if g.clock >= g.length { g.stage = -1 }
            }
        case .duet:
            if g.stage == 0 {
                var arrived = true
                for i in slots where i >= 0 && (bugs[i].social?.count ?? 0) == 0 { arrived = false }
                if arrived || g.clock > 4 {
                    g.stage = 1
                    g.clock = 0
                }
            } else if g.clock >= g.length {
                g.stage = -1
            }
        case .admire, .race:
            if g.kind == .race {
                if g.stage == 0 && g.clock >= 1.2 {
                    g.stage = 1
                    g.clock = 0
                } else if g.stage == 1 && g.clock >= g.length {
                    g.stage = 2
                    g.clock = 0
                    var best = -Double.infinity
                    for i in slots where i >= 0 {
                        let p = bugs[i].x * cos(g.angle) + bugs[i].y * sin(g.angle)
                        if p > best {
                            best = p
                            g.it = bugs[i].id
                        }
                    }
                } else if g.stage == 2 && g.clock >= 1.4 {
                    g.stage = -1
                }
            } else if g.clock >= g.length {
                g.stage = -1
            }
        case .nudge, .visit, .peekaboo, .roll, .slide, .bob, .rainDance, .watch, .flinch:
            break
        }
    }

    func socialStep(_ b: inout Bug, tr: SpeciesTraits, h: Double) -> Double {
        guard var s = b.social else { return 0 }
        let t = tuning
        if s.ending || (!s.kind.grouped && s.kind != .flinch && s.kind != .watch && max(light, targetLight) > t.duskLight) {
            endSocial(&b, s, tr: tr)
            return 0
        }
        s.clock += h
        var gi: Int?
        if s.kind.grouped {
            gi = groupIndex(s.group)
            if gi == nil {
                endSocial(&b, s, tr: tr)
                return 0
            }
        }
        var done = false
        switch s.kind {
        case .stroll: done = strollStep(&b, &s, gi!, tr: tr, h: h)
        case .string: done = stringStep(&b, &s, gi!, tr: tr, h: h)
        case .tag: done = tagStep(&b, &s, gi!, tr: tr, h: h)
        case .huddle: done = huddleStep(&b, &s, gi!, tr: tr, h: h)
        case .duet: done = duetStep(&b, &s, gi!, tr: tr, h: h)
        case .nudge: done = nudgeStep(&b, &s, gi!, tr: tr, h: h)
        case .visit: done = visitStep(&b, &s, gi!, tr: tr, h: h)
        case .admire: done = admireStep(&b, &s, gi!, tr: tr, h: h)
        case .race: done = raceStep(&b, &s, gi!, tr: tr, h: h)
        case .peekaboo: done = peekabooStep(&b, &s, gi!, tr: tr, h: h)
        case .roll, .slide: done = rollStep(&b, &s, tr: tr, h: h)
        case .bob: done = bobStep(&b, &s, tr: tr, h: h)
        case .rainDance: done = rainStep(&b, &s, tr: tr, h: h)
        case .watch: done = watchStep(&b, &s, tr: tr, h: h)
        case .flinch: done = flinchStep(&b, &s, tr: tr, h: h)
        }
        if done {
            endSocial(&b, s, tr: tr)
        } else if b.social != nil {
            b.social = s
        }
        return 0
    }

    private func endSocial(_ b: inout Bug, _ s: Social, tr: SpeciesTraits) {
        b.social = nil
        if !b.fading && b.alpha < 1 { b.alpha = 1 }
        resume(&b, tr: tr, toward: s.away)
    }

    private func other(_ id: Int) -> Bug? {
        guard let i = index(of: id), bugs[i].mode != .hidden else { return nil }
        return bugs[i]
    }

    private func moveMode(_ b: inout Bug) {
        b.mode = b.speed > 1 || b.lift > 0 ? .wandering : .resting
    }

    private func strollStep(_ b: inout Bug, _ s: inout Social, _ gi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        let g = stage.social.groups[gi]
        if g.stage == 1 {
            b.mode = .resting
            if let m = other(s.role == 0 ? g.members[1] : g.members[0]) {
                gaze(&b, tr: tr, x: m.x, y: m.y, h: h)
            } else {
                settleStill(&b, tr: tr, h: h)
            }
            s.gesture = .look
            return false
        }
        s.gesture = .none
        if s.role == 0 {
            var pace = s.pace
            if let m = other(g.members[1]), hypot(m.x - b.x, m.y - b.y) > (m.size + b.size) * 2.5 { pace *= 0.4 }
            let d = seek(&b, x: s.x, y: s.y, pace: pace, tr: tr, h: h, arrive: 0)
            if d < 40 {
                let goal = safeGoal(b, angle: b.course + socialRng.signed() * 1.1, distance: socialRng.range(200...320))
                s.x = goal.x
                s.y = goal.y
            }
        } else {
            guard let lead = other(s.target) else { return true }
            let th = lead.course
            let tx = lead.x + cos(th + s.sign * .pi / 2) * s.offset - cos(th) * 4
            let ty = lead.y + sin(th + s.sign * .pi / 2) * s.offset - sin(th) * 4
            let d = hypot(tx - b.x, ty - b.y)
            if d > 10 {
                _ = seek(&b, x: tx, y: ty, pace: s.pace * 1.8, tr: tr, h: h, arrive: 0)
            } else {
                steer(&b, toward: th, rate: max(3, tr.turnRate), h: h)
                approach(&b.speed, lead.speed, rate: s.pace / 0.2, h: h)
            }
        }
        b.mode = .wandering
        return false
    }

    private func stringStep(_ b: inout Bug, _ s: inout Social, _ gi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        let g = stage.social.groups[gi]
        if g.stage == 1 {
            settleStill(&b, tr: tr, h: h)
            b.mode = .resting
            if s.role == 0 {
                if let last = other(g.members[g.members.count - 1]) { gaze(&b, tr: tr, x: last.x, y: last.y, h: h) }
                s.gesture = .look
            } else {
                s.gesture = .none
            }
            return false
        }
        s.gesture = .none
        if s.role == 0 {
            let d = seek(&b, x: s.x, y: s.y, pace: s.pace, tr: tr, h: h, arrive: 0, turn: 2.2)
            if d < 30 || s.clock > 6 {
                s.clock = 0
                let turn = socialRng.range(0.5...1.3) * (socialRng.chance(0.5) ? 1 : -1)
                let goal = safeGoal(b, angle: b.course + turn, distance: socialRng.range(160...300))
                s.x = goal.x
                s.y = goal.y
            }
        } else {
            guard let a = other(s.target) else { return true }
            let dx = a.x - b.x, dy = a.y - b.y
            let d = hypot(dx, dy)
            if d > 1e-6 { steer(&b, toward: atan2(dy, dx), rate: 7, h: h) }
            let want = d < s.spacing * 0.8 ? 0 : min(s.pace * 1.8, s.pace * d / max(1, s.spacing))
            approach(&b.speed, want, rate: s.pace / 0.2, h: h)
        }
        moveMode(&b)
        return false
    }

    private func tagStep(_ b: inout Bug, _ s: inout Social, _ gi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        let g = stage.social.groups[gi]
        if g.stage == 1 {
            settleStill(&b, tr: tr, h: h)
            b.mode = .resting
            if let it = other(g.it), it.id != b.id { gaze(&b, tr: tr, x: it.x, y: it.y, h: h) }
            s.gesture = .look
            return false
        }
        if b.id == g.it {
            if g.freeze > 0 {
                settleStill(&b, tr: tr, h: h)
                b.mode = .resting
                s.gesture = .look
                return false
            }
            s.gesture = .none
            var target: Bug?
            var best = Double.infinity
            for id in g.members where id != b.id {
                if let r = other(id) {
                    let d = hypot(r.x - b.x, r.y - b.y)
                    if d < best {
                        best = d
                        target = r
                    }
                }
            }
            guard let r = target else { return true }
            let lead = min(0.4, best / max(1, g.pace * 2))
            let px = r.x + cos(r.heading) * r.speed * lead, py = r.y + sin(r.heading) * r.speed * lead
            _ = seek(&b, x: px, y: py, pace: min(150, g.pace * 1.7), tr: tr, h: h, arrive: 0, turn: 7)
            b.mode = .wandering
            return false
        }
        s.gesture = .none
        guard let it = other(g.it) else { return true }
        var vx = 0.0, vy = 0.0
        let dx = b.x - it.x, dy = b.y - it.y
        let d = max(1, hypot(dx, dy))
        let threat = clamp01((280 - d) / 200)
        vx += dx / d * threat
        vy += dy / d * threat
        let ax = g.x - b.x, ay = g.y - b.y
        let da = max(1, hypot(ax, ay))
        let pull = clamp01((da - g.radius * 0.55) / (g.radius * 0.45))
        vx += ax / da * pull * 1.4
        vy += ay / da * pull * 1.4
        let pad = b.size * 2.5
        if b.x < pad { vx += 1 }
        if b.x > width - pad { vx -= 1 }
        if b.y < pad { vy += 1 }
        if b.y > height - pad { vy -= 1 }
        let mag = hypot(vx, vy)
        if mag > 0.05 {
            let wiggle = 0.5 * sin(s.clock * 1.4 + s.sign * 2)
            steer(&b, toward: atan2(vy, vx) + wiggle, rate: max(4, tr.turnRate * 1.8), h: h)
        }
        let run = min(130, g.pace * 1.45) * (threat > 0.05 ? 1 : 0.35)
        approach(&b.speed, run, rate: max(run, 30) / 0.15, h: h)
        moveMode(&b)
        return false
    }

    private func huddleStep(_ b: inout Bug, _ s: inout Social, _ gi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        let g = stage.social.groups[gi]
        let d = hypot(s.x - b.x, s.y - b.y)
        if g.stage == 0 {
            s.gesture = .none
            if s.count == 0 {
                _ = seek(&b, x: s.x, y: s.y, pace: s.pace, tr: tr, h: h, arrive: 4)
                moveMode(&b)
                if d <= 5 { s.count = 1 }
            } else {
                b.mode = .resting
                gaze(&b, tr: tr, x: g.x, y: g.y, h: h)
            }
            return false
        }
        switch s.stage {
        case 1:
            s.gesture = .look
            settleStill(&b, tr: tr, h: h)
            b.mode = .resting
            if s.clock >= 1.3 {
                s.stage = 0
                s.clock = 0
            }
        case 2:
            s.gesture = .none
            steer(&b, toward: atan2(g.y - b.y, g.x - b.x), rate: 8, h: h)
            if !s.aloft {
                approach(&b.speed, b.size * 0.6, rate: 200, h: h)
                if b.lift > 0 { s.aloft = true }
            } else if b.lift == 0 {
                s.aloft = false
                s.stage = 3
                s.clock = 0
                b.speed = 0
            }
            b.mode = b.lift > 0 || b.speed > 1 ? .wandering : .resting
            if s.clock > 1.2 {
                s.stage = 3
                s.clock = 0
            }
        case 3:
            s.gesture = .none
            _ = seek(&b, x: s.x, y: s.y, pace: max(12, s.pace * 0.8), tr: tr, h: h, arrive: 3)
            moveMode(&b)
            if d <= 4 || s.clock > 2 {
                s.stage = 0
                s.clock = 0
                b.speed = 0
            }
        default:
            s.gesture = .none
            if d > 8 {
                _ = seek(&b, x: s.x, y: s.y, pace: max(10, s.pace * 0.5), tr: tr, h: h, arrive: 3)
                moveMode(&b)
            } else {
                settleStill(&b, tr: tr, h: h)
                b.mode = .resting
                if b.facingHold <= 0 { faceToward(&b, x: g.x) }
            }
        }
        return false
    }

    private func duetStep(_ b: inout Bug, _ s: inout Social, _ gi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        let g = stage.social.groups[gi]
        let mate = other(s.target)
        if g.stage == 0 {
            s.gesture = .none
            let d = seek(&b, x: s.x, y: s.y, pace: s.pace, tr: tr, h: h, arrive: 4)
            if d <= 6 {
                s.count = 1
                b.mode = .resting
                if let m = mate { gaze(&b, tr: tr, x: m.x, y: m.y, h: h) } else { settleStill(&b, tr: tr, h: h) }
            } else {
                moveMode(&b)
            }
            return false
        }
        if s.gesture != .dance, let m = mate, abs(m.x - b.x) > 2 {
            b.facing = m.x > b.x ? 1 : -1
            b.facingHold = 0.3
        }
        s.gesture = .dance
        b.mode = .resting
        b.backward = false
        if b.species.isAirborne {
            hover(&b, tr: tr, h: h, spin: 2.6, scale: 1.6)
        } else {
            brake(&b, tau: 0.08, h: h)
            if b.species.locomotion == .hop { b.speed = 0 }
        }
        return false
    }

    private func nudgeStep(_ b: inout Bug, _ s: inout Social, _ gi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        let t = tuning
        guard let si = index(of: s.target), bugs[si].mode != .hidden else { return true }
        let sleeper = bugs[si]
        switch s.stage {
        case 0:
            s.gesture = .none
            let tx = sleeper.x + s.sign * (sleeper.size + b.size) * 0.5, ty = sleeper.y
            let d = seek(&b, x: tx, y: ty, pace: s.pace, tr: tr, h: h, arrive: 5)
            moveMode(&b)
            guard sleeper.act?.kind == .sleep else { return true }
            if d <= 6 || s.clock > 8 {
                s.stage = 1
                s.clock = 0
            }
        case 1:
            b.mode = .resting
            gaze(&b, tr: tr, x: sleeper.x, y: sleeper.y, h: h)
            s.gesture = .look
            if s.clock >= 0.8 {
                if var a = bugs[si].act, a.kind == .sleep, !a.waking {
                    a.waking = true
                    a.kind = .look
                    a.clock = 0
                    a.length = socialRng.range(t.wakeLength) + 0.5
                    bugs[si].act = a
                    let f: Double = b.x > sleeper.x ? 1 : -1
                    bugs[si].facing = f
                    bugs[si].facingHold = 0.3
                }
                s.stage = 2
                s.clock = 0
            }
        default:
            settleStill(&b, tr: tr, h: h)
            b.mode = .resting
            s.gesture = .look
            if s.clock >= 1.0 { return true }
        }
        return false
    }

    private func visitStep(_ b: inout Bug, _ s: inout Social, _ gi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        let g = stage.social.groups[gi]
        if s.role == 1 {
            settleStill(&b, tr: tr, h: h)
            b.mode = .resting
            guard let v = other(s.target) else {
                s.gesture = .look
                return s.clock > 0.6
            }
            if g.stage >= 1 {
                s.gesture = .look
                gaze(&b, tr: tr, x: v.x, y: v.y, h: h)
            } else {
                s.gesture = .none
            }
            return false
        }
        guard let host = other(s.target) else { return true }
        let shade = b.species == .cloud || b.species == .sun
        let lift = shade ? host.size * 0.9 + b.size * 0.8 : host.size * 0.8 + b.size * 0.55
        var px = host.x + s.sign * 6, py = min(height - b.size * 0.6, host.y + lift)
        s.gesture = .none
        if s.stage == 0 {
            let d = seek(&b, x: px, y: py, pace: s.pace, tr: tr, h: h, arrive: 0)
            b.mode = .wandering
            if d < 14 || s.clock > 6 {
                s.stage = 1
                s.clock = 0
                stage.social.groups[gi].stage = 1
            }
            return false
        }
        let r = shade ? 4.0 : 10.0
        let w = shade ? 0.8 : 2.4
        px += cos(s.clock * w) * r * s.sign
        py += sin(s.clock * w) * r * 0.5
        _ = seek(&b, x: px, y: py, pace: s.pace * 0.6, tr: tr, h: h, arrive: 0)
        b.mode = .wandering
        if s.clock >= g.length {
            s.away = .pi / 2 + socialRng.signed() * 0.9
            return true
        }
        return false
    }

    private func admireStep(_ b: inout Bug, _ s: inout Social, _ gi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        let g = stage.social.groups[gi]
        guard let star = other(s.target) else { return true }
        let a = g.angle + s.angle
        let pad = b.size * 0.8
        let tx = min(max(star.x + cos(a) * s.offset, pad), width - pad)
        let ty = min(max(star.y + sin(a) * s.offset, pad), height - pad)
        let d = hypot(tx - b.x, ty - b.y)
        if d > (s.gesture == .none ? 10 : 34 + b.size * 0.5) {
            _ = seek(&b, x: tx, y: ty, pace: s.pace, tr: tr, h: h, arrive: 6)
            moveMode(&b)
            s.gesture = .none
            return false
        }
        b.mode = .resting
        gaze(&b, tr: tr, x: star.x, y: star.y, h: h, gap: s.offset)
        let waving = g.waver == b.id && g.clock > 2.5 && g.clock < 4.0
        s.gesture = waving ? .wave : .look
        return false
    }

    private func raceStep(_ b: inout Bug, _ s: inout Social, _ gi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        let g = stage.social.groups[gi]
        switch g.stage {
        case 0:
            s.gesture = .none
            brake(&b, tau: 0.1, h: h)
            steer(&b, toward: g.angle, rate: 3, h: h)
            b.mode = .resting
        case 1:
            s.gesture = .none
            steer(&b, toward: g.angle, rate: 2, h: h)
            approach(&b.speed, s.pace, rate: max(s.pace, 6) / 0.4, h: h)
            let pad = b.size * 2
            if b.x < pad || b.x > width - pad || b.y < pad || b.y > height - pad {
                approach(&b.speed, 0, rate: 60, h: h)
            }
            moveMode(&b)
        default:
            settleStill(&b, tr: tr, h: h)
            b.mode = .resting
            s.gesture = .look
            if b.id == g.it, let loser = g.members.first(where: { $0 != b.id }).flatMap({ other($0) }) {
                gaze(&b, tr: tr, x: loser.x, y: loser.y, h: h)
            }
        }
        return false
    }

    private func peekabooStep(_ b: inout Bug, _ s: inout Social, _ gi: Int, tr: SpeciesTraits, h: Double) -> Bool {
        let g = stage.social.groups[gi]
        if s.role == 1 {
            guard let ghost = other(s.target) else { return s.stage > 0 && s.clock > 0.4 }
            switch s.stage {
            case 0:
                s.gesture = .none
                settleStill(&b, tr: tr, h: h)
                b.mode = .resting
                if g.stage >= 2 {
                    s.stage = 1
                    s.clock = 0
                    s.angle = atan2(b.y - ghost.y, b.x - ghost.x)
                    b.course = s.angle
                    b.backward = !b.species.isAirborne
                    b.speed = min(tuning.fleeSpeedCap, b.size * 3)
                    ripple(fromX: b.x, y: b.y, except: ghost.id)
                }
            case 1:
                s.gesture = .shiver
                b.mode = .resting
                b.course = s.angle
                brake(&b, tau: 0.15, h: h)
                if s.clock >= 0.6 {
                    s.stage = 2
                    s.clock = 0
                    b.backward = false
                }
            default:
                s.gesture = .look
                b.mode = .resting
                gaze(&b, tr: tr, x: ghost.x, y: ghost.y, h: h)
                if s.clock >= 0.8 { return true }
            }
            return false
        }
        guard let victim = other(s.target) else {
            b.alpha = 1
            return true
        }
        if lightRate > 0.3 {
            b.alpha = 1
            return true
        }
        switch s.stage {
        case 0:
            s.gesture = .none
            hover(&b, tr: tr, h: h)
            b.mode = .resting
            let u = min(1, s.clock / 0.6)
            b.alpha = 1 - 0.88 * u
            if u >= 1 {
                s.stage = 1
                s.clock = 0
            }
        case 1:
            s.gesture = .none
            b.alpha = 0.12
            let tx = victim.x + s.sign * (victim.size + b.size) * 0.6, ty = victim.y + b.size * 0.15
            let d = seek(&b, x: tx, y: ty, pace: s.pace, tr: tr, h: h, arrive: 4)
            b.mode = .wandering
            if d < 8 || s.clock > 3.5 {
                s.stage = 2
                s.clock = 0
                stage.social.groups[gi].stage = 2
            }
        case 2:
            s.gesture = .wave
            hover(&b, tr: tr, h: h, spin: 0.3, scale: 0.4)
            b.mode = .resting
            b.alpha = min(1, 0.12 + 0.88 * s.clock / 0.2)
            if abs(victim.x - b.x) > 2 { b.facing = victim.x > b.x ? 1 : -1 }
            b.facingHold = 0.35
            if s.clock >= 1.1 {
                b.alpha = 1
                s.away = atan2(b.y - victim.y, b.x - victim.x)
                return true
            }
        default:
            b.alpha = 1
            return true
        }
        return false
    }

    private func rollStep(_ b: inout Bug, _ s: inout Social, tr: SpeciesTraits, h: Double) -> Bool {
        let cap = tuning.fleeSpeedCap * 0.9
        b.mode = .resting
        switch s.stage {
        case 0:
            if s.kind == .roll {
                let tau = max(0.22, s.offset / cap)
                b.glide = true
                b.course = s.angle
                b.speed = min(cap, s.offset / tau * exp(-s.clock / tau))
                s.gesture = .tumble
                if s.clock >= s.length {
                    s.stage = 2
                    s.clock = 0
                    s.gesture = .look
                    land(&b)
                }
            } else {
                s.gesture = .none
                brake(&b, tau: 0.06, h: h)
                steer(&b, toward: s.angle, rate: 6, h: h)
                if s.clock >= s.length {
                    s.stage = 1
                    s.clock = 0
                    b.course = s.angle
                }
            }
        case 1:
            let tau = max(0.4, s.offset / cap)
            b.glide = true
            b.course = s.angle
            b.speed = min(cap, s.offset / tau * exp(-s.clock / tau))
            s.gesture = .none
            if s.clock >= tau * 2.6 {
                s.stage = 2
                s.clock = 0
                s.gesture = .look
                land(&b)
            }
        default:
            b.glide = false
            s.gesture = .look
            brake(&b, tau: 0.08, h: h)
            if b.species.locomotion == .hop { b.speed = 0 }
            if s.clock >= 0.8 { return true }
        }
        return false
    }

    func land(_ b: inout Bug) {
        b.glide = false
        if b.species.locomotion == .hop {
            b.gaitPhase = b.gaitPhase.rounded(.down)
            b.speed = 0
        }
    }

    private func bobStep(_ b: inout Bug, _ s: inout Social, tr: SpeciesTraits, h: Double) -> Bool {
        hover(&b, tr: tr, h: h, spin: 0.2, scale: 0.4)
        b.mode = .resting
        s.gesture = .none
        var off: Double
        if s.stage == 0 {
            let u = min(1, s.clock / s.length)
            off = s.offset * (1 - (1 - u) * (1 - u))
            if u >= 1 {
                s.stage = 1
                s.clock = 0
            }
        } else {
            off = s.offset * exp(-2.6 * s.clock) * cos(4.2 * s.clock)
        }
        b.y += off - s.prev
        s.prev = off
        return s.stage == 1 && s.clock >= 2.0
    }

    private func rainStep(_ b: inout Bug, _ s: inout Social, tr: SpeciesTraits, h: Double) -> Bool {
        s.gesture = .cheer
        if b.lift == 0 && s.aloft {
            s.aloft = false
            s.sign = -s.sign
            s.count += 1
        }
        if b.lift > 0 { s.aloft = true }
        b.course = wrap(.pi / 2 + s.sign * 1.3)
        let pad = b.size * 1.5
        if b.x < pad { b.course = 0.2 }
        if b.x > width - pad { b.course = .pi - 0.2 }
        b.speed = s.clock < s.length ? b.size * 0.5 : 0
        moveMode(&b)
        return s.clock >= s.length && b.lift == 0
    }

    private func watchStep(_ b: inout Bug, _ s: inout Social, tr: SpeciesTraits, h: Double) -> Bool {
        b.mode = .resting
        s.gesture = .look
        if let o = other(s.target) {
            gaze(&b, tr: tr, x: o.x, y: o.y, h: h)
        } else {
            settleStill(&b, tr: tr, h: h)
        }
        return s.clock >= s.length
    }

    private func flinchStep(_ b: inout Bug, _ s: inout Social, tr: SpeciesTraits, h: Double) -> Bool {
        b.mode = .resting
        if s.delay > 0 {
            s.delay -= h
            s.clock = 0
            s.gesture = .none
            settleStill(&b, tr: tr, h: h)
            if s.delay <= 0 {
                s.angle = atan2(b.y - s.y, b.x - s.x)
                b.course = s.angle
                b.backward = !b.species.isAirborne && b.species.locomotion != .hop
                b.speed = min(tuning.fleeSpeedCap, b.size * 2.6)
                b.facingHold = 0
                faceToward(&b, x: s.x)
            }
            return false
        }
        if s.stage == 0 {
            s.gesture = .shiver
            b.course = s.angle
            brake(&b, tau: 0.14, h: h)
            if b.species.locomotion == .hop {
                if b.lift > 0 {
                    s.aloft = true
                } else if s.aloft {
                    b.speed = 0
                }
            }
            if s.clock >= 0.6 {
                s.stage = 1
                s.clock = 0
                b.backward = false
            }
            return false
        }
        s.gesture = .look
        gaze(&b, tr: tr, x: s.x, y: s.y, h: h)
        return s.clock >= 0.6
    }
}
