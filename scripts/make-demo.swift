import Foundation
import AppKit
import SceneKit
import Metal
import Accelerate
import ImageIO
import UniformTypeIdentifiers

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

struct Options {
    var positional: [String] = []
    var flags: [String: String] = [:]

    init(_ raw: [String]) {
        var i = 0
        while i < raw.count {
            let a = raw[i]
            if a.hasPrefix("--"), i + 1 < raw.count {
                flags[String(a.dropFirst(2))] = raw[i + 1]
                i += 2
            } else {
                positional.append(a)
                i += 1
            }
        }
    }

    func double(_ key: String, _ fallback: Double) -> Double { flags[key].flatMap(Double.init) ?? fallback }
    func int(_ key: String, _ fallback: Int) -> Int { flags[key].flatMap(Int.init) ?? fallback }
}

let options = Options(Array(CommandLine.arguments.dropFirst()))
guard options.positional.count >= 3 else {
    fail("usage: make-demo <timeline.json> <screenFramesDir> <outDir> [--from 86.8] [--fps 30] [--width 1600] [--height 1000] [--supersample 2] [--subframes 3] [--only 0,40,90]")
}
let timelinePath = options.positional[0]
let screenDir = options.positional[1]
let outDir = options.positional[2]
let fps = options.double("fps", 30)
let from = options.double("from", 86.8)
let outWidth = options.int("width", 1600)
let outHeight = options.int("height", 1000)
let supersample = options.int("supersample", 2)
let baseSubframes = options.int("subframes", 3)
let only: Set<Int>? = options.flags["only"].map { Set($0.split(separator: ",").compactMap { Int($0) }) }
let displayHigh = options.double("display-angle", 100)

struct Keyframe: Decodable {
    var t: Double
    var angle: Double
    var ease: String?
}

struct Timeline: Decodable {
    var keyframes: [Keyframe]

    func angle(at t: Double) -> Double {
        guard let first = keyframes.first, let last = keyframes.last else { return 110 }
        if t <= first.t { return first.angle }
        if t >= last.t { return last.angle }
        for i in 1..<keyframes.count where t < keyframes[i].t {
            let a = keyframes[i - 1], b = keyframes[i]
            let span = b.t - a.t
            guard span > 0 else { return b.angle }
            let u = (t - a.t) / span
            switch b.ease ?? "linear" {
            case "inOut": return a.angle + (b.angle - a.angle) * (u * u * (3 - 2 * u))
            case "hold": return a.angle
            default: return a.angle + (b.angle - a.angle) * u
            }
        }
        return last.angle
    }

    var rise: (start: Double, end: Double, low: Double, high: Double) {
        var best: (Double, Double, Double, Double) = (0, 0, 20, 110)
        for i in 1..<keyframes.count where keyframes[i].angle > keyframes[i - 1].angle + 30 {
            best = (keyframes[i - 1].t, keyframes[i].t, keyframes[i - 1].angle, keyframes[i].angle)
        }
        return best
    }
}

guard let timelineData = FileManager.default.contents(atPath: timelinePath),
      let timeline = try? JSONDecoder().decode(Timeline.self, from: timelineData) else { fail("could not read \(timelinePath)") }
let rise = timeline.rise

func displayAngle(_ t: Double) -> Double {
    let a = timeline.angle(at: t)
    if a <= rise.low { return a }
    return rise.low + (a - rise.low) * (displayHigh - rise.low) / (rise.high - rise.low)
}

let screenFiles = ((try? FileManager.default.contentsOfDirectory(atPath: screenDir)) ?? []).filter { $0.hasSuffix(".png") }.sorted()
guard !screenFiles.isEmpty else { fail("no frames in \(screenDir)") }
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func clamp(_ x: Double, _ a: Double = 0, _ b: Double = 1) -> Double { min(b, max(a, x)) }
func smooth(_ x: Double) -> Double { let u = clamp(x); return u * u * (3 - 2 * u) }
func smoother(_ x: Double) -> Double { let u = clamp(x); return u * u * u * (u * (u * 6 - 15) + 10) }
func mix(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }
func mix(_ a: SIMD3<Double>, _ b: SIMD3<Double>, _ t: Double) -> SIMD3<Double> { a + (b - a) * t }
func vec(_ v: SIMD3<Double>) -> SCNVector3 { SCNVector3(v.x, v.y, v.z) }
func color(_ r: Double, _ g: Double, _ b: Double) -> NSColor { NSColor(srgbRed: r, green: g, blue: b, alpha: 1) }

guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue() else { fail("no Metal device") }
let linearSpace = CGColorSpace(name: CGColorSpace.linearSRGB)!
let srgbSpace = CGColorSpace(name: CGColorSpace.sRGB)!

func bitmap(_ w: Int, _ h: Int, _ draw: (CGContext) -> Void) -> CGImage {
    guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: srgbSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { fail("bitmap") }
    draw(ctx)
    return ctx.makeImage()!
}

func writeEnvironment(_ path: String) {
    let w = 1024, h = 512
    var pixels = [Float](repeating: 0, count: w * h * 4)
    func box(_ d: SIMD3<Double>, centre: SIMD3<Double>, up: SIMD3<Double>, halfW: Double, halfH: Double, soft: Double) -> Double {
        let c = simd_normalize(centre)
        let right = simd_normalize(simd_cross(up, c))
        let top = simd_cross(c, right)
        let dc = simd_dot(d, c)
        guard dc > 0.05 else { return 0 }
        let x = abs(simd_dot(d, right) / dc), y = abs(simd_dot(d, top) / dc)
        return (1 - smooth((x - halfW) / soft + 0.5)) * (1 - smooth((y - halfH) / soft + 0.5))
    }
    for j in 0..<h {
        let lat = (0.5 - (Double(j) + 0.5) / Double(h)) * .pi
        for i in 0..<w {
            let lon = ((Double(i) + 0.5) / Double(w) - 0.5) * 2 * .pi
            let d = SIMD3<Double>(cos(lat) * sin(lon), sin(lat), cos(lat) * cos(lon))
            let up = max(0, d.y), down = max(0, -d.y)
            var c = SIMD3<Double>(0.020, 0.024, 0.040) + SIMD3<Double>(0.03, 0.035, 0.06) * pow(up, 0.6) - SIMD3<Double>(0.012, 0.014, 0.024) * pow(down, 0.5)
            c += SIMD3<Double>(1.0, 0.97, 0.93) * 4.2 * box(d, centre: SIMD3(0.15, 0.9, 0.55), up: SIMD3(0, 0, -1), halfW: 0.75, halfH: 0.38, soft: 0.25)
            c += SIMD3<Double>(0.75, 0.85, 1.0) * 2.6 * box(d, centre: SIMD3(-0.8, 0.25, -0.55), up: SIMD3(0, 1, 0), halfW: 0.12, halfH: 0.9, soft: 0.12)
            c += SIMD3<Double>(1.0, 0.82, 0.68) * 0.9 * box(d, centre: SIMD3(0.95, 0.2, 0.1), up: SIMD3(0, 1, 0), halfW: 0.35, halfH: 0.5, soft: 0.3)
            c += SIMD3<Double>(0.6, 0.7, 1.0) * 0.5 * box(d, centre: SIMD3(0.0, 0.3, -1.0), up: SIMD3(0, 1, 0), halfW: 1.2, halfH: 0.25, soft: 0.4)
            let k = (j * w + i) * 4
            pixels[k] = Float(max(0, c.x)); pixels[k + 1] = Float(max(0, c.y)); pixels[k + 2] = Float(max(0, c.z)); pixels[k + 3] = 1
        }
    }
    let data = pixels.withUnsafeBytes { Data($0) }
    guard let provider = CGDataProvider(data: data as CFData),
          let image = CGImage(width: w, height: h, bitsPerComponent: 32, bitsPerPixel: 128, bytesPerRow: w * 16, space: linearSpace,
                              bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.floatComponents.rawValue | CGBitmapInfo.byteOrder32Little.rawValue),
                              provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent),
          let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.exr.identifier as CFString, 1, nil) else { fail("environment") }
    CGImageDestinationAddImage(dest, image, nil)
    if !CGImageDestinationFinalize(dest) { fail("could not write environment") }
}

func roundedPath(_ w: Double, _ h: Double, _ r: Double, x: Double = 0, y: Double = 0) -> NSBezierPath {
    let p = NSBezierPath(roundedRect: NSRect(x: x - w / 2, y: y - h / 2, width: w, height: h), xRadius: r, yRadius: r)
    p.flatness = 0.004
    return p
}

func roundProfile() -> NSBezierPath {
    let p = NSBezierPath()
    p.move(to: NSPoint(x: 0, y: 1))
    let steps = 16
    for s in 1...steps {
        let a = Double(s) / Double(steps) * .pi / 2
        p.line(to: NSPoint(x: sin(a), y: cos(a)))
    }
    return p
}

func slab(_ w: Double, _ h: Double, _ r: Double, depth: Double, chamfer: Double, material: SCNMaterial) -> SCNShape {
    let s = SCNShape(path: roundedPath(w, h, r), extrusionDepth: depth)
    s.chamferRadius = chamfer
    s.chamferMode = .both
    s.chamferProfile = roundProfile()
    s.materials = [material]
    return s
}

func pbr(_ base: NSColor, metal: Double, rough: Double) -> SCNMaterial {
    let m = SCNMaterial()
    m.lightingModel = .physicallyBased
    m.diffuse.contents = base
    m.metalness.contents = metal
    m.roughness.contents = rough
    return m
}

func noiseImage(_ size: Int, seed: UInt64, amount: Double, base: Double) -> CGImage {
    var state = seed
    func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 11) / Double(1 << 53)
    }
    return bitmap(size, size) { ctx in
        guard let data = ctx.data else { return }
        let p = data.bindMemory(to: UInt8.self, capacity: size * size * 4)
        for i in 0..<(size * size) {
            let v = UInt8(clamp(base + (next() - 0.5) * amount) * 255)
            p[i * 4] = v; p[i * 4 + 1] = v; p[i * 4 + 2] = v; p[i * 4 + 3] = 255
        }
    }
}

let aluminium = pbr(color(0.78, 0.80, 0.83), metal: 1, rough: 0.36)
aluminium.roughness.contents = noiseImage(256, seed: 7, amount: 0.06, base: 0.36)
aluminium.roughness.wrapS = .repeat
aluminium.roughness.wrapT = .repeat
aluminium.roughness.contentsTransform = SCNMatrix4MakeScale(6, 6, 1)
let darkMetal = pbr(color(0.16, 0.16, 0.17), metal: 1, rough: 0.42)
let keyMaterial = pbr(color(0.018, 0.018, 0.02), metal: 0, rough: 0.45)
let wellMaterial = pbr(color(0.012, 0.012, 0.014), metal: 0, rough: 0.7)
let glassMaterial = pbr(color(0.004, 0.004, 0.005), metal: 0, rough: 0.06)
let trackpadMaterial = pbr(color(0.78, 0.79, 0.81), metal: 0.9, rough: 0.26)
let gapMaterial = pbr(color(0.05, 0.05, 0.055), metal: 0, rough: 0.6)

let baseW = 31.26, baseD = 22.12, baseT = 0.95, feet = 0.12, cornerR = 1.05
let baseTop = feet + baseT
let hingeZ = -baseD / 2 + 0.5
let hingeY = baseTop + 0.28
let lidT = 0.5
let lidLow = -0.35
let lidTop = baseD - 0.5 - 0.02
let lidFace = hingeY - baseTop - 0.04
let displayW = 30.0
let displayH = displayW * 715.0 / 1100.0
let displayTop = lidTop - 0.55
let displayCentreY = displayTop - displayH / 2

let scene = SCNScene()
let envPath = outDir + "/environment.exr"
writeEnvironment(envPath)
scene.lightingEnvironment.contents = URL(fileURLWithPath: envPath)
scene.lightingEnvironment.intensity = 1
let horizonColor = color(0.085, 0.095, 0.15)
scene.background.contents = bitmap(64, 512) { ctx in
    let stops: [CGFloat] = [0.035, 0.04, 0.07, 1, 0.07, 0.08, 0.13, 1, 0.085, 0.095, 0.15, 1, 0.085, 0.095, 0.15, 1]
    let g = CGGradient(colorSpace: srgbSpace, colorComponents: stops, locations: [0, 0.35, 0.5, 1], count: 4)!
    ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: 512), end: CGPoint(x: 0, y: 0), options: [])
}
scene.fogColor = horizonColor
scene.fogStartDistance = 70
scene.fogEndDistance = 320
scene.fogDensityExponent = 1.2

let laptop = SCNNode()
scene.rootNode.addChildNode(laptop)

let baseNode = SCNNode(geometry: slab(baseW, baseD, cornerR, depth: baseT, chamfer: 0.22, material: aluminium))
baseNode.eulerAngles.x = -.pi / 2
baseNode.position = SCNVector3(0, feet + baseT / 2, 0)
laptop.addChildNode(baseNode)

func flatShape(_ w: Double, _ d: Double, _ r: Double, x: Double, z: Double, y: Double, thickness: Double, chamfer: Double, material: SCNMaterial) -> SCNNode {
    let s = SCNShape(path: roundedPath(w, d, r), extrusionDepth: thickness)
    if chamfer > 0 {
        s.chamferRadius = chamfer
        s.chamferMode = .front
        s.chamferProfile = roundProfile()
    }
    s.materials = [material]
    let n = SCNNode(geometry: s)
    n.eulerAngles.x = -.pi / 2
    n.position = SCNVector3(x, y - thickness / 2, z)
    return n
}

let pitch = 1.88, keyGap = 0.30
let fnRow = 1.12
let rows: [[Double]] = [
    [1.5] + Array(repeating: 1.0, count: 12) + [1.0],
    Array(repeating: 1.0, count: 13) + [1.5],
    [1.5] + Array(repeating: 1.0, count: 12) + [1.0],
    [1.8] + Array(repeating: 1.0, count: 11) + [1.7],
    [2.3] + Array(repeating: 1.0, count: 10) + [2.2],
]
let keyboardW = 14.5 * pitch
let keyboardD = fnRow + 5 * pitch
let wellMargin = 0.28
let keyboardBack = -baseD / 2 + 1.45
let wellNode = flatShape(keyboardW + 2 * wellMargin, keyboardD + 2 * wellMargin, 0.45, x: 0, z: keyboardBack + keyboardD / 2, y: baseTop + 0.004, thickness: 0.02, chamfer: 0, material: wellMaterial)
laptop.addChildNode(wellNode)

let keyHeight = 0.09
let keyY = baseTop + 0.01
var keyGeometries: [String: SCNGeometry] = [:]
func keycap(_ w: Double, _ d: Double, x: Double, z: Double) {
    let id = String(format: "%.3f-%.3f", w, d)
    let g: SCNGeometry
    if let cached = keyGeometries[id] { g = cached } else {
        let b = SCNBox(width: w, height: keyHeight, length: d, chamferRadius: 0.07)
        b.chamferSegmentCount = 4
        b.materials = [keyMaterial]
        keyGeometries[id] = b
        g = b
    }
    let n = SCNNode(geometry: g)
    n.position = SCNVector3(x, keyY + keyHeight / 2, z)
    laptop.addChildNode(n)
}
let left = -keyboardW / 2
var zCursor = keyboardBack
for (r, widths) in rows.enumerated() {
    let rowD = r == 0 ? fnRow : pitch
    var x = left
    for w in widths {
        keycap(w * pitch - keyGap, rowD - keyGap, x: x + w * pitch / 2, z: zCursor + rowD / 2)
        x += w * pitch
    }
    zCursor += rowD
}
do {
    let rowD = pitch
    let z = zCursor + rowD / 2
    var x = left
    for w in [1.0, 1.0, 1.0, 1.25, 5.0, 1.25, 1.0] {
        keycap(w * pitch - keyGap, rowD - keyGap, x: x + w * pitch / 2, z: z)
        x += w * pitch
    }
    keycap(pitch - keyGap, rowD - keyGap, x: x + pitch / 2, z: z)
    x += pitch
    keycap(pitch - keyGap, rowD / 2 - keyGap * 0.6, x: x + pitch / 2, z: z - rowD / 4)
    keycap(pitch - keyGap, rowD / 2 - keyGap * 0.6, x: x + pitch / 2, z: z + rowD / 4)
    x += pitch
    keycap(pitch - keyGap, rowD - keyGap, x: x + pitch / 2, z: z)
}

let grille = SCNMaterial()
grille.lightingModel = .physicallyBased
grille.diffuse.contents = bitmap(48, 640) { ctx in
    ctx.setFillColor(CGColor(gray: 0, alpha: 0.75))
    for row in 0..<80 {
        for col in 0..<6 {
            let ox = row % 2 == 0 ? 4.0 : 8.0
            ctx.fillEllipse(in: CGRect(x: ox + Double(col) * 7.0, y: 4 + Double(row) * 7.95, width: 3.4, height: 3.4))
        }
    }
}
grille.diffuse.mipFilter = .linear
grille.metalness.contents = 0.0
grille.roughness.contents = 0.8
grille.transparencyMode = .aOne
grille.writesToDepthBuffer = false
for side in [-1.0, 1.0] {
    let plane = SCNNode(geometry: SCNPlane(width: 0.95, height: keyboardD + 2 * wellMargin))
    plane.geometry?.materials = [grille]
    plane.eulerAngles.x = -.pi / 2
    plane.position = SCNVector3(side * (keyboardW / 2 + wellMargin + 0.85), baseTop + 0.003, keyboardBack + keyboardD / 2)
    laptop.addChildNode(plane)
}

let padW = 13.2, padD = 8.0
let padZ = baseD / 2 - 1.15 - padD / 2
laptop.addChildNode(flatShape(padW + 0.07, padD + 0.07, 0.62, x: 0, z: padZ, y: baseTop + 0.002, thickness: 0.02, chamfer: 0, material: gapMaterial))
laptop.addChildNode(flatShape(padW, padD, 0.58, x: 0, z: padZ, y: baseTop + 0.006, thickness: 0.03, chamfer: 0.01, material: trackpadMaterial))

let notchShape = SCNShape(path: roundedPath(4.6, 1.4, 0.7), extrusionDepth: 0.6)
notchShape.materials = [gapMaterial]
let thumbNotch = SCNNode(geometry: notchShape)
thumbNotch.eulerAngles.x = -.pi / 2
thumbNotch.position = SCNVector3(0, baseTop - 0.05, baseD / 2 + 0.25)
_ = thumbNotch

for (i, port) in [(2.2, 0.55), (4.6, 0.32), (6.6, 0.32)].enumerated() {
    let s = SCNShape(path: roundedPath(port.0 == 2.2 ? 1.6 : 0.9, port.1, port.1 / 2.2), extrusionDepth: 0.04)
    s.materials = [gapMaterial]
    let n = SCNNode(geometry: s)
    n.eulerAngles.y = .pi / 2
    n.position = SCNVector3(baseW / 2 + 0.005, feet + baseT * 0.5, -baseD / 2 + 3.5 + Double(i) * 2.6)
    laptop.addChildNode(n)
}

let hinge = SCNNode(geometry: SCNCylinder(radius: 0.36, height: 25.0))
hinge.geometry?.materials = [darkMetal]
hinge.eulerAngles.z = .pi / 2
hinge.position = SCNVector3(0, hingeY - 0.06, hingeZ)
laptop.addChildNode(hinge)

let lidPivot = SCNNode()
lidPivot.position = SCNVector3(0, hingeY, hingeZ)
laptop.addChildNode(lidPivot)

let lidHeight = lidTop - lidLow
let lidShell = SCNNode(geometry: slab(baseW, lidHeight, cornerR, depth: lidT, chamfer: 0.14, material: aluminium))
lidShell.position = SCNVector3(0, lidLow + lidHeight / 2, lidFace - lidT / 2)
lidPivot.addChildNode(lidShell)

let glassShape = SCNShape(path: roundedPath(baseW - 0.34, lidHeight - 0.34, cornerR - 0.17), extrusionDepth: 0.02)
glassShape.materials = [glassMaterial]
let glass = SCNNode(geometry: glassShape)
glass.position = SCNVector3(0, lidLow + lidHeight / 2, lidFace + 0.01)
lidPivot.addChildNode(glass)

let screenMaterial = SCNMaterial()
screenMaterial.lightingModel = .physicallyBased
screenMaterial.diffuse.contents = NSColor.black
screenMaterial.metalness.contents = 0.0
screenMaterial.roughness.contents = 0.05
screenMaterial.emission.mipFilter = .linear
screenMaterial.emission.minificationFilter = .linear
screenMaterial.emission.magnificationFilter = .linear
screenMaterial.emission.maxAnisotropy = 16
let screenNode = SCNNode(geometry: SCNPlane(width: displayW, height: displayH))
screenNode.geometry?.materials = [screenMaterial]
screenNode.position = SCNVector3(0, displayCentreY, lidFace + 0.025)
lidPivot.addChildNode(screenNode)

let spill = SCNLight()
spill.type = .area
spill.areaType = .rectangle
spill.areaExtents = simd_float3(Float(displayW), Float(displayH), 1)
spill.drawsArea = false
spill.castsShadow = false
let spillNode = SCNNode()
spillNode.light = spill
spillNode.eulerAngles.y = .pi
spillNode.position = SCNVector3(0, displayCentreY, lidFace + 0.2)
lidPivot.addChildNode(spillNode)

let key = SCNLight()
key.type = .spot
key.intensity = 1600
key.color = color(1.0, 0.97, 0.92)
key.spotInnerAngle = 30
key.spotOuterAngle = 70
key.castsShadow = true
key.shadowMapSize = CGSize(width: 4096, height: 4096)
key.shadowRadius = 14
key.shadowSampleCount = 32
key.shadowColor = NSColor(white: 0, alpha: 0.8)
key.zNear = 20
key.zFar = 300
let keyNode = SCNNode()
keyNode.light = key
keyNode.position = SCNVector3(-35, 95, 55)
keyNode.look(at: SCNVector3(0, 0, -3))
scene.rootNode.addChildNode(keyNode)

let shadowImage = bitmap(512, 512) { ctx in
    ctx.setFillColor(CGColor(gray: 1, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: 512, height: 512))
    ctx.setShadow(offset: .zero, blur: 26, color: CGColor(gray: 0, alpha: 1))
    ctx.setFillColor(CGColor(gray: 0.15, alpha: 1))
    ctx.addPath(CGPath(roundedRect: CGRect(x: 56, y: 76, width: 400, height: 360), cornerWidth: 18, cornerHeight: 18, transform: nil))
    ctx.fillPath()
}
let contact = SCNMaterial()
contact.lightingModel = .constant
contact.diffuse.contents = shadowImage
contact.blendMode = .multiply
contact.writesToDepthBuffer = false
let contactNode = SCNNode(geometry: SCNPlane(width: baseW * 512 / 400, height: baseD * 512 / 360))
contactNode.geometry?.materials = [contact]
contactNode.eulerAngles.x = -.pi / 2
contactNode.position = SCNVector3(0, 0.02, 0)
contactNode.renderingOrder = 5
scene.rootNode.addChildNode(contactNode)

let floor = SCNFloor()
floor.reflectivity = 0.07
floor.reflectionFalloffEnd = 12
floor.reflectionResolutionScaleFactor = 0.5
let deskMaterial = pbr(color(0.10, 0.105, 0.125), metal: 0, rough: 0.55)
deskMaterial.diffuse.contents = noiseImage(512, seed: 3, amount: 0.04, base: 0.12)
deskMaterial.multiply.contents = color(0.85, 0.88, 1.0)
deskMaterial.diffuse.wrapS = .repeat
deskMaterial.diffuse.wrapT = .repeat
deskMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(20, 20, 1)
floor.materials = [deskMaterial]
scene.rootNode.addChildNode(SCNNode(geometry: floor))

let camera = SCNCamera()
camera.wantsHDR = true
camera.zNear = 1
camera.zFar = 2000
camera.wantsExposureAdaptation = false
camera.exposureOffset = 0
camera.bloomIntensity = 0
camera.screenSpaceAmbientOcclusionIntensity = 0.8
camera.screenSpaceAmbientOcclusionRadius = 1.2
camera.screenSpaceAmbientOcclusionDepthThreshold = 0.5
camera.wantsDepthOfField = true
camera.focalBlurSampleCount = 12
camera.apertureBladeCount = 8
camera.sensorHeight = 24
let cameraNode = SCNNode()
cameraNode.camera = camera
scene.rootNode.addChildNode(cameraNode)

struct Shot {
    var eye: SIMD3<Double>
    var target: SIMD3<Double>
    var focal: Double
}

func lerpShot(_ a: Shot, _ b: Shot, _ t: Double) -> Shot {
    Shot(eye: mix(a.eye, b.eye, t), target: mix(a.target, b.target, t), focal: mix(a.focal, b.focal, t))
}

let wedgeStart = Shot(eye: SIMD3(11, 3.4, 72), target: SIMD3(0.5, 4.0, 0), focal: 50)
let wedgeEnd = Shot(eye: SIMD3(4, 2.4, 44), target: SIMD3(0.3, 4.6, 0), focal: 55)
let heroStart = Shot(eye: SIMD3(9, 20, 62), target: SIMD3(0.3, 11.2, -8), focal: 50)
let heroEnd = Shot(eye: SIMD3(6.5, 19.5, 58), target: SIMD3(0.2, 11.4, -8), focal: 50)

let clipStart = from
let wedgeSpan = rise.start - clipStart
let craneStart = rise.start - 0.15
let craneEnd = rise.end + 1.25

func shot(at t: Double) -> Shot {
    let a = lerpShot(wedgeStart, wedgeEnd, (t - clipStart) / wedgeSpan)
    let b = lerpShot(heroStart, heroEnd, smooth((t - craneEnd) / 6))
    return lerpShot(a, b, smoother((t - craneStart) / (craneEnd - craneStart)))
}

func lidLocalToWorld(_ p: SIMD3<Double>, angle: Double) -> SIMD3<Double> {
    let a = (90 - angle) * .pi / 180
    let y = p.y * cos(a) - p.z * sin(a)
    let z = p.y * sin(a) + p.z * cos(a)
    return SIMD3(p.x, hingeY + y, hingeZ + z)
}

func pose(at t: Double) {
    let angle = displayAngle(t)
    lidPivot.eulerAngles.x = CGFloat((90 - angle) * .pi / 180)
    let s = shot(at: t)
    cameraNode.position = vec(s.eye)
    cameraNode.look(at: vec(s.target), up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, -1))
    camera.focalLength = s.focal
    let centre = lidLocalToWorld(SIMD3(0, displayCentreY, lidFace), angle: angle)
    camera.focusDistance = simd_length(centre - s.eye)
    camera.fStop = 5.6 * 100
}

let renderW = outWidth * supersample, renderH = outHeight * supersample
func makeTarget(_ format: MTLPixelFormat, _ usage: MTLTextureUsage, _ storage: MTLStorageMode) -> MTLTexture {
    let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: format, width: renderW, height: renderH, mipmapped: false)
    d.usage = usage
    d.storageMode = storage
    guard let t = device.makeTexture(descriptor: d) else { fail("texture") }
    return t
}
let colorTarget = makeTarget(.rgba16Float, [.renderTarget, .shaderRead], .shared)
let depthTarget = makeTarget(.depth32Float, [.renderTarget], .private)
let pass = MTLRenderPassDescriptor()
pass.colorAttachments[0].texture = colorTarget
pass.colorAttachments[0].loadAction = .clear
pass.colorAttachments[0].storeAction = .store
pass.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
pass.depthAttachment.texture = depthTarget
pass.depthAttachment.loadAction = .clear
pass.depthAttachment.storeAction = .dontCare

let renderer = SCNRenderer(device: device, options: nil)
renderer.scene = scene
renderer.pointOfView = cameraNode

let screenTW = 2200, screenTH = 1430
func loadScreen(_ path: String) -> (MTLTexture, SIMD3<Double>) {
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
          let frame = CGImageSourceCreateImageAtIndex(src, 0, nil) else { fail("could not read \(path)") }
    let w = screenTW, h = screenTH
    guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4, space: srgbSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { fail("ctx") }
    ctx.setFillColor(CGColor(gray: 0, alpha: 1))
    ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
    let radius = Double(h) * 0.03
    let rect = CGRect(x: 0, y: 0, width: w, height: h)
    let outline = CGMutablePath()
    outline.move(to: CGPoint(x: 0, y: 0))
    outline.addLine(to: CGPoint(x: Double(w), y: 0))
    outline.addArc(tangent1End: CGPoint(x: Double(w), y: Double(h)), tangent2End: CGPoint(x: 0, y: Double(h)), radius: radius)
    outline.addArc(tangent1End: CGPoint(x: 0, y: Double(h)), tangent2End: CGPoint(x: 0, y: 0), radius: radius)
    outline.closeSubpath()
    ctx.saveGState()
    ctx.addPath(outline)
    ctx.clip()
    ctx.interpolationQuality = .high
    ctx.draw(frame, in: rect)
    ctx.restoreGState()
    let notchW = Double(w) * 0.115, notchH = Double(h) * 0.036
    let notch = CGMutablePath()
    let nx = (Double(w) - notchW) / 2
    notch.move(to: CGPoint(x: nx - 8, y: Double(h)))
    notch.addArc(tangent1End: CGPoint(x: nx, y: Double(h)), tangent2End: CGPoint(x: nx, y: Double(h) - notchH), radius: 8)
    notch.addArc(tangent1End: CGPoint(x: nx, y: Double(h) - notchH), tangent2End: CGPoint(x: nx + notchW, y: Double(h) - notchH), radius: notchH * 0.45)
    notch.addArc(tangent1End: CGPoint(x: nx + notchW, y: Double(h) - notchH), tangent2End: CGPoint(x: nx + notchW, y: Double(h)), radius: notchH * 0.45)
    notch.addArc(tangent1End: CGPoint(x: nx + notchW, y: Double(h)), tangent2End: CGPoint(x: nx + notchW + 8, y: Double(h)), radius: 8)
    notch.closeSubpath()
    ctx.addPath(notch)
    ctx.fillPath()
    guard let data = ctx.data else { fail("ctx data") }
    let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm_srgb, width: w, height: h, mipmapped: true)
    d.usage = [.shaderRead]
    guard let tex = device.makeTexture(descriptor: d) else { fail("screen texture") }
    let flipped = UnsafeMutablePointer<UInt8>.allocate(capacity: w * h * 4)
    defer { flipped.deallocate() }
    let bytes = data.bindMemory(to: UInt8.self, capacity: w * h * 4)
    var sum = SIMD3<Double>(0, 0, 0)
    for y in 0..<h {
        memcpy(flipped + y * w * 4, bytes + y * w * 4, w * 4)
        if y % 8 == 0 {
            for x in stride(from: 0, to: w, by: 8) {
                let i = (y * w + x) * 4
                sum += SIMD3(pow(Double(bytes[i]) / 255, 2.2), pow(Double(bytes[i + 1]) / 255, 2.2), pow(Double(bytes[i + 2]) / 255, 2.2))
            }
        }
    }
    let samples = Double((h / 8) * (w / 8))
    tex.replace(region: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0, withBytes: flipped, bytesPerRow: w * 4)
    let cb = queue.makeCommandBuffer()!
    let blit = cb.makeBlitCommandEncoder()!
    blit.generateMipmaps(for: tex)
    blit.endEncoding()
    cb.commit()
    cb.waitUntilCompleted()
    return (tex, sum / samples)
}

let pixelCount = renderW * renderH
var half = [UInt16](repeating: 0, count: pixelCount * 4)
var single = [Float](repeating: 0, count: pixelCount * 4)
var accum = [Float](repeating: 0, count: pixelCount * 4)

func renderSubframe(_ t: Double) {
    SCNTransaction.begin()
    SCNTransaction.disableActions = true
    pose(at: t)
    SCNTransaction.commit()
    SCNTransaction.flush()
    let cb = queue.makeCommandBuffer()!
    renderer.render(atTime: t, viewport: CGRect(x: 0, y: 0, width: renderW, height: renderH), commandBuffer: cb, passDescriptor: pass)
    cb.commit()
    cb.waitUntilCompleted()
    half.withUnsafeMutableBytes { raw in
        colorTarget.getBytes(raw.baseAddress!, bytesPerRow: renderW * 8, from: MTLRegionMake2D(0, 0, renderW, renderH), mipmapLevel: 0)
    }
    half.withUnsafeMutableBytes { src in
        single.withUnsafeMutableBytes { dst in
            var s = vImage_Buffer(data: src.baseAddress!, height: 1, width: vImagePixelCount(pixelCount * 4), rowBytes: pixelCount * 8)
            var d = vImage_Buffer(data: dst.baseAddress!, height: 1, width: vImagePixelCount(pixelCount * 4), rowBytes: pixelCount * 16)
            vImageConvert_Planar16FtoPlanarF(&s, &d, 0)
        }
    }
    vDSP_vadd(accum, 1, single, 1, &accum, 1, vDSP_Length(pixelCount * 4))
}

func blur(_ buffer: inout [Float], width: Int, height: Int, radius: Int) {
    var tmp = [Float](repeating: 0, count: buffer.count)
    let r = max(1, radius)
    let scale = 1 / Float(2 * r + 1)
    for _ in 0..<3 {
        for y in 0..<height {
            for c in 0..<4 {
                var sum: Float = 0
                for k in -r...r { sum += buffer[(y * width + min(width - 1, max(0, k))) * 4 + c] }
                for x in 0..<width {
                    tmp[(y * width + x) * 4 + c] = sum * scale
                    let add = min(width - 1, x + r + 1), drop = max(0, x - r)
                    sum += buffer[(y * width + add) * 4 + c] - buffer[(y * width + drop) * 4 + c]
                }
            }
        }
        for x in 0..<width {
            for c in 0..<4 {
                var sum: Float = 0
                for k in -r...r { sum += tmp[(min(height - 1, max(0, k)) * width + x) * 4 + c] }
                for y in 0..<height {
                    buffer[(y * width + x) * 4 + c] = sum * scale
                    let add = min(height - 1, y + r + 1), drop = max(0, y - r)
                    sum += tmp[(add * width + x) * 4 + c] - tmp[(drop * width + x) * 4 + c]
                }
            }
        }
    }
}

var rng = UInt64(12345)
func noise() -> Float {
    rng = rng &* 6364136223846793005 &+ 1442695040888963407
    return Float(rng >> 40) / Float(1 << 24)
}

func tone(_ x: Float) -> Float {
    let k: Float = 0.78
    if x <= k { return max(0, x) }
    return k + (1 - k) * (1 - exp(-(x - k) / (1 - k)))
}

func encode(_ x: Float) -> Float {
    x <= 0.0031308 ? x * 12.92 : 1.055 * pow(x, 1 / 2.4) - 0.055
}

func finish(index: Int, samples: Int, fade: Double) {
    let w = outWidth, h = outHeight, ss = supersample
    var out = [Float](repeating: 0, count: w * h * 4)
    let norm = 1 / Float(samples * ss * ss)
    for y in 0..<h {
        for x in 0..<w {
            var r: Float = 0, g: Float = 0, b: Float = 0
            for sy in 0..<ss {
                let row = (y * ss + sy) * renderW
                for sx in 0..<ss {
                    let i = (row + x * ss + sx) * 4
                    r += accum[i]; g += accum[i + 1]; b += accum[i + 2]
                }
            }
            let o = (y * w + x) * 4
            out[o] = 1; out[o + 1] = r * norm; out[o + 2] = g * norm; out[o + 3] = b * norm
        }
    }
    let bw = w / 4, bh = h / 4
    var bloom = [Float](repeating: 0, count: bw * bh * 4)
    let threshold: Float = 0.85
    for y in 0..<bh {
        for x in 0..<bw {
            var r: Float = 0, g: Float = 0, b: Float = 0
            for sy in 0..<4 {
                for sx in 0..<4 {
                    let i = ((y * 4 + sy) * w + x * 4 + sx) * 4
                    r += out[i + 1]; g += out[i + 2]; b += out[i + 3]
                }
            }
            r /= 16; g /= 16; b /= 16
            let l = max(r, max(g, b))
            let k = l > threshold ? (l - threshold) / max(l, 1e-4) : 0
            let o = (y * bw + x) * 4
            bloom[o] = 1; bloom[o + 1] = r * k; bloom[o + 2] = g * k; bloom[o + 3] = b * k
        }
    }
    var wide = bloom
    blur(&bloom, width: bw, height: bh, radius: 6)
    blur(&wide, width: bw, height: bh, radius: 22)
    let bloomStrength: Float = 0.22, wideStrength: Float = 0.18
    let exposure = Float(fade)
    var pixels = [UInt8](repeating: 255, count: w * h * 4)
    for y in 0..<h {
        let by = min(bh - 1, max(0, Int((Double(y) + 0.5) / 4 - 0.5)))
        let fy = Float((Double(y) + 0.5) / 4 - 0.5 - Double(by))
        let by1 = min(bh - 1, by + 1)
        let ny = Float(y) / Float(h) - 0.5
        for x in 0..<w {
            let bx = min(bw - 1, max(0, Int((Double(x) + 0.5) / 4 - 0.5)))
            let fx = Float((Double(x) + 0.5) / 4 - 0.5 - Double(bx))
            let bx1 = min(bw - 1, bx + 1)
            let nx = Float(x) / Float(w) - 0.5
            let vignette = 1 - 0.35 * pow(nx * nx * 1.1 + ny * ny * 1.6, 1.3)
            let o = (y * w + x) * 4
            let dither = (noise() + noise() - 1) / 255
            for c in 1...3 {
                func sample(_ buf: [Float]) -> Float {
                    let a = buf[(by * bw + bx) * 4 + c], b = buf[(by * bw + bx1) * 4 + c]
                    let d = buf[(by1 * bw + bx) * 4 + c], e = buf[(by1 * bw + bx1) * 4 + c]
                    return (a * (1 - fx) + b * fx) * (1 - fy) + (d * (1 - fx) + e * fx) * fy
                }
                let v = (out[o + c] + sample(bloom) * bloomStrength + sample(wide) * wideStrength) * vignette * exposure
                let s = encode(tone(v)) + dither
                pixels[o + c - 1] = UInt8(max(0, min(255, (s * 255).rounded())))
            }
            pixels[o + 3] = 255
        }
    }
    let data = Data(pixels)
    guard let provider = CGDataProvider(data: data as CFData),
          let image = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4, space: srgbSpace,
                              bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue), provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent),
          let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: String(format: "%@/frame-%04d.png", outDir, index)) as CFURL, UTType.png.identifier as CFString, 1, nil) else { fail("write") }
    CGImageDestinationAddImage(dest, image, nil)
    if !CGImageDestinationFinalize(dest) { fail("write frame \(index)") }
}

let total = screenFiles.count
let fadeOut = options.double("fade", 0.6)
let started = Date()
for (index, name) in screenFiles.enumerated() {
    if let only, !only.contains(index) { continue }
    let t = from + Double(index) / fps
    let (texture, average) = loadScreen(screenDir + "/" + name)
    screenMaterial.emission.contents = texture
    screenMaterial.emission.intensity = 1.0
    let luminance = simd_dot(average, SIMD3(0.2126, 0.7152, 0.0722))
    let tint = (average / max(1e-4, luminance) + SIMD3(1, 1, 1)) * 0.25
    spill.color = NSColor(srgbRed: pow(clamp(tint.x), 1 / 2.2), green: pow(clamp(tint.y), 1 / 2.2), blue: pow(clamp(tint.z), 1 / 2.2), alpha: 1)
    spill.intensity = 1800 * luminance
    let room = clamp(luminance * 3)
    scene.lightingEnvironment.intensity = 0.8 + 0.5 * room
    let moving = abs(displayAngle(t + 0.5 / fps) - displayAngle(t - 0.5 / fps)) > 0.5
    let samples = moving ? max(baseSubframes, 12) : baseSubframes
    let shutter = 0.5 / fps
    for i in accum.indices { accum[i] = 0 }
    for s in 0..<samples {
        let offset = samples == 1 ? 0 : (Double(s) / Double(samples - 1) - 0.5) * shutter
        renderSubframe(t + offset)
    }
    let remaining = Double(total - index - 1) / fps
    let fade = smooth(remaining / fadeOut)
    finish(index: index, samples: samples, fade: fade)
    print(String(format: "frame %d/%d t=%.2f angle=%.1f lum=%.3f %.1fs", index + 1, total, t, displayAngle(t), luminance, Date().timeIntervalSince(started)))
}
