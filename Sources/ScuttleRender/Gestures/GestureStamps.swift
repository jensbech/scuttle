import Foundation
import CoreGraphics

struct GestureStamp {
    let image: CGImage
    let half: CGFloat
}

struct StampRecipe {
    let kind: StampKind
    let tint: Int
    let half: CGFloat
    let draw: (GesturePen) -> Void
}

enum StampKind: UInt64 {
    case note
    case beamed
    case zed
    case star4
    case star5
    case glove
    case puff
    case confetti
    case dirt
    case canopy
    case digit
    case burst
    case drop
}

final class GestureStamps {
    static let limit = 6 << 20
    private var cache: [UInt64: GestureStamp] = [:]
    private var scale: CGFloat = 2
    private var space = CGColorSpace(name: CGColorSpace.sRGB)!
    private var style: ArtStyle = .kawaii
    private(set) var bytes = 0
    static let budget = 36
    private(set) var spent = 0

    var spare: Bool { spent < GestureStamps.budget }

    func prepare(scale: CGFloat, space: CGColorSpace, style: ArtStyle) {
        if scale != self.scale || style != self.style || !CFEqual(space, self.space) || bytes > GestureStamps.limit {
            purge()
        }
        self.scale = scale
        self.space = space
        self.style = style
        spent = 0
    }

    func spend() {
        spent += 1
    }

    func purge() {
        cache.removeAll(keepingCapacity: true)
        bytes = 0
    }

    func stamp(_ kind: StampKind, tint: Int = 0, size: CGFloat, half: CGFloat, boil: Int = 0, draw: (GesturePen) -> Void) -> GestureStamp? {
        let bucket = UInt64(max(4, min(400, Int((size / 2).rounded()) * 2)))
        let variant = style == .doodle ? UInt64(((boil % 3) + 3) % 3) : 0
        let key = kind.rawValue << 32 | UInt64(tint & 0xff) << 20 | variant << 16 | bucket
        if let hit = cache[key] { return hit }
        let side = Int((2 * half * scale).rounded(.up))
        let info = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard side > 0, side < 2048,
              let c = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: info)
        else { return nil }
        c.translateBy(x: CGFloat(side) / 2, y: CGFloat(side) / 2)
        c.scaleBy(x: scale, y: scale)
        c.setLineCap(.round)
        c.setLineJoin(.round)
        draw(GesturePen(c, style: style, size: size, time: Double(variant) / 7))
        guard let image = c.makeImage() else { return nil }
        let made = GestureStamp(image: image, half: CGFloat(side) / scale / 2)
        cache[key] = made
        bytes += side * side * 4
        return made
    }

    static func place(_ st: GestureStamp, in ctx: CGContext, _ t: CGAffineTransform, alpha: CGFloat) {
        guard alpha > 0.01 else { return }
        ctx.saveGState()
        ctx.concatenate(t)
        ctx.setAlpha(alpha)
        ctx.draw(st.image, in: CGRect(x: -st.half, y: -st.half, width: 2 * st.half, height: 2 * st.half))
        ctx.restoreGState()
    }
}
