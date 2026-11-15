import Foundation
import CoreGraphics

public enum Locomotion: String, Codable, Sendable {
    case crawl
    case walk
    case hop
    case flutter
    case hover
    case float
    case dart
}

public enum Stance: String, Codable, Sendable {
    case topDown
    case upright
}

public enum Species: String, CaseIterable, Codable, Sendable {
    case ladybird
    case bumblebee
    case snail
    case chick
    case butterfly
    case dragonfly
    case firefly
    case crab
    case hedgehog
    case acorn
    case toadstool
    case leaf
    case penguin
    case snowman
    case snowflake
    case robin
    case ghost
    case bat
    case pumpkin
    case spider
    case gingerbread
    case present
    case elf
    case reindeer
    case balloon
    case star
    case sparkler
    case rocket
    case frog
    case cloud
    case sun
    case owl
    case bunny
    case turtle
    case fox
    case polarBear = "polarbear"
    case blackCat = "blackcat"
    case santa
    case comet
    case ufo

    public var locomotion: Locomotion {
        switch self {
        case .ladybird, .snail, .spider, .crab, .turtle: return .crawl
        case .hedgehog, .toadstool, .penguin, .gingerbread, .elf, .reindeer, .sparkler, .snowman, .fox, .polarBear, .blackCat, .santa: return .walk
        case .chick, .acorn, .robin, .pumpkin, .present, .frog, .owl, .bunny: return .hop
        case .butterfly, .bat: return .flutter
        case .bumblebee, .firefly, .ufo: return .hover
        case .leaf, .snowflake, .ghost, .balloon, .star, .cloud, .sun: return .float
        case .dragonfly, .rocket, .comet: return .dart
        }
    }

    public var stance: Stance {
        switch self {
        case .ladybird, .bumblebee, .snail, .butterfly, .dragonfly, .firefly, .crab, .spider, .bat, .leaf, .snowflake, .star, .rocket, .comet:
            return .topDown
        default:
            return .upright
        }
    }

    public var isRare: Bool {
        switch self {
        case .bunny, .turtle, .fox, .polarBear, .blackCat, .santa, .comet, .ufo: return true
        default: return false
        }
    }

    public static let rareVisitors: [Species] = allCases.filter { $0.isRare }

    public var title: String {
        switch self {
        case .polarBear: return "Polar bear"
        case .blackCat: return "Black cat"
        case .ufo: return "UFO"
        default: return rawValue.prefix(1).uppercased() + rawValue.dropFirst()
        }
    }

    public var isAirborne: Bool {
        switch locomotion {
        case .flutter, .hover, .float, .dart: return true
        case .crawl, .walk, .hop: return false
        }
    }
}

public enum Gesture: String, CaseIterable, Codable, Sendable {
    case none
    case peek
    case tiptoe
    case wave
    case dance
    case cheer
    case sleep
    case look
    case shiver
    case tumble
    case parachute
    case popUp = "popup"
    case perch
    case carry
    case push
    case pull
    case build
    case count
    case kick
}

public enum CritterMode: String, Codable, Sendable {
    case hidden
    case emerging
    case wandering
    case resting
    case startled
    case fleeing
}

public struct Critter: Identifiable, Sendable {
    public var id: Int
    public var species: Species
    public var position: CGPoint
    public var heading: Double
    public var speed: Double
    public var size: Double
    public var mode: CritterMode
    public var gaitPhase: Double
    public var bend: Double
    public var antennaPhase: Double
    public var tint: Double
    public var alpha: Double
    public var confusion: Double
    public var facing: Double
    public var lift: Double
    public var fright: Double
    public var gesture: Gesture
    public var gestureTime: Double
    public var windup: Double
    public var dash: Double
    public var dashFrom: CGPoint
    public var quirk: CatchQuirk

    public init(
        id: Int,
        species: Species,
        position: CGPoint,
        heading: Double = .pi / 2,
        speed: Double = 0,
        size: Double = 18,
        mode: CritterMode = .wandering,
        gaitPhase: Double = 0,
        bend: Double = 0,
        antennaPhase: Double = 0,
        tint: Double = 0.5,
        alpha: Double = 1,
        confusion: Double = 0,
        facing: Double = 1,
        lift: Double = 0,
        fright: Double = 0,
        gesture: Gesture = .none,
        gestureTime: Double = 0,
        windup: Double = 0,
        dash: Double = 0,
        dashFrom: CGPoint = .zero,
        quirk: CatchQuirk = .none
    ) {
        self.id = id
        self.species = species
        self.position = position
        self.heading = heading
        self.speed = speed
        self.size = size
        self.mode = mode
        self.gaitPhase = gaitPhase
        self.bend = bend
        self.antennaPhase = antennaPhase
        self.tint = tint
        self.alpha = alpha
        self.confusion = confusion
        self.facing = facing
        self.lift = lift
        self.fright = fright
        self.gesture = gesture
        self.gestureTime = gestureTime
        self.windup = windup
        self.dash = dash
        self.dashFrom = dashFrom
        self.quirk = quirk
    }
}
