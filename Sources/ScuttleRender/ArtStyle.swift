import Foundation

public enum ArtStyle: String, CaseIterable, Codable, Sendable {
    case kawaii
    case sticker
    case hose
    case mascot
    case doodle

    public var title: String {
        switch self {
        case .kawaii: return "Kawaii blob"
        case .sticker: return "Sticker"
        case .hose: return "Rubber-hose"
        case .mascot: return "Mascot"
        case .doodle: return "Doodle"
        }
    }

    public init?(name: String) {
        let key = name.lowercased().filter { $0.isLetter }
        switch key {
        case "kawaiiblob", "blob", "cute": self = .kawaii
        case "rubberhose", "rubber", "classic": self = .hose
        case "crayon", "sketch": self = .doodle
        default:
            guard let match = ArtStyle(rawValue: key) else { return nil }
            self = match
        }
    }
}
