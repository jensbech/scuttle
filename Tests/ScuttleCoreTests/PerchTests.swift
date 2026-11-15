import XCTest
import CoreGraphics
@testable import ScuttleCore

final class PerchTests: BehaviourCase {
    let windows = [
        CGRect(x: 120, y: 260, width: 560, height: 360),
        CGRect(x: 820, y: 180, width: 520, height: 520),
        CGRect(x: 420, y: 520, width: 380, height: 200),
    ]
    let dock = CGRect(x: 380, y: 0, width: 760, height: 70)

    func perchWorld(seed: UInt64 = 2, season: Season = .winter, population: Int = 30, ledges: [CGRect]? = nil) -> World {
        let world = makeWorld(seed: seed, season: season, population: population)
        world.tuning.socialEnabled = false
        world.tuning.habitsEnabled = false
        world.tuning.forceGreeting = false
        world.surroundings = Surroundings(ledges: ledges ?? windows)
        return world
    }

    func settled(_ world: World) -> [Bug] {
        world.bugs.filter { b in
            guard b.mode != .hidden, let p = b.perch else { return false }
            return p.phase == .sit || p.phase == .look
        }
    }

    func testPerchersSitOnWindowTopsSpacedAndNeverStacked() {
        var sat = 0
        var perchGestures = 0
        var kinds = Set<Species>()
        for (season, seed) in [(Season.winter, 1), (.summer, 2), (.halloween, 3), (.spring, 4)] as [(Season, UInt64)] {
            let world = perchWorld(seed: seed, season: season)
            hold(world, angle: 8, seconds: 60) { _ in
                let cap = min(world.tuning.perchMax, max(1, Int(Double(world.critters.count) * world.tuning.perchShare)))
                XCTAssertLessThanOrEqual(world.percherCount, cap + 1)
                let on = self.settled(world)
                for b in on {
                    sat += 1
                    kinds.insert(b.species)
                    let top = b.perch!.top
                    XCTAssertTrue(self.windows.contains { abs(Double($0.maxY) - top) < 0.5 }, "\(b.species)")
                    if abs(b.y - (top + 0.46 * b.size)) > 0.5 {
                        XCTFail("feet \(b.species) \(b.y) vs \(top + 0.46 * b.size)")
                    }
                    if b.gesture == .perch { perchGestures += 1 }
                    XCTAssertEqual(b.speed, 0)
                }
                for i in on.indices {
                    for j in on.indices where j > i {
                        let a = on[i], c = on[j]
                        guard abs(a.perch!.top - c.perch!.top) < 1 else { continue }
                        XCTAssertGreaterThan(abs(a.x - c.x), (a.size + c.size) * 0.45, "\(a.species) \(c.species) stacked")
                    }
                }
            }
        }
        XCTAssertGreaterThan(sat, 2000)
        XCTAssertGreaterThan(perchGestures, 1000)
        XCTAssertGreaterThanOrEqual(kinds.count, 4, "\(kinds)")
    }

    func testOnlySpeciesWithAPerchingSenseClimbUp() {
        let world = perchWorld(seed: 5, season: .christmas)
        hold(world, angle: 8, seconds: 40) { _ in
            XCTAssertEqual(world.percherCount, 0)
        }
        let autumn = perchWorld(seed: 5, season: .autumn)
        hold(autumn, angle: 8, seconds: 60) { _ in
            for b in autumn.bugs where b.perch != nil { XCTAssertEqual(b.species, .leaf) }
        }
    }

    func testNoPerchingWithoutLedgesOrWhenSwitchedOff() {
        let bare = perchWorld(seed: 1, ledges: [])
        bare.tuning.forcePerch = true
        let off = perchWorld(seed: 1)
        off.tuning.perchEnabled = false
        hold(bare, angle: 8, seconds: 40) { _ in
            XCTAssertTrue(bare.bugs.allSatisfy { $0.perch == nil })
            XCTAssertFalse(bare.critters.contains { $0.gesture == .perch })
        }
        hold(off, angle: 8, seconds: 40) { _ in
            XCTAssertTrue(off.bugs.allSatisfy { $0.perch == nil })
        }
    }

    func testEmptySurroundingsMatchTheFeatureSwitchedOff() {
        let a = makeWorld(seed: 8, season: .winter), b = makeWorld(seed: 8, season: .winter)
        b.tuning.perchEnabled = false
        b.tuning.pointerEnabled = false
        var t = 0.0
        while t < 40 {
            t += dt
            a.step(dt: dt, lidAngle: 8)
            b.step(dt: dt, lidAngle: 8)
            XCTAssertEqual(signature(a), signature(b))
        }
    }

    func testPerchersLookAroundShuffleAndHop() {
        var looks = 0
        var shuffles = 0
        var jumps = 0
        var leaves = 0
        for seed in [1, 2, 3] as [UInt64] {
            let world = perchWorld(seed: seed, season: .winter)
            world.tuning.forcePerch = true
            world.tuning.perchStay = 12...16
            var was: [Int: PerchPhase] = [:]
            hold(world, angle: 8, seconds: 60) { _ in
                var now: [Int: PerchPhase] = [:]
                for b in world.bugs where b.mode != .hidden {
                    guard let p = b.perch else { continue }
                    now[b.id] = p.phase
                    if was[b.id] != p.phase {
                        switch p.phase {
                        case .look: looks += 1
                        case .shuffle: shuffles += 1
                        case .jump: jumps += 1
                        default: break
                        }
                    }
                }
                for id in was.keys where now[id] == nil { leaves += 1 }
                was = now
            }
        }
        XCTAssertGreaterThan(looks, 5)
        XCTAssertGreaterThan(shuffles, 10)
        XCTAssertGreaterThan(jumps, 2)
        XCTAssertGreaterThan(leaves, 6)
    }

    func testPerchersRideAMovingLedge() {
        let world = perchWorld(seed: 1, season: .winter)
        world.tuning.forcePerch = true
        world.tuning.perchStay = 40...50
        hold(world, angle: 8, seconds: 30)
        var before: [Int: (Double, Double)] = [:]
        for b in settled(world) { before[b.id] = (b.x, b.perch!.top) }
        XCTAssertFalse(before.isEmpty)
        var t = 0.0
        while t < 2 - 1e-9 {
            t += dt
            let moved = windows.map { r -> CGRect in
                var m = r
                m.origin.x += CGFloat(40 * t)
                m.origin.y -= CGFloat(60 * t)
                return m
            }
            world.surroundings = Surroundings(ledges: moved)
            world.step(dt: dt, lidAngle: 8)
        }
        hold(world, angle: 8, seconds: 1)
        var kept = 0
        for b in world.bugs where b.mode != .hidden {
            guard let was = before[b.id], let p = b.perch, p.phase == .sit || p.phase == .look else { continue }
            kept += 1
            XCTAssertEqual(p.top, was.1 - 120, accuracy: 0.5)
            XCTAssertEqual(b.y, was.1 - 120 + 0.46 * b.size, accuracy: 0.5)
            XCTAssertGreaterThan(b.x, was.0 + 40)
        }
        XCTAssertGreaterThan(kept, 0)
    }

    func testVanishingLedgeSendsEveryoneOffCleanly() {
        for season in [Season.winter, .summer, .spring] {
            let world = perchWorld(seed: 3, season: season)
            world.tuning.forcePerch = true
            world.tuning.perchStay = 40...50
            world.tuning.socialEnabled = true
            world.tuning.socialAfter = 999
            hold(world, angle: 8, seconds: 25)
            XCTAssertGreaterThan(world.percherCount, 0, "\(season)")
            var tumbles = 0
            world.surroundings = Surroundings()
            hold(world, angle: 8, seconds: 3) { _ in
                tumbles += world.critters.filter { $0.gesture == .tumble }.count
                for c in world.critters {
                    XCTAssertEqual(c.fright, 0)
                    XCTAssertNotEqual(c.mode, .fleeing)
                }
            }
            XCTAssertEqual(world.percherCount, 0, "\(season)")
            XCTAssertTrue(world.bugs.allSatisfy { !$0.pinned }, "\(season)")
            XCTAssertFalse(world.critters.contains { $0.gesture == .perch })
            if season != .summer { XCTAssertGreaterThan(tumbles, 0, "\(season)") }
        }
    }

    func testShrinkingLedgePushesSittersInOrOff() {
        let world = perchWorld(seed: 4, season: .winter)
        world.tuning.forcePerch = true
        world.tuning.perchStay = 40...50
        hold(world, angle: 8, seconds: 30)
        XCTAssertGreaterThan(world.percherCount, 0)
        let shrunk = windows.map { r -> CGRect in
            var m = r
            m.origin.x += 150
            m.size.width = 160
            return m
        }
        world.surroundings = Surroundings(ledges: shrunk)
        hold(world, angle: 8, seconds: 6)
        for b in settled(world) {
            XCTAssertTrue(shrunk.contains { abs(Double($0.maxY) - b.perch!.top) < 0.5 && b.x >= Double($0.minX) - 1 && b.x <= Double($0.maxX) + 1 })
        }
    }

    func testOneDockDwellerAtMost() {
        var docked = 0
        for seed in [1, 2, 3, 4, 5] as [UInt64] {
            let world = perchWorld(seed: seed, season: .christmas, ledges: [dock])
            world.tuning.forcePerch = true
            world.tuning.perchShare = 0.5
            world.tuning.perchMax = 6
            hold(world, angle: 8, seconds: 40) { _ in
                let on = world.bugs.filter { $0.mode != .hidden && $0.perch?.dock == true }
                XCTAssertLessThanOrEqual(on.count, world.tuning.dockMax)
                for b in on where b.perch?.phase == .sit || b.perch?.phase == .look {
                    docked += 1
                    XCTAssertEqual(b.y, Double(self.dock.maxY) + 0.46 * b.size, accuracy: 0.5)
                }
            }
        }
        XCTAssertGreaterThan(docked, 200)
    }

    func testPointerSpooksPerchersWithoutAScatter() {
        let world = perchWorld(seed: 2, season: .winter)
        world.tuning.forcePerch = true
        world.tuning.perchStay = 40...50
        hold(world, angle: 8, seconds: 25)
        let sitters = settled(world)
        XCTAssertFalse(sitters.isEmpty)
        let before = world.critters.count
        _ = world.drainEvents()
        let target = sitters[0]
        var t = 0.0
        while t < 0.6 {
            t += dt
            let x = target.x - 300 + 1000 * t
            world.surroundings = Surroundings(pointer: CGPoint(x: x, y: target.y), pointerSpeed: 1000, ledges: windows)
            world.step(dt: dt, lidAngle: 8)
        }
        XCTAssertNotEqual(world.bugs.first { $0.id == target.id }?.perch?.phase, .sit)
        world.surroundings = Surroundings(ledges: windows)
        hold(world, angle: 8, seconds: 3) { _ in
            for c in world.critters { XCTAssertEqual(c.fright, 0) }
        }
        XCTAssertEqual(world.critters.count, before)
        XCTAssertFalse(world.drainEvents().contains { if case .scatter = $0 { return true } else { return false } })
    }

    func testSnapOpenClearsPerchersInTime() {
        for (season, seed) in [(Season.winter, 1), (.summer, 2), (.halloween, 3), (.christmas, 4)] as [(Season, UInt64)] {
            let world = perchWorld(seed: seed, season: season, ledges: windows + [dock])
            world.tuning.forcePerch = true
            hold(world, angle: 8, seconds: 30)
            XCTAssertGreaterThan(world.percherCount, 0, "\(season)")
            clearsAfterSnap(world)
            XCTAssertTrue(world.bugs.allSatisfy { $0.perch == nil && !$0.pinned }, "\(season)")
        }
    }

    func testGentleOpeningTiptoesPerchersAway() {
        let world = perchWorld(seed: 1, season: .winter)
        world.tuning.forcePerch = true
        world.tuning.playEnabled = false
        hold(world, angle: 10, seconds: 30)
        XCTAssertGreaterThan(world.percherCount, 0)
        drive(world, seconds: 14, angle: ramp(from: 10, to: 110, over: 6)) { _ in
            for c in world.critters {
                XCTAssertEqual(c.fright, 0)
                XCTAssertNotEqual(c.mode, .startled)
            }
        }
        XCTAssertTrue(world.isQuiet)
    }

    func testFailsafeClearsPerchersWhenTheyCannotRun() {
        let world = perchWorld(seed: 2, season: .winter)
        world.tuning.forcePerch = true
        hold(world, angle: 8, seconds: 30)
        XCTAssertGreaterThan(world.percherCount, 0)
        world.tuning.fleeSpeedRange = 1...2
        world.tuning.fleeSpeedCap = 2
        var lastSeen = 0.0
        hold(world, angle: 110, seconds: 12) { t in
            if !world.critters.isEmpty { lastSeen = t }
        }
        XCTAssertTrue(world.isQuiet)
        XCTAssertLessThan(lastSeen, world.tuning.failsafeSeconds + world.tuning.failsafeGrace + 1.5)
        XCTAssertTrue(world.bugs.allSatisfy { !$0.scripted && !$0.pinned })
    }

    func testDuskOnlyPerchesNearTheEdge() {
        let world = perchWorld(seed: 3, season: .winter)
        world.tuning.forcePerch = true
        hold(world, angle: 8, seconds: 10)
        hold(world, angle: 48, seconds: 10)
        hold(world, angle: 48, seconds: 30) { _ in
            for b in world.bugs where b.mode != .hidden && b.perch?.phase == .travel {
                XCTAssertLessThan(world.edgeDistance(b.perch!.x, b.perch!.top + 0.46 * b.size), 180.5)
            }
        }
    }

    func testPerchingIsDeterministic() {
        let a = perchWorld(seed: 13, season: .summer), b = perchWorld(seed: 13, season: .summer)
        var t = 0.0
        while t < 50 {
            t += dt
            var r = windows[0]
            if t > 30 { r.origin.y += CGFloat(min(80, (t - 30) * 30)) }
            let s = Surroundings(ledges: [r, windows[1], windows[2]])
            a.surroundings = s
            b.surroundings = s
            a.step(dt: dt, lidAngle: 8)
            b.step(dt: dt, lidAngle: 8)
            XCTAssertEqual(signature(a), signature(b))
        }
    }

    func testEverythingOnStaysCheapAtFourHundredFigures() {
        func cost(rich: Bool) -> (count: Int, perStep: Double) {
            let world = makeWorld(seed: 2, season: .winter, population: 400)
            world.tuning.socialEnabled = rich
            world.tuning.habitsEnabled = rich
            world.tuning.perchEnabled = rich
            world.tuning.pointerEnabled = rich
            world.surroundings = Surroundings(pointer: CGPoint(x: 700, y: 450), pointerSpeed: 0, ledges: windows + [dock])
            hold(world, angle: 5, seconds: 30)
            var t = 0.0
            let start = Date()
            for i in 0..<300 {
                t += dt
                let moving = i > 100 && i < 200
                let x = moving ? 700 + 300 * sin(t * 3) : 700
                world.surroundings = Surroundings(pointer: CGPoint(x: x, y: 450), pointerSpeed: moving ? 600 : 0, ledges: windows + [dock])
                world.step(dt: dt, lidAngle: 5)
            }
            return (world.critters.count, Date().timeIntervalSince(start) / 300)
        }
        let plain = cost(rich: false)
        let rich = cost(rich: true)
        XCTAssertGreaterThan(rich.count, 300)
        XCTAssertLessThan(rich.perStep, plain.perStep * 1.35 + 0.0008)
        print("step cost 400 with everything \(rich.count) figures: \(String(format: "%.3f", rich.perStep * 1000)) ms, without \(String(format: "%.3f", plain.perStep * 1000)) ms")
    }
}
