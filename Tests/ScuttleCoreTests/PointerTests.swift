import XCTest
import CoreGraphics
@testable import ScuttleCore

final class PointerTests: BehaviourCase {
    func pointerWorld(seed: UInt64 = 3, season: Season = .christmas, population: Int = 30) -> World {
        let world = makeWorld(seed: seed, season: season, population: population)
        world.tuning.socialEnabled = false
        world.tuning.habitsEnabled = false
        world.tuning.forceGreeting = false
        return world
    }

    func point(_ world: World, _ x: Double, _ y: Double, speed: Double = 0) {
        world.surroundings = Surroundings(pointer: CGPoint(x: x, y: y), pointerSpeed: speed, ledges: [])
    }

    func lures(_ world: World, _ kind: LureKind) -> [Bug] {
        world.bugs.filter { $0.mode != .hidden && $0.lure?.kind == kind }
    }

    func testRestingPointerDrawsACuriousAudience() {
        var waved = 0
        for seed in [1, 2, 3] as [UInt64] {
            let world = pointerWorld(seed: seed)
            hold(world, angle: 8, seconds: 12)
            let cx = 756.0, cy = 400.0
            point(world, cx, cy)
            var early = 0
            var smallCrowd = 0
            var crowd = 0
            var wavers = Set<Int>()
            var looking = 0
            hold(world, angle: 8, seconds: 25) { t in
                let n = world.curiousCount
                if t < world.tuning.curiosityDelay - 0.05 { early += n }
                if t < world.tuning.audienceDelay - 0.1 { smallCrowd = max(smallCrowd, n) }
                crowd = max(crowd, n)
                for b in self.lures(world, .curious) {
                    XCTAssertGreaterThanOrEqual(b.nerve, world.tuning.curiosityNerve)
                    if b.gesture == .look {
                        looking += 1
                        let d = hypot(b.x - cx, b.y - cy)
                        XCTAssertGreaterThan(d, b.size * 1.5 + 20)
                        if abs(b.x - cx) > b.size { XCTAssertEqual(b.facing, b.x < cx ? 1 : -1) }
                    }
                    if b.gesture == .wave { wavers.insert(b.id) }
                }
            }
            XCTAssertEqual(early, 0, "seed \(seed)")
            XCTAssertGreaterThanOrEqual(smallCrowd, 1, "seed \(seed)")
            XCTAssertLessThanOrEqual(smallCrowd, world.tuning.curiousMax, "seed \(seed)")
            XCTAssertGreaterThan(crowd, world.tuning.curiousMax, "seed \(seed)")
            XCTAssertLessThanOrEqual(crowd, world.tuning.audienceMax, "seed \(seed)")
            XCTAssertGreaterThan(looking, 300, "seed \(seed)")
            XCTAssertLessThanOrEqual(wavers.count, 1, "seed \(seed)")
            waved += wavers.count
        }
        XCTAssertGreaterThanOrEqual(waved, 1)
    }

    func testAudienceDriftsAwayWhenBoredAndWhenThePointerGoes() {
        let world = pointerWorld(seed: 4)
        world.tuning.curiosityBored = 12
        hold(world, angle: 8, seconds: 12)
        point(world, 700, 450)
        var most = 0
        hold(world, angle: 8, seconds: 11) { _ in most = max(most, world.curiousCount) }
        XCTAssertGreaterThan(most, 0)
        hold(world, angle: 8, seconds: 14)
        XCTAssertEqual(world.curiousCount, 0)
        let again = pointerWorld(seed: 5)
        hold(again, angle: 8, seconds: 12)
        point(again, 700, 450)
        hold(again, angle: 8, seconds: 10)
        XCTAssertGreaterThan(again.curiousCount, 0)
        again.surroundings = Surroundings()
        hold(again, angle: 8, seconds: 1.5)
        XCTAssertEqual(again.curiousCount, 0)
        XCTAssertTrue(again.bugs.allSatisfy { $0.lure == nil })
    }

    func sweep(_ world: World, speed: Double, seconds: Double, y: Double, each: ((Double) -> Void)? = nil) {
        var t = 0.0
        var x = 60.0
        var dir = 1.0
        while t < seconds - 1e-9 {
            t += dt
            x += dir * speed * dt
            if x > Double(screen.width) - 60 { dir = -1 }
            if x < 60 { dir = 1 }
            let yy = y + 120 * sin(t * 1.3)
            point(world, x, yy, speed: speed)
            world.step(dt: dt, lidAngle: 8)
            each?(t)
        }
    }

    func testMovingPointerMakesNearbyFiguresShyAway() {
        for seed in [1, 2] as [UInt64] {
            let world = pointerWorld(seed: seed, population: 40)
            hold(world, angle: 8, seconds: 14)
            let before = world.critters.count
            _ = world.drainEvents()
            var shy = Set<Int>()
            var backing = 0
            sweep(world, speed: 200, seconds: 10, y: 300) { _ in
                for c in world.critters {
                    XCTAssertEqual(c.fright, 0)
                    XCTAssertNotEqual(c.mode, .startled)
                    XCTAssertNotEqual(c.mode, .fleeing)
                }
                for b in self.lures(world, .shy) {
                    shy.insert(b.id)
                    if b.backward { backing += 1 }
                }
            }
            XCTAssertGreaterThan(shy.count, 4, "seed \(seed)")
            XCTAssertGreaterThan(backing, 20, "seed \(seed)")
            XCTAssertEqual(world.critters.count, before, "seed \(seed)")
            XCTAssertFalse(world.drainEvents().contains { if case .scatter = $0 { return true } else { return false } }, "seed \(seed)")
            world.surroundings = Surroundings()
            hold(world, angle: 8, seconds: 3)
            XCTAssertEqual(world.shyCount, 0, "seed \(seed)")
        }
    }

    func testFastSwipeBowlsFiguresOverButNeverScatters() {
        var tumbled = Set<Int>()
        var scampered = Set<Int>()
        var shivered = Set<Int>()
        for seed in [1, 2, 3] as [UInt64] {
            let world = pointerWorld(seed: seed, population: 40)
            world.tuning.socialEnabled = true
            world.tuning.socialAfter = 999
            hold(world, angle: 8, seconds: 14)
            let before = world.critters.count
            _ = world.drainEvents()
            sweep(world, speed: 1400, seconds: 4, y: 350) { _ in
                for c in world.critters {
                    XCTAssertEqual(c.fright, 0)
                    XCTAssertNotEqual(c.mode, .fleeing)
                    XCTAssertLessThanOrEqual(c.speed, world.tuning.fleeSpeedCap + 0.001)
                    if c.gesture == .tumble { tumbled.insert(c.id) }
                    if c.gesture == .shiver { shivered.insert(c.id) }
                }
                for b in self.lures(world, .scamper) { scampered.insert(b.id) }
            }
            XCTAssertEqual(world.critters.count, before, "seed \(seed)")
            XCTAssertFalse(world.drainEvents().contains { if case .scatter = $0 { return true } else { return false } }, "seed \(seed)")
            world.surroundings = Surroundings()
            hold(world, angle: 8, seconds: 3)
            XCTAssertEqual(world.shyCount, 0, "seed \(seed)")
            XCTAssertFalse(world.critters.contains { $0.gesture == .tumble })
        }
        XCTAssertGreaterThan(tumbled.count, 3)
        XCTAssertGreaterThan(shivered.count, 0)
        let medium = pointerWorld(seed: 4, population: 40)
        hold(medium, angle: 8, seconds: 14)
        sweep(medium, speed: 500, seconds: 4, y: 350) { _ in
            for b in self.lures(medium, .scamper) { scampered.insert(b.id) }
        }
        XCTAssertGreaterThan(scampered.count, 2)
    }

    func testAPlayfulOneTrailsASlowPointerLikeADuckling() {
        var trailed = 0
        var keptBack = 0
        var close = 0
        for seed in [1, 2, 3] as [UInt64] {
            let world = pointerWorld(seed: seed)
            world.tuning.forceFollow = true
            world.tuning.curiosityEnabled = false
            hold(world, angle: 8, seconds: 12)
            var t = 0.0
            while t < 14 {
                t += dt
                let x = 756 + 380 * cos(t * 0.25), y = 491 + 220 * sin(t * 0.25)
                point(world, x, y, speed: 100)
                world.step(dt: dt, lidAngle: 8)
                for b in self.lures(world, .follow) where b.lure?.ahead == -1 && b.lure?.stage == 0 {
                    trailed += 1
                    let d = hypot(b.x - x, b.y - y)
                    if d > b.size * 1.5 { keptBack += 1 }
                    if d < 420 { close += 1 }
                }
                XCTAssertLessThanOrEqual(world.followerCount, 2)
            }
            point(world, 756, 491, speed: 900)
            hold(world, angle: 8, seconds: 1.5)
            XCTAssertEqual(world.followerCount, 0, "seed \(seed)")
        }
        XCTAssertGreaterThan(trailed, 600)
        XCTAssertGreaterThan(Double(keptBack), Double(trailed) * 0.95)
        XCTAssertGreaterThan(Double(close), Double(trailed) * 0.8)
    }

    func testFollowersLetGoWhenThePointerVanishes() {
        let world = pointerWorld(seed: 2)
        world.tuning.forceFollow = true
        hold(world, angle: 8, seconds: 12)
        var t = 0.0
        while t < 5 {
            t += dt
            point(world, 400 + 60 * t, 400, speed: 60)
            world.step(dt: dt, lidAngle: 8)
        }
        XCTAssertGreaterThan(world.followerCount, 0)
        world.surroundings = Surroundings()
        hold(world, angle: 8, seconds: 1.2)
        XCTAssertEqual(world.followerCount, 0)
    }

    func testOffScreenOrMissingPointerChangesNothing() {
        let a = pointerWorld(seed: 9), b = pointerWorld(seed: 9)
        b.tuning.pointerEnabled = false
        a.surroundings = Surroundings(pointer: nil, pointerSpeed: 0, ledges: [])
        var t = 0.0
        while t < 30 {
            t += dt
            a.step(dt: dt, lidAngle: 8)
            b.step(dt: dt, lidAngle: 8)
            XCTAssertEqual(signature(a), signature(b))
        }
        let c = pointerWorld(seed: 9)
        point(c, -400, -400)
        hold(c, angle: 8, seconds: 30) { _ in
            XCTAssertTrue(c.bugs.allSatisfy { $0.lure == nil })
        }
    }

    func testThePointerNeverStopsTheScatter() {
        for seed in [1, 2, 3] as [UInt64] {
            let world = pointerWorld(seed: seed)
            world.tuning.forceFollow = true
            hold(world, angle: 8, seconds: 12)
            point(world, 756, 420)
            hold(world, angle: 8, seconds: 12)
            XCTAssertGreaterThan(world.curiousCount, 0, "seed \(seed)")
            clearsAfterSnap(world)
            XCTAssertTrue(world.bugs.allSatisfy { $0.lure == nil }, "seed \(seed)")
        }
        let world = pointerWorld(seed: 4)
        hold(world, angle: 8, seconds: 12)
        point(world, 756, 420)
        hold(world, angle: 8, seconds: 10)
        world.tuning.fleeSpeedRange = 1...2
        world.tuning.fleeSpeedCap = 2
        var lastSeen = 0.0
        hold(world, angle: 110, seconds: 12) { t in
            if !world.critters.isEmpty { lastSeen = t }
        }
        XCTAssertTrue(world.isQuiet)
        XCTAssertLessThan(lastSeen, world.tuning.failsafeSeconds + world.tuning.failsafeGrace + 1.5)
    }

    func testPointerBehaviourIsDeterministic() {
        let a = pointerWorld(seed: 21), b = pointerWorld(seed: 21)
        var t = 0.0
        while t < 40 {
            t += dt
            let still = t > 14 && t < 26
            let x = still ? 700 : 700 + 300 * sin(t * 0.7), y = 450.0
            let speed = still ? 0 : abs(300 * 0.7 * cos(t * 0.7))
            for w in [a, b] {
                point(w, x, y, speed: speed)
                w.step(dt: dt, lidAngle: 8)
            }
            XCTAssertEqual(signature(a), signature(b))
        }
    }
}
