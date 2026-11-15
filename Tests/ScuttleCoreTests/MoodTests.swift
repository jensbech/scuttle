import XCTest
import CoreGraphics
@testable import ScuttleCore

final class MoodTests: BehaviourCase {
    func quiet(_ world: World) {
        world.tuning.forceRipple = false
        world.tuning.forceGreeting = false
        world.tuning.sleepEnabled = false
    }

    func testDeepDarkBringsOccasionalPlay() {
        var dancers = Set<Int>()
        var cheerers = Set<Int>()
        for seed in [1, 2, 3] as [UInt64] {
            let world = makeWorld(seed: seed, season: .christmas)
            quiet(world)
            var most = 0
            var early = 0
            hold(world, angle: 5, seconds: 60) { t in
                let playing = world.critters.filter { $0.gesture == .dance || $0.gesture == .cheer }
                if t < world.tuning.playAfter { early += playing.count }
                most = max(most, playing.count)
                for c in playing {
                    if c.gesture == .dance { dancers.insert(c.id) } else { cheerers.insert(c.id) }
                    XCTAssertEqual(c.mode, .resting)
                    if c.gestureTime > 0.5 && !c.species.isAirborne { XCTAssertLessThan(c.speed, 1) }
                }
            }
            XCTAssertEqual(early, 0, "seed \(seed)")
            XCTAssertGreaterThan(most, 0, "seed \(seed)")
            XCTAssertLessThanOrEqual(most, max(1, Int(24 * world.tuning.playShare)) + 1, "seed \(seed)")
        }
        XCTAssertGreaterThan(dancers.count, 2)
        XCTAssertGreaterThan(cheerers.count, 2)
    }

    func testNoPlayOrSleepOutsideDeepDark() {
        let world = makeWorld(seed: 4, season: .christmas)
        world.tuning.sleepAfter = 5
        world.tuning.forceRipple = true
        world.tuning.rippleAfter = 0
        hold(world, angle: 25, seconds: 60) { _ in
            for c in world.critters {
                XCTAssertFalse(c.gesture == .dance || c.gesture == .sleep || c.gesture == .cheer, "\(c.gesture)")
            }
        }
        XCTAssertEqual(world.mood, .dark)
    }

    func testStadiumRippleSweepsAcrossTheScreen() {
        for seed in [1, 2] as [UInt64] {
            let world = makeWorld(seed: seed, season: .christmas, population: 30)
            quiet(world)
            world.tuning.playEnabled = true
            world.tuning.playChance = 0
            world.tuning.forceRipple = true
            world.tuning.rippleAfter = 10
            var start: [Int: (t: Double, x: Double)] = [:]
            hold(world, angle: 5, seconds: 18) { t in
                for c in world.critters where c.gesture == .cheer && start[c.id] == nil {
                    start[c.id] = (t, Double(c.position.x))
                }
            }
            XCTAssertGreaterThan(start.count, 15, "seed \(seed)")
            let pts = start.values.map { ($0.x, $0.t) }
            let mx = pts.map(\.0).reduce(0, +) / Double(pts.count)
            let mt = pts.map(\.1).reduce(0, +) / Double(pts.count)
            var sxy = 0.0, sxx = 0.0, syy = 0.0
            for (x, t) in pts {
                sxy += (x - mx) * (t - mt)
                sxx += (x - mx) * (x - mx)
                syy += (t - mt) * (t - mt)
            }
            let r = sxy / max(1e-9, (sxx * syy).squareRoot())
            XCTAssertGreaterThan(abs(r), 0.8, "seed \(seed) r \(r)")
            let times = start.values.map(\.t)
            XCTAssertLessThan((times.max() ?? 0) - (times.min() ?? 0), world.tuning.rippleSpan + 0.6)
        }
    }

    func testTheySleepAfterALongWhileAndWakeWhenTheLidLifts() {
        let world = makeWorld(seed: 5, season: .autumn)
        quiet(world)
        world.tuning.sleepEnabled = true
        world.tuning.playChance = 0
        world.tuning.sleepAfter = 12
        world.tuning.sleepRamp = 10
        var sleptEarly = false
        var most = 0
        hold(world, angle: 4, seconds: 40) { t in
            let n = self.count(world, .sleep)
            if t < 12 && n > 0 { sleptEarly = true }
            most = max(most, n)
            for c in world.critters where c.gesture == .sleep {
                XCTAssertEqual(c.mode, .resting)
                XCTAssertTrue(!c.species.isAirborne || c.species.locomotion == .float)
            }
        }
        XCTAssertFalse(sleptEarly)
        XCTAssertGreaterThan(most, 4)
        XCTAssertLessThanOrEqual(most, Int((Double(world.critters.count) * world.tuning.sleepShare).rounded(.up)))
        let before = world.critters.count
        var woke = false
        hold(world, angle: 17, seconds: 3) { _ in
            if self.count(world, .look) > 0 { woke = true }
        }
        XCTAssertTrue(woke)
        XCTAssertEqual(count(world, .sleep), 0)
        XCTAssertEqual(world.critters.count, before)
    }

    func testSleepersStillScatterInTime() {
        let world = makeWorld(seed: 7, season: .autumn)
        world.tuning.sleepAfter = 4
        world.tuning.sleepRamp = 2
        hold(world, angle: 4, seconds: 20)
        XCTAssertGreaterThan(count(world, .sleep), 3)
        let out = world.critters.count
        var frozen = 0
        var gone: Double?
        hold(world, angle: 115, seconds: 7) { t in
            if abs(t - 0.6) < self.dt / 2 { frozen = world.critters.filter { $0.mode == .startled && $0.fright > 0 }.count }
            if gone == nil && world.critters.isEmpty { gone = t }
        }
        XCTAssertGreaterThanOrEqual(frozen, out - 2)
        XCTAssertLessThanOrEqual(gone ?? 99, 4.6)
        XCTAssertTrue(world.isQuiet)
    }

    func testSomeoneGreetsTheViewerFromTheMiddle() {
        for seed in [1, 2, 3] as [UInt64] {
            let world = makeWorld(seed: seed, season: .christmas)
            quiet(world)
            world.tuning.playEnabled = false
            world.tuning.forceGreeting = true
            world.tuning.greetCooldown = 6...6
            var greeters = Set<Int>()
            var most = 0
            hold(world, angle: 20, seconds: 40) { _ in
                let waving = world.critters.filter { $0.gesture == .wave }
                most = max(most, waving.count)
                for c in waving {
                    greeters.insert(c.id)
                    XCTAssertGreaterThan(self.edgeDistance(c), min(Double(self.screen.width), Double(self.screen.height)) * world.tuning.greetCentre - 30)
                    XCTAssertEqual(c.species.stance, .upright)
                    if c.gestureTime > 0.4 { XCTAssertLessThan(c.speed, 1) }
                }
            }
            XCTAssertGreaterThanOrEqual(greeters.count, 2, "seed \(seed)")
            XCTAssertEqual(most, 1, "seed \(seed)")
        }
        let world = makeWorld(seed: 1, season: .christmas)
        quiet(world)
        world.tuning.playEnabled = false
        hold(world, angle: 20, seconds: 40) { _ in
            XCTAssertEqual(self.count(world, .wave), 0)
        }
    }

    func testNaturalGreetingsAreRare() {
        var greetings = 0
        for seed in 1...6 as ClosedRange<UInt64> {
            let world = makeWorld(seed: seed, season: .christmas)
            world.tuning.playEnabled = false
            var waving = Set<Int>()
            var was = false
            hold(world, angle: 20, seconds: 120) { _ in
                let now = self.count(world, .wave) > 0
                if now && !was { greetings += 1 }
                was = now
                for c in world.critters where c.gesture == .wave { waving.insert(c.id) }
            }
        }
        XCTAssertGreaterThan(greetings, 3)
        XCTAssertLessThan(greetings, 40)
    }

    func testDuskMakesThemWatchfulAndHugTheEdges() {
        func run(_ dusk: Bool, seed: UInt64) -> (looks: Int, mean: Double) {
            let world = makeWorld(seed: seed, population: 40)
            if !dusk {
                world.tuning.duskLookChance = 0
                world.tuning.duskHug = 1
                world.tuning.duskReach = 1
            }
            hold(world, angle: 10, seconds: 12)
            var looks = 0
            var total = 0.0
            var n = 0
            hold(world, angle: 48, seconds: 30) { t in
                looks += world.critters.filter { $0.gesture == .look && $0.mode == .resting }.count
                if t > 15 {
                    for c in world.critters where self.onScreen(c) {
                        total += self.edgeDistance(c)
                        n += 1
                    }
                }
            }
            return (looks, total / Double(max(1, n)))
        }
        var watchfulMean = 0.0
        var plainMean = 0.0
        for seed in [8, 9, 10, 11, 12] as [UInt64] {
            let watchful = run(true, seed: seed)
            let plain = run(false, seed: seed)
            XCTAssertGreaterThan(watchful.looks, 200)
            XCTAssertEqual(plain.looks, 0)
            watchfulMean += watchful.mean
            plainMean += plain.mean
        }
        XCTAssertLessThan(watchfulMean, plainMean * 0.92)
    }
}
