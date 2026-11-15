import XCTest
import CoreGraphics
@testable import ScuttleCore

final class LocomotionTests: XCTestCase {
    let screen = CGSize(width: 1512, height: 982)
    let dt = 1.0 / 60.0

    func makeWorld(season: Season, seed: UInt64 = 1, population: Int = 24) -> World {
        let world = World(size: screen, config: WorldConfig(population: population, season: season, seed: seed))
        world.tuning.forceStraggler = false
        world.tuning.growthSeconds = 0
        world.tuning.catchEnabled = false
        world.tuning.forceRare = false
        return world
    }

    func hold(_ world: World, angle: Double, seconds: Double, each: (() -> Void)? = nil) {
        var t = 0.0
        while t < seconds - 1e-9 {
            t += dt
            world.step(dt: dt, lidAngle: angle)
            each?()
        }
    }

    func inside(_ c: Critter) -> Bool {
        let x = Double(c.position.x), y = Double(c.position.y)
        return x > c.size && y > c.size && x < Double(screen.width) - c.size && y < Double(screen.height) - c.size
    }

    func testEverySeasonSpawnsOnlyItsCast() {
        for season in Season.allCases {
            let cast = Set(season.cast)
            XCTAssertEqual(season.cast.count, 4)
            let world = makeWorld(season: season, population: 40)
            var seen = Set<Species>()
            hold(world, angle: 5, seconds: 14) {
                for c in world.critters {
                    XCTAssertTrue(cast.contains(c.species), "\(season) \(c.species)")
                    seen.insert(c.species)
                }
            }
            XCTAssertEqual(seen, cast, "\(season)")
            hold(world, angle: 112, seconds: 4)
            XCTAssertTrue(world.isQuiet, "\(season)")
        }
        let casts = Set(Season.allCases.flatMap(\.cast))
        let guests = Set(Weather.allCases.flatMap { $0.guests(night: false) + $0.guests(night: true) })
        let rares = Set(Species.rareVisitors)
        XCTAssertTrue(casts.isDisjoint(with: rares))
        XCTAssertTrue(guests.isDisjoint(with: rares))
        XCTAssertEqual(casts.union(guests).union(rares), Set(Species.allCases))
        XCTAssertEqual(Set(Season.allCases.map(\.rareVisitor)).union([.ufo]), rares)
    }

    func testSwitchingSeasonReplacesTheCast() {
        let world = makeWorld(season: .summer, seed: 3)
        hold(world, angle: 5, seconds: 12)
        XCTAssertGreaterThan(world.critters.count, 18)
        XCTAssertTrue(world.critters.allSatisfy { Season.summer.cast.contains($0.species) })
        let oldIDs = Set(world.critters.map(\.id))
        world.config.season = .halloween
        var oldFled = false
        hold(world, angle: 5, seconds: 20) {
            for c in world.critters where Season.summer.cast.contains(c.species) {
                XCTAssertTrue(oldIDs.contains(c.id))
                if c.mode == .fleeing { oldFled = true }
            }
        }
        XCTAssertTrue(oldFled)
        XCTAssertEqual(world.critters.count, 24)
        XCTAssertTrue(world.critters.allSatisfy { Season.halloween.cast.contains($0.species) })
        XCTAssertEqual(world.hiddenCount, 0)

        hold(world, angle: 112, seconds: 4)
        XCTAssertTrue(world.isQuiet)
        world.config.season = .newYear
        hold(world, angle: 112, seconds: 0.5)
        hold(world, angle: 5, seconds: 14) {
            XCTAssertTrue(world.critters.allSatisfy { Season.newYear.cast.contains($0.species) })
        }
        XCTAssertEqual(Set(world.critters.map(\.species)), Set(Season.newYear.cast))
    }

    func testHoppersTravelInHops() {
        for season in [Season.spring, .autumn, .winter, .halloween, .christmas] {
            let world = makeWorld(season: season, seed: 5, population: 30)
            var calmTop = 0.0
            var fleeTop = 0.0
            var squats = 0
            var hops = 0
            var previous: [Int: Critter] = [:]
            func check() {
                for c in world.critters {
                    XCTAssertTrue(c.lift >= 0 && c.lift <= 1)
                    if c.species.locomotion != .hop {
                        XCTAssertEqual(c.lift, 0, "\(c.species)")
                        continue
                    }
                    if c.mode == .wandering { calmTop = max(calmTop, c.lift) }
                    if c.mode == .fleeing { fleeTop = max(fleeTop, c.lift) }
                    if let p = previous[c.id], p.mode == .wandering, c.mode == .wandering, inside(c) {
                        if p.lift == 0 && c.lift == 0 {
                            squats += 1
                            XCTAssertEqual(c.position.x, p.position.x, accuracy: 1e-9)
                            XCTAssertEqual(c.position.y, p.position.y, accuracy: 1e-9)
                        } else if p.lift > 0 && c.lift > 0 {
                            hops += 1
                        }
                    }
                    previous[c.id] = c
                }
            }
            hold(world, angle: 5, seconds: 16, each: check)
            hold(world, angle: 112, seconds: 4, each: check)
            XCTAssertGreaterThan(calmTop, 0.5, "\(season)")
            XCTAssertGreaterThan(fleeTop, 0.5, "\(season)")
            XCTAssertGreaterThan(squats, 20, "\(season)")
            XCTAssertGreaterThan(hops, 100, "\(season)")
            XCTAssertTrue(world.isQuiet, "\(season)")
        }
    }

    func testHopCycleMatchesGaitAndFleeingHopsAreBigger() {
        let world = makeWorld(season: .christmas, seed: 2, population: 30)
        var calmHops: [Double] = []
        var fleeHops: [Double] = []
        var start: [Int: (gait: Double, x: Double, y: Double, fleeing: Bool)] = [:]
        func track() {
            for c in world.critters where c.species.locomotion == .hop {
                let cycle = c.gaitPhase.rounded(.down)
                guard let s = start[c.id] else {
                    start[c.id] = (c.gaitPhase, Double(c.position.x), Double(c.position.y), c.mode == .fleeing)
                    continue
                }
                if cycle > s.gait.rounded(.down) {
                    let span = hypot(Double(c.position.x) - s.x, Double(c.position.y) - s.y) / c.size
                    if cycle - s.gait.rounded(.down) == 1 && inside(c) {
                        if s.fleeing && c.mode == .fleeing { fleeHops.append(span) }
                        if !s.fleeing && c.mode == .wandering { calmHops.append(span) }
                    }
                    start[c.id] = (c.gaitPhase, Double(c.position.x), Double(c.position.y), c.mode == .fleeing)
                }
            }
        }
        hold(world, angle: 5, seconds: 16, each: track)
        hold(world, angle: 112, seconds: 4, each: track)
        XCTAssertGreaterThan(calmHops.count, 30)
        XCTAssertGreaterThan(fleeHops.count, 3)
        let calm = calmHops.reduce(0, +) / Double(max(1, calmHops.count))
        let flee = fleeHops.reduce(0, +) / Double(max(1, fleeHops.count))
        XCTAssertGreaterThan(calm, 0.3)
        XCTAssertLessThan(calm, 1.6)
        XCTAssertGreaterThan(flee, calm * 1.5)
    }

    func testFacingIsBinaryAndSteady() {
        for season in Season.allCases {
            let world = makeWorld(season: season, seed: 4, population: 30)
            var flips: [Int: [Double]] = [:]
            var last: [Int: Critter] = [:]
            var agree = 0
            var disagree = 0
            var clock = 0.0
            func check() {
                clock += dt
                for c in world.critters {
                    XCTAssertTrue(c.facing == 1 || c.facing == -1)
                    if let p = last[c.id] {
                        if p.facing != c.facing { flips[c.id, default: []].append(clock) }
                        let dx = Double(c.position.x - p.position.x)
                        let dist = hypot(dx, Double(c.position.y - p.position.y))
                        if c.species.stance == .upright && c.mode == .wandering && dist > 0.5 && abs(dx) > dist * 0.8 {
                            if (dx > 0) == (c.facing > 0) { agree += 1 } else { disagree += 1 }
                        }
                    }
                    last[c.id] = c
                }
            }
            hold(world, angle: 5, seconds: 14, each: check)
            hold(world, angle: 112, seconds: 4, each: check)
            for (id, times) in flips {
                for (i, t) in times.enumerated() {
                    let inWindow = times[i...].prefix { $0 < t + 1 }.count
                    XCTAssertLessThanOrEqual(inWindow, 4, "\(season) id \(id)")
                }
            }
            if Set(season.cast).contains(where: { $0.stance == .upright }) {
                XCTAssertGreaterThan(agree, 100, "\(season)")
                XCTAssertGreaterThan(Double(agree), Double(agree + disagree) * 0.85, "\(season)")
            }
        }
    }

    func testAirborneGaitIsTimeDriven() {
        let calm: [Locomotion: ClosedRange<Double>] = [.flutter: 2.9...4.4, .hover: 5.8...8.8, .dart: 6.0...8.0, .float: 0.4...0.7]
        for season in [Season.summer, .spring, .autumn, .winter, .halloween, .newYear] {
            let world = makeWorld(season: season, seed: 6, population: 30)
            var previous: [Int: Critter] = [:]
            var stillChecked = 0
            var checked = 0
            var calmRate: [Locomotion: [Double]] = [:]
            var fleeRate: [Locomotion: [Double]] = [:]
            func check() {
                for c in world.critters where c.species.isAirborne {
                    if let p = previous[c.id], p.mode == c.mode {
                        let rate = (c.gaitPhase - p.gaitPhase) / dt
                        let kind = c.species.locomotion
                        if c.mode == .wandering || c.mode == .resting {
                            guard let range = calm[kind] else { continue }
                            XCTAssertTrue(range.contains(rate), "\(c.species) \(c.mode) \(rate)")
                            calmRate[kind, default: []].append(rate)
                            checked += 1
                            if c.speed == 0 && p.speed == 0 { stillChecked += 1 }
                        } else if c.mode == .fleeing {
                            fleeRate[kind, default: []].append(rate)
                        }
                    }
                    previous[c.id] = c
                }
            }
            hold(world, angle: 5, seconds: 14, each: check)
            hold(world, angle: 112, seconds: 4, each: check)
            XCTAssertGreaterThan(checked, 500, "\(season)")
            if season.cast.contains(where: { $0.locomotion == .hover || $0.locomotion == .dart }) {
                XCTAssertGreaterThan(stillChecked, 20, "\(season)")
            }
            for (kind, rates) in fleeRate where rates.count > 10 {
                let f = rates.reduce(0, +) / Double(rates.count)
                let c = (calmRate[kind] ?? []).reduce(0, +) / Double(max(1, calmRate[kind]?.count ?? 0))
                XCTAssertGreaterThan(f, c * 1.2, "\(season) \(kind)")
                if kind == .flutter { XCTAssertGreaterThanOrEqual(f, 7, "\(season)") }
            }
        }
    }

    func testFlyersNeverQuiteStopAndFloatersDrift() {
        let world = makeWorld(season: .halloween, seed: 7, population: 30)
        hold(world, angle: 5, seconds: 8)
        var previous: [Int: Critter] = [:]
        var flutterStill = 0
        var flutterFrames = 0
        hold(world, angle: 5, seconds: 10) {
            for c in world.critters {
                if let p = previous[c.id], c.species.locomotion == .flutter, c.mode == .wandering || c.mode == .resting, self.inside(c) {
                    flutterFrames += 1
                    let moved = hypot(Double(c.position.x - p.position.x), Double(c.position.y - p.position.y))
                    if moved < 1e-6 { flutterStill += 1 }
                }
                previous[c.id] = c
            }
        }
        XCTAssertGreaterThan(flutterFrames, 200)
        XCTAssertEqual(flutterStill, 0)
    }

    func testEverySeasonClearsInTimeAfterSnapOpen() {
        for season in Season.allCases {
            for seed in [1, 2, 3, 9] as [UInt64] {
                let a = makeWorld(season: season, seed: seed)
                let b = makeWorld(season: season, seed: seed)
                a.settleInDark()
                b.settleInDark()
                let out = a.critters.count
                XCTAssertGreaterThanOrEqual(out, 18, "\(season) seed \(seed)")
                var t = 0.0
                var gone: Double?
                var atHalf = 0
                var faded = false
                while t < 6 {
                    a.step(dt: dt, lidAngle: 115)
                    b.step(dt: dt, lidAngle: 115)
                    t += dt
                    XCTAssertEqual(a.critters.map(\.id), b.critters.map(\.id))
                    XCTAssertEqual(a.critters.map { Double($0.position.x) }, b.critters.map { Double($0.position.x) })
                    XCTAssertEqual(a.critters.map { Double($0.position.y) }, b.critters.map { Double($0.position.y) })
                    XCTAssertEqual(a.critters.map(\.lift), b.critters.map(\.lift))
                    XCTAssertEqual(a.critters.map(\.facing), b.critters.map(\.facing))
                    if a.critters.contains(where: { $0.alpha < 1 }) { faded = true }
                    if abs(t - 0.5) < dt / 2 { atHalf = a.critters.count }
                    if gone == nil, a.critters.isEmpty { gone = t }
                }
                XCTAssertFalse(faded, "\(season) seed \(seed)")
                XCTAssertGreaterThanOrEqual(Double(atHalf), Double(out) * 0.75, "\(season) seed \(seed)")
                XCTAssertNotNil(gone, "\(season) seed \(seed)")
                XCTAssertGreaterThanOrEqual(gone ?? 0, 1.5, "\(season) seed \(seed)")
                XCTAssertLessThanOrEqual(gone ?? 99, a.tuning.clearTimeSnap, "\(season) seed \(seed)")
                XCTAssertTrue(a.isQuiet && b.isQuiet)
                XCTAssertEqual(a.drainEvents(), b.drainEvents())
            }
        }
    }
}
