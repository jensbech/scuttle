import AppKit

let options: Options
do {
    options = try Options.parse(Array(CommandLine.arguments.dropFirst()))
} catch {
    FileHandle.standardError.write(Data("scuttle: \(error)\n\n\(Options.usage)\n".utf8))
    exit(2)
}
if options.help {
    print(Options.usage)
    exit(0)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate: NSApplicationDelegate = InstanceLock.acquire() ? AppDelegate(options: options) : Forwarder(options: options)
app.delegate = delegate
app.run()
