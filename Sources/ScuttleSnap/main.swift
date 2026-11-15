import Foundation
import CoreGraphics
import CoreText
import ImageIO
import ScuttleCore
import ScuttleRender

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

func makeContext(width: CGFloat, height: CGFloat, scale: CGFloat) -> CGContext {
    guard let ctx = CGContext(
        data: nil, width: Int(width * scale), height: Int(height * scale), bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { fail("could not create bitmap context") }
    ctx.scaleBy(x: scale, y: scale)
    return ctx
}

func writePNG(_ image: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
        fail("could not open \(path) for writing")
    }
    CGImageDestinationAddImage(dest, image, nil)
    if !CGImageDestinationFinalize(dest) { fail("could not write \(path)") }
}

func drawText(_ text: String, at point: CGPoint, size: CGFloat, gray: CGFloat, alpha: CGFloat = 1, in ctx: CGContext) {
    let font = CTFontCreateWithName("Menlo-Regular" as CFString, size, nil)
    let attributes = [
        kCTFontAttributeName as String: font,
        kCTForegroundColorAttributeName as String: CGColor(red: gray, green: gray, blue: gray, alpha: alpha),
    ] as CFDictionary
    guard let attributed = CFAttributedStringCreate(nil, text as CFString, attributes) else { return }
    let line = CTLineCreateWithAttributedString(attributed)
    ctx.textMatrix = .identity
    ctx.textPosition = point
    CTLineDraw(line, ctx)
}

struct Arguments {
    var positional: [String] = []
    var flags: [String: String] = [:]

    static let switches: Set<String> = ["night"]

    init(_ raw: [String]) {
        var i = 0
        while i < raw.count {
            let a = raw[i]
            if a.hasPrefix("--") {
                let key = String(a.dropFirst(2))
                if !Arguments.switches.contains(key), i + 1 < raw.count, !raw[i + 1].hasPrefix("--") {
                    flags[key] = raw[i + 1]
                    i += 2
                } else {
                    flags[key] = "true"
                    i += 1
                }
            } else {
                positional.append(a)
                i += 1
            }
        }
    }

    func double(_ key: String, _ fallback: Double) -> Double {
        flags[key].flatMap(Double.init) ?? fallback
    }

    func int(_ key: String, _ fallback: Int) -> Int {
        flags[key].flatMap(Int.init) ?? fallback
    }

    func size(_ key: String, _ fallback: CGSize) -> CGSize {
        guard let v = flags[key] else { return fallback }
        let parts = v.lowercased().split(separator: "x").compactMap { Double($0) }
        guard parts.count == 2, parts[0] > 0, parts[1] > 0 else { fail("bad --\(key) \(v), expected WxH") }
        return CGSize(width: parts[0], height: parts[1])
    }
}

func seasonFlag(_ args: Arguments) -> Season? {
    guard let name = args.flags["season"] else { return nil }
    if ["off", "none"].contains(name.lowercased()) { return nil }
    guard let season = Season(name: name) else {
        fail("unknown season \(name); expected one of \(Season.allCases.map(\.rawValue).joined(separator: ", ")) or off")
    }
    return season
}

func weatherFlag(_ args: Arguments) -> Weather? {
    guard let name = args.flags["weather"] else { return nil }
    if ["off", "none"].contains(name.lowercased()) { return nil }
    guard let weather = Weather(name: name) else {
        fail("unknown weather \(name); expected one of \(Weather.allCases.map(\.rawValue).joined(separator: ", ")) or off")
    }
    return weather
}

func styleFlag(_ args: Arguments) -> ArtStyle {
    guard let name = args.flags["style"] else { return .kawaii }
    guard let style = ArtStyle(name: name) else {
        fail("unknown style \(name); expected one of \(ArtStyle.allCases.map(\.rawValue).joined(separator: ", "))")
    }
    return style
}

func nightFlag(_ args: Arguments) -> Bool {
    guard let v = args.flags["night"] else { return false }
    return !["false", "0", "no", "off"].contains(v.lowercased())
}

func figureScaleFlag(_ args: Arguments) -> Double {
    max(0.25, min(6, args.double("figure-scale", Tuning.figureScale)))
}

func worldOf(_ size: CGSize, _ k: Double) -> CGSize {
    CGSize(width: size.width / CGFloat(k), height: size.height / CGFloat(k))
}

func darkenFlag(_ args: Arguments, _ fallback: Bool = true) -> Bool {
    guard let v = args.flags["darken"] else { return fallback }
    return !["false", "0", "no", "off"].contains(v.lowercased())
}

func stillWorld(size: CGSize, config: WorldConfig, settle: Double = 14) -> World {
    let world = World(size: size, config: config)
    world.tuning.growthSeconds = 0
    world.settleInDark(seconds: settle)
    return world
}

let figureGroups: [String: [Species]] = [
    "meadow": [.ladybird, .bumblebee, .snail, .chick, .butterfly, .dragonfly, .firefly, .crab, .frog, .sun],
    "woodland": [.hedgehog, .acorn, .toadstool, .leaf, .penguin, .snowman, .snowflake, .robin, .cloud, .owl],
    "festive": [.ghost, .bat, .pumpkin, .spider, .gingerbread, .present, .elf, .reindeer, .blackCat, .santa],
    "party": [.balloon, .star, .sparkler, .rocket, .bunny, .turtle, .fox, .polarBear, .comet, .ufo],
]

func speciesFlag(_ args: Arguments) -> [Species]? {
    var list: [Species] = []
    if let group = args.flags["group"] {
        for name in group.split(separator: ",") {
            guard let members = figureGroups[name.lowercased()] else {
                fail("unknown group \(name); expected one of \(figureGroups.keys.sorted().joined(separator: ", "))")
            }
            list += members
        }
    }
    if let only = args.flags["species"] {
        for name in only.split(separator: ",") {
            let key = name.lowercased()
            guard let s = Species.allCases.first(where: { $0.rawValue == key }) else { fail("unknown species \(name)") }
            list.append(s)
        }
    }
    return list.isEmpty ? nil : list
}

func stylesFlag(_ args: Arguments) -> [ArtStyle] {
    guard let names = args.flags["style"] else { return ArtStyle.allCases }
    return names.split(separator: ",").map { name in
        guard let style = ArtStyle(name: String(name)) else {
            fail("unknown style \(name); expected one of \(ArtStyle.allCases.map(\.rawValue).joined(separator: ", "))")
        }
        return style
    }
}

let restPhase = 3.1

struct SheetColumn {
    var caption: String
    var kind: String
    var apply: (inout Critter) -> Void
}

func sheetColumns(frames: Int) -> [SheetColumn] {
    var cols: [SheetColumn] = []
    let moods: [(CritterMode, Double, String)] = [
        (.wandering, 0, "calm"), (.resting, 0, "sleepy"), (.startled, 0, "startled"), (.fleeing, 0, "fleeing"), (.wandering, 1, "dizzy"),
    ]
    for m in moods {
        cols.append(SheetColumn(caption: m.2, kind: "moods") { c in
            c.mode = m.0
            c.confusion = m.1
            c.gaitPhase = 0.2
        })
    }
    for i in 0..<frames {
        let frame = Double(i) / Double(frames)
        cols.append(SheetColumn(caption: "f\(i * 16 / frames)", kind: "frames") { c in
            c.gaitPhase = frame
            if c.species.locomotion == .hop, frame >= 0.25 {
                let u = (frame - 0.25) / 0.75
                c.lift = 4 * u * (1 - u)
            }
        })
    }
    for v in 0..<5 {
        cols.append(SheetColumn(caption: "v\(v)", kind: "variants") { c in
            c.tint = (Double(v) + 0.5) / 5
            c.gaitPhase = 0.3
        })
    }
    cols.append(SheetColumn(caption: "blink", kind: "idle") { c in c.antennaPhase = 0.17 })
    cols.append(SheetColumn(caption: "tw-", kind: "idle") { c in c.antennaPhase = 4.71 })
    cols.append(SheetColumn(caption: "tw+", kind: "idle") { c in c.antennaPhase = 1.57 })
    cols.append(SheetColumn(caption: "left", kind: "motion") { c in
        c.heading = .pi
        c.facing = -1
        c.gaitPhase = 0.45
    })
    cols.append(SheetColumn(caption: "up", kind: "motion") { c in
        c.heading = .pi / 2
        c.gaitPhase = 0.45
    })
    cols.append(SheetColumn(caption: "flee", kind: "motion") { c in
        c.heading = -.pi / 3
        c.mode = .fleeing
        c.gaitPhase = 0.45
    })
    return cols
}

func runSheet(_ args: Arguments) {
    guard let out = args.positional.first else {
        fail("usage: ScuttleSnap sheet <out.png> [--style name] [--species a,b] [--group festive] [--season name] [--weather name] [--night] [--frames 8|16] [--only moods,frames,variants,idle,motion] [--variant 0] [--zoom 2.5] [--size 28] [--scale 1]")
    }
    let style = styleFlag(args)
    var list = Species.allCases
    if let season = seasonFlag(args) { list = season.cast }
    let weather = weatherFlag(args), night = nightFlag(args)
    if weather != nil || night {
        let guests = (weather ?? .clear).guests(night: night)
        if seasonFlag(args) == nil { list = [] }
        for g in guests where !list.contains(g) { list.append(g) }
    }
    if let only = speciesFlag(args) { list = only }
    let scale = CGFloat(args.double("scale", 1))
    let zoom = CGFloat(args.double("zoom", 2.5))
    let figure = args.double("size", 28)
    let frames = args.int("frames", 8) >= 16 ? 16 : 8
    var columns = sheetColumns(frames: frames)
    if let only = args.flags["only"] {
        let kinds = Set(only.lowercased().split(separator: ",").map(String.init))
        columns = columns.filter { kinds.contains($0.kind) }
        if columns.isEmpty { fail("--only takes moods, frames, variants, idle, motion") }
    }
    let cell = CGFloat(figure) * 1.5, rowHeight = CGFloat(figure) * 2 + 8
    let labelWidth: CGFloat = 96
    let blockHeight = rowHeight * zoom * CGFloat(list.count) + 16
    let width = labelWidth + cell * zoom * CGFloat(columns.count) + 12, height = blockHeight * 2
    let ctx = makeContext(width: width, height: height, scale: scale)
    ctx.setFillColor(red: 0.955, green: 0.95, blue: 0.935, alpha: 1)
    ctx.fill(CGRect(x: 0, y: blockHeight, width: width, height: blockHeight))
    ctx.setFillColor(red: 0.065, green: 0.07, blue: 0.085, alpha: 1)
    ctx.fill(CGRect(x: 0, y: 0, width: width, height: blockHeight))
    let renderer = SceneRenderer()
    for half in 0..<2 {
        let baseY = half == 0 ? blockHeight : 0
        let gray: CGFloat = half == 0 ? 0.25 : 0.78
        var critters: [Critter] = []
        for (row, species) in list.enumerated() {
            let top = baseY + blockHeight - 8 - rowHeight * zoom * CGFloat(row)
            let cy = top - rowHeight * zoom * 0.5 + 4
            drawText(species.rawValue, at: CGPoint(x: 8, y: cy + 4), size: 11, gray: gray, in: ctx)
            drawText("\(species.locomotion.rawValue), \(style.rawValue)", at: CGPoint(x: 8, y: cy - 10), size: 7.5, gray: gray, alpha: 0.7, in: ctx)
            for (i, column) in columns.enumerated() {
                let x = labelWidth + cell * zoom * (CGFloat(i) + 0.5)
                var c = Critter(id: critters.count, species: species, position: CGPoint(x: x / zoom, y: cy / zoom), heading: 0, speed: figure, size: figure)
                c.antennaPhase = restPhase
                c.tint = (Double(args.int("variant", 0)) + 0.5) / 5
                column.apply(&c)
                critters.append(c)
                drawText(column.caption, at: CGPoint(x: x - 12, y: top - rowHeight * zoom + 4), size: 7.5, gray: gray, alpha: 0.6, in: ctx)
            }
        }
        ctx.saveGState()
        ctx.scaleBy(x: zoom, y: zoom)
        renderer.draw(Scene(size: CGSize(width: width / zoom, height: height / zoom), light: 1, critters: critters, time: 0),
                      options: RenderOptions(darkness: false, style: style), in: ctx)
        ctx.restoreGState()
    }
    guard let image = ctx.makeImage() else { fail("could not make image") }
    writePNG(image, to: out)
    print("wrote \(out) \(image.width)x\(image.height)")
}

func moodFlag(_ args: Arguments) -> (CritterMode, Double) {
    switch (args.flags["mood"] ?? "calm").lowercased() {
    case "calm": return (.wandering, 0)
    case "sleepy": return (.resting, 0)
    case "startled": return (.startled, 0)
    case "fleeing": return (.fleeing, 0)
    case "dizzy": return (.wandering, 1)
    case let other: fail("unknown mood \(other); expected calm, sleepy, startled, fleeing or dizzy")
    }
}

func runStyles(_ args: Arguments) {
    guard let out = args.positional.first else {
        fail("usage: ScuttleSnap styles <out.png> [--species a,b,c] [--group festive] [--style kawaii,sticker] [--mood calm] [--variant 0|all] [--phase 0.2] [--big 96] [--small 32] [--scale 2]")
    }
    let species = speciesFlag(args) ?? [.hedgehog, .ghost, .penguin, .butterfly]
    let styles = stylesFlag(args)
    let mood = moodFlag(args)
    let cycleVariants = args.flags["variant"] == "all"
    let variant = max(0, min(4, args.int("variant", 0)))
    let phase = args.double("phase", 0.2)
    let big = CGFloat(args.double("big", 96)), small = CGFloat(args.double("small", 32))
    let scale = CGFloat(args.double("scale", 2))
    let labelW: CGFloat = 120, header: CGFloat = 36
    let cellW = big * 1.5, rowH = max(big * 1.55, small * 3.4) + 12
    let stripCell = small * 1.45
    let stripX = labelW + cellW * CGFloat(species.count) + 16
    let width = stripX + stripCell * CGFloat(species.count) + 16
    let height = header + rowH * CGFloat(styles.count) + 8
    let ctx = makeContext(width: width, height: height, scale: scale)
    let navy = CGColor(srgbRed: 0.078, green: 0.102, blue: 0.165, alpha: 1)
    let light = CGColor(srgbRed: 0.914, green: 0.914, blue: 0.933, alpha: 1)
    ctx.setFillColor(navy)
    ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
    for (i, s) in species.enumerated() {
        drawText(s.rawValue, at: CGPoint(x: labelW + cellW * (CGFloat(i) + 0.5) - CGFloat(s.rawValue.count) * 3.6, y: height - 24), size: 12, gray: 0.7, in: ctx)
    }
    drawText("real size (\(Int(small)) pt @\(Int(scale))x)", at: CGPoint(x: stripX + 4, y: height - 24), size: 11, gray: 0.7, in: ctx)
    func critter(_ s: Species, _ i: Int, at p: CGPoint, size: CGFloat) -> Critter {
        var c = Critter(id: i, species: s, position: p, heading: 0, speed: 0, size: Double(size))
        c.mode = mood.0
        c.confusion = mood.1
        c.gaitPhase = phase
        c.antennaPhase = restPhase
        c.tint = (Double(cycleVariants ? i % 100 % 5 : variant) + 0.5) / 5
        if s.locomotion == .hop, phase >= 0.25 {
            let u = (phase - 0.25) / 0.75
            c.lift = 4 * u * (1 - u)
        }
        return c
    }
    for (row, style) in styles.enumerated() {
        let top = height - header - rowH * CGFloat(row)
        let bottom = top - rowH
        if row > 0 {
            ctx.setFillColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.07))
            ctx.fill(CGRect(x: 12, y: top, width: width - 24, height: 1))
        }
        drawText(style.title, at: CGPoint(x: 12, y: bottom + rowH / 2 + 4), size: 15, gray: 0.95, in: ctx)
        drawText(style.rawValue, at: CGPoint(x: 12, y: bottom + rowH / 2 - 14), size: 10, gray: 0.6, in: ctx)
        var bigs: [Critter] = []
        for (i, s) in species.enumerated() {
            let x = labelW + cellW * (CGFloat(i) + 0.5)
            bigs.append(critter(s, i, at: CGPoint(x: x, y: bottom + rowH / 2 + big * 0.04), size: big))
        }
        let panelH = (rowH - 18) / 2
        let panels: [(CGColor, CGFloat)] = [(navy, top - 6 - panelH), (light, top - 12 - 2 * panelH)]
        var strips: [[Critter]] = []
        for (k, panel) in panels.enumerated() {
            let rect = CGRect(x: stripX, y: panel.1, width: stripCell * CGFloat(species.count), height: panelH)
            let path = CGPath(roundedRect: rect, cornerWidth: 8, cornerHeight: 8, transform: nil)
            ctx.addPath(path)
            ctx.setFillColor(panel.0)
            ctx.fillPath()
            if k == 0 {
                ctx.addPath(path)
                ctx.setStrokeColor(CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0.15))
                ctx.setLineWidth(1)
                ctx.strokePath()
            }
            strips.append(species.enumerated().map { i, s in
                critter(s, 100 + i, at: CGPoint(x: stripX + stripCell * (CGFloat(i) + 0.5), y: panel.1 + panelH / 2 + small * 0.04), size: small)
            })
        }
        let renderer = SceneRenderer()
        let options = RenderOptions(darkness: false, style: style)
        let area = CGSize(width: width, height: height)
        renderer.draw(Scene(size: area, light: 1, critters: bigs + strips.flatMap { $0 }, time: 0), options: options, in: ctx)
    }
    guard let image = ctx.makeImage() else { fail("could not make image") }
    writePNG(image, to: out)
    print("wrote \(out) \(image.width)x\(image.height)")
}

func drawBackdrop(size: CGSize, in ctx: CGContext) {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    let w = size.width, h = size.height
    let colors: [CGFloat] = [
        0.98, 0.62, 0.36, 1,
        0.86, 0.4, 0.5, 1,
        0.42, 0.33, 0.68, 1,
        0.16, 0.24, 0.52, 1,
    ]
    let gradient = CGGradient(colorSpace: space, colorComponents: colors, locations: [0, 0.35, 0.7, 1], count: 4)!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: w * 0.35, y: h), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.setFillColor(red: 1, green: 0.85, blue: 0.6, alpha: 0.2)
    ctx.fillEllipse(in: CGRect(x: w * 0.55, y: -h * 0.35, width: w * 0.8, height: h * 0.8))

    ctx.setFillColor(red: 0.96, green: 0.96, blue: 0.97, alpha: 0.82)
    ctx.fill(CGRect(x: 0, y: h - 24, width: w, height: 24))
    drawText("Finder   File   Edit   View   Go   Window   Help", at: CGPoint(x: 18, y: h - 17), size: 11, gray: 0.1, in: ctx)

    func window(_ r: CGRect, dark: Bool) {
        ctx.setFillColor(red: 0, green: 0, blue: 0, alpha: 0.18)
        ctx.addPath(CGPath(roundedRect: r.offsetBy(dx: 0, dy: -8).insetBy(dx: -6, dy: -6), cornerWidth: 16, cornerHeight: 16, transform: nil))
        ctx.fillPath()
        let body: CGFloat = dark ? 0.13 : 0.985
        ctx.setFillColor(red: body, green: body, blue: body + (dark ? 0.015 : 0), alpha: 1)
        ctx.addPath(CGPath(roundedRect: r, cornerWidth: 10, cornerHeight: 10, transform: nil))
        ctx.fillPath()
        let bar: CGFloat = dark ? 0.19 : 0.92
        ctx.saveGState()
        ctx.addPath(CGPath(roundedRect: r, cornerWidth: 10, cornerHeight: 10, transform: nil))
        ctx.clip()
        ctx.setFillColor(red: bar, green: bar, blue: bar, alpha: 1)
        ctx.fill(CGRect(x: r.minX, y: r.maxY - 30, width: r.width, height: 30))
        ctx.restoreGState()
        let lights: [(CGFloat, CGFloat, CGFloat)] = [(1, 0.37, 0.34), (1, 0.74, 0.18), (0.16, 0.79, 0.25)]
        for (i, c) in lights.enumerated() {
            ctx.setFillColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
            ctx.fillEllipse(in: CGRect(x: r.minX + 12 + CGFloat(i) * 19, y: r.maxY - 21, width: 12, height: 12))
        }
        let ink: CGFloat = dark ? 0.62 : 0.3
        var y = r.maxY - 58
        var k = 0
        while y > r.minY + 20 {
            let frac = 0.35 + 0.6 * abs(sin(CGFloat(k) * 2.4 + (dark ? 1 : 0)))
            ctx.setFillColor(red: ink, green: ink, blue: ink, alpha: k % 7 == 0 ? 0.75 : 0.3)
            ctx.fill(CGRect(x: r.minX + 22, y: y, width: (r.width - 44) * frac, height: k % 7 == 0 ? 7 : 5))
            y -= 17
            k += 1
        }
    }
    window(CGRect(x: w * 0.07, y: h * 0.2, width: w * 0.46, height: h * 0.62), dark: false)
    window(CGRect(x: w * 0.48, y: h * 0.09, width: w * 0.42, height: h * 0.5), dark: true)

    let dockW = min(w * 0.5, 620), dockH: CGFloat = 58
    let dock = CGRect(x: (w - dockW) / 2, y: 6, width: dockW, height: dockH)
    ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: 0.3)
    ctx.addPath(CGPath(roundedRect: dock, cornerWidth: 16, cornerHeight: 16, transform: nil))
    ctx.fillPath()
    let icons = 11
    let pitch = (dockW - 20) / CGFloat(icons)
    for i in 0..<icons {
        let hue = CGFloat(i) / CGFloat(icons)
        let r = 0.55 + 0.4 * sin(hue * 6.28), g = 0.55 + 0.4 * sin(hue * 6.28 + 2.1), b = 0.55 + 0.4 * sin(hue * 6.28 + 4.2)
        ctx.setFillColor(red: r, green: g, blue: b, alpha: 1)
        let side = pitch - 10
        let rect = CGRect(x: dock.minX + 10 + CGFloat(i) * pitch + 5, y: dock.minY + (dockH - side) / 2, width: side, height: side)
        ctx.addPath(CGPath(roundedRect: rect, cornerWidth: side * 0.23, cornerHeight: side * 0.23, transform: nil))
        ctx.fillPath()
    }
}

func runTimeline(_ args: Arguments) {
    guard args.positional.count >= 2 else {
        fail("usage: ScuttleSnap timeline <timeline.json> <outdir> [--fps 4] [--size 1512x982] [--seed N] [--population N] [--scale 2] [--season name] [--weather name] [--night] [--style name]")
    }
    let timeline: LidTimeline
    do {
        timeline = try LidTimeline.load(from: URL(fileURLWithPath: args.positional[0]))
    } catch {
        fail("could not load timeline: \(error)")
    }
    let outDir = args.positional[1]
    let style = styleFlag(args)
    let fps = max(0.1, args.double("fps", 4))
    let size = args.size("size", CGSize(width: 1512, height: 982))
    let scale = CGFloat(args.double("scale", 2))
    var config = WorldConfig()
    config.seed = UInt64(max(0, args.int("seed", 1)))
    config.population = args.int("population", config.population)
    let season = seasonFlag(args)
    config.season = season ?? Season.of(Date())
    let weather = weatherFlag(args), night = nightFlag(args)
    config.weather = weather
    config.night = night
    let k = figureScaleFlag(args)
    let darken = darkenFlag(args)
    let world = World(size: worldOf(size, k), config: config)
    let renderer = SceneRenderer()

    let backdropCtx = makeContext(width: size.width, height: size.height, scale: scale)
    drawBackdrop(size: size, in: backdropCtx)
    guard let backdrop = backdropCtx.makeImage() else { fail("could not make backdrop") }
    let ctx = makeContext(width: size.width, height: size.height, scale: scale)

    let dt = 1.0 / 60.0
    let duration = args.double("duration", timeline.duration)
    let steps = Int((duration / dt).rounded())
    let every = max(1, Int((60.0 / fps).rounded()))
    var frame = 0
    var peak = 0
    let from = args.double("from", 0)
    let until = args.double("to", .infinity)
    for step in 0...steps {
        let t = Double(step) * dt
        let angle = timeline.angle(at: t)
        if step > 0 { world.step(dt: dt, lidAngle: angle) }
        peak = max(peak, world.critters.count)
        if step % every == 0 && t >= from - 1e-9 && t <= until + 1e-9 {
            ctx.draw(backdrop, in: CGRect(origin: .zero, size: size))
            let hud = String(format: "t %6.2fs  angle %5.1f  light %.2f  critters %d", t, angle, world.light, world.critters.count)
            renderer.draw(Scene(size: size, light: world.light, critters: world.critters, time: t, props: world.props, scale: k),
                          options: RenderOptions(darkness: darken, hud: hud, season: season, weather: weather, night: night, style: style), in: ctx)
            guard let image = ctx.makeImage() else { fail("could not make frame") }
            writePNG(image, to: String(format: "%@/frame-%04d.png", outDir, frame))
            frame += 1
        }
    }
    print("wrote \(frame) frames to \(outDir), peak critters \(peak)")
}

func benchCritters(count: Int, size: CGSize, fading: Bool, season: Season) -> [Critter] {
    var rng = SplitMixLite(seed: 7)
    var out: [Critter] = []
    let all = season.cast
    for i in 0..<count {
        let species = all[i % all.count]
        let range = SpeciesTraits.standard(for: species).sizeRange
        let sz = range.lowerBound + rng.unit() * (range.upperBound - range.lowerBound)
        out.append(Critter(
            id: i, species: species,
            position: CGPoint(x: 30 + rng.unit() * (size.width - 60), y: 30 + rng.unit() * (size.height - 60)),
            heading: rng.unit() * 2 * .pi, speed: 40, size: sz,
            mode: i % 9 == 0 ? .startled : (i % 7 == 0 ? .resting : .wandering),
            gaitPhase: rng.unit(), bend: rng.unit() * 2 - 1, antennaPhase: rng.unit() * 6,
            tint: rng.unit(), alpha: fading && i % 6 == 0 ? 0.6 : 1, facing: i % 2 == 0 ? 1 : -1
        ))
    }
    return out
}

struct SplitMixLite {
    var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func unit() -> Double {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        z ^= z >> 31
        return Double(z >> 11) / Double(1 << 53)
    }
}

func runBench(_ args: Arguments) {
    let frames = max(1, args.int("frames", 300))
    let count = args.int("critters", 120)
    let size = args.size("size", CGSize(width: 1512, height: 982))
    let scale = CGFloat(args.double("scale", 2))
    let turn = args.double("turn", 0.004)
    let style = styleFlag(args)
    let k = figureScaleFlag(args)
    let world = worldOf(size, k)
    let renderer = SceneRenderer()
    let ctx = makeContext(width: size.width, height: size.height, scale: scale)
    let rect = CGRect(origin: .zero, size: size)

    @discardableResult
    func measure(_ label: String, critters base: [Critter], light: Double, options: RenderOptions, start: Double = 0) -> Double {
        var critters = base
        var total: UInt64 = 0
        var worst: UInt64 = 0
        for f in 0..<(frames + 10) {
            for i in critters.indices {
                critters[i].gaitPhase += 0.03
                critters[i].antennaPhase += 0.08
                critters[i].heading += turn
                critters[i].gestureTime += 1.0 / 60
            }
            ctx.clear(rect)
            let scene = Scene(size: size, light: light, critters: critters, time: start + Double(f) / 60, scale: k)
            let start = DispatchTime.now().uptimeNanoseconds
            renderer.draw(scene, options: options, in: ctx)
            let elapsed = DispatchTime.now().uptimeNanoseconds - start
            if f >= 10 {
                total += elapsed
                worst = max(worst, elapsed)
            }
        }
        let mean = Double(total) / Double(frames) / 1e6
        print(String(format: "%@ mean %.3f ms  worst %.3f ms", label.padding(toLength: 46, withPad: " ", startingAt: 0), mean, Double(worst) / 1e6))
        return mean
    }

    print("bench: \(count) critters, \(Int(size.width))x\(Int(size.height)) @\(scale)x, figures x\(k), \(frames) frames")
    let cast = seasonFlag(args) ?? .summer
    let solid = benchCritters(count: count, size: world, fading: false, season: cast)
    let fading = benchCritters(count: count, size: world, fading: true, season: cast)
    measure("critters only", critters: solid, light: 1, options: RenderOptions(darkness: false, style: style))
    let acting = solid.enumerated().map { i, c -> Critter in
        var c = c
        c.gesture = args.flags["gesture"].flatMap { Gesture(rawValue: $0.lowercased()) } ?? Gesture.allCases[i % Gesture.allCases.count]
        c.gestureTime = Double(i % 7) * 0.4
        return c
    }
    measure("critters only, no shadows", critters: solid, light: 1, options: RenderOptions(darkness: false, shadows: false, style: style))
    measure("critters, 1 in 6 fading (alpha 0.6)", critters: fading, light: 1, options: RenderOptions(darkness: false, style: style))
    measure("critters acting gestures, warming", critters: acting, light: 1, options: RenderOptions(darkness: false, style: style))
    measure("critters acting gestures (all kinds)", critters: acting, light: 1, options: RenderOptions(darkness: false, style: style))
    measure("critters only, again", critters: solid, light: 1, options: RenderOptions(darkness: false, style: style))
    measure("critters + darkness (light 0.25)", critters: solid, light: 0.25, options: RenderOptions(darkness: true, style: style))
    measure("darkness only (light 0.25)", critters: [], light: 0.25, options: RenderOptions(darkness: true, style: style))
    measure("darkness only, no vignette", critters: [], light: 0.25, options: RenderOptions(darkness: true, vignette: 0, style: style))
    let uncached = measure("critters only, sprite cache off", critters: solid, light: 1, options: RenderOptions(darkness: false, spriteCache: false, style: style))
    print(String(format: "%@ %.3f ms", "\(style.rawValue) sprite build, per sprite".padding(toLength: 46, withPad: " ", startingAt: 0), uncached / Double(max(1, count))))
    var ramp = 0.0
    var total: UInt64 = 0
    for _ in 0..<60 {
        ramp += 1.0 / 60
        ctx.clear(rect)
        let start = DispatchTime.now().uptimeNanoseconds
        renderer.draw(Scene(size: size, light: 1 - ramp, critters: [], time: 0), options: RenderOptions(darkness: true, style: style), in: ctx)
        total += DispatchTime.now().uptimeNanoseconds - start
    }
    print(String(format: "%@ mean %.3f ms", "darkness only, light changing every frame".padding(toLength: 46, withPad: " ", startingAt: 0), Double(total) / 60 / 1e6))
    print("sprite cache: \(renderer.spriteCacheBytes / 1024) KiB")
    let propCount = args.int("props", 15)
    let stuff = benchProps(count: propCount, critters: solid, size: world)
    let workers = solid.enumerated().map { i, c -> Critter in
        var c = c
        if let rope = stuff.first(where: { $0.kind == .rope && $0.partner == c.id }),
           let mate = solid.first(where: { $0.id == rope.holder }) {
            c.position = CGPoint(x: min(world.width - 30, mate.position.x + 150), y: mate.position.y)
            c.facing = -1
            c.heading = .pi
        }
        if let p = stuff.first(where: { $0.holder == c.id || $0.partner == c.id }) {
            c.gesture = p.kind == .rope ? .pull : (p.kind == .snowball ? .push : .carry)
            c.gestureTime = Double(i % 5) * 0.3
        }
        return c
    }
    let base = measure("critters (workers), no props", critters: workers, light: 1, options: RenderOptions(darkness: false, style: style))
    func measureProps(_ label: String, list: [Prop], in ctx: CGContext) -> Double {
        var crits = workers
        var props = list
        var total: UInt64 = 0
        var worst: UInt64 = 0
        for f in 0..<(frames + 10) {
            for i in crits.indices {
                crits[i].gaitPhase += 0.03
                crits[i].antennaPhase += 0.08
                crits[i].gestureTime += 1.0 / 60
            }
            for i in props.indices { props[i].age += 1.0 / 60 }
            ctx.clear(rect)
            let scene = Scene(size: size, light: 1, critters: crits, time: 200 + Double(f) / 60, props: props, scale: k)
            let start = DispatchTime.now().uptimeNanoseconds
            renderer.draw(scene, options: RenderOptions(darkness: false, style: style), in: ctx)
            let elapsed = DispatchTime.now().uptimeNanoseconds - start
            if f >= 10 {
                total += elapsed
                worst = max(worst, elapsed)
            }
        }
        let mean = Double(total) / Double(frames) / 1e6
        print(String(format: "%@ mean %.3f ms  worst %.3f ms", label.padding(toLength: 46, withPad: " ", startingAt: 0), mean, Double(worst) / 1e6))
        return mean
    }
    let withProps = measureProps("critters (workers) + \(propCount) props", list: stuff, in: ctx)
    print(String(format: "%@ %.3f ms", "props overhead, steady state".padding(toLength: 46, withPad: " ", startingAt: 0), withProps - base))
    if let native = CGContext(data: nil, width: Int(size.width * scale), height: Int(size.height * scale), bitsPerComponent: 8, bytesPerRow: 0,
                              space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue) {
        native.scaleBy(x: scale, y: scale)
        let bare = measureProps("BGRA context: workers, no props", list: [], in: native)
        let full = measureProps("BGRA context: workers + \(propCount) props", list: stuff, in: native)
        print(String(format: "%@ %.3f ms", "props overhead, BGRA context (app format)".padding(toLength: 46, withPad: " ", startingAt: 0), full - bare))
    }
    renderer.purgeCaches()
    var first: UInt64 = 0
    do {
        ctx.clear(rect)
        let start = DispatchTime.now().uptimeNanoseconds
        renderer.draw(Scene(size: size, light: 1, critters: [], time: 300, props: stuff, scale: k), options: RenderOptions(darkness: false, style: style), in: ctx)
        first = DispatchTime.now().uptimeNanoseconds - start
    }
    print(String(format: "%@ %.3f ms", "\(propCount) props cold (sprite build)".padding(toLength: 46, withPad: " ", startingAt: 0), Double(first) / 1e6))
    print("prop cache: \(renderer.propCacheBytes / 1024) KiB")
    for species in cast.cast {
        let one = solid.map { c -> Critter in
            var c = c
            c.species = species
            return c
        }
        measure("\(count) x \(species.rawValue)", critters: one, light: 1, options: RenderOptions(darkness: false, style: style))
    }
}

func runSeasons(_ args: Arguments) {
    guard let out = args.positional.first else {
        fail("usage: ScuttleSnap seasons <out.png> [--size 1512x982] [--scale 1] [--columns 2] [--light 0.1] [--time 6] [--population 24] [--seed 1] [--only a,b] [--weather name] [--night] [--style name]")
    }
    let size = args.size("size", CGSize(width: 1512, height: 982))
    let scale = CGFloat(args.double("scale", 1))
    let columns = max(1, args.int("columns", 2))
    let time = args.double("time", 6)
    let style = styleFlag(args)
    var list = Season.allCases
    if let only = args.flags["only"] {
        list = only.split(separator: ",").map { name in
            guard let s = Season(name: String(name)) else { fail("unknown season \(name)") }
            return s
        }
    }
    var config = WorldConfig()
    config.seed = UInt64(max(0, args.int("seed", 1)))
    config.population = args.int("population", 24)
    let weather = weatherFlag(args), night = nightFlag(args)
    config.weather = weather
    config.night = night
    let light = args.double("light", 0.1)
    let gap: CGFloat = 12, label: CGFloat = 30
    let rows = (list.count + columns - 1) / columns
    let width = CGFloat(columns) * size.width + CGFloat(columns + 1) * gap
    let height = CGFloat(rows) * (size.height + label) + CGFloat(rows + 1) * gap
    let ctx = makeContext(width: width, height: height, scale: scale)
    ctx.setFillColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1)
    ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let backdropCtx = makeContext(width: size.width, height: size.height, scale: scale)
    drawBackdrop(size: size, in: backdropCtx)
    guard let backdrop = backdropCtx.makeImage() else { fail("could not make backdrop") }
    let renderer = SceneRenderer()
    for (i, season) in list.enumerated() {
        let col = i % columns, row = i / columns
        let x = gap + CGFloat(col) * (size.width + gap)
        let y = height - CGFloat(row + 1) * (size.height + label + gap)
        config.season = season
        let world = stillWorld(size: worldOf(size, figureScaleFlag(args)), config: config)
        drawText(season.title, at: CGPoint(x: x + 4, y: y + size.height + 9), size: 16, gray: 0.92, in: ctx)
        ctx.saveGState()
        ctx.translateBy(x: x, y: y)
        ctx.clip(to: CGRect(origin: .zero, size: size))
        ctx.draw(backdrop, in: CGRect(origin: .zero, size: size))
        renderer.draw(Scene(size: size, light: light, critters: world.critters, time: time, props: world.props, scale: figureScaleFlag(args)),
                      options: RenderOptions(darkness: darkenFlag(args), season: season, weather: weather, night: night, style: style), in: ctx)
        ctx.restoreGState()
    }
    guard let image = ctx.makeImage() else { fail("could not make image") }
    writePNG(image, to: out)
    print("wrote \(out) \(image.width)x\(image.height), light \(light)")
}

func runWeather(_ args: Arguments) {
    guard let out = args.positional.first else {
        fail("usage: ScuttleSnap weather <out.png> [--season name] [--size 1512x982] [--scale 1] [--columns 2] [--light 0.1] [--time 6] [--population 24] [--seed 1] [--only a,b] [--night] [--style name]")
    }
    let size = args.size("size", CGSize(width: 1512, height: 982))
    let scale = CGFloat(args.double("scale", 1))
    let columns = max(1, args.int("columns", 2))
    let time = args.double("time", 6)
    let light = args.double("light", 0.1)
    let season = seasonFlag(args)
    let style = styleFlag(args)
    let allNight = nightFlag(args)
    var panels: [(Weather, Bool)] = Weather.allCases.map { ($0, allNight) }
    if !allNight { panels.append((.clear, true)) }
    if let only = args.flags["only"] {
        let keys = only.split(separator: ",").map { $0.lowercased() }
        panels = panels.filter { weather, night in
            keys.contains { key in
                if ["night", "clearnight", "clear-night"].contains(key) { return weather == .clear && night }
                return Weather(name: key) == weather && night == allNight
            }
        }
        if panels.isEmpty { fail("no weather matched \(only)") }
    }
    var config = WorldConfig()
    config.seed = UInt64(max(0, args.int("seed", 1)))
    config.population = args.int("population", 24)
    config.season = season ?? Season.of(Date())
    let gap: CGFloat = 12, label: CGFloat = 30
    let rows = (panels.count + columns - 1) / columns
    let width = CGFloat(columns) * size.width + CGFloat(columns + 1) * gap
    let height = CGFloat(rows) * (size.height + label) + CGFloat(rows + 1) * gap
    let ctx = makeContext(width: width, height: height, scale: scale)
    ctx.setFillColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1)
    ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let backdropCtx = makeContext(width: size.width, height: size.height, scale: scale)
    drawBackdrop(size: size, in: backdropCtx)
    guard let backdrop = backdropCtx.makeImage() else { fail("could not make backdrop") }
    let renderer = SceneRenderer()
    for (i, panel) in panels.enumerated() {
        let (weather, night) = panel
        let col = i % columns, row = i / columns
        let x = gap + CGFloat(col) * (size.width + gap)
        let y = height - CGFloat(row + 1) * (size.height + label + gap)
        config.weather = weather
        config.night = night
        let world = stillWorld(size: worldOf(size, figureScaleFlag(args)), config: config)
        let title = "\(weather.title)\(night ? " night" : "") guests  ·  \(season?.title ?? "no season")"
        drawText(title, at: CGPoint(x: x + 4, y: y + size.height + 9), size: 16, gray: 0.92, in: ctx)
        ctx.saveGState()
        ctx.translateBy(x: x, y: y)
        ctx.clip(to: CGRect(origin: .zero, size: size))
        ctx.draw(backdrop, in: CGRect(origin: .zero, size: size))
        renderer.draw(Scene(size: size, light: light, critters: world.critters, time: time, props: world.props, scale: figureScaleFlag(args)),
                      options: RenderOptions(darkness: darkenFlag(args), season: season, weather: weather, night: night, style: style), in: ctx)
        ctx.restoreGState()
    }
    guard let image = ctx.makeImage() else { fail("could not make image") }
    writePNG(image, to: out)
    print("wrote \(out) \(image.width)x\(image.height), light \(light)")
}

enum SheetEdge: String {
    case bottom, top, left, right, none
}

struct GestureColumn {
    var t: Double
    var leave: Double?
    var caption: String
}

struct GestureRow {
    var title: String
    var gesture: Gesture
    var edge: SheetEdge
    var columns: [GestureColumn]
    var after: Gesture = .none
    var prop: PropKind? = nil
    var moving = false
}

func steps(_ from: Double, _ step: Double, _ count: Int = 10) -> [GestureColumn] {
    (0..<count).map { i in
        let t = from + step * Double(i)
        return GestureColumn(t: t, leave: nil, caption: String(format: "%.2f", t))
    }
}

func leaving(_ at: Double, _ times: [Double]) -> [GestureColumn] {
    times.map { GestureColumn(t: at, leave: $0, caption: String(format: "-%.2f", $0)) }
}

func gestureRows() -> [GestureRow] {
    [
        GestureRow(title: "peek bottom", gesture: .peek, edge: .bottom, columns: steps(0, 0.35, 8) + steps(3.6, 0.15, 6)),
        GestureRow(title: "peek top", gesture: .peek, edge: .top, columns: steps(0, 0.35, 8) + steps(3.6, 0.15, 6)),
        GestureRow(title: "peek left", gesture: .peek, edge: .left, columns: steps(0, 0.35, 8) + steps(3.6, 0.15, 6)),
        GestureRow(title: "peek right", gesture: .peek, edge: .right, columns: steps(0, 0.5, 10) + leaving(5, [0.1, 0.25, 0.4, 0.6])),
        GestureRow(title: "tiptoe", gesture: .tiptoe, edge: .none, columns: steps(1, 0.1, 14)),
        GestureRow(title: "wave", gesture: .wave, edge: .none, columns: steps(0, 0.1, 14)),
        GestureRow(title: "dance", gesture: .dance, edge: .none, columns: steps(0, 0.12, 14)),
        GestureRow(title: "cheer", gesture: .cheer, edge: .none, columns: steps(0, 0.08, 14)),
        GestureRow(title: "sleep", gesture: .sleep, edge: .none, columns: steps(0, 0.4, 10) + leaving(4, [0.1, 0.3, 0.5, 0.7])),
        GestureRow(title: "look", gesture: .look, edge: .none, columns: steps(0, 0.35, 14)),
        GestureRow(title: "shiver", gesture: .shiver, edge: .none, columns: steps(0, 0.025, 14)),
        GestureRow(title: "tumble", gesture: .tumble, edge: .none, columns: steps(0, 0.08, 7) + steps(0.7, 0.3, 7)),
        GestureRow(title: "parachute", gesture: .parachute, edge: .none, columns: steps(0, 0.1, 5) + steps(0.7, 0.5, 4) + leaving(3, [0.05, 0.15, 0.3, 0.45, 0.65])),
        GestureRow(title: "popUp bottom", gesture: .popUp, edge: .bottom, columns: steps(0, 0.06, 14)),
        GestureRow(title: "popUp left", gesture: .popUp, edge: .left, columns: steps(0, 0.08, 10) + leaving(1.2, [0.1, 0.2, 0.3, 0.45])),
        GestureRow(title: "perch", gesture: .perch, edge: .none, columns: steps(0, 0.4, 14)),
        GestureRow(title: "dance>look", gesture: .dance, edge: .none, columns: leaving(2, [0.05, 0.15, 0.25, 0.35]).map { GestureColumn(t: $0.t, leave: $0.leave, caption: "x" + $0.caption) }, after: .look),
        GestureRow(title: "carry", gesture: .carry, edge: .none, columns: steps(0, 0.3, 14), prop: .acorn),
        GestureRow(title: "carry walk", gesture: .carry, edge: .none, columns: steps(0.5, 0.07, 14), prop: .present, moving: true),
        GestureRow(title: "push", gesture: .push, edge: .none, columns: steps(0, 0.12, 14), prop: .snowball),
        GestureRow(title: "push walk", gesture: .push, edge: .none, columns: steps(0.5, 0.07, 14), prop: .pumpkin, moving: true),
        GestureRow(title: "pull", gesture: .pull, edge: .none, columns: steps(0, 0.1, 14), prop: .rope),
        GestureRow(title: "build", gesture: .build, edge: .none, columns: steps(0, 0.14, 14) + steps(2.3, 0.25, 6), prop: .snowman),
        GestureRow(title: "count", gesture: .count, edge: .none, columns: steps(0, 0.3, 14)),
        GestureRow(title: "kick", gesture: .kick, edge: .none, columns: steps(0, 0.06, 14) + steps(0.9, 0.3, 3), prop: .ball),
    ]
}

func gestureProps(_ row: GestureRow, critter c: Critter, figure: CGFloat, t: Double) -> [Prop] {
    guard let kind = row.prop else { return [] }
    let id = 100_000 + c.id
    let ground = c.position.y - figure * 0.46
    if row.gesture == .push {
        let size = figure * (kind == .snowball ? 0.9 : 0.62)
        let lean = figure * 0.42 + size * 0.5
        return [Prop(id: id, kind: kind, position: CGPoint(x: c.position.x + CGFloat(c.facing) * lean, y: ground + size * 0.5), size: Double(size),
                     rotation: -t * 1.5, age: 5)]
    }
    switch kind {
    case .rope:
        return [Prop(id: id, kind: .rope, position: c.position, size: Double(figure) * 0.8, progress: 1, holder: c.id,
                     end: CGPoint(x: c.position.x + figure * 1.5, y: ground + figure * 0.25), age: 5)]
    case .snowman:
        return [Prop(id: id, kind: .snowman, position: CGPoint(x: c.position.x + figure * 0.95, y: ground + figure * 1.1 * 0.46),
                     size: Double(figure) * 1.1, progress: 0.7, age: 5)]
    case .ball:
        let size = figure * 0.42
        let hit = 0.375
        var x = c.position.x + figure * 0.62
        var y = ground + size * 0.46
        var spin = 0.0
        if t > hit {
            let u = t - hit
            x += CGFloat(u) * figure * 3.2
            y += max(0, CGFloat(u * 2.6 - u * u * 4.2)) * figure
            spin = -u * 9
        }
        return [Prop(id: id, kind: .ball, position: CGPoint(x: x, y: y), size: Double(size), rotation: spin, age: 5)]
    case .snowball:
        return [Prop(id: id, kind: .snowball, position: c.position, size: Double(figure) * 0.9, rotation: -t * 1.5, holder: c.id, age: 5)]
    default:
        return [Prop(id: id, kind: kind, position: c.position, size: Double(figure) * (kind == .acorn ? 0.45 : 0.6), holder: c.id, age: 5)]
    }
}

func runGestures(_ args: Arguments) {
    guard let out = args.positional.first else {
        fail("usage: ScuttleSnap gestures <out.png> [--style name] [--species a,b,c] [--only peek,dance] [--cols 0-6] [--size 30] [--zoom 2.5] [--scale 1] [--variant 0] [--fright] [--confused]")
    }
    let styles = args.flags["style"] == nil ? [ArtStyle.kawaii] : stylesFlag(args)
    let species = speciesFlag(args) ?? [.hedgehog, .chick, .ghost, .butterfly, .turtle, .snowman]
    let blocks = styles.flatMap { st in species.map { (st, $0) } }
    var rows = gestureRows()
    if let only = args.flags["only"] {
        let keys = only.lowercased().split(separator: ",").map(String.init)
        rows = rows.filter { row in keys.contains { row.title.lowercased().hasPrefix($0) || row.gesture.rawValue == $0 } }
        if rows.isEmpty { fail("--only matched no gesture rows") }
    }
    if let range = args.flags["cols"] {
        let parts = range.split(separator: "-").compactMap { Int($0) }
        let lo = parts.first ?? 0, hi = parts.count > 1 ? parts[1] : lo
        rows = rows.map { row in
            var r = row
            r.columns = Array(row.columns.enumerated().filter { $0.offset >= lo && $0.offset <= hi }.map(\.element))
            return r
        }
    }
    let figure = CGFloat(args.double("size", 30))
    let zoom = CGFloat(args.double("zoom", 2.5))
    let scale = CGFloat(args.double("scale", 1))
    let variant = max(0, min(4, args.int("variant", 0)))
    let fright = args.flags["fright"] != nil
    let confused = args.flags["confused"] != nil
    let columns = rows.map(\.columns.count).max() ?? 10
    let cellW = figure * 2.1, rowH = figure * (rows.contains { $0.gesture == .parachute } ? 3.1 : 2.5), label: CGFloat = 70, gap: CGFloat = 3
    let blockH = rowH * CGFloat(rows.count) + 22
    let width = label + (cellW + gap) * CGFloat(columns) + 8
    let height = blockH * CGFloat(blocks.count) + 8
    let ctx = makeContext(width: width * zoom, height: height * zoom, scale: scale)
    ctx.setFillColor(red: 0.035, green: 0.04, blue: 0.055, alpha: 1)
    ctx.fill(CGRect(x: 0, y: 0, width: width * zoom, height: height * zoom))
    let scratch = makeContext(width: 4, height: 4, scale: scale)
    scratch.scaleBy(x: zoom, y: zoom)
    let renderer = SceneRenderer()
    var clock = 0.0
    var id = 0
    for (block, pair) in blocks.enumerated() {
        let (style, sp) = pair
        let options = RenderOptions(darkness: false, style: style)
        let blockTop = height - 4 - blockH * CGFloat(block)
        drawText("\(sp.rawValue)  \(sp.locomotion.rawValue)  \(style.rawValue)", at: CGPoint(x: 8 * zoom, y: (blockTop - 14) * zoom), size: 12 * zoom / 2.5 * 1.4, gray: 0.92, in: ctx)
        for (r, row) in rows.enumerated() {
            let top = blockTop - 20 - rowH * CGFloat(r)
            let bottom = top - rowH + gap
            drawText(row.title, at: CGPoint(x: 6 * zoom, y: (bottom + rowH * 0.5) * zoom), size: 9 * zoom / 2.5 * 1.4, gray: 0.75, in: ctx)
            for (i, col) in row.columns.enumerated() {
                let x0 = label + (cellW + gap) * CGFloat(i)
                let cell = CGRect(x: x0, y: bottom, width: cellW, height: rowH - gap)
                let bezel = figure * 0.55
                var screen = cell
                switch row.edge {
                case .bottom: screen = CGRect(x: cell.minX, y: cell.minY + bezel, width: cell.width, height: cell.height - bezel)
                case .top: screen = CGRect(x: cell.minX, y: cell.minY, width: cell.width, height: cell.height - bezel)
                case .left: screen = CGRect(x: cell.minX + bezel, y: cell.minY, width: cell.width - bezel, height: cell.height)
                case .right: screen = CGRect(x: cell.minX, y: cell.minY, width: cell.width - bezel, height: cell.height)
                case .none: break
                }
                ctx.saveGState()
                ctx.scaleBy(x: zoom, y: zoom)
                ctx.setFillColor(red: 0.02, green: 0.02, blue: 0.025, alpha: 1)
                ctx.fill(cell)
                ctx.setFillColor(red: 0.11, green: 0.12, blue: 0.17, alpha: 1)
                ctx.fill(screen)
                if row.edge != .none {
                    ctx.setStrokeColor(red: 0.45, green: 0.5, blue: 0.65, alpha: 0.7)
                    ctx.setLineWidth(0.6)
                    ctx.stroke(screen.insetBy(dx: 0.3, dy: 0.3))
                }
                let local: CGPoint
                let sw = screen.width, sh = screen.height
                switch row.edge {
                case .bottom: local = CGPoint(x: sw / 2, y: 0)
                case .top: local = CGPoint(x: sw / 2, y: sh)
                case .left: local = CGPoint(x: 0, y: sh * 0.42)
                case .right: local = CGPoint(x: sw, y: sh * 0.42)
                case .none:
                    if row.gesture == .parachute {
                        local = CGPoint(x: sw / 2, y: sh * 0.3)
                    } else if row.gesture == .popUp {
                        local = CGPoint(x: sw / 2, y: figure * 0.6)
                    } else {
                        local = CGPoint(x: sw / 2, y: sh * 0.36)
                    }
                }
                var position = local
                if row.gesture == .popUp {
                    switch row.edge {
                    case .bottom: position = CGPoint(x: sw / 2, y: figure * 0.5)
                    case .left: position = CGPoint(x: figure * 0.5, y: sh * 0.42)
                    default: break
                    }
                }
                ctx.translateBy(x: screen.minX, y: screen.minY)
                ctx.clip(to: CGRect(x: 0, y: 0, width: sw, height: sh))
                if row.prop != nil, row.gesture == .push || row.gesture == .pull || row.gesture == .build || row.gesture == .kick {
                    position.x = sw * (row.gesture == .pull ? 0.32 : 0.3)
                }
                var c = Critter(id: id, species: sp, position: position, heading: 0, speed: 0, size: Double(figure))
                id += 1
                c.antennaPhase = restPhase + col.t * 0.8
                c.tint = (Double(variant) + 0.5) / 5
                c.facing = row.edge == .right ? -1 : 1
                c.heading = row.gesture == .look ? 0.5 : 0
                c.gesture = row.gesture
                c.gestureTime = col.t
                c.gaitPhase = row.gesture == .tiptoe ? (col.t - 1) : col.t * (sp.isAirborne ? 1.6 : 0.9)
                if row.moving {
                    c.speed = Double(figure)
                    c.gaitPhase = col.t * 2.2
                }
                if fright { c.fright = 0.12; c.mode = .startled }
                if confused { c.confusion = 0.8 }
                let size = CGSize(width: sw, height: sh)
                let props = gestureProps(row, critter: c, figure: figure, t: col.t)
                if let leave = col.leave {
                    renderer.draw(Scene(size: size, light: 1, critters: [c], time: clock - 0.02, props: props), options: options, in: scratch)
                    c.gesture = row.after
                    c.gestureTime = 0
                    renderer.draw(Scene(size: size, light: 1, critters: [c], time: clock, props: props), options: options, in: scratch)
                    c.gestureTime = leave
                    c.gaitPhase += leave * 0.9
                    c.antennaPhase += leave * 0.8
                    if row.gesture == .parachute { c.position.y = max(figure * 0.5, c.position.y - CGFloat(leave) * figure) }
                    renderer.draw(Scene(size: size, light: 1, critters: [c], time: clock + leave, props: props), options: options, in: ctx)
                } else {
                    if row.prop != nil {
                        for k in 0..<12 {
                            var pre = c
                            let back = Double(12 - k) / 60
                            pre.gestureTime = max(0, c.gestureTime - back)
                            if row.moving { pre.gaitPhase -= back * 2.2 }
                            renderer.draw(Scene(size: size, light: 1, critters: [pre], time: clock - back, props: props), options: options, in: scratch)
                        }
                    }
                    renderer.draw(Scene(size: size, light: 1, critters: [c], time: clock, props: props), options: options, in: ctx)
                }
                clock += 10
                ctx.restoreGState()
                drawText(col.caption, at: CGPoint(x: (x0 + 2) * zoom, y: (bottom + 2) * zoom), size: 6 * zoom / 2.5 * 1.4, gray: 0.55, in: ctx)
            }
        }
    }
    guard let image = ctx.makeImage() else { fail("could not make image") }
    writePNG(image, to: out)
    print("wrote \(out) \(image.width)x\(image.height)")
}

let propScreenSize: [PropKind: Double] = [
    .acorn: 12, .leafPile: 34, .pumpkin: 20, .candy: 11, .lantern: 18, .snowball: 16, .snowman: 48, .igloo: 50,
    .present: 18, .giftStack: 40, .tree: 56, .egg: 13, .flower: 16, .nest: 26, .shell: 12, .sandcastle: 44,
    .ball: 14, .rope: 16, .cake: 34, .balloon: 28, .banner: 16, .campfire: 36, .crumb: 7,
]

func propsFlag(_ args: Arguments) -> [PropKind] {
    guard let names = args.flags["kind"] else { return PropKind.allCases }
    return names.split(separator: ",").map { name in
        guard let k = PropKind.allCases.first(where: { $0.rawValue.lowercased() == name.lowercased() }) else { fail("unknown prop kind \(name)") }
        return k
    }
}

func runProps(_ args: Arguments) {
    guard let out = args.positional.first else {
        fail("usage: ScuttleSnap props <out.png|dir> [--style a,b] [--kind a,b] [--big 84] [--small 1] [--scale 2] [--light] [--time 1.3]")
    }
    let styles = stylesFlag(args)
    let kinds = propsFlag(args)
    let big = CGFloat(args.double("big", 84))
    let smallK = CGFloat(args.double("small", 1))
    let scale = CGFloat(args.double("scale", 2))
    let time = args.double("time", 1.3)
    let lightBack = args.flags["light"] != nil
    let label: CGFloat = 92
    let cols = kinds.map { PropCatalog.stages($0) + ($0 == .rope || $0 == .banner ? 0 : PropCatalog.variants($0)) }.max() ?? 8
    let smallCell: CGFloat = 64, bigCell = big * 1.45
    let rowH = max(big * 1.5, 70)
    let width = label + smallCell * CGFloat(cols) + 16 + bigCell * CGFloat(cols) + 8
    let height = rowH * CGFloat(kinds.count) + 30
    for style in styles {
        let ctx = makeContext(width: width, height: height, scale: scale)
        if lightBack {
            ctx.setFillColor(red: 0.93, green: 0.92, blue: 0.9, alpha: 1)
        } else {
            ctx.setFillColor(red: 0.075, green: 0.085, blue: 0.13, alpha: 1)
        }
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let gray: CGFloat = lightBack ? 0.2 : 0.85
        drawText("\(style.title) props, small = on-screen size x\(smallK), big = \(Int(big)) pt", at: CGPoint(x: 10, y: height - 20), size: 12, gray: gray, in: ctx)
        var list: [Prop] = []
        var id = 0
        for (row, kind) in kinds.enumerated() {
            let top = height - 30 - rowH * CGFloat(row)
            let mid = top - rowH * 0.5
            if row % 2 == 1 {
                ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: lightBack ? 0.35 : 0.03)
                ctx.fill(CGRect(x: 0, y: top - rowH, width: width, height: rowH))
            }
            drawText(kind.rawValue, at: CGPoint(x: 8, y: mid + 2), size: 11, gray: gray, in: ctx)
            let n = PropCatalog.stages(kind)
            let vs = kind == .rope || kind == .banner ? 0 : PropCatalog.variants(kind)
            drawText("\(n) stage\(n == 1 ? "" : "s"), \(max(1, vs)) var", at: CGPoint(x: 8, y: mid - 11), size: 7.5, gray: gray, alpha: 0.6, in: ctx)
            var cells: [(Int, Int, String)] = (0..<n).map { (0, $0, n > 1 ? "s\($0)" : "") }
            cells += (0..<vs).map { (1, $0, "v\($0)") }
            if kind == .rope || kind == .banner {
                cells = [(2, 0, "line"), (3, 0, "free"), (2, 1, "long")]
            }
            for (i, cell) in cells.enumerated() {
                for enlarged in [false, true] {
                    let size = enlarged ? enlargedSize(kind, big: Double(big)) : propScreenSize[kind, default: 16] * Double(smallK)
                    let x0 = enlarged ? label + smallCell * CGFloat(cols) + 16 + bigCell * CGFloat(i) : label + smallCell * CGFloat(i)
                    let cw = enlarged ? bigCell : smallCell
                    let cx = x0 + cw / 2
                    let ground = top - rowH * (enlarged ? 0.84 : 0.66)
                    let stage = cell.0 == 0 ? cell.1 : n - 1
                    let variant = cell.0 == 1 ? cell.1 : 0
                    var p = Prop(id: id, kind: kind, position: CGPoint(x: cx, y: ground + CGFloat(size) * 0.46), size: size,
                                 progress: PropCatalog.progress(kind, stage: stage), age: 5, variant: variant)
                    id += 1
                    if cell.0 == 2 || (kind == .banner && cell.0 == 3) {
                        let reach = cw * (cell.1 == 1 ? 0.46 : 0.36)
                        p.position = CGPoint(x: cx - reach, y: ground + CGFloat(size) * (kind == .banner ? 1.6 : 0.4))
                        p.end = CGPoint(x: cx + reach, y: ground + CGFloat(size) * (kind == .banner ? 1.5 : 0.2))
                    }
                    list.append(p)
                    if !enlarged { drawText(cell.2, at: CGPoint(x: x0 + 3, y: top - rowH + 4), size: 7, gray: gray, alpha: 0.55, in: ctx) }
                }
            }
        }
        let renderer = SceneRenderer()
        renderer.draw(Scene(size: CGSize(width: width, height: height), light: 1, critters: [], time: time, props: list),
                      options: RenderOptions(darkness: false, style: style), in: ctx)
        guard let image = ctx.makeImage() else { fail("could not make image") }
        let path = out.hasSuffix(".png") ? (styles.count == 1 ? out : out.replacingOccurrences(of: ".png", with: "-\(style.rawValue).png")) : "\(out)/props-\(style.rawValue).png"
        writePNG(image, to: path)
        print("wrote \(path) \(image.width)x\(image.height)")
    }
}

func enlargedSize(_ kind: PropKind, big: Double) -> Double {
    switch kind {
    case .crumb, .candy, .acorn, .shell, .egg, .ball: return big * 0.7
    case .rope, .banner: return big * 0.35
    default: return big
    }
}

struct Vignette {
    var title: String
    var critters: [Critter]
    var props: [Prop]
    var walkers: Set<Int> = []
}

func critter(_ id: Int, _ s: Species, _ x: CGFloat, _ y: CGFloat, size: Double = 26, gesture: Gesture = .none, t: Double = 1, facing: Double = 1, tint: Int = 0) -> Critter {
    var c = Critter(id: id, species: s, position: CGPoint(x: x, y: y + CGFloat(size) * 0.46), heading: facing < 0 ? .pi : 0, speed: 0, size: size)
    c.facing = facing
    c.gesture = gesture
    c.gestureTime = t
    c.antennaPhase = restPhase + t
    c.tint = (Double(tint) + 0.5) / 5
    return c
}

func prop(_ id: Int, _ k: PropKind, _ x: CGFloat, _ y: CGFloat, size: Double, progress: Double = 1, holder: Int? = nil, partner: Int? = nil, end: CGPoint? = nil, variant: Int = 0, rotation: Double = 0) -> Prop {
    Prop(id: id, kind: k, position: CGPoint(x: x, y: y + CGFloat(size) * 0.46), size: size, rotation: rotation, progress: progress,
         holder: holder, partner: partner, end: end, age: 5, variant: variant)
}

func vignettes(time t: Double) -> [Vignette] {
    var out: [Vignette] = []
    var a = critter(1, .hedgehog, 120, 40, size: 30, gesture: .carry, t: t)
    a.speed = 20
    a.gaitPhase = t * 1.6
    var a2 = critter(2, .chick, 50, 46, size: 22, gesture: .carry, t: t + 0.4, facing: 1)
    a2.speed = 18
    a2.gaitPhase = t * 2.2
    out.append(Vignette(title: "carry: acorn overhead, flower", critters: [a, a2],
                        props: [prop(10, .acorn, 0, 0, size: 13, holder: 1), prop(11, .flower, 0, 0, size: 15, holder: 2, variant: 0)], walkers: [1, 2]))
    var p1 = critter(3, .penguin, 70, 46, size: 28, gesture: .push, t: t)
    var p2 = critter(4, .polarBear, 92, 32, size: 32, gesture: .push, t: t + 0.3)
    p1.speed = 6; p2.speed = 6
    p1.gaitPhase = t * 1.1; p2.gaitPhase = t * 1.0 + 0.3
    out.append(Vignette(title: "two pushing a big snowball", critters: [p1, p2],
                        props: [prop(12, .snowball, 130, 30, size: 40, rotation: -t * 0.9)], walkers: [3, 4]))
    let b1 = critter(5, .elf, 70, 40, size: 28, gesture: .build, t: t)
    let b2 = critter(6, .reindeer, 196, 44, size: 32, gesture: .build, t: t + 1.1, facing: -1)
    var b3 = critter(7, .penguin, 236, 26, size: 24, gesture: .carry, t: t, facing: -1)
    b3.speed = 16
    b3.gaitPhase = t * 2
    out.append(Vignette(title: "crew around a half-built snowman", critters: [b1, b2, b3],
                        props: [prop(13, .snowman, 134, 46, size: 66, progress: 0.7, variant: 1), prop(15, .snowball, 30, 22, size: 12, progress: 0, variant: 1),
                                prop(14, .snowball, 0, 0, size: 12, holder: 7)], walkers: [7]))
    let t1 = critter(8, .fox, 60, 40, size: 30, gesture: .pull, t: t)
    let t2 = critter(9, .bunny, 220, 40, size: 28, gesture: .pull, t: t + 0.45, facing: -1)
    out.append(Vignette(title: "tug of war", critters: [t1, t2],
                        props: [prop(16, .rope, 0, 0, size: 28, progress: 1, holder: 8, partner: 9)]))
    let k1 = critter(10, .frog, 90, 40, size: 28, gesture: .kick, t: 0.4)
    let k2 = critter(11, .bunny, 230, 40, size: 26, gesture: .none, t: t, facing: -1)
    out.append(Vignette(title: "a ball mid-kick", critters: [k1, k2],
                        props: [prop(17, .ball, 126, 50, size: 15, rotation: -0.8)]))
    let c1 = critter(12, .owl, 70, 40, size: 30, gesture: .count, t: t * 1.0 + 2.2, facing: -1)
    var c2 = critter(13, .hedgehog, 196, 40, size: 24, gesture: .tiptoe, t: t)
    c2.speed = 10
    c2.gaitPhase = t * 1.3
    out.append(Vignette(title: "hide and seek: one counting", critters: [c1, c2],
                        props: [prop(18, .tree, 40, 34, size: 70, progress: 0), prop(19, .giftStack, 240, 34, size: 40, progress: 1, variant: 1)], walkers: [13]))
    let f1 = critter(14, .hedgehog, 96, 54, size: 26, gesture: .perch, t: t)
    let f2 = critter(15, .fox, 186, 54, size: 28, gesture: .perch, t: t + 1, facing: -1)
    let f3 = critter(16, .owl, 140, 18, size: 28, gesture: .perch, t: t + 2, facing: -1)
    out.append(Vignette(title: "campfire with three sitting", critters: [f1, f2, f3],
                        props: [prop(20, .campfire, 140, 48, size: 34, progress: 1)]))
    let g1 = critter(17, .bunny, 112, 40, size: 26, gesture: .carry, t: t)
    let g2 = critter(18, .chick, 146, 40, size: 22, gesture: .carry, t: t + 0.6)
    let g3 = critter(19, .gingerbread, 200, 24, size: 24, gesture: .cheer, t: t)
    out.append(Vignette(title: "party: banner, cake, balloon", critters: [g1, g2, g3],
                        props: [Prop(id: 21, kind: .banner, position: CGPoint(x: 40, y: 118), size: 15, progress: 0.75, end: CGPoint(x: 240, y: 118), age: 5),
                                prop(23, .balloon, 0, 0, size: 30, holder: 19, variant: 1),
                                prop(22, .cake, 0, 0, size: 22, progress: 1, holder: 17, partner: 18)]))
    var s1 = critter(20, .crab, 70, 40, size: 22, gesture: .carry, t: t)
    s1.speed = 8
    s1.gaitPhase = t * 2
    var s2 = critter(21, .turtle, 210, 30, size: 26, gesture: .carry, t: t, facing: -1)
    s2.speed = 6
    s2.gaitPhase = t
    out.append(Vignette(title: "beach: sandcastle, shell carried", critters: [s1, s2],
                        props: [prop(24, .sandcastle, 132, 40, size: 50, progress: 0.7), prop(26, .ball, 250, 70, size: 16, variant: 0),
                                prop(25, .shell, 0, 0, size: 12, holder: 21, variant: 0), prop(38, .shell, 0, 0, size: 11, holder: 20, variant: 2)], walkers: [20, 21]))
    let n1 = critter(22, .robin, 80, 40, size: 22, gesture: .build, t: t)
    var n2 = critter(23, .butterfly, 200, 90, size: 22, gesture: .carry, t: t, facing: -1)
    n2.speed = 14
    n2.gaitPhase = t * 3
    let n3 = critter(24, .chick, 230, 30, size: 22, gesture: .push, t: t, facing: -1)
    out.append(Vignette(title: "spring: nest with eggs, flyer carrying, egg pushed", critters: [n1, n2, n3],
                        props: [prop(27, .nest, 130, 40, size: 32, progress: 1),
                                prop(40, .egg, 130 - 6.4, 40 + 9.6, size: 11, variant: 0), prop(41, .egg, 130 + 6.4, 40 + 9.6, size: 11, variant: 2),
                                prop(42, .egg, 130, 40 + 11.5, size: 11, variant: 3),
                                prop(28, .flower, 0, 0, size: 14, holder: 23, variant: 3),
                                prop(29, .egg, 207, 30, size: 11, variant: 1, rotation: -t)], walkers: [23]))
    let l1 = critter(25, .hedgehog, 90, 40, size: 26, gesture: .build, t: t)
    var l2 = critter(26, .acorn, 200, 34, size: 22, gesture: .carry, t: t, facing: -1)
    l2.speed = 12
    l2.gaitPhase = t * 1.5
    out.append(Vignette(title: "autumn: leaf pile, pumpkin, lantern", critters: [l1, l2],
                        props: [prop(30, .leafPile, 150, 40, size: 52, progress: 0.6), prop(32, .pumpkin, 40, 30, size: 26, progress: 1, variant: 1),
                                prop(33, .candy, 250, 26, size: 10, variant: 2), prop(31, .lantern, 0, 0, size: 14, holder: 26, variant: 0)], walkers: [26]))
    let w1 = critter(27, .santa, 76, 40, size: 30, gesture: .build, t: t)
    let w2 = critter(28, .elf, 236, 34, size: 24, gesture: .carry, t: t, facing: -1)
    out.append(Vignette(title: "winter: present stack, tree, igloo", critters: [w1, w2],
                        props: [prop(37, .igloo, 40, 70, size: 50, progress: 0.6), prop(36, .tree, 190, 50, size: 66, progress: 0.6),
                                prop(34, .giftStack, 130, 40, size: 40, progress: 0.5), prop(35, .present, 0, 0, size: 15, holder: 28, variant: 3)]))
    var o1 = critter(29, .ghost, 70, 60, size: 28, gesture: .carry, t: t)
    o1.speed = 10
    var o2 = critter(30, .ladybird, 150, 30, size: 22, gesture: .carry, t: t)
    o2.speed = 10
    o2.gaitPhase = t * 2
    var o3 = critter(31, .bumblebee, 230, 70, size: 22, gesture: .carry, t: t, facing: -1)
    o3.speed = 12
    o3.gaitPhase = t * 3
    out.append(Vignette(title: "floater in front, top-down on back, flyer below", critters: [o1, o2, o3],
                        props: [prop(43, .candy, 0, 0, size: 11, holder: 29, variant: 0), prop(44, .acorn, 0, 0, size: 11, holder: 30),
                                prop(45, .flower, 0, 0, size: 14, holder: 31, variant: 2)], walkers: [30, 31]))
    return out
}

func runPropScene(_ args: Arguments) {
    guard let out = args.positional.first else {
        fail("usage: ScuttleSnap propscene <out.png> [--style a,b] [--time 1.2] [--scale 2] [--columns 3] [--only 0,3] [--light 0.3]")
    }
    let styles = stylesFlag(args)
    let time = args.double("time", 1.2)
    let scale = CGFloat(args.double("scale", 2))
    let columns = max(1, args.int("columns", 3))
    let light = args.double("light", 0.3)
    var list = vignettes(time: time)
    if let only = args.flags["only"] {
        let keep = Set(only.split(separator: ",").compactMap { Int($0) })
        list = list.enumerated().filter { keep.contains($0.offset) }.map(\.element)
    }
    let fk = figureScaleFlag(args)
    let world = CGSize(width: 280, height: 150)
    let panel = CGSize(width: world.width * CGFloat(fk), height: world.height * CGFloat(fk))
    let gap: CGFloat = 8, label: CGFloat = 16
    let rows = (list.count + columns - 1) / columns
    let width = CGFloat(columns) * (panel.width + gap) + gap
    let blockH = CGFloat(rows) * (panel.height + label + gap) + 22
    let height = blockH * CGFloat(styles.count)
    let ctx = makeContext(width: width, height: height, scale: scale)
    ctx.setFillColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1)
    ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let backdropCtx = makeContext(width: panel.width, height: panel.height, scale: scale)
    drawBackdrop(size: CGSize(width: panel.width * 3, height: panel.height * 3), in: backdropCtx)
    guard let backdrop = backdropCtx.makeImage() else { fail("could not make backdrop") }
    let scratch = makeContext(width: 4, height: 4, scale: scale)
    for (si, style) in styles.enumerated() {
        let renderer = SceneRenderer()
        let options = RenderOptions(darkness: true, style: style)
        let blockTop = height - blockH * CGFloat(si)
        drawText(style.title, at: CGPoint(x: gap, y: blockTop - 16), size: 13, gray: 0.92, in: ctx)
        for (i, v) in list.enumerated() {
            let col = i % columns, row = i / columns
            let x = gap + CGFloat(col) * (panel.width + gap)
            let y = blockTop - 22 - CGFloat(row + 1) * (panel.height + label + gap) + gap
            drawText(v.title, at: CGPoint(x: x + 2, y: y + panel.height + 4), size: 9, gray: 0.8, in: ctx)
            for k in 0..<24 {
                let back = Double(24 - k) / 60
                let crits = v.critters.map { c -> Critter in
                    var c = c
                    c.gestureTime = max(0, c.gestureTime - back)
                    if v.walkers.contains(c.id) { c.gaitPhase -= back * 1.6 }
                    return c
                }
                renderer.draw(Scene(size: panel, light: light, critters: crits, time: time - back + Double(i) * 100, props: v.props, scale: fk), options: options, in: scratch)
            }
            ctx.saveGState()
            ctx.translateBy(x: x, y: y)
            ctx.clip(to: CGRect(origin: .zero, size: panel))
            ctx.draw(backdrop, in: CGRect(x: -CGFloat(i % 3) * 40 * CGFloat(fk), y: 0, width: panel.width * 1.4, height: panel.height * 1.4))
            renderer.draw(Scene(size: panel, light: light, critters: v.critters, time: time + Double(i) * 100, props: v.props, scale: fk), options: options, in: ctx)
            ctx.restoreGState()
        }
    }
    guard let image = ctx.makeImage() else { fail("could not make image") }
    writePNG(image, to: out)
    print("wrote \(out) \(image.width)x\(image.height)")
}

func runCatch(_ args: Arguments) {
    guard let out = args.positional.first else {
        fail("usage: ScuttleSnap catch <out.png> [--style name] [--season name] [--darken on|off] [--size 1512x982] [--frames 16] [--from -0.1] [--to 3] [--columns 4] [--thumb 0.5] [--seed N] [--population N] [--settle 40] [--open 0.35] [--angle 20] [--dir framesdir] [--fps 20] [--figure-scale k] [--quirk name] [--wake] [--stage] [--trace]")
    }
    let style = styleFlag(args)
    let size = args.size("size", CGSize(width: 1512, height: 982))
    let k = figureScaleFlag(args)
    let darken = darkenFlag(args, false)
    let count = max(1, args.int("frames", 16))
    let from = args.double("from", -0.1), to = args.double("to", 3)
    let columns = max(1, args.int("columns", 4))
    let thumb = CGFloat(max(0.1, args.double("thumb", 0.5)))
    let openTime = max(0.01, args.double("open", 0.35))
    let low = args.double("angle", 20)
    var config = WorldConfig()
    config.seed = UInt64(max(0, args.int("seed", 1)))
    config.population = args.int("population", config.population)
    let season = seasonFlag(args) ?? .autumn
    config.season = season
    let weather = weatherFlag(args), night = nightFlag(args)
    config.weather = weather
    config.night = night
    let world = World(size: worldOf(size, k), config: config)
    world.tuning.growthSeconds = 0
    world.tuning.forceRare = false
    if let q = args.flags["quirk"] { world.tuning.forceCatchQuirk = CatchQuirk(rawValue: q) }
    let dt = 1.0 / 60
    var clock = 0.0
    let settle = args.double("settle", 40)
    let staged = args.flags["stage"] != nil
    if staged {
        world.settleInDark(seconds: args.double("settle", 20))
    } else {
        while clock < settle {
            world.step(dt: dt, lidAngle: low)
            clock += dt
        }
    }
    _ = world.drainEvents()
    if args.flags["wake"] != nil { world.wakeCatch() }
    var woke = false
    let renderer = SceneRenderer()
    let backdropCtx = makeContext(width: size.width, height: size.height, scale: 1)
    drawBackdrop(size: size, in: backdropCtx)
    guard let backdrop = backdropCtx.makeImage() else { fail("could not make backdrop") }
    let frameCtx = makeContext(width: size.width, height: size.height, scale: 1)
    let tw = size.width * thumb, th = size.height * thumb
    let rows = (count + columns - 1) / columns
    let label: CGFloat = 18, gap: CGFloat = 6
    let sheetW = CGFloat(columns) * (tw + gap) + gap
    let sheetH = CGFloat(rows) * (th + label + gap) + gap
    let sheet = makeContext(width: sheetW, height: sheetH, scale: 1)
    sheet.setFillColor(red: 0.08, green: 0.08, blue: 0.1, alpha: 1)
    sheet.fill(CGRect(x: 0, y: 0, width: sheetW, height: sheetH))
    let times = (0..<count).map { i in count == 1 ? from : from + (to - from) * Double(i) / Double(count - 1) }
    let dir = args.flags["dir"]
    let fps = max(1, args.double("fps", 20))
    var nextDump = from
    var dumped = 0
    var t = from - 0.5
    var shot = 0
    var gone: Double?
    func angle(_ t: Double) -> Double {
        if staged { return t <= 0 ? 0 : 110 }
        if t <= 0 { return low }
        let u = min(1, t / openTime)
        let e = u < 0.5 ? 2 * u * u : 1 - pow(-2 * u + 2, 2) / 2
        return low + (110 - low) * e
    }
    func render(_ t: Double) -> CGImage {
        frameCtx.draw(backdrop, in: CGRect(origin: .zero, size: size))
        renderer.draw(Scene(size: size, light: world.light, critters: world.critters, time: clock, props: world.props, scale: k),
                      options: RenderOptions(darkness: darken, season: season, weather: weather, night: night, style: style), in: frameCtx)
        guard let image = frameCtx.makeImage() else { fail("could not make frame") }
        return image
    }
    while shot < count || (dir != nil && t <= to + 1e-9) {
        if t > to + 1e-9 && shot >= count { break }
        while shot < count && t >= times[shot] - 1e-9 {
            let image = render(t)
            let col = shot % columns, row = shot / columns
            let x = gap + CGFloat(col) * (tw + gap)
            let y = sheetH - CGFloat(row + 1) * (th + label + gap)
            sheet.draw(image, in: CGRect(x: x, y: y, width: tw, height: th))
            drawText(String(format: "%+.2fs  %d out", times[shot], world.critters.count), at: CGPoint(x: x + 2, y: y + th + 4), size: 11, gray: 0.9, in: sheet)
            shot += 1
        }
        if let dir, t >= nextDump - 1e-9, t <= to + 1e-9 {
            writePNG(render(t), to: String(format: "%@/f-%04d.png", dir, dumped))
            dumped += 1
            nextDump += 1 / fps
        }
        if staged && t < 0 {
            t += dt
            continue
        }
        if staged && !woke {
            woke = true
            world.catchNow()
        }
        world.step(dt: dt, lidAngle: angle(t + dt))
        clock += dt
        t += dt
        if gone == nil && t > 0 && world.critters.isEmpty { gone = t }
        if args.flags["trace"] != nil, abs(t * 4 - (t * 4).rounded()) < dt * 2, t > 0 {
            let list = world.critters.map { c in String(format: "%d:%@:%@:%@ (%.0f,%.0f) v%.0f", c.id, c.species.rawValue, c.mode.rawValue, c.quirk.rawValue, c.position.x, c.position.y, c.speed) }
            print(String(format: "t %.2f stray %@  ", t, world.stragglerID.map(String.init) ?? "-") + list.joined(separator: " | "))
        }
    }
    while gone == nil && t < 8 {
        world.step(dt: dt, lidAngle: 110)
        t += dt
        if world.critters.isEmpty { gone = t }
    }
    guard let image = sheet.makeImage() else { fail("could not make sheet") }
    writePNG(image, to: out)
    print(String(format: "wrote %@ %dx%d, all gone at %.2fs after the snap", out, image.width, image.height, gone ?? -1))
}

func benchProps(count: Int, critters: [Critter], size: CGSize) -> [Prop] {
    let kinds: [PropKind] = [.acorn, .snowman, .present, .snowball, .campfire, .ball, .rope, .leafPile, .cake, .lantern, .tree, .balloon, .giftStack, .egg, .banner, .sandcastle, .pumpkin]
    var rng = SplitMixLite(seed: 11)
    var out: [Prop] = []
    for i in 0..<count {
        let kind = kinds[i % kinds.count]
        let holder: Int? = (kind == .acorn || kind == .present || kind == .snowball || kind == .egg || kind == .balloon) && i < critters.count ? critters[i].id : nil
        let partner: Int? = kind == .rope && i + 1 < critters.count ? critters[i + 1].id : nil
        let ropeHolder: Int? = kind == .rope && i < critters.count ? critters[i].id : nil
        let big: Bool = [.snowman, .campfire, .leafPile, .cake, .tree, .giftStack, .sandcastle].contains(kind)
        let sz = big ? 36 + rng.unit() * 20 : 12 + rng.unit() * 8
        var p = Prop(id: 5000 + i, kind: kind, position: CGPoint(x: 40 + rng.unit() * (size.width - 80), y: 40 + rng.unit() * (size.height - 80)),
                     size: sz, progress: big ? 1 : 1, holder: holder ?? ropeHolder, partner: partner, age: 3, variant: i)
        if kind == .banner { p.end = CGPoint(x: p.position.x + 120, y: p.position.y + 10) }
        out.append(p)
    }
    return out
}

let raw = Array(CommandLine.arguments.dropFirst())
guard let command = raw.first else {
    fail("""
    usage: ScuttleSnap <command> ...
      sheet <out.png> [--style name] [--species a,b] [--group festive] [--season name] [--weather name] [--night] [--frames 8|16] [--only moods,frames,variants,idle,motion] [--variant 0] [--zoom 2.5] [--size 28] [--scale 1]
      styles <out.png> [--species a,b,c] [--group festive] [--style kawaii,sticker] [--mood calm] [--variant 0|all] [--phase 0.2] [--big 96] [--small 32] [--scale 2]
      timeline <timeline.json> <outdir> [--fps 4] [--size 1512x982] [--seed N] [--population N] [--scale 2] [--season name] [--weather name] [--night] [--style name]
      bench [--frames 300] [--critters 120] [--size 1512x982] [--scale 2] [--season name] [--style name] [--gesture name] [--props 15]
      seasons <out.png> [--size 1512x982] [--scale 1] [--columns 2] [--light 0.1] [--time 6] [--population 24] [--only a,b] [--weather name] [--night] [--style name]
      weather <out.png> [--season name] [--size 1512x982] [--scale 1] [--columns 2] [--light 0.1] [--time 6] [--population 24] [--only a,b] [--night] [--style name]
      gestures <out.png> [--style name] [--species a,b,c] [--only peek,dance] [--cols 0-6] [--size 30] [--zoom 2.5] [--scale 1] [--variant 0] [--fright] [--confused]
      props <out.png|dir> [--style a,b] [--kind a,b] [--big 84] [--small 1] [--scale 2] [--light] [--time 1.3]
      propscene <out.png> [--style a,b] [--time 1.2] [--scale 2] [--columns 3] [--only 0,3] [--light 0.3]
      catch <out.png> [--style name] [--season name] [--darken on|off] [--frames 16] [--from -0.1] [--to 3] [--thumb 0.5] [--dir framesdir] [--fps 20] [--wake] [--stage]
    """)
}
let parsed = Arguments(Array(raw.dropFirst()))
switch command {
case "sheet": runSheet(parsed)
case "styles": runStyles(parsed)
case "timeline": runTimeline(parsed)
case "bench": runBench(parsed)
case "seasons": runSeasons(parsed)
case "weather": runWeather(parsed)
case "gestures": runGestures(parsed)
case "props": runProps(parsed)
case "propscene": runPropScene(parsed)
case "catch": runCatch(parsed)
default: fail("unknown subcommand \(command); expected sheet, styles, timeline, bench, seasons, weather, gestures, props, propscene or catch")
}
