import XCTest
import CoreGraphics
@testable import ScuttleCore

final class WeatherTests: XCTestCase {
    let screen = CGSize(width: 1512, height: 982)
    let dt = 1.0 / 60.0

    func makeWorld(season: Season = .summer, weather: Weather? = nil, night: Bool = false, seed: UInt64 = 1, population: Int = 24) -> World {
        let world = World(size: screen, config: WorldConfig(population: population, season: season, seed: seed, weather: weather, night: night))
        world.tuning.forceStraggler = false
        world.tuning.forceRare = false
        world.tuning.growthSeconds = 0
        world.tuning.catchEnabled = false
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

    func tally(_ world: World) -> [Species: Int] {
        var out: [Species: Int] = [:]
        for c in world.critters { out[c.species, default: 0] += 1 }
        return out
    }

    func testNoWeatherMeansOnlyTheSeasonCast() {
        let world = makeWorld()
        XCTAssertTrue(world.bugs.allSatisfy { !$0.guest })
        XCTAssertTrue(world.bugs.allSatisfy { Season.summer.cast.contains($0.species) })
    }

    func testRainBringsAQuarterAsGuests() {
        let world = makeWorld(weather: .rain)
        hold(world, angle: 5, seconds: 14)
        XCTAssertEqual(world.critters.count, 24)
        let counts = tally(world)
        let guests = (counts[.frog] ?? 0) + (counts[.cloud] ?? 0)
        XCTAssertEqual(guests, 6)
        XCTAssertGreaterThan(counts[.frog] ?? 0, 0)
        XCTAssertGreaterThan(counts[.cloud] ?? 0, 0)
        let cast = world.critters.filter { Season.summer.cast.contains($0.species) }.count
        XCTAssertEqual(cast, 18)
        hold(world, angle: 112, seconds: 4)
        XCTAssertTrue(world.isQuiet)
    }

    func testGuestShareRoundingAndMinimum() {
        let expected: [(Int, Int)] = [(0, 0), (1, 0), (4, 1), (5, 1), (8, 2), (10, 3), (24, 6), (40, 10), (120, 30)]
        for (population, guests) in expected {
            let world = makeWorld(weather: .storm, population: population)
            XCTAssertEqual(world.bugs.count, population)
            XCTAssertEqual(world.bugs.filter(\.guest).count, guests, "population \(population)")
        }
        let tuned = makeWorld(weather: .storm)
        tuned.tuning.weatherGuestShare = 0.5
        tuned.config.population = 30
        tuned.step(dt: dt, lidAngle: 110)
        XCTAssertEqual(tuned.bugs.filter { !$0.retiring && $0.guest }.count, 15)
        XCTAssertEqual(tuned.bugs.filter { !$0.retiring }.count, 30)
    }

    func testGuestsAreSpreadThroughTheSpawnOrder() {
        let world = makeWorld(weather: .fog, population: 24)
        let guestIDs = world.bugs.filter(\.guest).map(\.id)
        XCTAssertEqual(guestIDs.count, 6)
        XCTAssertLessThan(guestIDs.first ?? 99, 4)
        XCTAssertGreaterThan(guestIDs.last ?? 0, 16)
        XCTAssertTrue(world.bugs.filter(\.guest).allSatisfy { $0.species == .cloud })
    }

    func testGuestsAlreadyInTheCastAreFine() {
        let world = makeWorld(season: .winter, weather: .snow)
        hold(world, angle: 5, seconds: 14)
        XCTAssertEqual(world.critters.count, 24)
        XCTAssertTrue(world.critters.allSatisfy { Season.winter.cast.contains($0.species) })
        XCTAssertEqual(world.bugs.filter(\.guest).count, 6)
        XCTAssertTrue(world.bugs.filter(\.guest).allSatisfy { $0.species == .snowflake })
    }

    func testNightWithoutWeatherBringsOwls() {
        let world = makeWorld(night: true)
        hold(world, angle: 5, seconds: 14)
        XCTAssertEqual(tally(world)[.owl], 6)
        XCTAssertEqual(world.critters.count, 24)
        let clearNight = makeWorld(weather: .clear, night: true)
        XCTAssertTrue(clearNight.bugs.filter(\.guest).allSatisfy { $0.species == .owl })
        let clearDay = makeWorld(weather: .clear)
        XCTAssertTrue(clearDay.bugs.filter(\.guest).allSatisfy { $0.species == .sun })
        let rainyNight = makeWorld(weather: .rain, night: true, population: 80)
        XCTAssertEqual(Set(rainyNight.bugs.filter(\.guest).map(\.species)), [.frog, .cloud, .owl])
    }

    func testChangingWeatherRetiresOldGuestsAndBringsNewOnes() {
        let world = makeWorld(weather: .rain, seed: 3)
        hold(world, angle: 5, seconds: 14)
        let oldIDs = Set(world.critters.filter { $0.species == .frog || $0.species == .cloud }.map(\.id))
        XCTAssertEqual(oldIDs.count, 6)
        let castIDs = Set(world.critters.filter { Season.summer.cast.contains($0.species) }.map(\.id))
        world.config.weather = .wind
        var oldFled = false
        hold(world, angle: 5, seconds: 20) {
            for c in world.critters where c.species == .frog || c.species == .cloud {
                XCTAssertTrue(oldIDs.contains(c.id))
                if c.mode == .fleeing { oldFled = true }
            }
        }
        XCTAssertTrue(oldFled)
        XCTAssertEqual(world.critters.count, 24)
        XCTAssertEqual(tally(world)[.leaf], 6)
        XCTAssertTrue(castIDs.isSubset(of: Set(world.critters.map(\.id))))
        XCTAssertEqual(world.hiddenCount, 0)

        world.config.weather = nil
        hold(world, angle: 5, seconds: 20)
        XCTAssertEqual(world.critters.count, 24)
        XCTAssertTrue(world.critters.allSatisfy { Season.summer.cast.contains($0.species) })

        world.config.night = true
        hold(world, angle: 5, seconds: 20)
        XCTAssertEqual(tally(world)[.owl], 6)
        XCTAssertEqual(world.critters.count, 24)
        hold(world, angle: 112, seconds: 4)
        XCTAssertTrue(world.isQuiet)
    }

    func testWeatherChangeInTheLightSwapsQuietly() {
        let world = makeWorld(weather: .cloudy)
        world.config.weather = .wind
        world.step(dt: dt, lidAngle: 110)
        XCTAssertEqual(world.bugs.count, 24)
        let guests = world.bugs.filter(\.guest)
        XCTAssertEqual(guests.count, 6)
        XCTAssertTrue(guests.allSatisfy { $0.species == .leaf })
        XCTAssertTrue(world.critters.isEmpty)
        XCTAssertTrue(world.drainEvents().isEmpty)
    }

    func testSeasonChangeKeepsValidGuests() {
        let world = makeWorld(season: .summer, weather: .fog)
        hold(world, angle: 5, seconds: 14)
        let clouds = Set(world.critters.filter { $0.species == .cloud }.map(\.id))
        world.config.season = .autumn
        hold(world, angle: 5, seconds: 20)
        XCTAssertEqual(Set(world.critters.filter { $0.species == .cloud }.map(\.id)), clouds)
        XCTAssertEqual(world.critters.count, 24)
        XCTAssertTrue(world.critters.allSatisfy { $0.species == .cloud || Season.autumn.cast.contains($0.species) })
    }

    func testDeterministicForSeedAndConfig() {
        let a = makeWorld(weather: .rain, night: true, seed: 12)
        let b = makeWorld(weather: .rain, night: true, seed: 12)
        let c = makeWorld(weather: .snow, night: true, seed: 12)
        XCTAssertEqual(a.bugs.map(\.species), b.bugs.map(\.species))
        XCTAssertNotEqual(a.bugs.map(\.species), c.bugs.map(\.species))
        var t = 0.0
        while t < 16 {
            t += dt
            a.step(dt: dt, lidAngle: t < 14 ? 5 : 112)
            b.step(dt: dt, lidAngle: t < 14 ? 5 : 112)
            XCTAssertEqual(a.critters.map(\.id), b.critters.map(\.id))
            XCTAssertEqual(a.critters.map { Double($0.position.x) }, b.critters.map { Double($0.position.x) })
        }
        XCTAssertEqual(a.drainEvents(), b.drainEvents())
    }
}
