import Foundation

public struct SleepStage: Sendable {
    public enum Phase: String, Sendable {
        case awake
        case staged
        case waking
    }

    public enum Signal: String, Sendable {
        case displaySleep
        case displayWake
        case systemSleep
        case systemWake
        case lidClosed
        case lidOpened
        case locked
        case unlocked
        case sessionResigned
        case sessionActive
    }

    public struct Context: Sendable, Equatable {
        public var enabled: Bool
        public var stageable: Bool

        public init(enabled: Bool, stageable: Bool) {
            self.enabled = enabled
            self.stageable = stageable
        }
    }

    public enum Action: Equatable, Sendable {
        case stage
        case conceal
        case reveal
        case startCatch(from: Double)
        case cancel
    }

    public private(set) var phase = Phase.awake
    public private(set) var stagedAt: Double?
    public private(set) var wokeAt: Double?
    public private(set) var displayAsleep = false
    public private(set) var systemAsleep = false
    public private(set) var lidClosed = false
    public private(set) var locked = false
    public private(set) var sessionInactive = false
    public var grace: Double

    public init(grace: Double = 0.12) {
        self.grace = grace
    }

    public var isStaged: Bool { phase != .awake }
    public var isDark: Bool { displayAsleep || systemAsleep || lidClosed }
    public var isHidden: Bool { isDark || locked || sessionInactive }
    public var freezesWorld: Bool { phase != .awake }

    public mutating func handle(_ signal: Signal, at now: Double, context: Context) -> [Action] {
        switch signal {
        case .displaySleep: displayAsleep = true
        case .systemSleep: systemAsleep = true
        case .lidClosed: lidClosed = true
        case .displayWake:
            displayAsleep = false
            lidClosed = false
        case .systemWake: systemAsleep = false
        case .lidOpened: lidClosed = false
        case .locked: locked = true
        case .unlocked: locked = false
        case .sessionResigned: sessionInactive = true
        case .sessionActive: sessionInactive = false
        }
        if !context.enabled || !context.stageable || sessionInactive {
            return phase == .awake ? [] : reset()
        }
        switch signal {
        case .displaySleep, .systemSleep, .lidClosed:
            switch phase {
            case .awake:
                phase = .staged
                stagedAt = now
                wokeAt = nil
                return [.stage]
            case .waking:
                phase = .staged
                wokeAt = nil
                return []
            case .staged:
                return []
            }
        case .locked:
            guard phase != .awake else { return [] }
            phase = .staged
            wokeAt = nil
            return [.conceal]
        case .displayWake, .systemWake, .lidOpened, .unlocked, .sessionActive:
            guard phase == .staged, !isHidden else { return [] }
            phase = .waking
            wokeAt = now
            return [.reveal]
        case .sessionResigned:
            return []
        }
    }

    public mutating func update(_ context: Context) -> [Action] {
        guard phase != .awake, !context.enabled || !context.stageable else { return [] }
        return reset()
    }

    public mutating func tick(at now: Double) -> [Action] {
        guard phase == .waking, let woke = wokeAt, now >= woke + grace else { return [] }
        phase = .awake
        stagedAt = nil
        wokeAt = nil
        return [.startCatch(from: woke + grace)]
    }

    private mutating func reset() -> [Action] {
        phase = .awake
        stagedAt = nil
        wokeAt = nil
        return [.cancel]
    }
}
