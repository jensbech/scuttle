import Foundation
import CoreGraphics
import ScuttleCore

struct StageItem {
    var depth: CGFloat
    var order: Int
    var critter: Int
    var prop: Int
}

enum HoldSpot {
    case overhead
    case beneath
    case front
    case hands
    case back
    case side
}

final class PropStage {
    private var items: [StageItem] = []
    private var holds: [Int: FigureHold] = [:]
    private var present: [Int: Int] = [:]
    private var waiting: [Int: [Int]] = [:]
    private var slot: [Int: Int] = [:]

    static func depth(_ c: Critter) -> CGFloat {
        c.position.y - CGFloat(c.size) * (c.species.isAirborne ? 0.9 : 0.46)
    }

    static func ends(_ p: Prop) -> (CGPoint, CGPoint) {
        let a = p.position
        let b = p.end ?? CGPoint(x: a.x + CGFloat(p.size) * 2.2, y: a.y)
        return (a, b)
    }

    static func depth(_ p: Prop) -> CGFloat {
        if p.kind == .rope || p.kind == .banner {
            if p.end != nil {
                let (a, b) = ends(p)
                return min(a.y, b.y) - CGFloat(p.size) * 0.1
            }
        }
        return p.position.y - CGFloat(p.size) * 0.46
    }

    func draw(_ scene: Scene, figures: FigurePainter, props: PropPainter) {
        let w = scene.size.width, h = scene.size.height
        items.removeAll(keepingCapacity: true)
        holds.removeAll(keepingCapacity: true)
        present.removeAll(keepingCapacity: true)
        waiting.removeAll(keepingCapacity: true)
        slot.removeAll(keepingCapacity: true)
        for (i, c) in scene.critters.enumerated() {
            let m = CGFloat(c.size) * 1.5 + 6
            let p = c.position
            if p.x < -m || p.y < -m || p.x > w + m || p.y > h + m { continue }
            guard FigurePainter.drawable(c) else { continue }
            present[c.id] = i
            items.append(StageItem(depth: PropStage.depth(c), order: i, critter: i, prop: -1))
        }
        var held: [Int] = []
        let first = items.count
        for (j, p) in scene.props.enumerated() {
            guard p.alpha > 0.01, p.size > 1, p.position.x.isFinite, p.position.y.isFinite else { continue }
            let a = p.holder.flatMap { present[$0] }
            let b = p.partner.flatMap { present[$0] }
            if a != nil || b != nil {
                held.append(j)
                continue
            }
            if !PropStage.visible(p, in: scene.size) { continue }
            var d = PropStage.depth(p)
            let q = p.position, s = CGFloat(p.size)
            for k in first..<items.count {
                let o = scene.props[items[k].prop]
                let os = CGFloat(o.size)
                guard abs(o.position.x - q.x) < (s + os) * 0.5, abs(o.position.y - q.y) < (s + os) * 0.6 else { continue }
                d = min(d, items[k].depth - 0.01)
            }
            items.append(StageItem(depth: d, order: scene.critters.count + j, critter: -1, prop: j))
        }
        items.sort { $0.depth != $1.depth ? $0.depth > $1.depth : $0.order < $1.order }
        for (k, item) in items.enumerated() where item.critter >= 0 {
            slot[scene.critters[item.critter].id] = k
        }
        for j in held {
            let p = scene.props[j]
            let k = max(p.holder.flatMap { slot[$0] } ?? -1, p.partner.flatMap { slot[$0] } ?? -1)
            waiting[k, default: []].append(j)
        }
        for item in items where item.prop >= 0 {
            let p = scene.props[item.prop]
            if p.kind == .rope || p.kind == .banner { continue }
            if PropArt.glows(p.kind, stage: PropArt.stage(p.kind, progress: p.progress)).isEmpty { continue }
            props.drawGlows(p, free(p), stage: PropArt.stage(p.kind, progress: p.progress))
        }
        for (k, item) in items.enumerated() {
            if item.critter >= 0 {
                let c = scene.critters[item.critter]
                if let hold = figures.draw(c) { holds[c.id] = hold }
                if let list = waiting[k] {
                    for j in list { drawHeld(scene.props[j], props: props) }
                }
            } else {
                drawFree(scene.props[item.prop], props: props)
            }
        }
    }

    static func visible(_ p: Prop, in size: CGSize) -> Bool {
        let m = CGFloat(p.size) * 1.6 + 8
        if p.kind == .rope || p.kind == .banner, p.end != nil {
            let (a, b) = ends(p)
            return max(a.x, b.x) > -m && min(a.x, b.x) < size.width + m && max(a.y, b.y) > -m && min(a.y, b.y) < size.height + m
        }
        let q = p.position
        return q.x > -m && q.y > -m && q.x < size.width + m && q.y < size.height + m
    }

    func free(_ p: Prop) -> PropPlacement {
        PropPlacement(centre: p.position, rotation: CGFloat(p.rotation.isFinite ? p.rotation : 0), alpha: CGFloat(min(1, p.alpha)),
                      grounded: p.kind != .balloon, ground: nil)
    }

    func drawFree(_ p: Prop, props: PropPainter) {
        let alpha = CGFloat(min(1, p.alpha))
        switch p.kind {
        case .rope where p.end != nil:
            let (a, b) = PropStage.ends(p)
            let tension = CGFloat(max(0, min(1, p.progress.isFinite ? p.progress : 1)))
            let d = hypot(b.x - a.x, b.y - a.y)
            if tension < 0.5 {
                props.drawRope(p, from: a, to: b, sag: 0, alpha: alpha, marker: false, wave: CGFloat(p.size) * 0.22 * (1 - tension * 2))
            } else {
                props.drawRope(p, from: a, to: b, sag: d * 0.2 * (1 - tension), alpha: alpha, marker: false)
            }
        case .banner:
            let (a, b) = PropStage.ends(p)
            props.drawBanner(p, from: a, to: b, sag: hypot(b.x - a.x, b.y - a.y) * 0.12, alpha: alpha, reveal: CGFloat(p.progress.isFinite ? p.progress : 1))
        default:
            var place = free(p)
            if p.kind == .balloon { place.rotation += sway(p) }
            props.draw(p, place, glows: false)
        }
    }

    func sway(_ p: Prop) -> CGFloat {
        CGFloat(0.07 * sin(p.age * 1.4 + Double(p.id % 13)))
    }

    static func carrySpot(_ prop: Prop, hold: FigureHold) -> HoldSpot {
        if prop.kind == .balloon { return .hands }
        switch hold.species.locomotion {
        case .flutter, .hover, .dart: return .beneath
        case .float: return hold.species.stance == .topDown ? .back : .side
        default: return hold.species.stance == .topDown ? .back : .overhead
        }
    }

    static func spot(for g: Gesture, prop: Prop, hold: FigureHold) -> HoldSpot {
        switch g {
        case .push: return .front
        case .pull: return prop.kind == .balloon ? .hands : .side
        default: return carrySpot(prop, hold: hold)
        }
    }

    static func tilt(_ hold: FigureHold) -> CGFloat {
        let o = CGPoint.zero.applying(hold.place)
        let u = CGPoint(x: 0, y: 1).applying(hold.place)
        return atan2(-(u.x - o.x), u.y - o.y)
    }

    static func centre(_ s: HoldSpot, prop: Prop, hold: FigureHold) -> CGPoint {
        let ps = CGFloat(prop.size)
        let foot = 0.46 * ps
        switch s {
        case .overhead:
            let top = hold.top
            if prop.kind == .balloon {
                let hand = hold.hands
                return CGPoint(x: hand.x, y: hand.y + foot)
            }
            return CGPoint(x: top.x, y: top.y + foot - 0.04 * ps)
        case .beneath:
            let b = hold.bottom
            return CGPoint(x: b.x, y: b.y - 0.5 * ps)
        case .front:
            let c = hold.shove
            return CGPoint(x: c.x + hold.face * 0.42 * ps, y: hold.ground + foot)
        case .hands:
            let hand = hold.hands
            if prop.kind == .balloon { return CGPoint(x: hand.x, y: hand.y + foot) }
            return CGPoint(x: hand.x + hold.face * 0.18 * ps, y: hand.y - 0.05 * ps)
        case .back:
            return hold.at(hold.rect.midX, hold.rect.midY + 0.12)
        case .side:
            let hand = hold.hands
            return CGPoint(x: hand.x + hold.face * 0.32 * ps, y: hand.y)
        }
    }

    func target(_ p: Prop, hold: FigureHold) -> (centre: CGPoint, spot: HoldSpot) {
        let b = hold.blend
        let main = PropStage.spot(for: b.gesture, prop: p, hold: hold)
        let here = PropStage.centre(main, prop: p, hold: hold)
        guard b.leaving != .none, b.leaveWeight > 0.001 else { return (here, main) }
        let other = PropStage.spot(for: b.leaving, prop: p, hold: hold)
        guard other != main else { return (here, main) }
        let there = PropStage.centre(other, prop: p, hold: hold)
        let wa = b.gesture == .none ? 0 : max(0.0001, b.amount)
        let wb = b.leaveWeight
        let k = wb / (wa + wb)
        return (CGPoint(x: here.x + (there.x - here.x) * k, y: here.y + (there.y - here.y) * k), k > 0.5 ? other : main)
    }

    func drawHeld(_ p: Prop, props: PropPainter) {
        let a = p.holder.flatMap { holds[$0] }
        let b = p.partner.flatMap { holds[$0] }
        guard let first = a ?? b else {
            drawFree(p, props: props)
            return
        }
        let second = a != nil ? b : nil
        let alpha = CGFloat(min(1, p.alpha)) * min(first.alpha, second?.alpha ?? 1)
        if p.kind == .rope || p.kind == .banner {
            drawLine(p, first, second, alpha: alpha, props: props)
            return
        }
        var t1 = target(p, hold: first)
        var rotation = CGFloat(p.rotation.isFinite ? p.rotation : 0)
        var grounded = t1.spot == .front
        if let second {
            let t2 = target(p, hold: second)
            var mid = CGPoint(x: (t1.centre.x + t2.centre.x) / 2, y: (t1.centre.y + t2.centre.y) / 2)
            if t1.spot == .front, t2.spot == .front, first.face == second.face {
                mid.x = first.face > 0 ? max(t1.centre.x, t2.centre.x) : min(t1.centre.x, t2.centre.x)
            }
            if t1.spot == .overhead || t2.spot == .overhead {
                let dx = t2.centre.x - t1.centre.x, dy = t2.centre.y - t1.centre.y
                var ang = atan2(dy, dx)
                if ang > .pi / 2 { ang -= .pi } else if ang < -.pi / 2 { ang += .pi }
                rotation += max(-0.35, min(0.35, ang))
                t1.centre = CGPoint(x: mid.x, y: max(t1.centre.y, t2.centre.y) - abs(dy) * 0.5)
            } else {
                t1.centre = mid
            }
            grounded = grounded || t2.spot == .front
        } else if t1.spot == .back {
            rotation += PropStage.tilt(first)
        } else if t1.spot == .overhead || t1.spot == .hands || t1.spot == .beneath || t1.spot == .side {
            rotation += PropStage.tilt(first) * 0.6
        }
        if t1.spot == .overhead || t1.spot == .beneath {
            let rel = CGPoint(x: t1.centre.x - first.anchor.x, y: t1.centre.y - first.anchor.y)
            let lag = props.spring(p.id, target: rel)
            t1.centre = CGPoint(x: first.anchor.x + lag.x, y: first.anchor.y + lag.y)
            rotation += max(-0.25, min(0.25, (lag.x - rel.x) / max(4, CGFloat(p.size)) * 1.2))
        } else {
            _ = props.spring(p.id, target: CGPoint(x: t1.centre.x - first.anchor.x, y: t1.centre.y - first.anchor.y))
        }
        if p.kind == .balloon { rotation = PropStage.tilt(first) * 0.3 + sway(p) }
        let ground = second.map { min(first.ground, $0.ground) } ?? first.ground
        let flip: CGFloat = p.kind == .rope || PropStage.round(p.kind) ? 1 : first.face
        let place = PropPlacement(centre: t1.centre, rotation: rotation, flip: flip, alpha: alpha, grounded: grounded, ground: ground)
        let palm = max(1.5, min(0.085 * first.size, 0.16 * CGFloat(p.size)))
        if p.kind == .balloon {
            props.draw(p, place, glows: true)
            let ps = CGFloat(p.size)
            let knot = CGPoint(x: t1.centre.x + sin(rotation) * 0.42 * ps, y: t1.centre.y - cos(rotation) * 0.42 * ps)
            props.mitt(at: knot, palm: palm * 0.85, rot: -1.2 * first.face, face: first.face, alpha: alpha)
            return
        }
        props.draw(p, place, glows: true, grip: t1.spot == .back ? nil : t1.spot, palm: palm)
    }

    static func round(_ k: PropKind) -> Bool {
        k == .snowball || k == .ball
    }

    func ropeEnd(_ hold: FigureHold, _ p: Prop) -> CGPoint {
        let g = hold.blend.gesture
        if p.kind == .banner, g == .carry {
            let t = hold.top
            return CGPoint(x: t.x, y: t.y + CGFloat(p.size) * 0.5)
        }
        return hold.hands
    }

    func drawLine(_ p: Prop, _ first: FigureHold, _ second: FigureHold?, alpha: CGFloat, props: PropPainter) {
        let a = ropeEnd(first, p)
        let b: CGPoint
        var taut = false
        if let second {
            b = ropeEnd(second, p)
            taut = first.blend.gesture == .pull || second.blend.gesture == .pull
        } else if let e = p.end {
            b = e
        } else {
            b = CGPoint(x: a.x + first.face * CGFloat(p.size) * 1.6, y: first.ground + 1)
        }
        let d = hypot(b.x - a.x, b.y - a.y)
        if p.kind == .banner {
            props.drawBanner(p, from: a, to: b, sag: d * (second != nil ? 0.1 : 0.16), alpha: alpha)
            return
        }
        let slack = CGFloat(1 - max(0, min(1, p.progress.isFinite ? p.progress : 1)))
        let wobble = taut ? CGFloat(sin(props.time * 7.3 + Double(p.id))) * 0.01 * d : 0
        let sag = second == nil ? max(CGFloat(p.size) * 0.15, d * 0.18) : (taut ? d * 0.03 + wobble : d * (0.03 + 0.2 * slack))
        props.drawRope(p, from: a, to: b, sag: sag, alpha: alpha, marker: second != nil)
        let ang = atan2(b.y - a.y, b.x - a.x)
        props.mitt(at: a, palm: max(1.6, 0.085 * first.size), rot: ang - .pi / 2, face: 1, alpha: alpha)
        if let second {
            props.mitt(at: b, palm: max(1.6, 0.085 * second.size), rot: ang + .pi / 2, face: -1, alpha: alpha)
        }
    }
}
