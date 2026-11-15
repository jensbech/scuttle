import XCTest
@testable import ScuttleCore

final class SeasonTests: XCTestCase {
    private func date(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12, zone: String = "UTC") -> (Date, Calendar) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        let value = calendar.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
        return (value, calendar)
    }

    private func season(_ y: Int, _ m: Int, _ d: Int, _ hemisphere: Hemisphere = .northern) -> Season {
        let (value, calendar) = date(y, m, d)
        return Season.of(value, hemisphere: hemisphere, calendar: calendar)
    }

    func testMeteorologicalNorth() {
        XCTAssertEqual(season(2026, 1, 15), .winter)
        XCTAssertEqual(season(2026, 2, 28), .winter)
        XCTAssertEqual(season(2026, 3, 1), .spring)
        XCTAssertEqual(season(2026, 5, 31), .spring)
        XCTAssertEqual(season(2026, 6, 1), .summer)
        XCTAssertEqual(season(2026, 8, 31), .summer)
        XCTAssertEqual(season(2026, 9, 1), .autumn)
        XCTAssertEqual(season(2026, 11, 30), .autumn)
        XCTAssertEqual(season(2026, 12, 28), .winter)
    }

    func testMeteorologicalSouthFlipsTheFour() {
        XCTAssertEqual(season(2026, 1, 15, .southern), .summer)
        XCTAssertEqual(season(2026, 4, 10, .southern), .autumn)
        XCTAssertEqual(season(2026, 7, 10, .southern), .winter)
        XCTAssertEqual(season(2026, 10, 10, .southern), .spring)
        XCTAssertEqual(season(2026, 12, 28, .southern), .summer)
    }

    func testFestiveWindowsWin() {
        XCTAssertEqual(season(2026, 10, 23), .autumn)
        XCTAssertEqual(season(2026, 10, 24), .halloween)
        XCTAssertEqual(season(2026, 10, 31), .halloween)
        XCTAssertEqual(season(2026, 11, 1), .autumn)
        XCTAssertEqual(season(2026, 11, 30), .autumn)
        XCTAssertEqual(season(2026, 12, 1), .christmas)
        XCTAssertEqual(season(2026, 12, 25), .christmas)
        XCTAssertEqual(season(2026, 12, 26), .christmas)
        XCTAssertEqual(season(2026, 12, 27), .winter)
        XCTAssertEqual(season(2026, 12, 30), .winter)
        XCTAssertEqual(season(2026, 12, 31), .newYear)
        XCTAssertEqual(season(2027, 1, 1), .newYear)
        XCTAssertEqual(season(2027, 1, 2), .winter)
    }

    func testFestiveWindowsDoNotFlipSouth() {
        XCTAssertEqual(season(2026, 10, 31, .southern), .halloween)
        XCTAssertEqual(season(2026, 12, 25, .southern), .christmas)
        XCTAssertEqual(season(2026, 12, 31, .southern), .newYear)
        XCTAssertEqual(season(2026, 11, 2, .southern), .spring)
    }

    func testLeapDay() {
        XCTAssertEqual(season(2028, 2, 29), .winter)
        XCTAssertEqual(season(2028, 2, 29, .southern), .summer)
    }

    func testUsesCalendarTimeZone() {
        let (value, _) = date(2026, 12, 1, hour: 2, zone: "Pacific/Auckland")
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        var auckland = Calendar(identifier: .gregorian)
        auckland.timeZone = TimeZone(identifier: "Pacific/Auckland")!
        XCTAssertEqual(Season.of(value, calendar: auckland), .christmas)
        XCTAssertEqual(Season.of(value, calendar: utc), .autumn)
    }

    func testNonGregorianCalendarStillUsesGregorianDates() {
        let (value, _) = date(2026, 12, 24)
        var buddhist = Calendar(identifier: .buddhist)
        buddhist.timeZone = TimeZone(identifier: "UTC")!
        XCTAssertEqual(Season.of(value, calendar: buddhist), .christmas)
    }

    func testEveryDayOfTheYearResolves() {
        var counts: [Season: Int] = [:]
        for month in 1...12 {
            for day in 1...31 {
                counts[Season.of(month: month, day: day), default: 0] += 1
            }
        }
        XCTAssertEqual(counts[.christmas], 26)
        XCTAssertEqual(counts[.halloween], 8)
        XCTAssertEqual(counts[.newYear], 2)
        XCTAssertEqual(Set(counts.keys), Set(Season.allCases))
    }

    func testSettingParsingAndNames() {
        XCTAssertEqual(SeasonSetting("auto"), .automatic)
        XCTAssertEqual(SeasonSetting("Automatic"), .automatic)
        XCTAssertEqual(SeasonSetting("off"), .automatic)
        XCTAssertEqual(SeasonSetting("winter"), .fixed(.winter))
        XCTAssertEqual(SeasonSetting("Christmas"), .fixed(.christmas))
        XCTAssertEqual(SeasonSetting("fall"), .fixed(.autumn))
        XCTAssertEqual(SeasonSetting("new-year"), .fixed(.newYear))
        XCTAssertEqual(SeasonSetting("newyear"), .fixed(.newYear))
        XCTAssertNil(SeasonSetting("monsoon"))
        XCTAssertNil(SeasonSetting(""))
        for setting in SeasonSetting.all {
            XCTAssertEqual(SeasonSetting(setting.name), setting)
        }
        XCTAssertEqual(SeasonSetting.all.count, Season.allCases.count + 1)
    }

    func testSettingResolves() {
        let (value, calendar) = date(2026, 7, 10)
        XCTAssertEqual(SeasonSetting.automatic.resolve(on: value, calendar: calendar), .summer)
        XCTAssertEqual(SeasonSetting.automatic.resolve(on: value, hemisphere: .southern, calendar: calendar), .winter)
        XCTAssertEqual(SeasonSetting.fixed(.halloween).resolve(on: value, calendar: calendar), .halloween)
    }

    func testSettingCodable() throws {
        let data = try JSONEncoder().encode([SeasonSetting.automatic, .fixed(.newYear)])
        XCTAssertEqual(String(decoding: data, as: UTF8.self), "[\"auto\",\"newyear\"]")
        XCTAssertEqual(try JSONDecoder().decode([SeasonSetting].self, from: data), [.automatic, .fixed(.newYear)])
        XCTAssertEqual(try JSONDecoder().decode([SeasonSetting].self, from: Data("[\"off\"]".utf8)), [.automatic])
        XCTAssertThrowsError(try JSONDecoder().decode([SeasonSetting].self, from: Data("[\"monsoon\"]".utf8)))
    }

    func testHemisphereGuess() {
        XCTAssertEqual(Hemisphere.guess(regionCode: "AU"), .southern)
        XCTAssertEqual(Hemisphere.guess(regionCode: "nz"), .southern)
        XCTAssertEqual(Hemisphere.guess(regionCode: "ZA"), .southern)
        XCTAssertEqual(Hemisphere.guess(regionCode: "AR"), .southern)
        XCTAssertEqual(Hemisphere.guess(regionCode: "NO"), .northern)
        XCTAssertEqual(Hemisphere.guess(regionCode: "US"), .northern)
        XCTAssertEqual(Hemisphere.guess(regionCode: nil), .northern)
        XCTAssertEqual(Hemisphere.guess(regionCode: ""), .northern)
    }

    func testSeasonNames() {
        for season in Season.allCases {
            XCTAssertEqual(Season(name: season.rawValue), season)
            XCTAssertEqual(Season(name: season.title), season)
            XCTAssertFalse(season.title.isEmpty)
        }
        XCTAssertEqual(Season.allCases.filter(\.isFestive), [.halloween, .christmas, .newYear])
    }
}
