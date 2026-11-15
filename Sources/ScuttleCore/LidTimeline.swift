import Foundation

public struct LidTimeline: Codable, Sendable, Equatable {
    public enum Ease: String, Codable, Sendable {
        case linear
        case inOut
        case hold
    }

    public struct Keyframe: Codable, Sendable, Equatable {
        public var t: Double
        public var angle: Double
        public var ease: Ease?

        public init(t: Double, angle: Double, ease: Ease? = nil) {
            self.t = t
            self.angle = angle
            self.ease = ease
        }
    }

    public var loop: Bool
    public var keyframes: [Keyframe]

    public init(loop: Bool = false, keyframes: [Keyframe]) {
        self.loop = loop
        self.keyframes = keyframes.sorted { $0.t < $1.t }
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let loop = try c.decodeIfPresent(Bool.self, forKey: .loop) ?? false
        let keyframes = try c.decode([Keyframe].self, forKey: .keyframes)
        self.init(loop: loop, keyframes: keyframes)
    }

    public static func load(from url: URL) throws -> LidTimeline {
        try JSONDecoder().decode(LidTimeline.self, from: Data(contentsOf: url))
    }

    public var duration: Double { keyframes.last?.t ?? 0 }

    public func isFinished(at time: Double) -> Bool {
        !loop && time >= duration
    }

    public func angle(at time: Double) -> Double {
        guard let first = keyframes.first, let last = keyframes.last else { return 110 }
        var t = time
        if loop, duration > 0 { t = t.truncatingRemainder(dividingBy: duration) }
        if t <= first.t { return first.angle }
        if t >= last.t { return last.angle }
        for i in 1..<keyframes.count where t < keyframes[i].t {
            let a = keyframes[i - 1], b = keyframes[i]
            let span = b.t - a.t
            guard span > 0 else { return b.angle }
            let u = (t - a.t) / span
            switch b.ease ?? .linear {
            case .linear: return a.angle + (b.angle - a.angle) * u
            case .inOut: return a.angle + (b.angle - a.angle) * (u * u * (3 - 2 * u))
            case .hold: return a.angle
            }
        }
        return last.angle
    }
}
