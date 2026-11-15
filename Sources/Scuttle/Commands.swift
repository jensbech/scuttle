import AppKit
import ScuttleCore
import ScuttleRender

extension Engine {
    static let commandNotification = Notification.Name("app.scuttle.Scuttle.command")

    @discardableResult
    func handle(_ text: String) -> Bool {
        guard let parts = URLComponents(string: text), parts.scheme?.lowercased() == "scuttle" else { return false }
        let verb = (parts.host ?? "").lowercased()
        let arg = parts.path.split(separator: "/").first.map(String.init)
        let query = Dictionary((parts.queryItems ?? []).map { ($0.name, $0.value ?? "") }) { a, _ in a }

        func flag(_ current: Bool) -> Bool? {
            switch arg?.lowercased() {
            case "on": return true
            case "off": return false
            case "toggle", nil: return !current
            default: return nil
            }
        }

        switch verb {
        case "on":
            update { $0.enabled = true }
        case "off":
            update { $0.enabled = false }
        case "toggle":
            update { $0.enabled.toggle() }
        case "angle":
            guard let value = arg.flatMap(Double.init) else { return false }
            hold(value)
        case "sensor":
            useSensor()
        case "play":
            if let file = query["file"] {
                return play(file: file, loop: ["1", "true", "yes"].contains(query["loop"] ?? ""))
            }
            guard let arg else { return false }
            return play(name: arg)
        case "stop":
            stopTimeline()
        case "ambush":
            ambush()
        case "sleep":
            switch arg?.lowercased() {
            case "stage": simulateSleep()
            case "wake": simulateWake()
            default: return false
            }
        case "hud":
            guard let on = flag(hud) else { return false }
            setHUD(on)
        case "population":
            guard let value = arg.flatMap({ Int($0) }), value >= 0 else { return false }
            update { $0.population = value }
        case "season":
            guard let setting = arg.flatMap(SeasonSetting.init) else { return false }
            update { $0.season = setting }
        case "hemisphere":
            switch arg?.lowercased() {
            case "northern", "north": update { $0.hemisphere = .northern }
            case "southern", "south": update { $0.hemisphere = .southern }
            case "toggle", nil: update { $0.hemisphere = $0.hemisphere == .northern ? .southern : .northern }
            default: return false
            }
        case "idle":
            switch arg?.lowercased() {
            case "now": forceIdle(sticky: false)
            case "hold": forceIdle(sticky: true)
            case "wake": wakeIdle()
            case "off":
                update { $0.idleSeconds = 0 }
                wakeIdle()
            default:
                guard let value = arg.flatMap({ Int($0) }), value >= 0 else { return false }
                update { $0.idleSeconds = value }
            }
        case "weather":
            guard let setting = arg.flatMap(WeatherSetting.init) else { return false }
            update { $0.weather = setting }
        case "style":
            guard let style = arg.flatMap({ ArtStyle(name: $0) }) else { return false }
            update { $0.style = style }
        case "night":
            switch arg?.lowercased() {
            case "auto", "automatic": setNight(nil)
            case "on": setNight(true)
            case "off": setNight(false)
            default: return false
            }
        case "rare":
            if let arg {
                guard let species = Album.species(named: arg) else { return false }
                summonRare(species)
            } else {
                summonRare(nil)
            }
        case "surroundings":
            guard let on = flag(settings.surroundings) else { return false }
            update { $0.surroundings = on }
        case "ledge":
            if arg?.lowercased() == "clear" {
                clearLedges()
                return true
            }
            guard arg == nil,
                  let x = query["x"].flatMap(Double.init), let y = query["y"].flatMap(Double.init),
                  let w = query["w"].flatMap(Double.init), w > 0, x.isFinite, y.isFinite, w.isFinite else { return false }
            let h = query["h"].flatMap(Double.init) ?? y
            guard h > 0, h.isFinite else { return false }
            addLedge(CGRect(x: x, y: y - h, width: w, height: h))
        case "pointer":
            if arg?.lowercased() == "clear" {
                setPointer(nil)
                return true
            }
            guard arg == nil,
                  let x = query["x"].flatMap(Double.init), let y = query["y"].flatMap(Double.init),
                  x.isFinite, y.isFinite else { return false }
            setPointer(CGPoint(x: x, y: y))
        case "album":
            guard arg?.lowercased() == "reset" else { return false }
            resetAlbum()
        case "quit":
            NSApp.terminate(nil)
        default:
            return false
        }
        return true
    }
}
