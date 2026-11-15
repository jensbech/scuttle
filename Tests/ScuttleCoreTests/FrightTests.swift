import XCTest
@testable import ScuttleCore

final class FrightTests: XCTestCase {
    private let screen = CGSize(width: 1512 / Tuning.figureScale, height: 982 / Tuning.figureScale)

    private func makeWorld(seed: UInt64, population: Int = 15) -> World {
        let world = World(size: screen, config: WorldConfig(population: population, season: .autumn, seed: seed))
        world.tuning.growthSeconds = 0
        world.tuning.forceRare = false
        world.tuning.forceStraggler = false
        return world
    }

    private func run(_ world: World, angle: Double, seconds: Double, each: ((Double) -> Void)? = nil) {
        let dt = 1.0 / 60
        var t = 0.0
        while t < seconds {
            world.step(dt: dt, lidAngle: angle)
            t += dt
            each?(t)
        }
    }

    private struct Trace {
        var out = 0
        var frightAt: [Int: Double] = [:]
        var fleeAt: [Int: Double] = [:]
        var frozenAt06 = 0
        var allGone: Double?
    }

    private func snap(_ world: World) -> Trace {
        var trace = Trace()
        trace.out = world.critters.count
        run(world, angle: 115, seconds: 8) { t in
            for c in world.critters {
                if c.fright > 0, trace.frightAt[c.id] == nil { trace.frightAt[c.id] = t }
                if c.mode == .fleeing, trace.fleeAt[c.id] == nil { trace.fleeAt[c.id] = t }
            }
            if abs(t - 0.6) < 0.009 {
                trace.frozenAt06 = world.critters.filter { $0.mode == .startled && $0.fright > 0 && $0.speed < 1 }.count
            }
            if trace.allGone == nil && world.critters.isEmpty { trace.allGone = t }
        }
        return trace
    }

    func testEveryoneFreezesAtTheSameInstant() {
        for seed in [1, 3, 9, 42] as [UInt64] {
            let world = makeWorld(seed: seed)
            run(world, angle: 5, seconds: 14)
            let trace = snap(world)
            XCTAssertGreaterThan(trace.out, 9, "seed \(seed)")
            let starts = trace.frightAt.values
            XCTAssertGreaterThanOrEqual(trace.frightAt.count, trace.out - 1, "seed \(seed)")
            XCTAssertLessThanOrEqual((starts.max() ?? 0) - (starts.min() ?? 0), world.tuning.catchJitter + 0.05, "seed \(seed)")
            XCTAssertGreaterThanOrEqual(trace.frozenAt06, trace.out - 1, "seed \(seed)")
        }
    }

    func testHoldThenCascadeThenGone() {
        var gone: [Double] = []
        for seed in [1, 2, 3, 5, 9, 42] as [UInt64] {
            let world = makeWorld(seed: seed)
            run(world, angle: 5, seconds: 14)
            let trace = snap(world)
            let flee = trace.fleeAt.values.sorted()
            let t = world.tuning
            XCTAssertGreaterThanOrEqual(flee.first ?? 0, t.catchReact + t.catchHold.lowerBound + t.catchWindup.lowerBound - 0.05, "seed \(seed)")
            XCTAssertGreaterThan((flee.last ?? 0) - (flee.first ?? 0), 0.2, "seed \(seed) should cascade, not leave as one")
            XCTAssertLessThanOrEqual(trace.allGone ?? 99, 4.6, "seed \(seed)")
            gone.append(trace.allGone ?? 99)
        }
        gone.sort()
        XCTAssertLessThanOrEqual(gone[gone.count / 2], 3.5)
    }

    func testCascadeLeavesNearestTheEdgeFirst() {
        var agree = 0, total = 0
        for seed in [1, 2, 3, 4, 5, 6] as [UInt64] {
            let world = makeWorld(seed: seed)
            run(world, angle: 5, seconds: 14)
            run(world, angle: 115, seconds: 0.2)
            let beats = world.bugs.compactMap { b -> (depth: Double, bolt: Double)? in
                guard let beat = b.beat, beat.quirk == .none else { return nil }
                return (world.depth(b.x, b.y, from: beat.exit) / max(1, b.size), beat.bolt)
            }
            guard beats.count >= 4 else { continue }
            let near = beats.min { $0.depth < $1.depth }!
            let far = beats.max { $0.depth < $1.depth }!
            total += 1
            if near.bolt < far.bolt { agree += 1 }
        }
        XCTAssertGreaterThan(total, 3)
        XCTAssertEqual(agree, total)
    }

    func testGlancePairLooksAtEachOther() {
        var checked = 0
        for seed in [1, 2, 3, 5, 9] as [UInt64] {
            let world = makeWorld(seed: seed)
            world.tuning.forceCatchQuirk = .glance
            run(world, angle: 5, seconds: 14)
            run(world, angle: 115, seconds: 0.2)
            let pair = world.bugs.filter { $0.beat?.quirk == .glance }
            guard pair.count == 2 else { continue }
            let lookAt = pair.map { $0.beat!.lookAt }.max()!
            run(world, angle: 115, seconds: lookAt - world.time + 0.25)
            let a = world.critters.first { $0.id == pair[0].id }!
            let b = world.critters.first { $0.id == pair[1].id }!
            XCTAssertEqual(a.facing > 0, b.position.x > a.position.x, "seed \(seed)")
            XCTAssertEqual(b.facing > 0, a.position.x > b.position.x, "seed \(seed)")
            checked += 1
        }
        XCTAssertGreaterThan(checked, 2)
    }

    func testQuirksAreRareAndSpread() {
        for seed in [1, 3, 9] as [UInt64] {
            let world = makeWorld(seed: seed)
            run(world, angle: 5, seconds: 14)
            run(world, angle: 115, seconds: 0.3)
            let caught = world.bugs.filter { $0.beat != nil }
            let quirky = caught.filter { $0.beat!.quirk != .none }
            XCTAssertLessThanOrEqual(quirky.count, 6, "seed \(seed)")
            XCTAssertGreaterThan(caught.count - quirky.count, caught.count / 2, "seed \(seed)")
        }
    }

    func testGentleOpeningSneaksInsteadOfCatching() {
        let world = makeWorld(seed: 7)
        run(world, angle: 5, seconds: 14)
        XCTAssertGreaterThan(world.critters.count, 9)
        var caught = false
        var sneakers = 0
        let dt = 1.0 / 60
        var t = 0.0
        while t < 40 {
            let angle = min(115, 5 + 110 * t / 30)
            world.step(dt: dt, lidAngle: angle)
            t += dt
            if world.critters.contains(where: { $0.fright > 0 }) { caught = true }
            sneakers = max(sneakers, world.sneakerCount)
        }
        XCTAssertFalse(caught)
        XCTAssertGreaterThan(sneakers, 2)
    }

    func testWakeCatchHoldsLongerAndStartsAtOnce() {
        let world = makeWorld(seed: 11)
        world.settleInDark(seconds: 20)
        let out = world.critters.count
        XCTAssertGreaterThan(out, 9)
        world.catchNow(since: 0.05)
        XCTAssertTrue(world.catchActive)
        let startled = world.bugs.filter { $0.beat != nil }.count
        XCTAssertGreaterThanOrEqual(startled, out - 1)
        var firstFlee: Double?
        var gone: Double?
        run(world, angle: 115, seconds: 8) { t in
            if firstFlee == nil, world.critters.contains(where: { $0.mode == .fleeing }) { firstFlee = t }
            if gone == nil, world.critters.isEmpty { gone = t }
        }
        let tr = world.tuning
        XCTAssertGreaterThanOrEqual(firstFlee ?? 0, tr.catchReact + tr.catchHold.lowerBound + tr.catchWakeHold - 0.1)
        XCTAssertLessThanOrEqual(gone ?? 99, 4.6)
    }

    func testStagingSettlesAFullPopulationOnScreen() {
        for (seed, population) in [(21, 15), (22, 15), (23, 30)] as [(UInt64, Int)] {
            let world = makeWorld(seed: seed, population: population)
            world.settleInDark(seconds: 20)
            let onScreen = world.critters.filter { c in
                c.mode != .hidden && c.alpha > 0.5 && c.position.x > 0 && c.position.x < screen.width && c.position.y > 0 && c.position.y < screen.height
            }
            XCTAssertGreaterThanOrEqual(onScreen.count, population * 8 / 10, "seed \(seed)")
            XCTAssertFalse(world.critters.contains { $0.mode == .startled || $0.mode == .fleeing }, "seed \(seed)")
        }
    }

    func testWakeCatchStillRunsWhenTheLidReadsStale() {
        let world = makeWorld(seed: 12)
        world.settleInDark(seconds: 20)
        world.catchNow()
        var gone: Double?
        run(world, angle: 3, seconds: 8) { t in
            if gone == nil, world.critters.allSatisfy({ $0.fright == 0 && $0.mode != .startled }) { gone = t }
        }
        XCTAssertNotNil(gone)
    }

    func testFrightIsZeroOutsideTheStartle() {
        let world = makeWorld(seed: 5)
        run(world, angle: 5, seconds: 10)
        XCTAssertFalse(world.critters.contains { $0.fright > 0 || $0.dash > 0 || $0.windup > 0 })
    }
}
