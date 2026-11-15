import Foundation
import CoreGraphics
import ScuttleCore

final class PropSprite {
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

struct PropTrack {
    var stage: Int
    var popAt: Double
    var seen: Int
    var offset: CGPoint
    var velocity: CGPoint
    var springAt: Double
    var springOn: Bool
    var peak: Double = 0
    var lastY: CGFloat = .nan
    var lastAt: Double = 0
    var lift: CGFloat = 0
}

struct PropPlacement {
    var centre: CGPoint
    var rotation: CGFloat
    var flip: CGFloat = 1
    var alpha: CGFloat
    var grounded: Bool
    var ground: CGFloat?
}

final class PropPainter {
    static let extent: CGFloat = 1.4
    static let cacheLimit = 24 << 20
    static let flameKind: UInt64 = 40
    static let turnStep: CGFloat = 0.09
    static let tiltStep: CGFloat = 0.045

    var style: ArtStyle = .kawaii
    private(set) var cachedBytes = 0
    private var cache: [UInt64: PropSprite] = [:]
    private var cachedStyle: ArtStyle = .kawaii
    private var clock = 0
    private(set) var ctx: CGContext!
    private(set) var time: Double = 0
    private var lastTime: Double = -.infinity
    private var scale: CGFloat = 2
    private var space = CGColorSpace(name: CGColorSpace.sRGB)!
    private var tracks: [Int: PropTrack] = [:]
    private var lastPrune = 0
    private var glowImages: [Int: CGImage] = [:]
    private var glowBytes = 0
    var shadows = true

    var trackCount: Int { tracks.count }

    func purge() {
        cache.removeAll()
        glowImages.removeAll()
        glowBytes = 0
        cachedBytes = 0
    }

    func begin(_ ctx: CGContext, style: ArtStyle, time: Double, shadows: Bool) {
        self.ctx = ctx
        self.shadows = shadows
        let t = time.isFinite ? time : 0
        if t < lastTime - 0.5 { tracks.removeAll(keepingCapacity: true) }
        self.time = t
        clock &+= 1
        let m = ctx.ctm
        let s = max(1, min(6, (m.a * m.a + m.b * m.b).squareRoot()))
        let rounded = (s * 2).rounded() / 2
        var cs = CGColorSpace(name: CGColorSpace.sRGB)!
        if let c = ctx.colorSpace, c.model == .rgb, c.supportsOutput { cs = c }
        if rounded != scale || !CFEqual(cs, space) || style != cachedStyle {
            scale = rounded
            space = cs
            cachedStyle = style
            purge()
        }
        self.style = style
        if cachedBytes > PropPainter.cacheLimit {
            let cutoff = clock - 240
            for (key, sprite) in cache where sprite.used < cutoff {
                cachedBytes -= sprite.bytes
                cache.removeValue(forKey: key)
            }
            if cachedBytes > PropPainter.cacheLimit { purge() }
        }
        if clock &- lastPrune > 200 || tracks.count > 512 {
            lastPrune = clock
            let cutoff = clock &- 120
            tracks = tracks.filter { $0.value.seen > cutoff }
        }
    }

    func end() {
        lastTime = time
        ctx = nil
    }

    static func bucket(_ size: CGFloat) -> Int {
        max(4, min(400, Int((size / 2).rounded()) * 2))
    }

    var boil: Int {
        style == .doodle ? Int((time * 2.5).rounded(.down)) % 3 : 0
    }

    func sprite(_ kind: PropKind, stage: Int, variant: Int, size: CGFloat, turn: Int = 0, mirrored: Bool = false) -> PropSprite? {
        let bucket = PropPainter.bucket(size)
        let k = UInt64(PropKind.allCases.firstIndex(of: kind) ?? 0)
        let b = boil
        let turn = max(-31, min(31, turn))
        var key = PropPainter.key(kind: k, stage: stage, variant: variant, boil: b, bucket: bucket)
        key |= UInt64(turn + 32) << 48 | (mirrored ? 1 << 56 : 0)
        if let hit = cache[key] {
            hit.used = clock
            return hit
        }
        let angle = CGFloat(turn) * (kind == .banner ? PropPainter.turnStep : PropPainter.tiltStep)
        let pivot: CGFloat = kind == .banner ? 94 : 50
        guard let made = render(size: CGFloat(bucket), finish: true, draw: { brush in
            if angle != 0 || mirrored {
                brush.ctx.translateBy(x: 50, y: pivot)
                brush.ctx.rotate(by: angle)
                if mirrored { brush.ctx.scaleBy(x: -1, y: 1) }
                brush.ctx.translateBy(x: -50, y: -pivot)
            }
            PropArt.draw(kind, stage: stage, variant: variant, brush)
        }, boil: b) else { return nil }
        cache[key] = made
        cachedBytes += made.bytes
        return made
    }

    func flameSprite(frame: Int, size: CGFloat, ratio: Int) -> PropSprite? {
        let bucket = PropPainter.bucket(size)
        let key = PropPainter.key(kind: PropPainter.flameKind, stage: ratio, variant: frame, boil: 0, bucket: bucket)
        if let hit = cache[key] {
            hit.used = clock
            return hit
        }
        let widths: [CGFloat] = [44, 58, 74]
        guard let made = render(size: CGFloat(bucket), finish: style == .sticker, draw: { brush in
            PropArt.flame(brush, cx: 50, base: 10, w: widths[max(0, min(2, ratio))], h: 80, frame: frame)
        }, boil: frame % 3) else { return nil }
        cache[key] = made
        cachedBytes += made.bytes
        return made
    }

    static func key(kind: UInt64, stage: Int, variant: Int, boil: Int, bucket: Int) -> UInt64 {
        var key = kind
        key = key << 4 | UInt64(stage & 0xf)
        key = key << 4 | UInt64(variant & 0xf)
        key = key << 2 | UInt64(boil & 0x3)
        key = key << 12 | UInt64(bucket & 0xfff)
        return key
    }

    func finish() -> SpriteFinish {
        switch style {
        case .kawaii: return SpriteFinish(shadowBlur: 3, shadowMinPt: 1.1, shadowDrop: 0.8, shadowTone: Tone(0x4a2f66, 0.55))
        case .sticker:
            return SpriteFinish(border: 3.8, borderMinPt: 1.3, borderTone: .white, shadowBlur: 4, shadowMinPt: 1.2, shadowDrop: 2, shadowTone: Tone(0x000000, 0.42))
        case .hose: return SpriteFinish(border: 2, borderMinPt: 0.8, borderTone: Tone(0xf7eedb))
        case .mascot: return SpriteFinish(border: 1.8, borderMinPt: 0.75, borderTone: Tone(0xf2efff, 0.9))
        case .doodle: return SpriteFinish(shadowBlur: 2, shadowMinPt: 0.8, shadowDrop: 0, shadowTone: Tone(0x1a1020, 0.3))
        }
    }

    func render(size: CGFloat, finish useFinish: Bool, draw: (PropBrush) -> Void, boil: Int) -> PropSprite? {
        let side = Int((2 * PropPainter.extent * size * scale).rounded(.up))
        let info = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard side > 0, side < 4096,
              let c = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: info)
        else { return nil }
        let unit = size * scale
        let designPx = unit / 100
        c.translateBy(x: CGFloat(side) / 2, y: CGFloat(side) / 2)
        c.scaleBy(x: designPx, y: designPx)
        c.translateBy(x: -50, y: -50)
        draw(PropBrush(c, style: style, size: size, boil: boil))
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
        let fin = finish()
        if useFinish, !fin.isEmpty, let done = fin.apply(to: image, designPx: designPx, scale: scale, space: space) {
            image = done.image
            pad = CGFloat(done.pad)
        }
        image = owned(image)
        let half = CGFloat(side) / 2
        let rect = CGRect(
            x: (crop.minX - pad - half) / unit, y: (half - crop.maxY - pad) / unit,
            width: CGFloat(image.width) / unit, height: CGFloat(image.height) / unit)
        return PropSprite(image: image, rect: rect, bytes: image.width * image.height * 4, used: clock)
    }

    func owned(_ image: CGImage) -> CGImage {
        let w = image.width, h = image.height
        let info = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let row = w * 4
        guard w > 0, h > 0,
              let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: row, space: space, bitmapInfo: info)
        else { return image }
        c.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let base = c.data else { return image }
        let data = Data(bytes: base, count: row * h) as CFData
        guard let provider = CGDataProvider(data: data),
              let made = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: row, space: space,
                                 bitmapInfo: CGBitmapInfo(rawValue: info), provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
        else { return image }
        return made
    }

    func track(_ p: Prop, stage: Int, y: CGFloat? = nil) -> PropTrack {
        let progress = p.progress.isFinite ? p.progress : 1
        if var tr = tracks[p.id] {
            if stage != tr.stage {
                if stage > tr.stage { tr.popAt = time }
                tr.stage = stage
            }
            tr.seen = clock
            tr.peak = max(tr.peak, progress)
            if let y {
                let dt = time - tr.lastAt
                if dt > 0, dt < 0.25, tr.lastY.isFinite {
                    let speed = abs(y - tr.lastY) / CGFloat(dt)
                    tr.lift = max(speed, tr.lift * CGFloat(exp(-dt * 4)))
                } else if dt >= 0.25 {
                    tr.lift = 0
                }
                tr.lastY = y
                tr.lastAt = time
            }
            tracks[p.id] = tr
            return tr
        }
        var tr = PropTrack(stage: stage, popAt: -.infinity, seen: clock, offset: .zero, velocity: .zero, springAt: time, springOn: false)
        tr.peak = progress
        tr.lastY = y ?? .nan
        tr.lastAt = time
        tracks[p.id] = tr
        return tr
    }

    func spring(_ id: Int, target: CGPoint) -> CGPoint {
        guard var tr = tracks[id] else { return target }
        let dt = time - tr.springAt
        if !tr.springOn || dt > 0.25 || dt < 0 {
            tr.offset = target
            tr.velocity = .zero
            tr.springOn = true
            tr.springAt = time
            tracks[id] = tr
            return target
        }
        var left = dt
        let w: CGFloat = 17, z: CGFloat = 0.42
        while left > 1e-6 {
            let h = CGFloat(min(left, 1.0 / 120))
            let ax = w * w * (target.x - tr.offset.x) - 2 * z * w * tr.velocity.x
            let ay = w * w * (target.y - tr.offset.y) - 2 * z * w * tr.velocity.y
            tr.velocity.x += ax * h
            tr.velocity.y += ay * h
            tr.offset.x += tr.velocity.x * h
            tr.offset.y += tr.velocity.y * h
            left -= Double(h)
        }
        tr.springAt = time
        tracks[id] = tr
        return tr.offset
    }

    func glow(radius: CGFloat, level: Int) -> CGImage? {
        let n = max(8, min(640, Int((2 * radius * scale / 8).rounded()) * 8))
        let key = n << 6 | (level & 63)
        if let hit = glowImages[key] { return hit }
        let strength = CGFloat(level) / 40
        let info = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard let c = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: info) else { return nil }
        let comps: [CGFloat] = [1, 0.78, 0.42, strength, 1, 0.62, 0.3, 0.42 * strength, 1, 0.5, 0.2, 0.12 * strength, 1, 0.45, 0.2, 0]
        guard let g = CGGradient(colorSpace: space, colorComponents: comps, locations: [0, 0.3, 0.65, 1], count: 4) else { return nil }
        let mid = CGPoint(x: CGFloat(n) / 2, y: CGFloat(n) / 2)
        c.drawRadialGradient(g, startCenter: mid, startRadius: 0, endCenter: mid, endRadius: CGFloat(n) / 2, options: [])
        guard let made = c.makeImage().map(owned) else { return nil }
        if glowBytes > 8 << 20 || glowImages.count > 64 {
            glowImages.removeAll()
            glowBytes = 0
        }
        glowImages[key] = made
        glowBytes += n * n * 4
        return made
    }

    func contact(width: CGFloat, level: Int) -> CGImage? {
        let w = max(8, min(400, Int((width * scale / 4).rounded()) * 4))
        let key = 1 << 30 | w << 6 | (level & 63)
        if let hit = glowImages[key] { return hit }
        let h = max(4, Int((CGFloat(w) * 0.2).rounded()))
        let info = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: info) else { return nil }
        let a = CGFloat(level) / 40
        let comps: [CGFloat] = [0.05, 0.04, 0.12, a, 0.05, 0.04, 0.12, a * 0.8, 0.05, 0.04, 0.12, 0]
        guard let g = CGGradient(colorSpace: space, colorComponents: comps, locations: [0, 0.6, 1], count: 3) else { return nil }
        c.translateBy(x: CGFloat(w) / 2, y: CGFloat(h) / 2)
        c.scaleBy(x: 1, y: CGFloat(h) / CGFloat(w))
        c.drawRadialGradient(g, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: CGFloat(w) / 2, options: [])
        guard let made = c.makeImage().map(owned) else { return nil }
        if glowBytes > 8 << 20 || glowImages.count > 96 {
            glowImages.removeAll()
            glowBytes = 0
        }
        glowImages[key] = made
        glowBytes += w * h * 4
        return made
    }

    func blit(_ image: CGImage, origin: CGPoint) {
        let d = ctx.convertToDeviceSpace(origin)
        let snapped = ctx.convertToUserSpace(CGPoint(x: d.x.rounded(), y: d.y.rounded()))
        ctx.draw(image, in: CGRect(x: snapped.x, y: snapped.y, width: CGFloat(image.width) / scale, height: CGFloat(image.height) / scale))
    }

    func flicker(_ id: Int, _ k: Int) -> CGFloat {
        let s = Double(id % 97) * 1.37 + Double(k) * 2.1
        return CGFloat(0.82 + 0.1 * sin(time * 9.3 + s) + 0.08 * sin(time * 23.7 + s * 1.7))
    }

    func transform(_ p: Prop, _ place: PropPlacement, squash: (sx: CGFloat, sy: CGFloat)) -> CGAffineTransform {
        let size = CGFloat(p.size)
        let foot = -0.46 * size
        return CGAffineTransform(translationX: place.centre.x, y: place.centre.y)
            .rotated(by: place.rotation)
            .translatedBy(x: 0, y: foot)
            .scaledBy(x: squash.sx * place.flip, y: squash.sy)
            .translatedBy(x: 0, y: -foot)
    }

    func squash(_ p: Prop, _ tr: PropTrack) -> (sx: CGFloat, sy: CGFloat) {
        var sx: CGFloat = 1, sy: CGFloat = 1
        let age = CGFloat(p.age.isFinite ? p.age : 1)
        if age < 0.32 {
            let k = max(0.02, GestureMotion.backOut(age / 0.32, 2.4))
            sx *= k
            sy *= k
        }
        let since = CGFloat(time - tr.popAt)
        if since >= 0, since < 0.6 {
            let a = 0.2 * exp(-since * 6) * sin(since * 19)
            sy *= 1 + a
            sx *= 1 - a * 0.7
        }
        return (sx, sy)
    }

    func drawGlows(_ p: Prop, _ place: PropPlacement, stage: Int) {
        let list = PropArt.glows(p.kind, stage: stage)
        guard !list.isEmpty else { return }
        let size = CGFloat(p.size)
        let t = transform(p, place, squash: (1, 1))
        for (k, g) in list.enumerated() {
            let c = CGPoint(x: (g.x - 50) / 100 * size, y: (g.y - 50) / 100 * size).applying(t)
            let a = min(1, g.strength * 1.15 * (0.55 + 0.45 * flicker(p.id, k + 3)))
            guard let image = glow(radius: g.r / 100 * size, level: max(1, min(40, Int((a * 40).rounded())))) else { continue }
            let r = CGFloat(image.width) / scale / 2
            ctx.saveGState()
            if place.alpha < 0.995 { ctx.setAlpha(place.alpha) }
            blit(image, origin: CGPoint(x: c.x - r, y: c.y - r))
            ctx.restoreGState()
        }
    }

    func mitt(at c: CGPoint, palm: CGFloat, rot: CGFloat, face: CGFloat, alpha: CGFloat) {
        guard alpha > 0.01, palm > 0.5 else { return }
        let pen = GesturePen(ctx, style: style, size: palm / 0.11, time: time)
        let tone: Tone
        switch style {
        case .kawaii: tone = Tone(0xfff1e8)
        case .hose: tone = GesturePen.hoseCream
        case .doodle: tone = Tone(0xfff6ea)
        default: tone = .white
        }
        ctx.saveGState()
        ctx.translateBy(x: c.x, y: c.y)
        ctx.rotate(by: rot)
        ctx.scaleBy(x: face, y: 1)
        ctx.setLineJoin(.round)
        ctx.setLineCap(.round)
        pen.shape(GesturePen.ring(CGPoint(x: -palm * 0.85, y: -palm * 0.1), palm * 0.42, palm * 0.6, n: 8, rot: 0.6), tone, alpha: alpha, w: 0.8, seed: 1)
        pen.shape(GesturePen.ring(.zero, palm, palm * 1.08, n: 10), tone, alpha: alpha, w: 0.8, seed: 2)
        ctx.restoreGState()
    }

    func grips(_ spot: HoldSpot, rect r: CGRect) -> [(CGPoint, CGFloat, CGFloat)] {
        switch spot {
        case .overhead:
            return [(CGPoint(x: r.minX + 0.1, y: r.minY + 0.14), -0.5, -1), (CGPoint(x: r.maxX - 0.1, y: r.minY + 0.14), 0.5, 1)]
        case .beneath:
            return [(CGPoint(x: r.minX + 0.12, y: r.maxY - 0.14), -2.4, -1), (CGPoint(x: r.maxX - 0.12, y: r.maxY - 0.14), 2.4, 1)]
        case .front:
            return [(CGPoint(x: r.minX + 0.07, y: r.minY + r.height * 0.62), -1.3, 1), (CGPoint(x: r.minX + 0.05, y: r.minY + r.height * 0.36), -1.7, 1)]
        case .hands, .side:
            return [(CGPoint(x: r.minX + 0.06, y: r.midY), -1.4, 1)]
        case .back:
            return []
        }
    }

    func draw(_ p: Prop, _ place: PropPlacement, glows drawGlowsHere: Bool, grip: HoldSpot? = nil, palm: CGFloat = 0) {
        let size = CGFloat(p.size)
        guard size > 1, size < 600, place.alpha > 0.01, place.centre.x.isFinite, place.centre.y.isFinite, place.rotation.isFinite else { return }
        var stage = PropArt.stage(p.kind, progress: p.progress)
        let variant = PropArt.variant(p.kind, p.variant)
        let tr = track(p, stage: stage, y: place.grounded && place.ground == nil ? place.centre.y : nil)
        if p.kind == .leafPile, tr.peak - p.progress > 0.18, p.progress < 0.95 { stage = 5 }
        if drawGlowsHere { drawGlows(p, place, stage: stage) }
        guard let sprite = sprite(p.kind, stage: stage, variant: variant, size: size) else { return }
        let sq = squash(p, tr)
        let t = transform(p, place, squash: sq)
        if shadows, place.grounded {
            let w = sprite.rect.width * size * 0.82 * sq.sx
            let gy = place.ground ?? (place.centre.y - 0.46 * size)
            let lift = max(0, (place.centre.y - 0.46 * size) - gy)
            let k = max(0.4, 1 - lift / max(1, size))
            let air = place.ground == nil ? max(0, 1 - tr.lift / max(8, size * 2.5)) : 1
            let level = max(0, min(40, Int((0.26 * place.alpha * k * air * 40).rounded())))
            if level > 0,
               let image = contact(width: w * k * 1.08, level: level) {
                let iw = CGFloat(image.width) / scale, ih = CGFloat(image.height) / scale
                blit(image, origin: CGPoint(x: place.centre.x - iw / 2, y: gy - ih / 2))
            }
        }
        ctx.saveGState()
        if place.alpha < 0.995 { ctx.setAlpha(place.alpha) }
        let r = sprite.rect
        let tilt = Int((place.rotation / PropPainter.tiltStep).rounded())
        if sq.sx == 1, sq.sy == 1, abs(tilt) <= 16, abs(place.flip) == 1,
           let turned = tilt == 0 && place.flip == 1 ? sprite : self.sprite(p.kind, stage: stage, variant: variant, size: size, turn: tilt, mirrored: place.flip < 0) {
            let fs = CGFloat(PropPainter.bucket(size))
            let q = turned.rect
            if tilt == 0 {
                blit(turned.image, origin: CGPoint(x: place.centre.x + q.minX * fs, y: place.centre.y + (q.minY + 0.46) * fs - 0.46 * size))
            } else {
                blit(turned.image, origin: CGPoint(x: place.centre.x + q.minX * fs, y: place.centre.y + q.minY * fs))
            }
        } else {
            ctx.concatenate(t)
            ctx.draw(sprite.image, in: CGRect(x: r.minX * size, y: r.minY * size, width: r.width * size, height: r.height * size))
        }
        ctx.restoreGState()
        drawFlames(p, t, stage: stage, alpha: place.alpha)
        if let grip, palm > 0.5 {
            var upright = place
            upright.rotation = 0
            let ut = transform(p, upright, squash: sq)
            for g in grips(grip, rect: sprite.rect) {
                let c = CGPoint(x: g.0.x * size, y: g.0.y * size).applying(ut)
                mitt(at: c, palm: palm, rot: g.1 * place.flip, face: g.2 * place.flip, alpha: place.alpha)
            }
        }
        let since = time - tr.popAt
        if since >= 0, since < 0.5 {
            sparkle(p, t, age: CGFloat(since), alpha: place.alpha)
        }
    }

    func drawFlames(_ p: Prop, _ t: CGAffineTransform, stage: Int, alpha: CGFloat) {
        let list = PropArt.flames(p.kind, stage: stage)
        guard !list.isEmpty else { return }
        let size = CGFloat(p.size)
        let frames = PropArt.flameFrames()
        for (k, fl) in list.enumerated() {
            let h = fl.h / 100 * size
            guard h > 1.5 else { continue }
            let ratio = fl.w / fl.h
            let cls = ratio < 0.64 ? 0 : (ratio < 0.8 ? 1 : 2)
            let flameSize = h / 0.8
            let frame = (Int((time * 8.5).rounded(.down)) + p.id &* 7 + k * 3) % frames
            guard let sprite = flameSprite(frame: (frame + frames) % frames, size: flameSize, ratio: cls) else { continue }
            let fs = CGFloat(PropPainter.bucket(flameSize))
            let base = CGPoint(x: (fl.x - 50) / 100 * size, y: (fl.base - 50) / 100 * size)
            let r = sprite.rect
            ctx.saveGState()
            if alpha < 0.995 { ctx.setAlpha(alpha) }
            if t.a == 1, t.b == 0, t.c == 0, t.d == 1 {
                let foot = base.applying(t)
                blit(sprite.image, origin: CGPoint(x: foot.x + r.minX * fs, y: foot.y + (r.minY + 0.4) * fs))
            } else {
                let wob = 1 + 0.08 * sin(CGFloat(time) * 13 + CGFloat(k) * 1.9 + CGFloat(p.id))
                ctx.concatenate(t.translatedBy(x: base.x, y: base.y).scaledBy(x: flameSize / fs * (2 - wob), y: flameSize / fs * wob).translatedBy(x: 0, y: 0.4 * fs))
                ctx.draw(sprite.image, in: CGRect(x: r.minX * fs, y: r.minY * fs, width: r.width * fs, height: r.height * fs))
            }
            ctx.restoreGState()
        }
        if p.kind == .campfire, stage >= 3 {
            let base = CGPoint(x: 0, y: (30 - 50) / 100 * size).applying(t)
            for i in 0..<4 {
                let s = Double(p.id % 31) + Double(i) * 1.7
                let u = CGFloat((time * 0.6 + s * 0.37).truncatingRemainder(dividingBy: 1))
                let x = base.x + size * 0.18 * sin(CGFloat(s) * 3.1 + u * 4)
                let y = base.y + size * (0.2 + 0.9 * u)
                let r = max(0.6, size * 0.018) * (1 - u * 0.6)
                ctx.setFillColor(red: 1, green: 0.72 - 0.3 * u, blue: 0.3, alpha: alpha * (1 - u) * 0.9)
                ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r))
            }
        }
    }

    func sparkle(_ p: Prop, _ t: CGAffineTransform, age: CGFloat, alpha: CGFloat) {
        let size = CGFloat(p.size)
        let pen = GesturePen(ctx, style: style, size: max(10, size * 0.5), time: time)
        let tw = sin(min(1, age / 0.5) * .pi)
        let centre = CGPoint(x: 0, y: 0.05 * size).applying(t)
        let tone = pen.tone(Tone(0xffd84a), .cream)
        ctx.saveGState()
        ctx.setLineJoin(.round)
        for k in 0..<4 {
            let a = CGFloat(k) / 4 * 2 * .pi + 0.6 + CGFloat(p.id % 7)
            let d = size * (0.42 + 0.3 * age)
            let c = CGPoint(x: centre.x + cos(a) * d, y: centre.y + sin(a) * d * 0.85)
            let r = max(1.6, size * 0.07) * tw
            pen.shape(GesturePen.star(c, r, points: 4, inner: 0.37, spin: age * 2), tone, alpha: alpha * tw, smooth: style == .kawaii, w: 0.6, seed: k)
        }
        ctx.restoreGState()
    }
}
