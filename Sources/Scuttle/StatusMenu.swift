import AppKit
import ServiceManagement
import ScuttleCore
import ScuttleRender

final class StatusMenu: NSObject, NSMenuDelegate {
    private let engine: Engine
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()
    private let status = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let enabled = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
    private let darken = NSMenuItem(title: "Darken screen", action: #selector(toggleDarken), keyEquivalent: "")
    private let notice = NSMenuItem(title: "Notice windows and pointer", action: #selector(toggleNotice), keyEquivalent: "")
    private let login = NSMenuItem(title: "Launch at login", action: #selector(toggleLogin), keyEquivalent: "")
    private let preview = NSMenuItem(title: "Preview", action: #selector(runPreview), keyEquivalent: "")
    private var presets: [NSMenuItem] = []
    private var seasons: [NSMenuItem] = []
    private let southern = NSMenuItem(title: "Southern hemisphere", action: #selector(toggleHemisphere), keyEquivalent: "")
    private var idlePresets: [NSMenuItem] = []
    private var weathers: [NSMenuItem] = []
    private var styles: [NSMenuItem] = []
    private let spotted = NSMenuItem(title: "Spotted", action: nil, keyEquivalent: "")
    private let spottedMenu = NSMenu()
    private var icon: NSImage?
    private var celebration: DispatchWorkItem?

    private var isBundled: Bool {
        Bundle.main.bundleURL.pathExtension == "app" && Bundle.main.bundleIdentifier != nil
    }

    init(engine: Engine) {
        self.engine = engine
        super.init()

        let image = Bundle.main.image(forResource: "MenuBarIcon")
            ?? NSImage(systemSymbolName: "ladybug", accessibilityDescription: "Scuttle")
        image?.size = NSSize(width: 18, height: 18)
        image?.isTemplate = true
        icon = image
        item.button?.image = image
        if image == nil { item.button?.title = "Scuttle" }
        item.button?.toolTip = "Scuttle"

        menu.delegate = self
        menu.autoenablesItems = false
        status.isEnabled = false
        add(enabled)
        menu.addItem(status)
        menu.addItem(.separator())

        let howMany = NSMenu()
        for preset in Settings.presets {
            let entry = NSMenuItem(title: preset.title, action: #selector(pickPopulation(_:)), keyEquivalent: "")
            entry.target = self
            entry.tag = preset.count
            howMany.addItem(entry)
            presets.append(entry)
        }
        addSubmenu("How many", howMany)

        let seasonMenu = NSMenu()
        for setting in SeasonSetting.all {
            let entry = NSMenuItem(title: StatusMenu.title(for: setting), action: #selector(pickSeason(_:)), keyEquivalent: "")
            entry.target = self
            entry.representedObject = setting.name
            seasonMenu.addItem(entry)
            seasons.append(entry)
            if setting == .automatic { seasonMenu.addItem(.separator()) }
        }
        seasonMenu.addItem(.separator())
        southern.target = self
        southern.toolTip = "Flips spring, summer, autumn and winter for Automatic"
        seasonMenu.addItem(southern)
        addSubmenu("Season", seasonMenu)

        let styleMenu = NSMenu()
        for style in ArtStyle.allCases {
            let entry = NSMenuItem(title: style.title, action: #selector(pickStyle(_:)), keyEquivalent: "")
            entry.target = self
            entry.representedObject = style.rawValue
            styleMenu.addItem(entry)
            styles.append(entry)
        }
        addSubmenu("Art style", styleMenu)

        let weatherMenu = NSMenu()
        for setting in WeatherSetting.all {
            let entry = NSMenuItem(title: StatusMenu.title(for: setting), action: #selector(pickWeather(_:)), keyEquivalent: "")
            entry.target = self
            entry.representedObject = setting.name
            weatherMenu.addItem(entry)
            weathers.append(entry)
            if setting == .off { weatherMenu.addItem(.separator()) }
        }
        addSubmenu("Weather", weatherMenu)

        let idleMenu = NSMenu()
        for preset in Settings.idlePresets {
            let entry = NSMenuItem(title: preset.title, action: #selector(pickIdle(_:)), keyEquivalent: "")
            entry.target = self
            entry.tag = preset.seconds
            idleMenu.addItem(entry)
            idlePresets.append(entry)
        }
        addSubmenu("When idle", idleMenu)

        spottedMenu.autoenablesItems = false
        spotted.submenu = spottedMenu
        menu.addItem(spotted)

        notice.toolTip = "Figures perch on window tops and the Dock and react to the pointer. Only window positions are read, never titles or contents."
        add(darken)
        add(notice)
        menu.addItem(.separator())
        add(preview)
        add(login)
        menu.addItem(.separator())
        add(NSMenuItem(title: "About Scuttle", action: #selector(about), keyEquivalent: ""))
        add(NSMenuItem(title: "Quit Scuttle", action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu

        engine.onChange = { [weak self] in self?.refreshStatus() }
        engine.onDiscovery = { [weak self] species in self?.celebrate(species) }
        refresh()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        refresh()
    }

    private func add(_ entry: NSMenuItem) {
        entry.target = self
        menu.addItem(entry)
    }

    private func addSubmenu(_ title: String, _ submenu: NSMenu) {
        submenu.autoenablesItems = false
        let parent = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        parent.submenu = submenu
        menu.addItem(parent)
    }

    private static func title(for setting: SeasonSetting, today: Season? = nil) -> String {
        switch setting {
        case .automatic: return today.map { "Automatic (\($0.title))" } ?? "Automatic"
        case .fixed(let season): return season.title
        }
    }

    private static func title(for setting: WeatherSetting) -> String {
        switch setting {
        case .live: return "Live"
        case .off: return "Off"
        case .fixed(let weather): return weather.title
        }
    }

    private func refreshStatus() {
        let title = engine.settings.enabled ? engine.statusText : "Off"
        if status.title != title { status.title = title }
    }

    private func refresh() {
        let settings = engine.settings
        refreshStatus()
        enabled.state = settings.enabled ? .on : .off
        darken.state = settings.darken ? .on : .off
        notice.state = settings.surroundings ? .on : .off
        for entry in presets {
            entry.state = entry.tag == settings.population ? .on : .off
        }
        let today = SeasonSetting.automatic.resolve(hemisphere: settings.hemisphere)
        for entry in seasons {
            guard let setting = (entry.representedObject as? String).flatMap(SeasonSetting.init) else { continue }
            entry.state = setting == settings.season ? .on : .off
            if setting == .automatic {
                let title = StatusMenu.title(for: setting, today: today)
                if entry.title != title { entry.title = title }
            }
        }
        southern.state = settings.hemisphere == .southern ? .on : .off
        for entry in styles {
            entry.state = entry.representedObject as? String == settings.style.rawValue ? .on : .off
        }
        for entry in idlePresets {
            entry.state = entry.tag == settings.idleSeconds ? .on : .off
        }
        for entry in weathers {
            guard let setting = (entry.representedObject as? String).flatMap(WeatherSetting.init) else { continue }
            entry.state = setting == settings.weather ? .on : .off
            if setting == .live {
                let title = engine.weatherStatusText
                if entry.title != title { entry.title = title }
            }
        }
        refreshAlbum()
        login.isEnabled = isBundled
        login.state = isBundled && SMAppService.mainApp.status == .enabled ? .on : .off
        login.toolTip = isBundled ? nil : "Available when running Scuttle.app"
    }

    private func refreshAlbum() {
        let album = engine.album
        spotted.title = "Spotted (\(album.count) of \(Species.rareVisitors.count))"
        spottedMenu.removeAllItems()
        for species in Species.rareVisitors {
            let row: NSMenuItem
            if let entry = album.entries[species] {
                let times = entry.timesSeen == 1 ? "once" : "\(entry.timesSeen) times"
                row = NSMenuItem(title: "\(species.title) · seen \(times)", action: nil, keyEquivalent: "")
                row.state = .on
                row.toolTip = "First seen \(DateFormatter.localizedString(from: entry.firstSeen, dateStyle: .medium, timeStyle: .short))"
            } else {
                row = NSMenuItem(title: "???", action: nil, keyEquivalent: "")
            }
            row.isEnabled = false
            spottedMenu.addItem(row)
        }
        spottedMenu.addItem(.separator())
        let reset = NSMenuItem(title: "Reset album…", action: #selector(resetAlbum), keyEquivalent: "")
        reset.target = self
        reset.isEnabled = album.count > 0
        spottedMenu.addItem(reset)
    }

    private func celebrate(_ species: Species) {
        celebration?.cancel()
        let sparkle = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "New visitor spotted")
        sparkle?.size = NSSize(width: 18, height: 18)
        sparkle?.isTemplate = true
        if let sparkle { item.button?.image = sparkle }
        item.button?.toolTip = "Spotted: \(species.title)!"
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.item.button?.image = self.icon
            self.item.button?.toolTip = "Scuttle"
        }
        celebration = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: work)
    }

    @objc private func toggleEnabled() {
        engine.update { $0.enabled.toggle() }
    }

    @objc private func toggleDarken() {
        engine.update { $0.darken.toggle() }
    }

    @objc private func toggleNotice() {
        engine.update { $0.surroundings.toggle() }
    }

    @objc private func pickPopulation(_ sender: NSMenuItem) {
        engine.update { $0.population = sender.tag }
    }

    @objc private func pickSeason(_ sender: NSMenuItem) {
        guard let setting = (sender.representedObject as? String).flatMap(SeasonSetting.init) else { return }
        engine.update { $0.season = setting }
    }

    @objc private func pickWeather(_ sender: NSMenuItem) {
        guard let setting = (sender.representedObject as? String).flatMap(WeatherSetting.init) else { return }
        engine.update { $0.weather = setting }
    }

    @objc private func pickStyle(_ sender: NSMenuItem) {
        guard let style = (sender.representedObject as? String).flatMap({ ArtStyle(rawValue: $0) }) else { return }
        engine.update { $0.style = style }
    }

    @objc private func pickIdle(_ sender: NSMenuItem) {
        engine.update { $0.idleSeconds = sender.tag }
    }

    @objc private func resetAlbum() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Reset the album?"
        alert.informativeText = "This forgets every rare visitor you have spotted so far."
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")
        alert.buttons.first?.hasDestructiveAction = true
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        engine.resetAlbum()
        refresh()
    }

    @objc private func toggleHemisphere() {
        engine.update { $0.hemisphere = $0.hemisphere == .northern ? .southern : .northern }
    }

    @objc private func toggleLogin() {
        guard isBundled else { return }
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("Scuttle: launch at login failed: %@", error.localizedDescription)
        }
        refresh()
    }

    @objc private func runPreview() {
        engine.update { $0.enabled = true }
        engine.play(name: "peek")
    }

    @objc private func about() {
        NSApp.activate(ignoringOtherApps: true)
        let credits = NSAttributedString(
            string: "Lower the lid and the season sneaks in.\nOpen it and everyone scatters.",
            attributes: [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.secondaryLabelColor]
        )
        NSApp.orderFrontStandardAboutPanel(options: [.applicationName: "Scuttle", .credits: credits])
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
