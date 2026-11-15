import XCTest
import CoreGraphics
@testable import ScuttleCore

final class StragglerTests: XCTestCase {
    let screen = CGSize(width: 1512, height: 982)
    let dt = 1.0 / 60.0

    func makeWorld(seed: UInt64, population: Int = 24, straggler: Bool?) -> World {
        let world = World(size: screen, config: WorldConfig(population: population, seed: seed))
        world.tuning.forceStraggler = straggler
        world.tuning.growthSeconds = 0
        world.tuning.catchEnabled = false
        world.tuning.forceRare = false
        return world
    }

    func hold(_ world: World, angle: Double, seconds: Double, step: Double? = nil, each: (() -> Void)? = nil) {
        let h = step ?? dt
        var t = 0.0
        while t < seconds - 1e-9 {
            t += h
            world.step(dt: h, lidAngle: angle)
            each?()
        }
    }

    func snapOpen(_ world: World, seconds: Double, each: ((Double) -> Void)? = nil) {
        let ramp = LidTimeline(keyframes: [.init(t: 0, angle: 10), .init(t: 0.2, angle: 110)])
        var t = 0.0
        while t < seconds - 1e-9 {
            t += dt
            world.step(dt: dt, lidAngle: ramp.angle(at: t))
            each?(t)
        }
    }

    func edgeDistance(_ c: Critter) -> Double {
        let x = Double(c.position.x), y = Double(c.position.y)
        return min(min(x, Double(screen.width) - x), min(y, Double(screen.height) - y))
    }

    struct Run {
        var id: Int?
        var othersGone = 0.0
        var lastSeen = 0.0
        var maxConfusion = 0.0
        var exitConfusion = -1.0
        var strayEvents = 0
        var quietWhileVisible = false
        var outOfBox = false
        var wentTop = false
        var aloneActivity = 0.0
        var concurrent = 0
    }

    func watch(_ world: World, seconds: Double) -> Run {
        var r = Run()
        snapOpen(world, seconds: seconds) { t in
            for e in world.drainEvents() where e == .straggler { r.strayEvents += 1 }
            let confused = world.critters.filter { $0.confusion > 0 }
            r.concurrent = max(r.concurrent, confused.count)
            if r.id == nil { r.id = world.stragglerID }
            if world.critters.contains(where: { $0.id != r.id }) { r.othersGone = t }
            guard let id = r.id, let c = world.critters.first(where: { $0.id == id }) else { return }
            r.lastSeen = t
            r.maxConfusion = max(r.maxConfusion, c.confusion)
            r.exitConfusion = c.confusion
            if world.isQuiet { r.quietWhileVisible = true }
            if c.confusion > 0 {
                if self.edgeDistance(c) < 12 { r.outOfBox = true }
                if Double(c.position.y) > Double(self.screen.height) - 40 { r.wentTop = true }
            }
            if t > r.othersGone + 0.5 && world.critters.count == 1 { r.aloneActivity = max(r.aloneActivity, world.activity) }
        }
        return r
    }

    func testForcedStragglerLingersAloneThenLeaves() {
        var alone: [Double] = []
        for seed in [1, 2, 3, 5, 7, 9, 11, 13, 42, 1234] as [UInt64] {
            let world = makeWorld(seed: seed, straggler: true)
            hold(world, angle: 10, seconds: 16)
            XCTAssertGreaterThanOrEqual(world.critters.count, 20)
            let r = watch(world, seconds: 16)
            XCTAssertNotNil(r.id, "seed \(seed)")
            XCTAssertEqual(r.strayEvents, 1, "seed \(seed)")
            XCTAssertEqual(r.concurrent, 1, "seed \(seed)")
            XCTAssertGreaterThan(r.othersGone, 1.5, "seed \(seed)")
            XCTAssertLessThan(r.othersGone, 3.2, "seed \(seed)")
            let lonely = r.lastSeen - r.othersGone
            alone.append(lonely)
            XCTAssertGreaterThanOrEqual(lonely, 3, "seed \(seed)")
            XCTAssertLessThanOrEqual(lonely, 7, "seed \(seed)")
            XCTAssertGreaterThan(r.maxConfusion, 0.9, "seed \(seed)")
            XCTAssertEqual(r.exitConfusion, 0, "seed \(seed)")
            XCTAssertFalse(r.quietWhileVisible, "seed \(seed)")
            XCTAssertFalse(r.outOfBox, "seed \(seed)")
            XCTAssertFalse(r.wentTop, "seed \(seed)")
            XCTAssertGreaterThan(r.aloneActivity, 0.01, "seed \(seed)")
            XCTAssertTrue(world.critters.isEmpty, "seed \(seed)")
            XCTAssertTrue(world.isQuiet, "seed \(seed)")
            XCTAssertNil(world.stragglerID)
        }
        XCTAssertGreaterThan((alone.max() ?? 0) - (alone.min() ?? 0), 1)
    }

    func testForbiddenStragglerKeepsTodaysTimings() {
        for seed in [1, 2, 3, 5, 7, 9, 11, 13, 42, 1234] as [UInt64] {
            let world = makeWorld(seed: seed, straggler: false)
            hold(world, angle: 10, seconds: 16)
            let r = watch(world, seconds: 8)
            XCTAssertNil(r.id, "seed \(seed)")
            XCTAssertEqual(r.strayEvents, 0, "seed \(seed)")
            XCTAssertEqual(r.concurrent, 0, "seed \(seed)")
            XCTAssertGreaterThan(r.othersGone, 1.5, "seed \(seed)")
            XCTAssertLessThanOrEqual(r.othersGone, 3.0, "seed \(seed)")
            XCTAssertTrue(world.isQuiet, "seed \(seed)")
        }
    }

    func testFrequencyNearChanceAndNeverTwoAtOnce() {
        var scatters = 0
        var stragglers = 0
        for seed in 1...36 as ClosedRange<UInt64> {
            let world = makeWorld(seed: seed, population: 24, straggler: nil)
            for _ in 0..<3 {
                hold(world, angle: 10, seconds: 9, step: 1.0 / 30)
                hold(world, angle: 112, seconds: 10, step: 1.0 / 30) {
                    for e in world.drainEvents() {
                        if case .scatter = e { scatters += 1 }
                        if e == .straggler { stragglers += 1 }
                    }
                    XCTAssertLessThanOrEqual(world.critters.filter { $0.confusion > 0 }.count, 1)
                }
                XCTAssertTrue(world.isQuiet, "seed \(seed)")
            }
        }
        XCTAssertEqual(scatters, 108)
        let rate = Double(stragglers) / Double(scatters)
        XCTAssertGreaterThan(rate, 0.15, "\(stragglers) of \(scatters)")
        XCTAssertLessThan(rate, 0.35, "\(stragglers) of \(scatters)")
    }

    func testChanceIsTunable() {
        var count = 0
        for seed in 1...12 as ClosedRange<UInt64> {
            let world = makeWorld(seed: seed, population: 16, straggler: nil)
            world.tuning.confusedStragglerChance = 0
            hold(world, angle: 10, seconds: 9, step: 1.0 / 30)
            hold(world, angle: 112, seconds: 9, step: 1.0 / 30) {
                for e in world.drainEvents() where e == .straggler { count += 1 }
            }
        }
        XCTAssertEqual(count, 0)
    }

    func testLidDroppingMidRoutineCalmsItDown() {
        for seed in [1, 3, 42] as [UInt64] {
            let world = makeWorld(seed: seed, straggler: true)
            hold(world, angle: 10, seconds: 16)
            var id: Int?
            snapOpen(world, seconds: 3.4) { _ in
                if id == nil { id = world.stragglerID }
            }
            guard let sid = id, let c = world.critters.first(where: { $0.id == sid }) else {
                XCTFail("no straggler for seed \(seed)")
                continue
            }
            XCTAssertGreaterThan(c.confusion, 0.5)
            hold(world, angle: 8, seconds: 3)
            let calm = world.critters.first { $0.id == sid }
            XCTAssertNotNil(calm, "seed \(seed)")
            XCTAssertEqual(calm?.confusion, 0, "seed \(seed)")
            XCTAssertNotEqual(calm?.mode, .fleeing)
            XCTAssertNotEqual(calm?.mode, .startled)
            XCTAssertNil(world.stragglerID)
            XCTAssertTrue(world.critters.allSatisfy { $0.confusion == 0 })
            world.tuning.forceStraggler = false
            hold(world, angle: 112, seconds: 6)
            XCTAssertTrue(world.isQuiet, "seed \(seed)")
        }
    }

    func testSlowOpenDoesNotProduceStraggler() {
        for seed in [1, 2, 3, 4, 5] as [UInt64] {
            let world = makeWorld(seed: seed, straggler: true)
            hold(world, angle: 10, seconds: 16)
            let slow = LidTimeline(keyframes: [.init(t: 0, angle: 10), .init(t: 6, angle: 110)])
            var t = 0.0
            var events = 0
            while t < 16 {
                t += dt
                world.step(dt: dt, lidAngle: slow.angle(at: t))
                for e in world.drainEvents() where e == .straggler { events += 1 }
                XCTAssertTrue(world.critters.allSatisfy { $0.confusion == 0 })
            }
            XCTAssertEqual(events, 0, "seed \(seed)")
            XCTAssertTrue(world.isQuiet)
        }
    }

    func testWakeFromSleepPathCanStraggle() {
        let world = makeWorld(seed: 9, straggler: true)
        world.settleInDark()
        XCTAssertGreaterThanOrEqual(world.critters.count, 18)
        var sid: Int?
        var othersGone = 0.0
        var last = 0.0
        var t = 0.0
        while t < 14 {
            t += dt
            world.step(dt: dt, lidAngle: 115)
            if sid == nil { sid = world.stragglerID }
            if world.critters.contains(where: { $0.id != sid }) { othersGone = t }
            if !world.critters.isEmpty { last = t }
        }
        XCTAssertNotNil(sid)
        XCTAssertGreaterThanOrEqual(last - othersGone, 3)
        XCTAssertLessThanOrEqual(last - othersGone, 7)
        XCTAssertTrue(world.isQuiet)
    }

    func testStragglerIsDeterministicPerSeed() {
        let a = makeWorld(seed: 77, straggler: true), b = makeWorld(seed: 77, straggler: true)
        hold(a, angle: 10, seconds: 12)
        hold(b, angle: 10, seconds: 12)
        var sawConfused = false
        var t = 0.0
        while t < 12 {
            t += dt
            a.step(dt: dt, lidAngle: 112)
            b.step(dt: dt, lidAngle: 112)
            XCTAssertEqual(a.critters.map(\.id), b.critters.map(\.id))
            XCTAssertEqual(a.critters.map(\.confusion), b.critters.map(\.confusion))
            XCTAssertEqual(a.critters.map { Double($0.position.x) }, b.critters.map { Double($0.position.x) })
            XCTAssertEqual(a.critters.map(\.heading), b.critters.map(\.heading))
            XCTAssertEqual(a.drainEvents(), b.drainEvents())
            if a.critters.contains(where: { $0.confusion > 0 }) { sawConfused = true }
        }
        XCTAssertTrue(sawConfused)
        XCTAssertTrue(a.isQuiet && b.isQuiet)
    }

    func testFailsafeStillClearsAStuckStraggler() {
        let world = makeWorld(seed: 6, straggler: true)
        hold(world, angle: 10, seconds: 12)
        world.tuning.fleeSpeedRange = 1...2
        world.tuning.fleeSpeedCap = 2
        var t = 0.0
        var lastSeen = 0.0
        while t < 30 {
            t += dt
            world.step(dt: dt, lidAngle: 110)
            if !world.critters.isEmpty { lastSeen = t }
        }
        XCTAssertTrue(world.isQuiet)
        XCTAssertLessThan(lastSeen, world.tuning.confusedMaxSeconds + world.tuning.failsafeSeconds + 2)
    }
}
