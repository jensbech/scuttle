import Foundation
import IOKit.hid
import QuartzCore

final class LidSensor: AngleSource {
    let kind = SourceKind.sensor
    var onAvailabilityChange: (() -> Void)?

    private let manager: IOHIDManager
    private var device: IOHIDDevice?
    private var cached: Double?
    private var lastRead = 0.0
    private var lastScan = 0.0
    private var failures = 0

    var isAvailable: Bool { device != nil }

    init() {
        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let match: [String: Any] = [
            kIOHIDVendorIDKey: 0x05AC,
            kIOHIDProductIDKey: 0x8104,
            kIOHIDDeviceUsagePageKey: 0x0020,
            kIOHIDDeviceUsageKey: 0x008A,
        ]
        IOHIDManagerSetDeviceMatching(manager, match as CFDictionary)
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, _, _, device in
            guard let context else { return }
            Unmanaged<LidSensor>.fromOpaque(context).takeUnretainedValue().attach(device)
        }, context)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, _, _, device in
            guard let context else { return }
            Unmanaged<LidSensor>.fromOpaque(context).takeUnretainedValue().detach(device)
        }, context)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        scan()
    }

    var angle: Double? {
        let now = CACurrentMediaTime()
        if now - lastRead < 1.0 / 40 { return cached }
        lastRead = now
        guard let device else {
            if now - lastScan > 5 { scan() }
            return nil
        }
        var report = [UInt8](repeating: 0, count: 8)
        var length = CFIndex(report.count)
        let result = report.withUnsafeMutableBufferPointer {
            IOHIDDeviceGetReport(device, kIOHIDReportTypeFeature, 1, $0.baseAddress!, &length)
        }
        guard result == kIOReturnSuccess, length >= 3 else {
            failures += 1
            if failures >= 40 { detach(device) }
            return cached
        }
        failures = 0
        let raw = Double(UInt16(report[2]) << 8 | UInt16(report[1]))
        cached = raw > 360 ? raw / 100 : raw
        return cached
    }

    func advance(by seconds: Double) {}

    private func scan() {
        lastScan = CACurrentMediaTime()
        guard device == nil, let found = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else { return }
        for candidate in found {
            attach(candidate)
            if device != nil { break }
        }
    }

    private func attach(_ candidate: IOHIDDevice) {
        guard device == nil else { return }
        guard IOHIDDeviceOpen(candidate, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess else { return }
        device = candidate
        failures = 0
        onAvailabilityChange?()
    }

    private func detach(_ candidate: IOHIDDevice) {
        guard let current = device, CFEqual(current, candidate) else { return }
        IOHIDDeviceClose(current, IOOptionBits(kIOHIDOptionsTypeNone))
        device = nil
        cached = nil
        failures = 0
        lastScan = CACurrentMediaTime()
        onAvailabilityChange?()
    }
}
