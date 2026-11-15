import Foundation
import CoreGraphics

public struct WorldConfig: Sendable, Equatable {
    public var population: Int
    public var season: Season
    public var seed: UInt64
    public var weather: Weather?
    public var night: Bool

    public init(population: Int = 24, season: Season = .summer, seed: UInt64 = 1, weather: Weather? = nil, night: Bool = false) {
        self.population = population
        self.season = season
        self.seed = seed
        self.weather = weather
        self.night = night
    }
}

public enum WorldEvent: Sendable, Equatable {
    case emerged(count: Int)
    case scatter(intensity: Double)
    case straggler
    case rareVisitor(Species)
}

enum Edge: CaseIterable {
    case bottom
    case left
    case right
    case top
}

struct Bug {
    var id: Int
    var species: Species
    var size: Double
    var nerve: Double
    var tint: Double
    var venture: Double
    var wallAffinity: Double
    var tempo: Double
    var antennaRate: Double
    var fleeVariance: Double

    var retiring = false
    var guest = false
    var rare = false
    var mode: CritterMode = .hidden
    var x = 0.0
    var y = 0.0
    var course = Double.pi / 2
    var heading = Double.pi / 2
    var speed = 0.0
    var targetSpeed = 0.0
    var desired = Double.pi / 2
    var pivot = Double.pi / 2
    var pivotWindow = 0.0
    var meander = 0.0
    var bend = 0.0
    var gaitPhase = 0.0
    var antennaPhase = 0.0
    var alpha = 1.0
    var timer = 0.0
    var emergeTimer = 0.0
    var entry = Edge.bottom
    var emergeDepth = 0.0
    var peekDepth = 0.0
    var peekTimer = 0.0
    var goalAlong = 0.0
    var goalFrac = 0.5
    var goalTimer = 0.0

    var panic = 0.0
    var flinchOnly = false
    var flinched = false
    var fleeEdge = Edge.bottom
    var fleeAim = 0.0
    var fleeTop = 0.0
    var fleeElapsed = 0.0
    var fleeDeadline = 0.0
    var wrongWay = 0.0
    var wrongHeading = 0.0
    var wobblePhase = 0.0
    var wobbleRate = 0.0
    var wobbleAmp = 0.0
    var litTime = 0.0
    var fading = false

    var stray: Stray?
    var confusion = 0.0

    var pace = 0.0
    var facing = 1.0
    var facingHold = 0.0
    var fleeHead = 0.0
    var lift = 0.0
    var hopSpeed = 0.0
    var hopAir = 0.3
    var sway = 0.0
    var circle = 1.0

    var gesture = Gesture.none
    var gestureStart = 0.0
    var restGesture = Gesture.none
    var backward = false
    var glide = false
    var peekRest = 0.0
    var peek: Peek?
    var entrance: Entrance?
    var act: Act?
    var sneak: Sneak?
    var shake: Shake?
    var social: Social?
    var lure: Lure?
    var perch: Perch?
    var habit: Habit?
    var job: Job?
    var keep = -1
    var grab = -1
    var pinned = false
    var lureCalm = 0.0
    var perchRest = 0.0
    var beat: Beat?
    var dashStart = -1.0
    var dashX = 0.0
    var dashY = 0.0
}

public final class World {
    public private(set) var size: CGSize
    public var config: WorldConfig
    public var tuning = Tuning()
    public var surroundings = Surroundings()
    public private(set) var critters: [Critter] = []
    public internal(set) var props: [Prop] = []
    public private(set) var light: Double = 1
    public private(set) var lightRate: Double = 0
    public private(set) var lidAngle: Double = 110
    public private(set) var activity: Double = 0
    public private(set) var time: Double = 0
    public private(set) var darkSeconds: Double = 0
    public internal(set) var mood = LidMood.bright
    private var events: [WorldEvent] = []

    var bugs: [Bug] = []
    private var applied: WorldConfig?
    private var rng = SplitMix64(seed: 0)
    var strayRng = SplitMix64(seed: 0)
    var rareRng = SplitMix64(seed: 0)
    var actRng = SplitMix64(seed: 0)
    var socialRng = SplitMix64(seed: 0)
    var pointerRng = SplitMix64(seed: 0)
    var perchRng = SplitMix64(seed: 0)
    var workRng = SplitMix64(seed: 0)
    var lid = LidSense()
    var stage = Stage()
    var brightSeconds = 0.0
    var darkEpisode = false
    var rareAnnounced = false
    var rareFast = false
    var rareSerial = 0
    var summonPending = false
    var summonSpecies: Species?
    var othersRunning = false
    private var nextID = 0
    private(set) var targetLight = 1.0
    var peakRate = 0.0
    private var emergeGap = 0.0
    var startledThisStep = 0
    private var episodeActive = false
    private var episodePending = false
    private var episodeTimer = 0.0
    private var episodeQuiet = 0.0
    private var episodePeak = 0.0
    private var avoidX: [Double] = []
    private var avoidY: [Double] = []

    public init(size: CGSize, config: WorldConfig = WorldConfig()) {
        self.size = size
        self.config = config
        syncConfig()
    }

    public var isQuiet: Bool { critters.isEmpty && light >= 0.999 && props.isEmpty }

    public var hiddenCount: Int { bugs.count - critters.count }

    public var stragglerID: Int? {
        bugs.first { $0.stray != nil && $0.mode != .hidden }?.id
    }

    var width: Double { Double(size.width) }
    var height: Double { Double(size.height) }

    public func resize(_ size: CGSize) {
        self.size = size
        let w = width, ht = height
        for i in bugs.indices where bugs[i].mode != .hidden {
            bugs[i].x = min(max(bugs[i].x, -bugs[i].size), w + bugs[i].size)
            bugs[i].y = min(max(bugs[i].y, -bugs[i].size), ht + bugs[i].size)
            bugs[i].goalAlong = min(max(bugs[i].goalAlong, 0), span(bugs[i].entry))
        }
        publish()
    }

    public func step(dt: Double, lidAngle: Double) {
        if lidAngle.isFinite { self.lidAngle = lidAngle }
        guard dt.isFinite, dt > 0 else { return }
        let total = min(dt, 0.25)
        let parts = max(1, Int((total / (1.0 / 30.0 + 1e-9)).rounded(.up)))
        let h = total / Double(parts)
        for _ in 0..<parts { advance(h) }
    }

    public func drainEvents() -> [WorldEvent] {
        defer { events.removeAll() }
        return events
    }

    private func syncConfig() {
        if applied == config { return }
        let new = config
        if let old = applied, old.seed != new.seed {
            for i in bugs.indices { bugs[i].retiring = true }
        }
        if applied == nil || applied?.seed != new.seed {
            rng = SplitMix64(seed: new.seed ^ 0xD1B5_4A32_D192_ED03)
            strayRng = SplitMix64(seed: (new.seed &* 0x2545_F491_4F6C_DD1D) ^ 0x7A3C_19E5_B04D_6F21)
            rareRng = SplitMix64(seed: (new.seed &* 0x94D0_49BB_1331_11EB) ^ 0x3C6E_F372_FE94_F82B)
            actRng = SplitMix64(seed: (new.seed &* 0xA24B_AED4_963E_E407) ^ 0x5851_F42D_4C95_7F2D)
            socialRng = SplitMix64(seed: (new.seed &* 0x9FB2_1C65_1E98_DF25) ^ 0x2F6B_3C1D_8A4E_9071)
            pointerRng = SplitMix64(seed: (new.seed &* 0xD6E8_FEB8_6659_FD93) ^ 0x61C8_8646_80B5_83EB)
            perchRng = SplitMix64(seed: (new.seed &* 0xFF51_AFD7_ED55_8CCD) ^ 0x4CF5_AD43_2745_937F)
            workRng = SplitMix64(seed: (new.seed &* 0xC4CE_B9FE_1A85_EC53) ^ 0x1B87_3593_CC9E_2D51)
            stage.work.memory = nil
            nextID = 0
        }
        let guests = guestList(for: new)
        for i in bugs.indices where !bugs[i].rare {
            let valid = bugs[i].guest ? guests.contains(bugs[i].species) : new.season.cast.contains(bugs[i].species)
            if !valid { bugs[i].retiring = true }
        }
        let wanted = max(0, new.population)
        let wantedGuests = guestTarget(population: wanted, guests: guests)
        let wantedCast = wanted - wantedGuests
        let guestsActive = trim(guest: true, to: wantedGuests)
        let castActive = trim(guest: false, to: wantedCast)
        bugs.removeAll { $0.retiring && $0.mode == .hidden }
        let guestNeed = wantedGuests - guestsActive
        let castNeed = wantedCast - castActive
        var g = guestNeed, c = castNeed
        while g > 0 || c > 0 {
            let asGuest = c == 0 || (g > 0 && g * castNeed >= c * guestNeed)
            bugs.append(makeBug(serial: nextID, config: new, guest: asGuest))
            nextID += 1
            if asGuest { g -= 1 } else { c -= 1 }
        }
        applied = new
    }

    private func trim(guest: Bool, to wanted: Int) -> Int {
        var active = 0
        for b in bugs where !b.retiring && !b.rare && b.guest == guest { active += 1 }
        var i = bugs.count - 1
        while i >= 0 && active > wanted {
            if !bugs[i].retiring && !bugs[i].rare && bugs[i].guest == guest {
                bugs[i].retiring = true
                active -= 1
            }
            i -= 1
        }
        return active
    }

    func makeBug(serial: Int, config: WorldConfig, guest: Bool = false, species chosen: Species? = nil) -> Bug {
        let t = tuning
        var r = SplitMix64(seed: (config.seed &* 0x9E37_79B9_7F4A_7C15) ^ (UInt64(truncatingIfNeeded: serial) &* 0xC2B2_AE3D_27D4_EB4F) ^ 0x1656_67B1_9E37_79F9)
        _ = r.next()
        let pool = chosen.map { [$0] } ?? (guest ? guestList(for: config) : config.season.cast)
        var totalWeight = 0.0
        for s in pool { totalWeight += max(0, t.traits(for: s).weight) }
        var species = pool.first ?? .butterfly
        if totalWeight > 0 {
            var pick = r.unit() * totalWeight
            for s in pool {
                pick -= max(0, t.traits(for: s).weight)
                if pick <= 0 {
                    species = s
                    break
                }
            }
        } else if !pool.isEmpty {
            species = pool[Int(r.unit() * Double(pool.count)) % pool.count]
        }
        let tr = t.traits(for: species)
        let size = tr.sizeRange.lowerBound + (tr.sizeRange.upperBound - tr.sizeRange.lowerBound) * pow(r.unit(), 1.25)
        let nerve = t.nerveRange.lowerBound + (t.nerveRange.upperBound - t.nerveRange.lowerBound) * pow(r.unit(), t.nerveSkew)
        var b = Bug(
            id: serial,
            species: species,
            size: size,
            nerve: nerve,
            tint: r.unit(),
            venture: t.ventureRange.lowerBound + (t.ventureRange.upperBound - t.ventureRange.lowerBound) * pow(r.unit(), 0.8),
            wallAffinity: 0.15 + 0.6 * r.unit() * r.unit(),
            tempo: r.range(0.85...1.15),
            antennaRate: r.range(0.8...1.25),
            fleeVariance: r.range(0.92...1.08)
        )
        b.guest = guest
        b.antennaPhase = r.unit() * 6.283
        b.gaitPhase = r.unit()
        let u = r.unit()
        b.emergeTimer = t.emergeDelay.lowerBound + (t.emergeDelay.upperBound - t.emergeDelay.lowerBound) * u * u
        b.sway = r.unit() * 6.283
        b.facing = r.chance(0.5) ? 1 : -1
        b.circle = r.chance(0.5) ? 1 : -1
        if species.locomotion == .hop { b.gaitPhase = 0 }
        return b
    }

    private func advance(_ h: Double) {
        syncConfig()
        time += h
        let t = tuning
        let span = max(1e-6, t.litAngle - t.darkAngle)
        targetLight = clamp01((lidAngle - t.darkAngle) / span)
        let previous = light
        light += (targetLight - light) * (1 - exp(-h / max(1e-4, t.lightSmoothing)))
        if abs(targetLight - light) < 0.0005 { light = targetLight }
        let raw = (light - previous) / h
        lightRate += (raw - lightRate) * (1 - exp(-h / max(1e-4, t.lightRateSmoothing)))
        if raw == 0 && abs(lightRate) < 1e-3 { lightRate = 0 }
        peakRate = max(peakRate * exp(-h / max(1e-4, t.panicMemory)), lightRate)
        trackDark(h)
        senseLid(h)

        computeAvoidance()
        othersRunning = false
        var members = 0
        var out = 0
        var visible = 0
        for b in bugs {
            if b.mode != .hidden { visible += 1 }
            if b.retiring || b.rare { continue }
            members += 1
            if b.mode != .hidden { out += 1 }
        }
        stage.visible = visible
        for b in bugs where b.stray == nil && (b.mode == .fleeing || (b.mode == .startled && !b.flinchOnly)) {
            othersRunning = true
            break
        }
        let allowed = emergeAllowance(members: members)
        let rareReady = rareFast || darkSeconds >= t.rareMinDark
        emergeGap -= h
        startledThisStep = 0
        direct(h)
        var emergedNow = 0
        var visitor: Species?
        var removeAny = false
        for i in bugs.indices {
            var b = bugs[i]
            if b.mode == .hidden {
                if b.retiring {
                    removeAny = true
                } else if light < b.nerve - t.nerveHysteresis && lightRate < t.startleRate * 0.5 && (b.rare ? rareReady : out < allowed) {
                    b.emergeTimer -= h
                    if b.emergeTimer <= 0 && emergeGap <= 0 {
                        let room = b.rare ? 0 : (allowed == Int.max ? Int.max : allowed - out - 1)
                        let extra = emerge(&b, room: room)
                        emergeGap = t.emergeMinGap
                        emergedNow += 1 + extra
                        if b.rare {
                            if !rareAnnounced { visitor = b.species }
                        } else {
                            out += 1 + extra
                        }
                    }
                }
            } else {
                update(&b, h: h, ax: avoidX[i], ay: avoidY[i])
                if b.mode == .hidden && b.retiring { removeAny = true }
            }
            bugs[i] = b
        }
        sweepCatch()
        if removeAny { bugs.removeAll { $0.retiring && $0.mode == .hidden } }
        tendProps(h)

        if emergedNow > 0 {
            if case .emerged(let n)? = events.last {
                events[events.count - 1] = .emerged(count: n + emergedNow)
            } else {
                pushEvent(.emerged(count: emergedNow))
            }
            if let v = visitor {
                rareAnnounced = true
                pushEvent(.rareVisitor(v))
            }
            if !darkEpisode { beginDarkEpisode() }
        }
        updateEpisode(h)
        publish()
        updateActivity(h)
        if darkEpisode && critters.isEmpty && light >= 0.999 { endDarkEpisode() }
    }

    private func trackDark(_ h: Double) {
        if isDarkNow {
            darkSeconds += h
            brightSeconds = 0
        } else if darkSeconds > 0 {
            brightSeconds += h
            if brightSeconds > tuning.growthGrace {
                darkSeconds = 0
                brightSeconds = 0
            }
        }
    }

    func primeDark() {
        darkSeconds = max(darkSeconds, tuning.growthSeconds)
        brightSeconds = 0
    }

    var isDarkNow: Bool {
        light < tuning.nerveRange.upperBound - tuning.nerveHysteresis
    }

    func noteEmerged(_ n: Int) {
        guard n > 0 else { return }
        if case .emerged(let m)? = events.last {
            events[events.count - 1] = .emerged(count: m + n)
        } else {
            pushEvent(.emerged(count: n))
        }
    }

    func pushEvent(_ e: WorldEvent) {
        if events.count >= 256 { events.removeFirst(events.count - 255) }
        events.append(e)
    }

    private func updateEpisode(_ h: Double) {
        let t = tuning
        var running = 0
        var doomed = 0
        var visible = 0
        for b in bugs where b.mode != .hidden {
            visible += 1
            if b.mode == .fleeing || (b.mode == .startled && !b.flinchOnly) {
                running += 1
            } else if targetLight > b.nerve + t.nerveHysteresis {
                doomed += 1
            }
        }
        if startledThisStep > 0 && !episodeActive {
            episodeActive = true
            episodePending = true
            episodeTimer = t.scatterEventLatency
            episodePeak = 0
        }
        if episodeActive {
            episodePeak = max(episodePeak, max(lightRate, peakRate))
            if episodePending {
                episodeTimer -= h
                if episodeTimer <= 0 || running == 0 {
                    episodePending = false
                    let p = panicLevel(rate: episodePeak)
                    let fraction = clamp01(Double(running + doomed) / Double(max(1, max(visible, min(config.population, 12)))))
                    pushEvent(.scatter(intensity: clamp01((0.2 + 0.8 * p) * (0.35 + 0.65 * fraction.squareRoot()))))
                    considerStraggler(panic: p)
                }
            }
            if running == 0 {
                episodeQuiet += h
                if episodeQuiet > t.scatterQuietTime && lightRate < 0.05 {
                    episodeActive = false
                }
            } else {
                episodeQuiet = 0
            }
        }
    }

    private func publish() {
        critters.removeAll(keepingCapacity: true)
        for b in bugs where b.mode != .hidden {
            var windup = 0.0, dash = 0.0, fright = 0.0
            var quirk = CatchQuirk.none
            if let beat = b.beat {
                quirk = beat.quirk
                let held = b.mode == .startled && (b.stray == nil || !(b.stray?.started ?? true))
                if held {
                    fright = max(0.001, time - beat.start)
                    if time >= beat.bolt { windup = max(0.001, time - beat.bolt) }
                }
            } else if b.mode == .startled && !b.flinchOnly && b.stray == nil {
                fright = max(0.001, b.fleeElapsed)
            }
            if b.mode == .fleeing && b.dashStart >= 0 && b.stray == nil { dash = max(0.001, time - b.dashStart) }
            critters.append(Critter(
                id: b.id,
                species: b.species,
                position: CGPoint(x: b.x, y: b.y),
                heading: b.heading,
                speed: b.pace,
                size: b.size,
                mode: b.mode,
                gaitPhase: b.gaitPhase,
                bend: b.bend,
                antennaPhase: b.antennaPhase,
                tint: b.tint,
                alpha: b.alpha,
                confusion: b.confusion,
                facing: b.beat == nil ? b.facing : catchFacing(b),
                lift: b.lift,
                fright: fright,
                gesture: b.gesture,
                gestureTime: b.gesture == .none ? 0 : max(0, time - b.gestureStart),
                windup: windup,
                dash: dash,
                dashFrom: CGPoint(x: b.dashX, y: b.dashY),
                quirk: quirk
            ))
        }
        publishProps()
    }

    private func updateActivity(_ h: Double) {
        var raw = 0.0
        for b in bugs where b.mode != .hidden {
            raw += min(14, b.pace / max(1, b.size))
        }
        let target = 1 - exp(-raw / max(1e-3, tuning.activityScale))
        activity += (target - activity) * (1 - exp(-h / 0.1))
        if critters.isEmpty && activity < 0.002 { activity = 0 }
        activity = clamp01(activity)
    }

    private func computeAvoidance() {
        let n = bugs.count
        if avoidX.count != n {
            avoidX = [Double](repeating: 0, count: n)
            avoidY = [Double](repeating: 0, count: n)
        } else {
            for i in 0..<n {
                avoidX[i] = 0
                avoidY[i] = 0
            }
        }
        let k = tuning.avoidRadius
        if n < 2 { return }
        for i in 0..<(n - 1) {
            let a = bugs[i]
            if a.mode == .hidden || a.mode == .fleeing { continue }
            for j in (i + 1)..<n {
                let b = bugs[j]
                if b.mode == .hidden || b.mode == .fleeing { continue }
                if a.species.isAirborne != b.species.isAirborne { continue }
                let r = (a.size + b.size) * k
                let dx = a.x - b.x
                if dx > r || dx < -r { continue }
                let dy = a.y - b.y
                if dy > r || dy < -r { continue }
                let d2 = dx * dx + dy * dy
                if d2 >= r * r || d2 < 1e-9 { continue }
                let d = d2.squareRoot()
                let push = (1 - d / r) / d
                avoidX[i] += dx * push
                avoidY[i] += dy * push
                avoidX[j] -= dx * push
                avoidY[j] -= dy * push
            }
        }
    }

    func panicLevel(rate: Double) -> Double {
        let t = tuning
        return clamp01((rate - t.panicRateFloor) / max(1e-6, t.panicRateFull - t.panicRateFloor))
    }

    func inward(_ e: Edge) -> Double {
        switch e {
        case .bottom: return .pi / 2
        case .top: return -.pi / 2
        case .left: return 0
        case .right: return .pi
        }
    }

    func outward(_ e: Edge) -> Double {
        switch e {
        case .bottom: return -.pi / 2
        case .top: return .pi / 2
        case .left: return .pi
        case .right: return 0
        }
    }

    func depth(_ x: Double, _ y: Double, from e: Edge) -> Double {
        switch e {
        case .bottom: return y
        case .top: return height - y
        case .left: return x
        case .right: return width - x
        }
    }

    func span(_ e: Edge) -> Double {
        switch e {
        case .bottom, .top: return width
        case .left, .right: return height
        }
    }

    func perpendicular(_ e: Edge) -> Double {
        switch e {
        case .bottom, .top: return height
        case .left, .right: return width
        }
    }

    func along(_ x: Double, _ y: Double, on e: Edge) -> Double {
        switch e {
        case .bottom, .top: return x
        case .left, .right: return y
        }
    }

    func point(on e: Edge, along a: Double, depth d: Double) -> (x: Double, y: Double) {
        switch e {
        case .bottom: return (a, d)
        case .top: return (a, height - d)
        case .left: return (d, a)
        case .right: return (width - d, a)
        }
    }

    func edgeDistance(_ x: Double, _ y: Double) -> Double {
        min(min(x, width - x), min(y, height - y))
    }

    func nearestEdge(_ x: Double, _ y: Double) -> Edge {
        var best = Edge.bottom
        var cost = Double.infinity
        for e in Edge.allCases {
            let c = depth(x, y, from: e)
            if c < cost {
                cost = c
                best = e
            }
        }
        return best
    }

    func exitEdge(for b: Bug) -> Edge {
        let t = tuning
        var best = Edge.bottom
        var cost = Double.infinity
        for e in Edge.allCases {
            var c = max(0, depth(b.x, b.y, from: e))
            if e == .left || e == .right { c *= max(0.01, t.sideEdgeBias) }
            if e == b.entry { c *= max(0.01, t.homeEdgeBias) }
            if c < cost {
                cost = c
                best = e
            }
        }
        return best
    }

    func reach(for b: Bug) -> Double {
        let t = tuning
        let dark = clamp01((b.nerve - light) / max(0.05, b.nerve))
        let c = perpendicular(b.entry) * t.maxVenture * b.venture * pow(dark, t.ventureDarknessCurve) * duskCaution()
        return max(b.size * 2.2, c)
    }

    func homeDepth(_ b: Bug) -> Double {
        depth(b.x, b.y, from: b.entry)
    }

    func overReach(_ b: Bug, slack: Double) -> Bool {
        homeDepth(b) > reach(for: b) + slack || edgeDistance(b.x, b.y) > tuning.maxEdgeDistance + slack
    }

    private func alongWall(_ e: Edge, course: Double) -> Double {
        let n = inward(e)
        let a = n - .pi / 2 + tuning.wallAngle
        let b = n + .pi / 2 - tuning.wallAngle
        return cos(course - (n - .pi / 2)) >= 0 ? a : b
    }

    private func entryEdge() -> Edge {
        let t = tuning
        let weights: [(Edge, Double)] = [
            (.bottom, max(0, t.bottomEntryWeight)),
            (.left, max(0, t.leftEntryWeight)),
            (.right, max(0, t.rightEntryWeight)),
            (.top, max(0, t.topEntryWeight)),
        ]
        var total = 0.0
        for (_, w) in weights { total += w }
        var pick = rng.unit() * total
        if total <= 0 { return .bottom }
        for (e, w) in weights where w > 0 {
            pick -= w
            if pick <= 0 { return e }
        }
        return .bottom
    }

    func emerge(_ b: inout Bug, room: Int) -> Int {
        let t = tuning
        let tr = t.traits(for: b.species)
        let w = width, ht = height
        let out = b.size * 0.6
        let edge = entryEdge()
        let margin = min(max(t.entryCornerMargin, 0), 0.45)
        let a = span(edge) * rng.range(margin...(1 - margin))
        b.entry = edge
        switch edge {
        case .bottom:
            b.x = a
            b.y = -out
        case .top:
            b.x = a
            b.y = ht + out
        case .left:
            b.x = -out
            b.y = a
        case .right:
            b.x = w + out
            b.y = a
        }
        b.course = wrap(inward(edge) + rng.signed() * (edge == .bottom || edge == .top ? 0.5 : 0.45))
        b.heading = b.course
        b.desired = b.course
        b.mode = .emerging
        b.speed = 0
        b.targetSpeed = tr.cruise * b.size * b.tempo * 0.85
        b.timer = 4
        b.emergeDepth = b.size * 1.3 + rng.unit() * 90
        if rng.chance(t.peekChance) {
            b.peekDepth = b.size * rng.range(-0.15...0.3)
            b.peekTimer = rng.range(t.peekPause)
        } else {
            b.peekTimer = 0
        }
        b.alpha = 1
        b.bend = 0
        b.meander = 0
        b.fading = false
        b.litTime = 0
        b.flinched = false
        b.goalTimer = 0
        b.stray = nil
        b.beat = nil
        b.dashStart = -1
        b.confusion = 0
        b.pace = 0
        b.lift = 0
        b.hopSpeed = 0
        b.facingHold = 0
        clearScripts(&b)
        let c = cos(b.course)
        if abs(c) > 0.2 { b.facing = c > 0 ? 1 : -1 }
        if b.species.locomotion == .hop { b.gaitPhase = b.gaitPhase.rounded(.down) }
        let extra = chooseEntrance(&b, room: room)
        refreshGesture(&b)
        return extra
    }

    func hide(_ b: inout Bug) {
        let t = tuning
        b.mode = .hidden
        b.speed = 0
        b.pace = 0
        b.lift = 0
        b.alpha = 1
        b.fading = false
        b.litTime = 0
        b.stray = nil
        b.beat = nil
        b.dashStart = -1
        b.confusion = 0
        clearScripts(&b)
        b.keep = -1
        b.grab = -1
        b.gesture = .none
        let u = rng.unit()
        b.emergeTimer = rng.range(t.reemergeCooldown) + (t.emergeDelay.upperBound - t.emergeDelay.lowerBound) * 0.6 * u * u
    }

    private func update(_ b: inout Bug, h: Double, ax: Double, ay: Double) {
        let t = tuning
        let tr = t.traits(for: b.species)
        let w = width, ht = height
        let previousHeading = b.heading
        let hyst = t.nerveHysteresis
        let mustLeave = b.retiring || light > b.nerve + hyst || light >= t.fullLight
        let aboutToLeave = lightRate > t.startleRate && min(targetLight, light + lightRate * t.startleLookahead) > b.nerve + hyst
        let safe = !b.retiring && !b.fading && light < b.nerve - hyst && targetLight < b.nerve - hyst
        if lightRate < t.flinchRate * 0.3 { b.flinched = false }
        var pivoted = 0.0

        if b.stray != nil {
            pivoted = strayStep(&b, tr: tr, h: h, safe: safe)
        } else if b.scripted, let p = scriptStep(&b, tr: tr, h: h, leave: mustLeave || aboutToLeave, safe: safe) {
            pivoted = p
            if b.mode == .hidden { return }
        } else {
            switch b.mode {
            case .hidden:
                return
            case .emerging, .wandering, .resting:
                if mustLeave || aboutToLeave {
                    depart(&b, tr: tr)
                } else if lightRate > t.flinchRate && !b.flinched {
                    b.flinched = true
                    startle(&b, flinch: true)
                } else if b.mode == .emerging {
                    creepIn(&b, tr: tr, h: h)
                } else if b.mode == .wandering {
                    wander(&b, tr: tr, h: h, ax: ax, ay: ay)
                } else {
                    pivoted = rest(&b, tr: tr, h: h, crowded: ax != 0 || ay != 0)
                }
            case .startled where b.beat != nil:
                catchStep(&b, tr: tr, h: h, safe: safe)
            case .startled:
                b.fleeElapsed += h
                if !b.retiring { b.panic = max(b.panic, panicLevel(rate: max(lightRate, peakRate))) }
                b.speed *= exp(-h / 0.035)
                if b.speed < 0.5 { b.speed = 0 }
                b.timer -= h
                if safe && !b.flinchOnly && lightRate <= 0 {
                    settle(&b)
                } else if b.timer <= 0 {
                    if b.flinchOnly && !mustLeave && targetLight <= b.nerve + hyst {
                        settle(&b)
                    } else {
                        beginFlee(&b, tr: tr)
                    }
                }
            case .fleeing:
                if safe && lightRate <= 0.02 && b.y > 0 && b.x > 0 && b.x < w && b.y < ht {
                    settle(&b)
                    b.timer = rng.range(0.15...0.5)
                } else if b.grab < 0 || !grabStep(&b, h: h) {
                    flee(&b, h: h)
                }
            }
        }

        let routine = b.stray.map { $0.started && !$0.exiting } ?? false
        if b.stray == nil {
            if light >= t.fullLight { b.litTime += h } else { b.litTime = 0 }
            if b.litTime > t.failsafeSeconds { b.fading = true }
            if b.confusion > 0 { b.confusion = max(0, b.confusion - h / max(1e-3, t.confusedCalmTime)) }
        }
        if b.mode == .fleeing && !routine && b.fleeElapsed > b.fleeDeadline + t.failsafeGrace { b.fading = true }
        if let s = b.stray, s.elapsed > t.confusedMaxSeconds + t.failsafeSeconds { b.fading = true }

        if !b.species.isAirborne && b.species.locomotion != .hop { b.gaitPhase += pivoted }
        locomote(&b, tr: tr, h: h)
        let turn = wrap(b.heading - previousHeading) / h
        let bendTarget = max(-1, min(1, turn / max(0.1, tr.bendRate)))
        b.bend += (bendTarget - b.bend) * (1 - exp(-h / 0.1))

        var flutter = 2.2
        switch b.mode {
        case .startled: flutter = routine ? 9 : 15
        case .fleeing: flutter = 9
        case .resting: flutter = b.timer > b.pivotWindow ? 5.5 : 2.6
        case .emerging: flutter = b.speed < 1 ? 7 : 4
        default: flutter = 3.2 + min(3, b.speed / max(1, b.size))
        }
        b.antennaPhase += flutter * b.antennaRate * h
        if b.antennaPhase > 1e6 { b.antennaPhase -= 1e6 }
        if b.gaitPhase > 1e6 { b.gaitPhase -= 1e6 }
        b.goalTimer -= h

        if routine {
            keepInBox(&b, h: h)
        } else if b.mode == .wandering || b.mode == .resting || b.mode == .startled {
            let pad = b.size * 0.3
            b.x = min(max(b.x, pad), max(pad, w - pad))
            b.y = min(max(b.y, pad), max(pad, ht - pad))
        }

        if !(b.x.isFinite && b.y.isFinite && b.course.isFinite && b.speed.isFinite) {
            b.x = 0
            b.y = 0
            b.course = -.pi / 2
            b.heading = b.course
            b.bend = 0
            hide(&b)
            return
        }
        if b.fading {
            b.alpha -= h / max(1e-3, t.fadeTime)
            if b.alpha <= 0 {
                hide(&b)
                return
            }
        }
        if b.mode == .fleeing && !routine {
            let out = b.size * 0.6
            if b.y < -out || b.y > ht + out || b.x < -out || b.x > w + out {
                hide(&b)
                return
            }
        }
        refreshGesture(&b)
    }

    func creepIn(_ b: inout Bug, tr: SpeciesTraits, h: Double) {
        let depth = homeDepth(b)
        b.timer -= h
        if b.peekTimer > 0 && depth >= b.peekDepth {
            b.peekTimer -= h
            b.speed *= exp(-h / 0.06)
            if b.speed < 0.5 { b.speed = 0 }
            return
        }
        b.meander += (-b.meander / 0.5) * h + rng.gauss() * tr.meander * 0.6 * h.squareRoot()
        let d = wrap(b.desired + b.meander - b.course)
        b.course = wrap(b.course + max(-tr.turnRate, min(tr.turnRate, d * 4)) * h)
        approach(&b.speed, b.targetSpeed, rate: b.targetSpeed / 0.15, h: h)
        if depth >= b.emergeDepth || b.timer <= 0 {
            startBurst(&b, tr: tr)
        }
    }

    func rollGoal(_ b: inout Bug) {
        let s = span(b.entry)
        b.goalAlong = min(max(along(b.x, b.y, on: b.entry) + rng.signed() * 420, s * 0.03), s * 0.97)
        b.goalFrac = pow(rng.unit(), 1 + 2 * b.wallAffinity) * goalHug()
        b.goalTimer = rng.range(8...20)
    }

    func goalPoint(_ b: Bug) -> (x: Double, y: Double) {
        let pad = b.size * 0.7
        let top = reach(for: b)
        return point(on: b.entry, along: b.goalAlong, depth: pad + max(0, top - pad) * b.goalFrac)
    }

    func startBurst(_ b: inout Bug, tr: SpeciesTraits) {
        let t = tuning
        let top = reach(for: b)
        var goal = goalPoint(b)
        if b.goalTimer <= 0 || (abs(goal.x - b.x) < 40 && abs(goal.y - b.y) < 40) {
            rollGoal(&b)
            goal = goalPoint(b)
        }
        var desired: Double
        if rng.chance(t.goalSeeking) {
            desired = atan2(goal.y - b.y, goal.x - b.x) + rng.gauss() * 0.45
        } else {
            desired = b.course + rng.gauss() * tr.turnSpread
        }
        if homeDepth(b) > top * 0.85 && rng.chance(0.7) {
            desired = outward(b.entry) + rng.signed() * 1.1
        }
        let near = nearestEdge(b.x, b.y)
        if depth(b.x, b.y, from: near) < b.size * 2.5 {
            let n = inward(near)
            if rng.chance(b.wallAffinity) {
                desired = alongWall(near, course: b.course) + rng.gauss() * 0.05
            } else if cos(desired - n) < 0 {
                desired = 2 * n + .pi - desired
            }
        }
        let cruise = tr.cruise * b.size * b.tempo
        if rng.chance(tr.dashChance) {
            b.targetSpeed = cruise * tr.dashBoost * rng.range(0.9...1.15)
            b.timer = rng.range(0.15...0.4)
        } else {
            b.targetSpeed = cruise * rng.range(0.75...1.15)
            b.timer = rng.range(tr.burst)
        }
        b.desired = wrap(desired)
        b.mode = .wandering
        b.restGesture = .none
    }

    private func wander(_ b: inout Bug, tr: SpeciesTraits, h: Double, ax: Double, ay: Double) {
        let t = tuning
        let pad = b.size * 0.7
        b.timer -= h
        var desired = b.desired
        var hurry = false
        if overReach(b, slack: t.ceilingSlack) {
            let home = exitEdge(for: b)
            if home != b.entry && depth(b.x, b.y, from: home) < homeDepth(b) {
                b.entry = home
                b.goalTimer = 0
            }
            if overReach(b, slack: t.ceilingSlack) {
                let tangent = inward(b.entry) + .pi / 2
                let side: Double = cos(b.course - tangent) >= 0 ? 1 : -1
                desired = outward(b.entry) - side * 0.61
                b.desired = desired
                hurry = true
                if b.timer < 0.25 { b.timer = 0.25 }
            }
        }
        for e in Edge.allCases where depth(b.x, b.y, from: e) < pad && cos(desired - inward(e)) < 0 {
            desired = alongWall(e, course: desired)
            b.desired = desired
        }
        b.meander += (-b.meander / 0.5) * h + rng.gauss() * tr.meander * h.squareRoot()
        desired += b.meander
        if ax != 0 || ay != 0 {
            let away = atan2(ay, ax)
            let weight = b.species.isAirborne ? t.airAvoidance : 1
            desired += max(-1.2, min(1.2, wrap(away - b.course))) * min(1, hypot(ax, ay)) * t.avoidance * weight
        }
        let d = wrap(desired - b.course)
        b.course = wrap(b.course + max(-tr.turnRate, min(tr.turnRate, d * t.steerGain)) * h)
        let cruise = tr.cruise * b.size * b.tempo
        var target = b.targetSpeed * (hurry ? t.hurryBoost : 1)
        target *= 0.6 + 0.4 * max(0, cos(d))
        target = min(target, t.fleeSpeedCap * 0.9)
        approach(&b.speed, target, rate: max(cruise, target) / 0.12, h: h)
        if b.timer <= 0 {
            if rng.chance(tr.chainChance) {
                startBurst(&b, tr: tr)
            } else {
                b.mode = .resting
                var pause = rng.range(tr.pause)
                if rng.chance(0.08) { pause *= 2.5 }
                b.timer = pause
                b.pivotWindow = pause * rng.range(0.2...0.45)
                b.pivot = wrap(b.course + rng.gauss() * tr.turnSpread * 0.8)
                if b.species.locomotion == .flutter { b.circle = rng.chance(0.5) ? 1 : -1 }
                beganRest(&b)
            }
        }
    }

    private func rest(_ b: inout Bug, tr: SpeciesTraits, h: Double, crowded: Bool) -> Double {
        let t = tuning
        let drift = restDrift(b, tr: tr)
        if drift > 0 {
            approach(&b.speed, drift, rate: max(drift, b.speed) / 0.4, h: h)
            if b.species.locomotion == .flutter && b.timer >= b.pivotWindow {
                b.course = wrap(b.course + b.circle * 0.9 * h)
            }
        } else {
            b.speed *= exp(-h / 0.07)
            if b.speed < 0.5 { b.speed = 0 }
        }
        b.timer -= crowded ? h * 2 : h
        if overReach(b, slack: t.ceilingSlack) && b.timer > 0.2 { b.timer = 0.2 }
        var pivoted = 0.0
        if b.timer < b.pivotWindow {
            let d = wrap(b.pivot - b.course)
            let step = max(-tr.turnRate * 0.6, min(tr.turnRate * 0.6, d * 5)) * h
            b.course = wrap(b.course + step)
            pivoted = abs(step) * 0.3
        }
        if b.timer <= 0 { startBurst(&b, tr: tr) }
        return pivoted
    }

    func restDrift(_ b: Bug, tr: SpeciesTraits) -> Double {
        switch b.species.locomotion {
        case .flutter: return tr.cruise * b.size * b.tempo * 0.45
        case .float: return tr.cruise * b.size * b.tempo * 0.35
        default: return 0
        }
    }

    func settle(_ b: inout Bug) {
        clearScripts(&b)
        b.beat = nil
        b.dashStart = -1
        b.keep = -1
        b.grab = -1
        b.mode = .resting
        b.timer = rng.range(0.3...1.0)
        b.pivotWindow = b.timer * 0.4
        b.pivot = b.course
        b.flinchOnly = false
        b.wrongWay = 0
    }

    func startle(_ b: inout Bug, flinch: Bool) {
        let t = tuning
        var p = panicLevel(rate: max(lightRate, peakRate))
        if b.retiring && p < 0.3 { p = 0.3 }
        b.panic = p
        let u = pow(rng.unit(), 1.2)
        let depth = clamp01(edgeDistance(b.x, b.y) / max(1, min(width, height) * 0.5))
        let mix = (1 - t.rippleWeight) * u + t.rippleWeight * (1 - depth)
        var delay = t.startleDelay.lowerBound + (t.startleDelay.upperBound - t.startleDelay.lowerBound) * mix
        delay *= t.startleSlowScale + (t.startleSnapScale - t.startleSlowScale) * p
        b.wrongWay = 0
        b.beat = nil
        b.dashStart = -1
        noteGrab(&b, flinch: flinch)
        clearScripts(&b)
        if !flinch && catchReady(b) {
            b.mode = .startled
            b.fleeElapsed = 0
            b.flinchOnly = false
            joinCatch(&b)
            b.fleeHead = 0
            b.timer = max(0.05, (b.beat?.bolt ?? time) + (b.beat?.windup ?? 0) - time)
            startledThisStep += 1
            return
        }
        if !flinch && rng.chance(t.hesitantChance) {
            if rng.chance(0.5) {
                delay += rng.range(t.hesitation) * (1 - 0.4 * p)
            } else {
                b.wrongWay = rng.range(t.wrongWay) * (1 - 0.25 * p)
            }
        }
        b.fleeHead = max(0, delay)
        b.mode = .startled
        b.timer = delay
        b.fleeElapsed = 0
        b.flinchOnly = flinch
        if !flinch && !b.retiring { startledThisStep += 1 }
    }

    func beginFlee(_ b: inout Bug, tr: SpeciesTraits) {
        let t = tuning
        let p = b.panic
        b.fleeEdge = exitEdge(for: b)
        b.fleeAim = rng.signed() * t.fleeAimSpread
        let mid = (tr.sizeRange.lowerBound + tr.sizeRange.upperBound) / 2
        let base = min(max(tr.fleeSpeed * pow(b.size / max(1, mid), t.fleeSizeExponent), t.fleeSpeedRange.lowerBound), t.fleeSpeedRange.upperBound)
        let factor = t.fleeSlowFactor + (t.fleeSnapFactor - t.fleeSlowFactor) * p
        b.fleeTop = min(t.fleeSpeedCap, base * factor * b.fleeVariance)
        let full = t.clearTimeSlow + (t.clearTimeSnap - t.clearTimeSlow) * p
        b.fleeDeadline = max(full * 0.6, full - min(max(0, b.fleeHead), b.fleeElapsed) - 0.1)
        b.wobbleAmp = rng.range(t.fleeWobble) * (0.55 + 0.45 * p)
        b.wobbleRate = rng.range(t.fleeWobbleHz) * 2 * .pi
        b.wobblePhase = rng.unit() * 2 * .pi
        if b.wrongWay > 0 {
            b.wrongHeading = wrap(fleeDirection(b) + .pi + rng.signed() * 0.8)
        }
        b.mode = .fleeing
        b.flinchOnly = false
        b.fleeElapsed = 0
    }

    private func fleeDirection(_ b: Bug) -> Double {
        outward(b.fleeEdge) + b.fleeAim
    }

    func flee(_ b: inout Bug, h: Double) {
        let t = tuning
        b.fleeElapsed += h
        var direction = fleeDirection(b)
        var top = b.fleeTop
        let out = b.size * 0.6
        let remaining = depth(b.x, b.y, from: b.fleeEdge) + out
        let needed = remaining * 1.1 / max(0.2, b.fleeDeadline - b.fleeElapsed)
        let urgency = clamp01((needed / max(1, top) - 0.8) / 0.6)
        top = min(t.fleeSpeedCap, max(top, needed))
        direction -= b.fleeAim * urgency
        if b.wrongWay > 0 {
            b.wrongWay -= h
            direction = b.wrongHeading
            top *= 0.75
        }
        for e in Edge.allCases where e != b.fleeEdge && depth(b.x, b.y, from: e) < b.size {
            let n = inward(e)
            if cos(direction - n) < 0 { direction = 2 * n + .pi - direction }
        }
        b.wobblePhase += b.wobbleRate * h
        let desired = direction + b.wobbleAmp * (1 - 0.7 * urgency) * sin(b.wobblePhase)
        let d = wrap(desired - b.course)
        b.course = wrap(b.course + max(-t.fleeTurnRate, min(t.fleeTurnRate, d * 10)) * h)
        let target = top * (0.45 + 0.55 * max(0, cos(d)))
        approach(&b.speed, target, rate: top / max(0.02, t.fleeAccelTime), h: h)
    }

    func approach(_ value: inout Double, _ target: Double, rate: Double, h: Double) {
        let step = rate * h
        if value < target {
            value = min(target, value + step)
        } else {
            value = max(target, value - step)
        }
    }

    func wrap(_ a: Double) -> Double {
        a.remainder(dividingBy: 2 * .pi)
    }

    func clamp01(_ v: Double) -> Double {
        v < 0 ? 0 : (v > 1 ? 1 : v)
    }
}
