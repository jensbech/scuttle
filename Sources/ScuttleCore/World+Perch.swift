import Foundation
import CoreGraphics

enum PerchPhase: Equatable {
    case travel
    case land
    case sit
    case look
    case shuffle
    case jump
    case drop
    case leave
}

enum PerchWay: Equatable {
    case fly
    case hop
    case climb
    case walk
}

struct Perch {
    var phase = PerchPhase.travel
    var way = PerchWay.fly
    var clock = 0.0
    var length = 0.0
    var total = 0.0
    var stay = 0.0
    var top = 0.0
    var x = 0.0
    var lo = 0.0
    var hi = 0.0
    var side = 1.0
    var fromX = 0.0
    var fromY = 0.0
    var toX = 0.0
    var toTop = 0.0
    var hump = 0.0
    var vy = 0.0
    var floor = 0.0
    var dock = false
    var spooked = false
    var exiting = false
    var flipped = false
    var gesture = Gesture.none
}

struct PerchStage {
    var clock = 0.0
}

extension World {
    public var percherCount: Int {
        var n = 0
        for b in bugs where b.mode != .hidden {
            if let p = b.perch, p.phase != .travel { n += 1 }
        }
        return n
    }

    public var perchedIDs: [Int] {
        bugs.filter { b in
            guard b.mode != .hidden, let p = b.perch else { return false }
            return p.phase == .sit || p.phase == .look || p.phase == .shuffle
        }.map(\.id)
    }

    func perchAffinity(_ s: Species) -> Double {
        switch s {
        case .robin, .owl: return 1.0
        case .butterfly: return 0.8
        case .bat: return 0.7
        case .bumblebee, .firefly, .chick, .frog: return 0.6
        case .dragonfly, .blackCat: return 0.5
        case .snowflake, .spider: return 0.4
        case .bunny, .ladybird, .leaf: return 0.3
        case .star: return 0.2
        case .snail: return 0.15
        default: return 0
        }
    }

    func perchWay(_ b: Bug) -> PerchWay {
        if b.species.isAirborne { return .fly }
        switch b.species.locomotion {
        case .hop: return .hop
        case .crawl: return .climb
        default: return b.species == .blackCat ? .hop : .walk
        }
    }

    func isDock(_ r: CGRect) -> Bool {
        Double(r.minY) <= 8 && Double(r.maxY) < height * 0.2 && Double(r.width) >= 200
    }

    func feet(_ b: Bug) -> Double {
        tuning.perchFeet * b.size
    }

    func ledgeAt(x: Double, top: Double, track: Double) -> CGRect? {
        var best: CGRect?
        var bestD = Double.infinity
        for r in surroundings.ledges {
            let maxY = Double(r.maxY), minX = Double(r.minX), maxX = Double(r.maxX)
            guard maxY.isFinite, minX.isFinite, maxX.isFinite else { continue }
            let d = abs(maxY - top)
            guard d <= track, x >= minX - 1, x <= maxX + 1, d < bestD else { continue }
            best = r
            bestD = d
        }
        return best
    }

    private func spotTaken(x: Double, top: Double, size: Double, except id: Int) -> Bool {
        for o in bugs where o.id != id && o.mode != .hidden {
            guard let p = o.perch else { continue }
            let ox = p.phase == .jump ? p.toX : p.x
            let otop = p.phase == .jump ? p.toTop : p.top
            if abs(otop - top) < 6 && abs(ox - x) < (o.size + size) * 0.7 + 6 { return true }
        }
        return false
    }

    private func landing(_ b: Bug, on r: CGRect, near x0: Double) -> Double? {
        let s = b.size
        let lo = Double(r.minX) + s * 0.6, hi = Double(r.maxX) - s * 0.6
        guard hi >= lo else { return nil }
        let top = Double(r.maxY)
        let y = top + feet(b)
        guard y + s * 0.5 <= height, y >= s * 0.5 else { return nil }
        let start = min(max(x0, lo), hi)
        for k in 0..<9 {
            let off = Double((k + 1) / 2) * s * 0.9 * (k % 2 == 0 ? 1 : -1)
            let x = start + off
            guard x >= lo, x <= hi else { continue }
            if !spotTaken(x: x, top: top, size: s, except: b.id) { return x }
        }
        return nil
    }

    func tendPerches(_ h: Double) {
        let t = tuning
        stage.perch.clock -= h
        guard t.perchEnabled, !surroundings.ledges.isEmpty, stage.visible > 0, !isJiggling else { return }
        guard stage.perch.clock <= 0 else { return }
        stage.perch.clock = perchRng.range(t.perchTick)
        let cap = min(max(0, t.perchMax), max(1, Int(Double(stage.visible) * max(0, t.perchShare))))
        guard stage.census.perchers < cap else { return }
        guard t.forcePerch ?? perchRng.chance(t.perchChance) else { return }
        let dockOpen = stage.census.docked < max(0, t.dockMax) && surroundings.ledges.contains { isDock($0) }
        var pool: [(Int, Double)] = []
        var total = 0.0
        for i in bugs.indices {
            let b = bugs[i]
            guard b.mode != .hidden, b.free, onScreen(b), time >= b.perchRest, time >= b.lureCalm else { continue }
            var w = perchAffinity(b.species)
            if w <= 0 && dockOpen && !b.species.isAirborne { w = max(0, t.dockChance) * 0.5 }
            guard w > 0 else { continue }
            pool.append((i, w))
            total += w
        }
        guard total > 0 else { return }
        var roll = perchRng.unit() * total
        var chosen = pool[pool.count - 1].0
        for (i, w) in pool {
            roll -= w
            if roll <= 0 {
                chosen = i
                break
            }
        }
        var b = bugs[chosen]
        guard let pick = chooseLedge(b, dockOpen: dockOpen, range: t.perchRange, from: (b.x, b.y), except: nil) else {
            bugs[chosen].perchRest = time + 4
            return
        }
        var p = Perch()
        p.way = pick.dock && !b.species.isAirborne && perchAffinity(b.species) <= 0 ? .walk : perchWay(b)
        p.top = Double(pick.rect.maxY)
        p.x = pick.x
        p.lo = Double(pick.rect.minX) + b.size * 0.6
        p.hi = Double(pick.rect.maxX) - b.size * 0.6
        p.dock = pick.dock
        p.stay = perchRng.range(t.perchStay)
        p.side = b.x <= pick.x ? 1 : -1
        b.perch = p
        bugs[chosen] = b
        stage.census.perchers += 1
        if p.dock { stage.census.docked += 1 }
    }

    func travelPace(_ b: Bug, _ tr: SpeciesTraits, _ way: PerchWay) -> Double {
        way == .fly ? min(160, max(30, paceOf(b, tr) * 1.3)) : max(12, paceOf(b, tr) * 1.2)
    }

    private func chooseLedge(_ b: Bug, dockOpen: Bool, range: Double, from: (Double, Double), except: Double?) -> (rect: CGRect, x: Double, dock: Bool)? {
        let t = tuning
        let affinity = perchAffinity(b.species)
        let way = perchWay(b)
        let tr = t.traits(for: b.species)
        var best: (rect: CGRect, x: Double, dock: Bool)?
        var bestCost = Double.infinity
        for r in surroundings.ledges {
            let dock = isDock(r)
            if dock && !dockOpen { continue }
            if !dock && affinity <= 0 { continue }
            if let skip = except, abs(Double(r.maxY) - skip) < 6 { continue }
            guard let x = landing(b, on: r, near: from.0) else { continue }
            let y = Double(r.maxY) + feet(b)
            var cost = hypot(x - from.0, y - from.1)
            let walkWay = dock && !b.species.isAirborne && affinity <= 0 ? PerchWay.walk : way
            let reach = travelPace(b, tr, walkWay) * max(1, t.perchTravelMax) * 0.55
            let limit = min(walkWay == .fly || walkWay == .hop ? range : min(range, 360), reach)
            guard cost <= limit else { continue }
            if light > t.duskLight && edgeDistance(x, y) > 180 { continue }
            if way == .climb { cost *= 1.5 }
            cost *= perchRng.range(0.8...1.2)
            if cost < bestCost {
                bestCost = cost
                best = (r, x, dock)
            }
        }
        return best
    }

    func spookPerch(_ b: inout Bug, fromX px: Double, speed: Double) {
        guard var p = b.perch else { return }
        let t = tuning
        let tr = t.traits(for: b.species)
        let settled = p.phase == .sit || p.phase == .look || p.phase == .shuffle
        if !settled {
            if p.phase == .travel { endPerch(&b, tr: tr, away: nil) }
            return
        }
        if p.way == .fly {
            endPerch(&b, tr: tr, away: .pi / 2 + (b.x >= px ? -0.7 : 0.7))
            ripple(fromX: b.x, y: b.y, except: b.id)
            return
        }
        let dir: Double = b.x >= px ? 1 : -1
        let target = p.x + dir * b.size * 1.8
        if speed < t.pointerScamperSpeed && target >= p.lo && target <= p.hi && !spotTaken(x: target, top: p.top, size: b.size, except: b.id) {
            p.phase = .shuffle
            p.fromX = b.x
            p.toX = target
            p.clock = 0
            p.length = 3
            b.perch = p
            return
        }
        beginDrop(&b, &p, spooked: speed >= t.pointerScamperSpeed)
        b.perch = p
        ripple(fromX: b.x, y: b.y, except: b.id)
    }

    private func endPerch(_ b: inout Bug, tr: SpeciesTraits, away: Double?) {
        b.perch = nil
        b.pinned = false
        b.perchRest = time + perchRng.range(tuning.perchCooldown)
        resume(&b, tr: tr, toward: away)
    }

    private func beginDrop(_ b: inout Bug, _ p: inout Perch, spooked: Bool) {
        p.phase = .drop
        p.clock = 0
        p.spooked = spooked
        p.vy = spooked ? 0 : 110
        p.floor = max(b.size * 0.6, p.top + feet(b) - b.size * perchRng.range(1.5...3.0))
        p.gesture = spooked ? .tumble : .none
        b.speed = 0
        b.pinned = true
    }

    private func sitBeat(_ b: inout Bug, _ p: inout Perch, length: Double) {
        p.phase = .sit
        p.clock = 0
        p.length = length
        p.gesture = .perch
        p.exiting = false
        b.speed = 0
        b.pinned = true
        b.course = b.facing > 0 ? 0 : .pi
    }

    func perchStep(_ b: inout Bug, tr: SpeciesTraits, h: Double) -> Double {
        guard var p = b.perch else { return 0 }
        let t = tuning
        p.clock += h
        p.total += h
        let s = b.size
        let f = feet(b)
        switch p.phase {
        case .travel:
            guard let r = ledgeAt(x: p.x, top: p.top, track: t.perchTrack) else {
                endPerch(&b, tr: tr, away: nil)
                return 0
            }
            p.top = Double(r.maxY)
            p.lo = Double(r.minX) + s * 0.6
            p.hi = Double(r.maxX) - s * 0.6
            guard p.hi >= p.lo, p.top + f + s * 0.5 <= height, p.clock <= t.perchTravelMax else {
                endPerch(&b, tr: tr, away: nil)
                return 0
            }
            p.x = min(max(p.x, p.lo), p.hi)
            var tx = p.x, ty = p.top + f
            switch p.way {
            case .fly: ty += s * 1.3
            case .hop:
                tx -= p.side * s * 1.2
                ty = max(s * 0.6, ty - s * 0.9)
            case .climb, .walk: break
            }
            ty = min(ty, height - s * 0.6)
            let pace = travelPace(b, tr, p.way)
            let d = seek(&b, x: tx, y: ty, pace: pace, tr: tr, h: h, arrive: p.way == .fly ? 8 : 5)
            b.mode = b.speed > 1 || b.lift > 0 ? .wandering : .resting
            p.gesture = .none
            if d <= (p.way == .fly ? 14 : 8) && (p.way != .hop || b.lift == 0) {
                p.fromX = b.x
                p.fromY = b.y
                p.clock = 0
                switch p.way {
                case .fly:
                    p.phase = .land
                    p.length = 0.7
                case .hop:
                    p.phase = .jump
                    p.toX = p.x
                    p.toTop = p.top
                    p.hump = s * 0.9
                    p.length = 0.5
                case .climb, .walk:
                    b.x = p.x
                    b.y = p.top + f
                    sitBeat(&b, &p, length: perchRng.range(t.perchSit))
                }
                b.speed = 0
                b.pinned = true
            }
        case .land:
            b.mode = .resting
            p.gesture = .none
            b.pinned = true
            b.speed = 0
            if ledgeAt(x: p.x, top: p.top, track: t.perchTrack) == nil {
                endPerch(&b, tr: tr, away: .pi / 2)
                return 0
            }
            let u = min(1, p.clock / max(0.1, p.length))
            let e = u * u * (3 - 2 * u)
            b.x = p.fromX + (p.x - p.fromX) * e
            b.y = p.fromY + (p.top + f - p.fromY) * e
            if u >= 1 { sitBeat(&b, &p, length: perchRng.range(t.perchSit)) }
        case .jump:
            b.mode = .resting
            p.gesture = .none
            b.pinned = true
            b.speed = 0
            let u = min(1, p.clock / max(0.1, p.length))
            b.x = p.fromX + (p.toX - p.fromX) * u
            b.y = p.fromY + (p.toTop + f - p.fromY) * u + p.hump * 4 * u * (1 - u)
            if abs(p.toX - p.fromX) > 2 { b.facing = p.toX > p.fromX ? 1 : -1 }
            if u >= 1 {
                if let r = ledgeAt(x: p.toX, top: p.toTop, track: t.perchTrack) {
                    p.x = p.toX
                    p.top = Double(r.maxY)
                    p.lo = Double(r.minX) + s * 0.6
                    p.hi = Double(r.maxX) - s * 0.6
                    sitBeat(&b, &p, length: perchRng.range(t.perchSit))
                } else if p.way == .fly {
                    endPerch(&b, tr: tr, away: .pi / 2)
                    return 0
                } else {
                    p.top = p.toTop
                    beginDrop(&b, &p, spooked: true)
                }
            }
        case .sit, .look, .shuffle:
            guard let r = ledgeAt(x: b.x, top: p.top, track: t.perchTrack) else {
                if p.exiting {
                    beginDrop(&b, &p, spooked: false)
                    b.perch = p
                    return 0
                }
                if p.way == .fly {
                    endPerch(&b, tr: tr, away: .pi / 2 + perchRng.signed() * 0.8)
                } else {
                    beginDrop(&b, &p, spooked: true)
                    b.perch = p
                }
                ripple(fromX: b.x, y: b.y, except: b.id)
                return 0
            }
            let lo = Double(r.minX) + s * 0.6, hi = Double(r.maxX) - s * 0.6
            let slide = lo - p.lo
            if abs((hi - lo) - (p.hi - p.lo)) < 1 && abs(slide) > 1e-3 && abs(slide) < t.perchTrack {
                b.x += slide
                p.x += slide
                p.fromX += slide
                p.toX += slide
            }
            p.top = Double(r.maxY)
            p.lo = lo
            p.hi = hi
            let floorY = p.top + f
            if abs(b.y - floorY) > 0.01 {
                var y = b.y
                approach(&y, floorY, rate: 160, h: h)
                b.y = y
            }
            b.mode = .resting
            if p.phase == .shuffle {
                if shuffleStep(&b, &p, r, tr: tr, h: h) { return 0 }
            } else {
                b.pinned = true
                b.speed = 0
                if b.x < Double(r.minX) + s * 0.2 || b.x > Double(r.maxX) - s * 0.2 {
                    let edge = b.x < Double(r.minX) + s * 0.2 ? Double(r.minX) + s * 0.6 : Double(r.maxX) - s * 0.6
                    if p.hi >= p.lo {
                        p.phase = .shuffle
                        p.fromX = b.x
                        p.toX = edge
                        p.clock = 0
                        p.length = 2
                    } else {
                        beginDrop(&b, &p, spooked: false)
                    }
                    b.perch = p
                    return 0
                }
                b.x = min(max(b.x, Double(r.minX)), Double(r.maxX))
                p.x = b.x
                if p.phase == .look {
                    p.gesture = .look
                    if !p.flipped && p.clock > p.length * 0.45 {
                        p.flipped = true
                        b.facing = -b.facing
                        b.facingHold = 0.3
                    }
                } else {
                    p.gesture = .perch
                    b.course = b.facing > 0 ? 0 : .pi
                }
                if p.clock >= p.length {
                    if nextBeat(&b, &p, tr: tr) { return 0 }
                }
            }
        case .drop:
            b.mode = .resting
            b.pinned = true
            b.speed = 0
            p.vy = max(-320, p.vy - 900 * h)
            b.y += p.vy * h
            p.gesture = p.spooked ? .tumble : .none
            if b.y <= p.floor {
                b.y = p.floor
                p.phase = .leave
                p.clock = 0
                b.pinned = false
            }
        case .leave:
            b.mode = .resting
            b.pinned = false
            p.gesture = .look
            settleStill(&b, tr: tr, h: h)
            if p.clock >= 0.6 {
                endPerch(&b, tr: tr, away: nil)
                return 0
            }
        }
        b.perch = p
        return 0
    }

    private func shuffleStep(_ b: inout Bug, _ p: inout Perch, _ r: CGRect, tr: SpeciesTraits, h: Double) -> Bool {
        let s = b.size
        p.gesture = .none
        let dx = p.toX - b.x
        if p.way == .fly {
            b.pinned = true
            b.speed = 0
            let u = min(1, p.clock / max(0.2, p.length))
            b.x = p.fromX + (p.toX - p.fromX) * u
            b.y = p.top + feet(b) + s * 0.8 * 4 * u * (1 - u)
            if abs(dx) > 1 { b.facing = dx > 0 ? 1 : -1 }
            if u >= 1 {
                p.x = b.x
                sitBeat(&b, &p, length: perchRng.range(tuning.perchSit))
            }
            return false
        }
        b.pinned = false
        b.course = dx >= 0 ? 0 : .pi
        let pace = max(10, paceOf(b, tr) * 0.6)
        let over = b.x < Double(r.minX) - s * 0.3 || b.x > Double(r.maxX) + s * 0.3
        if p.exiting && over {
            beginDrop(&b, &p, spooked: false)
            b.perch = p
            return true
        }
        if abs(dx) < 2 && !p.exiting && b.lift == 0 {
            p.x = b.x
            sitBeat(&b, &p, length: perchRng.range(tuning.perchSit))
            return false
        }
        if b.species.locomotion == .hop {
            b.speed = abs(dx) > s * 0.4 || p.exiting ? pace : (b.lift > 0 ? b.speed : 0)
            if abs(dx) <= s * 0.4 && !p.exiting && b.lift == 0 {
                p.x = b.x
                sitBeat(&b, &p, length: perchRng.range(tuning.perchSit))
            }
        } else {
            approach(&b.speed, p.exiting ? pace : min(pace, abs(dx) * 3), rate: pace / 0.2, h: h)
        }
        if p.clock > max(p.length, 4) && !p.exiting {
            p.x = b.x
            sitBeat(&b, &p, length: perchRng.range(tuning.perchSit))
        }
        p.x = b.x
        return false
    }

    private func nextBeat(_ b: inout Bug, _ p: inout Perch, tr: SpeciesTraits) -> Bool {
        let t = tuning
        let s = b.size
        p.flipped = false
        if p.total >= p.stay {
            switch p.way {
            case .fly:
                endPerch(&b, tr: tr, away: .pi / 2 + perchRng.signed() * 0.9)
                return true
            case .climb, .walk:
                endPerch(&b, tr: tr, away: -.pi / 2 + perchRng.signed() * 0.4)
                return true
            case .hop:
                if perchRng.chance(0.5) {
                    let right = perchRng.chance(0.5)
                    p.phase = .shuffle
                    p.exiting = true
                    p.toX = right ? p.hi + s * 2 : p.lo - s * 2
                    p.clock = 0
                    p.length = 6
                    b.facing = right ? 1 : -1
                } else {
                    beginDrop(&b, &p, spooked: false)
                }
                b.perch = p
                return true
            }
        }
        let roll = perchRng.unit()
        if roll < 0.3 {
            p.phase = .look
            p.clock = 0
            p.length = perchRng.range(1.2...2.0)
            p.gesture = .look
            b.pinned = true
            return false
        }
        if roll < 0.6 {
            let dir: Double = perchRng.chance(0.5) ? 1 : -1
            var target = p.x + dir * s * perchRng.range(0.8...2.2)
            if target < p.lo || target > p.hi { target = p.x - dir * s * perchRng.range(0.8...2.2) }
            if target >= p.lo && target <= p.hi && !spotTaken(x: target, top: p.top, size: s, except: b.id) {
                p.phase = .shuffle
                p.toX = target
                p.fromX = b.x
                p.clock = 0
                p.length = p.way == .fly ? 0.7 : 3
                return false
            }
        } else if roll < 0.75 && (p.way == .fly || p.way == .hop) && !p.dock {
            if let next = chooseLedge(b, dockOpen: false, range: t.perchHopRange, from: (b.x, b.y), except: p.top) {
                p.phase = .jump
                p.fromX = b.x
                p.fromY = b.y
                p.toX = next.x
                p.toTop = Double(next.rect.maxY)
                let dist = hypot(p.toX - b.x, p.toTop - p.top)
                p.hump = dist * 0.3 + s
                p.length = p.way == .fly ? 0.6 + dist / 400 : 0.45 + dist / 600
                p.clock = 0
                b.pinned = true
                return false
            }
        }
        sitBeat(&b, &p, length: perchRng.range(t.perchSit))
        return false
    }
}
