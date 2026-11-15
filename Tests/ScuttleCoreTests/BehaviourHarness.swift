import XCTest
import CoreGraphics
@testable import ScuttleCore

class BehaviourCase: XCTestCase {
    let screen = CGSize(width: 1512, height: 982)
    let dt = 1.0 / 60.0

    func makeWorld(seed: UInt64 = 1, season: Season = .autumn, population: Int = 24, growth: Bool = false, fright: Bool = true, work: Bool = false) -> World {
        let world = World(size: screen, config: WorldConfig(population: population, season: season, seed: seed))
        world.tuning.workEnabled = work
        world.tuning.forceRare = false
        world.tuning.forceStraggler = false
        if !growth { world.tuning.growthSeconds = 0 }
        if !fright { world.tuning.catchEnabled = false }
        return world
    }

    func hold(_ world: World, angle: Double, seconds: Double, each: ((Double) -> Void)? = nil) {
        var t = 0.0
        while t < seconds - 1e-9 {
            t += dt
            world.step(dt: dt, lidAngle: angle)
            each?(t)
        }
    }

    func drive(_ world: World, seconds: Double, angle: (Double) -> Double, each: ((Double) -> Void)? = nil) {
        var t = 0.0
        while t < seconds - 1e-9 {
            t += dt
            world.step(dt: dt, lidAngle: angle(t))
            each?(t)
        }
    }

    func ramp(from a: Double, to b: Double, over seconds: Double) -> (Double) -> Double {
        { t in a + (b - a) * min(1, max(0, t / max(1e-6, seconds))) }
    }

    func edgeDistance(_ c: Critter) -> Double {
        let x = Double(c.position.x), y = Double(c.position.y)
        return min(min(x, Double(screen.width) - x), min(y, Double(screen.height) - y))
    }

    func onScreen(_ c: Critter) -> Bool {
        let x = Double(c.position.x), y = Double(c.position.y)
        return x >= 0 && y >= 0 && x <= Double(screen.width) && y <= Double(screen.height)
    }

    func gestures(_ world: World) -> Set<Gesture> {
        Set(world.critters.map(\.gesture))
    }

    func count(_ world: World, _ g: Gesture) -> Int {
        world.critters.filter { $0.gesture == g }.count
    }

    func signature(_ world: World) -> [Double] {
        var out: [Double] = [world.light, world.lightRate, world.activity]
        for c in world.critters {
            out += [Double(c.id), Double(c.position.x), Double(c.position.y), c.heading, c.speed, c.alpha, c.facing, c.lift, c.gestureTime, Double(Gesture.allCases.firstIndex(of: c.gesture) ?? -1)]
        }
        return out
    }

    func clearsAfterSnap(_ world: World, within limit: Double = 4.6, file: StaticString = #filePath, line: UInt = #line) {
        var gone: Double?
        hold(world, angle: 115, seconds: limit + 2) { t in
            if gone == nil && world.critters.isEmpty { gone = t }
        }
        XCTAssertNotNil(gone, file: file, line: line)
        XCTAssertLessThanOrEqual(gone ?? 99, limit, file: file, line: line)
        XCTAssertTrue(world.isQuiet, file: file, line: line)
    }
}
