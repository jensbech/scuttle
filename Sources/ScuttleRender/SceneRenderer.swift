import Foundation
import CoreGraphics
import CoreText
import ScuttleCore

public struct Scene {
    public var size: CGSize
    public var light: Double
    public var critters: [Critter]
    public var time: Double
    public var props: [Prop]
    public var scale: Double

    public init(size: CGSize, light: Double, critters: [Critter], time: Double, props: [Prop] = [], scale: Double = 1) {
        self.size = size
        self.light = light
        self.critters = critters
        self.time = time
        self.props = props
        self.scale = scale
    }

    public var worldSize: CGSize {
        let k = CGFloat(scale.isFinite && scale > 0.01 ? scale : 1)
        return CGSize(width: size.width / k, height: size.height / k)
    }
}

public struct RenderOptions {
    public var darkness: Bool
    public var hud: String?
    public var maxDarkness: Double
    public var vignette: Double
    public var shadows: Bool
    public var spriteCache: Bool
    public var season: Season?
    public var weather: Weather?
    public var night: Bool
    public var style: ArtStyle

    public init(
        darkness: Bool = true,
        hud: String? = nil,
        maxDarkness: Double = 0.8,
        vignette: Double = 1,
        shadows: Bool = true,
        spriteCache: Bool = true,
        season: Season? = nil,
        weather: Weather? = nil,
        night: Bool = false,
        style: ArtStyle = .kawaii
    ) {
        self.darkness = darkness
        self.hud = hud
        self.maxDarkness = maxDarkness
        self.vignette = vignette
        self.shadows = shadows
        self.spriteCache = spriteCache
        self.season = season
        self.weather = weather
        self.night = night
        self.style = style
    }
}

public final class SceneRenderer {
    private let painter = FigurePainter()
    private let props = PropPainter()
    private let stage = PropStage()
    private let space = CGColorSpace(name: CGColorSpace.sRGB)!
    private var stopColors = [CGFloat](repeating: 0, count: SceneRenderer.stops * 4)
    private var stopLocations = [CGFloat](repeating: 0, count: SceneRenderer.stops)
    private lazy var hudFont: CTFont = CTFontCreateUIFontForLanguage(.userFixedPitch, 11, nil)
        ?? CTFontCreateWithName("Menlo-Regular" as CFString, 11, nil)
    private static let stops = 25

    public init() {}

    public func draw(_ scene: Scene, options: RenderOptions = RenderOptions(), in ctx: CGContext) {
        let light = CGFloat(max(0, min(1, scene.light.isFinite ? scene.light : 1)))
        if options.darkness {
            drawDarkness(1 - light, size: scene.size, options: options, in: ctx)
        }
        if !scene.critters.isEmpty || !scene.props.isEmpty {
            let k = CGFloat(scene.scale.isFinite && scene.scale > 0.01 ? scene.scale : 1)
            var inner = scene
            inner.size = scene.worldSize
            ctx.saveGState()
            if k != 1 { ctx.scaleBy(x: k, y: k) }
            painter.spritesEnabled = options.spriteCache
            painter.style = options.style
            painter.begin(ctx, shadows: options.shadows, time: scene.time, bounds: inner.size)
            props.begin(ctx, style: options.style, time: scene.time, shadows: options.shadows)
            stage.draw(inner, figures: painter, props: props)
            props.end()
            painter.end()
            ctx.restoreGState()
        }
        if let hud = options.hud, !hud.isEmpty {
            drawHUD(hud, size: scene.size, in: ctx)
        }
    }

    public func image(_ scene: Scene, options: RenderOptions = RenderOptions(), scale: CGFloat = 2, background: CGColor? = nil) -> CGImage? {
        let w = Int(scene.size.width * scale), h = Int(scene.size.height * scale)
        guard w > 0, h > 0, let ctx = CGContext(
            data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        if let background {
            ctx.setFillColor(background)
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        }
        ctx.scaleBy(x: scale, y: scale)
        draw(scene, options: options, in: ctx)
        return ctx.makeImage()
    }

    public static func darknessAlpha(light: Double, heightFraction: Double, maxDarkness: Double = 0.8) -> Double {
        let d = 1 - max(0, min(1, light))
        let y = max(0, min(1, heightFraction))
        let reach = 0.85
        var p = d * (1 + reach) - reach * y
        p = max(0, min(1, p))
        p = p * p * p * (p * (p * 6 - 15) + 10)
        let ceiling = maxDarkness * (0.95 - 0.47 * pow(y, 1.25))
        return ceiling * p
    }

    public var spriteCacheBytes: Int { painter.cachedBytes }

    public var propCacheBytes: Int { props.cachedBytes }

    public func purgeCaches() {
        painter.purge()
        props.purge()
        releaseShade()
    }

    public func darknessImage(light: Double, pixelWidth: Int, pixelHeight: Int, options: RenderOptions = RenderOptions()) -> CGImage? {
        let clamped = max(0, min(1, light.isFinite ? light : 1))
        return shadeImage(pw: pixelWidth, ph: pixelHeight, dark: CGFloat(1 - clamped), options: options, space: space)
    }

    private var shadeBuffer: UnsafeMutablePointer<UInt32>?
    private var shadeEdge: [Int32] = []
    private var shadeEdgeWidth = 0
    private var shadeW = 0
    private var shadeH = 0
    private var shadeLevel = -1
    private var shadeMax = -1.0
    private var shadeVignette = -1.0
    private var shadeImageCache: CGImage?
    private var shadeSpace: CGColorSpace?

    deinit {
        shadeBuffer?.deallocate()
    }

    private func releaseShade() {
        shadeImageCache = nil
        shadeBuffer?.deallocate()
        shadeBuffer = nil
        shadeW = 0
        shadeH = 0
        shadeLevel = -1
    }

    private static let bayer: [Float] = [
        0.5, 8.5, 2.5, 10.5,
        12.5, 4.5, 14.5, 6.5,
        3.5, 11.5, 1.5, 9.5,
        15.5, 7.5, 13.5, 5.5,
    ]

    @inline(__always) private static func shadePixel(_ fixed: Int32) -> UInt32 {
        let v = fixed >> 8
        let a = UInt32(truncatingIfNeeded: v < 0 ? 0 : (v > 255 ? 255 : v))
        return (a &<< 24) | ((a &* 5) &>> 8)
    }

    private func shadeImage(pw: Int, ph: Int, dark: CGFloat, options: RenderOptions, space target: CGColorSpace) -> CGImage? {
        guard pw > 0, ph > 0, pw <= 16384, ph <= 16384 else { return nil }
        let level = Int((dark * 2000).rounded())
        if pw == shadeW, ph == shadeH, level == shadeLevel, options.maxDarkness == shadeMax, options.vignette == shadeVignette,
           let cached = shadeImageCache, let cachedSpace = shadeSpace, CFEqual(cachedSpace, target) {
            return cached
        }
        if pw != shadeW || ph != shadeH || shadeBuffer == nil {
            shadeBuffer?.deallocate()
            shadeBuffer = .allocate(capacity: pw * ph)
            shadeW = pw
            shadeH = ph
            let ew = max(4, Int(Double(pw) * 0.24)) & ~3
            shadeEdge = (0..<pw).map { x in
                let near = min(x, pw - 1 - x)
                if near >= ew { return 0 }
                let u = 1 - (Float(near) + 0.5) / Float(ew)
                return Int32(u * u * (3 - 2 * u) * 256)
            }
            shadeEdgeWidth = min(ew, (pw / 2) & ~3)
        }
        guard let buffer = shadeBuffer else { return nil }
        shadeLevel = level
        shadeMax = options.maxDarkness
        shadeVignette = options.vignette
        shadeSpace = target
        let d = Double(level) / 2000
        let light = 1 - d
        let v = max(0, options.vignette) * d * d * (3 - 2 * d) * 0.3
        let ew = shadeEdgeWidth
        let rightStart = max(ew, (pw - ew) & ~3)
        shadeEdge.withUnsafeBufferPointer { edge in
            for r in 0..<ph {
                let y = 1 - (Double(r) + 0.5) / Double(ph)
                let a = SceneRenderer.darknessAlpha(light: light, heightFraction: y, maxDarkness: options.maxDarkness)
                let base = Float(a * 255)
                let gain = Float((1 - a) * v * (0.65 + 0.35 * abs(2 * y - 1)) * 255)
                let row = buffer + r * pw
                let k = (r & 3) * 4
                let baseFP = Int32(base * 256)
                let gainFP = Int32(gain * 256)
                let t0 = baseFP &+ Int32(SceneRenderer.bayer[k] * 16), t1 = baseFP &+ Int32(SceneRenderer.bayer[k + 1] * 16)
                let t2 = baseFP &+ Int32(SceneRenderer.bayer[k + 2] * 16), t3 = baseFP &+ Int32(SceneRenderer.bayer[k + 3] * 16)
                var pattern = (
                    SceneRenderer.shadePixel(t0), SceneRenderer.shadePixel(t1),
                    SceneRenderer.shadePixel(t2), SceneRenderer.shadePixel(t3)
                )
                memset_pattern16(row, &pattern, pw * 4)
                if gain > 0.4 {
                    var x = 0
                    while x < ew {
                        row[x] = SceneRenderer.shadePixel(t0 &+ ((gainFP &* edge[x]) >> 8))
                        row[x + 1] = SceneRenderer.shadePixel(t1 &+ ((gainFP &* edge[x + 1]) >> 8))
                        row[x + 2] = SceneRenderer.shadePixel(t2 &+ ((gainFP &* edge[x + 2]) >> 8))
                        row[x + 3] = SceneRenderer.shadePixel(t3 &+ ((gainFP &* edge[x + 3]) >> 8))
                        x += 4
                    }
                    x = rightStart
                    while x + 4 <= pw {
                        row[x] = SceneRenderer.shadePixel(t0 &+ ((gainFP &* edge[x]) >> 8))
                        row[x + 1] = SceneRenderer.shadePixel(t1 &+ ((gainFP &* edge[x + 1]) >> 8))
                        row[x + 2] = SceneRenderer.shadePixel(t2 &+ ((gainFP &* edge[x + 2]) >> 8))
                        row[x + 3] = SceneRenderer.shadePixel(t3 &+ ((gainFP &* edge[x + 3]) >> 8))
                        x += 4
                    }
                    while x < pw {
                        let tt = x & 3 == 0 ? t0 : (x & 3 == 1 ? t1 : (x & 3 == 2 ? t2 : t3))
                        row[x] = SceneRenderer.shadePixel(tt &+ ((gainFP &* edge[x]) >> 8))
                        x += 1
                    }
                }
            }
        }
        guard let provider = CGDataProvider(dataInfo: nil, data: buffer, size: pw * ph * 4, releaseData: { _, _, _ in }) else { return nil }
        let image = CGImage(
            width: pw, height: ph, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: pw * 4, space: target,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue),
            provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent
        )
        shadeImageCache = image
        return image
    }

    private func drawDarkness(_ dark: CGFloat, size: CGSize, options: RenderOptions, in ctx: CGContext) {
        guard dark > 0.003, size.width > 0, size.height > 0 else { return }
        let m = ctx.ctm
        if abs(m.b) < 1e-9, abs(m.c) < 1e-9, m.a > 0, abs(m.a - m.d) < 1e-6 {
            let pw = Int((size.width * m.a).rounded(.up)), ph = Int((size.height * m.a).rounded(.up))
            var target = space
            if let cs = ctx.colorSpace, cs.model == .rgb, cs.supportsOutput { target = cs }
            if let image = shadeImage(pw: pw, ph: ph, dark: dark, options: options, space: target) {
                let ox = (m.tx.rounded() - m.tx) / m.a, oy = (m.ty.rounded() - m.ty) / m.a
                ctx.draw(image, in: CGRect(x: ox, y: oy + size.height - CGFloat(ph) / m.a, width: CGFloat(pw) / m.a, height: CGFloat(ph) / m.a))
                return
            }
        }
        drawDarknessGradient(dark, size: size, options: options, in: ctx)
    }

    private func drawDarknessGradient(_ dark: CGFloat, size: CGSize, options: RenderOptions, in ctx: CGContext) {
        let n = SceneRenderer.stops
        let light = Double(1 - dark)
        for i in 0..<n {
            let y = Double(i) / Double(n - 1)
            let a = SceneRenderer.darknessAlpha(light: light, heightFraction: y, maxDarkness: options.maxDarkness)
            stopColors[i * 4] = 0
            stopColors[i * 4 + 1] = 0
            stopColors[i * 4 + 2] = 0.02
            stopColors[i * 4 + 3] = CGFloat(a)
            stopLocations[i] = CGFloat(y)
        }
        guard let gradient = CGGradient(colorSpace: space, colorComponents: stopColors, locations: stopLocations, count: n) else { return }
        ctx.saveGState()
        ctx.clip(to: CGRect(origin: .zero, size: size))
        ctx.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: size.height), options: [])
        ctx.restoreGState()
    }

    private func drawHUD(_ text: String, size: CGSize, in ctx: CGContext) {
        let white = CGColor(red: 1, green: 1, blue: 1, alpha: 0.94)
        let attributes = [
            kCTFontAttributeName as String: hudFont,
            kCTForegroundColorAttributeName as String: white,
        ] as CFDictionary
        var lines: [CTLine] = []
        var width: CGFloat = 0
        var ascent: CGFloat = 0, descent: CGFloat = 0, leading: CGFloat = 0
        for part in text.split(separator: "\n", omittingEmptySubsequences: false) {
            guard let attributed = CFAttributedStringCreate(nil, String(part) as CFString, attributes) else { continue }
            let line = CTLineCreateWithAttributedString(attributed)
            var a: CGFloat = 0, d: CGFloat = 0, l: CGFloat = 0
            let lw = CGFloat(CTLineGetTypographicBounds(line, &a, &d, &l))
            width = max(width, lw)
            ascent = max(ascent, a)
            descent = max(descent, d)
            leading = max(leading, l)
            lines.append(line)
        }
        guard !lines.isEmpty else { return }
        let lineHeight = ceil(ascent + descent + leading + 2)
        let padX: CGFloat = 9, padY: CGFloat = 5, margin: CGFloat = 12
        let boxW = ceil(width) + padX * 2
        let boxH = lineHeight * CGFloat(lines.count) + padY * 2
        let box = CGRect(x: margin, y: size.height - margin - boxH, width: boxW, height: boxH)
        ctx.saveGState()
        let radius = min(11, boxH / 2)
        ctx.addPath(CGPath(roundedRect: box, cornerWidth: radius, cornerHeight: radius, transform: nil))
        ctx.setFillColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 0.62)
        ctx.fillPath()
        ctx.textMatrix = .identity
        var baseline = box.maxY - padY - ascent - 1
        for line in lines {
            ctx.textPosition = CGPoint(x: box.minX + padX, y: baseline)
            CTLineDraw(line, ctx)
            baseline -= lineHeight
        }
        ctx.restoreGState()
    }
}
