import Foundation
import CoreGraphics

public enum PropKind: String, CaseIterable, Codable, Sendable {
    case acorn
    case leafPile
    case pumpkin
    case candy
    case lantern
    case snowball
    case snowman
    case igloo
    case present
    case giftStack
    case tree
    case egg
    case flower
    case nest
    case shell
    case sandcastle
    case ball
    case rope
    case cake
    case balloon
    case banner
    case campfire
    case crumb
}

public struct Prop: Identifiable, Equatable, Sendable {
    public var id: Int
    public var kind: PropKind
    public var position: CGPoint
    public var size: Double
    public var rotation: Double
    public var progress: Double
    public var alpha: Double
    public var holder: Int?
    public var partner: Int?
    public var end: CGPoint?
    public var age: Double
    public var variant: Int

    public init(
        id: Int,
        kind: PropKind,
        position: CGPoint,
        size: Double,
        rotation: Double = 0,
        progress: Double = 1,
        alpha: Double = 1,
        holder: Int? = nil,
        partner: Int? = nil,
        end: CGPoint? = nil,
        age: Double = 0,
        variant: Int = 0
    ) {
        self.id = id
        self.kind = kind
        self.position = position
        self.size = size
        self.rotation = rotation
        self.progress = progress
        self.alpha = alpha
        self.holder = holder
        self.partner = partner
        self.end = end
        self.age = age
        self.variant = variant
    }
}
