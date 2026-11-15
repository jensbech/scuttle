import XCTest
import CoreGraphics
@testable import ScuttleCore

final class EdgeTests: XCTestCase {
    let screen = CGSize(width: 1512, height: 982)
    let dt = 1.0 / 60.0

    enum Side: CaseIterable {
        case bottom, left, right, top
    }

    func makeWorld(seed: UInt64, population: Int = 24) -> World {
        let world = World(size: screen, config: WorldConfig(population: population, seed: seed))
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

    func outside(_ p: CGPoint) -> Side? {
        let x = Double(p.x), y = Double(p.y)
        if y < 0 { return .bottom }
        if y > Double(screen.height) { return .top }
        if x < 0 { return .left }
        if x > Double(screen.width) { return .right }
        return nil
    }

    func depth(_ p: CGPoint, _ side: Side) -> Double {
        let x = Double(p.x), y = Double(p.y)
        switch side {
        case .bottom: return y
        case .top: return Double(screen.height) - y
        case .left: return x
        case .right: return Double(screen.width) - x
        }
    }

    func testEntriesUseAllFourEdgesInProportionAndSpreadAlongThem() {
        var counts: [Side: Int] = [:]
        var cornerish = 0
        var total = 0
        for seed in [1, 2, 3, 4] as [UInt64] {
            let world = makeWorld(seed: seed, population: 120)
            for _ in 0..<3 {
                var seen = Set<Int>()
                hold(world, angle: 5, seconds: 12) {
                    for c in world.critters where c.mode == .emerging && !seen.contains(c.id) {
                        seen.insert(c.id)
                        guard let side = self.outside(c.position) else { continue }
                        counts[side, default: 0] += 1
                        total += 1
                        let along: Double
                        let span: Double
                        switch side {
                        case .bottom, .top:
                            along = Double(c.position.x)
                            span = Double(self.screen.width)
                        case .left, .right:
                            along = Double(c.position.y)
                            span = Double(self.screen.height)
                        }
                        if along < span * 0.05 || along > span * 0.95 { cornerish += 1 }
                    }
                }
                hold(world, angle: 112, seconds: 6)
                XCTAssertTrue(world.isQuiet)
            }
        }
        XCTAssertGreaterThan(total, 1000)
        let t = Tuning()
        let weights: [Side: Double] = [.bottom: t.bottomEntryWeight, .left: t.leftEntryWeight, .right: t.rightEntryWeight, .top: t.topEntryWeight]
        let sum = weights.values.reduce(0, +)
        for side in Side.allCases {
            let share = Double(counts[side] ?? 0) / Double(total)
            XCTAssertEqual(share, (weights[side] ?? 0) / sum, accuracy: 0.05, "\(side)")
        }
        XCTAssertEqual(cornerish, 0)
    }

    func testEntryWeightsAreTunable() {
        let world = makeWorld(seed: 5, population: 60)
        world.tuning.bottomEntryWeight = 0
        world.tuning.leftEntryWeight = 0
        world.tuning.rightEntryWeight = 0
        world.tuning.topEntryWeight = 1
        var seen = Set<Int>()
        var sides = Set<Side>()
        hold(world, angle: 5, seconds: 12) {
            for c in world.critters where c.mode == .emerging && !seen.contains(c.id) {
                seen.insert(c.id)
                if let s = self.outside(c.position) { sides.insert(s) }
            }
        }
        XCTAssertEqual(sides, [.top])
        XCTAssertGreaterThan(world.critters.count, 50)
    }

    func testDarkPopulatesWholeScreenAndTimidStayNearAnEdge() {
        let world = makeWorld(seed: 3, population: 120)
        hold(world, angle: 5, seconds: 14)
        var quadrants = Set<Int>()
        var central = 0
        for c in world.critters {
            let x = Double(c.position.x), y = Double(c.position.y)
            quadrants.insert((x < Double(screen.width) / 2 ? 0 : 1) + (y < Double(screen.height) / 2 ? 0 : 2))
            let d = min(min(x, Double(screen.width) - x), min(y, Double(screen.height) - y))
            if d > 250 { central += 1 }
        }
        XCTAssertEqual(quadrants.count, 4)
        XCTAssertGreaterThan(central, 2)
        XCTAssertLessThan(central, world.critters.count / 2)
        let highHalf = world.critters.filter { Double($0.position.y) > Double(screen.height) / 2 }.count
        XCTAssertGreaterThan(highHalf, world.critters.count / 5)
    }

    func testFleeGoesToTheNearestEdge() {
        var exits: [Side: Int] = [:]
        var near = 0
        var tracked = 0
        for seed in [1, 2, 3, 7, 42] as [UInt64] {
            let world = makeWorld(seed: seed)
            hold(world, angle: 10, seconds: 16)
            var start: [Int: CGPoint] = [:]
            var last: [Int: CGPoint] = [:]
            var gone: [Int: CGPoint] = [:]
            hold(world, angle: 112, seconds: 6) {
                var present = Set<Int>()
                for c in world.critters {
                    present.insert(c.id)
                    if c.mode == .fleeing && start[c.id] == nil { start[c.id] = c.position }
                    last[c.id] = c.position
                }
                for (id, p) in last where !present.contains(id) && gone[id] == nil { gone[id] = p }
            }
            XCTAssertTrue(world.isQuiet)
            for (id, s) in start {
                guard let end = gone[id] else { continue }
                let w = Double(screen.width), h = Double(screen.height)
                let ex = Double(end.x), ey = Double(end.y)
                let distances: [(Side, Double)] = [(.bottom, ey), (.top, h - ey), (.left, ex), (.right, w - ex)]
                guard let exit = distances.min(by: { $0.1 < $1.1 })?.0 else { continue }
                exits[exit, default: 0] += 1
                tracked += 1
                let nearest = Side.allCases.map { depth(s, $0) }.min() ?? 0
                if depth(s, exit) <= nearest / 0.8 + 60 { near += 1 }
            }
        }
        XCTAssertGreaterThan(tracked, 90)
        XCTAssertGreaterThan(Double(near), Double(tracked) * 0.92)
        XCTAssertEqual(Set(exits.keys), Set(Side.allCases))
    }

    func testPartialLightPullsThemTowardTheirNearestEdge() {
        let world = makeWorld(seed: 4, population: 60)
        hold(world, angle: 8, seconds: 16)
        func meanDistance() -> Double {
            let d = world.critters.map { c -> Double in
                let x = Double(c.position.x), y = Double(c.position.y)
                return min(min(x, Double(screen.width) - x), min(y, Double(screen.height) - y))
            }
            return d.reduce(0, +) / Double(max(1, d.count))
        }
        let dark = meanDistance()
        hold(world, angle: 42, seconds: 12)
        XCTAssertGreaterThan(world.critters.count, 3)
        XCTAssertLessThan(meanDistance(), dark * 0.7)
        for c in world.critters {
            let x = Double(c.position.x), y = Double(c.position.y)
            let d = min(min(x, Double(screen.width) - x), min(y, Double(screen.height) - y))
            XCTAssertLessThan(d, Double(screen.height) * 0.4)
        }
        hold(world, angle: 112, seconds: 6)
        XCTAssertTrue(world.isQuiet)
    }
}
