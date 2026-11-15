import Foundation

public enum Hemisphere: String, CaseIterable, Codable, Sendable {
    case northern
    case southern

    private static let southernRegions: Set<String> = [
        "AR", "AU", "BO", "BR", "BW", "CK", "CL", "FJ", "FK", "LS", "MG", "MU", "MW", "MZ", "NA",
        "NC", "NF", "NU", "NZ", "PE", "PF", "PN", "PY", "RE", "SB", "SZ", "TO", "UY", "VU", "WS",
        "YT", "ZA", "ZM", "ZW", "AO", "TL", "GS", "TF", "IO", "SH",
    ]

    public static func guess(regionCode: String?) -> Hemisphere {
        guard let code = regionCode?.uppercased(), southernRegions.contains(code) else { return .northern }
        return .southern
    }
}

public enum Season: String, CaseIterable, Codable, Sendable {
    case spring
    case summer
    case autumn
    case winter
    case halloween
    case christmas
    case newYear = "newyear"

    public var title: String {
        switch self {
        case .spring: return "Spring"
        case .summer: return "Summer"
        case .autumn: return "Autumn"
        case .winter: return "Winter"
        case .halloween: return "Halloween"
        case .christmas: return "Christmas"
        case .newYear: return "New Year"
        }
    }

    public var isFestive: Bool {
        switch self {
        case .halloween, .christmas, .newYear: return true
        case .spring, .summer, .autumn, .winter: return false
        }
    }

    public var cast: [Species] {
        switch self {
        case .spring: return [.ladybird, .bumblebee, .snail, .chick]
        case .summer: return [.butterfly, .dragonfly, .firefly, .crab]
        case .autumn: return [.hedgehog, .acorn, .toadstool, .leaf]
        case .winter: return [.penguin, .snowman, .snowflake, .robin]
        case .halloween: return [.ghost, .bat, .pumpkin, .spider]
        case .christmas: return [.gingerbread, .present, .elf, .reindeer]
        case .newYear: return [.balloon, .star, .sparkler, .rocket]
        }
    }

    public var rareVisitor: Species {
        switch self {
        case .spring: return .bunny
        case .summer: return .turtle
        case .autumn: return .fox
        case .winter: return .polarBear
        case .halloween: return .blackCat
        case .christmas: return .santa
        case .newYear: return .comet
        }
    }

    public init?(name: String) {
        let key = name.lowercased().filter { $0.isLetter }
        switch key {
        case "fall": self = .autumn
        case "xmas": self = .christmas
        case "newyears", "nye", "hogmanay": self = .newYear
        default:
            guard let match = Season.allCases.first(where: { $0.rawValue == key }) else { return nil }
            self = match
        }
    }

    public static func festive(month: Int, day: Int) -> Season? {
        switch (month, day) {
        case (12, 31), (1, 1): return .newYear
        case (12, 1...26): return .christmas
        case (10, 24...31): return .halloween
        default: return nil
        }
    }

    public static func meteorological(month: Int, hemisphere: Hemisphere = .northern) -> Season {
        let north: Season
        switch month {
        case 3...5: north = .spring
        case 6...8: north = .summer
        case 9...11: north = .autumn
        default: north = .winter
        }
        guard hemisphere == .southern else { return north }
        switch north {
        case .spring: return .autumn
        case .summer: return .winter
        case .autumn: return .spring
        default: return .summer
        }
    }

    public static func of(month: Int, day: Int, hemisphere: Hemisphere = .northern) -> Season {
        festive(month: month, day: day) ?? meteorological(month: month, hemisphere: hemisphere)
    }

    public static func of(_ date: Date, hemisphere: Hemisphere = .northern, calendar: Calendar = .current) -> Season {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = calendar.timeZone
        let parts = gregorian.dateComponents([.month, .day], from: date)
        return of(month: parts.month ?? 1, day: parts.day ?? 1, hemisphere: hemisphere)
    }
}

public enum SeasonSetting: Hashable, Codable, Sendable {
    case automatic
    case fixed(Season)

    public static let all: [SeasonSetting] = [.automatic] + Season.allCases.map { .fixed($0) }

    public init?(_ text: String) {
        switch text.lowercased() {
        case "auto", "automatic", "on", "off", "none": self = .automatic
        default:
            guard let season = Season(name: text) else { return nil }
            self = .fixed(season)
        }
    }

    public var name: String {
        switch self {
        case .automatic: return "auto"
        case .fixed(let season): return season.rawValue
        }
    }

    public func resolve(on date: Date = Date(), hemisphere: Hemisphere = .northern, calendar: Calendar = .current) -> Season {
        switch self {
        case .automatic: return Season.of(date, hemisphere: hemisphere, calendar: calendar)
        case .fixed(let season): return season
        }
    }

    public init(from decoder: Decoder) throws {
        let text = try decoder.singleValueContainer().decode(String.self)
        guard let value = SeasonSetting(text) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "unknown season setting \(text)"))
        }
        self = value
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(name)
    }
}
