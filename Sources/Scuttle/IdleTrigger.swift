import CoreGraphics
import Foundation
import IOKit.pwr_mgt

final class IdleTrigger {
    static let startAngle = 90.0
    static let targetAngle = 25.0
    static let easeSeconds = 4.0
    static let pollInterval = 1.0 / 8
    static let assertionInterval = 5.0
    static let forceGrace = 1.0

    private static let anyInput = CGEventType(rawValue: ~0)!

    private(set) var isActive = false
    private(set) var isForced = false
    private var sticky = false
    private var snoozed = false
    private var since = 0.0
    private var forcedAt = 0.0
    private var lastPoll = -Double.infinity
    private var lastAssertionCheck = -Double.infinity
    private var blocked = false

    static var secondsSinceInput: Double {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
    }

    static var displaySleepPrevented: Bool {
        var status: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsStatus(&status) == kIOReturnSuccess,
              let values = status?.takeRetainedValue() as? [String: Any] else { return false }
        for key in ["PreventUserIdleDisplaySleep", "NoDisplaySleepAssertion"] {
            if let count = values[key] as? Int, count > 0 { return true }
        }
        return false
    }

    func angle(at now: Double) -> Double? {
        guard isActive else { return nil }
        let p = min(1, max(0, (now - since) / IdleTrigger.easeSeconds))
        let eased = p * p * (3 - 2 * p)
        return IdleTrigger.startAngle + (IdleTrigger.targetAngle - IdleTrigger.startAngle) * eased
    }

    func force(sticky: Bool, now: Double) {
        if !isActive { since = now }
        isActive = true
        isForced = true
        forcedAt = now
        self.sticky = sticky
        snoozed = false
    }

    func wake() {
        reset()
        snoozed = IdleTrigger.secondsSinceInput > IdleTrigger.forceGrace
    }

    func reset() {
        isActive = false
        isForced = false
        sticky = false
    }

    @discardableResult
    func update(now: Double, threshold: Int, allowed: Bool) -> Bool {
        let was = isActive
        if isForced {
            let away = now - forcedAt - IdleTrigger.forceGrace
            if !sticky, away > 0, IdleTrigger.secondsSinceInput < away { reset() }
            return was != isActive
        }
        guard allowed, threshold > 0 else {
            reset()
            return was != isActive
        }
        let limit = Double(threshold)
        if isActive {
            if IdleTrigger.secondsSinceInput < limit {
                reset()
            } else if now - lastAssertionCheck >= IdleTrigger.assertionInterval {
                lastAssertionCheck = now
                if IdleTrigger.displaySleepPrevented { reset() }
            }
        } else if now - lastPoll >= IdleTrigger.pollInterval {
            lastPoll = now
            let idle = IdleTrigger.secondsSinceInput
            if idle < limit {
                snoozed = false
                blocked = false
            } else if !snoozed {
                if !blocked || now - lastAssertionCheck >= IdleTrigger.assertionInterval {
                    lastAssertionCheck = now
                    blocked = IdleTrigger.displaySleepPrevented
                }
                if !blocked {
                    isActive = true
                    since = now
                }
            }
        }
        return was != isActive
    }
}
