import CoreLocation
import Foundation
import ScuttleCore

final class LiveWeather: NSObject, CLLocationManagerDelegate {
    enum Status: Equatable {
        case waiting
        case ok
        case denied
        case unavailable
    }

    struct Reading: Equatable {
        var weather: Weather
        var isDay: Bool
        var time: Date
    }

    static let refreshInterval = 30.0 * 60
    static let retryInterval = 10.0 * 60
    static let maxAge = 3.0 * 60 * 60
    static let endpoint = "https://api.open-meteo.com/v1/forecast"
    static let windyKmh = 36.0

    var onChange: (() -> Void)?
    private(set) var status = Status.waiting
    private var stored: Reading?
    private let defaults: UserDefaults
    private var manager: CLLocationManager?
    private var running = false
    private var busy = false
    private var lastAttempt: Date?
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.httpCookieStorage = nil
        config.httpShouldSetCookies = false
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    init(defaults: UserDefaults) {
        self.defaults = defaults
        super.init()
        if let raw = defaults.string(forKey: "weatherReading"), let weather = Weather(rawValue: raw),
           defaults.object(forKey: "weatherTime") != nil {
            stored = Reading(
                weather: weather,
                isDay: defaults.object(forKey: "weatherIsDay") == nil ? true : defaults.bool(forKey: "weatherIsDay"),
                time: Date(timeIntervalSince1970: defaults.double(forKey: "weatherTime"))
            )
        }
    }

    static var canAsk: Bool {
        Bundle.main.object(forInfoDictionaryKey: "NSLocationUsageDescription") != nil
            || Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil
    }

    var reading: Reading? {
        guard let stored, abs(Date().timeIntervalSince(stored.time)) < LiveWeather.maxAge else { return nil }
        return stored
    }

    func start() {
        guard !running else { return }
        running = true
        guard LiveWeather.canAsk else {
            set(.unavailable)
            return
        }
        let manager = self.manager ?? CLLocationManager()
        self.manager = manager
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyReduced
        authorizationChanged()
    }

    func stop() {
        guard running else { return }
        running = false
        busy = false
        manager?.stopUpdatingLocation()
    }

    func refreshIfDue() {
        guard running, !busy, let manager, isAllowed(manager.authorizationStatus) else { return }
        let now = Date()
        if let r = reading, now.timeIntervalSince(r.time) < LiveWeather.refreshInterval { return }
        if let last = lastAttempt, now.timeIntervalSince(last) < LiveWeather.retryInterval { return }
        busy = true
        lastAttempt = now
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationChanged()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard running, busy else { return }
        guard let location = locations.last else {
            failed()
            return
        }
        fetch(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard busy else { return }
        if (error as? CLError)?.code == .denied {
            busy = false
            forget()
            set(.denied)
            return
        }
        failed()
    }

    private func isAllowed(_ status: CLAuthorizationStatus) -> Bool {
        switch status {
        case .notDetermined, .denied, .restricted: return false
        default: return true
        }
    }

    private func authorizationChanged() {
        guard running, let manager else { return }
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            busy = false
            forget()
            set(.denied)
        default:
            if status == .denied { set(reading == nil ? .waiting : .ok) }
            refreshIfDue()
        }
    }

    static func url(latitude: Double, longitude: Double) -> URL? {
        var parts = URLComponents(string: endpoint)
        parts?.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.1f", latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.1f", longitude)),
            URLQueryItem(name: "current", value: "weather_code,wind_speed_10m,is_day"),
        ]
        return parts?.url
    }

    static func weather(code: Int, windKmh: Double?) -> Weather? {
        let kind: Weather
        switch code {
        case 0, 1: kind = .clear
        case 2, 3: kind = .cloudy
        case 45, 48: kind = .fog
        case 51...67, 80...82: kind = .rain
        case 71...77, 85, 86: kind = .snow
        case 95...99: kind = .storm
        default: return nil
        }
        if kind == .clear || kind == .cloudy, let windKmh, windKmh > windyKmh { return .wind }
        return kind
    }

    private struct Response: Decodable {
        struct Current: Decodable {
            let weatherCode: Int
            let windSpeed: Double?
            let isDay: Int?

            enum CodingKeys: String, CodingKey {
                case weatherCode = "weather_code"
                case windSpeed = "wind_speed_10m"
                case isDay = "is_day"
            }
        }
        let current: Current
    }

    private func fetch(latitude: Double, longitude: Double) {
        guard latitude.isFinite, longitude.isFinite, let url = LiveWeather.url(latitude: latitude, longitude: longitude) else {
            failed()
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Scuttle", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("en", forHTTPHeaderField: "Accept-Language")
        session.dataTask(with: request) { [weak self] data, response, _ in
            let ok = (response as? HTTPURLResponse).map { (200..<300).contains($0.statusCode) } ?? false
            let current = ok ? data.flatMap { try? JSONDecoder().decode(Response.self, from: $0) }?.current : nil
            DispatchQueue.main.async {
                guard let self else { return }
                guard let current, let weather = LiveWeather.weather(code: current.weatherCode, windKmh: current.windSpeed) else {
                    self.failed()
                    return
                }
                self.received(Reading(weather: weather, isDay: (current.isDay ?? 1) != 0, time: Date()))
            }
        }.resume()
    }

    private func received(_ next: Reading) {
        busy = false
        guard running else { return }
        stored = next
        defaults.set(next.weather.rawValue, forKey: "weatherReading")
        defaults.set(next.isDay, forKey: "weatherIsDay")
        defaults.set(next.time.timeIntervalSince1970, forKey: "weatherTime")
        status = .ok
        onChange?()
    }

    private func failed() {
        busy = false
        set(reading == nil ? .unavailable : .ok)
    }

    private func forget() {
        stored = nil
        for key in ["weatherReading", "weatherIsDay", "weatherTime"] { defaults.removeObject(forKey: key) }
    }

    private func set(_ next: Status) {
        status = next
        onChange?()
    }
}
