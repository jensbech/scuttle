import Foundation
import ScuttleCore

enum SourceKind: String {
    case sensor
    case timeline
    case manual
}

protocol AngleSource: AnyObject {
    var kind: SourceKind { get }
    var angle: Double? { get }
    func advance(by seconds: Double)
}

final class ManualSource: AngleSource {
    let kind = SourceKind.manual
    let angle: Double?

    init(angle: Double) {
        self.angle = max(0, min(180, angle))
    }

    func advance(by seconds: Double) {}
}

final class TimelineSource: AngleSource {
    let kind = SourceKind.timeline
    let name: String
    let timeline: LidTimeline
    private(set) var time = 0.0

    init(name: String, timeline: LidTimeline) {
        self.name = name
        self.timeline = timeline
    }

    var angle: Double? { timeline.angle(at: time) }
    var isFinished: Bool { timeline.isFinished(at: time) }

    func advance(by seconds: Double) {
        time += seconds
    }
}

final class LidInput {
    let sensor = LidSensor()
    private(set) var active: AngleSource

    init() {
        active = sensor
    }

    var kind: SourceKind { active.kind }
    var timeline: TimelineSource? { active as? TimelineSource }

    func useSensor() {
        active = sensor
    }

    func hold(_ angle: Double) {
        active = ManualSource(angle: angle)
    }

    func play(_ timeline: LidTimeline, name: String) {
        active = TimelineSource(name: name, timeline: timeline)
    }
}

enum Timelines {
    static let bundled = ["peek", "slow-open", "tease"]

    static let peek = LidTimeline(keyframes: [
        .init(t: 0, angle: 110),
        .init(t: 1, angle: 110),
        .init(t: 5, angle: 22, ease: .inOut),
        .init(t: 13, angle: 22),
        .init(t: 13.35, angle: 115, ease: .inOut),
        .init(t: 19, angle: 115),
    ])

    static func named(_ name: String) -> LidTimeline? {
        guard !name.isEmpty, name.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }) else { return nil }
        for dir in searchDirectories() {
            let url = dir.appendingPathComponent("\(name).json")
            if let timeline = try? LidTimeline.load(from: url) { return timeline }
        }
        return name == "peek" ? peek : nil
    }

    private static func searchDirectories() -> [URL] {
        var dirs: [URL] = []
        if Bundle.main.bundleURL.pathExtension == "app", let resources = Bundle.main.resourceURL {
            dirs.append(resources)
        }
        var dir = (Bundle.main.executableURL ?? URL(fileURLWithPath: CommandLine.arguments[0])).resolvingSymlinksInPath()
        for _ in 0..<6 {
            dir = dir.deletingLastPathComponent()
            dirs.append(dir.appendingPathComponent("scripts/timelines"))
        }
        dirs.append(URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("scripts/timelines"))
        return dirs
    }
}
