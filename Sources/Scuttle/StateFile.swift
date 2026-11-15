import Foundation

final class StateFile {
    static let directory = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Scuttle", isDirectory: true)

    let url = StateFile.directory.appendingPathComponent("state.json")
    func write(_ state: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: state, options: [.prettyPrinted, .sortedKeys]) else { return }
        try? FileManager.default.createDirectory(at: StateFile.directory, withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    func remove() {
        try? FileManager.default.removeItem(at: url)
    }
}

enum InstanceLock {
    private static var descriptor: Int32 = -1

    static func acquire() -> Bool {
        try? FileManager.default.createDirectory(at: StateFile.directory, withIntermediateDirectories: true)
        let path = StateFile.directory.appendingPathComponent("lock").path
        let fd = open(path, O_CREAT | O_RDWR | O_CLOEXEC, 0o644)
        guard fd >= 0 else { return true }
        if flock(fd, LOCK_EX | LOCK_NB) == 0 {
            descriptor = fd
            return true
        }
        close(fd)
        return false
    }
}
