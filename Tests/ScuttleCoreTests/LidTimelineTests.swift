import XCTest
@testable import ScuttleCore

final class LidTimelineTests: XCTestCase {
    func testInterpolatesBetweenKeyframes() {
        let t = LidTimeline(keyframes: [.init(t: 0, angle: 100), .init(t: 2, angle: 20)])
        XCTAssertEqual(t.angle(at: -1), 100)
        XCTAssertEqual(t.angle(at: 1), 60, accuracy: 0.001)
        XCTAssertEqual(t.angle(at: 5), 20)
        XCTAssertTrue(t.isFinished(at: 2))
    }

    func testHoldAndLoop() {
        let t = LidTimeline(loop: true, keyframes: [
            .init(t: 0, angle: 100),
            .init(t: 1, angle: 20, ease: .hold),
            .init(t: 2, angle: 20),
        ])
        XCTAssertEqual(t.angle(at: 0.9), 100)
        XCTAssertEqual(t.angle(at: 1.5), 20)
        XCTAssertEqual(t.angle(at: 2.5), 100)
        XCTAssertFalse(t.isFinished(at: 99))
    }

    func testDecodesWithoutLoopField() throws {
        let json = #"{"keyframes":[{"t":0,"angle":110},{"t":1,"angle":30,"ease":"inOut"}]}"#
        let t = try JSONDecoder().decode(LidTimeline.self, from: Data(json.utf8))
        XCTAssertFalse(t.loop)
        XCTAssertEqual(t.angle(at: 0.5), 70, accuracy: 0.001)
    }
}
