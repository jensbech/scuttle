import Foundation
import CoreGraphics
import ScuttleCore

enum Mood: Int, CaseIterable {
    case calm
    case sleepy
    case startled
    case fleeing
    case dizzy
}

struct FigureFrame {
    static let frames = 16
    static let variants = 5
    static let liftSteps = 4

    var species: Species
    var style: ArtStyle
    var variant: Int
    var phase: CGFloat
    var mood: Mood
    var lift: CGFloat
    var blink: Bool
    var twitch: CGFloat
    var size: CGFloat

    init(species: Species, style: ArtStyle = .kawaii, variant: Int = 0, phase: CGFloat = 0, mood: Mood = .calm,
         lift: CGFloat = 0, blink: Bool = false, twitch: CGFloat = 0, size: CGFloat = 30) {
        self.species = species
        self.style = style
        self.variant = variant
        self.phase = phase
        self.mood = mood
        self.lift = lift
        self.blink = blink
        self.twitch = twitch
        self.size = size
    }

    var pt: CGFloat { 100 / max(1, size) }
    var frameIndex: Int { Int((phase * CGFloat(FigureFrame.frames)).rounded()) % FigureFrame.frames }
    var t: CGFloat { phase * 2 * .pi }
    var swing: CGFloat { sin(t) }
    var swing2: CGFloat { sin(2 * t) }
    var sway: CGFloat { cos(t) }
    var bounce: CGFloat { abs(sin(t)) }

    var hurried: Bool { mood == .fleeing || mood == .startled }
    var eyesShut: Bool { mood == .sleepy || (blink && mood != .dizzy) }
    var locomotion: Locomotion { species.locomotion }

    var squat: CGFloat {
        guard locomotion == .hop, phase < 0.25 else { return 0 }
        return sin(phase / 0.25 * .pi)
    }

    var airborne: Bool { locomotion == .hop && phase >= 0.25 }

    var air: CGFloat {
        guard airborne else { return 0 }
        return (phase - 0.25) / 0.75
    }

    var stretch: CGFloat {
        guard airborne else { return 0 }
        return cos(air * .pi)
    }

    var energy: CGFloat {
        switch mood {
        case .sleepy: return 0.35
        case .calm: return 1
        case .dizzy: return 0.8
        case .startled: return 1.3
        case .fleeing: return 1.6
        }
    }

    func pick<T>(_ options: [T]) -> T {
        options[((variant % options.count) + options.count) % options.count]
    }
}
