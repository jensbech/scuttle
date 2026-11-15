import XCTest
import CoreGraphics
@testable import ScuttleCore

final class RareVisitorTests: XCTestCase {
    let screen = CGSize(width: 1512, height: 982)
    let dt = 1.0 / 60.0

    func makeWorld(season: Season = .summer, seed: UInt64 = 1, population: Int = 24, rare: Bool? = nil, growth: Bool = false) -> World {
        let world = World(size: screen, config: WorldConfig(population: population, season: season, seed: seed))
        world.tuning.forceStraggler = false
        world.tuning.forceRare = rare
        if !growth { world.tuning.growthSeconds = 0 }
        world.tuning.catchEnabled = false
        return world
    }

    func hold(_ world: World, angle: Double, seconds: Double, step: Double? = nil, each: ((Double) -> Void)? = nil) {
        let h = step ?? dt
        var t = 0.0
        while t < seconds - 1e-9 {
            t += h
            world.step(dt: h, lidAngle: angle)
            each?(t)
        }
    }

    func visitors(_ events: [WorldEvent]) -> [Species] {
        events.compactMap { e in
            if case .rareVisitor(let s) = e { return s }
            return nil
        }
    }

    func testNeverWhenForcedOff() {
        for seed in 1...6 as ClosedRange<UInt64> {
            let world = makeWorld(seed: seed, rare: false)
            world.tuning.rareChance = 1
            var seen: [Species] = []
            hold(world, angle: 5, seconds: 40) { _ in
                seen += self.visitors(world.drainEvents())
                XCTAssertFalse(world.critters.contains { $0.species.isRare })
            }
            XCTAssertTrue(seen.isEmpty)
            XCTAssertFalse(world.bugs.contains { $0.rare })
        }
    }

    func testAlwaysWhenForcedOnOncePerEpisodeAndScattersWithTheRest() {
        for seed in [1, 2, 3, 7] as [UInt64] {
            let world = makeWorld(seed: seed, rare: true)
            var seen: [Species] = []
            var firstAt: Double?
            var firstVisible: Double?
            hold(world, angle: 5, seconds: 32) { t in
                let found = self.visitors(world.drainEvents())
                if !found.isEmpty && firstAt == nil { firstAt = t }
                seen += found
                if firstVisible == nil && world.critters.contains(where: { $0.species.isRare }) { firstVisible = t }
            }
            XCTAssertEqual(seen.count, 1, "seed \(seed)")
            XCTAssertTrue(seen.first == .turtle || seen.first == .ufo, "seed \(seed)")
            XCTAssertGreaterThanOrEqual(firstAt ?? 0, world.tuning.rareMinDark, "seed \(seed)")
            XCTAssertGreaterThanOrEqual(firstVisible ?? 0, world.tuning.rareMinDark, "seed \(seed)")
            XCTAssertEqual(firstAt, firstVisible)
            XCTAssertEqual(world.critters.count, 25, "seed \(seed)")
            let rare = world.critters.first { $0.species.isRare }
            XCTAssertNotNil(rare)
            XCTAssertFalse(world.critters.contains { $0.id == rare?.id && !$0.species.isRare })
            XCTAssertEqual(Set(world.critters.map(\.id)).count, 25)

            hold(world, angle: 112, seconds: 0.4)
            hold(world, angle: 5, seconds: 10) { _ in seen += self.visitors(world.drainEvents()) }
            XCTAssertEqual(seen.count, 1, "seed \(seed)")

            hold(world, angle: 112, seconds: 5) { _ in seen += self.visitors(world.drainEvents()) }
            XCTAssertTrue(world.isQuiet, "seed \(seed)")
            XCTAssertFalse(world.bugs.contains { $0.rare })
            XCTAssertEqual(world.bugs.count, 24)

            hold(world, angle: 5, seconds: 30) { _ in seen += self.visitors(world.drainEvents()) }
            XCTAssertEqual(seen.count, 2, "seed \(seed)")
            hold(world, angle: 112, seconds: 5)
            XCTAssertTrue(world.isQuiet)
        }
    }

    func testNotBeforeMinimumDark() {
        let world = makeWorld(seed: 5, rare: true)
        world.tuning.rareMinDark = 30
        var at: Double?
        hold(world, angle: 5, seconds: 40) { t in
            if at == nil && !self.visitors(world.drainEvents()).isEmpty { at = t }
        }
        XCTAssertNotNil(at)
        XCTAssertGreaterThanOrEqual(at ?? 0, 30)
        XCTAssertLessThan(at ?? 99, 38)
    }

    func testVisitorIsTheSeasonsOwnOrAUfo() {
        for season in Season.allCases {
            var kinds = Set<Species>()
            for seed in 1...40 as ClosedRange<UInt64> {
                let world = makeWorld(season: season, seed: seed, population: 1, rare: true)
                world.tuning.rareMinDark = 0
                hold(world, angle: 5, seconds: 7, step: 1.0 / 30)
                kinds.formUnion(world.bugs.filter(\.rare).map(\.species))
            }
            XCTAssertEqual(kinds, [season.rareVisitor, .ufo], "\(season)")
        }
    }

    func testUfoShareRoughlyRight() {
        var ufo = 0
        var total = 0
        for seed in 1...500 as ClosedRange<UInt64> {
            let world = makeWorld(seed: seed, population: 1, rare: true)
            world.tuning.rareMinDark = 0
            hold(world, angle: 5, seconds: 7, step: 1.0 / 30)
            guard let s = world.bugs.first(where: \.rare)?.species else { continue }
            total += 1
            if s == .ufo { ufo += 1 }
        }
        XCTAssertEqual(total, 500)
        let share = Double(ufo) / Double(total)
        XCTAssertGreaterThan(share, 0.07, "\(ufo) of \(total)")
        XCTAssertLessThan(share, 0.17, "\(ufo) of \(total)")
    }

    func testChanceRollIsRoughlyRight() {
        func rate(_ chance: Double?) -> Double {
            var hits = 0
            for seed in 1...400 as ClosedRange<UInt64> {
                let world = makeWorld(seed: seed, population: 1, rare: nil)
                if let c = chance { world.tuning.rareChance = c }
                hold(world, angle: 5, seconds: 7, step: 1.0 / 30)
                if world.bugs.contains(where: \.rare) { hits += 1 }
            }
            return Double(hits) / 400
        }
        let standard = rate(nil)
        XCTAssertGreaterThan(standard, 0.02)
        XCTAssertLessThan(standard, 0.09)
        let half = rate(0.5)
        XCTAssertGreaterThan(half, 0.4)
        XCTAssertLessThan(half, 0.6)
        XCTAssertEqual(rate(0), 0)
    }

    func testSummonWhileDarkArrivesQuickly() {
        let world = makeWorld(season: .autumn, seed: 4, rare: false)
        hold(world, angle: 5, seconds: 3)
        _ = world.drainEvents()
        world.summonRare(.blackCat)
        var seen: [Species] = []
        var at: Double?
        hold(world, angle: 5, seconds: 4) { t in
            seen += self.visitors(world.drainEvents())
            if at == nil && world.critters.contains(where: { $0.species == .blackCat }) { at = t }
        }
        XCTAssertEqual(seen, [.blackCat])
        XCTAssertNotNil(at)
        XCTAssertLessThanOrEqual(at ?? 99, 2.2)

        world.summonRare(.ufo)
        hold(world, angle: 5, seconds: 5) { _ in seen += self.visitors(world.drainEvents()) }
        XCTAssertEqual(seen, [.blackCat])
        XCTAssertEqual(world.bugs.filter(\.rare).count, 1)
        hold(world, angle: 112, seconds: 5)
        XCTAssertTrue(world.isQuiet)
        hold(world, angle: 5, seconds: 30) { _ in seen += self.visitors(world.drainEvents()) }
        XCTAssertEqual(seen, [.blackCat, .ufo])
    }

    func testSummonDefaultsToTheSeasonsVisitor() {
        let world = makeWorld(season: .winter, seed: 2, rare: false)
        hold(world, angle: 5, seconds: 1)
        world.summonRare()
        var seen: [Species] = []
        hold(world, angle: 5, seconds: 3) { _ in seen += self.visitors(world.drainEvents()) }
        XCTAssertEqual(seen, [.polarBear])
    }

    func testSummonInTheLightWaitsForTheNextDark() {
        let world = makeWorld(season: .christmas, seed: 6, rare: false)
        hold(world, angle: 110, seconds: 1)
        world.summonRare()
        hold(world, angle: 110, seconds: 3)
        XCTAssertFalse(world.bugs.contains { $0.rare })
        var seen: [Species] = []
        var at: Double?
        hold(world, angle: 5, seconds: 30) { t in
            let found = self.visitors(world.drainEvents())
            if at == nil && !found.isEmpty { at = t }
            seen += found
        }
        XCTAssertEqual(seen, [.santa])
        XCTAssertLessThan(at ?? 99, 8)
        hold(world, angle: 112, seconds: 5)
        XCTAssertTrue(world.isQuiet)
        hold(world, angle: 5, seconds: 30) { _ in seen += self.visitors(world.drainEvents()) }
        XCTAssertEqual(seen, [.santa])
    }

    func testVisitorIsNeverTheStraggler() {
        for seed in [1, 2, 3, 4, 5] as [UInt64] {
            let world = makeWorld(seed: seed, population: 0, rare: false)
            world.tuning.forceStraggler = true
            hold(world, angle: 5, seconds: 1)
            world.summonRare()
            hold(world, angle: 5, seconds: 8)
            XCTAssertEqual(world.critters.count, 1, "seed \(seed)")
            _ = world.drainEvents()
            var events: [WorldEvent] = []
            hold(world, angle: 112, seconds: 6) { _ in
                events += world.drainEvents()
                XCTAssertNil(world.stragglerID)
            }
            XCTAssertFalse(events.contains(.straggler), "seed \(seed)")
            XCTAssertTrue(world.isQuiet, "seed \(seed)")
        }
        for seed in [1, 2, 3, 4, 5, 6, 7, 8] as [UInt64] {
            let world = makeWorld(seed: seed, population: 1, rare: true)
            world.tuning.forceStraggler = true
            world.tuning.rareMinDark = 0
            hold(world, angle: 5, seconds: 12)
            XCTAssertEqual(world.critters.count, 2, "seed \(seed)")
            let regular = world.critters.first { !$0.species.isRare }?.id
            hold(world, angle: 112, seconds: 3) { _ in
                if let id = world.stragglerID { XCTAssertEqual(id, regular, "seed \(seed)") }
            }
        }
    }

    func testAmbushKeepsTheVisitorAndItsEvent() {
        let world = makeWorld(season: .spring, seed: 3, rare: true, growth: true)
        world.settleInDark()
        XCTAssertEqual(world.critters.count, 25)
        XCTAssertTrue(world.critters.contains { $0.species == .bunny || $0.species == .ufo })
        let events = world.drainEvents()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(visitors(events).count, 1)
        hold(world, angle: 115, seconds: 5)
        XCTAssertTrue(world.isQuiet)
    }

    func testVisitorDoesNotTakeAGrowthSlot() {
        let world = makeWorld(seed: 9, rare: true, growth: true)
        world.tuning.rareMinDark = 0
        hold(world, angle: 5, seconds: 8)
        let regulars = world.critters.filter { !$0.species.isRare }.count
        XCTAssertTrue(world.critters.contains { $0.species.isRare })
        XCTAssertLessThanOrEqual(regulars, 4)
        XCTAssertGreaterThanOrEqual(regulars, 3)
    }

    func testDeterministicPerSeed() {
        let a = makeWorld(seed: 31, rare: true), b = makeWorld(seed: 31, rare: true)
        var t = 0.0
        while t < 34 {
            t += dt
            let angle = t < 30 ? 5.0 : 112
            a.step(dt: dt, lidAngle: angle)
            b.step(dt: dt, lidAngle: angle)
            XCTAssertEqual(a.critters.map(\.id), b.critters.map(\.id))
            XCTAssertEqual(a.critters.map(\.species), b.critters.map(\.species))
            XCTAssertEqual(a.drainEvents(), b.drainEvents())
        }
    }
}
