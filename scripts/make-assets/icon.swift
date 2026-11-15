import Foundation
import CoreGraphics
import ImageIO

struct RNG {
    var s: UInt64
    mutating func next() -> CGFloat {
        s ^= s << 13
        s ^= s >> 7
        s ^= s << 17
        return CGFloat(s % 1_000_000) / 1_000_000
    }
    mutating func range(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
        a + (b - a) * next()
    }
}

let space = CGColorSpace(name: CGColorSpace.sRGB)!

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(
        colorSpace: space,
        components: [
            CGFloat((hex >> 16) & 0xff) / 255,
            CGFloat((hex >> 8) & 0xff) / 255,
            CGFloat(hex & 0xff) / 255,
            a,
        ])!
}

func gradient(_ stops: [(CGFloat, CGColor)]) -> CGGradient {
    CGGradient(
        colorsSpace: space,
        colors: stops.map { $0.1 } as CFArray,
        locations: stops.map { $0.0 })!
}

struct Canvas {
    let ctx: CGContext
    let px: Int
    let scale: CGFloat

    init(px: Int, unit: CGFloat) {
        self.px = px
        scale = CGFloat(px) / unit
        ctx = CGContext(
            data: nil, width: px, height: px, bitsPerComponent: 8, bytesPerRow: 0,
            space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.translateBy(x: 0, y: CGFloat(px))
        ctx.scaleBy(x: scale, y: -scale)
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        ctx.interpolationQuality = .high
    }

    func shadow(dx: CGFloat, dy: CGFloat, blur: CGFloat, color: CGColor) {
        ctx.setShadow(offset: CGSize(width: dx * scale, height: -dy * scale), blur: blur * scale, color: color)
    }

    func softFill(_ path: CGPath, color: CGColor, blur: CGFloat, dx: CGFloat = 0, dy: CGFloat = 0) {
        let far: CGFloat = 4000
        ctx.saveGState()
        shadow(dx: dx + far, dy: dy, blur: blur, color: color)
        ctx.translateBy(x: -far, y: 0)
        ctx.addPath(path)
        ctx.setFillColor(rgb(0x000000))
        ctx.fillPath()
        ctx.restoreGState()
    }

    func radial(_ g: CGGradient, cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat, rot: CGFloat = 0) {
        ctx.saveGState()
        ctx.translateBy(x: cx, y: cy)
        ctx.rotate(by: rot)
        ctx.scaleBy(x: 1, y: ry / rx)
        ctx.drawRadialGradient(
            g, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: rx, options: [])
        ctx.restoreGState()
    }

    func linear(_ g: CGGradient, from: CGPoint, to: CGPoint) {
        ctx.drawLinearGradient(
            g, start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    }

    func image() -> CGImage { ctx.makeImage()! }
}

func writePNG(_ image: CGImage, _ path: String) {
    let url = URL(fileURLWithPath: path) as CFURL
    let dest = CGImageDestinationCreateWithURL(url, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    if !CGImageDestinationFinalize(dest) {
        FileHandle.standardError.write("failed to write \(path)\n".data(using: .utf8)!)
        exit(1)
    }
}

func squircle(_ rect: CGRect, n: CGFloat = 5) -> CGPath {
    let p = CGMutablePath()
    let steps = 720
    for i in 0..<steps {
        let t = CGFloat(i) / CGFloat(steps) * 2 * .pi
        let c = cos(t)
        let s = sin(t)
        let x = rect.midX + rect.width / 2 * (c < 0 ? -1 : 1) * pow(abs(c), 2 / n)
        let y = rect.midY + rect.height / 2 * (s < 0 ? -1 : 1) * pow(abs(s), 2 / n)
        if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
    }
    p.closeSubpath()
    return p
}

func pebble(cx: CGFloat, cy: CGFloat, rx: CGFloat, ry: CGFloat, rot: CGFloat, n: CGFloat = 2.5, wobble: CGFloat = 1) -> CGPath {
    let p = CGMutablePath()
    let steps = 360
    for i in 0..<steps {
        let t = CGFloat(i) / CGFloat(steps) * 2 * .pi
        let c = cos(t)
        let s = sin(t)
        let w = 1 + wobble * (0.035 * sin(2 * t + 1.1) + 0.022 * sin(3 * t + 0.4) + 0.012 * sin(5 * t + 2.0))
        let lx = rx * w * (c < 0 ? -1 : 1) * pow(abs(c), 2 / n)
        let ly = ry * w * (s < 0 ? -1 : 1) * pow(abs(s), 2 / n)
        let x = cx + lx * cos(rot) - ly * sin(rot)
        let y = cy + lx * sin(rot) + ly * cos(rot)
        if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
    }
    p.closeSubpath()
    return p
}

func translated(_ path: CGPath, dx: CGFloat, dy: CGFloat) -> CGPath {
    var t = CGAffineTransform(translationX: dx, y: dy)
    return path.copy(using: &t)!
}

let ink: UInt32 = 0x2a2c44

struct Detail {
    var full: Bool
    var tiny: Bool
}

func drawHero(_ cv: Canvas, x: CGFloat, y: CGFloat, size L: CGFloat, heading: CGFloat, look: CGPoint, detail: Detail) {
    let ctx = cv.ctx
    let line: CGFloat = detail.tiny ? 0.075 : (detail.full ? 0.042 : 0.055)

    ctx.saveGState()
    ctx.translateBy(x: x, y: y)
    cv.radial(
        gradient([(0, rgb(0x5a4a10, 0.5)), (0.7, rgb(0x5a4a10, 0.3)), (1, rgb(0x5a4a10, 0))]),
        cx: -0.02 * L, cy: 0.5 * L, rx: 0.56 * L, ry: 0.16 * L)
    ctx.rotate(by: heading)
    ctx.scaleBy(x: L, y: L)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    let feet: [(CGPoint, CGPoint)] = [
        (CGPoint(x: 0.28, y: -0.08), CGPoint(x: 0.43, y: -0.17)),
        (CGPoint(x: 0.34, y: 0.14), CGPoint(x: 0.49, y: 0.15)),
        (CGPoint(x: 0.27, y: 0.36), CGPoint(x: 0.40, y: 0.46)),
    ]
    for pass in 0..<2 {
        ctx.setStrokeColor(rgb(pass == 0 ? ink : 0x4c4660))
        ctx.setLineWidth(pass == 0 ? 0.15 + line : 0.15 - line)
        for (a, b) in feet {
            for m in [1, -1] as [CGFloat] {
                ctx.move(to: CGPoint(x: a.x * m, y: a.y))
                ctx.addLine(to: CGPoint(x: b.x * m, y: b.y))
            }
        }
        ctx.strokePath()
    }

    let bobbles = detail.tiny ? [] : [CGPoint(x: 0.25, y: -0.66), CGPoint(x: -0.25, y: -0.66)]
    ctx.setStrokeColor(rgb(ink))
    ctx.setLineWidth(line * 1.15)
    for (i, bob) in bobbles.enumerated() {
        let m: CGFloat = i == 0 ? 1 : -1
        ctx.move(to: CGPoint(x: 0.1 * m, y: -0.38))
        ctx.addQuadCurve(to: bob, control: CGPoint(x: 0.1 * m, y: -0.6))
    }
    ctx.strokePath()
    for bob in bobbles {
        let r: CGFloat = detail.tiny ? 0.07 : 0.058
        ctx.setFillColor(rgb(ink))
        ctx.fillEllipse(in: CGRect(x: bob.x - r, y: bob.y - r, width: 2 * r, height: 2 * r))
        if !detail.tiny {
            let q = r - line * 0.75
            ctx.setFillColor(rgb(0xffd24a))
            ctx.fillEllipse(in: CGRect(x: bob.x - q, y: bob.y - q, width: 2 * q, height: 2 * q))
        }
    }

    let headRect = CGRect(x: -0.27, y: -0.47, width: 0.54, height: 0.42)
    ctx.setFillColor(rgb(0x4c4660))
    ctx.setStrokeColor(rgb(ink))
    ctx.setLineWidth(line)
    ctx.addEllipse(in: headRect)
    ctx.drawPath(using: .fillStroke)

    let bodyRect = CGRect(x: -0.4, y: -0.24, width: 0.8, height: 0.76)
    let body = CGPath(ellipseIn: bodyRect, transform: nil)
    ctx.saveGState()
    ctx.addPath(body)
    ctx.clip()
    ctx.setFillColor(rgb(0xd8343a))
    ctx.fill(bodyRect)
    ctx.setFillColor(rgb(0xf4534a))
    ctx.fillEllipse(in: bodyRect.offsetBy(dx: 0.05, dy: -0.06))
    if !detail.tiny {
        ctx.setFillColor(rgb(0xff8a78, 0.9))
        ctx.saveGState()
        ctx.translateBy(x: 0.19, y: -0.04)
        ctx.rotate(by: 0.6)
        ctx.fillEllipse(in: CGRect(x: -0.045, y: -0.11, width: 0.09, height: 0.22))
        ctx.restoreGState()
    }
    ctx.setFillColor(rgb(ink))
    let spots: [(CGFloat, CGFloat, CGFloat)] = detail.tiny
        ? [(0.19, 0.08, 0.085), (-0.19, 0.08, 0.085), (0.13, 0.32, 0.07), (-0.13, 0.32, 0.07)]
        : [(0.2, 0.02, 0.07), (-0.2, 0.02, 0.07), (0.24, 0.26, 0.055), (-0.24, 0.26, 0.055), (0.1, 0.38, 0.05), (-0.1, 0.38, 0.05)]
    for (sx, sy, sr) in spots {
        ctx.fillEllipse(in: CGRect(x: sx - sr, y: sy - sr, width: 2 * sr, height: 2 * sr))
    }
    ctx.setStrokeColor(rgb(ink))
    ctx.setLineWidth(line * 0.8)
    ctx.move(to: CGPoint(x: 0, y: -0.24))
    ctx.addLine(to: CGPoint(x: 0, y: 0.52))
    ctx.strokePath()
    ctx.restoreGState()
    ctx.setStrokeColor(rgb(ink))
    ctx.setLineWidth(line)
    ctx.addPath(body)
    ctx.strokePath()

    let eyeR: CGFloat = detail.tiny ? 0.2 : 0.15
    let lx = look.x * cos(-heading) - look.y * sin(-heading)
    let ly = look.x * sin(-heading) + look.y * cos(-heading)
    for m in [1, -1] as [CGFloat] {
        let c = CGPoint(x: (detail.tiny ? 0.2 : 0.155) * m, y: -0.36)
        ctx.setFillColor(rgb(0xffffff))
        ctx.setStrokeColor(rgb(ink))
        ctx.setLineWidth(detail.tiny ? line * 0.55 : line)
        ctx.addEllipse(in: CGRect(x: c.x - eyeR, y: c.y - eyeR, width: 2 * eyeR, height: 2 * eyeR))
        ctx.drawPath(using: .fillStroke)
        let pr = eyeR * (detail.tiny ? 0.5 : 0.48)
        let pc = CGPoint(x: c.x + lx * (eyeR - pr) * 0.8, y: c.y + ly * (eyeR - pr) * 0.8)
        ctx.setFillColor(rgb(ink))
        ctx.fillEllipse(in: CGRect(x: pc.x - pr, y: pc.y - pr, width: 2 * pr, height: 2 * pr))
        if !detail.tiny {
            let gr = pr * 0.36
            ctx.setFillColor(rgb(0xffffff))
            ctx.fillEllipse(in: CGRect(x: pc.x + pr * 0.3 - gr, y: pc.y - pr * 0.4 - gr, width: 2 * gr, height: 2 * gr))
        }
    }
    ctx.restoreGState()
}

func stonePath(hinge: CGPoint, width: CGFloat, top: CGFloat, bottom: CGFloat, tilt: CGFloat) -> CGPath {
    let p = CGMutablePath()
    let steps = 480
    for i in 0..<steps {
        let t = CGFloat(i) / CGFloat(steps) * 2 * .pi
        let c = cos(t)
        let s = sin(t)
        let lean = 1 + 0.10 * (-c) + 0.03 * sin(3 * t + 0.7)
        let lx = width / 2 + width / 2 * (c < 0 ? -1 : 1) * pow(abs(c), 2 / (s > 0 ? 3.0 : 2.3))
        let ly = -bottom + (s > 0 ? bottom * pow(s, 2 / 3.4) : -top * lean * pow(-s, 2 / 2.3))
        let x = hinge.x + lx * cos(tilt) - ly * sin(tilt)
        let y = hinge.y + lx * sin(tilt) + ly * cos(tilt)
        if i == 0 { p.move(to: CGPoint(x: x, y: y)) } else { p.addLine(to: CGPoint(x: x, y: y)) }
    }
    p.closeSubpath()
    return p
}

func drawScene(_ cv: Canvas, detail: Detail) {
    let ctx = cv.ctx
    let plate = CGRect(x: 100, y: 100, width: 824, height: 824)
    let shape = squircle(plate)
    let outline: CGFloat = detail.tiny ? 26 : (detail.full ? 15 : 20)

    ctx.saveGState()
    cv.shadow(dx: 0, dy: 12, blur: 26, color: rgb(0x000000, 0.34))
    ctx.addPath(shape)
    ctx.setFillColor(rgb(0x8fd47a))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(shape)
    ctx.clip()
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    cv.linear(
        gradient([(0, rgb(0xc9efaa)), (1, rgb(0xa3e08c))]),
        from: CGPoint(x: 512, y: 100), to: CGPoint(x: 512, y: 560))
    let ground = CGMutablePath()
    ground.move(to: CGPoint(x: 60, y: 520))
    ground.addQuadCurve(to: CGPoint(x: 980, y: 470), control: CGPoint(x: 520, y: 400))
    ground.addLine(to: CGPoint(x: 980, y: 980))
    ground.addLine(to: CGPoint(x: 60, y: 980))
    ground.closeSubpath()
    ctx.saveGState()
    ctx.addPath(ground)
    ctx.clip()
    cv.linear(
        gradient([(0, rgb(0x8ed672)), (1, rgb(0x62b95c))]),
        from: CGPoint(x: 512, y: 440), to: CGPoint(x: 512, y: 924))
    ctx.restoreGState()

    func tuft(_ x: CGFloat, _ y: CGFloat, _ h: CGFloat, _ color: UInt32) {
        ctx.setStrokeColor(rgb(color))
        ctx.setLineWidth(h * 0.2)
        for (dx, k) in [(-0.45, 0.72), (0.0, 1.0), (0.45, 0.72)] as [(CGFloat, CGFloat)] {
            ctx.move(to: CGPoint(x: x + dx * h * 0.35, y: y))
            ctx.addQuadCurve(
                to: CGPoint(x: x + dx * h * 1.1, y: y - h * k),
                control: CGPoint(x: x + dx * h * 0.3, y: y - h * k * 0.6))
        }
        ctx.strokePath()
    }
    if detail.full {
        tuft(790, 400, 62, 0x7fcb68)
        tuft(250, 300, 50, 0x8ed672)
        tuft(610, 250, 44, 0x8ed672)
        tuft(850, 600, 46, 0x4fa651)
        tuft(190, 800, 58, 0x4fa651)
        tuft(420, 880, 40, 0x4fa651)
        for (dx, dy, r) in [(300.0, 850.0, 9.0), (860.0, 760.0, 8.0), (150.0, 470.0, 8.0), (880.0, 300.0, 9.0), (420.0, 200.0, 7.0)] as [(CGFloat, CGFloat, CGFloat)] {
            ctx.setFillColor(rgb(0xfff6c8, 0.95))
            ctx.fillEllipse(in: CGRect(x: dx - r, y: dy - r, width: 2 * r, height: 2 * r))
        }
    }

    let hinge = CGPoint(x: 172, y: 596)
    let tilt: CGFloat = -22 * .pi / 180
    let stoneW: CGFloat = 620
    let stone = stonePath(hinge: hinge, width: stoneW, top: 196, bottom: 62, tilt: tilt)
    let ux = cos(tilt)
    let uy = sin(tilt)
    let lip = CGPoint(x: hinge.x + stoneW * 0.95 * ux, y: hinge.y + stoneW * 0.95 * uy)
    let floorY = hinge.y + 4

    let pool = CGRect(x: 300, y: floorY - 40, width: 760, height: 340)
    cv.radial(
        gradient([(0, rgb(0xfff7b0, 0.85)), (0.75, rgb(0xfff09a, 0.45)), (1, rgb(0xfff09a, 0))]),
        cx: pool.midX, cy: pool.midY, rx: pool.width * 0.62, ry: pool.height * 0.68)
    ctx.setFillColor(rgb(0xffe873))
    ctx.fillEllipse(in: pool)
    ctx.setFillColor(rgb(0xfff4ad))
    ctx.fillEllipse(in: pool.insetBy(dx: 90, dy: 44).offsetBy(dx: 40, dy: 6))

    let cavity = CGMutablePath()
    cavity.move(to: CGPoint(x: hinge.x + 40, y: floorY - 24))
    cavity.addLine(to: CGPoint(x: hinge.x + stoneW * 0.66 * ux, y: hinge.y + stoneW * 0.66 * uy + 10))
    cavity.addQuadCurve(to: CGPoint(x: hinge.x + stoneW * 0.62, y: floorY + 96), control: CGPoint(x: hinge.x + stoneW * 0.8, y: floorY - 30))
    cavity.addQuadCurve(to: CGPoint(x: hinge.x + 40, y: floorY - 24), control: CGPoint(x: hinge.x + 200, y: floorY + 110))
    cavity.closeSubpath()
    ctx.saveGState()
    ctx.addPath(cavity)
    ctx.clip()
    cv.linear(
        gradient(detail.full
            ? [(0, rgb(0x34365c)), (0.55, rgb(0x45426e)), (1, rgb(0x6a5a7a))]
            : [(0, rgb(0x3d7f55)), (1, rgb(0x4f9a5c))]),
        from: CGPoint(x: hinge.x + 120, y: floorY), to: CGPoint(x: hinge.x + stoneW * 0.75, y: floorY - 40))
    ctx.restoreGState()

    if detail.full {
        for (ex, ey) in [(316.0, 590.0)] as [(CGFloat, CGFloat)] {
            for m in [-1.0, 1.0] as [CGFloat] {
                let c = CGPoint(x: ex + m * 21, y: ey)
                ctx.setFillColor(rgb(0xffffff))
                ctx.fillEllipse(in: CGRect(x: c.x - 16, y: c.y - 16, width: 32, height: 32))
                ctx.setFillColor(rgb(ink))
                ctx.fillEllipse(in: CGRect(x: c.x - 2, y: c.y - 9, width: 15, height: 15))
            }
        }
    }

    ctx.saveGState()
    ctx.addPath(stone)
    ctx.clip()
    ctx.setFillColor(rgb(0x8298b8))
    ctx.fill(plate)
    ctx.addPath(translated(stone, dx: 14 * uy - 6, dy: -14 * ux - 30))
    ctx.setFillColor(rgb(0xb3c5dc))
    ctx.fillPath()
    cv.radial(
        gradient([(0, rgb(0xffe27a, 0.95)), (0.55, rgb(0xffd45e, 0.5)), (1, rgb(0xffd45e, 0))]),
        cx: lip.x - 40, cy: lip.y + 40, rx: 300, ry: 80, rot: tilt)
    let nx = -uy
    let ny = ux
    func onStone(_ u: CGFloat, _ v: CGFloat) -> CGPoint {
        CGPoint(x: hinge.x + stoneW * u * ux - nx * v, y: hinge.y + stoneW * u * uy - ny * v)
    }
    ctx.setStrokeColor(rgb(0xe6eef8))
    ctx.setLineWidth(detail.full ? 26 : 34)
    let h0 = onStone(0.2, 196)
    let h1 = onStone(0.52, 218)
    ctx.move(to: h0)
    ctx.addQuadCurve(to: h1, control: onStone(0.34, 232))
    ctx.strokePath()
    if detail.full {
        let dot = onStone(0.62, 208)
        ctx.setFillColor(rgb(0xe6eef8))
        ctx.fillEllipse(in: CGRect(x: dot.x - 13, y: dot.y - 13, width: 26, height: 26))
        ctx.setFillColor(rgb(0x8ea4c2))
        for (u, v, r) in [(0.3, 110.0, 20.0), (0.5, 70.0, 14.0), (0.68, 130.0, 17.0), (0.42, 150.0, 10.0), (0.8, 80.0, 11.0)] as [(CGFloat, CGFloat, CGFloat)] {
            let c = onStone(u, v)
            ctx.saveGState()
            ctx.translateBy(x: c.x, y: c.y)
            ctx.rotate(by: tilt)
            ctx.fillEllipse(in: CGRect(x: -r, y: -r * 0.7, width: 2 * r, height: 1.4 * r))
            ctx.restoreGState()
        }
        ctx.setFillColor(rgb(0x6fc35f))
        for (u, v, r) in [(0.05, 150.0, 40.0), (0.11, 185.0, 34.0), (0.02, 105.0, 30.0)] as [(CGFloat, CGFloat, CGFloat)] {
            let c = onStone(u, v)
            ctx.fillEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
        }
    }
    ctx.restoreGState()
    ctx.setStrokeColor(rgb(ink))
    ctx.setLineWidth(outline)
    ctx.addPath(stone)
    ctx.strokePath()

    if detail.full {
        ctx.setStrokeColor(rgb(0xffe45c))
        ctx.setLineWidth(14)
        for (a, r0, r1) in [(-0.15, 70.0, 120.0), (0.35, 70.0, 130.0), (0.85, 70.0, 115.0)] as [(CGFloat, CGFloat, CGFloat)] {
            let o = CGPoint(x: lip.x + 6, y: lip.y + 40)
            ctx.move(to: CGPoint(x: o.x + cos(a) * r0, y: o.y + sin(a) * r0))
            ctx.addLine(to: CGPoint(x: o.x + cos(a) * r1, y: o.y + sin(a) * r1))
        }
        ctx.strokePath()
    }

    if detail.tiny {
        drawHero(cv, x: 606, y: 704, size: 384, heading: 0.2, look: CGPoint(x: 0.5, y: -0.86), detail: detail)
    } else if detail.full {
        drawHero(cv, x: 604, y: 716, size: 312, heading: 0.24, look: CGPoint(x: 0.55, y: -0.83), detail: detail)
    } else {
        drawHero(cv, x: 604, y: 708, size: 350, heading: 0.22, look: CGPoint(x: 0.55, y: -0.83), detail: detail)
    }
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(shape)
    ctx.clip()
    ctx.addPath(shape)
    ctx.setLineWidth(detail.full ? 6 : 10)
    ctx.replacePathWithStrokedPath()
    ctx.clip()
    cv.linear(
        gradient([(0, rgb(0xffffff, 0.55)), (0.4, rgb(0xffffff, 0.08)), (1, rgb(0x1f5a2a, 0.3))]),
        from: CGPoint(x: 512, y: 100), to: CGPoint(x: 512, y: 924))
    ctx.restoreGState()
}

func renderIcon(px: Int) -> CGImage {
    let cv = Canvas(px: px, unit: 1024)
    drawScene(cv, detail: Detail(full: px > 64, tiny: px <= 32))
    return cv.image()
}

func contactSheet(_ path: String) {
    let w = 1400
    let h = 620
    let ctx = CGContext(
        data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
        space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    ctx.setFillColor(rgb(0xe9e9ec))
    ctx.fill(CGRect(x: 0, y: 0, width: w / 2, height: h))
    ctx.setFillColor(rgb(0x1e1f24))
    ctx.fill(CGRect(x: w / 2, y: 0, width: w / 2, height: h))
    for side in 0..<2 {
        let ox = CGFloat(side * w / 2)
        ctx.interpolationQuality = .none
        ctx.draw(renderIcon(px: 128), in: CGRect(x: ox + 20, y: 220, width: 384, height: 384))
        ctx.draw(renderIcon(px: 32), in: CGRect(x: ox + 420, y: 348, width: 256, height: 256))
        ctx.draw(renderIcon(px: 16), in: CGRect(x: ox + 420, y: 76, width: 256, height: 256))
        ctx.draw(renderIcon(px: 64), in: CGRect(x: ox + 20, y: 12, width: 192, height: 192))
        ctx.draw(renderIcon(px: 128), in: CGRect(x: ox + 230, y: 70, width: 128, height: 128))
        ctx.draw(renderIcon(px: 64), in: CGRect(x: ox + 366, y: 6, width: 64, height: 64))
        ctx.draw(renderIcon(px: 32), in: CGRect(x: ox + 300, y: 22, width: 32, height: 32))
        ctx.draw(renderIcon(px: 16), in: CGRect(x: ox + 260, y: 30, width: 16, height: 16))
    }
    writePNG(ctx.makeImage()!, path)
}

let args = CommandLine.arguments
guard args.count >= 2 else {
    FileHandle.standardError.write("usage: icon <outdir> [previewdir]\n".data(using: .utf8)!)
    exit(2)
}
let outDir = args[1]
let iconset = outDir + "/AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: iconset, withIntermediateDirectories: true)

let entries: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
var cache: [Int: CGImage] = [:]
for (name, px) in entries {
    let image = cache[px] ?? renderIcon(px: px)
    cache[px] = image
    writePNG(image, "\(iconset)/\(name).png")
}
writePNG(cache[1024]!, outDir + "/AppIcon-1024.png")

if args.count >= 3 {
    let preview = args[2]
    try? FileManager.default.createDirectory(atPath: preview, withIntermediateDirectories: true)
    writePNG(cache[1024]!, preview + "/icon-1024.png")
    writePNG(cache[128]!, preview + "/icon-128.png")
    writePNG(cache[32]!, preview + "/icon-32.png")
    contactSheet(preview + "/icon-sheet.png")
}
