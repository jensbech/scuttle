import AppKit
import QuartzCore
import os
import ScuttleCore
import ScuttleRender

final class Engine {
    enum Pace: String {
        case stopped
        case idle
        case alert
        case active
        case staged
    }

    static let openAngle = 120.0
    static let alertAngle = 100.0
    static let idleInterval = 1.0 / 8
    static let alertInterval = 1.0 / 30
    static let maxStep = 1.0 / 30
    static let lingerSeconds = 1.0
    static let closedAngle = 12.0
    static let reopenAngle = 20.0
    static let stageSeconds = 20.0
    static let lidDarkness = 0.8
    static let idleDarkness = 0.45
    static let shadeRate = 0.6
    static let weatherCheckInterval = 30.0

    let options: Options
    let input = LidInput()
    let album: Album
    var onChange: (() -> Void)?
    var onDiscovery: ((Species) -> Void)?

    private let store: SettingsStore
    private let overlay: Overlay
    private let renderer = SceneRenderer()
    private let stateFile = StateFile()
    private let idle = IdleTrigger()
    private let feed = SurroundingsFeed()
    private let live: LiveWeather?
    private let seed: UInt64
    private var world: World
    private var pauses: Set<String> = []
    private var timer: Timer?
    private var lastTick = CACurrentMediaTime()
    private var clock = 0.0
    private var quietSince: Double?
    private var frames = 0
    private var fpsMark = CACurrentMediaTime()
    private var fps = 0.0
    private var lastSnapshot: Snapshot?
    private var lastWrite = 0.0
    private var sleep = SleepStage()
    private var lidShut = false
    private var wakeCatches = 0
    private var armed = false
    private let log = Logger(subsystem: "app.scuttle.Scuttle", category: "sleep")
    private var lidOffScreen = false
    private var shade = 1.0
    private var lastWeatherCheck = -Double.infinity

    private(set) var pace = Pace.stopped
    private(set) var angle: Double?
    private(set) var effectiveAngle: Double?
    private(set) var hud: Bool
    private(set) var settings: Settings
    private(set) var season: Season
    private(set) var weather: Weather?
    private(set) var night = false
    private(set) var nightOverride: Bool?

    init(options: Options) {
        self.options = options
        overlay = Overlay(headless: options.headless)
        store = SettingsStore(defaults: options.fresh ? nil : .standard)
        var loaded = store.load()
        if let population = options.population { loaded.population = min(population, Settings.maxPopulation) }
        if let setting = options.season { loaded.season = setting }
        if let setting = options.weather { loaded.weather = setting }
        if let style = options.style { loaded.style = style }
        if let surroundings = options.surroundings { loaded.surroundings = surroundings }
        settings = loaded
        season = loaded.resolvedSeason()
        hud = options.hud
        seed = options.seed ?? UInt64.random(in: 1...UInt64.max)
        if let path = options.album {
            album = Album(url: URL(fileURLWithPath: (path as NSString).expandingTildeInPath))
        } else {
            album = Album(url: options.fresh ? nil : Album.defaultURL)
        }
        live = options.fresh || options.headless ? nil : LiveWeather(defaults: .standard)
        world = World(size: Engine.worldSize(overlay.size), config: WorldConfig(population: loaded.population, season: season, seed: seed))
        overlay.onFrame = { [weak self] in self?.tick() }
        overlay.view.onDraw = { [weak self] ctx, size in self?.draw(in: ctx, size: size) }
        input.sensor.onAvailabilityChange = { [weak self] in
            self?.layout()
            self?.publish(force: true)
        }
        live?.onChange = { [weak self] in
            self?.refreshWeather()
            self?.onChange?()
        }
    }

    var sensorAvailable: Bool { input.sensor.isAvailable }
    var isPaused: Bool { !pauses.isEmpty }
    var isIdle: Bool { idle.isActive }
    var visibleCritters: Int {
        let size = world.size
        return world.critters.reduce(0) { count, c in
            guard c.mode != .hidden, c.alpha > 0.01 else { return count }
            let m = CGFloat(c.size)
            let seen = c.position.x > -m && c.position.x < size.width + m && c.position.y > -m && c.position.y < size.height + m
            return seen ? count + 1 : count
        }
    }

    var statusText: String {
        let text = sourceText
        return idle.isActive ? "\(text) · you're away" : text
    }

    private var sourceText: String {
        let degrees = angle.map { String(format: "%.0f°", $0) } ?? "?"
        let missing = sensorAvailable ? "" : "No lid sensor on this Mac · "
        switch input.kind {
        case .sensor:
            if !sensorAvailable { return "No lid sensor on this Mac" }
            if pauses.contains("display") { return "Lid \(degrees) · built-in display is off" }
            if lidOffScreen { return "Built-in display is off" }
            return "Lid \(degrees)"
        case .timeline:
            return "\(missing)Playing \(input.timeline?.name ?? "timeline") · \(degrees)"
        case .manual:
            return "\(missing)Held at \(degrees)"
        }
    }

    var weatherStatusText: String {
        guard settings.weather == .live else { return "Live" }
        guard let live else { return "Live · unavailable" }
        if live.status == .denied { return "Live · location not allowed" }
        if let reading = live.reading { return "Live · \(reading.weather.title)" }
        return live.status == .waiting ? "Live" : "Live · unavailable"
    }

    func start() {
        if let path = options.timeline {
            if !play(file: path, loop: options.loop) {
                FileHandle.standardError.write(Data("scuttle: cannot read timeline \(path)\n".utf8))
                if options.quitWhenDone { exit(1) }
            }
        } else if let angle = options.angle {
            input.hold(angle)
        }
        layout()
        syncPower()
        armed = true
        refresh()
        refreshSeason()
        syncWeather()
        publish(force: true)
    }

    func refreshSeason() {
        let next = settings.resolvedSeason()
        guard next != season else { return }
        season = next
        world.config.season = next
        overlay.redraw()
        publish(force: true)
    }

    func syncPower() {
        setPaused(Overlay.isDisplayAsleep, reason: "screens")
        setPaused(Overlay.isSessionLocked, reason: "lock")
    }

    func shutdown() {
        setPace(.stopped)
        live?.stop()
        stateFile.remove()
    }

    func update(_ change: (inout Settings) -> Void) {
        var next = settings
        change(&next)
        next.population = max(0, min(Settings.maxPopulation, next.population))
        next.idleSeconds = max(0, min(Settings.maxIdleSeconds, next.idleSeconds))
        guard next != settings else { return }
        let previous = settings
        settings = next
        store.save(next)
        if next.enabled != previous.enabled {
            world = makeWorld()
        } else {
            world.config.population = next.population
        }
        if next.enabled != previous.enabled || next.surroundings != previous.surroundings {
            refreshSurroundings()
        }
        season = next.resolvedSeason()
        world.config.season = season
        if next.idleSeconds != previous.idleSeconds {
            idle.reset()
            layout()
        }
        if next.weather != previous.weather {
            syncWeather()
        }
        apply(sleep.update(stageContext), at: CACurrentMediaTime())
        refresh()
        overlay.redraw()
        publish(force: true)
    }

    func setHUD(_ on: Bool) {
        hud = on
        sourceChanged()
    }

    func useSensor() {
        input.useSensor()
        sourceChanged()
    }

    func hold(_ angle: Double) {
        input.hold(angle)
        sourceChanged()
    }

    @discardableResult
    func play(name: String) -> Bool {
        guard let timeline = Timelines.named(name) else { return false }
        input.play(timeline, name: name)
        sourceChanged()
        return true
    }

    @discardableResult
    func play(file path: String, loop: Bool = false) -> Bool {
        let url = URL(fileURLWithPath: path)
        guard var timeline = try? LidTimeline.load(from: url), !timeline.keyframes.isEmpty else { return false }
        if loop { timeline.loop = true }
        input.play(timeline, name: url.deletingPathExtension().lastPathComponent)
        sourceChanged()
        return true
    }

    func stopTimeline() {
        guard input.kind == .timeline else { return }
        useSensor()
    }

    func forceIdle(sticky: Bool) {
        idle.force(sticky: sticky, now: CACurrentMediaTime())
        sourceChanged()
    }

    func wakeIdle() {
        idle.wake()
        sourceChanged()
    }

    func setNight(_ value: Bool?) {
        nightOverride = value
        refreshWeather()
        publish(force: true)
    }

    func summonRare(_ species: Species?) {
        world.summonRare(species)
        if pace == .idle { setPace(.alert) }
        publish(force: true)
    }

    func addLedge(_ rect: CGRect) {
        feed.addLedge(rect)
        refreshSurroundings()
        publish(force: true)
    }

    func clearLedges() {
        feed.clearLedges()
        refreshSurroundings()
        publish(force: true)
    }

    func setPointer(_ point: CGPoint?) {
        feed.pointerOverride = point
        refreshSurroundings()
        publish(force: true)
    }

    private func refreshSurroundings() {
        if !settings.surroundings {
            feed.forget()
            world.surroundings = Surroundings()
        } else if pace == .active {
            world.surroundings = Engine.toWorld(feed.sense(now: CACurrentMediaTime(), screen: overlay.screen))
        } else {
            world.surroundings = Engine.toWorld(feed.quiet())
        }
    }

    func resetAlbum() {
        album.reset()
        publish(force: true)
    }

    func syncWeather() {
        if settings.weather == .live {
            live?.start()
        } else {
            live?.stop()
        }
        refreshWeather()
    }

    func refreshWeather(now: Date = Date()) {
        let reading = settings.weather == .live ? live?.reading : nil
        let nextWeather: Weather?
        switch settings.weather {
        case .off: nextWeather = nil
        case .fixed(let kind): nextWeather = kind
        case .live: nextWeather = reading?.weather
        }
        let nextNight = nightOverride ?? reading.map { !$0.isDay } ?? Engine.isNightByClock(now)
        guard nextWeather != weather || nextNight != night else { return }
        weather = nextWeather
        night = nextNight
        world.config.weather = nextWeather
        world.config.night = nextNight
        overlay.redraw()
        publish(force: true)
    }

    func woke() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self, self.settings.weather == .live else { return }
            self.live?.refreshIfDue()
            self.refreshWeather()
        }
    }

    static func isNightByClock(_ date: Date, calendar: Calendar = .current) -> Bool {
        let hour = calendar.component(.hour, from: date)
        return hour < 7 || hour >= 19
    }

    func setPaused(_ paused: Bool, reason: String) {
        guard !options.headless else { return }
        let changed = paused ? pauses.insert(reason).inserted : pauses.remove(reason) != nil
        guard changed else { return }
        if let signal = Engine.signal(for: reason, paused: paused) {
            feed(signal)
        } else {
            apply(sleep.update(stageContext), at: CACurrentMediaTime())
        }
        refresh()
        publish(force: true)
    }

    static func signal(for reason: String, paused: Bool) -> SleepStage.Signal? {
        switch reason {
        case "screens": return paused ? .displaySleep : .displayWake
        case "sleep": return paused ? .systemSleep : .systemWake
        case "session": return paused ? .sessionResigned : .sessionActive
        case "lock": return paused ? .locked : .unlocked
        default: return nil
        }
    }

    var sleepPhase: SleepStage.Phase { sleep.phase }

    func ambush() {
        guard settings.enabled else { return }
        world.settleInDark()
        if pace == .idle { setPace(.alert) }
    }

    func simulateSleep() {
        feed(.displaySleep)
    }

    func simulateWake() {
        feed(.displayWake)
    }

    private var stageContext: SleepStage.Context {
        SleepStage.Context(enabled: settings.enabled && armed, stageable: overlay.hasScreen && !lidOffScreen)
    }

    func feed(_ signal: SleepStage.Signal) {
        let now = CACurrentMediaTime()
        let before = sleep.phase
        let actions = sleep.handle(signal, at: now, context: stageContext)
        log.debug("signal \(signal.rawValue, privacy: .public) at \(now, format: .fixed(precision: 3)) phase \(before.rawValue, privacy: .public) -> \(self.sleep.phase.rawValue, privacy: .public)")
        apply(actions, at: now)
        refresh()
        publish(force: true)
    }

    private func apply(_ actions: [SleepStage.Action], at now: Double) {
        for action in actions {
            switch action {
            case .stage:
                world.settleInDark(seconds: Engine.stageSeconds)
                shade = 1
                log.debug("staged \(self.visibleCritters) figures in \(CACurrentMediaTime() - now, format: .fixed(precision: 3))s")
            case .conceal:
                overlay.hide()
            case .reveal:
                lastTick = now
                log.debug("revealed at \(now, format: .fixed(precision: 3))")
            case .startCatch(let from):
                world.catchNow(since: now - from)
                wakeCatches += 1
                lastTick = now
                log.debug("wake catch at \(now, format: .fixed(precision: 3)), \(now - from, format: .fixed(precision: 3))s after wake grace")
            case .cancel:
                log.debug("staging cancelled")
            }
        }
    }

    func layout() {
        var screen = Overlay.builtInScreen
        var offScreen = false
        if screen == nil {
            if input.kind != .sensor || !sensorAvailable {
                screen = NSScreen.main ?? NSScreen.screens.first
            } else if settings.idleSeconds > 0 || idle.isForced {
                screen = NSScreen.main ?? NSScreen.screens.first
                offScreen = screen != nil
            }
        }
        lidOffScreen = offScreen
        overlay.place(on: screen)
        apply(sleep.update(stageContext), at: CACurrentMediaTime())
        if overlay.hasScreen, world.size != Engine.worldSize(overlay.size) {
            world.resize(Engine.worldSize(overlay.size))
        }
        setPaused(!overlay.hasScreen, reason: "display")
    }

    private func sourceChanged() {
        layout()
        if pace == .idle {
            setPace(.alert)
        }
        publish(force: true)
    }

    private func makeWorld() -> World {
        World(size: Engine.worldSize(overlay.size), config: WorldConfig(population: settings.population, season: season, seed: seed, weather: weather, night: night))
    }

    private func refresh() {
        if settings.enabled, sleep.isStaged {
            setPace(sleep.phase == .waking && pauses.isEmpty ? .active : .staged)
            if pace == .staged { showStaged() }
            return
        }
        if !settings.enabled || !pauses.isEmpty {
            setPace(.stopped)
        } else if pace == .stopped || pace == .staged {
            setPace(.alert)
        }
    }

    private func showStaged() {
        if sleep.locked || sleep.sessionInactive || !overlay.hasScreen {
            overlay.hide()
        } else {
            overlay.show()
            overlay.drawNow()
        }
    }

    private func setPace(_ next: Pace) {
        guard next != pace else { return }
        let previous = pace
        pace = next
        timer?.invalidate()
        timer = nil
        if previous == .active {
            refreshSurroundings()
        }
        if previous == .stopped || previous == .staged {
            lastTick = CACurrentMediaTime()
            quietSince = nil
        }
        switch next {
        case .stopped:
            overlay.hide()
        case .staged:
            overlay.stopFrames()
            schedule(every: Engine.idleInterval, tolerance: 0.04)
        case .idle:
            overlay.hide()
            schedule(every: Engine.idleInterval, tolerance: 0.04)
        case .alert:
            overlay.hide()
            schedule(every: Engine.alertInterval, tolerance: 0.004)
        case .active:
            fpsMark = CACurrentMediaTime()
            frames = 0
            overlay.show()
            overlay.startFrames()
            schedule(every: 0.5, tolerance: 0.1)
        }
    }

    private func schedule(every interval: Double, tolerance: Double) {
        let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.pace == .active, CACurrentMediaTime() - self.lastTick < 0.4 { return }
            self.tick()
        }
        t.tolerance = tolerance
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func lightAt(_ angle: Double) -> Double {
        let t = world.tuning
        let span = max(1e-6, t.litAngle - t.darkAngle)
        return max(0, min(1, (angle - t.darkAngle) / span))
    }

    private func updateShade(real: Double, effective: Double, dt: Double) {
        let lidDark = 1 - lightAt(real)
        let shown = 1 - world.light
        let target: Double
        if idle.isActive {
            let total = 1 - lightAt(effective)
            target = total > 0.001 ? min(1, lidDark / total) : (lidDark > 0.001 ? 1 : 0)
        } else if shown < 0.001 || lidDark >= shown - 0.01 {
            target = 1
        } else {
            target = shade
        }
        if shown < 0.02 {
            shade = target
        } else {
            let limit = Engine.shadeRate * dt
            shade += max(-limit, min(limit, target - shade))
        }
    }

    private func stagedTick() {
        let now = CACurrentMediaTime()
        input.active.advance(by: min(max(0, now - lastTick), 0.25))
        lastTick = now
        angle = input.active.angle
        if lidReopened {
            lidShut = false
            feed(.lidOpened)
            return
        }
        publish()
    }

    private var lidReopened: Bool {
        guard lidShut else { return false }
        guard input.kind == .sensor, sensorAvailable, !lidOffScreen else { return true }
        return (angle ?? Engine.openAngle) > Engine.reopenAngle
    }

    private func tick() {
        guard pace != .stopped else { return }
        if pace == .staged {
            stagedTick()
            return
        }
        let now = CACurrentMediaTime()
        let elapsed = max(0, now - lastTick)
        lastTick = now
        let dt = min(elapsed, Engine.maxStep)

        input.active.advance(by: min(elapsed, 0.25))
        if let timeline = input.timeline, timeline.isFinished {
            if options.quitWhenDone {
                NSApp.terminate(nil)
                return
            }
            input.useSensor()
            layout()
            guard pace != .stopped else { return }
        }
        angle = input.active.angle
        let real = lidOffScreen ? nil : angle
        if lidReopened {
            lidShut = false
            feed(.lidOpened)
            guard pace != .stopped, pace != .staged else { return }
        } else if input.kind == .sensor, sensorAvailable, let real, real < Engine.closedAngle, !lidShut {
            lidShut = true
            feed(.lidClosed)
            guard pace != .stopped, pace != .staged else { return }
        }
        if sleep.phase == .waking {
            apply(sleep.tick(at: now), at: now)
            if sleep.phase == .waking {
                publish()
                return
            }
            refresh()
        }

        if idle.update(now: now, threshold: settings.idleSeconds, allowed: input.kind == .sensor) {
            layout()
            publish(force: true)
            guard pace != .stopped else { return }
        }
        let effective = min(real ?? Engine.openAngle, idle.angle(at: now) ?? .infinity)
        effectiveAngle = effective

        if now - lastWeatherCheck >= Engine.weatherCheckInterval {
            lastWeatherCheck = now
            if settings.weather == .live { live?.refreshIfDue() }
            refreshWeather()
        }

        if pace == .active, settings.surroundings {
            world.surroundings = Engine.toWorld(feed.sense(now: now, screen: overlay.screen))
        }
        world.step(dt: dt, lidAngle: effective)
        updateShade(real: real ?? Engine.openAngle, effective: effective, dt: dt)
        clock += dt
        for event in world.drainEvents() {
            switch event {
            case .rareVisitor(let species):
                let isNew = album.record(species)
                publish(force: true)
                if isNew { onDiscovery?(species) }
            default:
                break
            }
        }

        if pace == .active {
            frames += 1
            if now - fpsMark >= 0.5 {
                fps = Double(frames) / (now - fpsMark)
                frames = 0
                fpsMark = now
            }
            overlay.redraw()
        }

        let busy = !world.isQuiet || hud
        if busy {
            quietSince = nil
        } else if quietSince == nil {
            quietSince = now
        }
        let lingering = pace == .active && now - (quietSince ?? now) < Engine.lingerSeconds
        if (busy || lingering) && overlay.hasScreen {
            setPace(.active)
        } else if busy || input.kind == .timeline || idle.isActive || effective < Engine.alertAngle {
            setPace(.alert)
        } else {
            setPace(.idle)
        }
        publish()
    }

    private func draw(in ctx: CGContext, size: CGSize) {
        guard pace == .active || pace == .staged else { return }
        let scene = Scene(size: size, light: world.light, critters: world.critters, time: clock, props: world.props, scale: Engine.figureScale)
        let lid = angle.map { String(format: "%.0f°", $0) } ?? "?"
        let shown = idle.isActive ? "\(lid) idle \(effectiveAngle.map { String(format: "%.0f°", $0) } ?? "?")" : lid
        let text = hud ? String(
            format: "lid %@  %@  light %.2f  critters %d/%d  %@%@%.0f fps",
            shown, input.kind.rawValue, world.light, visibleCritters, settings.population,
            weather.map { "\($0.rawValue)  " } ?? "", night ? "night  " : "", fps
        ) : nil
        let maxDarkness = Engine.idleDarkness + (Engine.lidDarkness - Engine.idleDarkness) * shade
        let options = RenderOptions(
            darkness: settings.darken, hud: text, maxDarkness: maxDarkness,
            season: season, weather: weather, night: night, style: settings.style,
            matchSpace: false
        )
        renderer.draw(scene, options: options, in: ctx)
    }

    static var figureScale: Double { Tuning.figureScale }

    static func worldSize(_ screen: CGSize) -> CGSize {
        let k = CGFloat(figureScale)
        return CGSize(width: screen.width / k, height: screen.height / k)
    }

    static func toWorld(_ s: Surroundings) -> Surroundings {
        let k = CGFloat(figureScale)
        return Surroundings(
            pointer: s.pointer.map { CGPoint(x: $0.x / k, y: $0.y / k) },
            pointerSpeed: s.pointerSpeed,
            ledges: s.ledges.map { CGRect(x: $0.minX / k, y: $0.minY / k, width: $0.width / k, height: $0.height / k) }
        )
    }

    private struct Snapshot: Equatable {
        var enabled: Bool
        var source: SourceKind
        var sensorAvailable: Bool
        var angle: Int?
        var light: Int
        var visible: Int
        var population: Int
        var hud: Bool
        var darken: Bool
        var season: Season
        var seasonSetting: SeasonSetting
        var hemisphere: Hemisphere
        var paused: Bool
        var displayOff: Bool
        var pace: Pace
        var timeline: String?
        var timelineTime: Int?
        var weather: Weather?
        var weatherSetting: WeatherSetting
        var style: ArtStyle
        var night: Bool
        var idle: Bool
        var idleSetting: Int
        var spotted: [String]
        var surroundings: Bool
        var ledges: Int
        var pointer: Bool
        var scans: Int
        var sleep: String
        var catching: Bool
        var wakeCatches: Int
        var shown: Bool
    }

    private static func decimal(_ value: Int, places: Int16) -> NSNumber {
        NSDecimalNumber(mantissa: UInt64(abs(value)), exponent: -places, isNegative: value < 0)
    }

    func publish(force: Bool = false) {
        let now = CACurrentMediaTime()
        let visible = settings.enabled ? visibleCritters : 0
        let interval = force ? 0 : (visible != lastSnapshot?.visible ? 0.05 : 0.25)
        guard now - lastWrite >= interval else { return }
        let timeline = input.timeline
        let snapshot = Snapshot(
            enabled: settings.enabled,
            source: input.kind,
            sensorAvailable: sensorAvailable,
            angle: angle.map { Int(($0 * 10).rounded()) },
            light: Int((world.light * 1000).rounded()),
            visible: visible,
            population: settings.population,
            hud: hud,
            darken: settings.darken,
            season: season,
            seasonSetting: settings.season,
            hemisphere: settings.hemisphere,
            paused: isPaused,
            displayOff: pauses.contains("display"),
            pace: pace,
            timeline: timeline?.name,
            timelineTime: timeline.map { Int(($0.time * 100).rounded()) },
            weather: weather,
            weatherSetting: settings.weather,
            style: settings.style,
            night: night,
            idle: idle.isActive,
            idleSetting: settings.idleSeconds,
            spotted: album.spotted,
            surroundings: settings.surroundings,
            ledges: world.surroundings.ledges.count,
            pointer: world.surroundings.pointer != nil,
            scans: feed.scans,
            sleep: sleep.phase.rawValue,
            catching: world.catchActive,
            wakeCatches: wakeCatches,
            shown: overlay.isShown
        )
        guard force || snapshot != lastSnapshot else { return }
        lastSnapshot = snapshot
        lastWrite = now
        var state: [String: Any] = [
            "pid": Int(ProcessInfo.processInfo.processIdentifier),
            "enabled": snapshot.enabled,
            "source": snapshot.source.rawValue,
            "sensorAvailable": snapshot.sensorAvailable,
            "angle": snapshot.angle.map { Engine.decimal($0, places: 1) } ?? NSNull(),
            "light": Engine.decimal(snapshot.light, places: 3),
            "visibleCritters": snapshot.visible,
            "population": snapshot.population,
            "hud": snapshot.hud,
            "darken": snapshot.darken,
            "season": snapshot.season.rawValue,
            "seasonSetting": snapshot.seasonSetting.name,
            "hemisphere": snapshot.hemisphere.rawValue,
            "paused": snapshot.paused,
            "pace": snapshot.pace.rawValue,
            "weather": snapshot.weather?.rawValue ?? NSNull(),
            "weatherSetting": snapshot.weatherSetting.name,
            "style": snapshot.style.rawValue,
            "night": snapshot.night,
            "idle": snapshot.idle,
            "idleSetting": snapshot.idleSetting,
            "spotted": snapshot.spotted,
            "surroundings": snapshot.surroundings,
            "ledges": snapshot.ledges,
            "pointer": snapshot.pointer,
            "ledgeScans": snapshot.scans,
            "sleep": snapshot.sleep,
            "catching": snapshot.catching,
            "wakeCatches": snapshot.wakeCatches,
            "overlayShown": snapshot.shown,
        ]
        if let name = snapshot.timeline, let time = snapshot.timelineTime {
            state["timeline"] = name
            state["timelineTime"] = Engine.decimal(time, places: 2)
        }
        stateFile.write(state)
        onChange?()
    }
}
