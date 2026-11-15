import XCTest
@testable import ScuttleCore

final class SleepStageTests: XCTestCase {
    private let on = SleepStage.Context(enabled: true, stageable: true)

    func testDisplaySleepStagesOnce() {
        var s = SleepStage()
        XCTAssertEqual(s.handle(.displaySleep, at: 10, context: on), [.stage])
        XCTAssertEqual(s.handle(.systemSleep, at: 10.1, context: on), [])
        XCTAssertEqual(s.handle(.lidClosed, at: 10.2, context: on), [])
        XCTAssertEqual(s.phase, .staged)
        XCTAssertEqual(s.stagedAt, 10)
        XCTAssertTrue(s.freezesWorld)
    }

    func testWakeRevealsThenCatchesAfterGrace() {
        var s = SleepStage(grace: 0.12)
        _ = s.handle(.lidClosed, at: 0, context: on)
        _ = s.handle(.displaySleep, at: 1, context: on)
        _ = s.handle(.systemSleep, at: 1, context: on)
        XCTAssertEqual(s.handle(.systemWake, at: 500, context: on), [])
        XCTAssertEqual(s.phase, .staged)
        XCTAssertEqual(s.handle(.displayWake, at: 500.2, context: on), [.reveal])
        XCTAssertEqual(s.phase, .waking)
        XCTAssertEqual(s.tick(at: 500.25), [])
        XCTAssertEqual(s.tick(at: 500.33), [.startCatch(from: 500.32)])
        XCTAssertEqual(s.phase, .awake)
        XCTAssertFalse(s.freezesWorld)
        XCTAssertEqual(s.tick(at: 501), [])
    }

    func testDisplaySleepWithoutLidStillStagesAndWakes() {
        var s = SleepStage()
        XCTAssertEqual(s.handle(.displaySleep, at: 0, context: on), [.stage])
        XCTAssertEqual(s.handle(.displayWake, at: 60, context: on), [.reveal])
    }

    func testDisplayWakeClearsAStaleLidClosed() {
        var s = SleepStage()
        _ = s.handle(.lidClosed, at: 0, context: on)
        _ = s.handle(.displaySleep, at: 1, context: on)
        XCTAssertEqual(s.handle(.displayWake, at: 9, context: on), [.reveal])
        XCTAssertFalse(s.lidClosed)
    }

    func testLidReopenedBeforeTheDisplaySleeps() {
        var s = SleepStage()
        XCTAssertEqual(s.handle(.lidClosed, at: 0, context: on), [.stage])
        XCTAssertEqual(s.handle(.lidOpened, at: 2, context: on), [.reveal])
        XCTAssertEqual(s.tick(at: 3), [.startCatch(from: 2 + s.grace)])
    }

    func testDisabledStagesNothing() {
        var s = SleepStage()
        let off = SleepStage.Context(enabled: false, stageable: true)
        XCTAssertEqual(s.handle(.displaySleep, at: 0, context: off), [])
        XCTAssertEqual(s.phase, .awake)
        XCTAssertEqual(s.handle(.displayWake, at: 5, context: off), [])
        XCTAssertEqual(s.tick(at: 6), [])
    }

    func testScreenThatStaysLitIsNotStaged() {
        var s = SleepStage()
        let external = SleepStage.Context(enabled: true, stageable: false)
        XCTAssertEqual(s.handle(.lidClosed, at: 0, context: external), [])
        XCTAssertEqual(s.phase, .awake)
    }

    func testMovingToALitScreenCancels() {
        var s = SleepStage()
        _ = s.handle(.lidClosed, at: 0, context: on)
        XCTAssertEqual(s.update(on), [])
        XCTAssertEqual(s.update(SleepStage.Context(enabled: true, stageable: false)), [.cancel])
        XCTAssertEqual(s.phase, .awake)
        XCTAssertEqual(s.update(SleepStage.Context(enabled: true, stageable: false)), [])
    }

    func testDisablingWhileStagedCancels() {
        var s = SleepStage()
        _ = s.handle(.displaySleep, at: 0, context: on)
        XCTAssertEqual(s.update(SleepStage.Context(enabled: false, stageable: true)), [.cancel])
    }

    func testLockedWakeWaitsForUnlock() {
        var s = SleepStage()
        _ = s.handle(.locked, at: 0, context: on)
        XCTAssertEqual(s.handle(.displaySleep, at: 0.1, context: on), [.stage])
        XCTAssertTrue(s.locked)
        XCTAssertEqual(s.handle(.displayWake, at: 100, context: on), [])
        XCTAssertEqual(s.phase, .staged)
        XCTAssertTrue(s.isHidden)
        XCTAssertEqual(s.tick(at: 110), [])
        XCTAssertEqual(s.handle(.unlocked, at: 120, context: on), [.reveal])
        XCTAssertEqual(s.tick(at: 121), [.startCatch(from: 120 + s.grace)])
    }

    func testLockWhileWakingConceals() {
        var s = SleepStage()
        _ = s.handle(.displaySleep, at: 0, context: on)
        _ = s.handle(.displayWake, at: 10, context: on)
        XCTAssertEqual(s.handle(.locked, at: 10.05, context: on), [.conceal])
        XCTAssertEqual(s.phase, .staged)
        XCTAssertEqual(s.tick(at: 11), [])
    }

    func testSessionSwitchCancels() {
        var s = SleepStage()
        _ = s.handle(.displaySleep, at: 0, context: on)
        XCTAssertEqual(s.handle(.sessionResigned, at: 1, context: on), [.cancel])
        XCTAssertEqual(s.phase, .awake)
        XCTAssertEqual(s.handle(.displaySleep, at: 2, context: on), [])
        XCTAssertEqual(s.handle(.sessionActive, at: 3, context: on), [])
        XCTAssertEqual(s.phase, .awake)
    }

    func testSleepingAgainWhileWakingRestages() {
        var s = SleepStage()
        _ = s.handle(.displaySleep, at: 0, context: on)
        _ = s.handle(.displayWake, at: 10, context: on)
        XCTAssertEqual(s.handle(.displaySleep, at: 10.05, context: on), [])
        XCTAssertEqual(s.phase, .staged)
        XCTAssertEqual(s.handle(.displayWake, at: 30, context: on), [.reveal])
        XCTAssertEqual(s.tick(at: 31), [.startCatch(from: 30 + s.grace)])
    }
}
