import Foundation
import CoreGraphics
import ImageIO

let space = CGColorSpace(name: CGColorSpace.sRGB)!

func writePNG(_ image: CGImage, _ path: String) {
    let url = URL(fileURLWithPath: path) as CFURL
    let dest = CGImageDestinationCreateWithURL(url, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    if !CGImageDestinationFinalize(dest) {
        FileHandle.standardError.write("failed to write \(path)\n".data(using: .utf8)!)
        exit(1)
    }
}

func bitmap(_ w: Int, _ h: Int) -> CGContext {
    CGContext(
        data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
        space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
}

func renderGlyph(px: Int) -> CGImage {
    let ctx = bitmap(px, px)
    let s = CGFloat(px) / 18
    ctx.translateBy(x: 0, y: CGFloat(px))
    ctx.scaleBy(x: s, y: -s)
    ctx.setFillColor(CGColor(colorSpace: space, components: [0, 0, 0, 1])!)
    ctx.setStrokeColor(CGColor(colorSpace: space, components: [0, 0, 0, 1])!)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    let cap = CGMutablePath()
    cap.move(to: CGPoint(x: 1.4, y: 8.8))
    cap.addCurve(to: CGPoint(x: 9, y: 1.8), control1: CGPoint(x: 1.4, y: 4.5), control2: CGPoint(x: 4.7, y: 1.8))
    cap.addCurve(to: CGPoint(x: 16.6, y: 8.8), control1: CGPoint(x: 13.3, y: 1.8), control2: CGPoint(x: 16.6, y: 4.5))
    cap.addCurve(to: CGPoint(x: 15.1, y: 10.4), control1: CGPoint(x: 16.6, y: 9.8), control2: CGPoint(x: 16.0, y: 10.4))
    cap.addLine(to: CGPoint(x: 2.9, y: 10.4))
    cap.addCurve(to: CGPoint(x: 1.4, y: 8.8), control1: CGPoint(x: 2.0, y: 10.4), control2: CGPoint(x: 1.4, y: 9.8))
    cap.closeSubpath()
    ctx.addPath(cap)
    ctx.fillPath()

    let stem = CGMutablePath()
    stem.move(to: CGPoint(x: 5.9, y: 11.2))
    stem.addLine(to: CGPoint(x: 12.1, y: 11.2))
    stem.addCurve(to: CGPoint(x: 13.0, y: 14.2), control1: CGPoint(x: 12.7, y: 12.0), control2: CGPoint(x: 13.0, y: 13.1))
    stem.addCurve(to: CGPoint(x: 10.4, y: 16.6), control1: CGPoint(x: 13.0, y: 15.7), control2: CGPoint(x: 12.0, y: 16.6))
    stem.addLine(to: CGPoint(x: 7.6, y: 16.6))
    stem.addCurve(to: CGPoint(x: 5.0, y: 14.2), control1: CGPoint(x: 6.0, y: 16.6), control2: CGPoint(x: 5.0, y: 15.7))
    stem.addCurve(to: CGPoint(x: 5.9, y: 11.2), control1: CGPoint(x: 5.0, y: 13.1), control2: CGPoint(x: 5.3, y: 12.0))
    stem.closeSubpath()
    ctx.addPath(stem)
    ctx.fillPath()

    ctx.setBlendMode(.clear)
    let holes: [(CGFloat, CGFloat, CGFloat)] = [
        (9.0, 4.9, 1.35), (4.7, 7.3, 1.0), (13.3, 7.3, 1.0), (7.55, 13.6, 0.8), (10.45, 13.6, 0.8),
    ]
    for (x, y, r) in holes {
        ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
    }
    ctx.setBlendMode(.normal)
    return ctx.makeImage()!
}

func tinted(_ glyph: CGImage, white: Bool) -> CGImage {
    let ctx = bitmap(glyph.width, glyph.height)
    let rect = CGRect(x: 0, y: 0, width: glyph.width, height: glyph.height)
    ctx.clip(to: rect, mask: glyph)
    let v: CGFloat = white ? 1 : 0
    ctx.setFillColor(CGColor(colorSpace: space, components: [v, v, v, white ? 1 : 0.85])!)
    ctx.fill(rect)
    return ctx.makeImage()!
}

func preview(_ g1: CGImage, _ g2: CGImage, dark: Bool, path: String) {
    let w = 560
    let h = 240
    let ctx = bitmap(w, h)
    let bg: [CGFloat] = dark ? [0.13, 0.14, 0.17, 1] : [0.90, 0.91, 0.93, 1]
    ctx.setFillColor(CGColor(colorSpace: space, components: bg)!)
    ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
    let a = tinted(g1, white: dark)
    let b = tinted(g2, white: dark)
    ctx.interpolationQuality = .none
    ctx.draw(a, in: CGRect(x: 20, y: 30, width: 180, height: 180))
    ctx.draw(b, in: CGRect(x: 230, y: 30, width: 180, height: 180))
    ctx.draw(a, in: CGRect(x: 440, y: 150, width: 18, height: 18))
    ctx.draw(b, in: CGRect(x: 480, y: 141, width: 36, height: 36))
    ctx.interpolationQuality = .high
    ctx.draw(b, in: CGRect(x: 440, y: 80, width: 18, height: 18))
    writePNG(ctx.makeImage()!, path)
}

let args = CommandLine.arguments
guard args.count >= 2 else {
    FileHandle.standardError.write("usage: menubar <outdir> [previewdir]\n".data(using: .utf8)!)
    exit(2)
}
try? FileManager.default.createDirectory(atPath: args[1], withIntermediateDirectories: true)
let g1 = renderGlyph(px: 18)
let g2 = renderGlyph(px: 36)
writePNG(g1, args[1] + "/MenuBarIcon.png")
writePNG(g2, args[1] + "/MenuBarIcon@2x.png")
writePNG(renderGlyph(px: 54), args[1] + "/MenuBarIcon@3x.png")
if args.count >= 3 {
    try? FileManager.default.createDirectory(atPath: args[2], withIntermediateDirectories: true)
    preview(g1, g2, dark: false, path: args[2] + "/menubar-preview-light.png")
    preview(g1, g2, dark: true, path: args[2] + "/menubar-preview-dark.png")
}
