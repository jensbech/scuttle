import Foundation
import CoreGraphics

public struct Surroundings: Sendable, Equatable {
    public var pointer: CGPoint?
    public var pointerSpeed: Double
    public var ledges: [CGRect]

    public init(pointer: CGPoint? = nil, pointerSpeed: Double = 0, ledges: [CGRect] = []) {
        self.pointer = pointer
        self.pointerSpeed = pointerSpeed
        self.ledges = ledges
    }
}
