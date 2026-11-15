import Foundation
import ScuttleCore
import ScuttleRender

enum WeatherSetting: Hashable {
    case live
    case off
    case fixed(Weather)

    static let all: [WeatherSetting] = [.live, .off] + Weather.allCases.map { .fixed($0) }

    init?(_ text: String) {
        switch text.lowercased() {
        case "live", "auto", "automatic", "on": self = .live
        case "off", "none": self = .off
        default:
            guard let weather = Weather(name: text) else { return nil }
            self = .fixed(weather)
        }
    }

    var name: String {
        switch self {
        case .live: return "live"
        case .off: return "off"
        case .fixed(let weather): return weather.rawValue
        }
    }
}

struct Settings: Equatable {
    var enabled = true
    var population = 15
    var darken = true
    var season = SeasonSetting.automatic
    var hemisphere = Settings.regionHemisphere
    var idleSeconds = 180
    var weather = WeatherSetting.live
    var style = ArtStyle.kawaii
    var surroundings = true

    static let presets: [(title: String, count: Int)] = [
        ("A few", 8), ("Some", 15), ("Lots", 24), ("A whole parade", 40),
    ]
    static let idlePresets: [(title: String, seconds: Int)] = [
        ("Off", 0), ("After 1 minute", 60), ("After 3 minutes", 180), ("After 10 minutes", 600),
    ]
    static let maxPopulation = 400
    static let migratedPopulation = 24
    static let populationMarker = "populationRescaled"
    static let maxIdleSeconds = 24 * 60 * 60

    static var regionHemisphere: Hemisphere {
        Hemisphere.guess(regionCode: Locale.current.region?.identifier)
    }

    func resolvedSeason(on date: Date = Date()) -> Season {
        season.resolve(on: date, hemisphere: hemisphere)
    }
}

struct SettingsStore {
    let defaults: UserDefaults?

    func migrate() {
        guard let d = defaults, !d.bool(forKey: Settings.populationMarker) else { return }
        if d.object(forKey: "population") != nil, d.integer(forKey: "population") > Settings.migratedPopulation {
            d.set(Settings.migratedPopulation, forKey: "population")
        }
        d.removeObject(forKey: "sound")
        d.set(true, forKey: Settings.populationMarker)
    }

    func load() -> Settings {
        var s = Settings()
        guard let d = defaults else { return s }
        migrate()
        if d.object(forKey: "enabled") != nil { s.enabled = d.bool(forKey: "enabled") }
        if d.object(forKey: "population") != nil {
            s.population = max(0, min(Settings.maxPopulation, d.integer(forKey: "population")))
        }
        if d.object(forKey: "darken") != nil { s.darken = d.bool(forKey: "darken") }
        if let name = d.string(forKey: "season"), let setting = SeasonSetting(name) { s.season = setting }
        if let name = d.string(forKey: "hemisphere"), let value = Hemisphere(rawValue: name) { s.hemisphere = value }
        if d.object(forKey: "idleSeconds") != nil {
            s.idleSeconds = max(0, min(Settings.maxIdleSeconds, d.integer(forKey: "idleSeconds")))
        }
        if let name = d.string(forKey: "weather"), let setting = WeatherSetting(name) { s.weather = setting }
        if let name = d.string(forKey: "style"), let value = ArtStyle(name: name) { s.style = value }
        if d.object(forKey: "surroundings") != nil { s.surroundings = d.bool(forKey: "surroundings") }
        return s
    }

    func save(_ s: Settings) {
        guard let d = defaults else { return }
        d.set(s.enabled, forKey: "enabled")
        d.set(s.population, forKey: "population")
        d.set(s.darken, forKey: "darken")
        d.set(s.season.name, forKey: "season")
        if s.hemisphere != Settings.regionHemisphere || d.string(forKey: "hemisphere") != nil {
            d.set(s.hemisphere.rawValue, forKey: "hemisphere")
        }
        d.set(s.idleSeconds, forKey: "idleSeconds")
        d.set(s.weather.name, forKey: "weather")
        d.set(s.style.rawValue, forKey: "style")
        d.set(s.surroundings, forKey: "surroundings")
    }
}
