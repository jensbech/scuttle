import XCTest
import CoreGraphics
@testable import ScuttleCore

final class PeekTests: BehaviourCase {
    func peekers(_ world: World) -> [Critter] {
        let ids = Set(world.bugs.filter { $0.peek != nil && $0.mode != .hidden }.map(\.id))
        return world.critters.filter { ids.contains($0.id) }
    }

    func testHoldingSlightlyLoweredBringsOneWatcherToTheEdge() {
        for seed in [1, 2, 3, 7, 42] as [UInt64] {
            let world = makeWorld(seed: seed)
            var seen = Set<Int>()
            var firstAt: Double?
            var most = 0
            var watching = 0.0
            var peekGestures = 0
            hold(world, angle: 80, seconds: 30) { t in
                let p = self.peekers(world)
                XCTAssertEqual(p.count, world.critters.count, "seed \(seed)")
                most = max(most, p.count)
                if !p.isEmpty {
                    watching += self.dt
                    if firstAt == nil { firstAt = t }
                }
                for c in p {
                    seen.insert(c.id)
                    XCTAssertEqual(c.mode, .emerging)
                    XCTAssertTrue(c.gesture == .peek || c.gesture == .wave)
                    if c.gesture == .peek {
                        peekGestures += 1
                        XCTAssertLessThan(self.edgeDistance(c), c.size * 0.3, "seed \(seed)")
                    }
                    XCTAssertEqual(c.fright, 0)
                }
            }
            XCTAssertNotNil(firstAt, "seed \(seed)")
            XCTAssertLessThan(firstAt ?? 99, 2.5, "seed \(seed)")
            XCTAssertEqual(most, 1, "seed \(seed)")
            XCTAssertGreaterThan(watching, 12, "seed \(seed)")
            XCTAssertLessThan(watching, 29, "seed \(seed)")
            XCTAssertGreaterThanOrEqual(seen.count, 2, "seed \(seed)")
            XCTAssertGreaterThan(peekGestures, 300)
            XCTAssertEqual(world.mood, .tease)
        }
    }

    func testPeekersAreTheBoldest() {
        let world = makeWorld(seed: 5)
        let ranked = world.bugs.sorted { $0.nerve > $1.nerve }.map(\.id)
        let top = Set(ranked.prefix(world.tuning.peekPool + 3))
        var seen = Set<Int>()
        hold(world, angle: 76, seconds: 60) { _ in
            for c in self.peekers(world) { seen.insert(c.id) }
        }
        XCTAssertFalse(seen.isEmpty)
        XCTAssertTrue(seen.isSubset(of: top), "\(seen) not within the boldest \(top)")
    }

    func testDeeperIntoTheBandMorePeekAtOnce() {
        var most = 0
        for seed in [1, 2, 3] as [UInt64] {
            let world = makeWorld(seed: seed)
            hold(world, angle: 64, seconds: 30) { _ in
                most = max(most, self.peekers(world).count)
                XCTAssertLessThanOrEqual(self.peekers(world).count, world.tuning.peekMax)
            }
        }
        XCTAssertGreaterThanOrEqual(most, 2)
    }

    func testNoPeekingInFullLightOrWhenLidMovesThrough() {
        let world = makeWorld(seed: 3)
        for angle in [85.0, 88, 95, 110, 130] {
            hold(world, angle: angle, seconds: 6) { _ in
                XCTAssertTrue(world.critters.isEmpty, "angle \(angle)")
            }
        }
        drive(world, seconds: 8, angle: ramp(from: 110, to: 10, over: 0.8)) { _ in
            XCTAssertTrue(self.peekers(world).isEmpty)
        }
        drive(world, seconds: 6, angle: ramp(from: 10, to: 110, over: 3)) { _ in
            XCTAssertTrue(self.peekers(world).isEmpty)
        }
    }

    func testRaisingTheLidALittleMakesThemDuck() {
        for seed in [1, 2, 3, 4] as [UInt64] {
            let world = makeWorld(seed: seed)
            var t = 0.0
            while t < 20 && !(world.bugs.contains { $0.peek?.phase == .watch }) {
                world.step(dt: dt, lidAngle: 76)
                t += dt
            }
            XCTAssertEqual(peekers(world).count, 1, "seed \(seed)")
            var goneAt: Double?
            var back: Double?
            drive(world, seconds: 12, angle: ramp(from: 76, to: 80, over: 0.4)) { t in
                if goneAt == nil && world.critters.isEmpty { goneAt = t }
                if goneAt != nil && back == nil && !world.critters.isEmpty { back = t }
                for c in world.critters {
                    XCTAssertNotEqual(c.mode, .fleeing)
                    XCTAssertNotEqual(c.mode, .startled)
                }
            }
            XCTAssertNotNil(goneAt, "seed \(seed)")
            XCTAssertLessThan(goneAt ?? 99, 0.8, "seed \(seed)")
            XCTAssertNotNil(back, "seed \(seed)")
            XCTAssertGreaterThan((back ?? 0) - (goneAt ?? 0), 2, "seed \(seed)")
            XCTAssertLessThan(back ?? 99, 9, "seed \(seed)")
        }
    }

    func testLoweringFurtherTurnsThePeekerIntoACreeper() {
        for seed in [1, 2, 3] as [UInt64] {
            let world = makeWorld(seed: seed)
            var id: Int?
            var t = 0.0
            while t < 20 && id == nil {
                world.step(dt: dt, lidAngle: 72)
                t += dt
                id = world.bugs.first { $0.mode != .hidden && $0.peek?.phase == .watch }?.id
            }
            guard let pid = id else {
                XCTFail("no peeker for seed \(seed)")
                continue
            }
            var startDepth: Double?
            var deepest = 0.0
            var converted = false
            drive(world, seconds: 8, angle: ramp(from: 72, to: 30, over: 3)) { _ in
                guard let c = world.critters.first(where: { $0.id == pid }) else { return }
                if startDepth == nil { startDepth = self.edgeDistance(c) }
                if !world.bugs.contains(where: { $0.id == pid && $0.peek != nil }) {
                    converted = true
                    if self.onScreen(c) { deepest = max(deepest, self.edgeDistance(c)) }
                }
            }
            XCTAssertTrue(converted, "seed \(seed)")
            XCTAssertNotNil(world.critters.first { $0.id == pid }, "seed \(seed)")
            XCTAssertGreaterThan(deepest, 40, "seed \(seed)")
        }
    }

    func testPeekersClearWhenTheLidOpens() {
        let world = makeWorld(seed: 2)
        var t = 0.0
        while t < 20 && peekers(world).isEmpty {
            world.step(dt: dt, lidAngle: 70)
            t += dt
        }
        XCTAssertFalse(peekers(world).isEmpty)
        XCTAssertEqual(peekers(world).count, world.critters.count)
        var gone: Double?
        hold(world, angle: 112, seconds: 3) { t in
            if gone == nil && world.critters.isEmpty { gone = t }
        }
        XCTAssertLessThan(gone ?? 99, 1.0)
        XCTAssertTrue(world.isQuiet)
    }

    func testDareStepsInAndWaves() {
        let world = makeWorld(seed: 4)
        world.tuning.forcePeekDare = true
        var waved = false
        var fullyIn = false
        hold(world, angle: 78, seconds: 20) { _ in
            for c in self.peekers(world) where c.gesture == .wave {
                waved = true
                if self.edgeDistance(c) > c.size * 0.9 { fullyIn = true }
            }
        }
        XCTAssertTrue(waved)
        XCTAssertTrue(fullyIn)
        let never = makeWorld(seed: 4)
        never.tuning.forcePeekDare = false
        hold(never, angle: 78, seconds: 40) { _ in
            XCTAssertFalse(never.critters.contains { $0.gesture == .wave })
        }
    }

    func testPatienceRunsOut() {
        let world = makeWorld(seed: 6)
        world.tuning.peekPatience = 5
        world.tuning.peekGiveUp = 20
        var late = 0
        var early = 0
        hold(world, angle: 78, seconds: 50) { t in
            if t < 18 { early += world.critters.count }
            if t > 32 { late += world.critters.count }
        }
        XCTAssertGreaterThan(early, 0)
        XCTAssertEqual(late, 0)
        hold(world, angle: 100, seconds: 1)
        var again = false
        hold(world, angle: 78, seconds: 6) { _ in if !world.critters.isEmpty { again = true } }
        XCTAssertTrue(again)
    }

    func testDisabledMeansNoPeeking() {
        let world = makeWorld(seed: 1)
        world.tuning.peekEnabled = false
        hold(world, angle: 76, seconds: 20) { _ in
            XCTAssertTrue(world.critters.isEmpty)
        }
    }

    func testPeekingIsDeterministic() {
        let a = makeWorld(seed: 9), b = makeWorld(seed: 9)
        var t = 0.0
        while t < 25 {
            t += dt
            let angle = t < 15 ? 74.0 : 74 - (t - 15) * 6
            a.step(dt: dt, lidAngle: angle)
            b.step(dt: dt, lidAngle: angle)
            XCTAssertEqual(signature(a), signature(b))
        }
        XCTAssertFalse(a.critters.isEmpty)
    }
}
