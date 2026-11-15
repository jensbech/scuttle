import XCTest
import CoreGraphics
@testable import ScuttleCore

final class HabitTests: BehaviourCase {
    func habitWorld(seed: UInt64 = 2, season: Season = .autumn, population: Int = 30) -> World {
        let world = makeWorld(seed: seed, season: season, population: population)
        world.tuning.socialEnabled = false
        world.tuning.forceGreeting = false
        return world
    }

    func testIdleHabitsAreOccasionalAndVariedPerLocomotion() {
        var seen = Set<HabitKind>()
        for (season, seed) in [(Season.autumn, 1), (.spring, 2), (.summer, 3), (.winter, 4), (.halloween, 5), (.newYear, 6), (.christmas, 7)] as [(Season, UInt64)] {
            let world = habitWorld(seed: seed, season: season)
            var early = 0
            var busiest = 0
            var figureTime = 0.0
            var habitTime = 0.0
            hold(world, angle: 8, seconds: 60) { t in
                let counts = world.habitCounts
                let n = counts.values.reduce(0, +)
                if t < world.tuning.habitAfter - 0.05 { early += n }
                busiest = max(busiest, n)
                seen.formUnion(counts.keys)
                habitTime += Double(n) * self.dt
                figureTime += Double(world.critters.count) * self.dt
                for b in world.bugs where b.mode != .hidden {
                    guard let k = b.habit else { continue }
                    XCTAssertTrue(world.habitKinds(for: b).contains { $0.0 == k.kind }, "\(b.species) \(k.kind)")
                }
            }
            XCTAssertEqual(early, 0, "\(season)")
            XCTAssertLessThanOrEqual(busiest, max(1, Int(30 * world.tuning.habitShare)) + 1, "\(season)")
            XCTAssertGreaterThan(habitTime, 0, "\(season)")
            XCTAssertLessThan(habitTime / max(1, figureTime), 0.2, "\(season)")
        }
        XCTAssertGreaterThanOrEqual(seen.count, 8, "\(seen)")
    }

    func testEveryHabitRunsAndEnds() {
        let cases: [(HabitKind, Season)] = [
            (.pace, .christmas), (.lookAround, .christmas), (.sniff, .autumn), (.circle, .spring),
            (.zigzag, .spring), (.loop, .summer), (.zip, .spring), (.drift, .newYear), (.spin, .newYear), (.patrol, .summer),
        ]
        for (kind, season) in cases {
            let world = habitWorld(seed: 3, season: season)
            world.tuning.forceHabit = kind
            world.tuning.habitShare = 0.3
            var started = Set<Int>()
            var longest: [Int: Double] = [:]
            var finished = 0
            var was = Set<Int>()
            hold(world, angle: 8, seconds: 45) { _ in
                var now = Set<Int>()
                for b in world.bugs where b.mode != .hidden && b.habit?.kind == kind {
                    now.insert(b.id)
                    started.insert(b.id)
                    longest[b.id] = max(longest[b.id] ?? 0, b.habit!.total)
                }
                finished += was.subtracting(now).count
                was = now
            }
            XCTAssertFalse(started.isEmpty, "\(kind)")
            XCTAssertGreaterThan(finished, 0, "\(kind)")
            XCTAssertLessThanOrEqual(longest.values.max() ?? 0, 12.1, "\(kind)")
        }
    }

    func testHabitsKeepTheGaitAndFacingHonest() {
        for season in [Season.christmas, .autumn, .spring, .summer] {
            let world = habitWorld(seed: 4, season: season)
            world.tuning.habitChance = 1
            world.tuning.habitShare = 0.4
            var last: [Int: Critter] = [:]
            var flips: [Int: [Double]] = [:]
            var clock = 0.0
            hold(world, angle: 8, seconds: 40) { _ in
                clock += self.dt
                for c in world.critters {
                    if let p = last[c.id] {
                        if p.facing != c.facing { flips[c.id, default: []].append(clock) }
                        let moved = hypot(Double(c.position.x - p.position.x), Double(c.position.y - p.position.y))
                        if c.species.locomotion == .flutter && (c.mode == .wandering || c.mode == .resting) {
                            XCTAssertGreaterThan(moved, 0, "\(c.species)")
                        }
                        if c.species.locomotion == .hop && c.mode == .wandering && c.lift == 0 && p.lift == 0 {
                            XCTAssertLessThan(moved, 0.01, "\(c.species)")
                        }
                    }
                    last[c.id] = c
                }
            }
            for (_, times) in flips {
                for i in times.indices where i + 4 < times.count {
                    XCTAssertGreaterThan(times[i + 4] - times[i], 1.0, "\(season)")
                }
            }
        }
    }

    func testNoHabitsAtDuskInBrightLightOrWhenSwitchedOff() {
        let dusk = habitWorld(seed: 5)
        dusk.tuning.forceHabit = .sniff
        hold(dusk, angle: 10, seconds: 8)
        hold(dusk, angle: 48, seconds: 2)
        hold(dusk, angle: 48, seconds: 30) { _ in
            XCTAssertTrue(dusk.habitCounts.isEmpty)
        }
        let off = habitWorld(seed: 5)
        off.tuning.habitsEnabled = false
        off.tuning.forceHabit = .sniff
        hold(off, angle: 8, seconds: 40) { _ in
            XCTAssertTrue(off.bugs.allSatisfy { $0.habit == nil })
        }
    }

    func testHabitsGiveWayToTheScatterAndTheTiptoe() {
        for kind in [HabitKind.sniff, .circle, .lookAround] {
            let world = habitWorld(seed: 6)
            world.tuning.forceHabit = kind
            world.tuning.habitShare = 0.3
            hold(world, angle: 8, seconds: 20)
            clearsAfterSnap(world)
            XCTAssertTrue(world.bugs.allSatisfy { $0.habit == nil }, "\(kind)")
        }
        let world = habitWorld(seed: 7, season: .summer)
        world.tuning.forceHabit = .loop
        world.tuning.habitShare = 0.3
        world.tuning.playEnabled = false
        hold(world, angle: 10, seconds: 20)
        drive(world, seconds: 14, angle: ramp(from: 10, to: 110, over: 6)) { _ in
            for c in world.critters { XCTAssertEqual(c.fright, 0) }
        }
        XCTAssertTrue(world.isQuiet)
    }

    func testHabitsAreDeterministic() {
        let a = habitWorld(seed: 17, season: .summer), b = habitWorld(seed: 17, season: .summer)
        var t = 0.0
        while t < 40 {
            t += dt
            a.step(dt: dt, lidAngle: 8)
            b.step(dt: dt, lidAngle: 8)
            XCTAssertEqual(signature(a), signature(b))
        }
        XCTAssertEqual(a.habitCounts, b.habitCounts)
    }
}
