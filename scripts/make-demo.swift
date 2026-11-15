import Foundation
import CoreGraphics
import CoreImage
import ImageIO
import UniformTypeIdentifiers

struct V {
    var x: Double
    var y: Double
    var z: Double
    static func + (a: V, b: V) -> V { V(x: a.x + b.x, y: a.y + b.y, z: a.z + b.z) }
    static func - (a: V, b: V) -> V { V(x: a.x - b.x, y: a.y - b.y, z: a.z - b.z) }
    static func * (a: V, k: Double) -> V { V(x: a.x * k, y: a.y * k, z: a.z * k) }
    func dot(_ b: V) -> Double { x * b.x + y * b.y + z * b.z }
    func cross(_ b: V) -> V { V(x: y * b.z - z * b.y, y: z * b.x - x * b.z, z: x * b.y - y * b.x) }
    var unit: V { self * (1 / max(1e-9, dot(self).squareRoot())) }
}

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write("usage: make-demo.swift <framesDir> <outDir> [fps] [from] [riseStart] [riseEnd] [low] [high]\n".data(using: .utf8)!)
    exit(2)
}
let framesDir = args[1]
let outDir = args[2]
func number(_ i: Int, _ d: Double) -> Double { args.count > i ? Double(args[i]) ?? d : d }
let fps = number(3, 30)
let from = number(4, 72.5)
let riseStart = number(5, 75)
let riseEnd = number(6, 75.9)
let low = number(7, 20)
let high = number(8, 110)

let width = 1280.0
let height = 800.0
let eye = V(x: 0.24, y: 0.13, z: -2.2)
let target = V(x: 0, y: 0.2, z: -0.25)
let forward = (target - eye).unit
let right = V(x: 0, y: 1, z: 0).cross(forward).unit
let upward = forward.cross(right)
let focal = 1780.0

func project(_ p: V) -> CGPoint {
    let d = p - eye
    let depth = max(0.05, d.dot(forward))
    return CGPoint(x: width / 2 + focal * d.dot(right) / depth, y: height * 0.4 + focal * d.dot(upward) / depth)
}

func quad(_ ctx: CGContext, _ pts: [V], _ color: CGColor) {
    let p = pts.map(project)
    ctx.beginPath()
    ctx.move(to: p[0])
    for q in p.dropFirst() { ctx.addLine(to: q) }
    ctx.closePath()
    ctx.setFillColor(color)
    ctx.fillPath()
}

func rgb(_ hex: UInt32, _ a: Double = 1) -> CGColor {
    CGColor(red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, alpha: a)
}

func mix(_ a: UInt32, _ b: UInt32, _ t: Double) -> CGColor {
    func c(_ h: UInt32, _ s: UInt32) -> Double { Double((h >> s) & 255) / 255 }
    let k = min(1, max(0, t))
    return CGColor(red: c(a, 16) + (c(b, 16) - c(a, 16)) * k, green: c(a, 8) + (c(b, 8) - c(a, 8)) * k, blue: c(a, 0) + (c(b, 0) - c(a, 0)) * k, alpha: 1)
}

let half = 0.5
let depth = 0.68
let slab = 0.022
let lidLength = 0.675
let lidThickness = 0.012
let bezel = 0.018
let screenHeight = (1 - 2 * bezel) * 982.0 / 1512.0

func base(_ x: Double, _ z: Double, _ y: Double = 0) -> V { V(x: x, y: y, z: -z) }

func lid(_ x: Double, _ r: Double, _ theta: Double, out: Double = 0) -> V {
    let inner = V(x: x, y: r * sin(theta), z: -r * cos(theta))
    let normal = V(x: 0, y: cos(theta), z: sin(theta))
    return inner + normal * out
}

func angle(at t: Double) -> Double {
    if t <= riseStart { return low }
    if t >= riseEnd { return high }
    let u = (t - riseStart) / (riseEnd - riseStart)
    return low + (high - low) * u * u * (3 - 2 * u)
}

let files = (try? FileManager.default.contentsOfDirectory(atPath: framesDir))?.filter { $0.hasSuffix(".png") }.sorted() ?? []
guard !files.isEmpty else {
    FileHandle.standardError.write("no frames in \(framesDir)\n".data(using: .utf8)!)
    exit(1)
}
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
let space = CGColorSpace(name: CGColorSpace.sRGB)!
let ci = CIContext(options: [.workingColorSpace: space])

for (index, name) in files.enumerated() {
    let t = from + Double(index) / fps
    let degrees = angle(at: t)
    let theta = degrees * .pi / 180
    let open = (degrees - low) / max(1, high - low)
    guard let ctx = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { exit(1) }
    ctx.interpolationQuality = .high

    let horizon = project(V(x: 0, y: 0, z: 40)).y
    let wall = CGGradient(colorsSpace: space, colors: [mix(0x141526, 0x23243c, open), mix(0x1d1e33, 0x34365a, open)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(wall, start: CGPoint(x: 0, y: height), end: CGPoint(x: 0, y: horizon), options: [])
    let desk = CGGradient(colorsSpace: space, colors: [mix(0x2a2233, 0x4a3b52, open), mix(0x15121d, 0x221b2b, open)] as CFArray, locations: [0, 1])!
    ctx.saveGState()
    ctx.clip(to: CGRect(x: 0, y: 0, width: width, height: horizon))
    ctx.drawLinearGradient(desk, start: CGPoint(x: 0, y: horizon), end: CGPoint(x: 0, y: 0), options: [])
    ctx.restoreGState()

    let shadow = [base(-half - 0.03, -0.02, -slab), base(half + 0.03, -0.02, -slab), base(half + 0.05, depth + 0.05, -slab), base(-half - 0.05, depth + 0.05, -slab)]
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 28, color: rgb(0x000000, 0.55))
    quad(ctx, shadow, rgb(0x000000, 0.35))
    ctx.restoreGState()

    quad(ctx, [base(-half, depth, -slab), base(half, depth, -slab), base(half, depth), base(-half, depth)], mix(0x6f7482, 0xa9afbd, open))
    quad(ctx, [base(half, 0, -slab), base(half, depth, -slab), base(half, depth), base(half, 0)], mix(0x565a66, 0x8b909d, open))
    quad(ctx, [base(-half, 0), base(half, 0), base(half, depth), base(-half, depth)], mix(0x8a8f9c, 0xc9ced9, open))

    let wellLeft = -0.44, wellRight = 0.44, wellBack = 0.07, wellFront = 0.36
    quad(ctx, [base(wellLeft, wellBack), base(wellRight, wellBack), base(wellRight, wellFront), base(wellLeft, wellFront)], rgb(0x1b1c24))
    let rows = 6, columns = 14
    for row in 0..<rows {
        for column in 0..<columns {
            let x0 = wellLeft + (wellRight - wellLeft) * (Double(column) + 0.08) / Double(columns)
            let x1 = wellLeft + (wellRight - wellLeft) * (Double(column) + 0.92) / Double(columns)
            let z0 = wellBack + (wellFront - wellBack) * (Double(row) + 0.1) / Double(rows)
            let z1 = wellBack + (wellFront - wellBack) * (Double(row) + 0.9) / Double(rows)
            quad(ctx, [base(x0, z0, 0.004), base(x1, z0, 0.004), base(x1, z1, 0.004), base(x0, z1, 0.004)], mix(0x2b2d38, 0x3a3d4b, open))
        }
    }
    quad(ctx, [base(-0.17, 0.41), base(0.17, 0.41), base(0.17, 0.63), base(-0.17, 0.63)], mix(0x7e8390, 0xbcc1cd, open))

    quad(ctx, [lid(-half, lidLength, theta), lid(half, lidLength, theta), lid(half, lidLength, theta, out: lidThickness), lid(-half, lidLength, theta, out: lidThickness)], mix(0x7b808d, 0xb4b9c6, open))
    quad(ctx, [lid(half, 0, theta), lid(half, lidLength, theta), lid(half, lidLength, theta, out: lidThickness), lid(half, 0, theta, out: lidThickness)], mix(0x5d616d, 0x9499a6, open))
    quad(ctx, [lid(-half, 0, theta), lid(half, 0, theta), lid(half, lidLength, theta), lid(-half, lidLength, theta)], rgb(0x0b0b10))

    let bottom = lidLength - bezel - screenHeight
    let top = lidLength - bezel
    let leftEdge = -half + bezel
    let rightEdge = half - bezel
    guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: framesDir + "/" + name) as CFURL, nil),
          let frame = CGImageSourceCreateImageAtIndex(source, 0, nil) else { exit(1) }
    let filter = CIFilter(name: "CIPerspectiveTransform")!
    filter.setValue(CIImage(cgImage: frame), forKey: kCIInputImageKey)
    filter.setValue(CIVector(cgPoint: project(lid(leftEdge, top, theta))), forKey: "inputTopLeft")
    filter.setValue(CIVector(cgPoint: project(lid(rightEdge, top, theta))), forKey: "inputTopRight")
    filter.setValue(CIVector(cgPoint: project(lid(leftEdge, bottom, theta))), forKey: "inputBottomLeft")
    filter.setValue(CIVector(cgPoint: project(lid(rightEdge, bottom, theta))), forKey: "inputBottomRight")
    if let output = filter.outputImage, let image = ci.createCGImage(output, from: output.extent) {
        ctx.draw(image, in: output.extent)
    }

    let glow = CGGradient(colorsSpace: space, colors: [rgb(0xbfc8ff, 0.16 * open + 0.03), rgb(0xbfc8ff, 0)] as CFArray, locations: [0, 1])!
    let centre = project(base(0, 0.3))
    ctx.saveGState()
    ctx.translateBy(x: centre.x, y: centre.y)
    ctx.scaleBy(x: 1, y: 0.22)
    ctx.drawRadialGradient(glow, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: 560, options: [])
    ctx.restoreGState()

    guard let result = ctx.makeImage(),
          let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: String(format: "%@/frame-%04d.png", outDir, index)) as CFURL, UTType.png.identifier as CFString, 1, nil) else { exit(1) }
    CGImageDestinationAddImage(destination, result, nil)
    CGImageDestinationFinalize(destination)
}
print("wrote \(files.count) frames to \(outDir)")
