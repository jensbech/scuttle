import AppKit
import IOKit
import QuartzCore

final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class OverlayView: NSView {
    var onDraw: ((CGContext, CGSize) -> Void)?
    var onFrame: (() -> Void)?

    override var isFlipped: Bool { false }
    override var isOpaque: Bool { false }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        ctx.clear(bounds)
        onDraw?(ctx, bounds.size)
    }

    @objc func frame(_ sender: Any) {
        onFrame?()
    }
}

final class Overlay {
    let window: OverlayWindow
    let view: OverlayView
    private(set) var hasScreen = false
    private(set) var screen: NSScreen?
    private let headless: Bool
    private var link: AnyObject?
    private var timer: Timer?
    static let linkStall = 0.05

    var onFrame: (() -> Void)?
    private var lastLinked = 0.0

    var size: CGSize { view.bounds.size }

    init(headless: Bool) {
        self.headless = headless
        let frame = NSRect(x: 0, y: 0, width: 1440, height: 900)
        window = OverlayWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.hidesOnDeactivate = false
        window.animationBehavior = .none
        window.isExcludedFromWindowsMenu = true
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        view = OverlayView(frame: frame)
        view.wantsLayer = true
        view.layerContentsRedrawPolicy = .onSetNeedsDisplay
        window.contentView = view
        view.onFrame = { [weak self] in
            guard let self else { return }
            self.lastLinked = CACurrentMediaTime()
            self.onFrame?()
        }
    }

    static var builtInScreen: NSScreen? {
        NSScreen.screens.first { screen in
            guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID else { return false }
            return CGDisplayIsBuiltin(id) != 0
        }
    }

    static var isDisplayAsleep: Bool {
        let id = builtInScreen?.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
        return CGDisplayIsAsleep(id ?? CGMainDisplayID()) != 0
    }

    static var isLidClosed: Bool {
        let entry = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        guard entry != 0 else { return false }
        defer { IOObjectRelease(entry) }
        let value = IORegistryEntryCreateCFProperty(entry, "AppleClamshellState" as CFString, kCFAllocatorDefault, 0)
        return value?.takeRetainedValue() as? Bool ?? false
    }

    static var isSessionLocked: Bool {
        let session = CGSessionCopyCurrentDictionary() as? [String: Any]
        return session?["CGSSessionScreenIsLocked"] as? Bool ?? false
    }

    func place(on screen: NSScreen?) {
        if headless {
            hasScreen = true
            self.screen = screen ?? NSScreen.main ?? NSScreen.screens.first
            return
        }
        hasScreen = screen != nil
        self.screen = screen
        guard let screen else {
            hide()
            return
        }
        if window.frame != screen.frame {
            window.setFrame(screen.frame, display: false)
        }
    }

    func show() {
        guard hasScreen, !headless, !window.isVisible else { return }
        window.orderFrontRegardless()
    }

    func hide() {
        stopFrames()
        if window.isVisible { window.orderOut(nil) }
    }

    func redraw() {
        view.needsDisplay = true
    }

    var isShown: Bool { !headless && window.isVisible }

    func drawNow() {
        view.needsDisplay = true
        view.displayIfNeeded()
    }

    func startFrames() {
        stopFrames()
        if #available(macOS 14.0, *), !headless {
            let displayLink = view.displayLink(target: view, selector: #selector(OverlayView.frame(_:)))
            displayLink.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
            displayLink.add(to: .main, forMode: .common)
            link = displayLink
        }
        let t = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in
            guard let self, CACurrentMediaTime() - self.lastLinked > Overlay.linkStall else { return }
            self.onFrame?()
        }
        t.tolerance = 0.002
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stopFrames() {
        if #available(macOS 14.0, *) {
            (link as? CADisplayLink)?.invalidate()
        }
        link = nil
        timer?.invalidate()
        timer = nil
    }
}
