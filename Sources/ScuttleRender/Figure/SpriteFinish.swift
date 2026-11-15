import Foundation
import CoreGraphics

struct SpriteFinish {
    var border: CGFloat = 0
    var borderMinPt: CGFloat = 0
    var borderTone: Tone = .white
    var shadowBlur: CGFloat = 0
    var shadowMinPt: CGFloat = 0
    var shadowDrop: CGFloat = 0
    var shadowTone: Tone = .clear

    static let none = SpriteFinish()

    var isEmpty: Bool { border <= 0 && borderMinPt <= 0 && shadowTone.a <= 0 }

    func apply(to image: CGImage, designPx: CGFloat, scale: CGFloat, space: CGColorSpace) -> (image: CGImage, pad: Int)? {
        let r = border > 0 || borderMinPt > 0 ? max(border * designPx, borderMinPt * scale) : 0
        let shadowed = shadowTone.a > 0
        let blur = shadowed ? max(shadowBlur * designPx, shadowMinPt * scale) : 0
        let drop = shadowed ? shadowDrop * designPx : 0
        let pad = Int((r + blur * 1.25 + abs(drop) + 2).rounded(.up))
        let w = image.width + 2 * pad, h = image.height + 2 * pad
        let info = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard w < 4096, h < 4096,
              let out = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: info)
        else { return nil }
        let full = CGRect(x: 0, y: 0, width: w, height: h)
        let inner = CGRect(x: pad, y: pad, width: image.width, height: image.height)
        var cut: CGImage?
        if r > 0.3 {
            var mask: CGImage? = image
            var frame = inner
            for (pass, angle) in ([0, CGFloat.pi / 3, 2 * CGFloat.pi / 3] as [CGFloat]).enumerated() {
                guard let src = mask,
                      let d = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: info)
                else { return nil }
                let steps = max(1, Int((r * 0.55).rounded(.up)))
                let dx = cos(angle) * r * 0.5, dy = sin(angle) * r * 0.5
                for i in -steps...steps {
                    let u = CGFloat(i) / CGFloat(steps)
                    d.draw(src, in: frame.offsetBy(dx: dx * u, dy: dy * u))
                }
                if pass == 2 {
                    d.setBlendMode(.sourceIn)
                    d.setFillColor(borderTone.cg)
                    d.fill(full)
                }
                mask = d.makeImage()
                frame = full
            }
            cut = mask
        }
        if shadowed {
            out.setShadow(offset: CGSize(width: 0, height: -drop), blur: blur, color: shadowTone.cg)
        }
        if let cut {
            out.draw(cut, in: full)
            out.setShadow(offset: .zero, blur: 0, color: nil)
            out.draw(image, in: inner)
        } else {
            out.draw(image, in: inner)
        }
        guard let made = out.makeImage() else { return nil }
        return (made, pad)
    }
}
