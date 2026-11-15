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

    let feet: [(CGPoint, CGPoint)] = [
        (CGPoint(x: 5.6, y: 9.0), CGPoint(x: 3.7, y: 7.9)),
        (CGPoint(x: 5.0, y: 11.5), CGPoint(x: 2.9, y: 11.5)),
        (CGPoint(x: 5.6, y: 14.0), CGPoint(x: 3.8, y: 15.1)),
    ]
    ctx.setLineWidth(1.9)
    for (a, b) in feet {
        for m in [1, -1] as [CGFloat] {
            ctx.move(to: CGPoint(x: 9 + (a.x - 9) * m, y: a.y))
            ctx.addLine(to: CGPoint(x: 9 + (b.x - 9) * m, y: b.y))
        }
    }
    ctx.strokePath()

    ctx.setLineWidth(1.1)
    for m in [1, -1] as [CGFloat] {
        ctx.move(to: CGPoint(x: 9 + 1.2 * m, y: 4.4))
        ctx.addQuadCurve(to: CGPoint(x: 9 + 3.5 * m, y: 2.7), control: CGPoint(x: 9 + 1.6 * m, y: 2.5))
    }
    ctx.strokePath()
    for m in [1, -1] as [CGFloat] {
        ctx.fillEllipse(in: CGRect(x: 9 + 3.7 * m - 1.05, y: 2.6 - 1.05, width: 2.1, height: 2.1))
    }

    ctx.fillEllipse(in: CGRect(x: 6.2, y: 3.5, width: 5.6, height: 4.6))

    let body = CGRect(x: 4.6, y: 6.9, width: 8.8, height: 9.0)
    ctx.setBlendMode(.clear)
    ctx.fillEllipse(in: body.insetBy(dx: -0.8, dy: -0.8))
    ctx.setBlendMode(.normal)
    ctx.setLineWidth(1.9)
    for (a, b) in feet {
        for m in [1, -1] as [CGFloat] {
            ctx.move(to: CGPoint(x: 9 + (a.x - 9) * m, y: a.y))
            ctx.addLine(to: CGPoint(x: 9 + (b.x - 9) * m, y: b.y))
        }
    }
    ctx.strokePath()
    ctx.fillEllipse(in: body)

    ctx.setBlendMode(.clear)
    ctx.setLineCap(.butt)
    ctx.setLineWidth(0.85)
    ctx.move(to: CGPoint(x: 9, y: 8.4))
    ctx.addLine(to: CGPoint(x: 9, y: 16.2))
    ctx.strokePath()
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
if args.count >= 3 {
    try? FileManager.default.createDirectory(atPath: args[2], withIntermediateDirectories: true)
    preview(g1, g2, dark: false, path: args[2] + "/menubar-preview-light.png")
    preview(g1, g2, dark: true, path: args[2] + "/menubar-preview-dark.png")
}
