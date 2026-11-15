import Foundation
import CoreGraphics

struct Tone: Equatable {
    var r: CGFloat
    var g: CGFloat
    var b: CGFloat
    var a: CGFloat

    init(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    init(hex: UInt32, _ a: CGFloat = 1) {
        r = CGFloat((hex >> 16) & 0xff) / 255
        g = CGFloat((hex >> 8) & 0xff) / 255
        b = CGFloat(hex & 0xff) / 255
        self.a = a
    }

    init(_ hex: UInt32, _ a: CGFloat = 1) {
        self.init(hex: hex, a)
    }

    func mix(_ o: Tone, _ t: CGFloat) -> Tone {
        Tone(r + (o.r - r) * t, g + (o.g - g) * t, b + (o.b - b) * t, a + (o.a - a) * t)
    }

    func dim(_ k: CGFloat) -> Tone {
        Tone(r * k, g * k, b * k, a)
    }

    func lift(_ t: CGFloat) -> Tone {
        Tone(r + (1 - r) * t, g + (1 - g) * t, b + (1 - b) * t, a)
    }

    func alpha(_ v: CGFloat) -> Tone {
        Tone(r, g, b, v)
    }

    func saturate(_ k: CGFloat) -> Tone {
        let l = luma
        func s(_ c: CGFloat) -> CGFloat { max(0, min(1, l + (c - l) * k)) }
        return Tone(s(r), s(g), s(b), a)
    }

    var luma: CGFloat { 0.2126 * r + 0.7152 * g + 0.0722 * b }

    var cg: CGColor { CGColor(srgbRed: r, green: g, blue: b, alpha: a) }

    static let white = Tone(1, 1, 1)
    static let black = Tone(0, 0, 0)
    static let clear = Tone(0, 0, 0, 0)
    static let ink = Tone(0.16, 0.12, 0.24)
    static let blush = Tone(1, 0.5, 0.6)
    static let cream = Tone(1, 0.96, 0.88)
}
