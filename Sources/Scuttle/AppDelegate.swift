import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let engine: Engine
    private var menu: StatusMenu?
    private var signals: [DispatchSourceSignal] = []
    private var powerCheck: Timer?

    init(options: Options) {
        engine = Engine(options: options)
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self, andSelector: #selector(openURL(_:reply:)),
            forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL)
        )
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if engine.options.statusItem {
            menu = StatusMenu(engine: engine)
        }
        observe()
        engine.start()
        for command in engine.options.commands { run(command) }
    }

    func applicationWillTerminate(_ notification: Notification) {
        engine.shutdown()
    }

    @objc private func openURL(_ event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        guard let text = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue else { return }
        run(text)
    }

    @objc private func handoff(_ note: Notification) {
        guard let text = note.object as? String else { return }
        text.split(separator: "\n").forEach { run(String($0)) }
    }

    private func run(_ command: String) {
        if !engine.handle(command) {
            NSLog("Scuttle: ignored %@", command)
        }
    }

    private func observe() {
        DistributedNotificationCenter.default().addObserver(
            self, selector: #selector(handoff(_:)), name: Engine.commandNotification,
            object: nil, suspensionBehavior: .deliverImmediately
        )

        let engine = self.engine
        func pause(_ center: NotificationCenter, _ name: Notification.Name, _ reason: String, _ paused: Bool) {
            center.addObserver(forName: name, object: nil, queue: .main) { _ in
                engine.setPaused(paused, reason: reason)
            }
        }
        let workspace = NSWorkspace.shared.notificationCenter
        pause(workspace, NSWorkspace.screensDidSleepNotification, "screens", true)
        pause(workspace, NSWorkspace.screensDidWakeNotification, "screens", false)
        pause(workspace, NSWorkspace.willSleepNotification, "sleep", true)
        pause(workspace, NSWorkspace.didWakeNotification, "sleep", false)
        pause(workspace, NSWorkspace.sessionDidResignActiveNotification, "session", true)
        pause(workspace, NSWorkspace.sessionDidBecomeActiveNotification, "session", false)
        let distributed = DistributedNotificationCenter.default()
        pause(distributed, Notification.Name("com.apple.screenIsLocked"), "lock", true)
        pause(distributed, Notification.Name("com.apple.screenIsUnlocked"), "lock", false)

        for name in [Notification.Name.NSCalendarDayChanged, .NSSystemClockDidChange, .NSSystemTimeZoneDidChange, NSLocale.currentLocaleDidChangeNotification] {
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
                engine.refreshSeason()
                engine.refreshWeather()
            }
        }
        workspace.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { _ in
            engine.refreshSeason()
            engine.refreshWeather()
            engine.woke()
        }

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { _ in
            engine.layout()
            engine.publish(force: true)
        }

        let check = Timer(timeInterval: 2, repeats: true) { _ in
            if engine.isPaused || engine.pace == .active { engine.syncPower() }
        }
        check.tolerance = 1
        RunLoop.main.add(check, forMode: .common)
        powerCheck = check

        for number in [SIGINT, SIGTERM] {
            signal(number, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: number, queue: .main)
            source.setEventHandler { NSApp.terminate(nil) }
            source.resume()
            signals.append(source)
        }
    }
}

final class Forwarder: NSObject, NSApplicationDelegate {
    private let options: Options

    init(options: Options) {
        self.options = options
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self, andSelector: #selector(openURL(_:reply:)),
            forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL)
        )
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let commands = options.handoff
        send(commands)
        print("Scuttle is already running; handed off \(commands.count) command(s).")
        DispatchQueue.main.asyncAfter(deadline: .now() + (commands.isEmpty ? 1.5 : 0.1)) {
            exit(0)
        }
    }

    @objc private func openURL(_ event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        guard let text = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue else { return }
        send([text])
    }

    private func send(_ commands: [String]) {
        guard !commands.isEmpty else { return }
        DistributedNotificationCenter.default().postNotificationName(
            Engine.commandNotification, object: commands.joined(separator: "\n"),
            userInfo: nil, deliverImmediately: true
        )
    }
}
