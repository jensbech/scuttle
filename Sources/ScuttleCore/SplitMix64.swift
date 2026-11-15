import Foundation

struct SplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func unit() -> Double {
        Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }

    mutating func range(_ r: ClosedRange<Double>) -> Double {
        r.lowerBound + (r.upperBound - r.lowerBound) * unit()
    }

    mutating func signed() -> Double {
        unit() * 2 - 1
    }

    mutating func gauss() -> Double {
        (unit() + unit() + unit() + unit() - 2) * 1.7320508075688772
    }

    mutating func chance(_ p: Double) -> Bool {
        unit() < p
    }
}
