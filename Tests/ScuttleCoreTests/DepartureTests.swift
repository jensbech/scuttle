import XCTest
import CoreGraphics
@testable import ScuttleCore

final class DepartureTests: BehaviourCase {
    func gentleOpen(_ world: World, over seconds: Double = 6, to angle: Double = 110, run: Double = 14, each: ((Double) -> Void)? = nil) {
        drive(world, seconds: run, angle: ramp(from: 10, to: angle, over: seconds), each: each)
    }

    func testGentleOpeningSneaksAwayWithoutFright() {
        for seed in [1, 2, 3, 7, 42] as [UInt64] {
            let world = makeWorld(seed: seed)
            world.tuning.playEnabled = false
            hold(world, angle: 10, seconds: 16)
            let before = world.critters.count
            XCTAssertGreaterThan(before, 18)
            var seen = Set<Gesture>()
            var lastVisible = 0.0
            var sneakers = 0
            gentleOpen(world) { t in
                if !world.critters.isEmpty { lastVisible = t }
                sneakers = max(sneakers, world.sneakerCount)
                for c in world.critters {
                    seen.insert(c.gesture)
                    XCTAssertEqual(c.fright, 0, "seed \(seed)")
                    XCTAssertNotEqual(c.mode, .startled, "seed \(seed)")
                    XCTAssertLessThan(c.speed, 260, "seed \(seed)")
                }
            }
            XCTAssertTrue(seen.contains(.look), "seed \(seed)")
            XCTAssertTrue(seen.contains(.tiptoe), "seed \(seed)")
            XCTAssertGreaterThan(sneakers, before / 3, "seed \(seed)")
            XCTAssertLessThan(lastVisible, 9, "seed \(seed)")
            XCTAssertTrue(world.isQuiet, "seed \(seed)")
        }
    }

    func testFastOpeningKeepsTheFrightAndNeverTiptoes() {
        for seed in [1, 2, 3] as [UInt64] {
            let world = makeWorld(seed: seed)
            hold(world, angle: 10, seconds: 16)
            var fright = false
            var tiptoe = false
            var gone: Double?
            drive(world, seconds: 7, angle: ramp(from: 10, to: 110, over: 0.25)) { t in
                for c in world.critters {
                    if c.fright > 0 { fright = true }
                    if c.gesture == .tiptoe || c.gesture == .wave { tiptoe = true }
                }
                if gone == nil && world.critters.isEmpty { gone = t }
            }
            XCTAssertTrue(fright, "seed \(seed)")
            XCTAssertFalse(tiptoe, "seed \(seed)")
            XCTAssertLessThanOrEqual(gone ?? 99, 4.6, "seed \(seed)")
        }
    }

    func testBackwardSneakersKeepFacingTheLight() {
        let world = makeWorld(seed: 3, season: .christmas)
        world.tuning.forceBackward = true
        world.tuning.playEnabled = false
        hold(world, angle: 10, seconds: 16)
        var previous: [Int: Critter] = [:]
        var against = 0
        var along = 0
        var facingAway = 0
        var facingTotal = 0
        gentleOpen(world) { _ in
            for c in world.critters {
                defer { previous[c.id] = c }
                guard c.gesture == .tiptoe, let p = previous[c.id], p.gesture == .tiptoe else { continue }
                let dx = Double(c.position.x - p.position.x), dy = Double(c.position.y - p.position.y)
                guard hypot(dx, dy) > 0.3 else { continue }
                if dx * cos(c.heading) + dy * sin(c.heading) < 0 { against += 1 } else { along += 1 }
                if abs(dx) > hypot(dx, dy) * 0.8 {
                    facingTotal += 1
                    if (c.facing > 0) == (dx < 0) { facingAway += 1 }
                }
            }
        }
        XCTAssertGreaterThan(against, 200)
        XCTAssertGreaterThan(Double(against), Double(against + along) * 0.9)
        if facingTotal > 20 { XCTAssertGreaterThan(Double(facingAway), Double(facingTotal) * 0.8) }
        XCTAssertTrue(world.isQuiet)
    }

    func testSomeoneWavesGoodbye() {
        let world = makeWorld(seed: 5, season: .christmas)
        world.tuning.forceWaveBye = true
        world.tuning.playEnabled = false
        hold(world, angle: 10, seconds: 16)
        var wavers = Set<Int>()
        var concurrent = 0
        gentleOpen(world) { _ in
            let now = world.critters.filter { $0.gesture == .wave }
            concurrent = max(concurrent, now.count)
            for c in now { wavers.insert(c.id) }
        }
        XCTAssertGreaterThanOrEqual(wavers.count, 1)
        XCTAssertLessThanOrEqual(concurrent, 2)
        XCTAssertTrue(world.isQuiet)
    }

    func testTheLastOneOutLooksAroundFirst() {
        var glanced = 0
        for seed in [1, 2, 3, 4, 5, 6] as [UInt64] {
            let world = makeWorld(seed: seed, season: .christmas, population: 1)
            world.tuning.playEnabled = false
            world.tuning.peekEnabled = false
            hold(world, angle: 10, seconds: 12)
            XCTAssertEqual(world.critters.count, 1)
            var sawTiptoe = false
            var looked = false
            drive(world, seconds: 14, angle: ramp(from: 10, to: 80, over: 6)) { _ in
                guard let c = world.critters.first else { return }
                if c.gesture == .tiptoe { sawTiptoe = true }
                if sawTiptoe && c.gesture == .look && self.edgeDistance(c) < c.size * 1.3 { looked = true }
            }
            if looked { glanced += 1 }
            XCTAssertTrue(world.critters.isEmpty, "seed \(seed)")
        }
        XCTAssertGreaterThanOrEqual(glanced, 4)
    }

    func testLoweringAgainBringsSneakersBack() {
        let world = makeWorld(seed: 2)
        world.tuning.playEnabled = false
        hold(world, angle: 10, seconds: 16)
        drive(world, seconds: 3, angle: ramp(from: 10, to: 50, over: 3))
        let sneaking = world.sneakerCount
        XCTAssertGreaterThan(sneaking, 2)
        hold(world, angle: 8, seconds: 4)
        XCTAssertEqual(world.sneakerCount, 0)
        XCTAssertFalse(world.critters.contains { $0.gesture == .tiptoe })
        XCTAssertGreaterThan(world.critters.count, 10)
    }

    func testSnapDuringASneakTurnsIntoAFright() {
        let world = makeWorld(seed: 4)
        hold(world, angle: 10, seconds: 16)
        drive(world, seconds: 2.5, angle: ramp(from: 10, to: 40, over: 2.5))
        XCTAssertGreaterThan(world.sneakerCount, 0)
        var fright = false
        var gone: Double?
        hold(world, angle: 115, seconds: 7) { t in
            if world.critters.contains(where: { $0.fright > 0 }) { fright = true }
            if gone == nil && world.critters.isEmpty { gone = t }
        }
        XCTAssertTrue(fright)
        XCTAssertLessThanOrEqual(gone ?? 99, 4.6)
        XCTAssertTrue(world.isQuiet)
    }

    func testGentleDisabledKeepsTodaysFright() {
        let world = makeWorld(seed: 1)
        world.tuning.gentleEnabled = false
        hold(world, angle: 10, seconds: 16)
        var fright = false
        gentleOpen(world) { _ in
            if world.critters.contains(where: { $0.fright > 0 }) { fright = true }
            XCTAssertEqual(world.sneakerCount, 0)
        }
        XCTAssertTrue(fright)
        XCTAssertTrue(world.isQuiet)
    }

    func testFailsafeStillClearsSlowSneakers() {
        let world = makeWorld(seed: 6)
        world.tuning.fleeSpeedRange = 1...2
        world.tuning.fleeSpeedCap = 2
        hold(world, angle: 10, seconds: 12)
        var lastSeen = 0.0
        gentleOpen(world, over: 4, run: 20) { t in
            if !world.critters.isEmpty { lastSeen = t }
        }
        XCTAssertTrue(world.isQuiet)
        XCTAssertLessThan(lastSeen, 4 + world.tuning.failsafeSeconds + world.tuning.fadeTime + 1)
    }
}
