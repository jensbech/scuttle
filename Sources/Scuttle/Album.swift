import Foundation
import ScuttleCore

final class Album {
    struct Entry: Codable, Equatable {
        var firstSeen: Date
        var timesSeen: Int
    }

    private struct File: Codable {
        var spotted: [String: Entry]
    }

    static let defaultURL = StateFile.directory.appendingPathComponent("album.json")

    let url: URL?
    private(set) var entries: [Species: Entry] = [:]

    init(url: URL?) {
        self.url = url
        guard let url, let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let file = try? decoder.decode(File.self, from: data) else { return }
        for (name, entry) in file.spotted {
            guard let species = Species(rawValue: name), species.isRare else { continue }
            entries[species] = entry
        }
    }

    var spotted: [String] {
        entries.keys.map(\.rawValue).sorted()
    }

    var count: Int { entries.count }

    @discardableResult
    func record(_ species: Species, on date: Date = Date()) -> Bool {
        guard species.isRare else { return false }
        let isNew = entries[species] == nil
        var entry = entries[species] ?? Entry(firstSeen: date, timesSeen: 0)
        entry.timesSeen += 1
        entries[species] = entry
        save()
        return isNew
    }

    func reset() {
        entries.removeAll()
        save()
    }

    private func save() {
        guard let url else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let file = File(spotted: Dictionary(uniqueKeysWithValues: entries.map { ($0.key.rawValue, $0.value) }))
        guard let data = try? encoder.encode(file) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    static func species(named text: String) -> Species? {
        let key = text.lowercased().filter { $0.isLetter }
        return Species.rareVisitors.first { $0.rawValue == key || $0.title.lowercased().filter { $0.isLetter } == key }
    }
}
