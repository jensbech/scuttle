import Foundation
import CoreGraphics

enum PropMotion: Equatable {
    case rest
    case carried
    case pushed
    case rolling
    case flying
    case falling
    case rope
    case hung
}

enum PropLanding: Equatable {
    case rest
    case splat
    case merge
    case vanish
}

struct PropBody {
    var id: Int
    var kind: PropKind
    var x: Double
    var y: Double
    var size: Double
    var rotation = 0.0
    var progress = 1.0
    var variant = 0
    var age = 0.0
    var fade = 0.0
    var fadeIn = 2.5
    var doomed = false
    var doomRate = 1.5
    var motion = PropMotion.rest
    var holder = -1
    var partner = -1
    var endX = 0.0
    var endY = 0.0
    var hasEnd = false
    var vx = 0.0
    var vy = 0.0
    var z = 0.0
    var vz = 0.0
    var spin = 0.0
    var fromX = 0.0
    var fromY = 0.0
    var toX = 0.0
    var toY = 0.0
    var clock = 0.0
    var length = 0.0
    var hump = 0.0
    var landing = PropLanding.rest
    var site = -1
    var game = -1
    var claim = -1
    var idle = 0.0
    var life = 0.0
    var leaving = false
    var grows = 0.0
    var maxSize = 0.0
    var growRate = 0.0
    var thrower = -1
    var target = -1
    var slot = -1
    var layer = 2
}

struct PropYard {
    var bodies: [PropBody] = []
    var serial = 0
    var seen = 1.0
    var veil = 0.0
    var litClock = 0.0
    var grabbed = false
    var landed: [(Int, PropLanding)] = []
}

extension World {
    public var propCount: Int { stage.yard.bodies.count }

    public var propVeil: Double { stage.yard.veil }

    func propIndex(_ id: Int) -> Int? {
        guard id >= 0 else { return nil }
        for k in stage.yard.bodies.indices where stage.yard.bodies[k].id == id { return k }
        return nil
    }

    func prop(_ id: Int) -> PropBody? {
        guard let k = propIndex(id) else { return nil }
        return stage.yard.bodies[k]
    }

    @discardableResult
    func addProp(_ kind: PropKind, x: Double, y: Double, size: Double, progress: Double = 1, motion: PropMotion = .rest, layer: Int = 2) -> Int {
        stage.yard.serial += 1
        var p = PropBody(id: stage.yard.serial, kind: kind, x: x, y: y, size: max(2, size))
        p.progress = progress
        p.motion = motion
        p.layer = layer
        p.variant = Int(workRng.unit() * 4) % 4
        stage.yard.bodies.append(p)
        return p.id
    }

    func editProp(_ id: Int, _ change: (inout PropBody) -> Void) {
        guard let k = propIndex(id) else { return }
        change(&stage.yard.bodies[k])
    }

    func ground(_ b: Bug) -> Double {
        b.y - b.size * 0.5
    }

    func carryPoint(_ b: Bug, size s: Double) -> (x: Double, y: Double) {
        switch b.species.locomotion {
        case .flutter, .hover, .dart:
            return (b.x, b.y - b.size * 0.42 - s * 0.38)
        case .float:
            if b.species.stance == .topDown { return (b.x, b.y + b.size * 0.12) }
            return (b.x + b.facing * b.size * 0.48, b.y - b.size * 0.08)
        default:
            if b.species.stance == .topDown { return (b.x, b.y + b.size * 0.14) }
            return (b.x, b.y + b.size * 0.55 + s * 0.42)
        }
    }

    func handPoint(_ b: Bug) -> (x: Double, y: Double) {
        (b.x + b.facing * b.size * 0.3, b.y + b.size * 0.04)
    }

    func carrierIndex(_ id: Int, holds pid: Int) -> Int? {
        guard id >= 0, let i = index(of: id) else { return nil }
        let b = bugs[i]
        guard b.mode != .hidden else { return nil }
        if b.keep == pid { return i }
        if let j = b.job, j.held == pid { return i }
        return nil
    }

    private func pusherIndex(_ id: Int, pushes pid: Int) -> Int? {
        guard id >= 0, let i = index(of: id) else { return nil }
        let b = bugs[i]
        guard b.mode != .hidden, let j = b.job, j.pushing == pid else { return nil }
        return i
    }

    private func claimValid(_ id: Int, _ pid: Int) -> Bool {
        guard id >= 0, let i = index(of: id), bugs[i].mode != .hidden, let j = bugs[i].job else { return false }
        return j.target == pid || j.held == pid || j.pushing == pid
    }

    func rounds(_ k: PropKind) -> Bool {
        switch k {
        case .ball, .snowball, .acorn, .egg, .pumpkin: return true
        default: return false
        }
    }

    func knockable(_ k: PropKind) -> Bool {
        switch k {
        case .ball, .snowball, .acorn, .egg, .shell, .candy, .crumb: return true
        default: return false
        }
    }

    func loosen(_ p: inout PropBody, from b: Bug?, gentle: Bool, vx: Double = 0, vy: Double = 0) {
        let cy = p.y + p.z
        var floor: Double
        if let b, !b.species.isAirborne {
            floor = ground(b) + p.size * 0.5
        } else {
            floor = cy - (gentle ? 26 : 70)
        }
        floor = min(cy, max(p.size * 0.5, floor))
        p.z = cy - floor
        p.y = floor
        p.motion = .falling
        p.holder = -1
        p.partner = -1
        p.vz = gentle ? 0 : 150
        p.vx = vx
        p.vy = vy
        p.spin = gentle ? 0 : workRng.signed() * 7
        p.claim = -1
        p.leaving = false
    }

    func setDown(_ id: Int, by b: Bug?) {
        guard let k = propIndex(id) else { return }
        var p = stage.yard.bodies[k]
        guard p.motion == .carried || p.motion == .pushed else { return }
        if p.motion == .pushed {
            p.motion = .rolling
            p.claim = -1
        } else {
            loosen(&p, from: b, gentle: true)
        }
        stage.yard.bodies[k] = p
    }

    func knockHeld(_ b: Bug, dirX: Double, dirY: Double, speed: Double) {
        guard let j = b.job else { return }
        let v = min(320, speed * 0.3)
        if j.held >= 0, let k = propIndex(j.held), stage.yard.bodies[k].motion == .carried {
            var p = stage.yard.bodies[k]
            loosen(&p, from: b, gentle: false, vx: dirX * v, vy: dirY * v)
            stage.yard.bodies[k] = p
        }
        if j.pushing >= 0, let k = propIndex(j.pushing), stage.yard.bodies[k].motion == .pushed {
            stage.yard.bodies[k].motion = .rolling
            stage.yard.bodies[k].claim = -1
            stage.yard.bodies[k].vx += dirX * v * 0.5
            stage.yard.bodies[k].vy += dirY * v * 0.5
        }
    }

    func knockLoose(_ px: Double, _ py: Double, speed: Double, dirX: Double, dirY: Double) {
        let t = tuning
        guard t.pointerEnabled else { return }
        for k in stage.yard.bodies.indices {
            var p = stage.yard.bodies[k]
            guard p.motion == .rest || p.motion == .rolling, p.site < 0, !p.doomed, knockable(p.kind) else { continue }
            let reach = t.pointerBowlRadius + p.size * 0.5 + 16
            let dx = p.x - px, dy = p.y - py
            if abs(dx) > reach || abs(dy) > reach { continue }
            let d = hypot(dx, dy)
            guard d < reach else { continue }
            let v = min(420, speed * 0.35)
            var ax = dirX * 0.75, ay = dirY * 0.75
            if d > 1 {
                ax += dx / d * 0.5
                ay += dy / d * 0.5
            }
            let m = max(1e-6, hypot(ax, ay))
            p.vx += ax / m * v
            p.vy += ay / m * v
            p.vz = max(p.vz, 90)
            p.motion = .rolling
            p.claim = -1
            stage.yard.bodies[k] = p
        }
    }

    func noteGrab(_ b: inout Bug, flinch: Bool) {
        b.grab = -1
        guard !flinch, !b.retiring, tuning.grabChance > 0, let j = b.job, j.held >= 0, !stage.yard.grabbed else { return }
        guard let k = propIndex(j.held), stage.yard.bodies[k].partner < 0, stage.yard.bodies[k].kind != .rope else { return }
        guard workRng.chance(tuning.grabChance) else { return }
        stage.yard.grabbed = true
        b.grab = j.held
    }

    func grabStep(_ b: inout Bug, h: Double) -> Bool {
        guard let k = propIndex(b.grab) else {
            b.grab = -1
            return false
        }
        var p = stage.yard.bodies[k]
        let loose = !p.doomed && (p.motion == .rest || p.motion == .falling || p.motion == .rolling)
        let tx = p.x, ty = p.y - p.size * 0.5 + b.size * 0.5
        let d = hypot(tx - b.x, ty - b.y)
        guard loose, b.fleeElapsed < 0.9, d < b.size * 4 + 40 else {
            b.grab = -1
            return false
        }
        b.fleeElapsed += h
        if d > 1e-6 { steer(&b, toward: atan2(ty - b.y, tx - b.x), rate: tuning.fleeTurnRate, h: h) }
        approach(&b.speed, min(max(60, b.fleeTop), max(60, d * 5)), rate: max(60, b.fleeTop) / 0.2, h: h)
        if d < b.size * 0.5 + p.size * 0.5 + 4 {
            p.motion = .carried
            p.holder = b.id
            p.partner = -1
            p.leaving = true
            p.z = 0
            p.site = -1
            p.game = -1
            stage.yard.bodies[k] = p
            b.keep = p.id
            b.grab = -1
        }
        return true
    }

    func keepOnSneak(_ b: inout Bug) {
        b.keep = -1
        b.grab = -1
        guard let j = b.job else { return }
        if j.held >= 0, let k = propIndex(j.held) {
            var p = stage.yard.bodies[k]
            guard p.motion == .carried, p.holder == b.id || p.partner == b.id else { return }
            if p.partner < 0 && p.kind != .rope && workRng.chance(tuning.carryOffChance) {
                p.leaving = true
                p.site = -1
                p.game = -1
                b.keep = p.id
            } else if p.kind != .rope {
                loosen(&p, from: b, gentle: true)
            }
            stage.yard.bodies[k] = p
            return
        }
        if j.family == .play, let g = gameIndex(j.group), stage.work.games[g].kind == .ball, let k = propIndex(stage.work.games[g].prop) {
            var p = stage.yard.bodies[k]
            guard p.motion == .rest || p.motion == .rolling, !p.leaving, hypot(p.x - b.x, p.y - b.y) < b.size * 3 + p.size else { return }
            p.motion = .carried
            p.holder = b.id
            p.partner = -1
            p.leaving = true
            p.game = -1
            p.z = 0
            stage.yard.bodies[k] = p
            b.keep = p.id
        }
    }

    func clearProps() {
        forgetWork()
        stage.yard.bodies.removeAll(keepingCapacity: true)
        stage.yard.landed.removeAll(keepingCapacity: true)
        props.removeAll(keepingCapacity: true)
        for i in bugs.indices where bugs[i].keep >= 0 || bugs[i].grab >= 0 {
            bugs[i].keep = -1
            bugs[i].grab = -1
        }
    }

    private func updateVeil(_ h: Double) {
        let t = tuning
        var y = stage.yard
        let rate = max(0.01, t.propFadeRate)
        let holding = catchHolding
        if !holding { approach(&y.seen, light, rate: rate * (stage.caught.start.isFinite && time - stage.caught.start < 5 ? 1.6 : 1), h: h) }
        let from = min(0.98, max(0, t.propFadeFrom))
        let u = clamp01((y.seen - from) / max(1e-3, 1 - from))
        y.veil = 1 - u * u * (3 - 2 * u)
        if light >= t.fullLight && !holding {
            y.litClock += h
        } else {
            y.litClock = 0
        }
        if y.litClock > t.propLitMax { y.veil = 0 }
        if light < t.duskLight && lightRate <= 0 { y.grabbed = false }
        stage.yard.seen = y.seen
        stage.yard.veil = y.veil
        stage.yard.litClock = y.litClock
        stage.yard.grabbed = y.grabbed
    }

    func tendProps(_ h: Double) {
        let t = tuning
        updateVeil(h)
        if stage.yard.bodies.isEmpty { return }
        let lit = light >= t.fullLight
        if (lit && (stage.yard.veil <= 0 || critters.isEmpty || stage.yard.litClock > t.propLitMax)) || (critters.isEmpty && light >= 0.999) {
            clearProps()
            return
        }
        var bodies = stage.yard.bodies
        stage.yard.bodies.removeAll(keepingCapacity: true)
        var landed = stage.yard.landed
        landed.removeAll(keepingCapacity: true)
        var loose = 0
        for p in bodies where p.motion == .rest && p.site < 0 && p.game < 0 && !p.doomed { loose += 1 }
        var excess = max(loose - max(0, t.propLooseMax), bodies.count - max(4, t.propMax))
        let w = width, ht = height
        for k in bodies.indices {
            var p = bodies[k]
            p.age += h
            if excess > 0 && !p.doomed && p.motion == .rest && p.site < 0 && p.game < 0 {
                p.doomed = true
                excess -= 1
            }
            switch p.motion {
            case .carried:
                guard let i = carrierIndex(p.holder, holds: p.id) else {
                    if p.leaving {
                        p.doomed = true
                        p.fade = 0
                    } else {
                        let gone = p.holder >= 0 ? index(of: p.holder).map { bugs[$0] } : nil
                        let v = gone.map { (cos($0.heading) * $0.pace * 0.5, sin($0.heading) * $0.pace * 0.2) } ?? (0, 0)
                        loosen(&p, from: gone, gentle: false, vx: v.0, vy: v.1)
                    }
                    break
                }
                var target = carryPoint(bugs[i], size: p.size)
                if p.partner >= 0 {
                    guard let j = carrierIndex(p.partner, holds: p.id) else {
                        loosen(&p, from: bugs[i], gentle: false)
                        break
                    }
                    let other = carryPoint(bugs[j], size: p.size)
                    target = ((target.x + other.x) / 2, max(target.y, other.y))
                }
                let k2 = min(1, h / 0.08)
                p.x += (target.x - p.x) * k2
                p.y += (target.y - p.y) * k2
                p.z = 0
                let swing = bugs[i].pace > 2 ? 0.09 : 0.03
                p.rotation += (swing * sin(p.age * 5.5) - p.rotation) * min(1, h / 0.15)
            case .pushed:
                guard let i = pusherIndex(p.claim, pushes: p.id) else {
                    p.motion = .rolling
                    p.claim = -1
                    break
                }
                let b = bugs[i]
                let d = b.size * 0.42 + p.size * 0.5
                let nx = b.x + cos(b.course) * d
                let ny = ground(b) + p.size * 0.5 + sin(b.course) * d * 0.7
                let k2 = min(1, h / 0.1)
                let ox = p.x, oy = p.y
                p.x += (nx - p.x) * k2
                p.y += (ny - p.y) * k2
                let moved = hypot(p.x - ox, p.y - oy)
                p.vx = (p.x - ox) / h
                p.vy = (p.y - oy) / h
                if rounds(p.kind) { p.rotation -= (p.x - ox) / max(1, p.size * 0.5) }
                if p.grows > 0 && p.maxSize > p.size { p.size = min(p.maxSize, p.size + p.grows * moved) }
                p.z = 0
            case .rolling:
                rollProp(&p, h: h)
            case .falling:
                p.vz -= 1500 * h
                p.z += p.vz * h
                p.x += p.vx * h
                p.y += p.vy * h
                let damp = exp(-h / 0.45)
                p.vx *= damp
                p.vy *= damp
                p.rotation += p.spin * h
                p.spin *= exp(-h / 0.7)
                if p.z <= 0 {
                    p.z = 0
                    if p.vz < -90 {
                        p.vz = -p.vz * 0.42
                        p.spin *= 0.6
                    } else {
                        p.vz = 0
                        p.motion = hypot(p.vx, p.vy) > 18 && rounds(p.kind) ? .rolling : .rest
                    }
                }
                p.x = min(max(p.x, p.size * 0.5), max(p.size * 0.5, w - p.size * 0.5))
                p.y = min(max(p.y, p.size * 0.5), max(p.size * 0.5, ht - p.size * 0.5))
            case .flying:
                p.clock += h
                let u = min(1, p.clock / max(0.05, p.length))
                p.x = p.fromX + (p.toX - p.fromX) * u
                p.y = p.fromY + (p.toY - p.fromY) * u
                p.z = p.hump * 4 * u * (1 - u)
                p.rotation += p.spin * h
                if u >= 1 {
                    p.z = 0
                    switch p.landing {
                    case .rest:
                        p.motion = .rest
                        p.spin = 0
                    case .vanish:
                        p.motion = .rest
                        p.doomed = true
                        p.doomRate = max(p.doomRate, 6)
                    case .splat, .merge:
                        p.motion = .rest
                        landed.append((p.id, p.landing))
                    }
                }
            case .rope:
                let a = carrierIndex(p.holder, holds: p.id)
                let c = carrierIndex(p.partner, holds: p.id)
                if let a, let c {
                    let pa = handPoint(bugs[a]), pc = handPoint(bugs[c])
                    let k2 = min(1, h / 0.06)
                    p.x += (pa.x - p.x) * k2
                    p.y += (pa.y - p.y) * k2
                    p.endX += (pc.x - p.endX) * k2
                    p.endY += (pc.y - p.endY) * k2
                    p.progress = min(1, p.progress + h * 3)
                    p.fromY = min(ground(bugs[a]), ground(bugs[c])) + 3
                } else {
                    p.motion = .rest
                    p.holder = -1
                    p.partner = -1
                }
            case .hung:
                p.z = 0
            case .rest:
                p.z = 0
                p.vx = 0
                p.vy = 0
                if p.kind == .rope && p.hasEnd {
                    p.progress = max(0, p.progress - h * 2.5)
                    approach(&p.y, p.fromY, rate: 90, h: h)
                    approach(&p.endY, p.fromY, rate: 90, h: h)
                }
                if !rounds(p.kind) && p.kind != .rope && p.kind != .banner {
                    let q = (p.rotation / (.pi / 2)).rounded() * (.pi / 2)
                    p.rotation += (q - p.rotation) * min(1, h / 0.4)
                }
            }
            if p.claim >= 0 && p.motion != .pushed && !claimValid(p.claim, p.id) { p.claim = -1 }
            if p.motion == .rest && p.site < 0 && p.game < 0 && p.claim < 0 {
                p.idle += h
                if p.idle > (p.life > 0 ? p.life : t.propIdleLife) { p.doomed = true }
            } else {
                p.idle = 0
            }
            if p.growRate > 0 {
                p.progress = min(1, p.progress + p.growRate * h)
                if p.progress >= 1 { p.growRate = 0 }
            }
            if p.doomed {
                p.fade -= max(0.1, p.doomRate) * h
            } else if p.fade < 1 {
                p.fade = min(1, p.fade + max(0.1, p.fadeIn) * h)
            }
            let finite = p.x.isFinite && p.y.isFinite && p.z.isFinite && p.size.isFinite && p.rotation.isFinite && p.endX.isFinite && p.endY.isFinite
            let far = p.x < -w * 0.5 || p.x > w * 1.5 || p.y < -ht * 0.5 || p.y > ht * 1.5
            if !finite || far || (p.doomed && p.fade <= 0) { continue }
            stage.yard.bodies.append(p)
        }
        bodies.removeAll(keepingCapacity: true)
        stage.yard.landed = landed
        for (id, kind) in landed { propLanded(id, kind) }
        stage.yard.landed.removeAll(keepingCapacity: true)
    }

    private func rollProp(_ p: inout PropBody, h: Double) {
        let t = tuning
        let r = p.size * 0.5
        let oy = p.y
        p.x += p.vx * h
        p.y += p.vy * h
        let damp = exp(-h / max(0.05, t.ballFriction * (p.kind == .ball ? 1 : 0.6)))
        p.vx *= damp
        p.vy *= damp
        if p.vz != 0 || p.z > 0 {
            p.vz -= 1500 * h
            p.z += p.vz * h
            if p.z <= 0 {
                p.z = 0
                p.vz = p.vz < -60 ? -p.vz * 0.4 : 0
            }
        }
        if rounds(p.kind) {
            p.rotation -= p.vx * h / max(1, r)
        } else {
            p.rotation += p.spin * h
            p.spin *= exp(-h / 0.5)
        }
        let e = min(1, max(0, t.ballBounce))
        if p.x < r {
            p.x = r
            p.vx = abs(p.vx) * e
        } else if p.x > width - r {
            p.x = width - r
            p.vx = -abs(p.vx) * e
        }
        if p.y < r {
            p.y = r
            p.vy = abs(p.vy) * e
        } else if p.y > height - r {
            p.y = height - r
            p.vy = -abs(p.vy) * e
        }
        if !surroundings.ledges.isEmpty {
            for l in surroundings.ledges {
                let top = Double(l.maxY), lo = Double(l.minX) - r, hi = Double(l.maxX) + r
                guard top.isFinite, lo.isFinite, hi.isFinite, p.x >= lo, p.x <= hi else { continue }
                if oy - r >= top && p.y - r < top && p.vy < 0 {
                    p.y = top + r
                    p.vy = abs(p.vy) * e * 0.85
                } else if oy + r <= top && p.y + r > top && p.vy > 0 {
                    p.y = top - r
                    p.vy = -abs(p.vy) * e * 0.85
                }
            }
        }
        if hypot(p.vx, p.vy) < 5 && p.z <= 0 && p.vz == 0 {
            p.vx = 0
            p.vy = 0
            p.motion = .rest
        }
    }

    func publishProps() {
        props.removeAll(keepingCapacity: true)
        let veil = stage.yard.veil
        guard veil > 0.001, !stage.yard.bodies.isEmpty else { return }
        var order: [(Int, Double, Int, Int)] = []
        order.reserveCapacity(stage.yard.bodies.count)
        for (k, p) in stage.yard.bodies.enumerated() {
            let alpha = min(1, max(0, p.fade)) * veil
            guard alpha > 0.002 else { continue }
            let layer: Int
            switch p.motion {
            case .carried: layer = 7
            case .flying: layer = 6
            case .rope: layer = 1
            case .hung: layer = 0
            default: layer = p.kind == .rope ? 1 : p.layer
            }
            order.append((layer, p.y + p.z, p.id, k))
        }
        order.sort { a, b in
            if a.0 != b.0 { return a.0 < b.0 }
            if a.1 != b.1 { return a.1 > b.1 }
            return a.2 < b.2
        }
        for o in order {
            let p = stage.yard.bodies[o.3]
            let held = p.motion == .carried || p.motion == .rope
            props.append(Prop(
                id: p.id,
                kind: p.kind,
                position: CGPoint(x: p.x, y: p.y + p.z),
                size: p.size,
                rotation: p.rotation,
                progress: min(1, max(0, p.progress)),
                alpha: min(1, max(0, p.fade)) * veil,
                holder: held && p.holder >= 0 ? p.holder : nil,
                partner: held && p.partner >= 0 ? p.partner : nil,
                end: p.hasEnd ? CGPoint(x: p.endX, y: p.endY) : nil,
                age: p.age,
                variant: p.variant
            ))
        }
    }
}
