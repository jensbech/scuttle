import XCTest
import CoreGraphics
@testable import ScuttleCore

final class LidMotionTests: BehaviourCase {
    func jiggle(_ world: World, around base: Double, amplitude: Double = 6, hz: Double = 3, seconds: Double, each: ((Double) -> Void)? = nil) {
        drive(world, seconds: seconds, angle: { t in base + amplitude * sin(t * 2 * .pi * hz) }, each: each)
    }

    func testMoodFollowsTheLidAngle() {
        let world = makeWorld(population: 0)
        let expected: [(Double, LidMood)] = [(110, .bright), (80, .tease), (66, .dusk), (50, .dusk), (30, .dark), (13, .dark), (8, .deep), (0, .deep), (90, .bright)]
        for (angle, mood) in expected {
            hold(world, angle: angle, seconds: 1.5)
            XCTAssertEqual(world.mood, mood, "angle \(angle)")
        }
    }

    func testSlamBurstsInWithTumblesAndPopUps() {
        var burstGestures = 0
        for seed in [1, 2, 3, 4, 5, 6] as [UInt64] {
            let world = makeWorld(seed: seed, season: .christmas, growth: true)
            var firstSeen: [Int: Double] = [:]
            var firstGesture: [Int: Gesture] = [:]
            hold(world, angle: 110, seconds: 1)
            hold(world, angle: 5, seconds: 4) { t in
                for c in world.critters where firstSeen[c.id] == nil {
                    firstSeen[c.id] = t
                    firstGesture[c.id] = c.gesture
                }
            }
            XCTAssertEqual(world.lidArrival, .slam, "seed \(seed)")
            let early = firstSeen.filter { $0.value < 1.2 }
            XCTAssertGreaterThanOrEqual(early.count, 3, "seed \(seed)")
            XCTAssertLessThanOrEqual(firstSeen.count, 3, "seed \(seed)")
            for (id, _) in early {
                let g = firstGesture[id] ?? .none
                XCTAssertTrue(g == .tumble || g == .popUp, "seed \(seed) \(g)")
                burstGestures += 1
            }
        }
        XCTAssertGreaterThanOrEqual(burstGestures, 18)
    }

    func testSlowLowerBringsCarefulOnesFirst() {
        for seed in [1, 2, 3, 4] as [UInt64] {
            let world = makeWorld(seed: seed, season: .christmas, growth: true)
            world.tuning.peekEnabled = false
            var pauses: [Int: Double] = [:]
            var order: [Int] = []
            var shown: [Int: Set<Gesture>] = [:]
            drive(world, seconds: 22, angle: ramp(from: 110, to: 8, over: 12)) { _ in
                for c in world.critters {
                    if !order.contains(c.id) { order.append(c.id) }
                    if c.gesture == .peek { pauses[c.id, default: 0] += self.dt }
                    shown[c.id, default: []].insert(c.gesture)
                }
            }
            XCTAssertEqual(world.lidArrival, .slow, "seed \(seed)")
            XCTAssertGreaterThanOrEqual(order.count, 2, "seed \(seed)")
            for id in order.prefix(world.tuning.carefulArrivals) {
                XCTAssertGreaterThan(pauses[id] ?? 0, world.tuning.peekPause.lowerBound * world.tuning.carefulPeekScale, "seed \(seed) id \(id)")
                XCTAssertFalse(shown[id]?.contains(.tumble) ?? true, "seed \(seed) id \(id)")
                XCTAssertFalse(shown[id]?.contains(.popUp) ?? true, "seed \(seed) id \(id)")
            }
        }
    }

    func testOrdinaryLowerIsSteady() {
        let world = makeWorld(seed: 2)
        drive(world, seconds: 4, angle: ramp(from: 110, to: 10, over: 1.5))
        XCTAssertEqual(world.lidArrival, .steady)
        hold(world, angle: 112, seconds: 6)
        drive(world, seconds: 3, angle: ramp(from: 110, to: 10, over: 0.2))
        XCTAssertEqual(world.lidArrival, .slam)
    }

    func testJiggleShakesThemAndTheyRecover() {
        for seed in [1, 2, 3] as [UInt64] {
            let world = makeWorld(seed: seed, season: .winter)
            world.tuning.playEnabled = false
            hold(world, angle: 10, seconds: 12)
            let before = world.critters.count
            XCTAssertGreaterThan(before, 20)
            var detected: Double?
            var mostShaken = 0
            var kinds = Set<Gesture>()
            jiggle(world, around: 10, seconds: 2.5) { t in
                if detected == nil && world.isJiggling { detected = t }
                mostShaken = max(mostShaken, world.shakenCount)
                for c in world.critters {
                    kinds.insert(c.gesture)
                    XCTAssertEqual(c.fright, 0)
                    XCTAssertNotEqual(c.mode, .fleeing)
                }
            }
            XCTAssertNotNil(detected, "seed \(seed)")
            XCTAssertLessThan(detected ?? 99, 1.0, "seed \(seed)")
            XCTAssertGreaterThan(Double(mostShaken), Double(before) * 0.8, "seed \(seed)")
            XCTAssertTrue(kinds.contains(.shiver), "seed \(seed)")
            XCTAssertTrue(kinds.contains(.tumble), "seed \(seed)")
            var dazed = false
            var recovered: Double?
            hold(world, angle: 10, seconds: 5) { t in
                if self.count(world, .look) > 0 { dazed = true }
                if recovered == nil && world.shakenCount == 0 { recovered = t }
            }
            XCTAssertTrue(dazed, "seed \(seed)")
            XCTAssertNotNil(recovered, "seed \(seed)")
            XCTAssertLessThan(recovered ?? 99, 3.0, "seed \(seed)")
            XCTAssertFalse(world.isJiggling)
            XCTAssertEqual(world.critters.count, before, "seed \(seed)")
            XCTAssertFalse(world.critters.contains { $0.gesture == .shiver || $0.gesture == .tumble })
        }
    }

    func testFlyersSwirlLikeASnowGlobeWhileWalkersShiverInPlace() {
        let world = makeWorld(seed: 4, season: .winter, population: 40)
        world.tuning.playEnabled = false
        hold(world, angle: 10, seconds: 12)
        var start: [Int: CGPoint] = [:]
        var airMoved: [Double] = []
        var shiverMoved: [Double] = []
        jiggle(world, around: 10, seconds: 2.5) { _ in
            for c in world.critters where start[c.id] == nil && (c.gesture == .shiver || c.gesture == .tumble) {
                start[c.id] = c.position
            }
        }
        let shaken = Set(world.bugs.filter { $0.shake != nil }.map(\.id))
        for c in world.critters where shaken.contains(c.id) {
            guard let s = start[c.id] else { continue }
            let d = hypot(Double(c.position.x - s.x), Double(c.position.y - s.y))
            if c.species.isAirborne { airMoved.append(d) }
            if c.gesture == .shiver && c.species.locomotion != .hop { shiverMoved.append(d) }
        }
        XCTAssertFalse(airMoved.isEmpty)
        XCTAssertFalse(shiverMoved.isEmpty)
        let air = airMoved.reduce(0, +) / Double(airMoved.count)
        XCTAssertGreaterThan(air, 40)
        XCTAssertLessThan(shiverMoved.max() ?? 99, 3)
    }

    func testSlowRockingIsNotAJiggle() {
        let world = makeWorld(seed: 2)
        hold(world, angle: 10, seconds: 10)
        jiggle(world, around: 20, amplitude: 10, hz: 0.25, seconds: 8) { _ in
            XCTAssertFalse(world.isJiggling)
            XCTAssertEqual(world.shakenCount, 0)
        }
        jiggle(world, around: 10, amplitude: 0.8, hz: 4, seconds: 3) { _ in
            XCTAssertFalse(world.isJiggling)
        }
    }

    func testJiggleCanBeTurnedOff() {
        let world = makeWorld(seed: 3)
        world.tuning.jiggleEnabled = false
        hold(world, angle: 10, seconds: 10)
        jiggle(world, around: 10, seconds: 3) { _ in
            XCTAssertFalse(world.isJiggling)
            XCTAssertEqual(world.shakenCount, 0)
        }
    }

    func testOpeningAfterAJiggleStillScattersInTime() {
        for seed in [1, 5, 9] as [UInt64] {
            let world = makeWorld(seed: seed)
            hold(world, angle: 10, seconds: 12)
            jiggle(world, around: 10, seconds: 2)
            XCTAssertGreaterThan(world.shakenCount, 0)
            var frightened = false
            var gone: Double?
            hold(world, angle: 115, seconds: 7) { t in
                if world.critters.contains(where: { $0.fright > 0 }) { frightened = true }
                if gone == nil && world.critters.isEmpty { gone = t }
            }
            XCTAssertTrue(frightened, "seed \(seed)")
            XCTAssertLessThanOrEqual(gone ?? 99, 4.6, "seed \(seed)")
            XCTAssertTrue(world.isQuiet)
        }
    }
}
