import Foundation
import CoreGraphics
import ScuttleCore

final class FigureSprite {
    let image: CGImage
    let rect: CGRect
    let bytes: Int
    var used: Int

    init(image: CGImage, rect: CGRect, bytes: Int, used: Int) {
        self.image = image
        self.rect = rect
        self.bytes = bytes
        self.used = used
    }
}

struct FigureHold {
    var id: Int
    var place: CGAffineTransform
    var rect: CGRect
    var size: CGFloat
    var face: CGFloat
    var anchor: CGPoint
    var ground: CGFloat
    var alpha: CGFloat
    var flying: Bool
    var blend: GestureBlend
    var species: Species = .hedgehog
    var centre: CGPoint { at(rect.midX, rect.midY) }

    func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: x * size, y: y * size).applying(place)
    }

    var top: CGPoint { at(rect.midX, rect.maxY - 0.08) }
    var bottom: CGPoint { at(rect.midX, rect.minY + 0.06) }
    var hands: CGPoint { at(rect.maxX * 0.82, rect.minY + rect.height * 0.5) }
    var shove: CGPoint { at(rect.maxX * 0.9, rect.minY + rect.height * 0.32) }
}

struct FigurePose {
    var raise: CGFloat = 0
    var angle: CGFloat = 0
    var pivot: CGFloat = 0
    var flip: CGFloat = 1
    var stretch: CGFloat = 1
    var grounded = true
    var height: CGFloat = 0
}

final class FigurePainter {
    static let extent: CGFloat = 1.4
    static let cacheLimit = 160 << 20
    static let ground: CGFloat = -0.46

    var spritesEnabled = true
    var style: ArtStyle = .kawaii
    private(set) var cachedBytes = 0
    private var cache: [UInt64: FigureSprite] = [:]
    private var cachedStyle: ArtStyle = .kawaii
    private var clock = 0
    private var ctx: CGContext!
    private var shadows = true
    private var time: Double = 0
    private var bounds: CGSize = .zero
    private var gestures = GestureMemory()
    private let stamps = GestureStamps()
    private var scale: CGFloat = 2
    private var spriteSpace = CGColorSpace(name: CGColorSpace.sRGB)!

    func purge() {
        cache.removeAll()
        cachedBytes = 0
        stamps.purge()
    }

    private func evictIfNeeded() {
        guard cachedBytes > FigurePainter.cacheLimit else { return }
        let cutoff = clock - 240
        for (key, sprite) in cache where sprite.used < cutoff {
            cachedBytes -= sprite.bytes
            cache.removeValue(forKey: key)
        }
        if cachedBytes > FigurePainter.cacheLimit { purge() }
    }

    func begin(_ ctx: CGContext, shadows: Bool, time: Double = 0, bounds: CGSize = .zero) {
        self.ctx = ctx
        self.shadows = shadows
        self.time = time.isFinite ? time : 0
        self.bounds = bounds
        clock &+= 1
        gestures.begin(time: self.time, clock: clock)
        let m = ctx.ctm
        let s = max(1, min(6, (m.a * m.a + m.b * m.b).squareRoot()))
        let rounded = (s * 2).rounded() / 2
        var space = CGColorSpace(name: CGColorSpace.sRGB)!
        if let cs = ctx.colorSpace, cs.model == .rgb, cs.supportsOutput { space = cs }
        if rounded != scale || !CFEqual(space, spriteSpace) || style != cachedStyle {
            scale = rounded
            spriteSpace = space
            cachedStyle = style
            purge()
        }
        evictIfNeeded()
        stamps.prepare(scale: scale, space: spriteSpace, style: style)
        ctx.saveGState()
        ctx.interpolationQuality = .low
    }

    func end() {
        ctx.restoreGState()
        ctx = nil
    }

    static func mood(for c: Critter) -> Mood {
        if c.confusion > 0.5 { return .dizzy }
        switch c.mode {
        case .startled: return .startled
        case .fleeing: return .fleeing
        case .resting: return .sleepy
        default: return .calm
        }
    }

    static func idle(_ antennaPhase: Double) -> (blink: Bool, twitch: CGFloat) {
        let ap = antennaPhase.isFinite ? antennaPhase : 0
        let cycle = ap / 17
        let blink = cycle - cycle.rounded(.down) < 0.035
        let s = sin(ap)
        let twitch: CGFloat = s > 0.55 ? 1 : (s < -0.55 ? -1 : 0)
        return (blink, twitch)
    }

    static func frame(for c: Critter, style: ArtStyle, size: CGFloat) -> FigureFrame {
        let g = c.gaitPhase.isFinite ? c.gaitPhase : 0
        let frac = g - g.rounded(.down)
        let index = Int(frac * Double(FigureFrame.frames)) % FigureFrame.frames
        let tint = max(0, min(0.999, c.tint.isFinite ? c.tint : 0.5))
        let lift = max(0, min(1, c.lift.isFinite ? c.lift : 0))
        let step = (lift * Double(FigureFrame.liftSteps)).rounded() / Double(FigureFrame.liftSteps)
        let mood = mood(for: c)
        let life = idle(c.antennaPhase)
        return FigureFrame(
            species: c.species,
            style: style,
            variant: Int(tint * Double(FigureFrame.variants)),
            phase: CGFloat(index) / CGFloat(FigureFrame.frames),
            mood: mood,
            lift: CGFloat(step),
            blink: life.blink && mood != .sleepy,
            twitch: life.twitch,
            size: size)
    }

    static func pose(for c: Critter, frame f: FigureFrame) -> FigurePose {
        var pose = FigurePose()
        let size = CGFloat(c.size)
        let heading = CGFloat(c.heading.isFinite ? c.heading : 0)
        let ap = CGFloat(c.antennaPhase.isFinite ? c.antennaPhase : 0)
        let gp = CGFloat(c.gaitPhase.isFinite ? c.gaitPhase : 0)
        let wave = gp * 2 * .pi
        let seed = CGFloat(c.id % 97) * 1.7
        let up = sin(heading)
        let moving = c.speed > c.size * 0.15
        let fleeing = c.mode == .fleeing
        pose.flip = c.facing < 0 ? -1 : 1
        pose.pivot = ground
        switch c.species.locomotion {
        case .crawl:
            pose.angle = moving ? 0.2 * up : 0
            pose.stretch = 1 + 0.02 * sin(ap * 0.35)
        case .walk:
            let lean: CGFloat = fleeing ? 0.16 : (moving ? 0.05 : 0)
            let roll: CGFloat = moving ? 0.035 * sin(wave) : 0
            pose.angle = -lean + roll
            pose.stretch = 1 + 0.025 * sin(ap * 0.35)
        case .hop:
            pose.raise = f.lift * size * 0.55
            pose.angle = f.airborne ? 0.16 * (1 - 2 * f.air) : 0
            pose.stretch = f.airborne ? 1 : 1 + 0.02 * sin(ap * 0.35)
        case .flutter:
            pose.grounded = false
            pose.pivot = 0
            pose.height = 0.34
            pose.raise = 0.07 * size * cos(wave)
            pose.angle = 0.28 * up + 0.07 * sin(ap * 0.4 + seed)
        case .hover:
            pose.grounded = false
            pose.pivot = 0
            pose.height = 0.3
            let level = c.species == .ufo
            pose.raise = (level ? 0.07 : 0.05) * size * sin(ap * 0.3 + seed)
            pose.angle = level ? 0 : (moving ? -0.14 : 0) + 0.12 * up
        case .float:
            pose.grounded = false
            pose.pivot = 0
            pose.height = 0.28
            let amp: CGFloat
            switch c.species {
            case .leaf: amp = 0.34
            case .cloud: amp = 0.03
            case .sun: amp = 0.05
            case .balloon: amp = 0.12
            default: amp = 0.1
            }
            pose.raise = 0.05 * size * sin(wave + 1 + seed)
            pose.angle = amp * sin(wave + seed) + (fleeing ? -0.12 : 0) * (c.species == .cloud ? 0.3 : 1)
        case .dart:
            pose.grounded = false
            pose.pivot = 0
            pose.height = 0.3
            if c.species == .rocket || c.species == .comet {
                let dx = cos(heading)
                pose.flip = dx < 0 ? -1 : 1
                var a = pose.flip > 0 ? heading : .pi - heading
                while a > .pi { a -= 2 * .pi }
                while a < -.pi { a += 2 * .pi }
                pose.angle = max(-.pi / 2 - 0.35, min(.pi / 2 + 0.35, a))
            } else {
                pose.angle = max(-0.4, min(0.4, 0.4 * up)) + (moving ? -0.06 : 0)
                pose.raise = 0.03 * size * sin(ap * 0.5 + seed)
            }
        }
        return pose
    }

    private static func index(of species: Species) -> UInt64 {
        UInt64(Species.allCases.firstIndex(of: species) ?? 0)
    }

    private static func index(of style: ArtStyle) -> UInt64 {
        UInt64(ArtStyle.allCases.firstIndex(of: style) ?? 0)
    }

    private func sprite(for f: FigureFrame, bucket: Int) -> FigureSprite? {
        let liftIndex = UInt64((f.lift * CGFloat(FigureFrame.liftSteps)).rounded())
        var key = FigurePainter.index(of: f.style)
        key = key << 6 | FigurePainter.index(of: f.species)
        key = key << 3 | UInt64(f.variant & 0x7)
        key = key << 3 | UInt64(f.mood.rawValue)
        key = key << 4 | UInt64(f.frameIndex)
        key = key << 3 | liftIndex
        key = key << 1 | (f.blink ? 1 : 0)
        key = key << 2 | UInt64(Int(f.twitch) + 1)
        key = key << 12 | UInt64(bucket & 0xfff)
        if spritesEnabled, let hit = cache[key] {
            hit.used = clock
            return hit
        }
        guard let made = FigurePainter.render(f, size: CGFloat(bucket), scale: scale, space: spriteSpace, clock: clock) else { return nil }
        if spritesEnabled {
            cache[key] = made
            cachedBytes += made.bytes
        }
        return made
    }

    static func render(_ f: FigureFrame, size: CGFloat, scale: CGFloat, space: CGColorSpace, clock: Int = 0) -> FigureSprite? {
        let side = Int((2 * extent * size * scale).rounded(.up))
        let info = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard side > 0, side < 4096,
              let c = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: info)
        else { return nil }
        let unit = size * scale
        let designPx = unit / 100
        c.translateBy(x: CGFloat(side) / 2, y: CGFloat(side) / 2)
        c.scaleBy(x: designPx, y: designPx)
        c.translateBy(x: -50, y: -50)
        var frame = f
        frame.size = size
        FigureArt.draw(frame, in: c)
        guard let full = c.makeImage(), let data = c.data else { return nil }
        let rowBytes = c.bytesPerRow
        let pixels = data.assumingMemoryBound(to: UInt8.self)
        var minX = side, maxX = -1, minY = side, maxY = -1
        for y in 0..<side {
            let row = pixels + y * rowBytes
            var first = -1, last = -1
            for x in 0..<side where row[x * 4 + 3] != 0 {
                if first < 0 { first = x }
                last = x
            }
            if first >= 0 {
                minX = min(minX, first)
                maxX = max(maxX, last)
                minY = min(minY, y)
                maxY = max(maxY, y)
            }
        }
        guard maxX >= minX, maxY >= minY else { return nil }
        let crop = CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
        guard var image = full.cropping(to: crop) else { return nil }
        var pad: CGFloat = 0
        let finish = FigureArt.finish(for: f.style)
        if !finish.isEmpty, let done = finish.apply(to: image, designPx: designPx, scale: scale, space: space) {
            image = done.image
            pad = CGFloat(done.pad)
        } else if let tight = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: info) {
            tight.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            if let copy = tight.makeImage() { image = copy }
        }
        let half = CGFloat(side) / 2
        let rect = CGRect(
            x: (crop.minX - pad - half) / unit, y: (half - crop.maxY - pad) / unit,
            width: CGFloat(image.width) / unit, height: CGFloat(image.height) / unit)
        return FigureSprite(image: image, rect: rect, bytes: image.width * image.height * 4, used: clock)
    }

    var gestureTracks: Int { gestures.count }

    private func blendLook(_ c: Critter, _ blend: GestureBlend, face: CGFloat, extent: CGRect? = nil) -> GestureLook {
        var look = GestureLook()
        var input = GestureInput(
            gesture: blend.gesture, t: blend.t, leaving: nil, size: CGFloat(c.size), seed: CGFloat(c.id % 97) * 1.7,
            facing: face, heading: CGFloat(c.heading), position: c.position, bounds: bounds,
            grounded: !c.species.isAirborne, locomotion: c.species.locomotion,
            gait: CGFloat(c.gaitPhase.isFinite ? c.gaitPhase : 0), moving: c.speed > c.size * 0.15)
        if let extent { input.extent = extent }
        if blend.leaving != .none, blend.leaveWeight > 0 {
            var out = input
            out.gesture = blend.leaving
            out.t = blend.leaveT
            out.leaving = blend.leaveProgress
            look.add(GestureMotion.look(out), blend.leaveWeight, base: face)
        }
        if blend.gesture != .none, blend.amount > 0 {
            input.leaving = nil
            look.add(GestureMotion.look(input), blend.amount, base: face)
        }
        return look
    }

    static func drawable(_ c: Critter) -> Bool {
        c.mode != .hidden && c.alpha > 0.01 && c.size > 2 && c.size < 400
            && c.position.x.isFinite && c.position.y.isFinite && c.heading.isFinite
    }

    @discardableResult
    func draw(_ c: Critter) -> FigureHold? {
        guard FigurePainter.drawable(c) else { return nil }
        let size = CGFloat(c.size)
        let bucket = max(4, Int((size / 2).rounded()) * 2)
        let fright = CGFloat(c.fright.isFinite ? max(0, c.fright) : 0)
        let windup = CGFloat(c.windup.isFinite ? max(0, c.windup) : 0)
        let dash = CGFloat(c.dash.isFinite ? max(0, c.dash) : 0)
        let caught = fright > 0 || dash > 0
        let resolved = gestures.resolve(c, time: time, clock: clock)
        let blend = caught ? GestureBlend.idle : resolved
        let baseFace: CGFloat = blend.isIdle ? (c.facing < 0 ? -1 : 1) : blend.face
        var look = GestureLook()
        var src = c
        if !blend.isIdle {
            look = blendLook(c, blend, face: baseFace)
            if let v = look.phase { src.gaitPhase = Double(v) }
            if let v = look.lift { src.lift = Double(v) }
        }
        var f = FigurePainter.frame(for: src, style: style, size: CGFloat(bucket))
        if let m = look.mood, f.mood == .calm || f.mood == .sleepy {
            f.mood = m
            if m != .sleepy, look.blink == nil { f.blink = FigurePainter.idle(c.antennaPhase).blink }
        }
        if let b = look.blink, f.mood != .startled, f.mood != .dizzy { f.blink = b }
        if let tw = look.twitch { f.twitch = tw }
        let natural = c.quirk == .natural && fright > 0.55 && windup == 0
        if natural {
            f.mood = .calm
            f.blink = true
            f.twitch = 0
        }
        guard let sprite = sprite(for: f, bucket: bucket) else { return nil }
        if blend.gesture.reachesEdge || (blend.leaving.reachesEdge && blend.leaveWeight > 0) {
            look = blendLook(c, blend, face: baseFace, extent: sprite.rect)
        }
        let alpha = CGFloat(min(1, c.alpha))
        var pose = FigurePainter.pose(for: src, frame: f)
        var p = c.position
        var widen: CGFloat = 1
        var jump: CGFloat = 0
        let seed = CGFloat(c.id % 97) * 1.7
        let airborne = c.species.isAirborne
        let face: CGFloat = c.facing < 0 ? -1 : 1
        let dirX = CGFloat(cos(c.heading)), dirY = CGFloat(sin(c.heading))
        if fright > 0 {
            var q = CatchMotion.react(age: fright, size: size, airborne: airborne, natural: c.quirk == .natural && windup == 0, seed: seed)
            if windup > 0 {
                q = CatchMotion.windup(windup, size: size, airborne: airborne, slip: c.quirk == .slip)
                q.dx *= face
            }
            jump = q.raise
            pose.raise += q.raise
            pose.stretch *= q.stretch
            pose.angle += q.angle
            widen *= q.sx
            p.x += q.dx
        } else if dash > 0 {
            let q = CatchMotion.dash(dash, size: size, vertical: abs(dirX) < 0.45, airborne: airborne)
            pose.stretch *= q.stretch
            pose.angle += q.angle
            widen *= q.sx
        }

        var flip = pose.flip
        if let face = look.face {
            flip = abs(face) < 0.14 ? (face < 0 ? -0.14 : 0.14) : max(-1, min(1, face))
        }
        if caught {
            let v = CGFloat(c.facing.isFinite ? c.facing : 1)
            flip = abs(v) < 0.3 ? (v < 0 ? -0.3 : 0.3) : max(-1, min(1, v))
        }
        let anchor = CGPoint(x: p.x + look.dx, y: p.y + look.dy)
        var body = CGAffineTransform(translationX: anchor.x, y: anchor.y)
        if look.tilt != 0 {
            body = body.translatedBy(x: look.px, y: look.py).rotated(by: look.tilt).translatedBy(x: -look.px, y: -look.py)
        }
        body = body.translatedBy(x: 0, y: pose.raise + look.rise)
        if look.spin != 0 { body = body.rotated(by: look.spin) }
        let pivot = pose.pivot * size
        let place = body.scaledBy(x: flip, y: 1)
            .translatedBy(x: 0, y: pivot)
            .rotated(by: pose.angle + look.lean)
            .scaledBy(x: max(0.3, 1 + look.sx) * widen / pose.stretch.squareRoot(), y: pose.stretch * max(0.3, 1 + look.sy))
            .translatedBy(x: 0, y: -pivot)
        let lifted = pose.raise + look.rise

        if c.species.isRare {
            sparkles(around: anchor, raise: lifted, size: size, id: c.id, alpha: alpha, front: false)
        }

        let shade = max(0, min(1.5, 1 + look.shadow))
        if shadows, shade > 0.01 {
            if pose.grounded {
                let up = max(f.lift, min(1, max(0, look.rise + jump) / (size * 0.55)))
                let k = 1 - 0.4 * up
                let a = alpha * (0.55 + 0.45 * k) * shade
                let gy = anchor.y + size * FigurePainter.ground
                ctx.setFillColor(red: 0.05, green: 0.04, blue: 0.12, alpha: 0.13 * a)
                ctx.fillEllipse(in: CGRect(x: anchor.x - size * 0.36 * k, y: gy - size * 0.07 * k, width: size * 0.72 * k, height: size * 0.14 * k))
                ctx.setFillColor(red: 0.05, green: 0.04, blue: 0.12, alpha: 0.26 * a)
                ctx.fillEllipse(in: CGRect(x: anchor.x - size * 0.24 * k, y: gy - size * 0.04 * k, width: size * 0.48 * k, height: size * 0.08 * k))
            } else {
                let k = max(0.6, 1 - lifted / size * 2)
                ctx.setFillColor(red: 0.05, green: 0.04, blue: 0.12, alpha: 0.14 * alpha * k * shade)
                let y = anchor.y - size * (0.5 + pose.height)
                ctx.fillEllipse(in: CGRect(x: anchor.x - size * 0.22 * k, y: y - size * 0.04 * k, width: size * 0.44 * k, height: size * 0.08 * k))
            }
        }

        if c.species.locomotion == .dart, c.speed > c.size * 2.5 {
            streak(c, raise: pose.raise, alpha: alpha)
        }

        let groundY = anchor.y + FigurePainter.ground * size - (airborne ? size * (0.04 + pose.height) : 0)
        let fx = caught ? CatchFx(pen: GesturePen(ctx, style: style, size: size, time: time), s: size, alpha: alpha) : nil
        if let fx {
            ctx.saveGState()
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            if fright > 0 {
                fx.pop(at: CGPoint(x: c.position.x, y: c.position.y + size * 0.05), age: fright)
                if !airborne { fx.thump(x: c.position.x, ground: groundY, age: fright) }
                if windup > 0 && !airborne { fx.spin(x: p.x, ground: groundY, w: windup, dirX: abs(dirX) > 0.3 ? (dirX < 0 ? -1 : 1) : face) }
            }
            if dash > 0 {
                fx.dashCloud(from: c.dashFrom, ground: c.dashFrom.y + FigurePainter.ground * size - (airborne ? size * 0.3 : 0), age: dash)
                fx.speedLines(from: CGPoint(x: anchor.x, y: anchor.y + pose.raise), dirX: dirX, dirY: dirY, age: dash, speed: CGFloat(c.speed))
            }
            ctx.restoreGState()
        }

        var props: GestureProps?
        if !blend.isIdle {
            let stage = GestureStage(
                body: body, size: size, face: flip < 0 ? -1 : 1, alpha: alpha, origin: c.position, anchor: anchor,
                seed: CGFloat(c.id % 97) * 1.7, gait: CGFloat(c.gaitPhase.isFinite ? c.gaitPhase : 0), bounds: bounds,
                grounded: pose.grounded, flying: c.species.isAirborne, place: place, rect: sprite.rect,
                moving: c.speed > c.size * 0.15)
            let made = GestureProps(pen: GesturePen(ctx, style: style, size: size, time: time), stage: stage, stamps: stamps)
            drawProps(made, blend, front: false)
            props = made
        }

        ctx.saveGState()
        ctx.setAlpha(alpha)
        ctx.concatenate(place)
        let r = sprite.rect
        ctx.draw(sprite.image, in: CGRect(x: r.minX * size, y: r.minY * size, width: r.width * size, height: r.height * size))
        ctx.restoreGState()

        if let props { drawProps(props, blend, front: true) }

        if c.species.isRare {
            sparkles(around: anchor, raise: lifted, size: size, id: c.id, alpha: alpha, front: true)
        }

        let hold = FigureHold(
            id: c.id, place: place, rect: sprite.rect, size: size, face: flip < 0 ? -1 : 1, anchor: anchor,
            ground: anchor.y + FigurePainter.ground * size, alpha: alpha, flying: c.species.isAirborne, blend: blend,
            species: c.species)
        guard caught || c.confusion > 0.01 else { return hold }
        let a = CGPoint(x: 0, y: 0.5 * size).applying(body), b = CGPoint(x: 0, y: -0.5 * size).applying(body)
        let centre = CGPoint.zero.applying(body)
        var top = max(a.y, b.y, centre.y + 0.1 * size)
        if bounds.height > 0 { top = min(top, bounds.height - size * 0.95 - 8) }
        let marks = props ?? GestureProps(pen: GesturePen(ctx, style: style, size: size, time: time), stage: GestureStage(
            body: body, size: size, face: flip < 0 ? -1 : 1, alpha: alpha, origin: c.position, anchor: anchor,
            seed: 0, gait: 0, bounds: bounds, grounded: pose.grounded, flying: c.species.isAirborne, place: place, rect: sprite.rect), stamps: stamps)
        ctx.saveGState()
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        if let fx, fright > 0 {
            let head = CGPoint(x: centre.x, y: top + size * 0.06)
            let mid = CGPoint(x: centre.x, y: (top + centre.y) / 2)
            var fade = 1 - GestureMotion.smooth(windup / 0.1)
            if c.quirk == .natural { fade *= 1 - GestureMotion.smooth((fright - 0.5) / 0.12) }
            fx.shock(around: mid, age: fright, face: face)
            fx.badge(at: head, age: fright, fade: fade, shake: windup > 0 ? 0 : size * 0.02 * sin(fright * 47 + seed))
            fx.sweat(head: CGPoint(x: centre.x, y: top - size * 0.3), age: fright, face: flip < 0 ? -1 : 1, fade: fade)
            if natural {
                fx.whistle(mouth: CGPoint(x: centre.x + (flip < 0 ? -1 : 1) * size * 0.2, y: centre.y + size * 0.02), age: fright, face: flip < 0 ? -1 : 1, fade: 1 - GestureMotion.smooth(windup / 0.1))
            }
        }
        if c.confusion > 0.01 {
            marks.question(at: CGPoint(x: centre.x, y: top + size * 0.05), phase: CGFloat(c.antennaPhase), amount: CGFloat(min(1, c.confusion)), alpha: alpha)
        }
        ctx.restoreGState()
        return hold
    }

    private func drawProps(_ props: GestureProps, _ blend: GestureBlend, front: Bool) {
        ctx.saveGState()
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        if blend.leaving != .none, blend.leaveWeight > 0 {
            props.draw(blend.leaving, t: blend.leaveT, weight: blend.leaveWeight, leaving: blend.leaveProgress, front: front)
        }
        if blend.gesture != .none {
            props.draw(blend.gesture, t: blend.t, weight: min(1, blend.amount * 1.5), leaving: nil, front: front)
        }
        ctx.restoreGState()
    }

    private func streak(_ c: Critter, raise: CGFloat, alpha: CGFloat) {
        let size = CGFloat(c.size)
        let k = min(1, CGFloat(c.speed / max(1, c.size) - 2.5) / 3)
        guard k > 0.02 else { return }
        let dx = CGFloat(cos(c.heading)), dy = CGFloat(sin(c.heading))
        let nx = -dy, ny = dx
        let base = CGPoint(x: c.position.x - dx * size * 0.45, y: c.position.y + raise - dy * size * 0.45)
        ctx.saveGState()
        ctx.setLineCap(.round)
        for (i, o) in ([-0.2, 0.02, 0.22] as [CGFloat]).enumerated() {
            let len = size * (0.5 + 0.25 * CGFloat(i % 2 == 0 ? 1 : 0)) * k
            let s = CGPoint(x: base.x + nx * o * size, y: base.y + ny * o * size)
            ctx.move(to: s)
            ctx.addLine(to: CGPoint(x: s.x - dx * len, y: s.y - dy * len))
            ctx.setStrokeColor(red: 0.72, green: 0.74, blue: 0.92, alpha: 0.42 * alpha * k)
            ctx.setLineWidth(max(1, size * 0.045))
            ctx.strokePath()
        }
        ctx.restoreGState()
    }

    private func sparkles(around p: CGPoint, raise: CGFloat, size: CGFloat, id: Int, alpha: CGFloat, front: Bool) {
        let count = 3
        let seed = Double(id) * 2.399
        let spin = time * 0.55 + seed
        let rx = size * 0.68 + 3, ry = size * 0.48 + 2
        let cy = p.y + raise + size * 0.04
        for k in 0..<count {
            let ang = spin + Double(k) * 2 * .pi / Double(count) + 0.35 * sin(time * 0.4 + Double(k) * 1.3 + seed)
            let behind = sin(ang) > 0.2
            if behind == front { continue }
            let blink = sin(time * (1.7 + 0.35 * Double(k)) + Double(k) * 2.1 + seed * 1.3)
            let tw = CGFloat(max(0, blink))
            guard tw > 0.05 else { continue }
            let level = tw * tw * (3 - 2 * tw)
            let r = max(1.7, size * 0.07 + 0.5) * (0.55 + 0.45 * level)
            let q = CGPoint(x: p.x + rx * CGFloat(cos(ang)), y: cy + ry * CGFloat(sin(ang)))
            let a = alpha * level * (behind ? 0.55 : 0.95)
            let n = r * 0.16
            ctx.move(to: CGPoint(x: q.x, y: q.y + r))
            ctx.addQuadCurve(to: CGPoint(x: q.x + r, y: q.y), control: CGPoint(x: q.x + n, y: q.y + n))
            ctx.addQuadCurve(to: CGPoint(x: q.x, y: q.y - r), control: CGPoint(x: q.x + n, y: q.y - n))
            ctx.addQuadCurve(to: CGPoint(x: q.x - r, y: q.y), control: CGPoint(x: q.x - n, y: q.y - n))
            ctx.addQuadCurve(to: CGPoint(x: q.x, y: q.y + r), control: CGPoint(x: q.x - n, y: q.y + n))
            ctx.closePath()
            ctx.setFillColor(red: 1, green: 0.93, blue: 0.62, alpha: a)
            ctx.setStrokeColor(red: 0.42, green: 0.3, blue: 0.1, alpha: a * 0.45)
            ctx.setLineWidth(max(0.5, r * 0.14))
            ctx.drawPath(using: .fillStroke)
        }
    }
}
