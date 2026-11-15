import Foundation
import ScuttleCore
import ScuttleRender

struct OptionsError: Error, CustomStringConvertible {
    let description: String
}

struct Options {
    var timeline: String?
    var loop = false
    var quitWhenDone = false
    var angle: Double?
    var hud = false
    var population: Int?
    var seed: UInt64?
    var season: SeasonSetting?
    var weather: WeatherSetting?
    var style: ArtStyle?
    var surroundings: Bool?
    var album: String?
    var statusItem = true
    var fresh = false
    var headless = false
    var help = false
    var commands: [String] = []

    static let usage = """
    Scuttle: lower the lid and the season sneaks in; open it and everyone scatters.

    Usage: Scuttle [options] [scuttle://command ...]

      --timeline <file.json>  play a lid timeline instead of the real sensor
      --loop                  force the timeline to loop
      --quit-when-done        quit when a non-looping timeline finishes
      --angle <deg>           hold a fixed lid angle
      --hud                   draw a status line (angle, source, light, count, fps)
      --population <n>        number of figures for this run
      --seed <n>              fixed random seed for this run
      --season <name>         auto, or spring, summer, autumn, winter, halloween,
                              christmas, newyear
      --weather <name>        live, off, or clear, cloudy, rain, snow, storm, fog, wind
      --style <name>          art style: kawaii, sticker, hose, mascot, doodle
      --surroundings on|off   let figures notice window tops, the Dock and the pointer
      --album <file.json>     keep the rare visitor album in this file
      --no-status-item        do not add the menu bar item
      --fresh                 ignore saved preferences and the album, save nothing,
                              and never ask for location or fetch the weather
      --headless              no overlay window, timer-driven, never pauses (for tests
                              over ssh or with the display asleep); no live weather
      --help                  show this text

    Commands (also via: open -g "scuttle://..."):
      on, off, toggle, angle/<deg>, sensor, play/<name>, play?file=<path>, stop, ambush,
      sleep/stage, sleep/wake,
      hud/on|off|toggle, population/<n>, season/<auto|name>,
      hemisphere/northern|southern|toggle, idle/now|hold|wake|off|<seconds>,
      weather/live|off|<name>, style/<name>, night/auto|on|off, rare, rare/<name>, album/reset,
      surroundings/on|off|toggle, ledge?x=<x>&y=<y>&w=<width>[&h=<height>], ledge/clear,
      pointer?x=<x>&y=<y>, pointer/clear, quit

    ledge and pointer add a pretend window top or pin the pointer, in overlay points
    with the origin at the bottom left, for testing without real windows.

    State is written to ~/Library/Application Support/Scuttle/state.json, and the
    rare visitors you have spotted are kept in album.json next to it.
    If Scuttle is already running, options and commands are handed to it.
    """

    static func parse(_ args: [String]) throws -> Options {
        var options = Options()
        var rest = args[...]
        func value(_ flag: String) throws -> String {
            guard let v = rest.popFirst() else { throw OptionsError(description: "\(flag) needs a value") }
            return v
        }
        while let arg = rest.popFirst() {
            switch arg {
            case "--timeline": options.timeline = try value(arg)
            case "--loop": options.loop = true
            case "--quit-when-done": options.quitWhenDone = true
            case "--angle":
                guard let v = Double(try value(arg)) else { throw OptionsError(description: "--angle needs a number") }
                options.angle = v
            case "--hud": options.hud = true
            case "--population":
                guard let v = Int(try value(arg)), v >= 0 else { throw OptionsError(description: "--population needs a whole number") }
                options.population = v
            case "--seed":
                guard let v = UInt64(try value(arg)) else { throw OptionsError(description: "--seed needs a whole number") }
                options.seed = v
            case "--season":
                let v = try value(arg)
                guard let setting = SeasonSetting(v) else { throw OptionsError(description: "--season needs auto or a season name") }
                options.season = setting
            case "--weather":
                let v = try value(arg)
                guard let setting = WeatherSetting(v) else { throw OptionsError(description: "--weather needs live, off or a weather name") }
                options.weather = setting
            case "--style":
                let v = try value(arg)
                guard let style = ArtStyle(name: v) else { throw OptionsError(description: "--style needs kawaii, sticker, hose, mascot or doodle") }
                options.style = style
            case "--surroundings":
                switch try value(arg).lowercased() {
                case "on", "true", "yes", "1": options.surroundings = true
                case "off", "false", "no", "0": options.surroundings = false
                default: throw OptionsError(description: "--surroundings needs on or off")
                }
            case "--album": options.album = try value(arg)
            case "--no-status-item": options.statusItem = false
            case "--fresh": options.fresh = true
            case "--headless": options.headless = true
            case "--help", "-h": options.help = true
            default:
                if arg.hasPrefix("scuttle:") {
                    options.commands.append(arg)
                } else if arg.hasPrefix("--") {
                    throw OptionsError(description: "unknown option \(arg)")
                }
            }
        }
        return options
    }

    var handoff: [String] {
        var out: [String] = []
        if let population { out.append("scuttle://population/\(population)") }
        if let season { out.append("scuttle://season/\(season.name)") }
        if let weather { out.append("scuttle://weather/\(weather.name)") }
        if let style { out.append("scuttle://style/\(style.rawValue)") }
        if let surroundings { out.append("scuttle://surroundings/\(surroundings ? "on" : "off")") }
        if hud { out.append("scuttle://hud/on") }
        if let angle { out.append("scuttle://angle/\(angle)") }
        if let timeline {
            var parts = URLComponents()
            parts.scheme = "scuttle"
            parts.host = "play"
            let path = URL(fileURLWithPath: timeline).standardizedFileURL.path
            parts.queryItems = [URLQueryItem(name: "file", value: path)] + (loop ? [URLQueryItem(name: "loop", value: "1")] : [])
            if let s = parts.string { out.append(s) }
        }
        return out + commands
    }
}
