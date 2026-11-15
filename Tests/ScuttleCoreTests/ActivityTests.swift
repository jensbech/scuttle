import XCTest
import CoreGraphics
@testable import ScuttleCore

class ActivityCase: BehaviourCase {
    let siteKinds: Set<PropKind> = [.leafPile, .snowman, .igloo, .tree, .giftStack, .nest, .sandcastle, .campfire, .banner, .rope]

    func busyWorld(seed: UInt64 = 1, season: Season = .autumn, population: Int = 24, growth: Bool = false) -> World {
        let world = makeWorld(seed: seed, season: season, population: population, growth: growth)
        world.tuning.workEnabled = true
        world.tuning.stealChance = 0
        return world
    }

    func checkProps(_ world: World, file: StaticString = #filePath, line: UInt = #line) {
        let ids = Set(world.critters.map(\.id))
        var lastSite = -1
        var firstCarried = Int.max
        for (n, p) in world.props.enumerated() {
            XCTAssertTrue(p.position.x.isFinite && p.position.y.isFinite && p.size.isFinite && p.rotation.isFinite, file: file, line: line)
            XCTAssertGreaterThan(p.alpha, 0, file: file, line: line)
            XCTAssertLessThanOrEqual(p.alpha, 1, file: file, line: line)
            XCTAssertTrue((0...1).contains(p.progress), file: file, line: line)
            XCTAssertTrue((0...3).contains(p.variant), file: file, line: line)
            XCTAssertGreaterThan(p.size, 1, file: file, line: line)
            let m = Double(p.size) * 1.5 + 4
            XCTAssertTrue(Double(p.position.x) > -m && Double(p.position.x) < Double(screen.width) + m, "\(p.kind) x \(p.position.x)", file: file, line: line)
            XCTAssertTrue(Double(p.position.y) > -m && Double(p.position.y) < Double(screen.height) + m * 4, "\(p.kind) y \(p.position.y)", file: file, line: line)
            if let h = p.holder { XCTAssertTrue(ids.contains(h), "holder \(h) of \(p.kind)", file: file, line: line) }
            if let h = p.partner { XCTAssertTrue(ids.contains(h), "partner \(h) of \(p.kind)", file: file, line: line) }
            if p.kind == .rope || p.kind == .banner { XCTAssertNotNil(p.end, file: file, line: line) }
            if siteKinds.contains(p.kind) { lastSite = max(lastSite, n) }
            if p.holder != nil && p.kind != .rope { firstCarried = min(firstCarried, n) }
        }
        if firstCarried != Int.max { XCTAssertGreaterThan(firstCarried, lastSite, "carried props draw over sites", file: file, line: line) }
    }

    func runUntil(_ world: World, angle: Double, limit: Double, check: Bool = true, _ done: () -> Bool) -> Double? {
        var t = 0.0
        while t < limit {
            t += dt
            world.step(dt: dt, lidAngle: angle)
            if check && Int(t * 60) % 15 == 0 { checkProps(world) }
            if done() { return t }
        }
        return nil
    }

    func home(_ k: ProjectKind) -> Season {
        switch k {
        case .leafPile, .acornStash: return .autumn
        case .snowman, .igloo: return .winter
        case .tree: return .christmas
        case .jackLantern: return .halloween
        case .nest: return .spring
        case .sandcastle, .campfire: return .summer
        case .party: return .newYear
        }
    }
}

final class ActivityTests: ActivityCase {
    func testBriefCloseStaysSparseAndPropFree() {
        for seed in [1, 2, 3] as [UInt64] {
            let world = busyWorld(seed: seed)
            hold(world, angle: 22, seconds: 5.5) { _ in
                XCTAssertTrue(world.props.isEmpty)
                XCTAssertEqual(world.workerCount, 0)
            }
        }
    }

    func testDuskOnlyBringsCautiousErrandsNearEdges() {
        var seen = 0
        for seed in [1, 2, 3, 4] as [UInt64] {
            let world = busyWorld(seed: seed)
            hold(world, angle: 44, seconds: 90) { _ in
                XCTAssertTrue(world.projects.isEmpty)
                XCTAssertTrue(world.games.isEmpty)
                XCTAssertLessThanOrEqual(world.workerCount, 1)
                for (k, v) in world.workCounts where v > 0 { XCTAssertEqual(k, .errand) }
                for b in world.bugs where b.job != nil && b.mode != .hidden {
                    seen += 1
                    XCTAssertLessThan(world.edgeDistance(b.x, b.y), world.tuning.duskBand + b.size * 2 + 40)
                }
            }
            XCTAssertEqual(world.mood, .dusk)
        }
        XCTAssertGreaterThan(seen, 0)
    }

    func testDarkBringsBuildingButNoGames() {
        var built = 0
        for seed in [1, 2] as [UInt64] {
            let world = busyWorld(seed: seed)
            hold(world, angle: 22, seconds: 90) { t in
                XCTAssertTrue(world.games.isEmpty)
                if Int(t * 60) % 30 == 0 { self.checkProps(world) }
            }
            if !world.projects.isEmpty { built += 1 }
        }
        XCTAssertGreaterThan(built, 0)
    }

    func testFewFiguresGetOneErrandAtMost() {
        for seed in [1, 2, 3] as [UInt64] {
            let world = busyWorld(seed: seed, population: 3, growth: true)
            hold(world, angle: 6, seconds: 70) { _ in
                XCTAssertLessThanOrEqual(world.workerCount, 1)
                XCTAssertTrue(world.projects.isEmpty)
                XCTAssertTrue(world.games.isEmpty)
            }
        }
    }

    func testMostFiguresStayIdle() {
        let world = busyWorld(seed: 5, season: .winter, population: 40)
        var peak = 0
        hold(world, angle: 6, seconds: 150) { _ in
            peak = max(peak, world.workerCount)
            XCTAssertLessThanOrEqual(world.projects.filter { $0.phase != .finished }.count, 1)
            XCTAssertLessThanOrEqual(world.games.count, 1)
        }
        XCTAssertGreaterThan(peak, 0)
        XCTAssertLessThanOrEqual(peak, Int(Double(40) * 0.25) + 1)
    }

    func testLargeCrowdKeepsCaps() {
        let world = busyWorld(seed: 2, season: .autumn, population: 220)
        hold(world, angle: 6, seconds: 90) { _ in
            XCTAssertLessThanOrEqual(world.workerCount, world.tuning.workMax + 8)
            XCTAssertLessThanOrEqual(world.projects.filter { $0.phase != .finished }.count, 2)
            XCTAssertLessThanOrEqual(world.games.count, 2)
            XCTAssertLessThanOrEqual(world.props.count, world.tuning.propMax)
        }
    }

    func testDisabledSwitchesKeepEverythingAway() {
        let world = busyWorld(seed: 1, season: .winter)
        world.tuning.workEnabled = false
        hold(world, angle: 6, seconds: 60) { _ in
            XCTAssertEqual(world.workerCount, 0)
            XCTAssertTrue(world.props.isEmpty)
        }
        let other = busyWorld(seed: 1, season: .winter)
        other.tuning.errandsEnabled = false
        other.tuning.projectsEnabled = false
        other.tuning.gamesEnabled = false
        hold(other, angle: 6, seconds: 60) { _ in
            XCTAssertTrue(other.projects.isEmpty)
            XCTAssertTrue(other.games.isEmpty)
            XCTAssertTrue(other.errandsRunning.isEmpty)
        }
    }

    func testDeterministicPerSeed() {
        let a = busyWorld(seed: 9, season: .winter)
        let b = busyWorld(seed: 9, season: .winter)
        hold(a, angle: 6, seconds: 80)
        hold(b, angle: 6, seconds: 80)
        XCTAssertEqual(signature(a), signature(b))
        XCTAssertEqual(a.props, b.props)
        XCTAssertFalse(a.props.isEmpty && a.workerCount == 0)
    }

    func testFailsafeEndsEveryJob() {
        let world = busyWorld(seed: 3, season: .winter)
        world.tuning.jobMaxSeconds = 25
        hold(world, angle: 6, seconds: 120) { _ in
            for b in world.bugs where b.job != nil {
                XCTAssertLessThanOrEqual(b.job!.total, 25.1)
            }
        }
    }

    func testStepCostStaysCheapWithActivities() {
        func cost(_ work: Bool) -> Double {
            let world = makeWorld(seed: 4, season: .winter, population: 400)
            world.tuning.workEnabled = work
            hold(world, angle: 6, seconds: 24)
            let start = Date()
            hold(world, angle: 6, seconds: 5)
            return Date().timeIntervalSince(start) / 300
        }
        let plain = cost(false)
        let rich = cost(true)
        XCTAssertLessThan(rich, plain * 1.35 + 0.0008)
    }
}

final class ActivityEndingTests: ActivityCase {
    func testFastOpenAbandonsEverythingInTime() {
        for (seed, season) in [(1, Season.winter), (2, .autumn), (3, .newYear)] as [(UInt64, Season)] {
            let world = busyWorld(seed: seed, season: season)
            world.tuning.forceProject = world.projectKinds(season).first
            hold(world, angle: 6, seconds: 70)
            XCTAssertFalse(world.props.isEmpty, "seed \(seed)")
            var propsGone: Double?
            var critsGone: Double?
            var afterFright = 0
            hold(world, angle: 115, seconds: 7) { t in
                if propsGone == nil && world.props.isEmpty { propsGone = t }
                if critsGone == nil && world.critters.isEmpty { critsGone = t }
                if t > 0.6 && t < 1.4 { afterFright += world.props.count }
                if world.light >= world.tuning.fullLight && t > 3.5 { XCTAssertTrue(world.props.isEmpty) }
                self.checkProps(world)
            }
            XCTAssertNotNil(propsGone)
            XCTAssertNotNil(critsGone)
            XCTAssertLessThanOrEqual(propsGone ?? 99, (critsGone ?? 0) + 0.05)
            XCTAssertLessThanOrEqual(critsGone ?? 99, 4.6)
            XCTAssertGreaterThan(afterFright, 0, "props stay visible through the fright pause")
            XCTAssertTrue(world.isQuiet)
            XCTAssertTrue(world.projects.isEmpty)
            XCTAssertTrue(world.games.isEmpty)
        }
    }

    func testFastOpenNeverTiptoesOutOfAGame() {
        for (seed, kind) in [(1, GameKind.hideAndSeek), (2, .ball), (3, .tug)] as [(UInt64, GameKind)] {
            let world = busyWorld(seed: seed, season: .summer)
            world.tuning.forceGame = kind
            _ = runUntil(world, angle: 8, limit: 80, check: false) { world.games.first?.phase == .play }
            var fright = false
            drive(world, seconds: 6, angle: ramp(from: 8, to: 110, over: 0.25)) { _ in
                for c in world.critters {
                    if c.fright > 0 { fright = true }
                    XCTAssertFalse(c.gesture == .tiptoe || c.gesture == .wave, "seed \(seed) \(kind)")
                }
            }
            XCTAssertTrue(fright)
            XCTAssertTrue(world.isQuiet)
        }
    }

    func testFrightDropsCarriedThings() {
        let world = busyWorld(seed: 2, season: .autumn)
        world.tuning.forceProject = .acornStash
        world.tuning.grabChance = 0
        let carrying = runUntil(world, angle: 22, limit: 120) { world.props.contains { $0.holder != nil } }
        XCTAssertNotNil(carrying)
        var dropped = false
        hold(world, angle: 115, seconds: 1.0) { t in
            if t > 0.3 && !world.props.isEmpty && world.props.allSatisfy({ $0.holder == nil }) { dropped = true }
        }
        XCTAssertTrue(dropped)
        clearsAfterSnap(world)
    }

    func testGentleOpenLetsSomeCarryThingsAway() {
        var kept = 0
        var tracked = 0
        for seed in [1, 2, 3, 4, 5, 6] as [UInt64] {
            let world = busyWorld(seed: seed, season: .autumn)
            world.tuning.forceProject = .acornStash
            world.tuning.carryOffChance = 1
            guard runUntil(world, angle: 22, limit: 150, check: false, { world.props.contains { $0.holder != nil && $0.partner == nil } }) != nil else { continue }
            tracked += 1
            drive(world, seconds: 30, angle: ramp(from: 22, to: 112, over: 24)) { _ in
                if world.bugs.contains(where: { $0.keep >= 0 && $0.sneak != nil }) { kept += 1 }
                self.checkProps(world)
            }
            hold(world, angle: 112, seconds: 6)
            XCTAssertTrue(world.props.isEmpty, "seed \(seed)")
            XCTAssertTrue(world.isQuiet, "seed \(seed)")
        }
        XCTAssertGreaterThan(tracked, 0)
        XCTAssertGreaterThan(kept, 0)
    }

    func testPropsNeverOutliveTheLight() {
        let world = busyWorld(seed: 4, season: .winter)
        hold(world, angle: 6, seconds: 90)
        drive(world, seconds: 12, angle: ramp(from: 6, to: 110, over: 3)) { _ in
            if world.light >= world.tuning.fullLight && world.critters.isEmpty { XCTAssertTrue(world.props.isEmpty) }
        }
        XCTAssertTrue(world.props.isEmpty)
        XCTAssertEqual(world.propCount, 0)
    }

    func testJiggleSuspendsWork() {
        let world = busyWorld(seed: 1, season: .autumn)
        world.tuning.forceProject = .leafPile
        hold(world, angle: 22, seconds: 40)
        XCTAssertFalse(world.projects.isEmpty)
        drive(world, seconds: 2, angle: { t in 22 + 5 * sin(t * 30) })
        if world.isJiggling { XCTAssertTrue(world.projects.allSatisfy { $0.dormant || $0.phase == .finished }) }
    }
}

final class ProjectTests: ActivityCase {
    func project(_ kind: ProjectKind, seed: UInt64 = 1, limit: Double = 320) -> (World, Double?, [Double]) {
        let world = busyWorld(seed: seed, season: home(kind))
        world.tuning.forceProject = kind
        world.tuning.inspectChance = 0
        var trail: [Double] = []
        let done = runUntil(world, angle: 22, limit: limit) {
            if let p = world.projects.first { trail.append(p.progress) }
            return world.projects.first.map { $0.phase != .building } ?? false
        }
        return (world, done, trail)
    }

    func assertBuilds(_ kind: ProjectKind, site: PropKind?, file: StaticString = #filePath, line: UInt = #line) {
        let (world, done, trail) = project(kind)
        XCTAssertNotNil(done, "\(kind) never finished", file: file, line: line)
        XCTAssertFalse(trail.isEmpty, file: file, line: line)
        var low = 0.0
        for v in trail {
            XCTAssertGreaterThanOrEqual(v, low - 1e-9, "\(kind) progress went backwards", file: file, line: line)
            low = max(low, v)
        }
        XCTAssertEqual(world.projects.first?.kind, kind, file: file, line: line)
        if let site {
            let p = world.props.first { $0.kind == site }
            XCTAssertNotNil(p, "\(kind) has no \(site)", file: file, line: line)
            XCTAssertEqual(p?.progress ?? 0, 1, accuracy: 0.01, file: file, line: line)
            XCTAssertNil(p?.holder, file: file, line: line)
        }
        let before = world.workCounts
        hold(world, angle: 22, seconds: 8)
        let after = world.workCounts
        XCTAssertTrue((before[.celebrate] ?? 0) + (after[.celebrate] ?? 0) + (after[.gather] ?? 0) > 0, "\(kind) no celebration", file: file, line: line)
    }

    func testLeafPile() {
        assertBuilds(.leafPile, site: nil)
    }

    func testAcornStashHeap() {
        let (world, done, _) = project(.acornStash)
        XCTAssertNotNil(done)
        XCTAssertGreaterThanOrEqual(world.props.filter { $0.kind == .acorn && $0.holder == nil }.count, 7)
    }

    func testSnowmanStages() {
        let world = busyWorld(seed: 1, season: .winter)
        world.tuning.forceProject = .snowman
        var bands = Set<Int>()
        var rolled = 0.0
        var lifted = false
        let done = runUntil(world, angle: 22, limit: 360) {
            if let s = world.props.first(where: { $0.kind == .snowman }) { bands.insert(Int(s.progress * 3 + 1e-6)) }
            for p in world.props where p.kind == .snowball { rolled = max(rolled, Double(p.size)) }
            if world.bugs.contains(where: { $0.job?.task == .lift }) { lifted = true }
            return world.projects.first.map { $0.phase != .building } ?? false
        }
        XCTAssertNotNil(done)
        XCTAssertTrue(bands.isSuperset(of: [1, 2, 3]), "\(bands)")
        XCTAssertTrue(lifted)
        XCTAssertGreaterThan(rolled, 20)
    }

    func testIgloo() { assertBuilds(.igloo, site: .igloo) }
    func testTree() { assertBuilds(.tree, site: .tree) }
    func testJackLantern() { assertBuilds(.jackLantern, site: .pumpkin) }
    func testNest() { assertBuilds(.nest, site: .nest) }
    func testSandcastle() { assertBuilds(.sandcastle, site: .sandcastle) }
    func testParty() { assertBuilds(.party, site: .banner) }
    func testCampfire() { assertBuilds(.campfire, site: .campfire) }

    func testSiteSitsOnScreenAwayFromEdges() {
        for kind in ProjectKind.allCases {
            let world = busyWorld(seed: 2, season: home(kind))
            world.tuning.forceProject = kind
            _ = runUntil(world, angle: 22, limit: 60) { !world.projects.isEmpty }
            guard let p = world.projects.first else {
                XCTFail("\(kind) never started")
                continue
            }
            XCTAssertGreaterThan(p.x, 60)
            XCTAssertLessThan(p.x, Double(screen.width) - 60)
            XCTAssertGreaterThan(p.y, 20)
            XCTAssertLessThan(p.y, Double(screen.height) * 0.62)
        }
    }

    func testThiefTakesFromTheHeap() {
        let world = busyWorld(seed: 3, season: .autumn)
        world.tuning.forceProject = .acornStash
        world.tuning.stealChance = 1
        world.tuning.stealCooldown = 1...2
        var stole = false
        _ = runUntil(world, angle: 22, limit: 200) {
            if (world.workCounts[.steal] ?? 0) > 0 { stole = true }
            return stole
        }
        XCTAssertTrue(stole)
    }

    func testBuildIsRememberedAcrossShortAbsence() {
        let world = busyWorld(seed: 1, season: .autumn)
        world.tuning.forceProject = .leafPile
        let started = runUntil(world, angle: 22, limit: 120) { (world.projects.first?.progress ?? 0) > 0.3 }
        XCTAssertNotNil(started)
        let saved = world.projects.first?.progress ?? 0
        world.tuning.forceProject = nil
        hold(world, angle: 115, seconds: 40)
        XCTAssertTrue(world.props.isEmpty)
        XCTAssertEqual(world.rememberedProject, .leafPile)
        let back = runUntil(world, angle: 22, limit: 40) { !world.projects.isEmpty }
        XCTAssertNotNil(back)
        XCTAssertEqual(world.projects.first?.kind, .leafPile)
        XCTAssertTrue(world.projects.first?.resumed ?? false)
        XCTAssertGreaterThanOrEqual(world.projects.first?.progress ?? 0, saved - 0.05)
        XCTAssertLessThan(back ?? 99, 20)
        XCTAssertTrue(world.props.contains { $0.kind == .leafPile })
    }

    func testLongAbsenceStartsFresh() {
        let world = busyWorld(seed: 1, season: .autumn)
        world.tuning.forceProject = .leafPile
        world.tuning.buildMemorySeconds = 30
        _ = runUntil(world, angle: 22, limit: 120) { (world.projects.first?.progress ?? 0) > 0.3 }
        world.tuning.forceProject = nil
        world.tuning.projectsEnabled = false
        hold(world, angle: 115, seconds: 45)
        world.tuning.projectsEnabled = true
        hold(world, angle: 22, seconds: 12)
        XCTAssertNil(world.rememberedProject)
        XCTAssertFalse(world.projects.contains { $0.resumed })
    }
}

final class GameTests: ActivityCase {
    func game(_ kind: GameKind, season: Season = .summer, seed: UInt64 = 1, ledges: [CGRect] = []) -> World {
        let world = busyWorld(seed: seed, season: season)
        world.tuning.forceGame = kind
        world.surroundings = Surroundings(ledges: ledges)
        return world
    }

    func testBallGetsKickedAround() {
        let world = game(.ball)
        var kicks = 0
        var kickGesture = false
        let over = runUntil(world, angle: 6, limit: 120) {
            kicks = max(kicks, world.games.first?.kicks ?? 0)
            if world.critters.contains(where: { $0.gesture == .kick }) { kickGesture = true }
            return kicks >= 4
        }
        XCTAssertNotNil(over)
        XCTAssertTrue(kickGesture)
        let ball = world.props.first { $0.kind == .ball }
        XCTAssertNotNil(ball)
        XCTAssertNil(ball?.holder)
    }

    func testPointerSwipeKnocksTheBallWithoutScaring() {
        let world = game(.ball, seed: 2)
        _ = runUntil(world, angle: 6, limit: 120) { (world.games.first?.kicks ?? 0) >= 2 }
        guard let ball = world.props.first(where: { $0.kind == .ball }) else { return XCTFail("no ball") }
        let before = ball.position
        world.surroundings = Surroundings(pointer: CGPoint(x: before.x - 30, y: before.y), pointerSpeed: 3000, ledges: [])
        hold(world, angle: 6, seconds: 0.1)
        world.surroundings = Surroundings(pointer: CGPoint(x: before.x + 10, y: before.y), pointerSpeed: 3000, ledges: [])
        hold(world, angle: 6, seconds: 0.1)
        world.surroundings = Surroundings()
        hold(world, angle: 6, seconds: 0.8)
        let after = world.props.first { $0.kind == .ball }?.position ?? before
        XCTAssertGreaterThan(hypot(after.x - before.x, after.y - before.y), 20)
        XCTAssertFalse(world.critters.contains { $0.mode == .fleeing })
    }

    func testTugOfWarEndsWithATumble() {
        let world = game(.tug, seed: 3)
        var taut = false
        var tumbled = false
        var ended = false
        _ = runUntil(world, angle: 6, limit: 120) {
            if let r = world.props.first(where: { $0.kind == .rope }) {
                if r.holder != nil && r.partner != nil && r.progress > 0.9 { taut = true }
            }
            if let g = world.games.first, g.phase == .end {
                ended = true
                if world.critters.contains(where: { $0.gesture == .tumble }) { tumbled = true }
            }
            return tumbled
        }
        XCTAssertTrue(taut)
        XCTAssertTrue(ended)
        XCTAssertTrue(tumbled)
        hold(world, angle: 6, seconds: 1)
        if let r = world.props.first(where: { $0.kind == .rope }) {
            XCTAssertNil(r.holder)
            XCTAssertLessThan(r.progress, 0.5)
        }
    }

    func testSnowballFightOnlyInWinter() {
        let summer = busyWorld(seed: 1, season: .summer)
        hold(summer, angle: 6, seconds: 150) { _ in
            XCTAssertFalse(summer.games.contains { $0.kind == .snowballs })
        }
        let world = game(.snowballs, season: .winter)
        var flying = false
        var hit = false
        _ = runUntil(world, angle: 6, limit: 120) {
            if world.props.contains(where: { $0.kind == .snowball && $0.holder == nil && $0.position.y > 0 && $0.rotation != 0 }) { flying = true }
            if (world.games.first?.hits ?? 0) > 0 || world.critters.contains(where: { $0.gesture == .shiver || $0.gesture == .tumble }) { hit = true }
            return flying && hit
        }
        XCTAssertTrue(flying)
        XCTAssertTrue(hit)
    }

    func testHideAndSeekAtEdges() {
        let world = game(.hideAndSeek, seed: 2)
        var counted = false
        var peeked: [Double] = []
        var found = 0
        _ = runUntil(world, angle: 6, limit: 120) {
            if world.critters.contains(where: { $0.gesture == .count }) { counted = true }
            let players = Set(world.bugs.filter { $0.job?.family == .play }.map(\.id))
            for c in world.critters where c.gesture == .peek && players.contains(c.id) { peeked.append(self.edgeDistance(c)) }
            found = max(found, world.games.first?.found ?? 0)
            return found >= 1 && !peeked.isEmpty
        }
        XCTAssertTrue(counted)
        XCTAssertFalse(peeked.isEmpty)
        XCTAssertLessThan(peeked.max() ?? 99, 40)
        XCTAssertGreaterThanOrEqual(found, 1)
    }

    func testHideAndSeekUsesLedges() {
        let ledge = CGRect(x: 300, y: 200, width: 600, height: 400)
        var under = false
        for seed in [1, 2, 3, 4] as [UInt64] {
            let world = game(.hideAndSeek, seed: seed, ledges: [ledge])
            _ = runUntil(world, angle: 6, limit: 60) {
                for b in world.bugs where b.job?.family == .play && b.job?.aloft == true && b.job?.stage == 3 {
                    if abs(b.y - Double(ledge.maxY)) < b.size && b.x > Double(ledge.minX) && b.x < Double(ledge.maxX) { under = true }
                }
                return under
            }
            if under { break }
        }
        XCTAssertTrue(under)
    }

    func testGamesOnlyInDeepDark() {
        let world = busyWorld(seed: 1, season: .summer)
        world.tuning.forceGame = .ball
        hold(world, angle: 24, seconds: 60) { _ in XCTAssertTrue(world.games.isEmpty) }
    }

    func testRaisingLidOutOfDeepEndsGame() {
        let world = game(.ball, seed: 4)
        _ = runUntil(world, angle: 6, limit: 80) { world.games.first?.phase == .play }
        XCTAssertFalse(world.games.isEmpty)
        world.tuning.forceGame = nil
        world.tuning.gamesEnabled = true
        hold(world, angle: 26, seconds: 14)
        XCTAssertTrue(world.games.isEmpty)
    }
}

final class ErrandTests: ActivityCase {
    func errand(_ kind: ErrandKind, season: Season, seed: UInt64 = 1, angle: Double = 22, limit: Double = 90, check: ((World) -> Bool)? = nil) -> Bool {
        let world = busyWorld(seed: seed, season: season)
        world.tuning.forceErrand = kind
        world.tuning.projectsEnabled = false
        world.tuning.gamesEnabled = false
        var saw = false
        _ = runUntil(world, angle: angle, limit: limit) {
            if world.errandsRunning.contains(kind) && (check?(world) ?? true) { saw = true }
            return saw
        }
        return saw
    }

    func testDeliverCarriesSeasonItem() {
        XCTAssertTrue(errand(.deliver, season: .autumn) { w in w.props.contains { $0.kind == .acorn && $0.holder != nil } })
        XCTAssertTrue(errand(.deliver, season: .christmas) { w in w.props.contains { $0.kind == .present && $0.holder != nil } })
    }

    func testCrumbGetsEaten() {
        XCTAssertTrue(errand(.crumb, season: .spring, limit: 120) { w in w.props.contains { $0.kind == .crumb && $0.progress < 0.6 } })
    }

    func testFlowersArePlantedAndVisited() {
        let world = busyWorld(seed: 2, season: .spring)
        world.tuning.forceErrand = .plant
        world.tuning.projectsEnabled = false
        world.tuning.gamesEnabled = false
        _ = runUntil(world, angle: 22, limit: 120) { world.props.contains { $0.kind == .flower && $0.progress >= 1 } }
        XCTAssertTrue(world.props.contains { $0.kind == .flower })
        world.tuning.forceErrand = .pollinate
        var visited = false
        _ = runUntil(world, angle: 22, limit: 120) {
            visited = world.errandsRunning.contains(.pollinate)
            return visited
        }
        XCTAssertTrue(visited)
        XCTAssertLessThanOrEqual(world.props.filter { $0.kind == .flower }.count, world.tuning.flowerMax)
    }

    func testGhostCarriesLantern() {
        XCTAssertTrue(errand(.lantern, season: .halloween) { w in w.props.contains { $0.kind == .lantern && $0.holder != nil } })
    }

    func testPenguinSlides() {
        XCTAssertTrue(errand(.slide, season: .winter, limit: 150) { w in w.bugs.contains { $0.glide && $0.species == .penguin } })
    }
}
