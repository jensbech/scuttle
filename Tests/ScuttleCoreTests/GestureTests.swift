import XCTest
import CoreGraphics
@testable import ScuttleCore

final class GestureTests: BehaviourCase {
    let story = LidTimeline(keyframes: [
        .init(t: 0, angle: 110), .init(t: 0.5, angle: 78), .init(t: 14, angle: 78),
        .init(t: 14.2, angle: 5), .init(t: 60, angle: 5),
        .init(t: 60.3, angle: 12), .init(t: 60.45, angle: 2), .init(t: 60.6, angle: 12), .init(t: 60.75, angle: 2),
        .init(t: 60.9, angle: 12), .init(t: 61.05, angle: 2), .init(t: 61.2, angle: 12), .init(t: 61.35, angle: 5),
        .init(t: 75, angle: 5), .init(t: 81, angle: 110), .init(t: 90, angle: 110),
    ])

    func storyWorld(seed: UInt64) -> World {
        let world = makeWorld(seed: seed, season: .christmas, population: 30, growth: true)
        world.tuning.sleepAfter = 20
        world.tuning.sleepRamp = 10
        world.tuning.rippleAfter = 15
        world.tuning.forcePeekDare = true
        world.tuning.forceWaveBye = true
        return world
    }

    func testEveryNewGestureShowsUpInOneEvening() {
        var all = Set<Gesture>()
        for seed in [1, 2, 3] as [UInt64] {
            let world = storyWorld(seed: seed)
            drive(world, seconds: 90, angle: story.angle(at:)) { _ in
                all.formUnion(world.critters.map(\.gesture))
            }
            XCTAssertTrue(world.isQuiet, "seed \(seed)")
        }
        let wanted: Set<Gesture> = [.peek, .tiptoe, .wave, .dance, .cheer, .sleep, .look, .shiver, .tumble, .parachute, .popUp]
        XCTAssertEqual(wanted.subtracting(all), [])
        XCTAssertFalse(all.contains(.perch))
    }

    func testGestureTimeCountsUpAndResets() {
        let world = storyWorld(seed: 2)
        var previous: [Int: Critter] = [:]
        var continued = 0
        var restarted = 0
        drive(world, seconds: 70, angle: story.angle(at:)) { _ in
            for c in world.critters {
                XCTAssertGreaterThanOrEqual(c.gestureTime, 0)
                if c.gesture == .none { XCTAssertEqual(c.gestureTime, 0) }
                if let p = previous[c.id], c.gesture != .none {
                    if p.gesture == c.gesture {
                        XCTAssertEqual(c.gestureTime - p.gestureTime, self.dt, accuracy: 1e-6)
                        continued += 1
                    } else {
                        XCTAssertLessThanOrEqual(c.gestureTime, self.dt + 1e-9)
                        restarted += 1
                    }
                }
                previous[c.id] = c
            }
        }
        XCTAssertGreaterThan(continued, 1000)
        XCTAssertGreaterThan(restarted, 20)
    }

    func testRichEveningIsDeterministic() {
        let a = storyWorld(seed: 31), b = storyWorld(seed: 31), c = storyWorld(seed: 32)
        var differed = false
        var t = 0.0
        while t < 90 {
            t += dt
            let angle = story.angle(at: t)
            a.step(dt: dt, lidAngle: angle)
            b.step(dt: dt, lidAngle: angle)
            c.step(dt: dt, lidAngle: angle)
            XCTAssertEqual(signature(a), signature(b))
            XCTAssertEqual(a.critters.map(\.gesture), b.critters.map(\.gesture))
            XCTAssertEqual(a.drainEvents(), b.drainEvents())
            if signature(a) != signature(c) { differed = true }
            _ = c.drainEvents()
        }
        XCTAssertTrue(differed)
    }

    func testNothingScriptedOutlivesTheLight() {
        for seed in [1, 2, 3, 4] as [UInt64] {
            let world = storyWorld(seed: seed)
            drive(world, seconds: 75, angle: story.angle(at:))
            XCTAssertGreaterThan(world.critters.count, 20)
            world.tuning.fleeSpeedRange = 1...2
            world.tuning.fleeSpeedCap = 2
            var lastSeen = 0.0
            hold(world, angle: 110, seconds: 12) { t in
                if !world.critters.isEmpty { lastSeen = t }
            }
            XCTAssertTrue(world.isQuiet, "seed \(seed)")
            XCTAssertLessThan(lastSeen, world.tuning.failsafeSeconds + world.tuning.failsafeGrace + 1.5, "seed \(seed)")
            XCTAssertTrue(world.bugs.allSatisfy { !$0.scripted }, "seed \(seed)")
        }
    }

    func testNewBehavioursAddLittleToStepCost() {
        func cost(plain: Bool) -> (count: Int, perStep: Double) {
            let world = makeWorld(seed: 2, season: .winter, population: 220)
            if plain {
                world.tuning.peekEnabled = false
                world.tuning.playEnabled = false
                world.tuning.sleepEnabled = false
                world.tuning.jiggleEnabled = false
                world.tuning.gentleEnabled = false
                world.tuning.forceEntrance = .creep
                world.tuning.forceGreeting = false
                world.tuning.duskLookChance = 0
            } else {
                world.tuning.sleepAfter = 4
                world.tuning.rippleAfter = 2
                world.tuning.forceRipple = true
            }
            hold(world, angle: 5, seconds: 30)
            var t = 0.0
            let start = Date()
            for i in 0..<400 {
                t += dt
                let angle = i > 200 && i < 300 ? 5 + 6 * sin(t * 2 * .pi * 3) : 5
                world.step(dt: dt, lidAngle: angle)
            }
            return (world.critters.count, Date().timeIntervalSince(start) / 400)
        }
        let plain = cost(plain: true)
        let rich = cost(plain: false)
        XCTAssertGreaterThan(rich.count, 150)
        XCTAssertLessThan(rich.perStep, plain.perStep * 1.35 + 0.0005)
        print("step cost \(rich.count) figures: \(String(format: "%.3f", rich.perStep * 1000)) ms, plain \(String(format: "%.3f", plain.perStep * 1000)) ms")
    }

    func testTeaseStaysUnderTheRadarAtOrdinaryAngles() {
        let world = makeWorld(seed: 3)
        for angle in [85.0, 90, 100, 110, 125] {
            hold(world, angle: angle, seconds: 20) { _ in
                XCTAssertTrue(world.critters.isEmpty)
            }
        }
        XCTAssertTrue(world.drainEvents().isEmpty)
        XCTAssertEqual(world.mood, .bright)
    }
}
