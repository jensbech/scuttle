import XCTest
import CoreGraphics
@testable import ScuttleCore

final class SocialTests: BehaviourCase {
    func social(_ kind: SocialKind?, seed: UInt64 = 3, season: Season = .christmas, population: Int = 24) -> World {
        let world = makeWorld(seed: seed, season: season, population: population)
        world.tuning.forceSocial = kind
        world.tuning.forceGreeting = false
        world.tuning.forceRipple = false
        if kind != nil {
            world.tuning.socialTick = 0.5...0.5
            world.tuning.habitsEnabled = false
        }
        return world
    }

    func members(_ world: World, _ kind: SocialKind) -> [Bug] {
        world.bugs.filter { $0.mode != .hidden && $0.social?.kind == kind }
    }

    func testNaturalSocialLifeIsOccasionalStaggeredAndVaried() {
        var kinds = Set<SocialKind>()
        for (season, seed) in [(Season.christmas, 1), (.spring, 2), (.halloween, 3), (.winter, 4), (.autumn, 5), (.summer, 6)] as [(Season, UInt64)] {
            let world = social(nil, seed: seed, season: season, population: 30)
            var early = 0
            var busiest = 0
            var socialTime = 0.0
            var figureTime = 0.0
            hold(world, angle: 8, seconds: 120) { t in
                var n = 0
                for b in world.bugs where b.mode != .hidden {
                    if let s = b.social {
                        kinds.insert(s.kind)
                        if s.kind.counts { n += 1 }
                    }
                }
                if t < world.tuning.socialAfter { early += n }
                busiest = max(busiest, n)
                socialTime += Double(n) * self.dt
                figureTime += Double(world.critters.count) * self.dt
            }
            let cap = max(2, Int(30 * world.tuning.socialShare))
            XCTAssertEqual(early, 0, "\(season)")
            XCTAssertLessThanOrEqual(busiest, cap + 1, "\(season)")
            XCTAssertLessThan(socialTime / max(1, figureTime), 0.2, "\(season)")
            XCTAssertGreaterThan(socialTime, 0, "\(season)")
        }
        XCTAssertGreaterThanOrEqual(kinds.count, 6, "\(kinds)")
    }

    func testNoSocialAtDuskOrWhenDisabled() {
        let dusk = social(nil, seed: 2)
        dusk.tuning.forceSocial = .stroll
        hold(dusk, angle: 10, seconds: 4)
        hold(dusk, angle: 48, seconds: 40) { _ in
            XCTAssertTrue(self.members(dusk, .stroll).isEmpty)
        }
        let off = social(.huddle, seed: 2)
        off.tuning.socialEnabled = false
        hold(off, angle: 8, seconds: 40) { _ in
            XCTAssertTrue(off.bugs.allSatisfy { $0.social == nil })
        }
    }

    func testStrollingPairsWalkSideBySide() {
        var together = 0
        var apart = 0
        var farewell = 0
        for seed in [1, 2, 3] as [UInt64] {
            let world = social(.stroll, seed: seed)
            hold(world, angle: 8, seconds: 40) { _ in
                let pair = self.members(world, .stroll)
                guard pair.count == 2, let g = world.stage.social.groups.first(where: { $0.kind == .stroll }) else { return }
                if g.stage == 0 && g.clock > 2 {
                    let d = hypot(pair[0].x - pair[1].x, pair[0].y - pair[1].y)
                    if d < (pair[0].size + pair[1].size) * 1.6 { together += 1 } else { apart += 1 }
                }
                if g.stage == 1 && pair.allSatisfy({ $0.gesture == .look }) { farewell += 1 }
            }
            XCTAssertTrue(world.bugs.filter { $0.social?.kind == .stroll }.count <= 2)
        }
        XCTAssertGreaterThan(together, 300)
        XCTAssertGreaterThan(Double(together), Double(together + apart) * 0.8)
        XCTAssertGreaterThan(farewell, 10)
    }

    func testFollowTheLeaderKeepsItsSpacing() {
        var ok = 0
        var all = 0
        var longest = 0
        for seed in [1, 2, 4] as [UInt64] {
            let world = social(.string, seed: seed, population: 30)
            hold(world, angle: 8, seconds: 40) { _ in
                let line = self.members(world, .string)
                longest = max(longest, line.count)
                for b in line where b.social?.role == 1 {
                    guard let s = b.social, let a = world.bugs.first(where: { $0.id == s.target }) else { continue }
                    all += 1
                    if hypot(a.x - b.x, a.y - b.y) < s.spacing * 2.4 { ok += 1 }
                }
            }
        }
        XCTAssertGreaterThanOrEqual(longest, 3)
        XCTAssertLessThanOrEqual(longest, 4)
        XCTAssertGreaterThan(all, 300)
        XCTAssertGreaterThan(Double(ok), Double(all) * 0.8)
    }

    func testTagRolesSwapOnTouch() {
        var swaps = 0
        var spread = 0.0
        for seed in [1, 2, 3, 5] as [UInt64] {
            let world = social(.tag, seed: seed)
            var lastIt: [Int: Int] = [:]
            hold(world, angle: 8, seconds: 45) { _ in
                for g in world.stage.social.groups where g.kind == .tag {
                    if let prev = lastIt[g.id], prev != g.it { swaps += 1 }
                    lastIt[g.id] = g.it
                    for id in g.members {
                        if let b = world.bugs.first(where: { $0.id == id && $0.mode != .hidden }) {
                            spread = max(spread, hypot(b.x - g.x, b.y - g.y))
                        }
                    }
                }
            }
        }
        XCTAssertGreaterThan(swaps, 2)
        XCTAssertLessThan(spread, 230 * 2.2)
    }

    func testHuddleGathersChatsAndDisperses() {
        var gathered = 0
        var chatty = 0
        var dispersed = 0
        for seed in [1, 2, 3] as [UInt64] {
            let world = social(.huddle, seed: seed, population: 30)
            var was: [Int: (Double, Double)] = [:]
            var centre: [Int: (Double, Double)] = [:]
            hold(world, angle: 8, seconds: 40) { _ in
                let ring = self.members(world, .huddle)
                for g in world.stage.social.groups where g.kind == .huddle {
                    if g.stage == 1 {
                        for b in ring where b.social?.group == g.id {
                            if hypot(b.x - g.x, b.y - g.y) < g.radius * 1.8 { gathered += 1 }
                            if b.gesture == .look { chatty += 1 }
                        }
                    }
                }
                let now = Set(ring.map(\.id))
                for (id, p) in was where !now.contains(id) {
                    if let b = world.bugs.first(where: { $0.id == id }), let c = centre[id], b.mode != .hidden {
                        if hypot(b.x - c.0, b.y - c.1) >= hypot(p.0 - c.0, p.1 - c.1) - 1 { dispersed += 1 }
                    }
                }
                was.removeAll()
                centre.removeAll()
                for b in ring {
                    was[b.id] = (b.x, b.y)
                    if let g = world.stage.social.groups.first(where: { $0.id == b.social?.group }) { centre[b.id] = (g.x, g.y) }
                }
            }
        }
        XCTAssertGreaterThan(gathered, 400)
        XCTAssertGreaterThan(chatty, 60)
        XCTAssertGreaterThan(dispersed, 3)
    }

    func testDuetDancesInSyncOnlyInDeepDark() {
        var synced = 0
        for seed in [1, 2, 3] as [UInt64] {
            let world = social(.duet, seed: seed)
            world.tuning.sleepEnabled = false
            world.tuning.playChance = 0
            hold(world, angle: 5, seconds: 40) { _ in
                let pair = self.members(world, .duet)
                let dancing = world.critters.filter { c in c.gesture == .dance && pair.contains { $0.id == c.id } }
                if dancing.count == 2 {
                    XCTAssertEqual(dancing[0].gestureTime, dancing[1].gestureTime, accuracy: 1e-9)
                    synced += 1
                }
                XCTAssertLessThanOrEqual(world.critters.filter { $0.gesture == .dance || $0.gesture == .cheer }.count, world.playCap() + 1)
            }
        }
        XCTAssertGreaterThan(synced, 200)
        let shallow = social(.duet, seed: 1)
        hold(shallow, angle: 25, seconds: 40) { _ in
            XCTAssertTrue(self.members(shallow, .duet).isEmpty)
        }
    }

    func testASleeperGetsNudgedAwake() {
        var woken = 0
        for seed in [1, 2, 3] as [UInt64] {
            let world = social(.nudge, seed: seed, season: .christmas)
            world.tuning.playChance = 0
            world.tuning.sleepAfter = 8
            world.tuning.sleepRamp = 4
            world.tuning.nudgeAfter = 2
            var nudgers = Set<Int>()
            hold(world, angle: 4, seconds: 50) { _ in
                for b in world.bugs where b.mode != .hidden {
                    if let s = b.social, s.kind == .nudge, s.stage == 2 { nudgers.insert(s.target) }
                }
            }
            for id in nudgers where world.bugs.contains(where: { $0.id == id }) { woken += 1 }
        }
        XCTAssertGreaterThan(woken, 1)
    }

    func testFlyersVisitRestingFigures() {
        var hovering = 0
        var craning = 0
        for seed in [1, 2, 3] as [UInt64] {
            let world = social(.visit, seed: seed, season: .spring)
            hold(world, angle: 8, seconds: 40) { _ in
                for g in world.stage.social.groups where g.kind == .visit && g.stage == 1 {
                    guard let v = world.bugs.first(where: { $0.id == g.members[0] }), let host = world.bugs.first(where: { $0.id == g.members[1] }) else { continue }
                    if v.y > host.y && hypot(v.x - host.x, v.y - host.y) < host.size * 2 + v.size { hovering += 1 }
                    if host.gesture == .look { craning += 1 }
                }
            }
        }
        XCTAssertGreaterThan(hovering, 100)
        XCTAssertGreaterThan(craning, 100)
    }

    func testRareVisitorDrawsAnAdmiringAudience() {
        var looking = 0
        var closest = Double.infinity
        var most = 0
        for seed in [1, 2] as [UInt64] {
            let world = social(.admire, seed: seed, season: .autumn)
            world.tuning.forceRare = true
            world.tuning.rareMinDark = 0
            hold(world, angle: 8, seconds: 45) { _ in
                let fans = self.members(world, .admire)
                most = max(most, fans.count)
                guard let star = world.bugs.first(where: { $0.rare && $0.mode != .hidden }) else { return }
                for f in fans where f.gesture == .look || f.gesture == .wave {
                    looking += 1
                    closest = min(closest, hypot(f.x - star.x, f.y - star.y) - (f.size + star.size) * 0.5)
                }
            }
        }
        XCTAssertGreaterThan(looking, 100)
        XCTAssertGreaterThan(closest, 10)
        XCTAssertLessThanOrEqual(most, 4)
    }

    func testSnailsRaceVerySlowly() {
        var racing = 0
        var finished = 0
        for seed in [1, 2, 3, 4] as [UInt64] {
            let world = social(.race, seed: seed, season: .spring, population: 30)
            hold(world, angle: 8, seconds: 40) { _ in
                for g in world.stage.social.groups where g.kind == .race {
                    let pair = g.members.compactMap { id in world.bugs.first { $0.id == id } }
                    if g.stage == 1 {
                        racing += 1
                        for b in pair { XCTAssertLessThan(b.speed, 40) }
                    }
                    if g.stage == 2 && pair.contains(where: { $0.id == g.it && $0.gesture == .look }) { finished += 1 }
                }
            }
        }
        XCTAssertGreaterThan(racing, 300)
        XCTAssertGreaterThan(finished, 20)
    }

    func testSpeciesTouches() {
        let rolls = social(.roll, seed: 2, season: .autumn)
        var tumbleMoves = 0
        var last: [Int: Critter] = [:]
        hold(rolls, angle: 8, seconds: 30) { _ in
            for c in rolls.critters {
                if c.gesture == .tumble, let p = last[c.id], hypot(c.position.x - p.position.x, c.position.y - p.position.y) > 0.5 {
                    tumbleMoves += 1
                    XCTAssertTrue(c.species == .hedgehog || c.species == .acorn || c.species == .pumpkin)
                    XCTAssertEqual(c.lift, 0)
                }
                last[c.id] = c
            }
        }
        XCTAssertGreaterThan(tumbleMoves, 30)

        let slides = social(.slide, seed: 2, season: .winter)
        var gliding = 0
        var lastSlide: [Int: Critter] = [:]
        hold(slides, angle: 8, seconds: 30) { _ in
            for c in slides.critters where c.species == .penguin {
                if let b = slides.bugs.first(where: { $0.id == c.id }), b.social?.kind == .slide, b.social?.stage == 1, let p = lastSlide[c.id], c.speed > 20 {
                    XCTAssertEqual(c.gaitPhase, p.gaitPhase, accuracy: 1e-9)
                    gliding += 1
                }
                lastSlide[c.id] = c
            }
        }
        XCTAssertGreaterThan(gliding, 20)

        var rose = 0.0
        for seed in [1, 2, 4] as [UInt64] {
            let bobs = social(.bob, seed: seed, season: .newYear)
            hold(bobs, angle: 8, seconds: 30) { _ in
                for b in self.members(bobs, .bob) {
                    if let s = b.social { rose = max(rose, s.prev / b.size) }
                }
            }
        }
        XCTAssertGreaterThan(rose, 1)

        let ghosts = social(.peekaboo, seed: 1, season: .halloween)
        var faint = 1.0
        var boo = 0
        var shivers = 0
        hold(ghosts, angle: 8, seconds: 40) { _ in
            for c in ghosts.critters {
                if c.species == .ghost { faint = min(faint, c.alpha) }
                if c.species == .ghost && c.gesture == .wave { boo += 1 }
                if c.gesture == .shiver { shivers += 1 }
            }
        }
        XCTAssertLessThan(faint, 0.3)
        XCTAssertGreaterThan(boo, 10)
        XCTAssertGreaterThan(shivers, 10)
        hold(ghosts, angle: 115, seconds: 5)
        XCTAssertTrue(ghosts.isQuiet)

        let rain = makeWorld(seed: 4, season: .spring)
        rain.config.weather = .rain
        rain.tuning.forceSocial = .rainDance
        rain.tuning.socialTick = 0.5...0.5
        var happy = 0
        hold(rain, angle: 8, seconds: 30) { _ in
            for c in rain.critters where c.species == .frog && c.gesture == .cheer { happy += 1 }
        }
        XCTAssertGreaterThan(happy, 60)
    }

    func testFlinchRipplesThroughNeighboursWithoutAFright() {
        let world = social(nil, seed: 5, population: 40)
        world.tuning.socialAfter = 999
        world.tuning.habitsEnabled = false
        hold(world, angle: 8, seconds: 14)
        let before = world.critters.count
        guard let centre = world.bugs.filter({ $0.mode != .hidden && $0.free }).max(by: { self.crowd(world, $0) < self.crowd(world, $1) }) else { return XCTFail() }
        world.ripple(fromX: centre.x, y: centre.y, except: centre.id)
        var first: [Int: Double] = [:]
        var dist: [Int: Double] = [:]
        hold(world, angle: 8, seconds: 3) { t in
            for c in world.critters {
                XCTAssertEqual(c.fright, 0)
                XCTAssertNotEqual(c.mode, .startled)
                XCTAssertNotEqual(c.mode, .fleeing)
                if c.gesture == .shiver && first[c.id] == nil {
                    first[c.id] = t
                    dist[c.id] = hypot(Double(c.position.x) - centre.x, Double(c.position.y) - centre.y)
                }
            }
        }
        XCTAssertGreaterThanOrEqual(first.count, 1)
        XCTAssertLessThanOrEqual(first.count, world.tuning.flinchMax)
        if first.count >= 2 {
            let ordered = first.keys.sorted { first[$0]! < first[$1]! }
            XCTAssertLessThanOrEqual(dist[ordered[0]]!, dist[ordered[ordered.count - 1]]! + 30)
        }
        XCTAssertEqual(world.critters.count, before)
        XCTAssertTrue(world.bugs.allSatisfy { $0.social?.kind != .flinch })
    }

    func crowd(_ world: World, _ b: Bug) -> Int {
        world.bugs.filter { $0.mode != .hidden && $0.id != b.id && hypot($0.x - b.x, $0.y - b.y) < 150 }.count
    }

    func testEverySocialActAbortsCleanlyOnSnapOpen() {
        let cases: [(SocialKind, Season, Double)] = [
            (.stroll, .christmas, 8), (.string, .christmas, 8), (.tag, .christmas, 8), (.huddle, .christmas, 8),
            (.duet, .christmas, 5), (.visit, .spring, 8), (.race, .spring, 8), (.roll, .autumn, 8),
            (.slide, .winter, 8), (.bob, .newYear, 8), (.peekaboo, .halloween, 8),
        ]
        for (kind, season, angle) in cases {
            let world = social(kind, seed: 2, season: season, population: 30)
            var started = false
            hold(world, angle: angle, seconds: 40) { _ in
                if !self.members(world, kind).isEmpty { started = true }
            }
            hold(world, angle: angle, seconds: 0.1)
            XCTAssertTrue(started, "\(kind)")
            clearsAfterSnap(world)
            XCTAssertTrue(world.bugs.allSatisfy { $0.social == nil }, "\(kind)")
            XCTAssertEqual(world.socialGroupCount, 0, "\(kind)")
        }
    }

    func testGentleOpeningStillTiptoesOutOfSocialActs() {
        let world = social(.huddle, seed: 3, population: 30)
        world.tuning.playEnabled = false
        hold(world, angle: 10, seconds: 25)
        XCTAssertFalse(members(world, .huddle).isEmpty)
        var tiptoe = false
        drive(world, seconds: 14, angle: ramp(from: 10, to: 110, over: 6)) { _ in
            for c in world.critters {
                if c.gesture == .tiptoe { tiptoe = true }
                XCTAssertEqual(c.fright, 0)
            }
        }
        XCTAssertTrue(tiptoe)
        XCTAssertTrue(world.isQuiet)
    }

    func testFailsafeStillClearsSocialFigures() {
        let world = social(.tag, seed: 6)
        hold(world, angle: 8, seconds: 25)
        world.tuning.fleeSpeedRange = 1...2
        world.tuning.fleeSpeedCap = 2
        var lastSeen = 0.0
        hold(world, angle: 110, seconds: 12) { t in
            if !world.critters.isEmpty { lastSeen = t }
        }
        XCTAssertTrue(world.isQuiet)
        XCTAssertLessThan(lastSeen, world.tuning.failsafeSeconds + world.tuning.failsafeGrace + 1.5)
        XCTAssertTrue(world.bugs.allSatisfy { !$0.scripted })
    }

    func testSocialLifeIsDeterministic() {
        let a = social(nil, seed: 11, season: .halloween, population: 30), b = social(nil, seed: 11, season: .halloween, population: 30)
        let c = social(nil, seed: 12, season: .halloween, population: 30)
        var differed = false
        var t = 0.0
        while t < 60 {
            t += dt
            a.step(dt: dt, lidAngle: 6)
            b.step(dt: dt, lidAngle: 6)
            c.step(dt: dt, lidAngle: 6)
            XCTAssertEqual(signature(a), signature(b))
            if signature(a) != signature(c) { differed = true }
        }
        XCTAssertEqual(a.socialCounts, b.socialCounts)
        XCTAssertTrue(differed)
    }
}
