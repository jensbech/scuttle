import Foundation
import CoreGraphics
import ScuttleCore

struct GestureTrack {
    var gesture: Gesture
    var lastT: Double
    var species: Species
    var leaving: Gesture
    var leaveT: Double
    var leaveAt: Double
    var seen: Int
    var facing: CGFloat
    var turnAt: Double
}

struct GestureBlend {
    var gesture: Gesture
    var t: CGFloat
    var amount: CGFloat
    var leaving: Gesture
    var leaveT: CGFloat
    var leaveProgress: CGFloat
    var leaveWeight: CGFloat
    var face: CGFloat

    static let idle = GestureBlend(gesture: .none, t: 0, amount: 0, leaving: .none, leaveT: 0, leaveProgress: 1, leaveWeight: 0, face: 1)

    var isIdle: Bool { gesture == .none && leaveWeight <= 0 }
}

struct GestureMemory {
    private var tracks: [Int: GestureTrack] = [:]
    private var lastTime: Double = -.infinity
    private var lastPrune = 0
    static let limit = 768

    var count: Int { tracks.count }

    mutating func begin(time: Double, clock: Int) {
        if time < lastTime - 0.5 { tracks.removeAll(keepingCapacity: true) }
        lastTime = time
        if clock &- lastPrune > 180 || tracks.count > GestureMemory.limit {
            lastPrune = clock
            let cutoff = clock &- 90
            tracks = tracks.filter { $0.value.seen > cutoff }
            if tracks.count > GestureMemory.limit { tracks.removeAll(keepingCapacity: true) }
        }
    }

    mutating func resolve(_ c: Critter, time: Double, clock: Int) -> GestureBlend {
        let gt = c.gestureTime.isFinite ? max(0, c.gestureTime) : 0
        var track = tracks[c.id]
        if track == nil || track?.species != c.species {
            guard c.gesture != .none else {
                if track != nil { tracks.removeValue(forKey: c.id) }
                return .idle
            }
            track = GestureTrack(gesture: c.gesture, lastT: gt, species: c.species, leaving: .none, leaveT: 0, leaveAt: -.infinity, seen: clock,
                                 facing: c.facing < 0 ? -1 : 1, turnAt: -.infinity)
        }
        guard var tr = track else { return .idle }
        if tr.gesture != c.gesture || gt + 0.05 < tr.lastT {
            if tr.gesture != .none {
                tr.leaving = tr.gesture
                tr.leaveT = tr.lastT
                tr.leaveAt = time
            }
            tr.gesture = c.gesture
        }
        tr.lastT = gt
        tr.seen = clock
        let sign: CGFloat = c.facing < 0 ? -1 : 1
        if sign != tr.facing {
            tr.facing = sign
            tr.turnAt = time
        }
        var blend = GestureBlend.idle
        blend.face = sign * (2 * GestureMotion.smooth(CGFloat(time - tr.turnAt) / 0.2) - 1)
        blend.gesture = c.gesture
        blend.t = CGFloat(gt)
        blend.amount = c.gesture == .none ? 0 : GestureMotion.smooth(CGFloat(gt) / GestureMotion.entry(c.gesture))
        if tr.leaving != .none {
            let since = CGFloat(max(0, time - tr.leaveAt))
            let q = since / GestureMotion.exit(tr.leaving)
            if q >= 1 {
                tr.leaving = .none
            } else {
                blend.leaving = tr.leaving
                blend.leaveT = CGFloat(tr.leaveT) + since
                blend.leaveProgress = q
                blend.leaveWeight = 1 - GestureMotion.smooth(q)
            }
        }
        if tr.gesture == .none && tr.leaving == .none {
            tracks.removeValue(forKey: c.id)
        } else {
            tracks[c.id] = tr
        }
        return blend
    }
}

extension Gesture {
    var reachesEdge: Bool { self == .peek || self == .popUp }
}
