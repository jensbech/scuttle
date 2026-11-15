import XCTest
import CoreGraphics
@testable import ScuttleCore

final class EntranceTests: BehaviourCase {
    struct Track {
        var points: [(t: Double, c: Critter)] = []
        var gestures: [Gesture] { points.map(\.c.gesture) }
        var sequence: [Gesture] {
            var out: [Gesture] = []
            for g in gestures where out.last != g { out.append(g) }
            return out
        }
    }

    func forced(_ style: EntranceStyle, season: Season = .christmas, seed: UInt64 = 4, population: Int = 8) -> World {
        let world = makeWorld(seed: seed, season: season, population: population)
        world.tuning.forceEntrance = style
        world.tuning.playEnabled = false
        world.tuning.slamBurst = 0
        return world
    }

    func tracks(_ world: World, seconds: Double, angle: Double = 10) -> [Int: Track] {
        var out: [Int: Track] = [:]
        hold(world, angle: angle, seconds: seconds) { t in
            for c in world.critters { out[c.id, default: Track()].points.append((t, c)) }
        }
        return out
    }

    func testPopUpRisesFromTheBottomLikeAMole() {
        let world = forced(.popUp)
        let all = tracks(world, seconds: 10)
        XCTAssertEqual(all.count, 8)
        var moles = 0
        for (id, tr) in all {
            guard let first = tr.points.first else { continue }
            XCTAssertLessThan(Double(first.c.position.y), 0, "id \(id)")
            XCTAssertEqual(tr.sequence.first, .popUp, "id \(id)")
            XCTAssertTrue(tr.sequence.contains(.look), "id \(id)")
            let rise = tr.points.first { $0.c.position.y > 0 }
            XCTAssertNotNil(rise)
            XCTAssertLessThan((rise?.t ?? 99) - first.t, 0.5, "id \(id)")
            XCTAssertTrue(tr.points.contains { $0.c.mode == .wandering }, "id \(id)")
            if tr.sequence.filter({ $0 == .popUp }).count >= 2 { moles += 1 }
        }
        XCTAssertGreaterThan(moles, 0)
        XCTAssertLessThan(moles, 8)
    }

    func testParachutersDriftDownFromTheTopAndLand() {
        let world = forced(.parachute)
        let all = tracks(world, seconds: 14)
        XCTAssertEqual(all.count, 8)
        for (id, tr) in all {
            guard let first = tr.points.first else { continue }
            XCTAssertGreaterThan(Double(first.c.position.y), Double(screen.height), "id \(id)")
            XCTAssertEqual(Array(tr.sequence.prefix(3)), [.parachute, .look, .none], "id \(id)")
            let chute = tr.points.filter { $0.c.gesture == .parachute }
            let fall = Double(chute.first!.c.position.y - chute.last!.c.position.y)
            let span = chute.last!.t - chute.first!.t
            XCTAssertGreaterThan(fall, 60, "id \(id)")
            XCTAssertLessThan(fall / max(0.1, span), 110, "id \(id)")
            XCTAssertLessThanOrEqual(span, world.tuning.parachuteMaxSeconds + 0.1, "id \(id)")
            let xs = chute.map { Double($0.c.position.x) }
            XCTAssertGreaterThan((xs.max() ?? 0) - (xs.min() ?? 0), 10, "id \(id)")
            XCTAssertTrue(tr.points.contains { $0.c.mode == .wandering }, "id \(id)")
            for p in chute { XCTAssertEqual(p.c.lift, 0) }
        }
    }

    func testFlyersSwoopInOnAnArc() {
        let world = forced(.swoop, season: .summer, population: 16)
        let all = tracks(world, seconds: 8)
        var swoops = 0
        for (_, tr) in all {
            guard let first = tr.points.first, first.c.species.locomotion != .crawl else { continue }
            let early = Array(tr.points.prefix(while: { $0.t - first.t < 0.9 }))
            guard early.count > 10 else { continue }
            let p0 = early[0].c.position, p1 = early[early.count / 2].c.position, p2 = early[early.count - 1].c.position
            let a1 = atan2(Double(p1.y - p0.y), Double(p1.x - p0.x))
            let a2 = atan2(Double(p2.y - p1.y), Double(p2.x - p1.x))
            if abs((a2 - a1).remainder(dividingBy: 2 * .pi)) > 0.25 { swoops += 1 }
            XCTAssertGreaterThan(edgeDistance(early[early.count - 1].c), 20)
        }
        XCTAssertGreaterThan(swoops, 4)
    }

    func testSlamTumblersRollInAndLookDazed() {
        let world = forced(.tumble)
        let all = tracks(world, seconds: 8)
        for (id, tr) in all {
            XCTAssertEqual(Array(tr.sequence.prefix(3)), [.tumble, .look, .none], "id \(id)")
            let fast = tr.points.prefix(10).map(\.c.speed).max() ?? 0
            XCTAssertGreaterThan(fast, 150, "id \(id)")
            for p in tr.points where p.c.gesture == .tumble { XCTAssertEqual(p.c.lift, 0, "id \(id)") }
        }
    }

    func testShyOneBacksOutAndTriesAgain() {
        let world = forced(.shy)
        let all = tracks(world, seconds: 26)
        XCTAssertEqual(all.count, 8)
        var retried = 0
        for (id, tr) in all {
            let seq = tr.sequence
            XCTAssertTrue(seq.starts(with: [.none, .look, .tiptoe, .none]), "id \(id) \(seq)")
            let back = tr.points.filter { $0.c.gesture == .tiptoe }
            XCTAssertGreaterThan(back.count, 10)
            var against = 0
            for (a, b) in zip(back, back.dropFirst()) {
                let dx = Double(b.c.position.x - a.c.position.x), dy = Double(b.c.position.y - a.c.position.y)
                if hypot(dx, dy) > 0.2 && dx * cos(b.c.heading) + dy * sin(b.c.heading) < 0 { against += 1 }
            }
            XCTAssertGreaterThan(Double(against), Double(back.count) * 0.7, "id \(id)")
            let outside = tr.points.contains { $0.t > back.last!.t && self.edgeDistance($0.c) < -5 }
            XCTAssertTrue(outside, "id \(id)")
            XCTAssertTrue(tr.points.contains { $0.t > back.last!.t && $0.c.mode == .wandering }, "id \(id)")
            if seq.filter({ $0 == .tiptoe }).count >= 2 { retried += 1 }
        }
        XCTAssertLessThan(retried, 8)
    }

    func testCongaLineFollowsTheLeader() {
        for seed in [1, 2, 3] as [UInt64] {
            let world = forced(.conga, seed: seed, population: 12)
            var members = Set<Int>()
            var spacingOK = 0
            var spacingAll = 0
            var cheered = Set<Int>()
            var most = 0
            hold(world, angle: 10, seconds: 20) { _ in
                let line = world.bugs.filter { $0.entrance?.style == .conga && $0.mode != .hidden }
                most = max(most, line.count)
                for b in line {
                    members.insert(b.id)
                    if b.gesture == .cheer { cheered.insert(b.id) }
                    XCTAssertTrue(b.gesture == .dance || b.gesture == .cheer)
                    guard let e = b.entrance, e.slot > 0, e.stage < 2, let a = world.bugs.first(where: { $0.id == e.ahead }) else { continue }
                    if b.y > 0 && a.y > 0 && b.x > 0 && b.x < Double(self.screen.width) {
                        spacingAll += 1
                        if hypot(a.x - b.x, a.y - b.y) < e.spacing * 2.2 { spacingOK += 1 }
                    }
                }
            }
            XCTAssertGreaterThanOrEqual(most, 3, "seed \(seed)")
            XCTAssertLessThanOrEqual(most, 4, "seed \(seed)")
            XCTAssertGreaterThan(spacingAll, 100, "seed \(seed)")
            XCTAssertGreaterThan(Double(spacingOK), Double(spacingAll) * 0.9, "seed \(seed)")
            XCTAssertEqual(cheered, members.intersection(cheered), "seed \(seed)")
            XCTAssertGreaterThanOrEqual(cheered.count, 2, "seed \(seed)")
            XCTAssertTrue(world.bugs.allSatisfy { $0.entrance?.style != .conga }, "seed \(seed)")
            clearsAfterSnap(world)
        }
    }

    func testCongaWaitsForTheDarkToSettleAndRespectsGrowth() {
        let world = makeWorld(seed: 3, season: .christmas, population: 24, growth: true)
        world.tuning.congaChance = 1
        world.tuning.shyChance = 0
        world.tuning.popUpChance = 0
        world.tuning.parachuteChance = 0
        var firstConga: Double?
        hold(world, angle: 5, seconds: 40) { t in
            let n = world.bugs.filter { $0.entrance?.style == .conga && $0.mode != .hidden }.count
            if n > 0 && firstConga == nil { firstConga = t }
            XCTAssertLessThanOrEqual(world.critters.count, world.emergeAllowance(members: 24) + world.tuning.congaBorrow + 1)
        }
        XCTAssertNotNil(firstConga)
        XCTAssertGreaterThanOrEqual(firstConga ?? 0, world.tuning.congaMinDark)
    }

    func testCarefulCreepersPauseLongAtTheEdge() {
        let world = forced(.careful)
        let all = tracks(world, seconds: 10)
        for (id, tr) in all {
            let paused = Double(tr.points.filter { $0.c.gesture == .peek }.count) * dt
            XCTAssertGreaterThan(paused, world.tuning.peekPause.lowerBound * world.tuning.carefulPeekScale, "id \(id)")
        }
    }

    func testNaturalMixIsVariedButMostlyPlain() {
        var firsts: [EntranceStyle: Int] = [:]
        var total = 0
        for (season, seed) in [(Season.christmas, 1), (.summer, 2), (.autumn, 3), (.halloween, 4), (.winter, 5)] as [(Season, UInt64)] {
            let world = makeWorld(seed: seed, season: season, population: 60, growth: true)
            world.tuning.playEnabled = false
            var seen = Set<Int>()
            hold(world, angle: 5, seconds: 70) { _ in
                for b in world.bugs where b.mode != .hidden && !seen.contains(b.id) {
                    seen.insert(b.id)
                    total += 1
                    firsts[b.entrance?.style ?? .creep, default: 0] += 1
                }
            }
        }
        XCTAssertGreaterThan(total, 250)
        for style in [EntranceStyle.popUp, .parachute, .swoop, .tumble, .shy, .conga] {
            XCTAssertGreaterThan(firsts[style] ?? 0, 0, "\(style) \(firsts)")
        }
        let plain = firsts[.creep] ?? 0
        XCTAssertGreaterThan(Double(plain), Double(total) * 0.55, "\(firsts)")
    }

    func testEveryEntranceAbortsCleanlyOnSnapOpen() {
        for style in EntranceStyle.allCases {
            for at in [0.4, 1.5, 3.0] {
                let world = forced(style, season: style == .swoop ? .summer : .christmas, population: 12)
                hold(world, angle: 10, seconds: at)
                clearsAfterSnap(world)
                XCTAssertTrue(world.bugs.allSatisfy { $0.entrance == nil }, "\(style) at \(at)")
            }
        }
    }

    func testEntrancesStayNearTheScreen() {
        for style in EntranceStyle.allCases {
            let world = forced(style, season: style == .swoop ? .summer : .christmas, population: 30)
            hold(world, angle: 10, seconds: 12) { _ in
                for c in world.critters {
                    let x = Double(c.position.x), y = Double(c.position.y)
                    XCTAssertTrue(x > -70 && x < Double(self.screen.width) + 70, "\(style) x \(x)")
                    XCTAssertTrue(y > -70 && y < Double(self.screen.height) + 70, "\(style) y \(y)")
                    XCTAssertTrue(c.speed >= 0 && c.speed <= world.tuning.fleeSpeedCap)
                    XCTAssertTrue(c.facing == 1 || c.facing == -1)
                    if c.species.locomotion != .hop { XCTAssertEqual(c.lift, 0) }
                }
            }
        }
    }
}
