import XCTest
import CoreGraphics
@testable import ScuttleCore

final class GrowthTests: XCTestCase {
    let screen = CGSize(width: 1512, height: 982)
    let dt = 1.0 / 60.0

    func makeWorld(seed: UInt64 = 1, population: Int = 24) -> World {
        let world = World(size: screen, config: WorldConfig(population: population, seed: seed))
        world.tuning.forceStraggler = false
        world.tuning.forceRare = false
        return world
    }

    func hold(_ world: World, angle: Double, seconds: Double, each: ((Double) -> Void)? = nil) {
        var t = 0.0
        while t < seconds - 1e-9 {
            t += dt
            world.step(dt: dt, lidAngle: angle)
            each?(t)
        }
    }

    func counts(_ world: World, at marks: [Double], until end: Double) -> [Double: Int] {
        var out: [Double: Int] = [:]
        hold(world, angle: 5, seconds: end) { t in
            for m in marks where abs(t - m) < self.dt / 2 { out[m] = world.critters.count }
        }
        return out
    }

    func testCountGrowsGraduallyToFullOverAMinute() {
        for seed in [1, 2, 3, 7, 42] as [UInt64] {
            let world = makeWorld(seed: seed)
            let c = counts(world, at: [2, 5, 10, 20, 30, 45, 59, 61, 64], until: 64)
            XCTAssertGreaterThanOrEqual(c[2] ?? 0, 1, "seed \(seed)")
            XCTAssertLessThanOrEqual(c[2] ?? 99, 3, "seed \(seed)")
            XCTAssertLessThanOrEqual(c[5] ?? 99, 4, "seed \(seed)")
            XCTAssertGreaterThanOrEqual(c[10] ?? 0, 3, "seed \(seed)")
            XCTAssertLessThanOrEqual(c[10] ?? 99, 6, "seed \(seed)")
            XCTAssertGreaterThanOrEqual(c[30] ?? 0, 8, "seed \(seed)")
            XCTAssertLessThanOrEqual(c[30] ?? 99, 14, "seed \(seed)")
            XCTAssertLessThan(c[30] ?? 99, c[45] ?? 0, "seed \(seed)")
            XCTAssertLessThan(c[45] ?? 99, 24, "seed \(seed)")
            XCTAssertGreaterThanOrEqual(c[59] ?? 0, 20, "seed \(seed)")
            XCTAssertGreaterThanOrEqual(c[61] ?? 0, 23, "seed \(seed)")
            XCTAssertEqual(c[64], 24, "seed \(seed)")
            let marks = [2.0, 5, 10, 20, 30, 45, 59, 61, 64]
            for (a, b) in zip(marks, marks.dropFirst()) {
                XCTAssertLessThanOrEqual(c[a] ?? 99, c[b] ?? 0, "seed \(seed) \(a)->\(b)")
            }
            XCTAssertEqual(world.darkSeconds, 64, accuracy: 0.5)
        }
    }

    func testCapScalesWithPopulation() {
        let world = makeWorld(seed: 5, population: 200)
        let c = counts(world, at: [10, 30, 66], until: 66)
        XCTAssertLessThanOrEqual(c[10] ?? 999, 50)
        XCTAssertGreaterThan(c[30] ?? 0, c[10] ?? 999)
        XCTAssertLessThan(c[30] ?? 999, 120)
        XCTAssertEqual(c[66], 200)
    }

    func testZeroGrowthSecondsDisablesTheCap() {
        let world = makeWorld(seed: 2)
        world.tuning.growthSeconds = 0
        let c = counts(world, at: [10], until: 10)
        XCTAssertGreaterThanOrEqual(c[10] ?? 0, 22)
    }

    func testGrowthStartAndCurveAreTunable() {
        let world = makeWorld(seed: 3)
        world.tuning.growthStart = 0
        let none = counts(world, at: [1.5], until: 1.5)
        XCTAssertEqual(none[1.5], 0)
        let fast = makeWorld(seed: 3)
        fast.tuning.growthSeconds = 10
        let c = counts(fast, at: [5, 14], until: 14)
        XCTAssertGreaterThan(c[5] ?? 0, 6)
        XCTAssertEqual(c[14], 24)
    }

    func testDarknessResetsAfterLightReturnsButSurvivesAFlicker() {
        let world = makeWorld(seed: 4)
        hold(world, angle: 5, seconds: 40)
        let before = world.critters.count
        XCTAssertEqual(world.darkSeconds, 40, accuracy: 0.1)
        hold(world, angle: 112, seconds: 0.8)
        XCTAssertEqual(world.darkSeconds, 40, accuracy: 0.1)
        hold(world, angle: 5, seconds: 8)
        XCTAssertGreaterThan(world.darkSeconds, 47)
        XCTAssertGreaterThanOrEqual(world.critters.count, before - 3)

        hold(world, angle: 112, seconds: 5)
        XCTAssertTrue(world.isQuiet)
        XCTAssertEqual(world.darkSeconds, 0)
        let c = counts(world, at: [2, 10], until: 10)
        XCTAssertLessThanOrEqual(c[2] ?? 99, 3)
        XCTAssertLessThanOrEqual(c[10] ?? 99, 6)
    }

    func testDarkClockIgnoresFullLightAndRunsInDimLight() {
        let world = makeWorld(seed: 6)
        hold(world, angle: 110, seconds: 5)
        XCTAssertEqual(world.darkSeconds, 0)
        hold(world, angle: 45, seconds: 5)
        XCTAssertEqual(world.darkSeconds, 5, accuracy: 0.2)
    }

    func testNerveStillAppliesOnTopOfTheCap() {
        let world = makeWorld(seed: 8)
        hold(world, angle: 60, seconds: 70)
        let dim = world.critters.count
        XCTAssertGreaterThan(dim, 0)
        XCTAssertLessThan(dim, 12)
        hold(world, angle: 5, seconds: 10)
        XCTAssertEqual(world.critters.count, 24)
    }

    func testAmbushSettlesWithEveryoneOut() {
        for seed in [1, 2, 3, 9, 77] as [UInt64] {
            let world = makeWorld(seed: seed)
            world.settleInDark()
            XCTAssertEqual(world.critters.count, 24, "seed \(seed)")
            XCTAssertTrue(world.drainEvents().isEmpty)
        }
        let big = makeWorld(seed: 4, population: 60)
        big.settleInDark()
        XCTAssertEqual(big.critters.count, 60)
    }
}
