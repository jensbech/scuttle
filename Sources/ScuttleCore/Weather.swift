import Foundation

public enum Weather: String, CaseIterable, Codable, Sendable {
    case clear
    case cloudy
    case rain
    case snow
    case storm
    case fog
    case wind

    public var title: String {
        switch self {
        case .clear: return "Clear"
        case .cloudy: return "Cloudy"
        case .rain: return "Rain"
        case .snow: return "Snow"
        case .storm: return "Thunderstorm"
        case .fog: return "Fog"
        case .wind: return "Windy"
        }
    }

    public init?(name: String) {
        let key = name.lowercased().filter { $0.isLetter }
        switch key {
        case "sunny", "sun": self = .clear
        case "clouds", "overcast": self = .cloudy
        case "rainy", "drizzle", "showers": self = .rain
        case "snowy": self = .snow
        case "thunder", "thunderstorm", "lightning": self = .storm
        case "foggy", "mist": self = .fog
        case "windy": self = .wind
        default:
            guard let match = Weather(rawValue: key) else { return nil }
            self = match
        }
    }

    public func guests(night: Bool) -> [Species] {
        var list: [Species]
        switch self {
        case .clear: list = night ? [] : [.sun]
        case .cloudy, .fog: list = [.cloud]
        case .rain: list = [.frog, .cloud]
        case .snow: list = [.snowflake]
        case .storm: list = [.cloud, .frog]
        case .wind: list = [.leaf]
        }
        if night { list.append(.owl) }
        return list
    }
}
