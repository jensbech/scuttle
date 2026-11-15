import XCTest
import CoreGraphics
@testable import ScuttleCore

final class WorldTests: XCTestCase {
    let screen = CGSize(width: 1512, height: 982)
    let dt = 1.0 / 60.0

    func makeWorld(population: Int = 24, seed: UInt64 = 1, season: Season = .summer, straggler: Bool? = nil) -> World {
        let world = World(size: screen, config: WorldConfig(population: population, season: season, seed: seed))
        world.tuning.forceStraggler = straggler
        world.tuning.growthSeconds = 0
        world.tuning.catchEnabled = false
        world.tuning.forceRare = false
        return world
    }

    func edgeDistance(_ c: Critter) -> Double {
        let x = Double(c.position.x), y = Double(c.position.y)
        return min(min(x, Double(screen.width) - x), min(y, Double(screen.height) - y))
    }

    @discardableResult
    func run(_ world: World, _ timeline: LidTimeline, from start: Double = 0, to end: Double, each: ((Double) -> Void)? = nil) -> Double {
        var t = start
        while t < end - 1e-9 {
            t += dt
            world.step(dt: dt, lidAngle: timeline.angle(at: t))
            each?(t)
        }
        return t
    }

    func hold(_ world: World, angle: Double, seconds: Double, each: (() -> Void)? = nil) {
        var t = 0.0
        while t < seconds - 1e-9 {
            t += dt
            world.step(dt: dt, lidAngle: angle)
            each?()
        }
    }

    func snapTimeline(darkFor: Double = 16, over: Double = 0.2, to angle: Double = 110) -> LidTimeline {
        LidTimeline(keyframes: [
            .init(t: 0, angle: 110),
            .init(t: 1, angle: 10),
            .init(t: darkFor, angle: 10),
            .init(t: darkFor + over, angle: angle),
        ])
    }

    func signature(_ world: World) -> [Double] {
        var out: [Double] = [world.light, world.lightRate, world.activity]
        for c in world.critters {
            out += [Double(c.id), Double(c.position.x), Double(c.position.y), c.heading, c.speed, c.size, c.gaitPhase, c.bend, c.antennaPhase, c.tint, c.alpha, c.facing, c.lift]
        }
        return out
    }

    func testDeterministicForSeed() {
        let timeline = LidTimeline(keyframes: [
            .init(t: 0, angle: 110), .init(t: 1, angle: 12), .init(t: 9, angle: 12),
            .init(t: 10, angle: 50), .init(t: 13, angle: 20), .init(t: 16, angle: 20), .init(t: 16.2, angle: 115),
        ])
        let a = makeWorld(seed: 77), b = makeWorld(seed: 77), c = makeWorld(seed: 78)
        var eventsA: [WorldEvent] = [], eventsB: [WorldEvent] = []
        var differed = false
        var t = 0.0
        while t < 20 {
            t += dt
            let angle = timeline.angle(at: t)
            a.step(dt: dt, lidAngle: angle)
            b.step(dt: dt, lidAngle: angle)
            c.step(dt: dt, lidAngle: angle)
            eventsA += a.drainEvents()
            eventsB += b.drainEvents()
            XCTAssertEqual(signature(a), signature(b))
            XCTAssertEqual(a.critters.map(\.mode), b.critters.map(\.mode))
            XCTAssertEqual(a.critters.map(\.species), b.critters.map(\.species))
            if signature(a) != signature(c) { differed = true }
        }
        XCTAssertEqual(eventsA, eventsB)
        XCTAssertFalse(eventsA.isEmpty)
        XCTAssertTrue(differed)
    }

    func testNobodyOutInFullLight() {
        let world = makeWorld()
        XCTAssertTrue(world.isQuiet)
        for angle in [85.0, 95, 110, 135] {
            hold(world, angle: angle, seconds: 10) {
                XCTAssertTrue(world.critters.isEmpty)
            }
        }
        XCTAssertTrue(world.isQuiet)
        XCTAssertEqual(world.light, 1, accuracy: 1e-9)
        XCTAssertEqual(world.activity, 0)
        XCTAssertTrue(world.drainEvents().isEmpty)
    }

    func testLightMapping() {
        let world = makeWorld(population: 0)
        hold(world, angle: 15, seconds: 2)
        XCTAssertEqual(world.light, 0, accuracy: 1e-6)
        hold(world, angle: 5, seconds: 1)
        XCTAssertEqual(world.light, 0, accuracy: 1e-6)
        hold(world, angle: 50, seconds: 2)
        XCTAssertEqual(world.light, 0.5, accuracy: 1e-3)
        world.step(dt: dt, lidAngle: 110)
        XCTAssertGreaterThan(world.lightRate, 0)
        XCTAssertLessThan(world.light, 1)
        hold(world, angle: 85, seconds: 2)
        XCTAssertEqual(world.light, 1, accuracy: 1e-6)
        XCTAssertEqual(world.lightRate, 0, accuracy: 1e-3)
        XCTAssertEqual(world.lidAngle, 85)
    }

    func testCrittersEmergeInTheDark() {
        for seed in [1, 2, 3] as [UInt64] {
            let world = makeWorld(seed: seed)
            var emerged = 0
            var firstAt: Double?
            var elapsed = 0.0
            var countAtOne = 0
            var countAtThree = 0
            hold(world, angle: 8, seconds: 12) {
                elapsed += self.dt
                for e in world.drainEvents() {
                    if case .emerged(let n) = e {
                        emerged += n
                        if firstAt == nil { firstAt = elapsed }
                    }
                }
                if abs(elapsed - 1) < self.dt / 2 { countAtOne = world.critters.count }
                if abs(elapsed - 3) < self.dt / 2 { countAtThree = world.critters.count }
            }
            XCTAssertNotNil(firstAt)
            XCTAssertLessThan(firstAt ?? 99, 1.5)
            XCTAssertLessThan(countAtOne, 12)
            XCTAssertGreaterThanOrEqual(countAtThree, 4)
            XCTAssertLessThan(countAtThree, 24)
            XCTAssertGreaterThanOrEqual(world.critters.count, 21)
            XCTAssertEqual(emerged, world.critters.count)
            XCTAssertGreaterThan(world.activity, 0)
            XCTAssertLessThanOrEqual(world.activity, 1)
            XCTAssertFalse(world.isQuiet)
            let deepest = world.critters.map(edgeDistance).max() ?? 0
            XCTAssertGreaterThan(deepest, 200)
        }
    }

    func testBraveOnesComeOutFirstAsItDims() {
        let world = makeWorld()
        hold(world, angle: 60, seconds: 15)
        let dim = world.critters.count
        hold(world, angle: 40, seconds: 15)
        let dimmer = world.critters.count
        hold(world, angle: 10, seconds: 15)
        let dark = world.critters.count
        XCTAssertGreaterThan(dim, 0)
        XCTAssertLessThan(dim, dimmer)
        XCTAssertLessThan(dimmer, dark)
    }

    func testSnapOpenIsReadableNotInstant() {
        for seed in [1, 2, 3, 7, 42, 1234] as [UInt64] {
            let world = makeWorld(seed: seed, straggler: false)
            let darkFor = 16.0
            let timeline = snapTimeline(darkFor: darkFor)
            run(world, timeline, to: darkFor)
            let before = world.critters.count
            XCTAssertGreaterThanOrEqual(before, 20)
            var at: [Double: Int] = [:]
            var lastVisible = 0.0
            var topSpeed = 0.0
            var sawStartled = false
            run(world, timeline, from: darkFor, to: darkFor + 6) { t in
                let since = t - darkFor
                for mark in [0.3, 0.6, 1.2, 1.5, 3.0] where abs(since - mark) < self.dt / 2 {
                    at[mark] = world.critters.count
                }
                if !world.critters.isEmpty { lastVisible = since }
                for c in world.critters {
                    if c.mode == .fleeing { topSpeed = max(topSpeed, c.speed) }
                    if c.mode == .startled { sawStartled = true }
                }
            }
            XCTAssertGreaterThanOrEqual(Double(at[0.3] ?? 0), Double(before) * 0.95, "seed \(seed)")
            XCTAssertGreaterThanOrEqual(Double(at[0.6] ?? 0), Double(before) * 0.75, "seed \(seed)")
            XCTAssertGreaterThanOrEqual(Double(at[1.2] ?? 0), Double(before) * 0.25, "seed \(seed)")
            XCTAssertLessThanOrEqual(Double(at[1.5] ?? 99), Double(before) * 0.75, "seed \(seed)")
            XCTAssertEqual(at[3.0], 0, "seed \(seed)")
            XCTAssertGreaterThanOrEqual(lastVisible, 1.5, "seed \(seed)")
            XCTAssertLessThanOrEqual(lastVisible, 3.0, "seed \(seed)")
            XCTAssertLessThanOrEqual(topSpeed, world.tuning.fleeSpeedCap + 0.001, "seed \(seed)")
            XCTAssertGreaterThan(topSpeed, 180, "seed \(seed)")
            XCTAssertTrue(sawStartled)
            XCTAssertTrue(world.isQuiet)
        }
    }

    func testSnapStartlesAreStaggered() {
        let world = makeWorld(seed: 5, straggler: false)
        let timeline = snapTimeline()
        run(world, timeline, to: 16)
        var fleeStart: [Int: Double] = [:]
        run(world, timeline, from: 16, to: 19) { t in
            for c in world.critters where c.mode == .fleeing && fleeStart[c.id] == nil {
                fleeStart[c.id] = t - 16
            }
        }
        let times = fleeStart.values.sorted()
        XCTAssertGreaterThan(times.count, 12)
        XCTAssertGreaterThan((times.last ?? 0) - (times.first ?? 0), 0.25)
        XCTAssertLessThan(times.last ?? 9, 1.2)
        let distinct = Set(times.map { Int(($0 * 30).rounded()) })
        XCTAssertGreaterThan(distinct.count, 6)
    }

    func testSlowOpenRetreatsGraduallyAndClears() {
        for seed in [1, 2, 3] as [UInt64] {
            let world = makeWorld(seed: seed, straggler: false)
            let timeline = snapTimeline(darkFor: 16, over: 6)
            run(world, timeline, to: 16)
            let before = world.critters.count
            var at: [Double: Int] = [:]
            var topSpeed = 0.0
            var lastVisible = 0.0
            run(world, timeline, from: 16, to: 30) { t in
                let since = t - 16
                for mark in [1.0, 3.5, 5.0] where abs(since - mark) < self.dt / 2 {
                    at[mark] = world.critters.count
                }
                if !world.critters.isEmpty { lastVisible = since }
                for c in world.critters where c.mode == .fleeing { topSpeed = max(topSpeed, c.speed) }
            }
            XCTAssertEqual(at[1.0], before, "seed \(seed)")
            XCTAssertLessThan(at[3.5] ?? 99, before, "seed \(seed)")
            XCTAssertGreaterThan(at[3.5] ?? 0, 0, "seed \(seed)")
            XCTAssertLessThan(at[5.0] ?? 99, at[3.5] ?? 0, "seed \(seed)")
            XCTAssertGreaterThan(lastVisible, 4, "seed \(seed)")
            XCTAssertLessThan(lastVisible, 9, "seed \(seed)")
            XCTAssertLessThan(topSpeed, 260, "seed \(seed)")
            XCTAssertTrue(world.isQuiet)
        }
    }

    func testPartialLightKeepsBoldOnesLowAndTheyReturn() {
        let world = makeWorld()
        hold(world, angle: 10, seconds: 16)
        let dark = world.critters.count
        let darkIDs = Set(world.critters.map(\.id))
        let darkDeepest = world.critters.map(edgeDistance).max() ?? 0
        let timeline = LidTimeline(keyframes: [.init(t: 0, angle: 10), .init(t: 2, angle: 45)])
        run(world, timeline, to: 12)
        let partial = world.critters.count
        XCTAssertGreaterThan(partial, 3)
        XCTAssertLessThan(partial, dark - 3)
        XCTAssertTrue(Set(world.critters.map(\.id)).isSubset(of: darkIDs))
        XCTAssertFalse(world.isQuiet)
        hold(world, angle: 45, seconds: 6) {
            for c in world.critters {
                XCTAssertNotEqual(c.mode, .fleeing)
            }
        }
        XCTAssertEqual(world.critters.count, partial)
        let partialDeepest = world.critters.map(edgeDistance).max() ?? 0
        XCTAssertLessThan(partialDeepest, Double(screen.height) * 0.3)
        XCTAssertLessThan(partialDeepest, darkDeepest)
        hold(world, angle: 10, seconds: 14)
        XCTAssertGreaterThanOrEqual(world.critters.count, dark - 3)
    }

    func testPositionsStayFiniteAndNearBounds() {
        let timeline = LidTimeline(loop: true, keyframes: [
            .init(t: 0, angle: 110), .init(t: 0.5, angle: 5), .init(t: 9, angle: 5),
            .init(t: 9.1, angle: 60), .init(t: 9.3, angle: 12), .init(t: 14, angle: 30, ease: .inOut),
            .init(t: 15, angle: 0), .init(t: 20, angle: 0), .init(t: 20.15, angle: 135), .init(t: 25, angle: 135),
        ])
        let world = makeWorld(population: 120, seed: 11)
        let steps = [1.0 / 60, 1.0 / 30, 1.0 / 120, 1.0 / 24, 1.0 / 60]
        var t = 0.0
        var i = 0
        var ids = Set<Int>()
        while t < 55 {
            let h = steps[i % steps.count]
            i += 1
            t += h
            world.step(dt: h, lidAngle: timeline.angle(at: t))
            ids.removeAll(keepingCapacity: true)
            XCTAssertLessThanOrEqual(world.critters.count, 120)
            XCTAssertTrue(world.light >= 0 && world.light <= 1)
            XCTAssertTrue(world.lightRate.isFinite)
            XCTAssertTrue(world.activity >= 0 && world.activity <= 1)
            for c in world.critters {
                XCTAssertTrue(ids.insert(c.id).inserted)
                XCTAssertNotEqual(c.mode, .hidden)
                let x = Double(c.position.x), y = Double(c.position.y)
                XCTAssertTrue(x.isFinite && y.isFinite && c.heading.isFinite && c.speed.isFinite)
                XCTAssertTrue(c.gaitPhase.isFinite && c.antennaPhase.isFinite)
                XCTAssertTrue(x > -70 && x < Double(screen.width) + 70, "x \(x)")
                XCTAssertTrue(y > -70 && y < Double(screen.height) + 70, "y \(y)")
                XCTAssertTrue(c.heading >= -Double.pi - 1e-9 && c.heading <= Double.pi + 1e-9)
                XCTAssertTrue(c.speed >= 0 && c.speed <= world.tuning.fleeSpeedCap + 0.001)
                XCTAssertTrue(c.bend >= -1 && c.bend <= 1)
                XCTAssertTrue(c.alpha >= 0 && c.alpha <= 1)
                XCTAssertTrue(c.tint >= 0 && c.tint <= 1)
                XCTAssertTrue(c.size >= 9 && c.size <= 61)
                XCTAssertTrue(c.facing == 1 || c.facing == -1)
                XCTAssertTrue(c.lift >= 0 && c.lift <= 1)
            }
        }
    }

    func testOddStepInputsAreHarmless() {
        let world = makeWorld()
        hold(world, angle: 10, seconds: 8)
        let before = signature(world)
        world.step(dt: 0, lidAngle: 10)
        world.step(dt: -1, lidAngle: 10)
        world.step(dt: .nan, lidAngle: 10)
        XCTAssertEqual(signature(world), before)
        world.step(dt: dt, lidAngle: .nan)
        world.step(dt: 5, lidAngle: 10)
        for c in world.critters {
            XCTAssertTrue(c.position.x.isFinite && c.position.y.isFinite)
        }
        world.resize(CGSize(width: 400, height: 300))
        hold(world, angle: 10, seconds: 5) {
            for c in world.critters {
                XCTAssertTrue(c.position.x > -70 && c.position.x < 470)
                XCTAssertTrue(c.position.y > -70 && c.position.y < 370)
            }
        }
        hold(world, angle: 110, seconds: 6)
        XCTAssertTrue(world.isQuiet)
    }

    func testPopulationAndSeasonRespected() {
        let spring = Set(Season.spring.cast)
        let world = makeWorld(population: 12, seed: 4, season: .spring)
        var most = 0
        var seen = Set<Species>()
        hold(world, angle: 5, seconds: 14) {
            most = max(most, world.critters.count)
            for c in world.critters {
                XCTAssertTrue(spring.contains(c.species))
                seen.insert(c.species)
            }
        }
        XCTAssertEqual(most, 12)
        XCTAssertEqual(seen, spring)

        world.config.population = 5
        hold(world, angle: 5, seconds: 8)
        XCTAssertEqual(world.critters.count, 5)

        world.config.season = .winter
        world.config.population = 9
        hold(world, angle: 5, seconds: 16)
        XCTAssertEqual(world.critters.count, 9)
        XCTAssertTrue(world.critters.allSatisfy { Season.winter.cast.contains($0.species) })

        world.config = WorldConfig(population: 0)
        hold(world, angle: 5, seconds: 5)
        XCTAssertTrue(world.critters.isEmpty)
        hold(world, angle: 110, seconds: 1)
        XCTAssertTrue(world.isQuiet)
    }

    func testSpeciesMixAndSizes() {
        for season in Season.allCases {
            let world = makeWorld(population: 120, seed: 21, season: season)
            hold(world, angle: 5, seconds: 14)
            var counts: [Species: Int] = [:]
            for c in world.critters {
                counts[c.species, default: 0] += 1
                let range = world.tuning.traits(for: c.species).sizeRange
                XCTAssertTrue(range.contains(c.size), "\(c.species) \(c.size)")
                XCTAssertTrue(c.size >= 14 && c.size <= 40, "\(c.species) \(c.size)")
            }
            XCTAssertEqual(Set(counts.keys), Set(season.cast), "\(season)")
            XCTAssertGreaterThan(Set(world.critters.map { ($0.tint * 1000).rounded() }).count, 60)
        }
        let castSpecies = Set(Season.allCases.flatMap(\.cast))
        for species in Species.allCases {
            let range = SpeciesTraits.standard(for: species).sizeRange
            if species.isRare {
                XCTAssertGreaterThanOrEqual(range.lowerBound, 34, "\(species)")
                XCTAssertLessThanOrEqual(range.upperBound, 46, "\(species)")
            } else if !castSpecies.contains(species) {
                XCTAssertGreaterThanOrEqual(range.lowerBound, 20, "\(species)")
                XCTAssertLessThanOrEqual(range.upperBound, 42, "\(species)")
            } else if species.isAirborne || species.locomotion == .crawl {
                XCTAssertGreaterThanOrEqual(range.lowerBound, 14, "\(species)")
                XCTAssertLessThanOrEqual(range.upperBound, 38, "\(species)")
            } else {
                XCTAssertGreaterThanOrEqual(range.lowerBound, 20, "\(species)")
                XCTAssertLessThanOrEqual(range.upperBound, 40, "\(species)")
            }
        }
        let small = [Species.ladybird, .bumblebee, .firefly, .spider].map { SpeciesTraits.standard(for: $0).sizeRange.upperBound }
        let large = [Species.snowman, .reindeer, .hedgehog, .balloon].map { SpeciesTraits.standard(for: $0).sizeRange.lowerBound }
        XCTAssertLessThan(small.max() ?? 99, large.min() ?? 0)
    }

    func testSeedChangeAtRuntimeReplacesCast() {
        let world = makeWorld(seed: 1)
        let fresh = makeWorld(seed: 2)
        hold(world, angle: 5, seconds: 10)
        world.config.seed = 2
        hold(world, angle: 5, seconds: 16)
        hold(fresh, angle: 5, seconds: 16)
        XCTAssertGreaterThanOrEqual(world.critters.count, 21)
        XCTAssertLessThanOrEqual(world.critters.count, 24)
        XCTAssertEqual(Set(world.critters.map(\.species)).count, Set(fresh.critters.map(\.species)).count)
    }

    func testScatterEventFiresOncePerScatter() {
        let world = makeWorld(seed: 3, straggler: false)
        var scatters: [Double] = []
        func collect() {
            for e in world.drainEvents() {
                if case .scatter(let intensity) = e { scatters.append(intensity) }
            }
        }
        let snap = snapTimeline(darkFor: 14)
        run(world, snap, to: 20) { _ in collect() }
        XCTAssertEqual(scatters.count, 1)
        XCTAssertGreaterThan(scatters.first ?? 0, 0.6)
        XCTAssertLessThanOrEqual(scatters.first ?? 2, 1)
        XCTAssertTrue(world.isQuiet)

        let slow = snapTimeline(darkFor: 14, over: 6)
        run(world, slow, to: 30) { _ in collect() }
        XCTAssertEqual(scatters.count, 2)
        XCTAssertGreaterThan(scatters.last ?? 0, 0)
        XCTAssertLessThan(scatters.last ?? 1, 0.35)
        XCTAssertTrue(world.isQuiet)

        hold(world, angle: 110, seconds: 5) { collect() }
        XCTAssertEqual(scatters.count, 2)
        XCTAssertTrue(world.drainEvents().isEmpty)
    }

    func testQuietAgainAfterFullCycleAndRepeatable() {
        let world = makeWorld(seed: 9, straggler: false)
        for _ in 0..<3 {
            XCTAssertTrue(world.isQuiet)
            hold(world, angle: 10, seconds: 9)
            XCTAssertFalse(world.isQuiet)
            XCTAssertGreaterThan(world.critters.count, 15)
            hold(world, angle: 112, seconds: 3.2)
            XCTAssertTrue(world.isQuiet)
            XCTAssertTrue(world.critters.isEmpty)
            XCTAssertEqual(world.light, 1)
            hold(world, angle: 112, seconds: 0.5)
            XCTAssertEqual(world.activity, 0)
        }
    }

    func testFailsafeClearsStuckCritters() {
        let world = makeWorld(seed: 6, straggler: false)
        world.tuning.fleeSpeedRange = 1...2
        world.tuning.fleeSpeedCap = 2
        hold(world, angle: 10, seconds: 12)
        XCTAssertGreaterThan(world.critters.count, 18)
        hold(world, angle: 110, seconds: 3)
        XCTAssertGreaterThan(world.critters.count, 6)
        var sawFade = false
        hold(world, angle: 110, seconds: 3) {
            if world.critters.contains(where: { $0.alpha < 1 }) { sawFade = true }
        }
        XCTAssertTrue(sawFade)
        XCTAssertTrue(world.critters.isEmpty)
        XCTAssertTrue(world.isQuiet)
    }

    func testGaitFollowsGroundDistanceForWalkers() {
        let world = makeWorld(seed: 8, season: .christmas)
        let stride = world.tuning.strideLength
        hold(world, angle: 10, seconds: 6)
        var previous: [Int: Critter] = [:]
        var checked = 0
        var restingAntennaMoved = false
        hold(world, angle: 10, seconds: 6) {
            for c in world.critters {
                if let p = previous[c.id] {
                    let ground = c.species.locomotion == .walk || c.species.locomotion == .crawl
                    if ground && c.mode == .wandering && p.mode == .wandering && c.speed > 5 && c.position.y > c.size && c.position.x > c.size && Double(c.position.x) < 1512 - c.size && Double(c.position.y) < 982 - c.size {
                        let moved = hypot(Double(c.position.x - p.position.x), Double(c.position.y - p.position.y))
                        XCTAssertEqual(c.gaitPhase - p.gaitPhase, moved / (c.size * stride), accuracy: 1e-6)
                        checked += 1
                    }
                    if c.mode == .resting && p.mode == .resting && c.speed == 0 {
                        XCTAssertGreaterThan(c.antennaPhase, p.antennaPhase)
                        restingAntennaMoved = true
                    }
                }
                previous[c.id] = c
            }
        }
        XCTAssertGreaterThan(checked, 300)
        XCTAssertTrue(restingAntennaMoved)
    }

    func testSpeciesPaceDiffers() {
        func meanPace(_ season: Season) -> [Species: Double] {
            let world = makeWorld(population: 40, seed: 13, season: season)
            hold(world, angle: 5, seconds: 10)
            var speed: [Species: Double] = [:], n: [Species: Double] = [:]
            hold(world, angle: 5, seconds: 12) {
                for c in world.critters where c.mode == .wandering {
                    speed[c.species, default: 0] += c.speed
                    n[c.species, default: 0] += 1
                }
            }
            var out: [Species: Double] = [:]
            for (s, v) in speed { out[s] = v / max(1, n[s] ?? 1) }
            return out
        }
        let spring = meanPace(.spring)
        XCTAssertLessThan(spring[.snail] ?? 99, (spring[.ladybird] ?? 0) * 0.5)
        let winter = meanPace(.winter)
        XCTAssertLessThan(winter[.snowman] ?? 99, winter[.penguin] ?? 0)
        let summer = meanPace(.summer)
        XCTAssertGreaterThan(summer[.dragonfly] ?? 0, summer[.butterfly] ?? 99)
    }

    func testStepCostIsTrivial() {
        let world = makeWorld(population: 120, seed: 2)
        hold(world, angle: 5, seconds: 12)
        let start = Date()
        for _ in 0..<600 { world.step(dt: dt, lidAngle: 5) }
        let perStep = Date().timeIntervalSince(start) / 600
        XCTAssertLessThan(perStep, 0.004)
    }

    func testSettleInDarkThenOpenScattersReadably() {
        let world = World(size: CGSize(width: 1512, height: 982), config: WorldConfig(seed: 9))
        world.tuning.forceStraggler = false
        world.tuning.forceRare = false
        world.tuning.catchEnabled = false
        world.settleInDark()
        let out = world.critters.count
        XCTAssertEqual(world.config.population, 24)
        XCTAssertGreaterThanOrEqual(out, 18)
        XCTAssertTrue(world.drainEvents().isEmpty)
        var t = 0.0
        var atHalf = 0
        var gone: Double?
        while t < 6 {
            world.step(dt: 1.0 / 60, lidAngle: 115)
            t += 1.0 / 60
            if abs(t - 0.5) < 1.0 / 120 { atHalf = world.critters.count }
            if gone == nil, world.critters.isEmpty { gone = t }
        }
        XCTAssertGreaterThanOrEqual(Double(atHalf), Double(out) * 0.75)
        XCTAssertNotNil(gone)
        XCTAssertGreaterThanOrEqual(gone ?? 0, 1.5)
        XCTAssertLessThanOrEqual(gone ?? 99, 3.2)
        XCTAssertTrue(world.isQuiet)
    }
}
